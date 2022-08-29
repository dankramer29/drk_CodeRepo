function [dataHoldMove] = procData(R, ns5File, varargin)
%procData Process the BCI data to break it up into times when it is
%hovering and when it isnt
%  R details - each row is a ms
% Input
%     R - R struct file, NEED TO FIGURE OUT THE TIMING
%     ns5File - the name of the file path for the file you want
%     
% Output
%     dataHoldMove - has 6 outputs
% TO DO:
%     -Need to set up the array with the gridlayout, which I need to get from spencer or someone else
%     -Find the channel names regardless of what's put in
%     -figure out how to time lock with the spiking activity? Probably what will need to happen is to plot the spiking activity as it changes around the stop/hold times and match it with the changes in beta
%     
% 
%     Example:
%         
%         [dataHoldMoveBP]=Analysis.NPTL.procData(Rr, ns5file, 'Spectrogram', true);
%LIKELY NEED THE HOVER TIME AT THE END WHICH WILL BE A DIFFERENT
    %STATE
 %THERE MIGHT BE A TIME WHERE IT ENDS WITH 4 AND THE NEXT ONE IS THE
    %SAME CONTINUOUS MOVEMENT EVEN THE R HAS PROGRESSED
    
    
[varargin, fs] = util.argkeyval('fs',varargin, 30000); %original sample rate
[varargin, ns5num] = util.argkeyval('ns5num',varargin, 3); %which cell of ns5 file you want, usually 3
[varargin, downSample] = util.argkeyval('downSample',varargin, 2000); %the new downsample rate

[varargin, epoch] = util.argkeyval('epoch',varargin, [.3 .3]); %the epoch to run spectrogram around size (1,1) and start time after 0 (1,2) you want in seconds
[varargin, bufferT] = util.argkeyval('bufferT',varargin, [.5 .5]); %the buffer window to process data around your desired time of interest (so will take .5 s before and .5 after the state==4 times). This is to allow sufficient plotting before and after
[varargin, channel] = util.argkeyval('channel',varargin, [1 10]); %which channels you want
[varargin, trialNum] = util.argkeyval('channel',varargin, [1, size(R,2)]); %which trials you want, default is all.
 
[varargin, Spectrogram] = util.argkeyval('Spectrogram',varargin, true); %if doing Spectrogram or not


[varargin, plotMean] = util.argkeyval('plotMean',varargin, true); %if you want to plot.

%% PREP ACTIVITY
%convert R to a struct PROBABLY THIS TO UNWIELDY AND WILL NEED TO BREAK
%R UP
if ~isa(R, 'struct')
    R=[R{:}];
end

%% OPEN DATA
%convert to readable for the channels
ch=['c:0', num2str(channel(1,1)), ':', num2str(channel(1,2))];
ns5=openNSx('read', ns5File, 'c:01:12'); %Open the file
data=double(ns5.Data{ns5num});



timeHold=[]; timeMove=[];
holdData=[]; moveData=[];

