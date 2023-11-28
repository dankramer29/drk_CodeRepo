function [T, dataLFP] = noiseTestEmuNBackITI(dataLFP, varargin)
%takes in the emotionLFP or identityLFP input and noise tests.


[varargin, stdAbove] = util.argkeyval('stdAbove',varargin, 5); %number of STDs above the mean something needs to be to flag the system
[varargin, plotNoiseCheckAll] = util.argkeyval('plotNoiseCheckAll',varargin, false); %plot the noise check or not
[varargin, flaggedplotNoiseCheck] = util.argkeyval('flaggedplotNoiseCheck',varargin, true); %plot the noise check or not
[varargin, taskNameSel] = util.argkeyval('taskNameSel',varargin, 1); %what is the type of task you are looking at. 1 is emotion task, 2 is identity task.
[varargin, savePlot] = util.argkeyval('savePlot', varargin, 1); %will save the figures as jpgs and close them so it's must smaller
[varargin, sessionName, ~, found]=util.argkeyval('sessionName', varargin, []);
[varargin, subjName, ~, found]=util.argkeyval('subjName', varargin, []);
[varargin, versionNum, ~, found]=util.argkeyval('versionNum', varargin, '_'); %if you want to do multiple versions of the same file

channelName = fieldnames(dataLFP);

if taskNameSel == 1
    taskType = 2;
    taskName = 'EmotionTask';
else
    taskType = 1;
    taskName = 'IdentityTask';
end

flaggedTrials = []; 
flaggedVariant = [];
flaggedChannel = []; 
flaggedTrialType = [];

tplotSp = 1:size(dataLFP.(channelName{1}).specD,2);
ff = 1:size(dataLFP.(channelName{1}).specD,1);
idxCh = 1;
F = figure;
F.WindowState = 'fullscreen';
F.Name = ([taskName, ' ', 'mean LFP across all ITI 1']);
sgtitle([taskName, ' ', 'mean LFP across all ITI 1'])
for kk = 1:25 %just put it on a 6x6 to look at them.
    if idxCh > length(channelName)
        break
    else
    sAll = dataLFP.(channelName{idxCh}).specD;
    meanS = mean(sAll,3);
    meanS = normalize(meanS,2);
    subplot(5,5,kk)
    imagesc(tplotSp, ff, meanS); axis xy; colorbar;
    title(channelName{idxCh})
    idxCh = idxCh +1;
    end
end
if savePlot
    if ~isempty(sessionName)
        hh =  findobj('type','figure');
        nh = length(hh);
        if taskNameSel == 1;
            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                'versionNum', 'v1_NoisecheckEmotionTask');
        elseif taskNameSel ==2; %THERE IS AN ERROR HERE THAT HAS TO DO WITH CLOSING THE PREVIOUS FIGURE, BUT DIDN'T HAVE TIME TO SORT THROUGH IT
            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                'versionNum', 'v1_NoisecheckIdentityTask');
        end
        close
    else
        saveas(F, 'jpg')
        close
    end
end
F = figure;
F.WindowState = 'fullscreen';
F.Name = ([taskName, ' ', 'mean LFP across all ITI 2']);
sgtitle([taskName, ' ', 'mean LFP across all ITI 2'])
for kk = 1:25 %just put it on a 6x6 to look at them. should cover the rest
    if idxCh > length(channelName)
        break
    else
    sAll = dataLFP.(channelName{idxCh}).specD;
    meanS = mean(sAll,3);
    meanS = normalize(meanS,2);
    subplot(5,5,kk)    
    imagesc(tplotSp, ff, meanS); axis xy; colorbar;
    title(channelName{idxCh})
    idxCh = idxCh +1;
    end
end
if savePlot
    if ~isempty(sessionName)
        hh =  findobj('type','figure');
        nh = length(hh);
        if taskNameSel == 1;
            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                'versionNum', 'v1_NoisecheckEmotionTask');
        elseif taskNameSel ==2;
            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                'versionNum', 'v1_NoisecheckIdentityTask');
        end
        close
    else
        saveas(F, 'jpg')
        close
    end
end

if idxCh < length(channelName) %incase more than 50 channels.
    F = figure;
    F.WindowState = 'fullscreen';
    F.Name = ([taskName, ' ', 'mean LFP across all ITI 3']);
    sgtitle([taskName, ' ', 'mean LFP across all ITI 3'])
    for kk = 1:25 %just put it on a 5x5 to look at them. should cover the rest
        if idxCh > length(channelName)
            break
        else
            sAll = dataLFP.(channelName{idxCh}).specD;
            meanS = mean(sAll,3);
            meanS = normalize(meanS,2);
            subplot(5,5,kk)
            imagesc(tplotSp, ff, meanS); axis xy; colorbar;
            title(channelName{idxCh})
            idxCh = idxCh +1;
        end
    end
    if savePlot
        if ~isempty(sessionName)
            hh =  findobj('type','figure');
            nh = length(hh);
            if taskNameSel == 1;
                plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                    'versionNum', 'v1_NoisecheckEmotionTask');
            elseif taskNameSel ==2;
                plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                    'versionNum', 'v1_NoisecheckIdentityTask');
            end
            close
        else
            saveas(F, 'jpg')
            close
        end
    end
