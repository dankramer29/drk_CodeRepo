%% major script for running the processing of an individual patient
%%
% EMUNBACK_PROC


% Structure: image 1 on, then off with fixation
% cross on, then image 2 on and response about same/different at any time
% after that, but then image off, fixation on, then image 3 and decision
% about if 2 and 3 were the same. TTLs are image on (TTL 2) then next image (TTL 4)
% and back and forth like that. The other TTL is some TTL artifact like TTL
% off. CorrectResponse is the right answer and Response is if the images matched
% (1) or didn't match (0) (i.e. if they are correct CorrectResponse ==
% Response)

%Timestamps: There are two clocks, the first clock from the psychtoolbox is
%from the "now" command (stores that output) at each timestamp (e.g.
%ImageTimes). the second is date time, but is in microseconds
%(beh_timestamps, but it's 500 samples/second and 1000ms/second, so
%essentially on the clock, 500,000 clock ticks pass each 1 second).
%ImageTimes(1) == beh_timestamps(2). Double checked and the psychtoolbox
%output for ImageTimes can be up to 0.015 seconds. TTLs are very on, but
%not necessarily behaviorally relevant.


%% Event files
%MW3_Session14_filter.nwb (NBack Emotion): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3_Session12_filter.nwb (NBack Identity): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3
%chInterest = [69, 77, 148];
%(MW3_Session11_filter.nwb = MW3_Session12_filter.nwb but the filtering is
%better)

% MW13_Session_9_filter.nwb — NBack_IDENTITY_2022_5_29…
% MW13_Session_10_filter.nwb — NBack_EMOTION_2022_5_29…
%run the script to pull in the data from nwb if needed



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% change the details for each patient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%MW13
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

preSpectrogramData = true; %either chop the data as already multitapered and then cut it up (true) or as raw voltage, cut it up, then process it by multitaper (false)
alreadyFilteredData = false; %toggle to true if you've run the entire dataset through LFP processing already and saved it.

sessionName = '5_29_2022session';
subjName = 'MW13';

MW13 = struct;

matNameEm = 'NBack_EMOTION_2022_5_29.18_10_57_BLIND.mat';
matNameId = 'NBack_IDENTITY_2022_5_29.18_5_50_BLIND.mat';
emotionFilter = 'MW13_Session_10_filter.nwb';
identityFilter = 'MW13_Session_9_filter.nwb';

%% setup details of the processing
fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s

