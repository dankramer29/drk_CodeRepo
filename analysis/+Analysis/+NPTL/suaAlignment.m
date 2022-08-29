function [smoothSpkAligned] = suaAlignment(R, varargin)
%Will get smoothed spike data aligned and parsed without the LFP data to
%make a much faster run
%   Detailed explanation goes here

[varargin, data] = util.argkeyval('data',varargin, []); %check if the data has already been extracted    
[varargin, dProc] = util.argkeyval('dProc',varargin, []); %check if the data has already processed, which you can do with BASICdataProc.m

[varargin, fs] = util.argkeyval('fs',varargin, 30000); %original sample rate
[varargin, downSample] = util.argkeyval('downSample',varargin, 2000); %the new downsample rate

[varargin, epoch] = util.argkeyval('epoch',varargin, 500); %the epoch for all times, in ms
[varargin, spkWin] = util.argkeyval('spkWin',varargin, 20); %the window to average spikes over, in ms

[varargin, event] = util.argkeyval('event',varargin, [4 3]); %the events to center on, it will be ii and ii-1 so look for marker and marker behind

%These are the times to take around the events (state==5, click state,
%state==4 hover state (300ms), state==3 move state; state==2 target
%appears, state==1 new trial.
%trial = 1 to 3, to center on the out target, goes 5 to 1 to 2 to 3 quickly, so 1 to 2 to 3 is best place to center, either side for the whole trial, should include all transitions
%
%holdPre = 4 to 5, hold to acquire, holdPre amount before that transition (then minus the epoch)
%
%transHold = 3 to 4, move to hold, transition to hold, transHold before (then plus the epoch)
%
%movePost = 2 to 3 and 1 to 3, moving to target, movePost after that (then plus the epoch)
%
%transMove = 4 to 5 (since other is prep to move), includes just hold to move transition, transMove after that (then plus epoch)
%
%prep = 1 to 2, target appears, prep before or after that (then plus the epoch) 
%
%prepMove= 2 to 3, go cue appears, prepMove before, (then plus epoch)
[varargin, trial] = util.argkeyval('trial',varargin, 1000); %trial on either side
[varargin, holdPre] = util.argkeyval('holdPre',varargin, 0); %holdPre (then minus the epoch)
[varargin, transHold] = util.argkeyval('transHold',varargin, -100); %transHold before the Hold starts (then plus epoch)
[varargin, movePost] = util.argkeyval('movePost',varargin, 200); %time after a target appears (then plus epoch)
[varargin, transMove] = util.argkeyval('transMove',varargin, 0); %time before a target appears, transition to state 3
[varargin, prep] = util.argkeyval('prep',varargin, 100); %time before a target appears (then plus epoch)
[varargin, prepMove] = util.argkeyval('prepMove',varargin, -100); %time before a target appears (then plus epoch)


[varargin, channel] = util.argkeyval('channel',varargin, [1 196]); %which channels you want, default is whole grid
[varargin, trialNum] = util.argkeyval('channel',varargin, [1, size(R,2)]); %which trials you want, default is all.
[varargin, perc] = util.argkeyval('channel',varargin, 60); %what percentile of the most active channels you want. THIS LIMITS HOW MANY CHANNELS ARE INCLUDED, HIGHER PERCENTILE MEANS LESS CHANNELS ARE DISPLAYED
[varargin, grid] = util.argkeyval('grid', varargin, 0); %0= both, 1 = lateral, 2 = medial

[varargin, plotData] = util.argkeyval('plotData',varargin, true); %amount to plot before the epoch.  Will error if longer than the bufferT.  Only applies to the spectrogram and bandpassed dataolmk,

%% PREP ACTIVITY
%convert R to a struct PROBABLY THIS TO UNWIELDY AND WILL NEED TO BREAK
%R UP
if ~isa(R, 'struct')
    R=[R{:}];
end


%gridlayout per idx to channel FOR NOW, ONLY ADJUSTING THE CHANNELS IN
%CORRELATION, EASIER TO KEEP TRACK OF WHICH CHANNEL IS WHICH
idxch2el=[78,88,68,58,56,48,57,38,47,28,37,27,36,18,45,17,46,8,35,16,24,7,26,6,25,5,15,4,14,3,13,2,77,67,76,66,75,65,74,64,73,54,63,53,72,43,62,55,61,44,52,33,51,34,41,42,31,32,21,22,11,23,10,12,96,87,95,86,94,85,93,84,92,83,91,82,90,81,89,80,79,71,69,70,59,60,50,49,40,39,30,29,19,20,1,9];



%Spike times to set up for plotting
tSpkEndPoint=linspace(-epoch, epoch, floor(abs(epoch)/spkWin)+1);


%% gather the data up
holdData=[]; moveData=[];

idx1=2; trl=1; fl=1;
rState=double([R.state]);
rCP=double([R.cursorPosition]); %1 and 3 are position, 2 and 4 are velocity for grid task, and it's derivative of cp in grid task or row 1:2 of xp
rFCT=double([R.firstCerebusTime])+10*30; %There is a 10ms offset from ns5 and firstCerebusTime, unknown why, but verified. difference between row 1 and 2 is 6ms, lastcerebrustime is 29 and 35ms respectively for row 1/2
rMinA=double([R.minAcausSpikeBand]);
rPosTarget=double([R.posTarget])';
rLastPosTarget=double([R.lastPosTarget])';
%classify targets
PosTargetTemp=[0,-409;-409,0;0,409;409,0;289,289;289,-289;-289,289;-289,-289];
PosTarget=vertcat(PosTargetTemp, PosTargetTemp);
PTendB=repmat([0 0 0 0], 8,1);
PTendO=repmat([0 0 0 1], 8,1);
PT=vertcat(PTendB, PTendO);
PosTarget=[PosTarget, PT]; %set up categorization of targets
deg='deg';
pos={'0', '315', '270', '225', '180', '135', '90', '45'};
outback={'out', 'back'};


rTrial=[];
trialCount=1;
for ii=1:length(R)
    trialTemp=repmat(trialCount,1,length(R(ii).state));
    rTrial=[rTrial trialTemp];
    trialCount=trialCount+1;
end
if isempty(cell2mat(strfind(fields(R), 'spikeRaster')))
    threshMultiplier = -4.5;
    RMSvals = channelRMS( R );
    thresholds = RMSvals.*threshMultiplier;
    thresholds = thresholds'; % make column vector
    for iTrial = 1 : numel( R )
        R(iTrial).spikeRaster = R(iTrial).minAcausSpikeBand < repmat( thresholds, 1, size( R(iTrial).minAcausSpikeBand, 2 ) );
    end
end
if ~isempty(cell2mat(strfind(fields(R), 'spikeRaster2')))
    rSpkAll(1:96,:)=double([R.spikeRaster]);
    rSpkAll(97:192,:)=double([R.spikeRaster2]);
else
    rSpkAll=double([R.spikeRaster]);
end
%choose your grid to evaluate, depends on the ns5. 
if grid==1
    rSpk=rSpkAll(1:96,:);
    rMinA=rMinA(1:96,:);
elseif grid==2
    rSpk=rSpkAll(971:192, :);
    rMinA=rMinA(97:192,:);
else
    rSpk=rSpkAll(1:192, :);
    rMinA=rMinA(1:192,:);
end



%% spikes, all channels
%smooth the spikes
[spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(rSpk, 'win', spkWin);
% Outputs:l,
%         spk-  converts raster to NaNs and 1s for plotting
%         spkRate- spikes summed over a window
%         spkRateSmooth- smoothed spikes with convolve
%         tm- a time vector for plotting to match spikes
spikeCh.spk=spk; %flip them all to match the lfp data, so columns are channels
spikeCh.spkRate=spkRate;
spikeCh.spkRateSmooth=spkRateSmooth;
spikeCh.tm=tm;

%% find active channels and get rid of noisey channels

[msM] = Analysis.BasicDataProc.activeSpkCh(spkRateSmooth, 'perc', perc);

% find the channels most active, then choose between highest spike rates
% (mean) or highest variability (std), or the modulation (highest to
% lowest)

%[msM] = Analysis.BasicDataProc.activeSpkCh(moveSmooth, 'perc', perc);
%which one to pick to look at the channels
spikeCh.meanstdSpkPerc=msM;
%choose the modDSPk, can also choose mean and ste changes, but likely will
%pick up noisey channels
ChSpk=msM.modDSpk;

byTargetEndPointSpk=struct;
idx=1;
for ii=1:2
    for jj=1:8
        PosTargetName{idx}=strcat(deg, ' ', pos{jj}, ' ', outback{ii});
        byTargetEndPointSpk.(PosTargetName{idx})=[];
        for kk=1:length(ChSpk)
            chstr=['ch', num2str(ChSpk(kk))];
            byTargetEndPointSpk.(PosTargetName{idx}).(chstr)=[];
        end
        idx=idx+1;
    end
end

%this sets the time before and after the event
tMEpoch=epoch;
tMDiff=tm(2)-tm(1);
tMEpoch=round(tMEpoch/tMDiff);
%%

%get the states hovering
idxTr=1; idxH=1; idxTH=1; idxMO=1; idxTM=1; idxPr=1; idxPM=1; idxTHe=1; idxCheck=1;
for ii=500:length(rState)-trial %start 500ms in, should be all garbage but some weird number things and end before length of trial
     if rState(ii)==event(1) && rState(ii-1)==event(2) && sum(rState(ii:ii+epoch)==5)>0 %so if the trial ends and it wasn't a false endpoint
            %epoch seconds on either side of stop
            rEndPoint(idxTHe,1)=ii;vc
            endPointCP{idxTHe}=rCP(:,ii-epoch:ii+epoch);
            endPointPosTarget(idxTHe,:)=rPosTarget(rTrial(ii),:);
            endPointLastPosTarget(idxTHe,:)=rLastPosTarget(rTrial(ii),:);
            if endPointPosTarget(idxTHe,1)==0 && endPointPosTarget(idxTHe,2)==0
                TargetTemp=endPointLastPosTarget(idxTHe,:);
                TargetTemp(1,end+1)=0; %if it's coming to center
                Target(idxTHe,:)=TargetTemp;
            else
                TargetTemp=endPointPosTarget(idxTHe,:);
                TargetTemp(1,end+1)=1; %if it's going out to target
                Target(idxTHe,:)=TargetTemp;
            end
            [~,TargetIdx]=intersect(PosTarget, Target(idxTHe,:), 'rows'); %find the row that lines up with the right target
            TargetByTrial(idxTHe)=TargetIdx; %record which target it was for each found endpoint.
            
            endPointSpk{idxTHe}=spk(ii-epoch:ii+epoch, :); %take all the channels at once
            endPointFCT(idxTHe, :)=rFCT(1,ii);        
            tempSt=find(tm>=ii-epoch); tempEnd=tempSt(1)+tMEpoch;
            endPointSmooth{idxTHe}=spkRateSmooth(tempSt(1):tempEnd(end),:);
            %get spikes averaged across the channels, for each trial
            tempSt=[]; tempEnd=[];
            endPointSmoothChMean(:,idxTHe)=nanmean(endPointSmooth{idxTHe},2);   %mean across all channels
            %%find maxima and minima of the spikes and band data for each trial,
            %%this is too compare within each trial.
            endPointpkPeaksChMean(:,idxTHe)=Analysis.BasicDataProc.specChange(endPointSmoothChMean(:,idxTHe));
            targetstr=PosTargetName{TargetIdx};
            for jj=1:length(ChSpk)
                bychEndPointSpk{jj}(:, idxTHe)=endPointSmooth{idxTHe}(:, ChSpk(jj)); %cells by channel, with trials by spike smoothed
                chstr=['ch', num2str(ChSpk(jj))];
                if isempty(byTargetEndPointSpk.(targetstr).(chstr))
                    byTargetEndPointSpk.(targetstr).(chstr)=endPointSmooth{idxTHe}(:, ChSpk(jj));
                else
                    byTargetEndPointSpk.(targetstr).(chstr)(:,end+1)=endPointSmooth{idxTHe}(:, ChSpk(jj));
                end
            end
            
            idxTHe=idxTHe+1;
      end
    
end

expectedChNum=floor(length(ChSpk)*(1-(perc/100)));
mostModDepthChbyTarget=[];
meanModDepthbyTarget=[];
mostMxChbyTarget=[];
meanMxbyTarget=[];
meanMxbyTargetAll=[];
meanMaxbyTargetMat=[];
meanModDepthbyTargetAll=[];
meanModDepthbyTargetMat=[];

for ii=1:length(PosTargetName)
    targetstr=PosTargetName{ii};
    for jj=1:length(ChSpk)
        chstr=['ch', num2str(ChSpk(jj))];
        meanTemp=mean(byTargetEndPointSpk.(targetstr).(chstr),2);
        byTargetEndPointSpk.(targetstr).(chstr)(:,end)=meanTemp;
        byChMeanTemp(:,jj)=meanTemp;
    end
    %% will assess the max and modular depth of the channels
    %% max
    mxSpk=max(byChMeanTemp);
    mxSpkPerc=prctile(mxSpk, perc);
    mostMxChbyTargetTemp=find(mxSpk > mxSpkPerc);%taking top x percent channels per target based on max fr
   
    mostMxChbyTarget=horzcat(mostMxChbyTarget, mostMxChbyTargetTemp);
    meanMxbyTargetAll=horzcat(meanMxbyTargetAll, byChMeanTemp(:,mostMxChbyTargetTemp)); %channels by means
    meanMxbyTarget{ii}=byChMeanTemp(:,mostMxChbyTargetTemp); %arranged by target, starting in order of PosTargetNames
    
    [maxSpkTemp, maxSpkId]=max(byChMeanTemp(:,mostMxChbyTargetTemp));
    normModDepthSpk=byChMeanTemp(:,mostMxChbyTargetTemp)./maxSpkTemp; %should normalize    
    [~,I]=sort(maxSpkId);
    meanMxbyTarget{ii}=normModDepthSpk(:,[I]);
    meanMaxbyTargetMat=horzcat(meanMaxbyTargetMat, normModDepthSpk(:,[I]));
    
    %% modular depth
    mnSpk=min(byChMeanTemp);
    modDepth=mxSpk-mnSpk;
    modDPerc=prctile(modDepth,perc);     
    mostModDepthChbyTargetTemp=find(modDepth > modDPerc); %taking the top x percent channels per target bsed on max mod depth
    
    mostModDepthChbyTarget=horzcat(mostModDepthChbyTarget, mostModDepthChbyTargetTemp);
    meanModDepthbyTargetAll=horzcat(meanModDepthbyTargetAll, byChMeanTemp(:,mostModDepthChbyTargetTemp));
    
    [maxSpkTemp, maxSpkId]=max(byChMeanTemp(:,mostModDepthChbyTargetTemp));
    normModDepthSpk=byChMeanTemp(:,mostModDepthChbyTargetTemp)./maxSpkTemp; %should normalize    
    [~,I]=sort(maxSpkId);
    meanModDepthbyTarget{ii}=normModDepthSpk(:,[I]);
    meanModDepthbyTargetMat=horzcat(meanModDepthbyTargetMat, normModDepthSpk(:,[I]));
end

Target(:,end+1)=TargetByTrial;

%set up plotting
%Max
%normalize

chLength=1:size(meanMxbyTargetAll,2);

[maxSpkTemp, maxSpkId]=max(meanMxbyTargetAll);
normModDepthSpk=meanMxbyTargetAll./maxSpkTemp; %should normalize

[~,I]=sort(maxSpkId);
normSpkT=normModDepthSpk(:,[I]);

figure
imagesc(tSpkEndPoint, chLength, normSpkT'); axis xy;

figure
H=imagesc(tSpkEndPoint, chLength, meanMaxbyTargetMat'); axis xy;




%Mod Depth
%normalize
[maxSpkTemp, maxSpkId]=max(meanModDepthbyTargetAll);
normModDepthSpk=meanModDepthbyTargetAll./maxSpkTemp; %should normalize

[~,I]=sort(maxSpkId);
normSpkT=normModDepthSpk(:,[I]);

figure
imagesc(tSpkEndPoint, chLength, normSpkT'); axis xy;

figure
H=imagesc(tSpkEndPoint, chLength, meanModDepthbyTargetMat'); axis xy;


end

