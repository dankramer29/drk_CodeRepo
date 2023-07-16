%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% NOISE TEST
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%can turn on plotting for these, because it makes a lot of plots. However,
%hard to visualize, so easiest to create the plots and have a look.
%NOTE: right now the SD of 10 above seems to be about right, but also seems
%to 

[Temot, allChannelMeanTemp] = proc.signalEval.noiseTestEmuNback(emotionTaskLFP, ...
    channelName, 'taskNameSel', 1, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
dbstop
removeTrialsEmot = input('which lines from Temot do you want to remove. if no worrisome noise enter [], or if no figures output, means none crossed the threshold, so enter []'); %put the lines of the table Temot that you wan to remove in the commandline
%put the row of the ones you actually want to remove here.
emotionTaskLFP = Analysis.emuEmot.noiseRemoval(emotionTaskLFP, Temot, removeTrialsEmot, 'trialType', 2);
TNoise = Temot;
allChannelMean = allChannelMeanTemp;
[Tident, allChannelMeanTemp] = proc.signalEval.noiseTestEmuNback(identityTaskLFP, ...
    channelName, 'taskNameSel', 2, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
dbstop
removeTrialsId = input('which lines from Tident do you want to remove. if no worrisome noise enter [], or if no figures output, means none crossed the threshold, so enter []');  %put the lines of the table Tident that you wan to remove in the commandline
identityTaskLFP = Analysis.emuEmot.noiseRemoval(identityTaskLFP, Tident, removeTrialsId, 'trialType', 1);
TNoise = vertcat(TNoise, Tident);

MWX.TNoise = TNoise;
MWX.RemovedEm = removeTrialsEmot;
MWX.RemovedId = removeTrialsId;
%allChannelMean = vertcat(allChannelMean, allChannelMeanTemp); %not necessary since this is just to see if a channel is bad.

%plot the periodogram for the mean of all trials across all channels to
%look for bad channels.
plotNoiseCheck = 1;
if plotNoiseCheck
   [subN1, subN2] = plt.subplotSize(length(channelName));
    figure
    for cc=1:length(channelName) %do all of the channels, go by 2 to get the spikes then the bands
        subplot(subN1, subN2, cc);        
        periodogram(allChannelMean(cc,:),[],size(allChannelMean,2), fs);
        title(channelName{cc})
    end
end
%turns out easiest way to eliminate a channel is to just ignore it.
removeChannel = input('which channels from the trial do you want to remove. if no worrisome noise enter [], or if no figures output, means none crossed the threshold, so enter []'); %put the lines of the table Temot that you wan to remove in the commandline
channelNameFinal = channelName;
for ii = 1:length(removeChannel)
    channelNameFinal(removeChannel(ii)) = [];
end
%%
% next section Analysis.emuEmot.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT.M
edit EMUNBACK_WITHINCOMPARISON_PLOT.M