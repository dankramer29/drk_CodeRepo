function [spkITI, spkStimOn, spkResp, sigUnits, shuffleHist, itiEnd, responseTime] = parseTrials(unitSpikesCl,taskData, varargin)
%parseTrials.m takes spike times and converts to spikes within trials
%broken up by different epoch. THIS IS REALLY FOR MSIT OUTPUT

%   will give spikes per ms bins, and a smoothed spike rate, as well as an
%   adjusted time vector to plot.

%
%   outputs: 
%           spkITI etc- has spikes in an array of 0s/1s each spot is a ms.
%           then binned spikes at 


[varargin, shuffleFR]=util.argkeyval('shuffleFR', varargin, true); %run a basic average fr calculation
[varargin, xshuffle]=util.argkeyval('xshuffle', varargin, 1000); %number of shuffles
[varargin, endTrials]=util.argkeyval('endTrials', varargin, []); %if the trials should end at a certain spot because the recording ended
[varargin, interval]=util.argkeyval('interval', varargin, []); %get the intervals, defaults below
[varargin, alph]=util.argkeyval('alph', varargin, 0.05); %alpha level for finding the threshold of mean firing rates
[varargin, sigWindow]=util.argkeyval('sigWindow', varargin, 30); %ms over which you need to be significant to count it as a significant trial
[varargin, shuffleHist]=util.argkeyval('shuffleHist', varargin, []); %can preload shuffleHist if have done it previously.
[varargin, firstSpikeTime]=util.argkeyval('firstSpikeTime', varargin, []); %find the final spike time to end the recording at. this is to create a long enough vector to make binary spike times.
[varargin, lastSpikeTime]=util.argkeyval('lastSpikeTime', varargin, []); %find the final spike time to end the recording at. this is to create a long enough vector to make binary spike times.

if isempty(shuffleHist)
    shuffleFR = 1; %run shuffle histogram if not provided
else
    shuffleFR = 0; %if provided, no need to run again
end
%set up some variables for trouble shooting so no nested variable errors.
xx=[];yy=[];zz=[];xxx=[];yyy=[];zzz=[]; x1 = []; x2 = []; x3 =[];


alphP = 1-(alph/2);
alphN = alph/2; 
alphPThreshold = round(xshuffle*alphP);
alphNThreshold = round(xshuffle*alphN);

if isempty(endTrials)
    endTrials = length(taskData.Trial);
end

if isempty(lastSpikeTime)
    trialEndTime = taskData.trial_end_time(end);
    for ii = 1:length(unitSpikesCl)
        tempfirstSpikeTime(ii,1) = unitSpikesCl{ii,1}(1);
        templastSpikeTime(ii,1) = unitSpikesCl{ii,1}(end);
    end
    firstSpikeTime = min(tempfirstSpikeTime);
    lastSpikeTime = max(templastSpikeTime);
end

if isempty(interval)
    interval.preStim = 750; %ms prior to stim on (includes a ramp to cut off for edge effects)
    interval.postStim = 1750; %ms post to stim on (includes a ramp to cut off for edge effects)
    interval.preITI = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
    interval.postITI = 2500; %ms post to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
    interval.preResp = 1250; %ms prior to Response on (includes a ramp to cut off for edge effects)
    interval.postResp = 750; %ms after Resonse on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
end

preStim = interval.preStim; %ms prior to stim on (includes a ramp to cut off for edge effects)
postStim= interval.postStim; %ms post to stim on (includes a ramp to cut off for edge effects)
preITI = interval.preITI; %ms prior to iti on (includes a ramp to cut off for edge effects)
postITI = interval.postITI; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
preResp = interval.preResp; %ms prior to iti on (includes a ramp to cut off for edge effects)
postResp = interval.postResp; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti


%create template rasters the size specified above
tempStimSize = zeros(endTrials, preStim+postStim); 
tempITISize = zeros(endTrials, preITI+postITI);
tempRespSize = zeros(endTrials, preResp+postResp);

spkITI = struct;
spkStimOn = struct;
spkResp = struct;

spkITI.spkTime= -preITI+1:1:postITI;
spkStimOn.spkTime= -preStim+1:1:postStim;
spkResp.spkTime = -preResp+1:1:postResp;