idx1=2; trl=1; fl=1;
for ii=trialNum(1):trialNum(2)  
    %get the states close to the center position which is 0 on the screen
    rHold=find(R(ii).state==4); %get all the time points around zero
    rTime(ii)=length(R(ii).state); %get the total time (in ms) of each trial, for finding data later
    %NEED TO FIND OUT THE TIMES THAT THE TRIAL IS HEADING OUT, WHAT STATE
    %THAT IS AND DO THE SAME THING AS THE R==4
    %if the trial failed, automatically pulls the cursor back, record which
    %trials to ignore
    if R(ii).isSuccessful==0 && ii<length(R)        
        rFail(fl)=ii+1;
        fl=fl+1;
    end
    
    multTrials=[];  
   
    %% cut the data by moving and not moving based on .state being 4
    %get a list of the start and stop times from firstCerebrusTime. (NOTE:
    %DOES NOT SOLVE THE 1MS DIFFERENCE OF FIRST AND LAST CEREBRUST TIME/ROW
    %1 ROW 2, HOWEVER IT'S 1 MS)
    %Set up so odd rows are start times, and even rows are end times for
    %state==4
    if isempty(rHold)
        continue
    else
        %record the 
        rHoldTime(trl,1)=ii;        
        rHoldTime(trl,2)=rHold(1);
        rHoldTime(trl,3)=rHold(end);
        trl=trl+1;
        
        if isempty(timeHold)
            timeHold(1,1)=R(ii).firstCerebusTime(1, rHold(1));
        end
        if ~isempty(rHold)
            
            %consecH=[]; consecH(1,1)=1;
            for jj=1:length(rHold)-1
                %check if it's a new state of 4
                consecTemp=rHold(jj+1)-rHold(jj);
                if consecTemp~=1
                    timeHold(idx1,1)=R(ii).firstCerebusTime(1, rHold(jj));
                    %consecH(idx1,2)=jj; %make it that index
                    idx1=idx1+1;
                    timeHold(idx1,1)=R(ii).firstCerebusTime(1, rHold(jj+1)); %start of the next set of R
                    idx1=idx1+1;
                    multTrials=true; %mark if there are multiple state 4s in a trial
                end
            end
            %check and make sure it doesn't cross into the next trial
            if rHold(end)==size(R(ii).state,2)
                if multTrials
                    warning('trial ends with a 4, meaning crosses into the next one',num2str(ii))
                    continue
                else
                    timeHold(idx1,1)=R(ii).firstCerebusTime(1, rHold(1));
                    idx1=idx1+1;
                    warning('trial ends with a 4, meaning crosses into the next one',num2str(ii))
                    continue
                end
            else
                if multTrials
                    timeHold(idx1,1)=R(ii).firstCerebusTime(1, rHold(end)); %end the last state 4
                    idx1=idx1+1;
                else
                    %if it's the first trial, only add the end
                    if length(timeHold)~=1
                        timeHold(idx1,1)=R(ii).firstCerebusTime(1, rHold(1));
                        idx1=idx1+1;
                    end
                    timeHold(idx1,1)=R(ii).firstCerebusTime(1, rHold(end)); %end the last state 4
                    idx1=idx1+1;
                end
            end
        end
    end
end

%% create the windows during movement
timeMove=zeros((size(timeHold,1)+1),1);
timeMove(1,1)=R(2).firstCerebusTime(1,1);
timeMove(2:size(timeHold,1)+1,1)=timeHold;
timeMove(end,1)=R(end).firstCerebusTime(end,1);

%% to obtain the cursor position and the spike rates


%go through each channel and pull the spike data
for jj=channel(1):channel(2)
    cp=[]; cpTrial=[]; spikeRaw=[]; id1=1; spk=[]; spkRate=[]; spkRateSmooth=[]; tm=[];
    for ii=trialNum(1):trialNum(2)
        cp=[cp R(ii).cursorPosition(1:2,:)];
        spikeRaw=[spikeRaw double(R(ii).spikeRaster(jj,:))];
        cpTrial{id1}=R(ii).cursorPosition(1:2,:);
        id1=id1+1;
    end
    
    %% to look at spikes (from what I understand about the R so far)
    [spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(spikeRaw);
    % Outputs:
    %         spk-  converts raster to NaNs and 1s for plotting
    %         spkRate- spikes summed over a window
    %         spkRateSmooth- smoothed spikes with convolve
    %         tm- a time vector for plotting to match spikes
    for kk=1:size(rHoldTime,1)
        timePrior=sum(rTime(1:rHoldTime(kk))); %get the add on time to find the right spot in spike timing
        stH=(rHoldTime(kk,2)-bufferT(1,1)*1000)+timePrior; 
        endH=(rHoldTime(kk,3)+bufferT(1,2)*1000)+timePrior;
        spkHold{kk}(1,:)=spk(1, stH:endH); %find the spike epochs you want + a buffer
        spkHold{kk}(2,:)=stH:endH;
        tmpSt=find(tm>=stH); tmpEnd=find(tm>=endH); 
        spkRateSmoothHold{kk}(1,:)=spkRateSmooth(1, tmpSt(1):tmpEnd(1)); 
        spkRateSmoothHold{kk}(2,:)=tm(1, tmpSt(1):tmpEnd(1));
    end
    spikeCh{jj}.spk=spk; %etc
    spikeCh{jj}.spkRate=spkRate;
    spikeCh{jj}.spkRateSmooth=spkRateSmooth;
    spikeCh{jj}.tm=tm;
    spikeCh{jj}.spkHold=spkHold;
    spikeCh{jj}.spkRateSmoothHold=spkRateSmoothHold;
    
end






%% grab and process the LFP data
%add a rampup
for ii=1:2:length(timeHold)    
    HoldWindow(ii,1)=timeHold(ii,1)-fs*bufferT(1,1); %add a buffer window of time bufferT
    HoldWindow(ii+1,1)=timeHold(ii+1,1)+fs*bufferT(1,2); %add a buffer window of .5s
end
for ii=1:2:length(timeMove)
    MoveWindow(ii,1)=timeMove(ii,1)-fs*bufferT(1,1); %add a buffer window of .5s
    MoveWindow(ii+1,1)=timeMove(ii+1,1)+fs*bufferT(1,2); %add a buffer window of .5s
end

tt=tic;


%% downsample and process the data with either a spectrogram or bandpass
%set up a dummy bandfilter if using spectrogram
if Spectrogram
    bandfilter=1;
else
    bandfilter=[];
end
    
idx2=1;
for kk=1:2:size(HoldWindow,1)
    holdData{idx2}=double(data(:,HoldWindow(kk,1):HoldWindow(kk+1,1)));
    if isempty(bandfilter)
        [holdDataP{idx2}, params, bandfilter]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(holdData{idx2}, fs, downSample), 'Spectrogram', Spectrogram);
    else
        [holdDataP{idx2}, params]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(holdData{idx2}, fs, downSample), 'Spectrogram', Spectrogram, 'bandfilter', bandfilter);
        
        idx2=idx2+1;
    end
