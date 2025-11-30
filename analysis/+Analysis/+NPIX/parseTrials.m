function [spkITI,spkStimOn,spkResp, itiEnd, stimEnd] = parseTrials(unitSpikesCl,taskData)
%parseTrials.m takes spike times and converts to spikes within trials
%broken up by different epoch. THIS IS REALLY FOR MSIT OUTPUT

%   will give spikes per ms bins, and a smoothed spike rate, as well as an
%   adjusted time vector to plot.

%
%   outputs: 
%           spkITI etc- has spikes in an array of 0s/1s each spot is a ms.
%           then binned spikes at 

[varargin, basicAvgFR] = util.argkeyval('basicAvgFR',varargin, true); % option to get some basic firing rate average (not for good statistics, just quick so no need to shuffle)


preStim = 750; %ms prior to stim on (includes a ramp to cut off for edge effects)
postStim = 1750; %ms post to stim on (includes a ramp to cut off for edge effects)
preITI = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
postITI = 2500; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti
preResp = 250; %ms prior to iti on (includes a ramp to cut off for edge effects)
postResp = 2500; %ms prior to iti on (includes a ramp to cut off for edge effects), the shortest iti is 2s so adding pad on that, but will likely take the middle of the iti


%create template rasters the size specified above
tempStimSize = zeros(length(taskData.Trial), preStim+postStim);
tempITISize = zeros(length(taskData.Trial), preITI+postITI);
tempRespSize = zeros(length(taskData.Trial), preResp+postResp);

spkITI = struct;
spkStimOn = struct;
spkResp = struct;

spkITI.spkTime= -preITI+1:1:postITI;
spkStimOn.spkTime= -preStim+1:1:postStim;
spkResp.spkTime = -preResp+1:1:postStim;

for jj = 1:length(unitSpikesCl) 
    spkStimOn.spk{jj,1} = tempStimSize;
    spkITI.spk{jj,1} = tempITISize;
    spkResp.spk{jj,1} = tempRespSize;    
    for ii = 1:length(taskData.Trial)
        itiSt = taskData.fixaton_time(ii);
        stimSt = taskData.stimulus_time(ii);
        if jj == 1 %only needs to be done once
            %record where on each trial the fixation ends/response happens so you can mark it in
            %time, adding the pretime so you can just plot it on the raster
            itiEnd(ii) = taskData.stimulus_time(ii)-taskData.fixaton_time(ii)+preITI;
            stimEnd(ii) = taskData.response_time(ii)-taskData.stimulus_time(ii)+preStim;
        end
        respSt = taskData.response_time(ii);
        %round is putting it into the closest ms (can have more fine
        %grained spike bins if necessary)
        epochSt = itiSt-(preITI/1000); epochEnd = itiSt + (postITI/1000);
        tempSpikeTimes = unitSpikesCl{jj}(unitSpikesCl{jj} >= epochSt & unitSpikesCl{jj} <= epochEnd); %find spikes in this window
        tempSpikeTimesConverted = round((tempSpikeTimes - epochSt)*1000); %convert to per trial time and ms to put a spike in the cell
        if ~isempty(tempSpikeTimesConverted)
            tempSpikeTimesConverted(tempSpikeTimesConverted == 0) = 1;
            if basicAvgFR     
                %find time of any block ends
                idx1 = 1;
                for ii = 1:length(taskData.Trial)-1
                    if taskData.Trial(ii+1)-taskData.Trial(ii)>1
                        blockChange(idx1) = taskData.fixation_time(ii)*1000; %convert ot ms
                        idx1 = idx1 + 1;
                    end
                end
                %will do for each block, WILL NEED TO DO A MOVING WINDOW AT
                %SOME POINT JUST TO MAKE SURE THERE ISN'T SIGNIFICANT DRIFT
                %BUT NOT DOING IT THIS SECOND AND THIS IS AN EASY WAY TO DO
                %IT
                for ii = 1:length(blockChange)
                    if ii ==1
                        basicMeanFr(jj,1) = sum(tempSpikeTimesConverted(1:round(blockChange(ii))))/blockChange(ii);
                    else
                        basicMeanFr(jj,1) = sum(tempSpikeTimesConverted(1:round(blockChange(ii))))/blockChange(ii)-blockChange(ii-1);
                    end
                end

            tempSpikeTimesConverted(tempSpikeTimesConverted >= preITI+postITI) = preITI+postITI; %if round puts a spike at 0 or after the trial, move it to 1 or end
            spkITI.spk{jj,1}(ii, tempSpikeTimesConverted) = 1;
            [~, spkITI.spkRate{jj,1}(ii,:), spkITI.spkRateSm{jj,1}(ii,:), spkITI.spkRateSmTime] = Analysis.BasicDataProc.spikeRateGauss(spkITI.spk{jj}(ii,:));
        end
        clear tempSpikeTimes; clear tempSpikeTimesConverted
        epochSt = stimSt-(preStim/1000); epochEnd = stimSt + (postStim/1000);
        tempSpikeTimes = unitSpikesCl{jj}(unitSpikesCl{jj} >= epochSt & unitSpikesCl{jj} <= epochEnd); %find spikes in this window
        tempSpikeTimesConverted = round((tempSpikeTimes - epochSt)*1000); %convert to per trial time and ms to put a spike in the cell
        if ~isempty(tempSpikeTimesConverted)
            tempSpikeTimesConverted(tempSpikeTimesConverted == 0) = 1;
            tempSpikeTimesConverted(tempSpikeTimesConverted >= preStim+postStim) = preStim+postStim; %if round puts a spike at 0 or after the trial, move it to 1 or end
            spkStimOn.spk{jj,1}(ii, tempSpikeTimesConverted) = 1;
            [~, spkStimOn.spkRate{jj,1}(ii,:), spkStimOn.spkRateSm{jj,1}(ii,:), spkStimOn.spkRateSmTime] = Analysis.BasicDataProc.spikeRateGauss(spkStimOn.spk{jj}(ii,:));
        end
        clear tempSpikeTimes; clear tempSpikeTimesConverted
        epochSt = respSt-(preResp/1000); epochEnd = respSt + (postResp/1000);
        tempSpikeTimes = unitSpikesCl{jj}(unitSpikesCl{jj} >= epochSt & unitSpikesCl{jj} <= epochEnd); %find spikes in this window
        tempSpikeTimesConverted = round((tempSpikeTimes - epochSt)*1000); %convert to per trial time and ms to put a spike in the cel
        if ~isempty(tempSpikeTimesConverted)
            tempSpikeTimesConverted(tempSpikeTimesConverted == 0) = 1;
            tempSpikeTimesConverted(tempSpikeTimesConverted >= preResp+postResp) = preResp+postResp; %if round puts a spike at 0 or after the trial, move it to 1 or end
            spkResp.spk{jj,1}(ii, tempSpikeTimesConverted) = 1;
            [~, spkResp.spkRate{jj,1}(ii,:), spkResp.spkRateSm{jj,1}(ii,:), spkResp.spkRateSmTime] = Analysis.BasicDataProc.spikeRateGauss(spkResp.spk{jj}(ii,:));
        end
      
    end
end


end