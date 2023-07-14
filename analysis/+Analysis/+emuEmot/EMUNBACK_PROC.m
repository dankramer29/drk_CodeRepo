%% major script for running the processing of an individual patient
%%
% EMUNBACK_PROC

%MW13 9 is identity, 10 is emotion
%MW9
%MW21 10 is identity, 12 is emo

% Structure: image 1 on, then off with fixation
% cross on, then image 2 on and response about same/different at any time
% after that, but then image off, fixation on, then image 3 and decision
% about if 2 and 3 were the same. TTLs are image on (TTL 2) then next image (TTL 4)
% and back and forth like that. The other TTL is some TTL artifact like TTL
% off. CorrectResponse is the right answer and Response is if the images matched
% (1) or didn't match (0) (i.e. if they are correct CorrectResponse ==
% Response)
% %Hex code 19 task start; 29 image on; 39 fixation on; response 49; 

%Timestamps: 
%Short version: ma_timestamps and beh_timestamps are on the neural clock
%(see below for conversion). 1.6xxxe15. 
%rest are on the now command psychtoolbox clock and are in microseconds
%(see below) 

%this is mostly relevant for MW16 and MW18 when the hex system wasn't
%labeled correctly. For nback 167 TTLS for emotion and 167 for identity
%(but might be doubled?).

%identity task is always run before emotion task

% There are two clocks, the first clock from the psychtoolbox is
%from the "now" command (stores that output) at each timestamp (e.g.
%ImageTimes). the second is date time, but is in microseconds
%(beh_timestamps, but it's 500 samples/second and 1000ms/second, so
%essentially on the clock, 500,000 clock ticks pass each 1 second).
%ImageTimes(1) == beh_timestamps(2). Double checked and the psychtoolbox
%output for ImageTimes can be up to 0.015 seconds. TTLs are very on, but
%not necessarily behaviorally relevant.


% You can use these values to search the timestamp data from the ephys
% To check the actual time conversion
% timeA = datetime(timestamps(1)/1000000,...
%          'ConvertFrom','posixtime','TimeZone','America/Denver')

% Preprocessing INFO

% MACROWIRE LFP
% Downsampled to 500Hz from 4khz (downsample by 8)
% Notch filtered with Parra spectral interpolation 59-61Hz
% High pass at 0.1Hz
% No low pass

% MICROWIRE for SPIKE
% NO Downsample 32khz
% NO Notch filter
% High pass at 600Hz
% Low pass at 3000Hz

%% Event files
%MW3_Session14_filter.nwb (NBack Emotion): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3_Session12_filter.nwb (NBack Identity): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3
%chInterest = [69, 77, 148];
%(MW3_Session11_filter.nwb = MW3_Session12_filter.nwb but the filtering is
%better)

%% HOW TO DIFFERENTIATE FILES
% the NBACK_IDENTITY files are the ones you want. Some extra files are like
% temp or practice and will only have a few trials.

% TO FIND WHICH FILE IS FOR WHICH SESSION, WILL NEED TO LOOK AT THE TTLS
% AND KNOW THAT THE IDENTITY TASK IS RUN FIRST EACH TIME. ALSO THE NWB FOR
% NBACK IS ALWAYS RUN LAST (ORDER IS  Read Speak Execute Name3 Name6 Nback_i Nback_e). FINALLY THE LAST 

% MW13_Session_9_filter.nwb — NBack_IDENTITY_2022_5_29…
% MW13_Session_10_filter.nwb — NBack_EMOTION_2022_5_29…
%run the script to pull in the data from nwb if needed

