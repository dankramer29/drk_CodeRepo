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
trialAdj = 1;
for ii = 1:size(Tremove,1)
    if ii > 1
        %need to adjust the trial count back one every time you remove one
        %from that channel and variant
        if strcmp(ch{ii}, ch{ii-1}) && variant(ii) == variant(ii-1)
            trial(ii) = trial(ii)-trialAdj; 
            trialAdj = trialAdj + 1;
        else
            trialAdj = 1; %start the count back at 1
        end
    end
    if size(dataLFP.(task{trialType}).(ch{ii}).image.specD{variant(ii)},3) < trial(ii)
        warning(['not as many trial in ', ch{ii}, ' variant ', num2str(variant(ii))] );
        continue
    end
    dataLFP.(task{trialType}).(ch{ii}).image.specD{variant(ii)}(:,:,trial(ii)) = [];
    dataLFP.(task{trialType}).(ch{ii}).response.specD{variant(ii)}(:,:,trial(ii)) = []; %remove the response too, since both will be unusable
    %actually no reason to remove this since the noise could be a single
    %channel and not the others.
    % dataLFP.(task{trialType}).(ch{ii}).correctTrial{variant(ii)}(trial(ii)) = []; %remove the patient response
    % dataLFP.(task{trialType}).(ch{ii}).responseTimesInSec{variant(ii)}(trial(ii)) = []; %remove the response time.
    for jj = 1:size(bandNames)
        dataLFP.(task{trialType}).(ch{ii}).image.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
        dataLFP.(task{trialType}).(ch{ii}).response.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
    end
end


dataLFPout = dataLFP;

end