%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% NOISE TEST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%can turn on plotting for these, because it makes a lot of plots. However,
%hard to visualize, so easiest to create the plots and have a look.
%NOTE: right now the SD of 10 above seems to be about right, but also seems
%to 
%remove bad trials on emotion task

%save a copy of the tasks before the noise is removed
emotionTaskLFP_noNoiseRemoval = emotionTaskLFP;
identityTaskLFP_noNoiseRemoval = identityTaskLFP;
%plots each trial so you can remove noisey ones.
[Temot, allChannelMeanTemp] = proc.signalEval.noiseTestEmuNback(emotionTaskLFP, ...
     'taskNameSel', 1, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
dbstop
removeTrialsEmot = input('which lines from Temot do you want to remove. if no worrisome noise enter [], or if no figures output, means none crossed the threshold, so enter []'); %put the lines of the table Temot that you wan to remove in the commandline
for ii = 2:length(removeTrialsEmot) %check none were entered wrong
    if ii == length(removeTrialsEmot)
        if removeTrialsEmot(ii) < removeTrialsEmot(ii-1)
                    warning(['line ', num2str(removeTrialsEmot(ii)), 'is not ordered right and is next to ', num2str(removeTrialsEmot(ii-1))])
        end
    elseif removeTrialsEmot(ii) < removeTrialsEmot(ii-1) || removeTrialsEmot(ii) > removeTrialsEmot(ii+1)
        warning(['line ', num2str(removeTrialsEmot(ii)), 'is not ordered right and is next to ', num2str(removeTrialsEmot(ii-1))])
    end
end
%put the row of the ones you actually want to remove here.
emotionTaskLFP = Analysis.emuEmot.noiseRemoval(emotionTaskLFP, Temot, removeTrialsEmot, 'trialType', 2);
TNoise = Temot;
allChannelMean = allChannelMeanTemp;
%remove bad trials on identity
[Tident, allChannelMeanTemp] = proc.signalEval.noiseTestEmuNback(identityTaskLFP, ...
     'taskNameSel', 2, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
dbstop
removeTrialsId = input('which lines from Tident do you want to remove. if no worrisome noise enter [], or if no figures output, means none crossed the threshold, so enter []');  %put the lines of the table Tident that you wan to remove in the commandline
for ii = 2:length(removeTrialsId) %check none were entered wrong
    if ii == length(removeTrialsId)
        if removeTrialsId(ii) < removeTrialsId(ii-1)
                    warning(['line ', num2str(removeTrialsId(ii)), 'is not ordered right and is next to ', num2str(removeTrialsId(ii-1))])
        end
    elseif removeTrialsId(ii) < removeTrialsId(ii-1) || removeTrialsId(ii) > removeTrialsId(ii+1)
        warning(['line ', num2str(removeTrialsId(ii)), 'is not ordered right and is next to ', num2str(removeTrialsId(ii-1))])
    end
end
identityTaskLFP = Analysis.emuEmot.noiseRemoval(identityTaskLFP, Tident, removeTrialsId, 'trialType', 1);
TNoise = vertcat(TNoise, Tident);

%THERE IS AN ERROR IN THIS THAT HAS TO DO WITH SAVING AND I CAN'T FIGURE IT
%OUT
[TchannelCheckEm, itiDataReal.EmotionTask] = proc.signalEval.noiseTestEmuNBackITI(itiDataReal.EmotionTask, ...
    'taskNameSel', 1, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
[TchannelCheckId, itiDataReal.IdentityTask] = proc.signalEval.noiseTestEmuNBackITI(itiDataReal.IdentityTask, ...
    'taskNameSel', 2, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v2');





MWX.TNoise = TNoise;
MWX.TNoiseITIEm=TchannelCheckEm;
MWX.TNoiseITIId=TchannelCheckId;
MWX.RemovedEm = removeTrialsEmot;
MWX.RemovedId = removeTrialsId;
%allChannelMean = vertcat(allChannelMean, allChannelMeanTemp); %not necessary since this is just to see if a channel is bad.

%plot the periodogram for the mean of all trials across all channels to
%look for bad channels.
plotNoiseCheck = 1;
if plotNoiseCheck
   [subN1, subN2] = plt.subplotSize(length(chInterest));
    figure
    for cc=1:length(chInterest) %do all of the channels, go by 2 to get the spikes then the bands
        subplot(subN1, subN2, cc);        
        periodogram(allChannelMean(cc,:),[],size(allChannelMean,2), fs);
        title(num2str(chInterest(cc)))
    end
end
%turns out easiest way to eliminate a channel is to just ignore it.
removeChannel = input('which channels from the trial do you want to remove. if no worrisome noise enter [], or if no figures output, means none crossed the threshold, so enter []'); %put the lines of the table Temot that you wan to remove in the commandline
channelNameFinal = channelName;
%as you remove channels, you need to adjust, for now, just enter them in
%and delete, and should work.
for ii = 1:length(removeChannel)
%    channelNameFinal(42:47) = [];
end
%%
% next section Analysis.emuEmot.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT.M
edit Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT