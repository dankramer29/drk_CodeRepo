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
[varargin, xshuffles]=util.argkeyval('xshuffles', varargin, 100); %number of shuffles for permutation test if needed
[varargin, threshold]=util.argkeyval('threshold', varargin, []); %if you are going to compare condition to iti (i.e. emotion task to random generated ITI) and have the thresholds done for comparison outside of this function
[varargin, eventChoice]=util.argkeyval('eventChoice', varargin, 1); %1 is when the image comes on, 2 is the response

if comparedToITI ==1
    if isempty(itiDataFilt)
        error('no iti data included')
    end
end


%% set up names for the struct
if ismatrix(chInterest)
    for ff=1:length(chInterest)
        ch = num2str(chInterest(ff));
        chName{ff} = ['ch' ch];
    end
elseif iscell(chInterest)
    chName = chInterest;
end

for ff=1:numIDs
    numstr = num2str(ff);
    idName{ff} = ['id' numstr];
end

for ff=1:numEmotions
    numstr = num2str(ff);
    emotName{ff} = ['emotion' numstr];
end

event = fieldnames(identityTaskLFP.byemotion.(chName{1}));


nback = struct;
significantComparisons = [];

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
            trialcountID = size(identityTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj};
            dataEmotionTask = emotionTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllIdentities(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all identities for identity task
            dataEmotionTaskAllIdentities(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all identities for emotion task

            [nback.(chName{ii}).(idName{jj}).identityTaskMean, nback.(chName{ii}).(idName{jj}).emotionTaskMean...
                nback.(chName{ii}).(idName{jj}).identityTaskSD, nback.(chName{ii}).(idName{jj}).emotionTaskSD...
                nback.(chName{ii}).(idName{jj}).sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, dataEmotionTask, 'xshuffles', xshuffles);
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
            nback.(chName{ii}).allIdentities.sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllIdentities, dataEmotionTaskAllIdentities, 'xshuffles', xshuffles);
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
            trialcountID = size(identityTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj};
            dataEmotionTask = emotionTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllEmotions(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all emotions together for identity task
            dataEmotionTaskAllEmotions(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all emotions together for emotion task

            [nback.(chName{ii}).(emotName{jj}).identityTaskMean, nback.(chName{ii}).(emotName{jj}).emotionTaskMean...
                nback.(chName{ii}).(emotName{jj}).identityTaskSD, nback.(chName{ii}).(emotName{jj}).emotionTaskSD...
                nback.(chName{ii}).(emotName{jj}).sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, dataEmotionTask, 'xshuffles', xshuffles);
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
            nback.(chName{ii}).allEmotions.sigclust] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllIdentities, dataEmotionTaskAllIdentities, 'xshuffles', xshuffles);
        %record if any significant clusters exist
        if sum(sum(nback.(chName{ii}).allEmotions.sigclust))>0
            significantComparisons{idxcomp,1} = chName{ii};
            significantComparisons{idxcomp,2} = 'allEmotions';
            idxcomp = idxcomp + 1;
        end
    end
end

%% compares condition vs iti derived from random time chunks grabbed throughout
%LOG IT, THEN TAKE THE MEAN OF THE ITI, THEN RUN CLUSTER STATS, THEN NORMALIZE 
if comparedToITI == 1
    %compares channel by channel
    %run through each channel and compare emotion to emotion and identity to
    %identity.
    %Using non z scored data
    idxcomp=1;
    for ii = 1:length(chInterest)
        idx1 = 1;
        idx2 = 1;
        itiDataId = itiDataFilt.IdentityTask.(chName{ii}).specD; %RUN THIS WITH THE ITI SHUFFLE DATA NOW FROM ONE ITI NOW. NEED TO CHANGE ALL THE REST IF THIS WORKS.
        itiDataEm = itiDataFilt.EmotionTask.(chName{ii}).specD; %RUN THIS WITH THE ITI SHUFFLE DATA NOW FROM ONE ITI NOW. NEED TO CHANGE ALL THE REST IF THIS WORKS.

        %this run compares the same identity, compared for the identity
        %task against the emotion task (so same face, different attention)
        for jj = 1:numIDs %goes through each identity (remember identity is the face, image refers to image vs response)
            trialcountID = size(identityTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj};
            dataEmotionTask = emotionTaskLFP.byidentity.(chName{ii}).(event{eventChoice}).specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllIdentities(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all identities for identity task
            dataEmotionTaskAllIdentities(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all identities for emotion task

            [nback.(chName{ii}).(idName{jj}).identityTaskMean, ~, ...
                nback.(chName{ii}).(idName{jj}).identityTaskSD, ~, ...
                nback.(chName{ii}).(idName{jj}).identityTasksigclust,...
                nback.(chName{ii}).(idName{jj}).identityTaskcentroid,...
                nback.(chName{ii}).(idName{jj}).identityTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, itiDataId, 'xshuffles', xshuffles);
            
            [nback.(chName{ii}).(idName{jj}).emotionTaskMean, ~,...
                nback.(chName{ii}).(idName{jj}).emotionTaskSD, ~, ...
                nback.(chName{ii}).(idName{jj}).emotionTasksigclust,...
                nback.(chName{ii}).(idName{jj}).emotionTaskcentroid,...
                nback.(chName{ii}).(idName{jj}).emotionTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTask, itiDataEm, 'xshuffles', xshuffles);

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
            nback.(chName{ii}).allIdentities.identityTasksigclust,...
                nback.(chName{ii}).allIdentities.identityTaskcentroid,...
                nback.(chName{ii}).allIdentities.identityTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllIdentities, itiDataId, 'xshuffles', xshuffles);
        [nback.(chName{ii}).allIdentities.emotionTaskMean, ~,...
            nback.(chName{ii}).allIdentities.emotionTaskSD, ~,...
            nback.(chName{ii}).allIdentities.emotionTasksigclust,...
                nback.(chName{ii}).allIdentities.emotionTaskcentroid,...
                nback.(chName{ii}).allIdentities.emotionTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTaskAllIdentities, itiDataEm, 'xshuffles', xshuffles);
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
            trialcountID = size(identityTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            trialcountEmot = size(emotionTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj}, 3);
            if trialcountID ~= trialcountEmot
                warning('trialcount different between same presentations between tasks')
            end

            dataIdentityTask = identityTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj};
            dataEmotionTask = emotionTaskLFP.byemotion.(chName{ii}).(event{eventChoice}).specD{jj};
            %create a matrix with all of the identities/emotions stacked so you
            %can process them as one
            dataIdentityTaskAllEmotions(:,:,idx1:idx1+trialcountID-1) = dataIdentityTask; %has all emotions together for identity task
            dataEmotionTaskAllEmotions(:,:,idx2:idx2+trialcountEmot-1) = dataEmotionTask; %has all emotions together for emotion task

            [nback.(chName{ii}).(emotName{jj}).identityTaskMean, ~,...
                nback.(chName{ii}).(emotName{jj}).identityTaskSD, ~, ...
                nback.(chName{ii}).(emotName{jj}).identityTasksigclust,...
                nback.(chName{ii}).(emotName{jj}).identityTaskcentroid,...
                nback.(chName{ii}).(emotName{jj}).identityTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTask, itiDataId, 'xshuffles', xshuffles);
            [nback.(chName{ii}).(emotName{jj}).emotionTaskMean, ~,...
                nback.(chName{ii}).(emotName{jj}).emotionTaskSD, ~,...
                nback.(chName{ii}).(emotName{jj}).emotionTasksigclust,...
                nback.(chName{ii}).(emotName{jj}).emotionTaskcentroid,...
                nback.(chName{ii}).(emotName{jj}).emotionTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTask, itiDataEm, 'xshuffles', xshuffles);

            %record if any significant clusters exist
            if sum(sum(nback.(chName{ii}).(emotName{jj}).identityTasksigclust))>0
                significantComparisons{idxcomp,1} = chName{ii};
                significantComparisons{idxcomp,2} = emotName{jj};
                significantComparisons{idxcomp,3} = 'identityTask';
                idxcomp = idxcomp + 1;
            end

            if sum(sum(nback.(chName{ii}).(emotName{jj}).emotionTasksigclust))>0
                significantComparisons{idxcomp,1} = chName{ii};
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
            nback.(chName{ii}).allEmotions.identityTasksigclust,...
                nback.(chName{ii}).allEmotions.identityTaskcentroid,...
                 nback.(chName{ii}).allEmotions.identityTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataIdentityTaskAllEmotions, itiDataId, 'xshuffles', xshuffles);
        [nback.(chName{ii}).allEmotions.emotionTaskMean, ~,...
            nback.(chName{ii}).allEmotions.emotionTaskSD, ~,...
            nback.(chName{ii}).allEmotions.emotionTasksigclust,...
                nback.(chName{ii}).allEmotions.emotionTaskcentroid,...
                nback.(chName{ii}).allEmotions.emotionTasktstatSum] = stats.cluster_permutation_Ttest_gpu3d( dataEmotionTaskAllEmotions, itiDataEm, 'xshuffles', xshuffles);
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