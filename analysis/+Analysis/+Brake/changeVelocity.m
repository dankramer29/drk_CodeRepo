function [outputArg1,outputArg2] = changeVelocity(spkData,velocityData, varargin)
%UNTITLED Summary of this function goes here
%   Input: The inputs must be lined up, so the start of spkData and the
%   start of velocityData are the same time point
%         spkData= smoothed spike data
%         velocityData= smoothed velocity data
            

[varargin, fsSpk] = util.argkeyval('fsSpk',varargin, 1000); %sampling rate of spike data
[varargin, fsVel] = util.argkeyval('fsVel',varargin, 1000); %sampling rate of position data
[varargin, binSize] = util.argkeyval('binSize',varargin, 45); %how many ms to check the change in velocity over

binSizeSpk=(1/fsSpk)*1000; %get the bin size in MS
binSizeVel=(1/fsVel)*1000; %get the bin size in MS

bS=round(binSize/binSizeVel); %find out how many bins = the desired bin size

for ii=1:bS:size(velocityData, 2)
    time1=velocityData(ii);
    
end

end

