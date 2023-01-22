function [nback,significantComparisons] = nbackCompareLFP(identityTaskLFP,emotionTaskLFP,varargin)
%UNTITLED2 Summary of this function goes here
%   lfp1/2 = expects output of nwbLFPchProc for the emotion relevant task
%   and the identity relevant task

[varargin, chInterest]=util.argkeyval('chInterest', varargin, 1); %pull in the channel names
[varargin, numIDs]=util.argkeyval('numIDs', varargin, 3); %3 face IDs are shown
[varargin, numEmotions]=util.argkeyval('numEmotions', varargin, 3); %3 emotions are shown
[varargin, itiDataFilt]=util.argkeyval('itiDataFilt', varargin, []); %include iti data
[varargin, comparedToCondition]=util.argkeyval('comparedToCondition', varargin, false); %if you are going to compare condition to condition (i.e. emotion task to identity task)
[varargin, comparedToITI]=util.argkeyval('comparedToITI', varargin, true); %if you are going to compare condition to iti (i.e. emotion task to random generated ITI)

if comparedToITI ==1
    if isempty(itiDataFilt)
        error('no iti data included')
    end
end


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

%% compares condition vs condition
if comparedToCondition == 1
    %compares channel by channel
    %run through each channel and compare emotion to emotion and identity to
    %identity.
    %REMINDER: it is using non z scored data, so do that at the end
    %
    idxcomp=1;
    for ii = 1:length(chInterest)
        idx1 = 1;
        idx2 = 1;
        %this run goes compares the same identity, compared for the identity
        %task against the emotion task (so same face, different attention)
        for jj = 1:numIDs %goes through each identity (remember identity is the face, image refers to image vs response)
            trialcountID = size(identityTaskLFP.byidentity.(chName{ii}).image.specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byidentity.(chName{ii}).image.specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byidentity.(chName{ii}).image.specD{jj};
            dataEmotionTask = emotionTaskLFP.byidentity.(chName{ii}).image.specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllIdentities(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all identities for identity task
            dataEmotionTaskAllIdentities(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all identities for emotion task

            [nback.(chName{ii}).(idName{jj}).identityTaskMean, nback.(chName{ii}).(idName{jj}).emotionTaskMean...
                nback.(chName{ii}).(idName{jj}).identityTaskSD, nback.(chName{ii}).(idName{jj}).emotionTaskSD...
                nback.(chName{ii}).(idName{jj}).sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, dataEmotionTask, 'xshuffles', 50);
            %record if any significant clusters exist
            if sum(sum(nback.(chName{ii}).(idName{jj}).sigclust))>0
                significantComparisons{idxcomp,1} = chName{ii};
                significantComparisons{idxcomp,2} = idName{jj};
                idxcomp = idxcomp + 1;
            end

            idx1 = idx1 + trialcountID;
            idx2 = idx2 + trialcountEmot;
        end
        nback.(chName{ii}).allIdentities.identityTaskData = dataIdentityTaskAllIdentities; %store the data in case you want to evaluate it later
        nback.(chName{ii}).allIdentities.emotionTaskData = dataEmotionTaskAllIdentities;
        [nback.(chName{ii}).allIdentities.identityTaskMean, nback.(chName{ii}).allIdentities.emotionTaskMean...
            nback.(chName{ii}).allIdentities.identityTaskSD, nback.(chName{ii}).allIdentities.emotionTaskSD...
            nback.(chName{ii}).allIdentities.sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllIdentities, dataEmotionTaskAllIdentities, 'xshuffles', 50);
        if sum(sum(nback.(chName{ii}).allIdentities.sigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allIdentities';
            idxcomp = idxcomp + 1;
        end
        idx1 = 1;
        idx2 = 1;
        %this run goes compares the same emotion, compared for the identity
        %task against the emotion task (so same emotion, different attention)
        for jj = 1:numEmotions %goes through each emotion for both tasks
            trialcountID = size(identityTaskLFP.byemotion.(chName{ii}).image.specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byemotion.(chName{ii}).image.specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byemotion.(chName{ii}).image.specD{jj};
            dataEmotionTask = emotionTaskLFP.byemotion.(chName{ii}).image.specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllEmotions(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all emotions together for identity task
            dataEmotionTaskAllEmotions(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all emotions together for emotion task

            [nback.(chName{ii}).(emotName{jj}).identityTaskMean, nback.(chName{ii}).(emotName{jj}).emotionTaskMean...
                nback.(chName{ii}).(emotName{jj}).identityTaskSD, nback.(chName{ii}).(emotName{jj}).emotionTaskSD...
                nback.(chName{ii}).(emotName{jj}).sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, dataEmotionTask, 'xshuffles', 50);
            %record if any significant clusters exist
            if sum(sum(nback.(chName{ii}).(idName{jj}).sigclust))>0
                significantComparisons{idxcomp,1} = chName{ii};
                significantComparisons{idxcomp,2} = emotName{jj};
                idxcomp = idxcomp + 1;
            end
            idx1 = idx1 + trialcountID;
            idx2 = idx2 + trialcountEmot;
        end
        nback.(chName{ii}).allEmotions.identityTaskData = dataIdentityTaskAllEmotions; %store the data in case you want to evaluate it later
        nback.(chName{ii}).allEmotions.emotionTaskData = dataEmotionTaskAllEmotions;

        [nback.(chName{ii}).allEmotions.identityTaskMean, nback.(chName{ii}).allEmotions.emotionTaskMean...
            nback.(chName{ii}).allEmotions.identityTaskSD, nback.(chName{ii}).allEmotions.emotionTaskSD...
            nback.(chName{ii}).allEmotions.sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllIdentities, dataEmotionTaskAllIdentities, 'xshuffles', 50);
        %record if any significant clusters exist
        if sum(sum(nback.(chName{ii}).allEmotions.sigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allEmotions';
            idxcomp = idxcomp + 1;
        end
    end
end

%% compares condition vs iti derived from random time chunks grabbed throughout
if comparedToITI == 1
    %compares channel by channel
    %run through each channel and compare emotion to emotion and identity to
    %identity.
    %REMINDER: it is using non z scored data, so do that at the end
    %
    idxcomp=1;
    for ii = 1:length(chInterest)
        idx1 = 1;
        idx2 = 1;
        itiData = itiDataFilt.iti.(chName{ii}).specD;
        %this run compares the same identity, compared for the identity
        %task against the emotion task (so same face, different attention)
        for jj = 1:numIDs %goes through each identity (remember identity is the face, image refers to image vs response)
            trialcountID = size(identityTaskLFP.byidentity.(chName{ii}).image.specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byidentity.(chName{ii}).image.specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byidentity.(chName{ii}).image.specD{jj};
            dataEmotionTask = emotionTaskLFP.byidentity.(chName{ii}).image.specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllIdentities(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all identities for identity task
            dataEmotionTaskAllIdentities(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all identities for emotion task

            [nback.(chName{ii}).(idName{jj}).identityTaskMean, ~, ...
                nback.(chName{ii}).(idName{jj}).identityTaskSD, ~, ...
                nback.(chName{ii}).(idName{jj}).identityTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, itiData, 'xshuffles', 50);
            [nback.(chName{ii}).(idName{jj}).emotionTaskMean, ~,...
                nback.(chName{ii}).(idName{jj}).emotionTaskSD, ~, ...
                nback.(chName{ii}).(idName{jj}).emotionTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTask, itiData, 'xshuffles', 50);

            %record if any significant clusters exist
            if sum(sum(nback.(chName{ii}).(idName{jj}).identityTasksigclust))>0
                significantComparisons{idxcomp,1} = chName{ii};
                significantComparisons{idxcomp,2} = idName{jj};
                significantComparisons{idxcomp,3} = 'identityTask';
                idxcomp = idxcomp + 1;
            end

            if sum(sum(nback.(chName{ii}).(idName{jj}).emotionTasksigclust))>0
                significantComparisons{idxcomp,1} = chName{ii};
                significantComparisons{idxcomp,2} = idName{jj};
                significantComparisons{idxcomp,3} = 'emotionTask';
                idxcomp = idxcomp + 1;
            end

            idx1 = idx1 + trialcountID;
            idx2 = idx2 + trialcountEmot;
        end
        nback.(chName{ii}).allIdentities.identityTaskData = dataIdentityTaskAllIdentities; %store the data in case you want to evaluate it later
        nback.(chName{ii}).allIdentities.emotionTaskData = dataEmotionTaskAllIdentities;
        [nback.(chName{ii}).allIdentities.identityTaskMean, ~,...
            nback.(chName{ii}).allIdentities.identityTaskSD, ~,...
            nback.(chName{ii}).allIdentities.identityTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllIdentities, itiData, 'xshuffles', 50);
        [nback.(chName{ii}).allIdentities.emotionTaskMean, ~,...
            nback.(chName{ii}).allIdentities.emotionTaskSD, ~,...
            nback.(chName{ii}).allIdentities.emotionTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTaskAllIdentities, itiData, 'xshuffles', 50);
        if sum(sum(nback.(chName{ii}).allIdentities.identityTasksigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allIdentities';
            significantComparisons{idxcomp,3} = 'identityTask';
            idxcomp = idxcomp + 1;
        end
        if sum(sum(nback.(chName{ii}).allIdentities.emotionTasksigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allIdentities';
            significantComparisons{idxcomp,3} = 'emotionTask';
            idxcomp = idxcomp + 1;
        end
        idx1 = 1;
        idx2 = 1;
        %this run compares the same emotion, compared for the identity
        %task against the emotion task (so same emotion, different attention)
        for jj = 1:numEmotions %goes through each emotion for both tasks
            trialcountID = size(identityTaskLFP.byemotion.(chName{ii}).image.specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byemotion.(chName{ii}).image.specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byemotion.(chName{ii}).image.specD{jj};
            dataEmotionTask = emotionTaskLFP.byemotion.(chName{ii}).image.specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllEmotions(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all emotions together for identity task
            dataEmotionTaskAllEmotions(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all emotions together for emotion task

            [nback.(chName{ii}).(emotName{jj}).identityTaskMean, ~,...
                nback.(chName{ii}).(emotName{jj}).identityTaskSD, ~, ...
                nback.(chName{ii}).(emotName{jj}).identityTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, itiData, 'xshuffles', 50);
            [nback.(chName{ii}).(emotName{jj}).emotionTaskMean, ~,...
                nback.(chName{ii}).(emotName{jj}).emotionTaskSD, ~,...
                nback.(chName{ii}).(emotName{jj}).emotionTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTask, itiData, 'xshuffles', 50);

            %record if any significant clusters exist
            if sum(sum(nback.(chName{ii}).(emotName{jj}).identityTasksigclust))>0
                significantComparisons{idxcomp,1} = emotName{ii};
                significantComparisons{idxcomp,2} = emotName{jj};
                significantComparisons{idxcomp,3} = 'identityTask';
                idxcomp = idxcomp + 1;
            end

            if sum(sum(nback.(chName{ii}).(emotName{jj}).emotionTasksigclust))>0
                significantComparisons{idxcomp,1} = emotName{ii};
                significantComparisons{idxcomp,2} = emotName{jj};
                significantComparisons{idxcomp,3} = 'emotionTask';
                idxcomp = idxcomp + 1;
            end

            idx1 = idx1 + trialcountID;
            idx2 = idx2 + trialcountEmot;
        end
        nback.(chName{ii}).allEmotions.identityTaskData = dataIdentityTaskAllEmotions; %store the data in case you want to evaluate it later
        nback.(chName{ii}).allEmotions.emotionTaskData = dataEmotionTaskAllEmotions;
        [nback.(chName{ii}).allEmotions.identityTaskMean, ~,...
            nback.(chName{ii}).allEmotions.identityTaskSD, ~,...
            nback.(chName{ii}).allEmotions.identityTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllEmotions, itiData, 'xshuffles', 50);
        [nback.(chName{ii}).allEmotions.emotionTaskMean, ~,...
            nback.(chName{ii}).allEmotions.emotionTaskSD, ~,...
            nback.(chName{ii}).allEmotions.emotionTasksigclust] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTaskAllEmotions, itiData, 'xshuffles', 50);
        if sum(sum(nback.(chName{ii}).allEmotions.identityTasksigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allEmotions';
            significantComparisons{idxcomp,3} = 'identityTask';
            idxcomp = idxcomp + 1;
        end
        if sum(sum(nback.(chName{ii}).allEmotions.emotionTasksigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allEmotions';
            significantComparisons{idxcomp,3} = 'emotionTask';
            idxcomp = idxcomp + 1;
        end
    end
end


end