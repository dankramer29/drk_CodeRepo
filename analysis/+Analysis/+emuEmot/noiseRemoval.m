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

    for jj = 1:size(bandNames)
        dataLFP.(task{trialType}).(ch{ii}).image.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
        dataLFP.(task{trialType}).(ch{ii}).response.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
    end
end

if trialType == 1
    trialType = 2;
elseif trialType == 2
    trialType = 1;
end


%this is the same thing, but removes it from the other variant (so by
%identity if by emotion and vice versa)
ch = Tremove.flaggedChannel;
variant = Tremove.flaggedVariantOtherway;
trial = Tremove.flaggedTrialOtherway;
trialAdj = 1;
for ii = 1:size(Tremove,1)
    if ii > 1
        %need to adjust the trial count back one every time you remove one
        %from that channel and variant. the last part of the logical is in case the
        %equivalent trial in the other presentation is actually earlier
        %than the one before it. 
        if strcmp(ch{ii}, ch{ii-1}) && variant(ii) == variant(ii-1) && trial(ii) > trial(ii-1)
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
   
    for jj = 1:size(bandNames)
        dataLFP.(task{trialType}).(ch{ii}).image.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
        dataLFP.(task{trialType}).(ch{ii}).response.bandPassed.(bandNames{jj}){variant(ii)}(trial(ii),:) = [];
    end
end


dataLFPout = dataLFP;

end