end


%%
channelToCheck = input('input which channels to check in more detail, put [] if none');
channelToCheck = channelToCheck';
if isempty(channelToCheck)
    T = [];
    return
end

for ii = 1:length(channelToCheck)
    channelCheckTemp = ['ch', num2str(channelToCheck(ii))];
    channelIdxTemp = strcmp(channelCheckTemp, channelName);
    channelIdx(ii,1) = find(channelIdxTemp == 1);
end

%%
for cc = 1:length(channelIdx)
    F = figure;
    F.WindowState = 'fullscreen';
    F.Name = ([taskName, ' ', 'LFP by trial for ', channelName{channelIdx(cc)}, ' 1']);
    sgtitle([taskName, ' ', 'LFP by trial for ', channelName{channelIdx(cc)}, ' 1']);
    idxTrial = 1;
    for kk = 1:36 %just put it on a 5x5 to look at them. should cover the rest
        sTr = dataLFP.(channelName{channelIdx(cc)}).specD(:,:,idxTrial);%grab each trial
        meanS = normalize(sTr,2);
        subplot(6,6,kk)
        imagesc(tplotSp, ff, meanS); axis xy; colorbar;
        title('Trial ', num2str(idxTrial))
        idxTrial = idxTrial + 1;

    end
    if savePlot
        if ~isempty(sessionName)
            hh =  findobj('type','figure');
            nh = length(hh);
            if taskNameSel == 1;
                plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                    'versionNum', 'v1_NoisecheckEmotionTask');
            elseif taskNameSel ==2;
                plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                    'versionNum', 'v1_NoisecheckIdentityTask');
            end
            close 
        else
            saveas(F, 'jpg')
            close
        end
    end
    F = figure;
    F.WindowState = 'fullscreen';
    F.Name = ([taskName, ' ', 'LFP by trial for ', channelName{channelIdx(cc)}, ' 2']);
    sgtitle([taskName, ' ', 'LFP by trial for ', channelName{channelIdx(cc)}, ' 2']);

    for kk = 1:36 %just put it on a 5x5 to look at them. should cover the rest
        if idxTrial > size(dataLFP.(channelName{channelIdx(cc)}).specD,3)
            break
        else
            sTr = dataLFP.(channelName{channelIdx(cc)}).specD(:,:,idxTrial);%grab each trial
            meanS = normalize(sTr,2);
            subplot(6,6,kk)
            imagesc(tplotSp, ff, meanS); axis xy; colorbar;
            title('Trial ', num2str(idxTrial))
            idxTrial = idxTrial + 1;
        end
    end
    if savePlot
        if ~isempty(sessionName)
            hh =  findobj('type','figure');
            nh = length(hh);
            if taskNameSel == 1;
                plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                    'versionNum', 'v1_NoisecheckEmotionTask');
            elseif taskNameSel ==2;
                plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                    'versionNum', 'v1_NoisecheckIdentityTask');
            end
            close 
        else
            saveas(F, 'jpg')
            close
        end
    end
end

removeTrialsTable = zeros(length(channelIdx),size(dataLFP.(channelName{1}).specD,3));

for jj = 1:length(channelIdx)
    removeTrials = input(['which trials do you want to remove from ch ', num2str(channelToCheck(jj))]);
    trialAdj = 1;
    removeTrialsTemp = removeTrials;
    for ii = 1:size(removeTrials,2)
        if ii > 1   %need to adjust the trial count back one every time you remove one
            %from that channel and variant            
                removeTrialsTemp(ii) = removeTrials(ii)-trialAdj;
                trialAdj = trialAdj + 1;
        end
        dataLFP.(channelName{channelIdx(jj)}).specD(:,:,removeTrialsTemp(ii)) = [];
    end
    removeTrialsTable(jj,1:length(removeTrials)) = removeTrials;
end

taskType = repmat(taskName,size(channelToCheck,1),1);

T = table(taskType, channelToCheck, removeTrialsTable);

idxCh = 1;
F = figure;
F.WindowState = 'fullscreen';
F.Name = ([taskName, ' ', 'mean LFP across all ITI Noise Removed']);
sgtitle([taskName, ' ', 'mean LFP across all ITI Noise Removed'])

for kk = 1:25 %just put it on a 6x6 to look at them.
    if idxCh > length(channelIdx)
        break
    else
    sAll = dataLFP.(channelName{channelIdx(idxCh)}).specD;
    meanS = mean(sAll,3);
    meanS = normalize(meanS,2);
    subplot(5,5,kk)
    imagesc(tplotSp, ff, meanS); axis xy; colorbar;
    title(channelName{channelIdx(idxCh)})
    idxCh = idxCh +1;
    end
end
if savePlot
    if ~isempty(sessionName)
        hh =  findobj('type','figure');
        nh = length(hh);
        if taskNameSel == 1;
            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                'versionNum', 'v1_NoisecheckEmotionTask');
        elseif taskNameSel ==2;
            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                'versionNum', 'v1_NoisecheckIdentityTask');
        end
        close
    else
        saveas(F, 'jpg')
        close
    end
end


end