function [nback,outputArg2] = nbackCompareLFP(identityTaskLFP,emotionTaskLFP,varargin)
%UNTITLED2 Summary of this function goes here
%   lfp1/2 = expects output of nwbLFPchProc for the emotion relevant task
%   and the identity relevant task

[varargin, chInterest]=util.argkeyval('chInterest', varargin, 1); %pull in the channel names
[varargin, numIDs]=util.argkeyval('numIDs', varargin, 3); %3 face IDs are shown
[varargin, numEmotions]=util.argkeyval('numEmotions', varargin, 3); %3 emotions are shown

%% set up names for the struct
for ff=1:length(chInterest)
    ch = num2str(chInterest(ff));
    chName{ff} = ['ch' ch];
end

for ff=1:numIDs
    numstr = num2str(ff);
    idName{ff} = ['id' numstr];
end

for ff=1:numEmotions
    numstr = num2str(ff);
    emotName{ff} = ['emotion' numstr];
end

%find the size of the data
[rr, cc, dd] = size(identityTaskLFP.byemotion.(chName{1}).image.specD{1});


%compare channel by channel
%run through each channel and compare emotion to emotion and identity to
%identity.
%nback.ch1.identityMean{id1}(identitymeanemotionmean)
for ii = 1:length(chInterest)
    idx1 = 1;
    idx2 = 1;
    for jj = 1:numIDs %goes through each image
        trialcountID = size(identityTaskLFP.byidentity.(chName{ii}).image.specD{jj}, 3);
        trialcountEmot = size(emotionTaskLFP.byidentity.(chName{ii}).image.specD{jj}, 3);
        if trialcountID ~= trialcountEmot
            warning('trialcount different between same presentations between tasks')
        end

        dataIdentity = identityTaskLFP.byidentity.(chName{ii}).image.specD{jj};
        dataEmotion = emotionTaskLFP.byidentity.(chName{ii}).image.specD{jj};
        %create a matrix with all of the identities/emotions stacked so you
        %can process them as one
        dataIdentityAll(:,:,idx1:idx1+trialcountID-1) = dataIdentity;
        dataEmotionAll(:,:,idx2:idx2+trialcountEmot-1) = dataEmotion;

        [nback.(chName{ii}).(idName{jj}).identityMean, nback.(chName{ii}).(idName{jj}).emotionMean...
            nback.(chName{ii}).(idName{jj}).identitySD, nback.(chName{ii}).(idName{jj}).emotionSD...
            nback.(chName{ii}).(idName{jj}).sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentity, dataEmotion, 'xshuffles', 50);
        idx1 = idx1 + trialcountID;
        idx2 = idx2 + trialcountEmot;
    end
    idx1 = 1;
    idx2 = 1;
    for jj = 1:numEmotions %goes through each emotion
        trialcountID = size(identityTaskLFP.byemotion.(chName{ii}).image{jj}, 3);
        trialcountEmot = size(emotionTaskLFP.byemotion.(chName{ii}).image{jj}, 3);
        if trialcountID ~= trialcountEmot
            warning('trialcount different between same presentations between tasks')
        end

        dataIdentity = identityTaskLFP.byemotion.(chName{ii}).image{jj};
        dataEmotion = emotionTaskLFP.byemotion.(chName{ii}).image{jj};
        dataIdentityAll(:,:,idx1:idx1+trialcountID-1) = dataIdentity;
        dataEmotionAll(:,:,idx2:idx2+trialcountEmot-1) = dataEmotion;

        [nback.(chName{ii}).(idName{jj}).identityMean, nback.(chName{ii}).(idName{jj}).emotionMean...
            nback.(chName{ii}).(idName{jj}).identitySD, nback.(chName{ii}).(idName{jj}).emotionSD...
            nback.(chName{ii}).(idName{jj}).sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentity, dataEmotion, 'xshuffles', 50);
        idx1 = idx1 + trialcountID;
        idx2 = idx2 + trialcountEmot;
    end
end



end