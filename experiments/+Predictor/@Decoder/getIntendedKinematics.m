function [x_intended,IntentionState]=getIntendedKinematics(obj,x_actual,goal_position)

is1D=false;
if size(goal_position,1)==1;
    is1D=true;
    goal_position=[goal_position;goal_position*0];
    x_actual=[x_actual;x_actual*0];
end

options=obj.decoderParams.intentionOptions;



options.showFigs=Utilities.getInputField(options,'showFigs',0); 
showFigs=options.showFigs;

% maximum number of time_points that the intentions and extrinsic events
% can be offset from each other
options.max_lags=Utilities.getInputField(options,'max_lags',0); 
max_lags=options.max_lags;

% set constants (hardcoded now, make optional later?)
options.targetzone_thresh=Utilities.getInputField(options,'targetzone_thresh',3); 
targetzone_thresh=options.targetzone_thresh;


options.bufferzone_thresh=Utilities.getInputField(options,'bufferzone_thresh',7); 
bufferzone_thresh=options.bufferzone_thresh;

% # of frames the monkey must be outside the buffer zone before we assume
% he tries to make a corrective movement to the target
options.bufferzoneDuration_thresh=Utilities.getInputField(options,'bufferzoneDuration_thresh',2); 
bufferzoneDuration_thresh=options.bufferzoneDuration_thresh;

% number of frames between when the target appears and when the monkey
% intends to move to target
options.targetAppearDelay=Utilities.getInputField(options,'targetAppearDelay',2); 

options.targetAppearDelay2=Utilities.getInputField(options,'targetAppearDelay2',options.targetAppearDelay);


% number of frames between when the the cursor enters the target zone and
% when the monkey intends to hold.
options.targetZoneDelay=Utilities.getInputField(options,'targetZoneDelay',0); targetZoneDelay=options.targetZoneDelay;


options.intention_estimation_type=Utilities.getInputField(options,'intention_estimation_type','reactionTime'); intention_estimation_type=options.intention_estimation_type;


% options
% How to calulate the intended trajectory
% version 1 uses the shenoy method of rotating the velocity vecotr so that
% it points at the goal.
% version 2 computes the optimal desired velocity based on the prevoius
% state and goal position.

% Shenoy version
% compute the intended state.  Use the current position and infer the
% intended velocity from the direction to the goal scaled by the computed
% velocity.

% DialInTime calculation
% DialInTime here referes to that period of time when the monkey intends
% zero velocity as he is onstensibly at the goal position.  However, how
% should should I treat entering and than exciting the target as sometimes
% the cursor can move quite far from the target.  I'm choosing to have
% seperate enter and exit thresholds.  For instance, on approach, i
% consider 3cms to be the radius of the DialInregion whereas the monkey
% must exit a 5cm radius for the DialIn region to be exited.


%%
% warning('This function assumes that when a target is not on the screen, the position of the target is represented by Nans.')
indxs=1:size(x_actual,2);
goal_position=goal_position';
if exist('backfillnans')>0
 GPos_Nonan = backfillnans(goal_position);
else
    GPos_Nonan=goal_position;
end

%% Step 1 : Compute Intended velocity
HPos=x_actual(1:2:end,indxs)';
HVel=x_actual(2:2:end,indxs)';
Hspeed=Utilities.mnorm(HVel);
HDir=HVel./repmat(Hspeed,1,2);

GDist=Utilities.mnorm(GPos_Nonan-HPos);
GDir=(GPos_Nonan-HPos)./repmat(GDist,1,2);
IntendedVel=GDir.*repmat(Utilities.mnorm(HVel),1,2);

x_intended=x_actual'*0;
x_intended(:,1:2:end)=HPos;
x_intended(:,2:2:end)=IntendedVel;


%% Step 2 : Estimate when intended velocity is zero

GPos_Nonan(GPos_Nonan==100) = nan;

goal_position = GPos_Nonan;

