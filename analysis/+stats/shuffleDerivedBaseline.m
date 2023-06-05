function [trialData] = shuffleDerivedBaseline(data,varargin)
%UNTITLED2 pulls Xms chunks of data to make fake trials and creates a
%histogram of clusters to compare. IN THEORY, ONLY NEED TO DO THIS ONCE
%   inputs
%   dataLFP = input the voltage, will cut and run spectrogram from here
% Example
% itiDataStitch = struct;
% trialLength = preTime + postTime;
% %stritch the iti trials together
% for ii= 1:length(channelName)
%     S1 = itiDataFiltEmotion.iti.(channelName{ii}).specD;
%     
%     [itiDataStitch.EmotionTask.(channelName{ii})] = stats.shuffleDerivedBaseline(S1, 'fs',...
%         size(emotionTaskLFP.byemotion.(channelName{ii}).image.specD{1}, 2)/trialLength, ...
%         'shuffleLength', shuffleLength, 'trials', stitchTrialNum, 'stitchSmooth',...
%         true, 'TimeFreqData', true, 'smoothingWindow', smoothingWindow);
% end
%  THIS WORKS, HOWEVER IF BEING USED FOR SPECTRAL ANALYSIS AND USING A STITCH METHOD A LOT MORE WORK
%  NEEDS TO GO INTO IT TO MAKE IT EVEN. WILL NEED TO ADJUST THE BASELINES
%  AND SMOOTH THE TRANSITIONS, BUT WITH SOMETHING BESIDES A SMOOTH
%  FUNCTION. THE EDGES OF THE STITCH CAUSE A LOT OF ARTIFACT.
%  ALSO ONLY OUTPUTS ONE RIGHT NOW, BUT CAN EASILY MAKE IT OUTPUT 1-3 OF
%  THESE TYPES

[varargin, fs]=util.argkeyval('fs', varargin, []); %sampling rate in samples/sec. if blank, will take trialLength as number of samples. most useful if using spectrogram data which often makes an awkward sampling rate
[varargin, shuffleLength]=util.argkeyval('shuffleLength', varargin, .150); %in s (default 50ms) how much time you want in each epoch
[varargin, trials]=util.argkeyval('trials', varargin, 50); %number of fake trials you want
[varargin, trialLength]=util.argkeyval('trialLength', varargin, 2.5); %length of epoch to compare in s
[varargin, noStitch]=util.argkeyval('noStitch', varargin, false); %if you want chunks that are the same size as the trial itself, this prevents the edge issues
[varargin, stitchNoSmooth]=util.argkeyval('fs', varargin, false); %does a stitching method without smoothing it NOTE THIS WILL CAUSE EDGE EFFECTS IF USED FOR LFP
[varargin, stitchSmooth]=util.argkeyval('stitchSmooth', varargin, false); %does a stitching method smoothed NOTE THIS WILL CAUSE EDGE EFFECTS IF USED FOR LFP
[varargin, smoothingWindow]=util.argkeyval('smoothingWindow', varargin, .100); %what your smoothing window is in s. does a gaussian but can do others.

[varargin, timeStamps]=util.argkeyval('timeStamps', varargin, []); %include time stamps if you want to center on something and then shift.
[varargin, TimeFreqData]=util.argkeyval('TimeFreqData', varargin, true); %if time frequency data input NOT SET UP TO GO CHANNEL BY CHANNEL, DO THAT OUTSIDE THIS FUNCTION.


util.argempty(varargin); % check all additional inputs have been processed



if ~TimeFreqData && size(data,2) > size(data,1)
    data = data';
end

if isempty(fs)
    fs = round(trialLength/10); %create an fs if not entered, just divide up by 10, THIS NEEDS SOME MORE THOUGHT
    shLAdj = round(shuffleLength*fs);
    trialLengthAdj = trialLength; 
    smWin = round(smoothingWindow*fs);
else
    shLAdj = round(shuffleLength*fs); %adjust the shuffle length for the sampling frequency
    trialLengthAdj = round(trialLength*fs); %adjust the trial length for the sampling frequency
    smWin = round(smoothingWindow*fs);
end

if isempty(fs)

else
    shLAdj = round(shuffleLength*fs);
end


