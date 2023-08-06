%% figure out which trial started first

%THINGS TO DO. NOT 100% SURE IT'S CAPTURING SIGNIFICANT AREAS FOR
%INDIVIDUAL EMOTIONS/IDS. 

%%%%%%%%
%CHANGE MWx BELOW BEFORE SAVIN!
%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create a table for the stats for all trials
%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ii =1:(length(CorrectTrialsEm))
    PatientName{ii,1} = subjName;
    TrialType{ii,1} = 'emotionTask';
    TrialNumber(ii,1) = ii;
    ImageTypeEmotion(ii,1) = PresentedEmotionIdxEm(ii);
    ImageTypeIdentity(ii,1) = PresentedIdentityIdxEm(ii);
    CorrectResponse(ii,1) = CorrectTrialsEm(ii);
    ResponseTime(ii,1) = ResponseTimesDiffEmotion(ii)/1e6;
end
statsAllTrialsEm = table(PatientName, TrialType, ...
    TrialNumber, ImageTypeEmotion, ImageTypeIdentity,...
    CorrectResponse, ResponseTime);

clear PatientName TrialType SecondTrial...
    TrialNumber ImageTypeEmotion ImageTypeIdentity...
    CorrectResponse ResponseTime

for ii =1:(length(CorrectTrialsId))
    PatientName{ii,1} = subjName;
    TrialType{ii,1} = 'identityTask';
    TrialNumber(ii,1) = ii;
    ImageTypeEmotion(ii,1) = PresentedEmotionIdxId(ii);
    ImageTypeIdentity(ii,1) = PresentedIdentityIdxId(ii);
    CorrectResponse(ii,1) = CorrectTrialsId(ii);
    ResponseTime(ii,1) = ResponseTimesDiffIdentity(ii)/1e6;
end
statsAllTrialsId = table(PatientName, TrialType, ...
    TrialNumber, ImageTypeEmotion, ImageTypeIdentity,...
    CorrectResponse, ResponseTime);


MWX.statsAllTrials = vertcat(statsAllTrialsEm, statsAllTrialsId);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compare the tasks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  allEmotions and allIdentities are the same since it's just all images
%  shown
tTot = tic;
[nbackCompareImageOn, sigComparisonImageOn] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP,...
    'chInterest', channelNameFinal, 'itiDataFilt', itiDataReal, 'xshuffles', xshuffles, 'eventChoice', 1);
[nbackCompareResponse, sigComparisonResponse] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP,...
    'chInterest', channelNameFinal, 'itiDataFilt', itiDataReal, 'xshuffles', xshuffles, 'eventChoice', 1);
toc(tTot)

%% plotting
ttImage = identityTaskLFP.tPlotImage;
ff = itiDataFiltIdentity.freq;
ttResponse = identityTaskLFP.tPlotResponse;

if DoPlot
    close all %need to close all other figures so the figures 
    comparisonName = 'Image On';
    figIdx = 1;
    [figIdxNow] = plt.nbackPlotSpectrogram(nbackCompareImageOn,'timePlot', ttImage, 'frequencyRange', ff, ...
        'chName', chLocationName, 'comparison', 1, 'figTitleName', comparisonName, 'figIdx', figIdx); %comparison 1 is emot task compared to id task, 2 is half set up to just show one subtracted from the other
    comparisonName = 'Response';
    plt.nbackPlotSpectrogram(nbackCompareResponse,'timePlot', ttResponse, 'frequencyRange', ff, ...
        'chName', chLocationName, 'comparison', 1, 'figTitleName', comparisonName, 'figIdx', figIdxNow); %comparison 1 is emot task compared to id task, 2 is half set up to just show one subtracted from the other
end

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

savePlotSpecificMat = false;
if savePlotSpecificMat
    nS = [7,8,17,18,19,20,41,42,43,44,65,66,67,68,91,92,93,94];
    plt.save_plots(nS, 'sessionName', sessionName, 'subjName', subjName, ...
        'versionNum', 'v1', 'plotType', 'm');
end

%% create a table to that can be combined for all patients regarding statistically significant clusters.
%timeMinMax and freqMinMax are to capture only significant epochs in those
%frequency bands during that period of time (so like 50 to 150 hz
%significant epochs that are between 100 and 900 ms). 
[MWX.SigClusterSummStats] = Analysis.emuEmot.comparePowerResponseTime(nbackCompareImageOn, ...
    identityTaskLFP, emotionTaskLFP, 'timeMinMax', [.1 .9], 'freqMinMax', [50 150],...
    'chName', chLocationName, 'patientName', subjName);




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

%%%%
MW19 = MWX;
%%%%
if saveSelectFile
    folder_create=strcat('Z:\KramerEmotionID_2023\Data\EMU_nBack', '\', sessionName);    
    folder_name=strcat(folder_create, '\', subjName, '\', mat2str(chInterest), '_', date);  
    if ~isfolder(folder_name)
        %make the directory folder
        mkdir(folder_name)
    end
    fileName = [folder_name, '\', 'MW19_itiDataFiltIdentity', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'MW19_itiDataFiltEmotion', '.mat'];    save(fileName, '-v7.3');    
    fileName = [folder_name, '\', 'MW19_emotionTaskLFP', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'MW19_identityTaskLFP', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'MW19_itiDataReal', '.mat'];    save(fileName);

    
    fileName = [folder_name, '\', 'MW19_nbackCompareImageOn', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'MW19_nbackCompareResponse', '.mat'];    save(fileName, '-v7.3');
    fileName = [folder_name, '\', 'MW19', '.mat'];    save(fileName);
    
end


%% summary stats per patient across all trials
%use EMUNBACK_COMPAREACROSSPATIENTS