%time in seconds to add before and after the events
preTime = 0.5; %time before and after image on
postTime = 2; 
preTimeRes = 1; %time befoe and after response
postTimeRes = 0.5;
% sets the shuffling parameters, so it's stitching post multi-tapered data,
% then smoothing it.
multiTaperWindow = .2; % in seconds, what window you are doing on this run for multitapering spectrograms (mtspectrogramc, also option to do pspectrum, but haven't used it)
xshuffles = 1000; %change the number of shuffles. 100 is a nice number to test data with, 500 or 1000 when it's ready for running completed.
DoPlot = 1; %toggle plotting on or off
savePlot = 0; %toggle on if you want to save the plots up front, probably better to look at them individually first
saveSelectFile = 0; %toggle on if you want to save all the files. probably best to do by hand
%NO LONGER USING THE BELOW
% shuffleLength = .05; %in seconds, the length of the stitched shuffles
% stitchTrialNum = 100; %number of trials to make the stitching out of.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% START OF EMOTION PROCESSING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
taskName = 'Emotion';
folderName=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName, '\', taskName, '\', matNameEm);

%%
% set to 0 if running this with a new data set for the first time, set to
% 1 if you saved the filtered data after running
% Analysis.emuEmot.nwbLFPchProc and don't want to keep running it
%Set up if you are saving and then loading the filtered data
rawData = false; %PREVIOUSLY COULD DO RAWDATA, STILL CAN BUT I REMOVED IT TO REDUCE CLUTTER

if alreadyFilteredData    
        load('C:\Users\kramdani\Documents\Data\EMU_nBack\5_29_2022session\Identity\allDataFiltered_IdentityTaskCh17_25_45_61_75_83_97.mat');
        load('C:\Users\kramdani\Documents\Data\EMU_nBack\5_29_2022session\Emotion\allDataFiltered_EmotionTaskCh17_25_45_61_75_83_97.mat');
else
    itiDataFiltEmotion = [];
    itiDataFiltIdentity = [];
end

%% Load NWB
% Emotion
testfile = nwbRead(emotionFilter);


run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
load(folderName)
nbackData.task = matchStr;

%% pull in wire ids
%pull wire numbers and wire ids
eleCtable = testfile.general_extracellular_ephys_electrodes.vectordata;

channID = eleCtable.get('channID').data.load();
hemis = cellstr(eleCtable.get('hemisph').data.load());
label = cellstr(eleCtable.get('label').data.load());
location = cellstr(eleCtable.get('location').data.load());
macroROWS = contains(label,'MA_');
macro_hemi = hemis(macroROWS);
macro_location = location(macroROWS);
%macro_wire = wireID(macroROWS);
wireID = testfile.general_extracellular_ephys_electrodes.vectordata.get('wireID').data.load();  
shortBAn = testfile.general_extracellular_ephys_electrodes.vectordata.get('shortBAn').data.load(); 

%number the channels on an electrode for easier assessment of which ones to
%pull
idx = 2;
channelNumber(1) = 1;
for ii = 2:length(wireID)   
    if wireID(ii,1)==wireID(ii-1,1)
        channelNumber(ii,1) = idx;
        idx = idx + 1;
    elseif wireID(ii,1) ~= wireID(ii-1,1)        
        idx = 1;
        channelNumber(ii,1) = idx;
        idx = idx + 1;
    end
end

TableChannel = table(location, hemis, macroROWS, label, channID, channelNumber, shortBAn, wireID);

%%%%%%%%%%%%%%%%%%%%%%%%%
%% change channels here %
%%%%%%%%%%%%%%%%%%%%%%%%%
chInterest = [17,18,26,69,77,78,79,59,60,83,89,90,91,126,127,129,130,93,94,95];
%chInterest = [1 9 29 45 59 67 81 139];
%chInterest = [7, 8, 15 16, 27, 28];  %REMEMBER, PMT OR DIXI HAVE 1 AS DISTAL (confirmed, REALLY IT'S THAT THE TECHS PUT 1 AS THE FARTHEST CHANNEL ON CHANNEL ID SO DOESNT MATTER WHAT BRAND)
%[2, 10, 30, 46, 60, 68, 82, 119, 120, 140 ];
%chInterest = [17,25,45,61,75,83,97];


%setup for accessing channels
%channels in dixi and pmt are 1=distal contact, adtech is 1=proximal

for ff=1:length(chInterest)
    ch = num2str(chInterest(ff));
    channelName{ff} = ['ch' ch];
    str = location(channID ==chInterest(ff));
    strout = plt.lowup(str); %converts to upper case for plotting later
    chLocationName{ff,1} = strcat(hemis(channID == chInterest(ff)), {' '}, strout);
end

%% common average rerefernce
macrowiresCAR = double(macrowires) - repmat(nanmean(macrowires,1), size(macrowires,1),1);

%% run a noise/artifact rejection
% UH DID NOT GET AROUND TO DOING THIS FULLY


%% low pass the data (nyquist 250)
lpFilt = designfilt('lowpassiir','FilterOrder',8, ...
'PassbandFrequency',200,'PassbandRipple',0.2, ...
'SampleRate',500);

%cut data to channels of interest
data = double(macrowiresCAR(chInterest, :));

%lowpass filter
dataFemotion = filtfilt(lpFilt,data');

%% find the behavioral timestamps
%downsamle the timestamps (ma_timestamps comes from the nwb as well)
ma_timestampsDS=downsample(ma_timestamps, 8);

%% 
% set up the behavioral timestamps to ensure they are the presentation of
% the image
idx1 = 1; idx2 = 1;
for ii=2:length(beh_timestamps)
    timeStampDiff(idx1) = beh_timestamps(ii)-beh_timestamps(ii-1);    
    if timeStampDiff(idx1) >= 499001 && timeStampDiff(idx1) <= 500999 %50000/500 = 1000ms
        imageOn(idx2) = ii-1; %record the relevant image onsets, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (THIS APPEARS CONFIRMED)
        idx2 = idx2 + 1;
    end
    idx1 = idx1 +1;
end

% find the timestamp conversion of the phys data and the psychtoolbox data
ttl_beh = beh_timestamps(imageOn); %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on

ImageTimesDiff = (ImageTimes-TTLTimes)*24*60*60*1e6; %convert to microseconds
ImageTimesAdjEm = ttl_beh+ImageTimesDiff; %moves the time into neural time scale

ResponseTimesDiffEmotion = (ResponseTimes-TTLTimes)*24*60*60*1e6;
itiTimeEmotion = (ImageTimes(3:end)-ResponseTimes(2:end-1))*24*60*60;
ResponseTimesAdjEm = ttl_beh+ResponseTimesDiffEmotion; %moves the time into neural time scale

%find if the responses were correct or not
Response(isnan(Response)) = [];
CorrectTrialsEm = CorrectResponse == Response;

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS); %finds the ttl
[behavioralIndexImageOnEm, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjEm, ma_timestampsDS); %finds the image onset which is more accurate
[behavioralIndexResponseEm, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjEm, ma_timestampsDS); %finds the response time

trialStartTimeEm = testfile.session_start_time;

%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
%THIS IS A CHOICE TO REMOVE DATA TO DECREASE THE TIME OF THE RECORDING, NOT
%CURRENTLY USING BUT COULD.
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
preStartData = dataFemotion; %can adjust if want to exclude part of the data
%filters the entire trial.
if alreadyFilteredData == 0
    [itiDataFiltEmotion] = Analysis.emuEmot.nwbLFPchProcITI(preStartData, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
end

PresentedEmotionIdxEm = PresentedEmotionIdx;
PresentedIdentityIdxEm = PresentedIdentityIdx;

%% process data with main proc function (see above to set this)
%this will break up the data. Can adjust the spectrogram window center
%point here (so beginning (1), middle(2), or end(3) of the moving window)
%the final filtered data (1to200) is broad so it can be inserted into PAC
%as desired

[emotionTaskLFP, itiDataReal.EmotionTask] = Analysis.emuEmot.nwbLFPchProc(itiDataFiltEmotion, PresentedEmotionIdxEm,...
    PresentedIdentityIdxEm, behavioralIndexImageOnEm, behavioralIndexResponseEm, ...
    'fs', fs, 'chNum', chInterest, 'itiTime', itiTimeEmotion,...
    'ImpreTime', preTime, 'ImpostTime', postTime, 'RespreTime', preTimeRes, 'RespostTime', postTimeRes, 'multiTaperWindow',...
    multiTaperWindow, 'CorrectTrials', CorrectTrialsEm, 'ResponseTimesAdj', ResponseTimesDiffEmotion);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% second set of data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Identity run
taskName = 'Identity';

folderName=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName, '\', taskName, '\', matNameId);

     %   testfile = nwbRead('MW3_Session_11_filter.nwb');
            testfile = nwbRead(identityFilter);
run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
%mw3
%load('C:\Users\kramdani\Documents\Data\EMU_nBack\4_12_2022session\FacialRecSession\NBack_2021_05_04.12_43_46_BLIND.mat')
%mw13
load(folderName)
nbackData.task = matchStr;


%% common average rerefernce
macrowiresCAR = double(macrowires) - repmat(nanmean(macrowires,1), size(macrowires,1),1);

%% low pass the data (nyquist 250)
lpFiltlow = designfilt('lowpassiir','FilterOrder',8, ...
'PassbandFrequency',200,'PassbandRipple',0.2, ...
'SampleRate',fs);

%cut data to channels of interest
data = double(macrowiresCAR(chInterest, :));

%lowpass filter
dataFidentity = filtfilt(lpFiltlow,data');


%% find the behavioral timestamps
%downsamle the timestamps
ma_timestampsDS=downsample(ma_timestamps, 8);

%% 
% set up the behavioral timestamps to ensure they are the presentation of
% the image
idx1 = 1; idx2 = 1;
for ii=2:length(beh_timestamps)
    timeStampDiff(idx1) = beh_timestamps(ii)-beh_timestamps(ii-1);    
    if timeStampDiff(idx1) >= 499001 && timeStampDiff(idx1) <= 500999 %50000/500 = 1000ms
        imageOn(idx2) = ii-1; %record the relevant image onsets, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (this is possibly not true!)
        idx2 = idx2 + 1;
    end
    idx1 = idx1 +1;
end

% find the timestamp conversion of the phys data and the psychtoolbox data
ttl_beh = beh_timestamps(imageOn); %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on

ImageTimesDiff = (ImageTimes-TTLTimes)*24*60*60*1e6; %convert to microseconds
ImageTimesAdjId = ttl_beh+ImageTimesDiff; %moves the time into neural time scale

ResponseTimesDiffIdentity = (ResponseTimes-TTLTimes)*24*60*60*1e6;
itiTimeIdentity = (ImageTimes(3:end)-ResponseTimes(2:end-1))*24*60*60;
ResponseTimesAdjId = ttl_beh+ResponseTimesDiffIdentity; %moves the time into neural time scale

%find if the responses were correct or not
Response(isnan(Response)) = [];
CorrectTrialsId = CorrectResponse == Response;

trialStartTimeId = testfile.session_start_time;

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);
[behavioralIndexImageOnId, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjId, ma_timestampsDS);
[behavioralIndexResponseId, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjId, ma_timestampsDS);

%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
preStartData = dataFidentity; %can adjust if want to exclude part of the data
%filters the entire trial.
if alreadyFilteredData == 0
    [itiDataFiltIdentity] = Analysis.emuEmot.nwbLFPchProcITI(preStartData, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
end

%preserve the variables so you can rerun the making of identityTaskLFP
PresentedEmotionIdxId = PresentedEmotionIdx;
PresentedIdentityIdxId = PresentedIdentityIdx;


%% process data with main proc function (see above to set this)
%this will break up the data. Can adjust the spectrogram window center
%point here (so beginning (1), middle(2), or end(3) of the moving window)
%the final filtered data (1to200) is broad so it can be inserted into PAC
%as desired
   [identityTaskLFP, itiDataReal.IdentityTask] = Analysis.emuEmot.nwbLFPchProc(itiDataFiltIdentity, PresentedEmotionIdxId,...
       PresentedIdentityIdx, behavioralIndexImageOnId, behavioralIndexResponseId, ...
       'fs', fs, 'chNum', chInterest, 'itiTime', itiTimeIdentity,...
       'ImagepreTime', preTime, 'ImagepostTime', postTime, 'ResponsepreTime', preTimeRes, 'ResponsepostTime', postTimeRes, 'multiTaperWindow',...
       multiTaperWindow, 'CorrectTrials', CorrectTrialsId, 'ResponseTimesAdj', ResponseTimesDiffIdentity);

%% for saving any variables
%THE NEXT STEP IS NOISE REMOVAL SO PROBABLY SAVE THE
%IDENTITY/EMOTIONTASKLFP AFTER THAT STEP


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

%% next section is Analysis.emuEmot.EMUNBACK_NOISECHECK_COMPARE
% 