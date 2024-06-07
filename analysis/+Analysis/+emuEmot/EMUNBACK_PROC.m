%% major script for running the processing of an individual patient
%%
% EMUNBACK_PROC

%MW13 9 is identity, 10 is emotion
%MW16 has hexcode but all hexs are 255. has 167 ttls x2 which is 334, but
%actually has 332. 
%MW9
%MW19 Session 6 - 329 TTL - NBack IDEN Session 7 - 330 TTL - NBack EMO 

%MW21 10 is identity, 12 is emo
%MW22 Session 6 - 331 TTL - NBack IDEN Session 7 - 331 TTL - NBack EMO
%MW24 the first ttl didn't make it into the nwb so the first image on is
%actually the second image. the first is just skipped (emotion task only).

% Structure: image 1 on, then off with fixation
% cross on, then image 2 on and response about same/different at any time
% after that, but then image off, fixation on, then image 3 and decision
% about if 2 and 3 were the same. TTLs are image on (TTL 2) then next image (TTL 4)
% and back and forth like that. The other TTL is some TTL artifact like TTL
% off. CorrectResponse is the right answer and Response is if the images matched
% (1) or didn't match (0) (i.e. if they are correct CorrectResponse ==
% Response)
% %Hex code 19 task start; 29 image on; 39 fixation on; response 49; 
% for MW_16 and 18 Audio on, task start, video on, 3*54, video 1000th frame, video off.

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
%(beh_timestamps, but it's a conversion of 1,000,000 (1e6) to convert to seconds.
%ImageTimes(1) == beh_timestamps(2). Double checked and the psychtoolbox
%output for ImageTimes can be up to 0.015 seconds. TTLs are very on, but
%not necessarily behaviorally relevant.

%to convert time stamps!
%best way is to get a time difference from the behavioral (so
%(ResponseTimesEm-ImageTimesEm)) then take that and convert to microseconds
%*24*60*60*1e6 then add that or subtract that from the neural time clock
%which is the beh_ so add to the ttl or the known image onset time.


% You can use these values to search the timestamp data from the ephys
% (e.g. beh_timestamps) To check the actual time conversion
% timeA = datetime(timestamps(1)/1000000,...
%          'ConvertFrom','posixtime','TimeZone','America/Denver')

%for the psychtoolbox output like ImageTimes:
% datetime(ImageTimes(1), 'ConvertFrom', 'datenum')

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
addpath(genpath('Z:\KramerEmotionID_2023\Data\EMU_nBack'));

preSpectrogramData = true; %either chop the data as already multitapered and then cut it up (true) or as raw voltage, cut it up, then process it by multitaper (false)
alreadyFilteredData = false; %toggle to true if you've run the entire dataset through LFP processing already and saved it.
%there are many variations on how the data are presented. here you can
%switch the options to run through them there are more!! Will have to
%figure it out as I go to some degree. As far as I know, no single
%behvioral files but who knows.
    %fileVariation = 1; This is two NWB files and two behavioral files, no
            %hex, with EvKey. Should be MW_9,    
    %fileVariation = 2; MW_5, MW_1, MW_2 this is one NWB files and two behavioral files with
            %no hex code and with EvKey. 
           
    %fileVariation = 6; don't ask, this is MW13. it's two behavioral, two
        %nwb files and no evkey
    %fileVariation = 3; This is two NWB files and two behavioral files with
            %EvKey and messed up hex.
            %this is MW_16 and MW_18
    %fileVariation = 4; This is two NWB files and two behavioral file with
            %no EvKey and good hex. This is after MW_19.
    %fileVariation = 5; This is one NWB and with bad hex numbers and with
            %an EvKey

%% if running for the first time uncomment out this section and comment out the parts below this
% fileVariation = 1;
% 
% sessionName = 'MW_9';
% subjName = 'MW_9';
%     %MWX - remember to change the name in the within subject processing!!
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %REMEMBER TO CHANGE THE CHANNELS BELOW
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matNameId = 'NBack_IDENTITY_2022_1_7.16_56_59'; 
% matNameEm = 'NBack_EMOTION_2022_1_7.17_29_54'; 
% 
% switch fileVariation
%     case {1, 3, 4, 6}
%         identityFilter = 'JM_MW9_Session_12_filter.nwb'; %does NOT need to be placed in a folder
%         emotionFilter = 'JM_MW9_Session_13_filter.nwb';
%     case  2
%         emotionidentityFilter = 'MW2_Session_7_filter.nwb'; %if they are one file
% end
% %For the hex code shenaningans
% switch fileVariation
%     case {1,  3}
%         %earlier is identity task
%         load JM_MW9_Session_12_EventKey.mat
%         EvKeyId = EvKey;
%         load JM_MW9_Session_13_EventKey.mat
%         %EvKeyCodes 629 = Image_Shown and 649 = Response_Made
%         EvKeyEm = EvKey;
%     case 2
%         load MW2_Session_7_EventKey.mat       
%     case {4, 5, 6}
%         EvKeyEm = [];
%         EvKeyId = [];
% end
% fastRun = false;
%%
%THIS IS SET UP TO JUST COMMENT IN EACH SUBJECT TO MAKE THIS FASTER IN THE
%FUTRE IF NEEDED. IT IMPLIES THAT YOU ALREADY KNOW THE NOISE AND DON'T NEED
%TO LOOK AT WHICH ONES ARE EXCLUDED AGAIN.
%MW24
% fileVariation = 4;
% sessionName = 'MW_24';
% subjName = 'MW_24';
% matNameId = 'NBack_IDENTITY_2023_09_05.13_01_39'; 
% matNameEm = 'NBack_EMOTION_2023_09_05.13_10_38';
% identityFilter = 'JM_MW24_Session_6_filter.nwb';
% emotionFilter = 'JM_MW24_Session_7_filter.nwb';
% chInterestActual = [24:27, 33:36, 45:48, 145:148];
% removeTrialsEmot = [1,2,5,7,12, 13,15,19,21,22,24,31,32, 33, 34,35,36,38,40,41,42,44,45,46,47,48,49,50,52,54:114,117:126,128:166, 170:172];
% removeTrialsId = [2:39,41:42,44,47:164,166:180];
% fastRun = true;

%MW2
% fileVariation = 2;
% sessionName = 'MW_2';
% subjName = 'MW_2';
% matNameId = 'NBack_2021_3_23.17_28_41'; 
% matNameEm = 'NBack_2021_3_23.17_32_58'; 
% emotionidentityFilter = 'MW2_Session_7_filter.nwb';
% load MW2_Session_7_EventKey.mat;    
% chInterestActual = [47:50, 85:88, 97:100, 149:152];
% removeTrialsEmot = [8, 14:26, 28,31, 32, 34];
% 
% removeTrialsId = [1,2,8,9:12, 14, 15:19, 21:30,32:35,37:38,40, 42:67,72,73, 75,79,88:103];
% fastRun = true;
%MW5 
% chInterestActual = [37:40,49:52,61:64,139:142,151:154];
% chInterestActual = [37:40,49:51,61:64,139:140,151:151]; %as of 3/7/2024 for bipolar
% fileVariation = 2;
% sessionName = 'MW_5';
% subjName = 'MW_5';
% matNameId = 'NBack_IDENTITY_2021_7_18.13_27_48'; 
% matNameEm = 'NBack_EMOTION_2021_7_18.13_32_34'; 
% emotionidentityFilter = 'JM_MW5_Session_8_filter.nwb';
% load JM_MW5_Session_8_EventKey.mat;    
% chInterestActual = [37:40,49:51,61:64,139:140,151:151];
% removeTrialsEmot = [1,2,4:9, 11, 13:18, 20:26, 28:32, 35, 38:51, 53:61, 63:70, 72, 74:78];
% removeTrialsId = [2:6, 11:13, 17:21, 25, 26, 29:36, 39:47, 49:53,56:83, 86:100];
% fastRun = true;

%MW18 channels NOTE MW18 HAS CHANNELS MISSING
% chInterestActual = [12,13, 22:27, 36:39, 149:152, 158:161];
% fileVariation = 3;
% sessionName = 'MW_18';
% subjName = 'MW_18';
% matNameId = 'NBack_IDENTITY_2022_10_20.13_12_18'; 
% matNameEm = 'NBack_EMOTION_2022_10_20.13_20_21'; 
% identityFilter = 'JM_MW18_Session_11_filter.nwb'; %does NOT need to be placed in a folder
% emotionFilter = 'JM_MW18_Session_12_filter.nwb';
% load JM_MW18_Session_11_EventKey.mat
% EvKeyId = EvKey;
% load JM_MW18_Session_12_EventKey.mat
% EvKeyEm = EvKey;
% removeTrialsEmot = [1,2,4,6:21,25,29:31, 36, 37, 39, 40, 41, 42,42, 48, 49, 50, 51, 52, 53, 54, 58, 59, 60, 61, 64:67, 69, 70, 71, 72, 73:76, 79:81, 83, 85:94, 97:99, 103, 105, 112,113, 114,115, 119:121, 123:125, 149,152, 153];
% removeTrialsId = [1,2,4,5:15, 17, 20:23, 25:34, 37:44, 46:49, 54:63, 67:80, 84:97, 99, 102, 103, 107:117, 119, 123, 126, 130:133, 135:137, 143, 148, 158, 160];
% fastRun = true;


%MW16 CAN UNCOMMENT THIS AND RUN IT.
% fileVariation = 3;
% sessionName = 'MW_16';
% subjName = 'MW_16';
% matNameId = 'NBack_IDENTITY_2022_08_29.16_54_54'; 
% matNameEm = 'NBack_EMOTION_2022_08_30.14_37_58'; 
% identityFilter = 'JM_MW16_Session_1_filter.nwb'; %does NOT need to be placed in a folder
% emotionFilter = 'JM_MW16_Session_3_filter.nwb';
% load JM_MW16_Session_1_EventKey.mat
% EvKeyId = EvKey;
% load JM_MW16_Session_3_EventKey.mat
% EvKeyEm = EvKey;
% chInterestActual = [1,2,3,9,10,11,12,13,14,25,26,27,28,39,40,41,42,54,55,66,67,68];
% removeTrialsEmot = [1,2, 4:6, 8:13, 16:28, 30:37, 39, 41:44, 47:49, 51:53, 55:58, 60, 62, 64:66, 69:95, 99:100, 102:109, 116, 118, 120, 122:123, 126:127, 129, 131:223];
% removeTrialsId = [1:10, 13:38,40:43,46:49, 55:56, 58:59, 62, 64:69, 71:75, 77:83,85:89,91:227];
% fastRun = true;

%MW23 channels
% chInterestActual = [46:48,54:57,68:70,145:147,154:158];
% fileVariation = 4;
% sessionName = 'MW_23';
% subjName = 'MW_23';
% matNameId = 'NBack_IDENTITY_2023_06_27.13_22_22'; 
% matNameEm = 'NBack_EMOTION_2023_06_27.13_29_53';
% identityFilter = 'JM_MW23_Session_8_filter.nwb';
% emotionFilter = 'JM_MW23_Session_9_filter.nwb';
% chInterestActual = [46:48,54:57,68:70,145:147,154:158];
% removeTrialsEmot = [1,3,4,7, 10, 12, 20, 21,22,45];
% removeTrialsId = [1, 2, 5, 6, 8,9, 25, 37, 48, 49];
% fastRun = true;

%MW19 channels:
% 
% fileVariation = 4;
% sessionName = 'MW_19';
% subjName = 'MW_19';
% matNameId = 'NBack_IDENTITY_2022_10_31.16_02_28'; 
% matNameEm = 'NBack_EMOTION_2022_10_31.16_10_12';
% identityFilter = 'JM_MW19_Session_6_filter.nwb';
% emotionFilter = 'JM_MW19_Session_7_filter.nwb';
% chInterestActual = [11:14, 23:25, 115:117, 123:125];
% removeTrialsEmot = [4,6, 11, 16, 17, 18, 21, 28, 30];
% removeTrialsId = [11,12,13,14,19,20,21,22, 23, 24, 29];
% fastRun = true;

%MW22 channels:
%chInterestActual=[16:19,28:31,40:42,169:171,178:181];
%chInterestActual = [2,3,4,5,13,14,19,20,21,22,30,31,32,33,34,...
%     45,46,47,56,57,73,74,75,88,89,90,121,122,123,139,140,...
%     141,142,143,172,173,174,181,182,183,184,192,193,194,196,197,198];
% 
% fileVariation = 4;
% sessionName = 'MW_22';
% subjName = 'MW_22';
% matNameId = 'NBack_IDENTITY_2023_04_10.15_56_32'; 
% matNameEm = 'NBack_EMOTION_2023_04_10.16_04_57'; 
% identityFilter = 'JM_MW22_Session_6_filter.nwb';
% emotionFilter = 'JM_MW22_Session_7_filter.nwb';
% chInterestActual=[16:19,28:31,40:42,169:171,178:181];
% removeTrialsEmot =[3, 5, 10, 12, 15,22,23,24, 25,26,28,30,31,34,35:49, 51,53:58, 60, 62,63, 65:69, 71:73, 75:85, 86,89:90, 100, 101, 125, 128, 130, 133,136];
% removeTrialsId = [1,2:9, 13, 15, 16, 17, 18, 20, 21, 22:26, 28, 31:52, 54:85, 87, 94:95, 110, 111, 112, 116, 117, 118];
% fastRun = true;

% %MW21 channels:
%chInterestActual = [49,50,57,58,65,66,67,68]; %bipolar
%chInterestActual = [2,3,34,35,38,39,49,50,54,56,63,64,77,88,89,134,135];
%
% fileVariation = 4;
% sessionName = 'MW_21';
% subjName = 'MW_21';
% matNameId = 'NBack_IDENTITY_2023_02_20.13_33_51'; 
% matNameEm = 'NBack_EMOTION_2023_02_20.13_43_16'; 
% identityFilter = 'JM_MW21_Session_10_filter.nwb';
% emotionFilter = 'JM_MW21_Session_12_filter.nwb';
% chInterestActual = [49,50,57,58,65,66,67,68];
% removeTrialsEmot =[1, 8, 15];
% removeTrialsId = [1,2, 5, 6];
% fastRun = true;

%MW13 channels:
% fileVariation = 6;
% sessionName = 'MW_13';
% subjName = 'MW_13';
% matNameId = 'NBack_IDENTITY_2022_5_29.18_5_50'; 
% matNameEm = 'NBack_EMOTION_2022_5_29.18_10_57'; 
% identityFilter = 'JM_MW13_Session_9_filter.nwb'; 
% emotionFilter = 'JM_MW13_Session_10_filter.nwb';
% EvKeyEm = [];
% EvKeyId = [];
% chInterestActual = [1,2,3,9,10,11,17,18,19,67:69,81:83,93:96];
% removeTrialsEmot = [2, 6, 9, 11,14,32,36,37,40];
% removeTrialsId = [1,4];
% fastRun = true;


%MW13 channels for Middle Frontal:
%chInterestActual = [49:56];

%MW9

%chInterestActual = [117:120];


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
DoPlot = 0; %toggle plotting on or off
savePlot = 0; %toggle on if you want to save the plots up front, doesn't close them so ok to save them. saves as jpg. in that script you can save them as individual mat files for the paper.
saveSelectFile = 0; %toggle on if you want to save select files as mat
timeCheck = 0; %toggle on if you want to check the clock for neural data and that for behavioral data (right now off by 6 hours as of 11/15/2023 for unknown reasons)
referenceStrategy = 3;  %case switch 1 is CAR with all electrodes, 2 is with just the ones you are using and,3 is bipolar
randomTimeIti = 1; %to make your iti a bunch of randomly selected time points so the average is essentially low.

%
beh_timestamps = [];
ma_timestamps = [];
ResponseTimes = [];
Response = [];
TTLTimes = [];
CorrectResponse = [];
ImageTimes = [];
ma_timestampsDSEm = [];
ma_timestampsDSId = [];
PresentedEmotionIdx = [];
PresentedIdentityIdx = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% START OF EMOTION PROCESSING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
taskName = 'Emotion';
folderName=strcat('Z:\KramerEmotionID_2023\Data\EMU_nBack', '\', sessionName, '\', matNameEm);

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
%Emotion
switch fileVariation
    case {1, 3, 4,6}
        testfileEm = nwbRead(emotionFilter);
        testfileId = nwbRead(identityFilter);
    case 2 %add any single NWB file cases here. MW5
        testfileEmId = nwbRead(emotionidentityFilter);
end

%% Load the behavioral data
trialEm = true;
%runs nwb
run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
%loads behavioral
load(folderName)


% in at least the first 2 subjects, finding the time of the actual trials
% is not straightforward. this will find the actual timestamps of when both
% started. Also good for MW16 where the timestamps are all 255. Of note
% there is about a 6 hour difference between the 2 clocks in at least MW_2
% and MW_16. As of 11/15/23 still working it out.
switch fileVariation
    case {4} %case 6, MW13 seems to just load image times.
        ImageTimes = Events.Times.Image_Shown;
end
if timeCheck
    trialStartRealTime = datetime(ImageTimes(1), 'ConvertFrom', 'datenum','TimeZone','America/Denver');
  
        ttlFirstRealTime = datetime(beh_timestamps(1)/1000000,'ConvertFrom','posixtime','TimeZone','America/Denver');

    for ii = 1:length(beh_timestamps)
        timeA = datetime(beh_timestamps(ii)/1000000,...
            'ConvertFrom','posixtime','TimeZone','America/Denver');
        minTime(ii) = time(between(timeA, trialStartRealTime));
    end
    [vl, trialStartTimeIndx] = min(minTime);
end



%% pull in wire ids
%pull wire numbers and wire ids
switch fileVariation
    case  {1, 3, 4,6}
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
    case 2 %add any single NWB file cases here.
        eleCtable = testfileEmId.general_extracellular_ephys_electrodes.vectordata;
        channID = eleCtable.get('channID').data.load();
        hemis = cellstr(eleCtable.get('hemisph').data.load());
        label = cellstr(eleCtable.get('label').data.load());
        location = cellstr(eleCtable.get('location').data.load());
        macroROWS = contains(label,'MA_');
        macro_hemi = hemis(macroROWS);
        macro_location = location(macroROWS);
        %macro_wire = wireID(macroROWS);
        wireID = testfileEmId.general_extracellular_ephys_electrodes.vectordata.get('wireID').data.load();
        shortBAn = testfileEmId.general_extracellular_ephys_electrodes.vectordata.get('shortBAn').data.load();
end

%number the channels on an electrode for easier assessment of which ones to
%pull
idx = 2;
channelNumber(1) = 1;
for ii = 2:length(wireID)   
    if wireID(ii,1) == wireID(ii-1,1)
        channelNumber(ii,1) = idx;
        idx = idx + 1;
    elseif wireID(ii,1) ~= wireID(ii-1,1)        
        idx = 1;
        channelNumber(ii,1) = idx;
        idx = idx + 1;
    end
end

TableChannel = table(location, hemis, macroROWS, label, channID, channelNumber, shortBAn, wireID);
if size(macrowires,1) ~= TableChannel.channID(end)
    warning('channel numbers do not match row numbers, check that some channels are removed for some reason AND REMEMBER TO ADJUST THE CHANNEL NAMES')
    %REMEMBER YOU MUST CHANGE THE NAMES OF THE CHANNELS BELOW AS WELL! for
    %chLocationName (change everywhere in that for loop that says channID
    %to channIDadjTot)
    %change in the chann
    %this lets you find the skips, although the part after the for loop
    %actually fixes it since the channels are just the next macrowire. this
    %for loop is just to identify where these happen.
    idxSk = 1;
    for ii = 2:height(TableChannel)
        if TableChannel.channID(ii) - TableChannel.channID(ii-1) > 1
            skippedChannels(idxSk,1) = ii;
            skippedChannels(idxSk,2) = TableChannel.channID(ii)-TableChannel.channID(ii-1);
            idxSk =idxSk +1;
        end
    end
    microNumCh = nnz(find(channID>250));
    channIDpadding(1:microNumCh,1) = NaN;
    channIDadj(:,1) = 1:height(TableChannel)-microNumCh;
    channIDadjTot = vertcat(channIDpadding,channIDadj);
    TableChannel.channIDadjusted = channIDadjTot;
else
    TableChannel.channIDadjusted = channID;
end
%%%%%%%%%%%%%%%%%%%%%%%%%
%% change channels here %
%%%%%%%%%%%%%%%%%%%%%%%%%
open TableChannel
%dbstop %this is not how to stop, but it does the trick of breaking it! adjust the channels here.
%%
chInterest=chInterestActual;

%% find the behavioral timestamps
%ADD MORE CASES AS YOU GO
switch fileVariation
    case 1
         combinedEvKey(:,1) = EvKeyEm.Names;
        for jj = 1:length(combinedEvKey)
            combinedEvKey{jj,2} = EvKeyEm.Codes(jj);
            combinedEvKey{jj,3} = EvKeyEm.GoodTTLs(jj);
        end
        %convert the hex codes to the real hex codes
        %db stop
        
        beh_timestampsEm = beh_timestamps;
    case  3
        %will need to load the file Rex created
        %convert the hex codes to the appropriate codes
        %commented out this version because not all codes of 255 are good
        %codes, updated by rex, use the below GoodTTLs version
        % idxH = 1;
        % for ii = 1:length(hexNum)
        %     if hexNum(ii) == 255 || hexNum(ii) == 256
        %         hexNum(ii) = EvKeyEm.Codes(idxH);
        %         idxH = idxH + 1;
        %     end
        % end
        % beh_timestampsEm = beh_timestamps;

        combinedEvKey(:,1) = EvKeyEm.Names;
        for jj = 1:length(combinedEvKey)
            combinedEvKey{jj,2} = EvKeyEm.Codes(jj);
            combinedEvKey{jj,3} = EvKeyEm.GoodTTLs(jj);
        end
        %convert the hex codes to the real hex codes
        %db stop
        hexNum(EvKeyEm.GoodTTLs*2,1) = EvKeyEm.Codes;
        beh_timestampsEm = beh_timestamps;
    case 2    %here there is one file and the evkey is one list with both so break it
        %up
        combinedEvKey(:,1) = EvKey.Task;
        for jj = 1:length(combinedEvKey)
            combinedEvKey{jj,2} = EvKey.GoodTTLs(jj);
        end
        %THIS APPEARS TO MESS IT UP AND BE REDUNDANT BECAUSE THERE ARE TOO
        %MANY BEH TIME STAMPS AND WE ONLY WANT EMOTION OR IDENTITY (BROKEN
        %UP BELOW) HOWEVER I HAD THIS FOR MW5 SO WILL LEAVE IT FOR NOW, BUT
        %MAY NOT WORK FOR MW5 EITHER? UPDATE it appears not to be needed
        %and messes up MW5 as well 
        % if strcmp(sessionName, 'MW_5') %if MW_2 it doesn't works so don't do it.
        % beh_timestampsEm = beh_timestamps;
        % end            
    case {4, 5, 6}
        beh_timestampsEm = beh_timestamps;
end


%% This part is get the time stamps of a long file if it's all one file

%   CASE SWITCH ALL OF THESE BECAUSE THIS GETS VERY SPECIFIC FOR
%   MW16, 18, 19, IT'S ALL PATIENT SPECIFIC AROUND THEN BUT SETTLES
%   OUT IN THE 20S I BELIEVE WITHOUT ALL THE ONE FILE STUFF. THE CONNECTION
%   BETWEEN THE HEX AND THE EVKEY ETC IS RELATIVELY SORTED OUT, JUST FOR
%   EACH CASE, IT'S WORTH FOLLOWING IT DOWN TO MAKE SURE THAT IMAGEON IS
%   THE RIGHT NWB TTL AND FROM THERE IT SHOULD WORK.
switch fileVariation
    case 1 %MW_9 amd 2? will need to check this. two files, two EvKey no hex
        
        beh_timestampsEm = beh_timestamps(EvKeyEm.GoodTTLs);       
        %this is for chopping the data up into two parts, one for Em and
        %one for Id task.
        [behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsEm, ma_timestampsDS); %finds the ttl
        macrowiresEm = macrowires; 
        ma_timestampsDSEm = ma_timestampsDS; 
       
    case 2 % one file MW5 and with a EvKey and no hex
        idxTS = 1; idxTS2 = 1;
        for ii = 1:length(combinedEvKey)
            if strcmp(combinedEvKey{ii}, ('NBack_IDENTITY'))
                beh_timestampsId(idxTS,1) = beh_timestamps(combinedEvKey{ii,2});
                imageOnId(idxTS,1) = combinedEvKey{ii,2};
                idxTS = idxTS+1;
            end
            if strcmp(combinedEvKey{ii}, ('NBack_EMOTION'))
                beh_timestampsEm(idxTS2,1) = beh_timestamps(combinedEvKey{ii,2});
                imageOnEm(idxTS2,1) = combinedEvKey{ii,2};
                idxTS2 = idxTS2+1;
            end
        end
        %this is for chopping the data up into two parts, one for Em and
        %one for Id task. 
        [behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsEm, ma_timestampsDS); %finds the ttl
        [behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsId, ma_timestampsDS); %finds the ttl
        macrowiresEm = macrowires; %remove all but 5 seconds worth of the macrowire data
        ma_timestampsDSEm = ma_timestampsDS; %remove all but 5 seconds worth of the macrowire data
        hexNumEm =[];
    case 5 %this is for a case with onefile and with hexNums, 
        beh_timestampsEm = beh_timestamps(hexNum == 255);
        beh_timestampsId = beh_timestamps(hexNum == 256); %NEED TO CHANGE THIS BASED ON WHAT IT REALLY IS.
        [behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsEm, ma_timestampsDS); %finds the ttl
        [behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsId, ma_timestampsDS); %finds the ttl
        %the below needs further checking because the
        %1:behavioralIndexTTLEm(1)-(fs*5) would be the time BEFORE the
        %trial starts. in either case probably easier to just do the whole
        %thing unless it's huge
        % macrowiresEm = macrowires(:,1:behavioralIndexTTLEm(1)-(fs*5)); %remove all but 5 seconds worth of the macrowire data
        % macrowiresId = macrowires(:,1:behavioralIndexTTLId(1)-(fs*5));
        % ma_timestampsDSEm = ma_timeSTampsDs(:,1:behavioralIndexTTLEm(1)-(fs*5)); %remove all but 5 seconds worth of the macrowire data
        % ma_timestampsDSId = ma_timeSTampsDs(:,1:behavioralIndexTTLId(1)-(fs*5)); %remove all but 5 seconds worth of the macrowire data
    case 3
        macrowiresEm = macrowires;
        beh_timestampsEm = beh_timestamps;
        ma_timestampsDSEm = ma_timestampsDS;
        if ~isempty(cellVar)
            if max(hexNum) < 2 %sometimes has a hex code that is only 1 or 0 or only 255/0
                cellVar = [];
            else
                hexNumEm = hexNum;
            end
        end
    case {4,6} %two nwb and two behavioral files, no hex
        %finds the index in the data of the behavioral indices
        %behavioralIndex now points to the row in data that is closest to the
        %behavioral time stamps.
        macrowiresEm = macrowires;
        beh_timestampsEm = beh_timestamps;
        ma_timestampsDSEm = ma_timestampsDS;
        [behavioralIndexTTLEm, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsEm, ma_timestampsDSEm); %finds the ttl
end

%% reference strategy
% low pass the data (nyquist 250)
lpFilt = designfilt('lowpassiir','FilterOrder',8, ...
    'PassbandFrequency',200,'PassbandRipple',0.2, ...
    'SampleRate',fs);

switch referenceStrategy
    case 1
        macrowiresCAREm = double(macrowiresEm) - repmat(nanmean(macrowiresEm,1), size(macrowiresEm,1),1);
        %cut data to channels of interest
        chInterest = chInterestActual;
        data = double(macrowiresCAREm(chInterest, :));
        %setup for accessing channels
        %channels in dixi and pmt are 1=distal contact, adtech is 1=proximal

        for ff=1:length(chInterest)
            ch = num2str(chInterest(ff));
            channelName{ff} = ['ch' ch];
            str = location(TableChannel.channIDadjusted ==chInterest(ff));
            strout = plt.lowup(str); %converts to upper case for plotting later
            chLocationName{ff,1} = strcat(hemis(TableChannel.channIDadjusted == chInterest(ff)), {' '}, strout);
        end
        emotionTaskLFP.ReferenceStrategy = 'CARallElectrodes'; 
        itiDataReal.ReferenceStrategy = 'CARallElectrodes';
    case 2
        chInterest = chInterestActual;
        data = double(macrowiresEm(chInterest,:)) - repmat(nanmean(macrowiresEm(chInterest,:),1), size(macrowiresEm(chInterest,:),1),1);
        %setup for accessing channels
        %channels in dixi and pmt are 1=distal contact, adtech is 1=proximal

        for ff=1:length(chInterest)
            ch = num2str(chInterest(ff));
            channelName{ff} = ['ch' ch];
            str = location(TableChannel.channIDadjusted ==chInterest(ff));
            strout = plt.lowup(str); %converts to upper case for plotting later
            chLocationName{ff,1} = strcat(hemis(TableChannel.channIDadjusted == chInterest(ff)), {' '}, strout);
        end
        emotionTaskLFP.ReferenceStrategy = 'CARElectrodesOfInterestOnly'; 
        itiDataReal.ReferenceStrategy = 'CARElectrodesOfInterestOnly';
    case 3
        %bipolar strategy

        idxBp = 1;
        for ii = 2:length(chInterestActual)
            if chInterestActual(ii)-chInterestActual(ii-1) == 1
                dataBp(idxBp,:) = macrowiresEm(chInterestActual(ii),:)-macrowiresEm(chInterestActual(ii-1),:);
                tempNum = [num2str(chInterestActual(ii)), num2str(chInterestActual(ii-1))];
                chInterestBp(idxBp) = str2double(tempNum);
                channelName{idxBp} = ['ch', num2str(chInterestBp(idxBp))];
                %for plotting naming later
                str = location(TableChannel.channIDadjusted ==chInterestActual(ii));
                strout = plt.lowup(str); %converts to upper case for plotting later
                chLocationName{idxBp,1} = strcat(hemis(TableChannel.channIDadjusted == chInterestActual(ii)), {' '}, strout);
                idxBp = idxBp + 1;
            end
        end       
        chInterest = chInterestBp;
        data = double(dataBp);
        emotionTaskLFP.ReferenceStrategy = 'Bipolar'; 
        itiDataReal.ReferenceStrategy = 'Bipolar';
end

%lowpass filter
dataFemotion = filtfilt(lpFilt,data');
%dataFemotionT = filtfilt(lpFilt,dataT');
%dataFemotionBp = filtfilt(lpFilt,dataBp');


% clear dataT; 
% clear macrowiresCAREm; 

%%  find image on
% set up the behavioral timestamps to ensure they are the presentation of
% the image 
%Hex code 19 task start; 29 image on; 39 fixation on; response 49; 
%for MW_16 and MW_18 hex codes are task start 619, image on 629, response
%made 649. (and fixation is 639)
%finds the image on time. realize this is variable but about 2 seconds.s
%this should be the indices of image on among TTLs (so like 2, 4, 6 etc)
switch fileVariation
    case {1}
        %if EvKey is present, it has the time stamps already and only those
        %time stamps.
        imageOn = 1:length(beh_timestampsEm);
        idx1 = 1;
        for ii = 2:length(imageOn)
            NWBtimeStampDiffEm(idx1,1) = beh_timestampsEm(ii)-beh_timestampsEm(ii-1);
            idx1 = idx1+1;
        end
    case 2 %MW_5
        %this is solved above but putting it here to be complete
        imageOn = imageOnEm;
        idx1 = 1;
        for ii = 2:length(imageOn)
            NWBtimeStampDiffEm(idx1,1) = beh_timestampsEm(ii)-beh_timestampsEm(ii-1);
            idx1 = idx1+1;
        end
    case {6}
        %MW13 seems to be this and maybe others?
        idx1 = 1; idx2 = 1;
        for ii=2:length(beh_timestampsEm)
            NWBtimeStampDiffEm(idx1,1) = beh_timestampsEm(ii)-beh_timestampsEm(ii-1);
            if NWBtimeStampDiffEm(idx1) >= 499001 && NWBtimeStampDiffEm(idx1) <= 500999 %it's 500000/1000000 or 0.5 s which i think is an image on and then image off. the whole trial is that 0.5 + the rest of the trial
                imageOn(idx2) = ii-1; %record the relevant image onsets indices, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (THIS APPEARS CONFIRMED)
                idx2 = idx2 + 1;
            end
            idx1 = idx1 +1;
        end
    case {3, 4, 5}
        hexNumEm = hexNum;
        imageOn = find(hexNumEm == 29 | hexNumEm == 629);
        idx1 = 1;
        for ii = 2:length(imageOn)
            NWBtimeStampDiffEm(idx1,1) = beh_timestampsEm(imageOn(ii))-beh_timestampsEm(imageOn(ii-1));
            idx1 = idx1+1;
        end
end
NWBtimeStampDiffEm = NWBtimeStampDiffEm/1000000;

% find the timestamp conversion of the phys data and the psychtoolbox data
if size(imageOn)>54
    warning('imageOn has too many timestamps, should be 54 max, so double check')
end
switch fileVariation
    case 2
        ttl_behImage = beh_timestampsEm; %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on
    case{1,3,4,5,6} %need to double check they all fit
        ttl_behImage = beh_timestampsEm(imageOn); %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on
end
%% get behavioral stamps
%convert the timestamps so you can go back to earlier steps
%Response is whether it is a match (1) or not match (0). CorrectResponse is the right answer. So to see if they gave the correct response you'd do (Response == CorrectResponse)
switch fileVariation
    case {3, 4} %later files with the Events
        TTLTimesEm = Events.Times.Image_Shown; %does not appear to be a true ttl time so it's now just the same as image time
        CorrectResponseEm = Stimuli.Correct_Responses;
        ResponseEm = Stimuli.Subject_Responses;
        ResponseTimesEm  = Events.Times.Response_Made;
        ImageTimesEm = Events.Times.Image_Shown;
    case {1, 2,6} %Early files without the structs
        %NOTE IN MW_1 THERE IS NOT TTLTIMES.
        TTLTimesEm = TTLTimes;
        CorrectResponseEm = CorrectResponse;
        ResponseEm = Response;
        ResponseTimesEm  = ResponseTimes;
        ImageTimesEm = ImageTimes;

end

if isempty(PresentedEmotionIdx)
    PresentedEmotionIdxEm = Stimuli.Presented_EmotionsIdx;
    PresentedIdentityIdxEm = Stimuli.Presented_IdentitiesIdx;
else
    PresentedEmotionIdxEm = PresentedEmotionIdx;
    PresentedIdentityIdxEm = PresentedIdentityIdx;
end


if ~isempty(TTLTimesEm) %MW1 doesn't have it
    ImageTimesDiffCheckEm = (ImageTimesEm-TTLTimesEm)*24*60*60; %in seconds to ensure that the TTLs and Imagetimes are as expected, close
end
%this is an attempt to make sure the times for the image onsets are on
%point, but a lot of caveats per case. MW24 has something weird with the ttls so you just ignore the first behavioral event marker for the first image and start at the second.
%This part will error but you can see that after the first image the times match up. And then it's kluged together from there. 
for ii= 1:length(ImageTimesEm)-1
    PTB_ImageTimesDiffEm(ii,1) = (ImageTimesEm(ii+1)-ImageTimesEm(ii))*24*60*60;
end
if ~strcmp(sessionName, 'MW_24') %see above but this doesn't work for MW24 but it has been checked, has to do with a ttl that didn't make it.
    switch fileVariation
        case {1,2,3,4,5}
            PTB_NWBImageDiffEm = PTB_ImageTimesDiffEm-NWBtimeStampDiffEm;
            PTB_NWBImageDiffEm(:,2) = PTB_ImageTimesDiffEm;
            PTB_NWBImageDiffEm(:,3) = NWBtimeStampDiffEm;
            open PTB_NWBImageDiffEm;
        case 6
            idx = 1;
            for ii = 1:length(imageOn)-1
                trialTimesEm(idx,1) = NWBtimeStampDiffEm(imageOn(ii)) + NWBtimeStampDiffEm(imageOn(ii)+1);
                idx = idx+1;
            end
            PTB_NWBImageDiffEm = PTB_ImageTimesDiffEm-trialTimesEm;
            PTB_NWBImageDiffEm(:,2) = PTB_ImageTimesDiffEm;
            PTB_NWBImageDiffEm(:,3) = trialTimesEm;

    end
    if nnz(find(abs(PTB_NWBImageDiffEm(:,1))>0.1))>0
        warning('Image time diff between TTLs and image on is more than 100ms and likely the timing is off')
    end
end

if strcmp(sessionName, 'MW_24')%special case MW_24 where the first image on is not in the ttls for em task only
    ImageTimesAdjEm = ttl_behImage;
elseif    ~isempty(TTLTimesEm) %MW1 doesn't have it
    ImageTimesDiff = ImageTimesDiffCheckEm*1e6; %convert to microseconds
    ImageTimesAdjEm = ttl_behImage+ImageTimesDiff; %moves the time into neural time scale
else
    ImageTimesAdjEm = ttl_behImage;
end

%if the response is a NaN, make it the next ttl
ResponseTimesNanRemoved = ResponseTimesEm;
ResponseNanRemoved = ResponseEm;
for ii = 2:length(ResponseTimesNanRemoved)
    if isnan(ResponseTimesNanRemoved(ii))
        ResponseNanRemoved(ii) = ~CorrectResponseEm(ii);
        ResponseTimesNanRemoved(ii) = ImageTimesEm(ii+1);
    end
end

%both gets the response adjusted and finds the "iti" which is the time
%between the response and the next image being shown.
if strcmp(sessionName, 'MW_24')
    ResponseTimesDiffEmotion = (ResponseTimesNanRemoved-TTLTimesEm)*24*60*60*1e6; %this takes the difference between the response and the TTL which is image on (in the hex code, you dont' need this but it still works)
    itiTimeEmotion = (ImageTimesEm(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60; %take the image time between the response and the next image.
    ResponseTimesAdjEm = ttl_behImage+ResponseTimesDiffEmotion(2:end);
elseif ~isempty(TTLTimesEm) %MW1 doesn't have it
    ResponseTimesDiffEmotion = (ResponseTimesNanRemoved-TTLTimesEm)*24*60*60*1e6; %this takes the difference between the response and the TTL which is image on (in the hex code, you dont' need this but it still works)
    itiTimeEmotion = (ImageTimesEm(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60; %take the image time between the response and the next image.
    ResponseTimesAdjEm = ttl_behImage+ResponseTimesDiffEmotion; %moves the time into neural time scale
else
    ResponseTimesDiffEmotion = (ResponseTimesEm-ImageTimesEm)*24*60*60*1e6; %this takes the difference between the response and the TTL (in microseconds) which is image on (in the hex code, you dont' need this but it still works)
    itiTimeEmotion = (ImageTimesEm(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60; %take the image time between the response and the next image.
    ResponseTimesAdjEm = ttl_behImage + ((ResponseTimesEm-ImageTimesEm)*24*60*60*1e6);
end

%find if the responses were correct or not
ResponseNanRemoved(1) = []; %remove the non first trial;
CorrectTrialsEm = CorrectResponseEm == ResponseNanRemoved;


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



%% process data with main proc function (see above to set this)
%this will break up the data. Can adjust the spectrogram window center
%point here (so beginning (1), middle(2), or end(3) of the moving window)
%the final filtered data (1to200) is broad so it can be inserted into PAC
%as desired

[emotionTaskLFP, itiDataReal.EmotionTask.trueIti] = Analysis.emuEmot.nwbLFPchProc(itiDataFiltEmotion, PresentedEmotionIdxEm,...
    PresentedIdentityIdxEm, behavioralIndexImageOnEm, behavioralIndexResponseEm, ...
    'fs', fs, 'chNum', chInterest, 'itiTime', itiTimeEmotion,...
    'ImpreTime', preTime, 'ImpostTime', postTime, 'RespreTime', preTimeRes, 'RespostTime', postTimeRes, 'multiTaperWindow',...
    multiTaperWindow, 'CorrectTrials', CorrectTrialsEm, 'ResponseTimesAdj', ResponseTimesDiffEmotion);


%this is an option to make an iti that is a bunch of random times chosen.
%iti count is 250 so it will be 500 total, 250 from each. the total time is
%about 335 seconds to 250 1 s ITIs.
if randomTimeIti
    [itiDataReal.EmotionTask.RandomTimeIti, percKeptbyChEm] = Analysis.emuEmot.nwbLFPchProc_ITIRandomTimes(itiDataFiltEmotion, 'fs', fs,...
        'chNum', chInterest, 'itiCount', 250, 'itiEpochMinus', 0.5, 'itiEpochPlus', 0.5 );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% second set of data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Identity run 
switch fileVariation
    case {1,3,6}  %for two nwb files
        beh_timestamps = [];
        ma_timestamps = [];
        cellVar = [];
        imageOn = [];
        ResponseTimes = [];
        Response = [];
        TTLTimes = [];
        CorrectResponse = [];
        ImageTimes = [];
        ma_timestampsDSEm = [];
        ma_timestampsDSId = [];
        PresentedEmotionIdx = [];
        PresentedIdentityIdx = [];
        dataBp = [];
        data = [];
        combinedEvKey = [];

    case 2 %one nwb and one EvKey
        ResponseTimes = [];
        Response = [];
        TTLTimes = [];
        CorrectResponse = [];
        ImageTimes = [];
        imageOn = [];
        PresentedEmotionIdx = [];
        PresentedIdentityIdx = [];
        ma_timestampsDSId = ma_timestampsDSEm;
        data = [];

    case 4 %two nwb and good hex
        hexNumId = [];
        imageOn = [];
        dataBp = [];
        data = [];
        combinedEvKey = [];


end


%% load the behavioral data

taskName = 'Identity';
folderName=strcat('Z:\KramerEmotionID_2023\Data\EMU_nBack', '\', sessionName, '\', matNameId);
trialEm = false;
load(folderName)

%identityFilter = 'MW_9_Session_12_filter.nwb'; %this is done as an earlier
%step but is here for ease of checking different nwbs
switch fileVariation
    case 1
        macrowires = [];
        run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
        macrowiresId = macrowires;
        macrowires = [];
        for jj = 1:length(EvKeyId.Names)
            combinedEvKey{jj,1} = EvKeyId.Names{jj};
            combinedEvKey{jj,2} = EvKeyId.Codes(jj);
            combinedEvKey{jj,3} = EvKeyId.GoodTTLs(jj);
        end
        beh_timestampsId =  beh_timestamps(EvKeyId.GoodTTLs);
        ma_timestampsDSId = ma_timestampsDS; %downsamle the timestamps
              
       [behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsId, ma_timestampsDS); %finds the ttl

    case {4, 6} %for two nwb files
        macrowires = [];
        run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
        macrowiresId = macrowires;
        macrowires = [];
        beh_timestampsId = beh_timestamps;
        ma_timestampsDSId = ma_timestampsDS; %downsamle the timestamps
    case 3 %This is two NWB files and two behavioral files with EvKey and messed up hex.
        macrowires = [];
        run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
        macrowiresId = macrowires;
        macrowires = [];
        beh_timestampsId = beh_timestamps;
        ma_timestampsDSId = ma_timestampsDS; %downsamle the timestamps
        % convert to individual so they are saved and can go back to earlier steps
        %will need to load the file Rex created
        %convert the hex codes to the appropriate codes
        %this is a way to combine the keys to look all as one
        %you don't need the commented out part, but it puts it together for
        %ease of looking at
        %For looking at the combined hexs
        for jj = 1:length(EvKeyId.Names)
            combinedEvKey{jj,1} = EvKeyId.Names{jj};
            combinedEvKey{jj,2} = EvKeyId.Codes(jj);
            combinedEvKey{jj,3} = EvKeyId.GoodTTLs(jj);
        end
        %convert the hex codes to the real hex codes
        %db stop
        hexNum(EvKeyId.GoodTTLs*2,1) = EvKeyId.Codes;
        hexNumId = hexNum;
end
    %for MW_16
    % if strcmp(sessionName, ('MW_16'))
    % [behavioralIndexTTLId, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestampsId, ma_timestampsDS); %finds the ttl
    % macrowiresId = macrowiresId(:,behavioralIndexTTLId(627)-(fs*5):end); %remove all but 5 seconds worth of the macrowire data
    % ma_timestampsDSId = ma_timestampsDS(behavioralIndexTTLId(627)-(fs*5):end);
    % end


%filter the data if two nwb files
switch fileVariation
    case {1, 3, 4, 6} %for two files so needs to be run again.
    switch referenceStrategy
        case 1
            macrowiresCARId = double(macrowiresId) - repmat(nanmean(macrowiresId,1), size(macrowiresId,1),1);
            %cut data to channels of interest
            data = double(macrowiresCAREm(chInterest, :));
            identityTaskLFP.ReferenceStrategy = 'CARallElectrodes';
            itiDataReal.ReferenceStrategy = 'CARallElectrodes';
        case 2 
            data = double(macrowiresId(chInterest,:)) - repmat(nanmean(macrowiresId(chInterest,:),1), size(macrowiresId(chInterest,:),1),1);
            identityTaskLFP.ReferenceStrategy = 'CARElectrodesOfInterestOnly';
            itiDataReal.ReferenceStrategy = 'CARElectrodesOfInterestOnly';
        case 3
            %bipolar strategy

            idxBp = 1;
            for ii = 2:length(chInterestActual)
                if chInterestActual(ii)-chInterestActual(ii-1) == 1
                    dataBp(idxBp,:) = macrowiresId(chInterestActual(ii),:)-macrowiresId(chInterestActual(ii-1),:);
                    idxBp = idxBp + 1;
                end
            end
            data = double(dataBp);

            identityTaskLFP.ReferenceStrategy = 'Bipolar';
            itiDataReal.ReferenceStrategy = 'Bipolar';
    end
    %lowpass filter
    dataFidentity = filtfilt(lpFilt,data');
    clear data;   
end

%primarily gets image on so no need to do if one file and have the image on
%for the ID task
switch fileVariation
    case {1} %EvKey and no hex
        %if EvKey is present, it has the time stamps already and only those
        %time stamps.
        imageOn = 1:length(beh_timestampsId);
        idx1 = 1;
        for ii = 2:length(imageOn)
            NWBtimeStampDiffId(idx1,1) = beh_timestampsId(ii)-beh_timestampsId(ii-1);
            idx1 = idx1+1;
        end
    case 2
        imageOn = imageOnId;
        idx1 = 1;
        for ii = 2:length(imageOn)
            NWBtimeStampDiffId(idx1,1) = beh_timestampsId(ii)-beh_timestampsId(ii-1);
            idx1 = idx1+1;
        end
    case 6 %two files EvKey, bad hex or no hex MW13 here
        idx1 = 1; idx2 = 1;
        for ii=2:length(beh_timestampsEm)
            NWBtimeStampDiffId(idx1) = beh_timestampsId(ii)-beh_timestampsId(ii-1);
            if NWBtimeStampDiffId(idx1) >= 499001 && NWBtimeStampDiffId(idx1) <= 500999 %50000/500 = 1000ms
                imageOn(idx2) = ii-1; %record the relevant image onsets indices, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (THIS APPEARS CONFIRMED)
                idx2 = idx2 + 1;
            end
            idx1 = idx1 +1;
        end
    case {3, 4, 5} %two files, good hex
        hexNumId = hexNum;
        imageOn = find(hexNumId == 29 | hexNumId == 629);
        idx1 = 1;
        for ii = 2:length(imageOn)
            NWBtimeStampDiffId(idx1,1) = beh_timestampsId(imageOn(ii))-beh_timestampsId(imageOn(ii-1));
            idx1 = idx1+1;
        end
end
NWBtimeStampDiffId =NWBtimeStampDiffId/1000000;

%get the TTLtimes from the behavioral file at some point it switched to
%Events, so will have to make sure it has events for each of them
%for two behavioral files
switch fileVariation
    case {3,4} %newer files
        TTLTimesId = Events.Times.Image_Shown; %does not appear to be a true ttl time so it's now just the same as image time
        CorrectResponseId = Stimuli.Correct_Responses;
        ResponseId = Stimuli.Subject_Responses;
        ResponseTimesId  = Events.Times.Response_Made;
        ImageTimesId = Events.Times.Image_Shown;
        PresentedEmotionIdxId = Stimuli.Presented_EmotionsIdx;
        PresentedIdentityIdxId = Stimuli.Presented_IdentitiesIdx;
    case {1, 2,6}  %older files
        TTLTimesId = TTLTimes;
        CorrectResponseId = CorrectResponse;
        ResponseId = Response;
        ResponseTimesId  = ResponseTimes;
        ImageTimesId = ImageTimes;
        PresentedEmotionIdxId = PresentedEmotionIdx;
        PresentedIdentityIdxId = PresentedIdentityIdx;
end


%% find the behavioral timestamps
%% 

% find the timestamp conversion of the phys data and the psychtoolbox data
if size(imageOn)>54
    warning('imageOn has too many timestamps, should be 54 max, so double check')
end

switch fileVariation
    case 2
        ttl_behImage = beh_timestampsId; %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on

    case {1,3,4,5,6}
        ttl_behImage = beh_timestampsId(imageOn); %get only the ttls of image on (verified these match the TTL output of psych toolbox and image on
end

if ~isempty(TTLTimesId) %MW1 doesn't have it
ImageTimesDiffCheckId = (ImageTimesId-TTLTimesId)*24*60*60; %in seconds to ensure that the TTLs and Imagetimes are as expected, closefor ii= 1:length(ImageTimesId)-1
end
%here you are comparing the image times from the nwb (NWBtimeStampDiffId)
%and from the behavioral file from psych toolbox (PTB_ImageTimesDiffId).
%they should be on point with minimal differences. This really should
%verify that your timing strategy is correct.
for ii = 1:length(ImageTimesId)-1
    PTB_ImageTimesDiffId(ii,1) = (ImageTimesId(ii+1)-ImageTimesId(ii))*24*60*60;
end
switch fileVariation
    case {1,2,3,4,5}
        PTB_NWBImageDiffId = PTB_ImageTimesDiffId-NWBtimeStampDiffId;
        PTB_NWBImageDiffId(:,2) = PTB_ImageTimesDiffId;
        PTB_NWBImageDiffId(:,3) = NWBtimeStampDiffId;
        open PTB_NWBImageDiffId;
    case 6
        idx = 1;
        for ii = 1:length(imageOn)-1
            trialTimesId(idx,1) = NWBtimeStampDiffId(imageOn(ii)) + NWBtimeStampDiffId(imageOn(ii)+1);
            idx = idx+1;
        end
        PTB_NWBImageDiffId = PTB_ImageTimesDiffId-trialTimesId;
        PTB_NWBImageDiffId(:,2) = PTB_ImageTimesDiffId;
        PTB_NWBImageDiffId(:,3) = trialTimesId;

end

if nnz(find(abs(PTB_NWBImageDiffId(:,1))>0.1))>0
    warning('Image time diff between TTLs and image on is more than 100ms and likely the timing is off')
end

if ~isempty(TTLTimesId) %MW1 doesn't have it
    ImageTimesDiff = ImageTimesDiffCheckId*1e6; %convert to microseconds
    ImageTimesAdjId = ttl_behImage+ImageTimesDiff; %moves the time into neural time scale
else
    ImageTimesAdjId = ttl_behImage;
end


%if the response is a NaN, make it the next ttl
ResponseTimesNanRemoved = ResponseTimesId;
ResponseNanRemoved = ResponseId;
for ii = 2:length(ResponseTimesNanRemoved)
    if isnan(ResponseTimesNanRemoved(ii))
        ResponseNanRemoved(ii) = ~CorrectResponseId(ii);
        ResponseTimesNanRemoved(ii) = ImageTimesId(ii+1);
    end
end


if ~isempty(TTLTimesEm) %MW1 doesn't have it
    ResponseTimesDiffIdentity = (ResponseTimesNanRemoved-TTLTimesId)*24*60*60*1e6;
    itiTimeIdentity = (ImageTimesId(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60;
    ResponseTimesAdjId = ttl_behImage+ResponseTimesDiffIdentity; %moves the time into neural time scale

else
    ResponseTimesDiffIdentity = (ResponseTimesId-ImageTimesId)*24*60*60*1e6; %this takes the difference between the response and the TTL which is image on (in the hex code, you dont' need this but it still works)
    itiTimeIdentity = (ImageTimesId(3:end)-ResponseTimesNanRemoved(2:end-1))*24*60*60; %take the image time between the response and the next image.
    ResponseTimesAdjId = ttl_behImage + ((ResponseTimesId-ImageTimesId)*24*60*60*1e6);
end

%find if the responses were correct or not
ResponseNanRemoved(1) = []; %remove the non first trial;
CorrectTrialsId = CorrectResponseId == ResponseNanRemoved;

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
%Only do this if there are two files

[behavioralIndexImageOnId, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjId, ma_timestampsDSId);
[behavioralIndexResponseId, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjId, ma_timestampsDSId);



%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
%preStartData = dataFidentity; %can adjust if want to exclude part of the data
%filters the entire trial.
switch fileVariation % for two nwb files.
    case {1, 3, 4,6}
        [itiDataFiltIdentity] = Analysis.emuEmot.nwbLFPchProcITI(dataFidentity, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
    case 2 %any single files where you've run the whole thing already
        itiDataFiltIdentity = itiDataFiltEmotion;
end


%% process data with main proc function (see above to set this)
%this will break up the data. Can adjust the spectrogram window center
%point here (so beginning (1), middle(2), or end(3) of the moving window)
%the final filtered data (1to200) is broad so it can be inserted into PAC
%as desired
   [identityTaskLFP, itiDataReal.IdentityTask.trueIti] = Analysis.emuEmot.nwbLFPchProc(itiDataFiltIdentity, PresentedEmotionIdxId,...
       PresentedIdentityIdxId, behavioralIndexImageOnId, behavioralIndexResponseId, ...
       'fs', fs, 'chNum', chInterest, 'itiTime', itiTimeIdentity,...
       'ImagepreTime', preTime, 'ImagepostTime', postTime, 'ResponsepreTime', preTimeRes, 'ResponsepostTime', postTimeRes, 'multiTaperWindow',...
       multiTaperWindow, 'CorrectTrials', CorrectTrialsId, 'ResponseTimesAdj', ResponseTimesDiffIdentity);

   %this is an option to make an iti that is a bunch of random times chosen.
%iti count is 250 so it will be 500 total, 250 from each. the total time is
%about 335 seconds to 250 1 s ITIs.
if randomTimeIti
    [itiDataReal.IdentityTask.RandomTimeIti, percKeptbyChId] = Analysis.emuEmot.nwbLFPchProc_ITIRandomTimes(itiDataFiltIdentity, 'fs', fs,...
        'chNum', chInterest, 'itiCount', 250, 'itiEpochMinus', 0.5, 'itiEpochPlus', 0.5 );
end

%record details of the run of the iti. threshold is what was the automatic
%removal threshold. percentKept is how many were kept and 1-percentKept is
%how many were rejected.
MWX.itiSDThresh = itiDataReal.IdentityTask.RandomTimeIti.sdThresh;  
MWX.itiTime = itiDataReal.IdentityTask.RandomTimeIti.tPlot; 
MWX.percentKeptIti.Id = percKeptbyChId;
MWX.percentKeptIti.Em = percKeptbyChEm;

%% next section is Analysis.emuEmot.EMUNBACK_NOISECHECK.M
% then Analysis.emuEmot.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT.M
% then Analysis.emuEmot.emuEmot.EMUNBACK_COMPAREACROSSPATIENTS.M (BUT, that
% one is mostly by hand and to be placed into excel file)

edit Analysis.emuEmot.EMUNBACK_NOISECHECK
