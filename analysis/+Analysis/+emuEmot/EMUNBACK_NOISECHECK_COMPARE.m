%THIS IS BOTH NOISE TEST AND COMPARE WITHIN PATIENTS, I SPLIT IT UP, NO
%NEED FOR THIS ANYMORE SO DON'T USE

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
removeTrialsEmot = input('which lines from Temot do you want to remove '); %put the lines of the table Temot that you wan to remove in the commandline
%put the row of the ones you actually want to remove here.
emotionTaskLFP = Analysis.emuEmot.noiseRemoval(emotionTaskLFP, Temot, removeTrialsEmot, 'trialType', 2);
TNoise = Temot;
allChannelMean = allChannelMeanTemp;
[Tident, allChannelMeanTemp] = proc.signalEval.noiseTestEmuNback(identityTaskLFP, ...
    channelName, 'taskNameSel', 2, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
removeTrialsId = input('which lines from Tident do you want to remove '); %put the lines of the table Tident that you wan to remove in the commandline
identityTaskLFP = Analysis.emuEmot.noiseRemoval(identityTaskLFP, Tident, removeTrialsId, 'trialType', 1);
TNoise = vertcat(TNoise, Tident);

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
removeChannel = [];
channelNameFinal = channelName;
for ii = 1:length(removeChannel)
    channelNameFinal(removeChannel(ii)) = [];
end
%%
%% figure out which trial started first
%1 means it was the second trial, 0 means it was the first.
if trialStartTimeId > trialStartTimeEm
    identityTaskLFP.secondTrial = 1;
    emotionTaskLFP.secondTrial = 0;
else
    identityTaskLFP.secondTrial = 0;
    emotionTaskLFP.secondTrial = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create a table for the stats for all trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii =1:(length(CorrectTrialsEm))
    PatientName{ii,1} = subjName;
    TrialType{ii,1} = 'emotionTask';
    SecondTrial(ii,1) = emotionTaskLFP.secondTrial;
    TrialNumber(ii,1) = ii;
    ImageTypeEmotion(ii,1) = PresentedEmotionIdxEm(ii);
    ImageTypeIdentity(ii,1) = PresentedIdentityIdxEm(ii);
    CorrectResponse(ii,1) = CorrectTrialsEm(ii);
    ResponseTime(ii,1) = ResponseTimesDiffEmotion(ii)/1e6;
end
statsAllTrialsEm = table(PatientName, TrialType, SecondTrial,...
    TrialNumber, ImageTypeEmotion, ImageTypeIdentity,...
    CorrectResponse, ResponseTime);

clear PatientName TrialType SecondTrial...
    TrialNumber ImageTypeEmotion ImageTypeIdentity...
    CorrectResponse ResponseTime

for ii =1:(length(CorrectTrialsId))
    PatientName{ii,1} = subjName;
    TrialType{ii,1} = 'identityTask';
    SecondTrial(ii,1) = identityTaskLFP.secondTrial;
    TrialNumber(ii,1) = ii;
    ImageTypeEmotion(ii,1) = PresentedEmotionIdxId(ii);
    ImageTypeIdentity(ii,1) = PresentedIdentityIdxId(ii);
    CorrectResponse(ii,1) = CorrectTrialsId(ii);
    ResponseTime(ii,1) = ResponseTimesDiffIdentity(ii)/1e6;
end
statsAllTrialsId = table(PatientName, TrialType, SecondTrial,...
    TrialNumber, ImageTypeEmotion, ImageTypeIdentity,...
    CorrectResponse, ResponseTime);


MW13.statsAllTrials = vertcat(statsAllTrialsEm, statsAllTrialsId);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compare the tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  allEmotions and allIdentities are the same since it's just all images
%  shown
[nbackCompareImageOn, sigComparisonImageOn] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP,...
    'chInterest', channelNameFinal, 'itiDataFilt', itiDataReal, 'xshuffles', xshuffles, 'eventChoice', 1);
[nbackCompareResponse, sigComparisonResponse] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP,...
    'chInterest', channelNameFinal, 'itiDataFilt', itiDataReal, 'xshuffles', xshuffles, 'eventChoice', 1);


%% plotting
ttImage = identityTaskLFP.tPlotImage;
ff = itiDataFiltIdentity.freq;
ttResponse = identityTaskLFP.tPlotResponse;

if DoPlot
    close all %need to close all other figures so the figures 
    comparisonName = 'Image On';
    plt.nbackPlotSpectrogram(nbackCompareImageOn,'timePlot', ttImage, 'frequencyRange', ff, ...
        'chName', chLocationName, 'comparison', 1, 'figTitleName', comparisonName); %comparison 1 is emot task compared to id task, 2 is half set up to just show one subtracted from the other
    comparisonName = 'Response';
    plt.nbackPlotSpectrogram(nbackCompareResponse,'timePlot', ttResponse, 'frequencyRange', ff, ...
        'chName', chLocationName, 'comparison', 1, 'figTitleName', comparisonName); %comparison 1 is emot task compared to id task, 2 is half set up to just show one subtracted from the other
end

%% create a table to that can be combined for all patients regarding statistically significant clusters.
%timeMinMax and freqMinMax are to capture only significant epochs in those
%frequency bands during that period of time (so like 50 to 150 hz
%significant epochs that are between 100 and 900 ms). 
[MW13.SigClusterSummStats] = Analysis.emuEmot.comparePowerResponseTime(nbackCompareImageOn, ...
    identityTaskLFP, emotionTaskLFP, 'timeMinMax', [.1 .9], 'freqMinMax', [50 150],...
    'chName', chLocationName, 'patientName', subjName);


%% save plots

%savePlot = 0; %toggle on if you want to save the plots up front, probably
%better to look at them individually first THE TOGGLE IS REPEATED HERE FOR
%EASE OF TOGGLING ON IF YOU WANT.
if savePlot
    hh =  findobj('type','figure'); 
    nh = length(hh);
    plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1');
end

%% for saving. probably easier to do by hand
% So save these variables with these names
% MW13_itiDataFiltEmotion
% MW13_itiDataFiltIdentity
% MW13_emotionTaskLFP
% MW13_identityTaskLFP
% MW13_itiDataReal
% MW13_nbackCompareImageOn
% MW13_nbackCompareResponse
% MW13_AllPatientsSigClusterSummStats
if saveSelectFile
    folder_create=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName);    
    folder_name=strcat(folder_create, '\', subjName, '\', mat2str(chInterest), '_', date);  
    if ~isfolder(folder_name)
        %make the directory folder
        mkdir (folder_name)
    end
    fileName = [folder_name, '\', 'itiDataFiltIdentity', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'itiDataFiltEmotion', '.mat'];    save(fileName, '-v7.3');    
    fileName = [folder_name, '\', 'emotionTaskLFP', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'identityTaskLFP', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'itiDataReal', '.mat'];    save(fileName, '-v7.3');

    
    fileName = [folder_name, '\', 'nbackCompareImageOn', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'nbackCompareResponse', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'MW13', '.mat'];    save(fileName, '-v7.3');

    
end


%% summary stats per patient across all trials
%use EMUNBACK_COMPAREACROSSPATIENTS