switch intention_estimation_type
    case 'simple'
        % Simple version, either target is absent or on the target
        
        % if no target is visible (e.g. after acquiring target) assume intention is
        % to remain stationary.
        NoTargetInds=isnan(sum(goal_position'))';
        % if overlapping target, assume intended velocity is zero
        WithinTargetInds=GDist<targetzone_thresh;
        
        % IntentionState is high when we assume the monkey has the intention to
        % move
        IntentionState=~[NoTargetInds | WithinTargetInds];
        
        % note that the above metrics are calculated assuming zero delay between
        % the monkeys intentions and alterations in the task (for instance, when
        % the target appears and target position is not nan, the monkey immedietly
        % has the intention to move.)  This will likely not be the case as there
        % are reaction time delays etc.
        % I assume that there should be a correlation between when the monkey
        % intends to move and the velocity of the cursor whould be correlated.
        % to correct for reaction time delays I introduce an offset that maximizes
        % the correlation between intentions and cursor speed e.g. the following
        % worked best (also true when running xcorr)
        % corrcoef(Hspeed(4:end),double(~IntZeroVelInds(1:end-3)))
        
        if showFigs
            figure; hold on
            plot(HPos,'--.')
            plot(goal_position,'linewidth',2)
            plot(~IntZeroVelInds,'r.')
        end
    case 'reactionTime'
        NoTargetInds=isnan(sum(goal_position'))';
        % if overlapping target, assume intended velocity is zero
        WithinTargetInds=GDist<targetzone_thresh;
        
        % IntentionState is high when we assume the monkey has the intention to
        % move
        IntentionState=~[NoTargetInds | WithinTargetInds];
        
        % account for reaction time on appearance of targets
        
        firstTargetAppear = find(diff(goal_position(:,1)==0 & goal_position(:,2)==0)==1)+1;
%         secondTargetAppear = find(diff(goal_position(:,1)==0 & goal_position(:,2)==0)==-1)+1;
        
c1=diff(goal_position(:,1)); c2=diff(goal_position(:,2));
c3=goal_position(:,1)==0; c4=goal_position(:,2)==0;
 secondTargetAppear=find((c1|c2)&~(c3(1:end-1)&c4(1:end-1)))+1;

secondTargetAppear = find(diff(goal_position(:,1)==0 & goal_position(:,2)==0)==-1)+1;
        
        
        for i = 1:length(firstTargetAppear)
            s = min([length(IntentionState) firstTargetAppear(i)+options.targetAppearDelay-1]);
                
            IntentionState(firstTargetAppear(i):s) = 0;
        end
        
        for i = 1:length(secondTargetAppear)
            s = min([length(IntentionState) secondTargetAppear(i)+options.targetAppearDelay2-1]);

            IntentionState(secondTargetAppear(i):s) = 0;
        end
        
      
    case 'complex'
        %%
        % more complex version.  Either first approach
        % to target or subsequent approaches if the cursor has traveled greater
        % than X distance from target (e.g. a condition under which he is likely to
        % try a corrective movement and is not simply holding over the target
        % waiting for it to settle on the target).
        
        % to construct we model the monkeys intentions using asymetric state
        % transition rules.  There are two states : TargetApproach and TargetHold.
        % We transition from TargetAppraoch to TargetHold if the cursor moves
        % within a neighborhood of the target.  We transition to TargetApproach if
        % a new target appears or if we move far away from the target for more
        % than x amount of time (the monkey is unlikely to attempt a corection if
        % the target leaves the buffer zone for e.g. a single time step) after
        % being within the vicinity of the target. Note that we are trying to model
        % the monkeys intentions - not a trivial problem, but this might be better
        % than the above approach. (also, if no target appears we assume the monkey
        % has no intention of moving)
        
        
        % bufferzone_thresh - if monkey moves outside this zone after being within
        % the targetzone we assume the monkey wants to move
        
        % targetzone_thresh - if monkey moves within this zone we assume he intends
        % to hold the position.
        %
        % bufferzoneDuration_thresh - the amount of time the monkey must be outside
        % the bufferzone before assuming the monkey wants to make a corrective
        % movement
     
        
        % compute zone thresholds as a function of target distances
        % target_distances=Utilities.mnorm(tmp); target_distances(target_distances==0)=[];
        
           
        % targetAppearDelay - the amount of time after the target appears
        % that we assume movement intentions arise in the monkey (e.g. to account for visual feedback delays)
         goal_position(isnan(goal_position))=inf;
    
        tmp=diff(goal_position); 
        tmp(tmp>1000000)=0;
        tmp(isnan(tmp))=0;
        targetAppear=logical([zeros(1,size(tmp,2));tmp]);
        targetAppear=any(targetAppear')';
        
        % precompute when the targets appear
%         tmp=diff(GPos_Nonan); tmp(isnan(tmp))=0;
%         targetAppear=logical([zeros(1,size(tmp,2));tmp]);
%         targetAppear=any(targetAppear')';
        
        % initialize in the TargetHold state for init_ind frames
        init_ind=max([targetAppearDelay,bufferzoneDuration_thresh]);
        IntentionState(1:init_ind)=0;
        
        for i=init_ind+1:length(targetAppear)
            
            % state transitions depend on the previous state
            switch IntentionState(i-1)
                case 1 % TargetApproach State
                    
                    if all(GDist(i-targetZoneDelay)<targetzone_thresh)
                        %                 the monk entered the target zone for some duration
                        IntentionState(i)=0;
                    else
                        IntentionState(i)=IntentionState(i-1);
                    end
                    
                case 0 % TargetHold State
                    
                                        if targetAppear(i-targetAppearDelay) & GDist(i)>targetzone_thresh
%                     if targetAppear(i-targetAppearDelay)
                        %                 if target appeared at a distant location the monkey
                        %                 transitions to the TargetApproach state
                        IntentionState(i)=1;
                        
                    elseif all(GDist(i-bufferzoneDuration_thresh:i)>bufferzone_thresh)
                        %                 the monk exited bufferzone_thresh for some extended
                        %                 duration
                        IntentionState(i)=1;
                    else
                        IntentionState(i)=IntentionState(i-1);
                    end
                    
                    
            end
        end
        IntentionState=IntentionState';
        %%
        
        % figure; hold on
        % plot(targetAppear,'r.')
        % plot(GPos_Nonan)
end


%%

if(max_lags)
    [cc,lags]=xcorr(Hspeed,double(IntentionState),max_lags,'coeff'); 
    plot(lags,cc)
    [peak,peak_ind]=max(cc); peak_lag=lags(peak_ind);


    IntentionState=circshift_zeroed(double(IntentionState),[peak_lag 0]);


    cc=corrcoef(Hspeed,IntentionState);

    disp(sprintf('Max correlation = %0.2f at %d lag',cc(1,2), peak_lag))
    disp(sprintf('Assuming monkey intended to move %0.2f percent of the time',sum(IntentionState)/length(IntentionState)))
end


%%
x_intended(~IntentionState,2:2:end)=0;
x_intended=x_intended'; 
%%

% obj.figureHandles.IntentionPlot=figure(88); clf;
% subplot(2,1,1);
% plot(x_actual(2:2:end,:)'); hold on; plot(IntendedVel,'--','linewidth',2)
% plot(x_intended(2:2:end,:)','linewidth',2)
% 
% subplot(2,1,2); hold on
% plot(HPos,'--.')
% plot(goal_position,'linewidth',2)
% line([firstTargetAppear'; firstTargetAppear'],ylim','Color','r','LineStyle','--')
% line([secondTargetAppear secondTargetAppear]',ylim','Color','c','LineStyle','--')
% plot(IntentionState.*2,'mo')
            
            if is1D;
    x_intended=x_intended(1:2,:);
            end
