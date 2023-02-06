function [trialData] = shuffleDerivedBaseline(data,varargin)
%UNTITLED2 pulls Xms chunks of data to make fake trials and creates a
%histogram of clusters to compare. IN THEORY, ONLY NEED TO DO THIS ONCE
%   inputs
%   dataLFP = input the voltage, will cut and run spectrogram from here
%   TO DO, NEED TO DO SOME MATH TO MAKE THE SHUFFLELENGTH DIVIDE EVENLY
%   INTO TRIALLENGTH, PROBABLY JUST INCREASE THE SIZE OF THE TRIAL

[varargin, fs]=util.argkeyval('fs', varargin, 500); %sampling rate
[varargin, shuffleLength]=util.argkeyval('shuffleLength', varargin, .05); %in s (default 50ms) how much time you want in each epoch
[varargin, trials]=util.argkeyval('trials', varargin, 50); %number of fake trials you want
[varargin, trialLength]=util.argkeyval('trialLength', varargin, 2); %length of epoch to compare in s
[varargin, continuous]=util.argkeyval('continuous', varargin, false); %if true, will unravel the trials to be able to run spectrogram or whatever across the whole thing, then break up by trial


util.argempty(varargin); % check all additional inputs have been processed

if size(data,2) > size(data,1)
    data = data';
end

shLAdj = round(shuffleLength*fs); %adjust the shuffle length for the sampling frequency
trialLengthAdj = round(trialLength*fs); %adjust the trial length for the sampling frequency

shiftAdjust = 20;
trialData = zeros(trialLengthAdj+shiftAdjust,size(data,2),trials);
trialDataTemp = zeros(trialLengthAdj+shiftAdjust,size(data,2),trials);

%% if you want to stitch small patches together
for ii = 1:trials
    for jj = 1:shLAdj:trialLengthAdj-shLAdj
        st = randi(length(data)-shLAdj-shiftAdjust);
        shift = randi(shiftAdjust);
        shLAdjRand = shLAdj + shift;
        trialDataTemp(jj:jj+shLAdjRand-1,:,ii) = data(st:st+shLAdjRand-1,:);
    end
    %smooth the data
    %trialData(:,:,ii) = smoothdata(trialDataTemp(:,:,ii),'sgolay',50);
        trialData(:,:,ii) = trialDataTemp(:,:,ii);

end


%remove any extra for creating even trial lengths.
if size(trialData,1) > trialLengthAdj    
    trialData(trialLengthAdj+1:end,:,:) = [];
end




%NOT TESTED
if continuous
    for ii = 1:size(trialData,3)
    trialDataCont = [trialDataCont trialData(:,:,ii)];
    end
end

end