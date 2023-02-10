function [trialData] = shuffleDerivedBaseline(data,varargin)
%UNTITLED2 pulls Xms chunks of data to make fake trials and creates a
%histogram of clusters to compare. IN THEORY, ONLY NEED TO DO THIS ONCE
%   inputs
%   dataLFP = input the voltage, will cut and run spectrogram from here
%  THIS WORKS, HOWEVER IF BEING USED FOR SPECTRAL ANALYSIS AND USING A STITCH METHOD A LOT MORE WORK
%  NEEDS TO GO INTO IT TO MAKE IT EVEN. WILL NEED TO ADJUST THE BASELINES
%  AND SMOOTH THE TRANSITIONS, BUT WITH SOMETHING BESIDES A SMOOTH
%  FUNCTION. THE EDGES OF THE STITCH CAUSE A LOT OF ARTIFACT.
%  ALSO ONLY OUTPUTS ONE RIGHT NOW, BUT CAN EASILY MAKE IT OUTPUT 1-3 OF
%  THESE TYPES

[varargin, fs]=util.argkeyval('fs', varargin, 500); %sampling rate
[varargin, shuffleLength]=util.argkeyval('shuffleLength', varargin, .05); %in s (default 50ms) how much time you want in each epoch
[varargin, trials]=util.argkeyval('trials', varargin, 50); %number of fake trials you want
[varargin, trialLength]=util.argkeyval('trialLength', varargin, 2); %length of epoch to compare in s
[varargin, noStitch]=util.argkeyval('noStitch', varargin, true); %if you want chunks that are the same size as the trial itself, this prevents the edge issues
[varargin, stitchNoSmooth]=util.argkeyval('fs', varargin, false); %does a stitching method without smoothing it NOTE THIS WILL CAUSE EDGE EFFECTS IF USED FOR LFP
[varargin, stitchSmooth]=util.argkeyval('fs', varargin, false); %does a stitching method smoothed NOTE THIS WILL CAUSE EDGE EFFECTS IF USED FOR LFP


util.argempty(varargin); % check all additional inputs have been processed

if size(data,2) > size(data,1)
    data = data';
end

shLAdj = round(shuffleLength*fs); %adjust the shuffle length for the sampling frequency
trialLengthAdj = round(trialLength*fs); %adjust the trial length for the sampling frequency


if noStitch %this just takes a trial sized chunk
    trialData = zeros(trialLengthAdj,size(data,2),trials);

    for ii = 1:trials
        st = randi(length(data)-trialLengthAdj);
        trialData(:,:,ii) = data(st:st+trialLengthAdj-1,:);
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
    smWin = 50;
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
end








end