%%%%%%%%%%%%
%% test the files to see if right number of ttls, which should be 54 if a single session
%%%%%%%%%%%%
% YOU DO NOT NEED TO DO THIS, JUST IF YOU DON'T KNOW WHICH ONE IS NBACK
addpath(genpath('Z:\JM_Emotion\SubjectData\'));

% fileLoc = 'Z:\JM_Emotion\SubjectData\MW18\NWB_Data';
% testNWB = 'JM_MW18_Session_4_filter.nwb';
% oneFile = true; trialEm = true; rawData = false;
% testfileEmId = nwbRead(testNWB);
% run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% change the details for each patient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% NWB contains beh_timestamps and ma_timestamps and macrowires data and on
% the neural clock. Rest are on now clock
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

preSpectrogramData = true; %either chop the data as already multitapered and then cut it up (true) or as raw voltage, cut it up, then process it by multitaper (false)
alreadyFilteredData = false; %toggle to true if you've run the entire dataset through LFP processing already and saved it.
oneFile = false; %if the nwb file is a single file and not split into two. Starts around patient MW_16
%USE _0X IF SINGLE DIGITS
sessionName = 'MW_21';
subjName = 'MW_21';
%MWX - remember to change the name in the within subject processing

matNameEm = 'NBack_EMOTION_2023_02_20.13_43_16'; %place this in an "Emotion" folder
matNameId = 'NBack_IDENTITY_2023_02_20.13_33_51'; %place this in an "Identity" folder
if oneFile == 0
    emotionFilter = 'JM_MW21_Session_12_filter.nwb'; %does NOT need to be placed in a folder
    identityFilter = 'JM_MW21_Session_10_filter.nwb';
elseif oneFile == 1
    emotionidentityFilter = 'JM_MW18_Session_16_filter.nwb'; %if they are one file
end
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
xshuffles = 10; %change the number of shuffles. 100 is a nice number to test data with, 500 or 1000 when it's ready for running completed.
DoPlot = 1; %toggle plotting on or off
savePlot = 0; %toggle on if you want to save the plots up front, probably better to look at them individually first
saveSelectFile = 0; %toggle on if you want to save all the files. probably best to do by hand


beh_timestamps = [];
ma_timestamps = [];
ResponseTimes = [];
Response = [];
TTLTimes = [];
CorrectResponse = [];
ImageTimes = [];

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
if oneFile == false
    testfileEm = nwbRead(emotionFilter);
    testfileId = nwbRead(identityFilter);
elseif oneFile == true
    testfileEmId = nwbRead(emotionidentityFilter);
end


%% Load the behavioral data
trialEm = true;
%runs nwb
run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
%loads behavioral
load(folderName)


%% pull in wire ids
%pull wire numbers and wire ids
eleCtable = testfileEm.general_extracellular_ephys_electrodes.vectordata;

channID = eleCtable.get('channID').data.load();
hemis = cellstr(eleCtable.get('hemisph').data.load());
label = cellstr(eleCtable.get('label').data.load());
location = cellstr(eleCtable.get('location').data.load());
macroROWS = contains(label,'MA_');
macro_hemi = hemis(macroROWS);
macro_location = location(macroROWS);
%macro_wire = wireID(macroROWS);
wireID = testfileEm.general_extracellular_ephys_electrodes.vectordata.get('wireID').data.load();  
shortBAn = testfileEm.general_extracellular_ephys_electrodes.vectordata.get('shortBAn').data.load(); 

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
%MW5 channels:
open TableChannel
dbstop %this is not how to stop, but it does the trick of breaking it! adjust the channels here.
%%
chInterest = [1, 2, 49, 50, 57, 58];
%MW9 channels:
%chInterest = [1, 2, 17, 18, 75, 76, 107, 108, 114, 115, 117, 118, 123, 124, 125, 126];
%MW13 channels:
% chInterest = [17,18,26,69,77,78,79,59,60,83,89,90,91,126,127,129,130,93,94,95];
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

%% find the behavioral timestamps
%TO FIGURE OUT THE START TIME, TRY TO MATCH UP THE "NOW" TIME AND THE
%NEURAL CLOCK TIME FOR WHERE YOU THINK IT WOULD START. 
if oneFile == true
    beh_timestampsEm = beh_timestamps(hexNum == 255);
    beh_timestampsId = beh_timestamps(hexNum == 256); %NEED TO CHANGE THIS BASED ON WHAT IT REALLY IS.
    [behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsEm, ma_timestampsDS); %finds the ttl
    [behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsId, ma_timestampsDS); %finds the ttl
    macrowiresEm = macrowires(:,1:behavioralIndexTTLEm(1)-(fs*5)); %remove all but 5 seconds worth of the macrowire data
    macrowiresId = macrowires(:,1:behavioralIndexTTLId(1)-(fs*5));
    ma_timestampsDSEm = ma_timeSTampsDs(:,1:behavioralIndexTTLEm(1)-(fs*5)); %remove all but 5 seconds worth of the macrowire data
    ma_timestampsDSId = ma_timeSTampsDs(:,1:behavioralIndexTTLId(1)-(fs*5)); %remove all but 5 seconds worth of the macrowire data
elseif oneFile == false
    macrowiresEm = macrowires;
    macrowires = [];
    beh_timestampsEm = beh_timestamps;
    if ~isempty(cellVar)
        hexNumEm = hexNum;
    end
end

%% common average rerefernce
macrowiresCAREm = double(macrowiresEm) - repmat(nanmean(macrowiresEm,1), size(macrowiresEm,1),1);

%% low pass the data (nyquist 250)
lpFilt = designfilt('lowpassiir','FilterOrder',8, ...
'PassbandFrequency',200,'PassbandRipple',0.2, ...
'SampleRate',500);

%cut data to channels of interest
data = double(macrowiresCAREm(chInterest, :));

%lowpass filter
dataFemotion = filtfilt(lpFilt,data');

clear data; clear macrowiresCAREm; 


%convert the timestamps so you can go back to earlier steps
TTLTimesEm = TTLTimes;
CorrectResponseEm = CorrectResponse;
ResponseEm = Response;
ResponseTimesEm  = ResponseTimes;
ImageTimesEm = ImageTimes;

%% 
% set up the behavioral timestamps to ensure they are the presentation of
% the image
%Hex code 19 task start; 29 image on; 39 fixation on; response 49; 
%finds the image on time. realize this is variable but about 2 seconds.
if isempty(cellVar)
idx1 = 1; idx2 = 1;
for ii=2:length(beh_timestampsEm)
    timeStampDiff(idx1) = beh_timestampsEm(ii)-beh_timestampsEm(ii-1);    
    if timeStampDiff(idx1) >= 499001 && timeStampDiff(idx1) <= 500999 %50000/500 = 1000ms
        imageOn(idx2) = ii-1; %record the relevant image onsets indices, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (THIS APPEARS CONFIRMED)
        idx2 = idx2 + 1;
    end
    idx1 = idx1 +1;
end
elseif ~isempty(cellVar)
    imageOn = find(hexNumEm == 29);
    idx1 = 1;
    for ii = 2:length(imageOn)   
        timeStampDiff(idx1,1) = beh_timestampsEm(imageOn(ii))-beh_timestampsEm(imageOn(ii-1));        
        idx1 = idx1+1;
    end
end

% find the timestamp conversion of the phys data and the psychtoolbox data
ttl_beh = beh_timestampsEm(imageOn); %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on

ImageTimesDiffCheck = (ImageTimesEm-TTLTimesEm)*24*60*60; %in seconds to ensure that the TTLs and Imagetimes are as expected, close
ImageTimesDiff = ImageTimesDiffCheck*1e6; %convert to microseconds
ImageTimesAdjEm = ttl_beh+ImageTimesDiff; %moves the time into neural time scale

%if the response is a NaN, make it the next ttl
ResponseTimesNanRemoved = ResponseTimesEm;
ResponseNanRemoved = ResponseEm;
for ii = 2:length(ResponseTimesNanRemoved)
    if isnan(ResponseTimesNanRemoved(ii))
        ResponseNanRemoved(ii) = ~CorrectResponseEm(ii);
        ResponseTimesNanRemoved(ii) = ImageTimesEm(ii+1);
    end
end

ResponseTimesDiffEmotion = (ResponseTimesNanRemoved-TTLTimesEm)*24*60*60*1e6;
itiTimeEmotion = (ImageTimesEm(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60;
ResponseTimesAdjEm = ttl_beh+ResponseTimesDiffEmotion; %moves the time into neural time scale

%find if the responses were correct or not
ResponseNanRemoved(1) = []; %remove the non first trial;
CorrectTrialsEm = CorrectResponseEm == ResponseNanRemoved;

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsEm, ma_timestampsDSEm); %finds the ttl
[behavioralIndexImageOnEm, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjEm, ma_timestampsDSEm); %finds the image onset which is more accurate
[behavioralIndexResponseEm, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjEm, ma_timestampsDSEm); %finds the response time


%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
%THIS IS A CHOICE TO REMOVE DATA TO DECREASE THE TIME OF THE RECORDING, NOT
%CURRENTLY USING BUT COULD.
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
%preStartData = dataFemotion; %can adjust if want to exclude part of the data
%filters the entire trial.
if alreadyFilteredData == 0
    [itiDataFiltEmotion] = Analysis.emuEmot.nwbLFPchProcITI(dataFemotion, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
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
beh_timestamps = [];
ma_timestamps = [];
ResponseTimes = [];
Response = [];
TTLTimes = [];
CorrectResponse = [];
ImageTimes = [];



%% load the behavioral data

taskName = 'Identity';

folderName=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName, '\', taskName, '\', matNameId);

%identityFilter = 'MW_9_Session_12_filter.nwb'; %this is done as an earlier
%step but is here for ease of checking different nwbs
if oneFile == false
    trialEm = false;
    run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
    %% common average rerefernce
    
    macrowiresId = macrowires;
    macrowires = [];
    
    % convert to individual so they are saved and can go back to earlier steps
    beh_timestampsId = beh_timestamps;
    ma_timestampsDSId = ma_timestampsDS; %downsamle the timestamps

end

macrowiresCARId = double(macrowiresId) - repmat(nanmean(macrowiresId,1), size(macrowiresId,1),1);

%% low pass the data (nyquist 250)
lpFiltlow = designfilt('lowpassiir','FilterOrder',8, ...
    'PassbandFrequency',200,'PassbandRipple',0.2, ...
    'SampleRate',fs);

%cut data to channels of interest
data = double(macrowiresCARId(chInterest, :));
%lowpass filter
dataFidentity = filtfilt(lpFiltlow,data');

clear data; clear macrowiresCARId;


load(folderName)
TTLTimesId = TTLTimes;
CorrectResponseId = CorrectResponse;
ResponseId = Response;
ResponseTimesId  = ResponseTimes;
ImageTimesId = ImageTimes;



%% find the behavioral timestamps
%% 
% set up the behavioral timestamps to ensure they are the presentation of
% the image
idx1 = 1; idx2 = 1;
for ii=2:length(beh_timestampsId)
    timeStampDiff(idx1) = beh_timestampsId(ii)-beh_timestampsId(ii-1);    
    if timeStampDiff(idx1) >= 499001 && timeStampDiff(idx1) <= 500999 %50000/500 = 1000ms
        imageOn(idx2) = ii-1; %record the relevant image onsets, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (this is possibly not true!)
        idx2 = idx2 + 1;
    end
    idx1 = idx1 +1;
end

% find the timestamp conversion of the phys data and the psychtoolbox data
ttl_beh = beh_timestampsId(imageOn); %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on

ImageTimesDiffCheck = (ImageTimesId-TTLTimesId)*24*60*60; %in seconds to ensure that the TTLs and Imagetimes are as expected, close
ImageTimesDiff = ImageTimesDiffCheck*1e6; %convert to microseconds
ImageTimesAdjId = ttl_beh+ImageTimesDiff; %moves the time into neural time scale

%if the response is a NaN, make it the next ttl
ResponseTimesNanRemoved = ResponseTimesId;
ResponseNanRemoved = ResponseId;
for ii = 2:length(ResponseTimesNanRemoved)
    if isnan(ResponseTimesNanRemoved(ii))
        ResponseNanRemoved(ii) = ~CorrectResponseId(ii);
        ResponseTimesNanRemoved(ii) = ImageTimesId(ii+1);
    end
end

ResponseTimesDiffIdentity = (ResponseTimesNanRemoved-TTLTimesId)*24*60*60*1e6;
itiTimeIdentity = (ImageTimesId(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60;
ResponseTimesAdjId = ttl_beh+ResponseTimesDiffIdentity; %moves the time into neural time scale

%find if the responses were correct or not
ResponseNanRemoved(1) = []; %remove the non first trial;
CorrectTrialsId = CorrectResponseId == ResponseNanRemoved;

%BELOW, THE BEHAVIORALINDEXRESPONSEID IS NOT OUTPUTTING CORRECTLY, IT'S ALL
%THE SAME VALUE.

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
if oneFile == false
    [behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsId, ma_timestampsDSId);
end
[behavioralIndexImageOnId, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjId, ma_timestampsDSId);
[behavioralIndexResponseId, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjId, ma_timestampsDSId);

%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
%preStartData = dataFidentity; %can adjust if want to exclude part of the data
%filters the entire trial.
if alreadyFilteredData == 0
    [itiDataFiltIdentity] = Analysis.emuEmot.nwbLFPchProcITI(dataFidentity, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
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
    fileName = [folder_name, '\', 'itiDataFiltIdentity', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'itiDataFiltEmotion', '.mat'];    save(fileName);    
    fileName = [folder_name, '\', 'emotionTaskLFP', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'identityTaskLFP', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'itiDataReal', '.mat'];    save(fileName);


    fileName = [folder_name, '\', 'nbackCompareImageOn', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'nbackCompareResponse', '.mat'];    save(fileName);
    fileName = [folder_name, '\', 'MW13', '.mat'];    save(fileName);

    
end

%% next section is Analysis.emuEmot.EMUNBACK_NOISECHECK_COMPARE.M
% then Analysis.emuEmot.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT.M
% then Analysis.emuEmot.emuEmot.EMUNBACK_COMPAREACROSSPATIENTS.M (BUT, that
% one is mostly by hand and to be placed into excel file)