for jj = 1:length(unitSpikesCl) 
    clear spikeTimesTemp tempAllSize
    tempAllSize = zeros(1,round(lastSpikeTime*1000));
    spkStimOn.spk{jj,1} = tempStimSize;
    spkITI.spk{jj,1} = tempITISize;
    spkResp.spk{jj,1} = tempRespSize;
    spkTimesTemp = round(unitSpikesCl{jj}*1000);
    tempAllSize(spkTimesTemp) = 1;
    [spkAll{jj,1}(1,:), spkRateAll{jj,1}(1,:), spkRateSmoothAll{jj,1}(1,:), tmAll{jj,1}(1,:)] = Analysis.BasicDataProc.spikeRateGauss(tempAllSize); %convert to ms and run the whole time
    for ii = 1:endTrials %stops any spot where the recording ends (so if no spikes at a certain trial (001 is like that) stops there)
        itiSt = round(taskData.fixaton_time(ii)*1000); %convert to ms and find the closest ms bin
        stimSt = round(taskData.stimulus_time(ii)*1000);
        if jj == 1 %only needs to be done once
            %record where on each trial the fixation ends/response happens so you can mark it in
            %time, adding the pretime so you can just plot it on the raster
            %or smoothed firing rate.
            itiEnd(ii) = taskData.stimulus_time(ii)-taskData.fixaton_time(ii)+preITI;
            responseTime(ii) = taskData.response_time(ii)-taskData.stimulus_time(ii)+preStim;
        end
        respSt = round(taskData.response_time(ii)*1000);
        %round is putting it into the closest ms (can have more fine
        %grained spike bins if necessary)
        spkITI.spk{jj,1}(ii,:) = spkAll{jj,1}(1,itiSt-preITI+1:itiSt+postITI); %raster
        spkITI.spkRateSm{jj,1}(ii,:) = spkRateSmoothAll{jj,1}(1,itiSt-preITI+1:itiSt+postITI); %smoothed
        spkStimOn.spk{jj,1}(ii,:) = spkAll{jj,1}(1,stimSt-preStim+1:stimSt+postStim); 
        spkStimOn.spkRateSm{jj,1}(ii,:) = spkRateSmoothAll{jj,1}(1,stimSt-preStim+1:stimSt+postStim);
        spkResp.spk{jj,1}(ii,:) = spkAll{jj,1}(1,respSt-preResp+1:respSt+postResp); 
        spkResp.spkRateSm{jj,1}(ii,:) = spkRateSmoothAll{jj,1}(1,respSt-preResp+1:respSt+postResp);       
        
    end
    if shuffleFR
        ticT = tic;
        timeRangeEnd = lastSpikeTime*1000; % take the last trial and convert to ms
        timeRangeSt = firstSpikeTime*1000;
        a = timeRangeSt+preStim; b = timeRangeEnd - postStim; n = endTrials;
        for kk = 1:xshuffle
            r = a + (b-a).*rand(n,1); %random generate start times
            for ii = 1:length(r)
                stimSt = round(r(ii)); %take random start times
                shuffleMatrix{jj,1}(ii,:,kk) = spkRateSmoothAll{jj,1}(1,stimSt-preStim+1:stimSt+postStim); %get random times
               
            end
        end
        shuffleTemp1 = mean(shuffleMatrix{jj},1);
        shuffleTemp2 = mean(shuffleTemp1, 2);        
        shuffleHist{jj,1} = sort(squeeze(shuffleTemp2)); %now above or below this .05/2 percentile should be significant.
        shuffleHist{jj,2} = shuffleHist{jj,1}(alphPThreshold);
        shuffleHist{jj,3} = shuffleHist{jj,1}(alphNThreshold);
        toc(ticT)
        % %find time of any block ends THIS IS TO SET UP FOR BLOCKS
        % IN CASE FR DRIFTS, WILL DO THIS MORE COMPLETELY LATER
        % idx1 = 1;
        % for ii = 1:length(taskData.Trial)-1
        %     if taskData.Trial(ii+1)-taskData.Trial(ii)<1 %if the trial count starts over
        %         blockChange(idx1) = taskData.fixation_time(ii+1)*1000; %convert the next trial number to ms
        %         idx1 = idx1 + 1;
        %     end
        % end
        % %will do for each block, WILL NEED TO DO A MOVING WINDOW AT
        % %SOME POINT JUST TO MAKE SURE THERE ISN'T SIGNIFICANT DRIFT
        % %BUT NOT DOING IT THIS SECOND AND THIS IS AN EASY WAY TO DO
        % %IT JUST BREAK IT UP INTO BLOCKS.
        % for ii = 1:length(blockChange)
        %     if ii ==1
        %         basicMeanFr(jj,1) = sum(tempSpikeTimesConverted(1:round(blockChange(ii))))/blockChange(ii); %find the overall firing rate
        %     else
        %         basicMeanFr(jj,1) = sum(tempSpikeTimesConverted(1:round(blockChange(ii))))/blockChange(ii)-blockChange(ii-1);
        %     end
        % end

    end
end


[spkITI.smMean, spkITI.smSTD, spkITI.posSection, spkITI.negSection, sigUnits.ITI] = findPositiveSection(spkITI, shuffleHist, sigWindow);
[spkStimOn.smMean, spkStimOn.smSTD, spkStimOn.posSection, spkStimOn.negSection, sigUnits.StimOn] = findPositiveSection(spkStimOn, shuffleHist, sigWindow);
[spkResp.smMean, spkResp.smSTD, spkResp.posSection, spkResp.negSection, sigUnits.Resp] = findPositiveSection(spkResp, shuffleHist, sigWindow);

    function [smMean, smStd, posSection, negSection, sigUnits] = findPositiveSection(spk, shuffleHist, sigWindow)
        sigUnits = zeros(size(spk.spkRateSm,1), 2); idx1 = 1; idx2 = 1;
        for jjj = 1:length(spk.spkRateSm)
            smMean(jjj,:) = mean(spk.spkRateSm{jjj}(:,251:end-250),1); %create unit x time matrix and remove the 250ms buffer I created for edge effects
            smStd(jjj,:) = std(spk.spkRateSm{jjj}(:,251:end-250));
            posSection(jjj,:) = smMean(jjj,:) > shuffleHist{jjj,2}; %greater than 97.5th of the mean
            negSection(jjj,:)  = smMean(jjj,:) < shuffleHist{jjj,3}; %less that 2.5th of the mean
            clustP=bwconncomp(posSection(jjj,:),8);
            for iii = 1:clustP.NumObjects
                if length(clustP.PixelIdxList{iii}) < sigWindow %make sure they are size of your window.
                    posSection(clustP.PixelIdxList{iii}) = 0;%convert any too small to 0
                else
                    sigUnits(jjj,1) = 1; %mark if it was positive or not.
                    idx1 = idx1+1;
                end
            end
            clustN=bwconncomp(negSection(jjj,:),8);
            for iii = 1:clustN.NumObjects
                if length(clustN.PixelIdxList{iii}) < sigWindow %make sure they are size of your window.
                    negSection(clustN.PixelIdxList{iii}) = 0;%convert any too small to 0
                else
                    sigUnits(jjj,2) = 2; %mark if it was positive or not.
                    idx2 = idx2+1;
                end
            end
        end
    end

end