end

idx3=1;
for kk=1:2:size(MoveWindow,1)
    moveData{idx3}=double(data(:, MoveWindow(kk,1):MoveWindow(kk+1,1)));
    moveDataP{idx3}=Analysis.NPTL.dataPrep(Analysis.NPTL.downSample(moveData{idx3}, fs, downSample), 'Spectrogram', Spectrogram, 'bandfilter', bandfilter);
    
    idx3=idx3+1;
end
toc(tt);

% get the stepsize and start times
%THE DATA OUTPUT IS TIME X F X CH
if Spectrogram
    stepsz=params.win(1,2);
    st=epoch(1,2)/stepsz+.5/stepsz; %the starting point to take the epoch from. the .5 is the 0 mark, based on a .5s ramp up
else %for bandpasseed
    stepsz=1/downSample;
    st=epoch(1,2)*downSample+.5*downSample;
end

%% compare data
%create 3d structures broken up by channel (so {channel}.(freq x time x trial) and cut into epochs that
for ii=1:size(holdDataP,2) %trials
    for jj=1:size(holdDataP{1}.data,3)   %channels     
        holdDataPCut{jj}(:,:,ii)=holdDataP{ii}.data(:, st:(st+epoch(1,1)/stepsz),jj);
    end
end
for ii=1:size(holdDataP,2)
    for jj=1:size(holdDataP{1}.data,3)        
        moveDataPCut{jj}(:,:,ii)=moveDataP{ii}.data(:, st:(st+epoch(1,1)/stepsz),jj);
    end
end

for ii=1:size(holdDataPCut,2)
    [meanHold{ii}, meanMove{ii}, stdHold{ii}, stdMove{ii}, sigclust{ii}, rlab{ii}]=stats.cluster_permutation_Ttest_gpu3d(holdDataPCut{ii}, moveDataPCut{ii}); 
end

%% set up plotting
tCut=holdDataP{1}.tplot(st:(st+epoch(1,1)/stepsz))-0.5; %creates the time for plotting
f=holdDataP{1}.f;

%set up colors
C=linspecer(36);

%create the numbers for the grid
for jj=1:10
    tmp=[];
    tmp=[1:10];
    tmp=tmp+((jj-1)*10);
    gridlayout(jj,1:10)=tmp;    
end
gridlayout=gridlayout'-1;
gridlayout(11:end)=gridlayout(11:end)-1;
gridlayout(91:end)=gridlayout(91:end)-1;
gridlayout([1 10 91 100])=NaN;
gridlayout=fliplr(gridlayout);

 
% figure



if plotMean
    
    for ii=1:size(moveDataPCut,2)
        meanData=meanHold{ii}-meanMove{ii};
        
        figtitle=['Hold minus Move Channel ', num2str(ii), ' Heatmap ', ];
            figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
            subplot(3,2, [1 2 3 4])
            
            im=imagesc(tCut, f, meanData); axis xy;
            ax=gca;
            title(['Normalized Power '])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
            ax.YTick=(0:20:round(f(end)));
            
            % plot where on the array the electrode is NOT DONE
%             subplot(3,2,5)
%             for ii=1:100
%                 
%                 for ii=1:gridlayout
%                     text(1,1, num2str(gridlayout(ii)));
%                 end
%             end
%             box on
%             axis off

            %for color schemes
            %temp_p=double(sigclustDB');
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
%             im=imagesc(tplot, f, rlab); axis xy;
%             ax=gca;
%             xlim([plot_buff(1) plot_buff(2)]); %only show the plot buffer pre and buffer post
%             title(['Pvalues Bonferroni ', ecog.evtNames{ff},' channel ',blc.ChannelInfo(ch(kk)).Label])
%             xlabel('Time (s)','Fontsize',13);
%             ylabel('Frequency (Hz)','Fontsize',13);
%             ax.YTick=(0:20:round(f(end)));
            
            
            %plot the sig clust
            subplot(3,2,6)
            temp_p=double(sigclust{ii});
            %temp_p(temp_p==0)=0.6;
            %temp_p(temp_p==1)=0.18;
            %temp_p(1,1)=0; temp_p(1,2)=1;
            im=imagesc(tCut, f, temp_p); axis xy;
            ax=gca;
            title(['Pvalues Cluster Permutation '])
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            ax.YTick=(0:20:round(f(end)));
    end
end
    


dataHoldMove=struct;
dataHoldMove.holdRaw=holdData;
dataHoldMove.holdProc=holdDataP;
dataHoldMove.holdProcCut=holdDataPCut;
dataHoldMove.moveRaw=moveData;
dataHoldMove.moveProc=moveDataP;
dataHoldMove.moveProcCut=moveDataPCut;
dataHoldMove.holdTime=HoldWindow;
dataHoldMove.moveTime=MoveWindow;
dataHoldMove.params=params;
dataHoldMove.tCut=tCut;
dataHoldMove.f=f;




    


end

