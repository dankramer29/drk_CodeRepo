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


util.argempty(varargin); % check all additional inputs have been processed

if size(data,1) > size(data,2)
    data = data';
end

shLAdj = round(shuffleLength*fs); %adjust the shuffle length for the sampling frequency
trialLengthAdj = round(trialLength*fs); %adjust the trial length for the sampling frequency


for ii = 1:trials
    for jj = 1:shLAdj:trialLengthAdj
        st = randi(length(data)-shLAdj);
        trialData(:,jj:jj+shLAdj-1,ii) = data(:,st:st+shLAdj-1);
    end
end



end