function [dataLFPout] = noiseRemoval(dataLFP, Tch, removeTrials, varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

[varargin, trialType] = util.argkeyval('trialType',varargin, 1); %1 if identity task and 2 if emotion task


Tremove = Tch(removeTrials, :);

task = fieldnames(dataLFP);
chNames = fieldnames(dataLFP.(task{1}));
tskTime = fieldnames(dataLFP.(task{1}).(chNames{1}));
dataType = fieldnames(dataLFP.(task{1}).(chNames{1}).image);
bandNames = fieldnames(dataLFP.(task{1}).(chNames{1}).image.bandPassed);


ch = Tremove.flaggedChannel;
variant = Tremove.flaggedVariant;
trial = Tremove.flaggedTrials;

for ii = 1:size(Tremove,1)
    dataLFP.(task{trialType}).(ch{ii}).image.specD{variant(ii)}(:,:,trial(ii)) = [];
    dataLFP.(task{trialType}).(ch{ii}).response.specD{variant(ii)}(:,:,trial(ii)) = []; %remove the response too, since both will be unusable
    for jj = 1:size(bandNames)
        dataLFP.(task{trialType}).(ch{ii}).image.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
        dataLFP.(task{trialType}).(ch{ii}).response.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
    end
end


dataLFPout = dataLFP;

end