if noStitch %this just takes a trial sized chunk
    if ~TimeFreqData
        trialData = zeros(trialLengthAdj,size(data,2),trials);
        if isempty(timeStamps)

            for ii = 1:trials
                st = randi(length(data)-trialLengthAdj);
                trialData(:,:,ii) = data(st:st+trialLengthAdj-1,:);
            end
        else
            for ii = 1:trials
                timeStampIdx = randi(length(timeStamps));
                st = timeStamps(timeStampIdx) + randi([-fs, fs]); %by doing fs, it will move it back and forth 1 second
                trialData(:,:,ii) = data(st:st+trialLengthAdj-1,:);
            end
        end
    elseif TimeFreqData
        trialData = zeros(size(data,1), trialLengthAdj, trials);
        if isempty(timeStamps)
            for ii = 1:trials
                st = randi(length(data)-trialLengthAdj);
                trialData(:,:,ii) = data(:, st:st+trialLengthAdj-1);
            end
        else
            for ii = 1:trials
                timeStampIdx = randi(length(timeStamps));
                st = timeStamps(timeStampIdx) + randi([-round(trialLengthAdj/4), round(trialLengthAdj/4)]); %currently moves half a length up and down around start, timestamps need to be in same time as spec data
                trialData(:,:,ii) = data(:, st:st+trialLengthAdj-1);
            end
        end
    end
end


%% if you want to stitch small patches together
if stitchNoSmooth
    shiftAdjust = 20;
    trialData = zeros(trialLengthAdj+shiftAdjust,size(data,2),trials);
    trialDataTemp = zeros(trialLengthAdj+shiftAdjust,size(data,2),trials);
    for ii = 1:trials
        for jj = 1:shLAdj:trialLengthAdj-shLAdj
            st = randi(length(data)-shLAdj-shiftAdjust);
            shift = randi(shiftAdjust);
            shLAdjRand = shLAdj + shift; %this adds a little buffer so the transitions aren't as sharp, PROBABLY DOESNT WORK AND CAN REMOVE
            trialDataTemp(jj:jj+shLAdjRand-1,:,ii) = data(st:st+shLAdjRand-1,:);
        end

        trialData(:,:,ii) = trialDataTemp(:,:,ii);

    end

    %remove any extra for creating even trial lengths.
    if size(trialData,1) > trialLengthAdj
        trialData(trialLengthAdj+1:end,:,:) = [];
    end
end

if stitchSmooth
    if ~TimeFreqData
       
        trialData = zeros(trialLengthAdj+(shLAdj*2),size(data,2),trials);
        trialDataTemp = zeros(trialLengthAdj+(shLAdj*2),size(data,2),trials);
        for ii = 1:trials
            for jj = 1:shLAdj:trialLengthAdj+(shLAdj*2)
                st = randi(length(data)-(shLAdj*2));
                trialDataTemp(jj:jj+shLAdj-1,:,ii) = data(st:st+shLAdj-1,:);
            end
            %smooth the data
            %trialDataTemp1(:,:,ii) = smoothdata(trialDataTemp(:,:,ii),'sgolay',smWin); %compared golay to gaussian and it's exactly the same
            trialDataTemp2(:,:,ii) = smoothdata(trialDataTemp(:,:,ii),'gaussian',smWin);
            %trialDataGolay(:,:,ii) = trialDataTemp1(shLAdj:shLAdj+trialLengthAdj,:,ii);
            trialDataGaus(:,:,ii) = trialDataTemp1(shLAdj:shLAdj+trialLengthAdj,:,ii);

        end
        %remove any extra for creating even trial lengths.
        if size(trialDataGaus,1) > trialLengthAdj
            trialDataGaus(trialLengthAdj+1:end,:,:) = [];
        end
        trialData = trialDataGaus;

    elseif TimeFreqData
        
        trialData = zeros(size(data,1), trialLengthAdj+(shLAdj*2), trials);
        trialDataTemp = zeros(size(data,1), trialLengthAdj+(shLAdj*2), trials);
        for ii = 1:trials
            for jj = 1:shLAdj:trialLengthAdj+(shLAdj*2)
                st = randi([round(fs*10), length(data)-(shLAdj*2)]);
                trialDataTemp(:, jj:jj+shLAdj-1, ii) = data(:, st:st+shLAdj-1,:);
            end
            %smooth the data
            %trialDataTemp1(:,:,ii) = smoothdata(trialDataTemp(:,:,ii),'sgolay',smWin); %compared golay to gaussian and it's exactly the same
            trialDataTemp2(:,:,ii) = smoothdata(trialDataTemp(:,:,ii), 2,'gaussian',smWin);
            %trialDataGolay(:,:,ii) = trialDataTemp1(shLAdj:shLAdj+trialLengthAdj,:,ii);
            trialDataGaus(:,:,ii) = trialDataTemp2(:, shLAdj:shLAdj+trialLengthAdj-1,ii);

        end
        %remove any extra for creating even trial lengths. taken care of
        %above, but just in case
        if size(trialDataGaus,1) > trialLengthAdj
            trialDataGaus(trialLengthAdj+1:end,:,:) = [];
        end
        trialData = trialDataGaus;
    end
end








end