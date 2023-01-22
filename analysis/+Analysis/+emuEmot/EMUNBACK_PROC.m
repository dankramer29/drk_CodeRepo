%% major script for running the processing of an individual patient
%TO DO IS PLACE VARIABLES IN THE FILE NAMES TO EASILY SWITCH PATIENT
%FEW THINGS STILL TO CHECK, CAUSE DOES STILL LOOK STREAKY. FIRST, JUST RUN
%WITH REAL DATA WHEN JOHN GIVES IT TO YOU AND SEE WHAT IT LOOKS LIKE. THEN,
%TRY THE OTHER LOWPASS FILTER FUNCTION. CHECK THAT IT'S GOING THE CORRECT
%DIRECTION WHEN FILTERING (I THINK IT ERRORS THE OTHER WAY, BUT EASY ENOUGH
%TO FLIP IT AND FIND OUT AND TRY THE OTHER FUNCTION). TRY THE OTHER
%NORMALIZE FUNCTION EVEN THOUGH YOU TRIED THAT...ALSO TRY THE OTHER
%SPECTROGRAM FUNCTION OR PSPECTRUM, WHATEVER MATLAB HAS AND FIGURE OUT THE
%OUTPUTS SO YOU CAN NORMALIZE IT AND SEE WHAT IT LOOKS LIKE.

% set to 0 if running this with a new data set for the first time, set to
% 1 if you saved the filtered data after running
% Analysis.emuEmot.nwbLFPchProc and don't want to keep running it
%Set up if you are saving and then loading the filtered data
alreadyFilteredData = 0; 

%% choose raw data or not
rawData = 0; %turn to 0 if wanting to use the filtered data

%%
% EMUNBACK_PROC
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

%% setup details of the processing
%MW3
chInterest = [69, 77, 148];
%MW13
%chInterest = [17, 25, 97];
% locationsInt = ['LAMY', 'RAMY', 'LAH', 'RAH', 'LPOL', 'RPOL']; % can
% return to this, for now probably easier to pick by hand, this was a setup
% to automatically pull the electrode numbers
fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s

extraTime = 3; %amount in seconds, to add to the end of the recordings

%time in seconds to add before and after the events
preTime = 0.5; 
postTime = 2; 


%% Event files

%% Load NWB
% Emotion

if rawData == 0
        testfile = nwbRead('MW3_Session_13_filter.nwb');
           %     testfile = nwbRead('MW13_Session_5_filter.nwb');

elseif rawData == 1
        testfile = nwbRead('MW3_Session_11_raw.nwb');
end




%MW3_Session14_filter.nwb (NBack Emotion): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3_Session12_filter.nwb (NBack Identity): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%(MW3_Session11_filter.nwb = MW3_Session12_filter.nwb but the filtering is
%better)
% MW13_Session_10_filter.nwb — NBack_IDENTITY_2022_5_29…
% MW13_Session_11_filter.nwb — NBack_EMOTION_2022_5_29…
%What this means is that beh_timestamps(2) = ImageTimes(1) = Image 1 and then beh_timestamps(4) = ImageTimes(2) = Image 2 
%run the script to pull in the data from nwb if needed

run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
load('C:\Users\kramdani\Documents\Data\EMU_nBack\4_12_2022session\EmotionSession\NBack_2021_05_04.12_53_08_BLIND.mat')
%load('C:\Users\kramdani\Documents\Data\EMU_nBack\5_29_2022session\Emotion\NBack_EMOTION_2022_5_29.18_10_57_BLIND.mat')
nbackData.task = matchStr;




%% pull in wire ids
%pull wire numbers and wire ids
wireID{:,1} = testfile.general_extracellular_ephys_electrodes.vectordata.get('wireID').data.load();  
wireID{:,2} = testfile.general_extracellular_ephys_electrodes.vectordata.get('shortBAn').data.load(); 

%setup for accessing channels
%channels in dixi and pmt are 1=distal contact, adtech is 1=proximal
%contact and 
for ii = 1:length(wireID{2})
    chName{ii,1} = wireID{2}(ii,:);
end


%common average rerefernce
macrowiresCAR = double(macrowires) - repmat(nanmean(macrowires,1), size(macrowires,1),1);

%this pulls a whole set of data in, that you can pull info from, if more
%than wireID is needed:
%columns = testfile.general_extracellular_ephys_electrodes.vectordata;

%% run a noise/artifact rejection



%% low pass the data (nyquist 250)
lpFilt = designfilt('lowpassiir','FilterOrder',8, ...
'PassbandFrequency',200,'PassbandRipple',0.2, ...
'SampleRate',500);

%cut data to channels of interest
data = double(macrowiresCAR(chInterest, :));

%lowpass filter
dataF = filtfilt(lpFilt,data');

%high pass if raw data
% lpFiltHigh = designfilt('highpassiir','FilterOrder',8, ...
% 'PassbandFrequency',1,'PassbandRipple',0.2, ...
% 'SampleRate',500);
%highpass filter
%dataF = filtfilt(lpFiltHigh,dataF);

%% find the behavioral timestamps
%downsamle the timestamps (ma_timestamps comes from the nwb as well)
ma_timestampsDS=downsample(ma_timestamps, 8);

%% 

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);

%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);


%% process data with main proc function (see above to set this)

if alreadyFilteredData == 1
    % need to change path but also change the name if done in the future
    load C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession\FiltData_NBack_2021_05_04.12_53_08_BLIND.mat
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'filtData', filtData, 'preTime', preTime, 'postTime', postTime);
elseif alreadyFilteredData ~= 1
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx, 'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'preTime', preTime, 'postTime', postTime);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% second set of data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Identity run
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));
        testfile = nwbRead('MW3_Session_11_filter.nwb');
run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
load('C:\Users\kramdani\Documents\Data\EMU_nBack\4_12_2022session\FacialRecSession\NBack_2021_05_04.12_43_46_BLIND.mat')
nbackData.task = matchStr;

%%
alreadyFilteredData = 0;
%% common average rerefernce
macrowiresCAR = double(macrowires) - repmat(nanmean(macrowires,1), size(macrowires,1),1);

%% low pass the data (nyquist 250)
lpFiltlow = designfilt('lowpassiir','FilterOrder',8, ...
'PassbandFrequency',200,'PassbandRipple',0.2, ...
'SampleRate',fs);

%% high pass the data (nyquist 250)
lpFilthigh = designfilt('highpassiir','FilterOrder',8, ...
'PassbandFrequency',1,'PassbandRipple',0.2, ...
'SampleRate',fs);

%cut data to channels of interest
data = double(macrowiresCAR(chInterest, :));

%lowpass filter
dataF = filtfilt(lpFiltlow,data');
%highpass filter
dataF = filtfilt(lpFilthigh,data');

%% find the behavioral timestamps
%downsamle the timestamps
ma_timestampsDS=downsample(ma_timestamps, 8);

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);

if alreadyFilteredData == 1
    load C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession\FiltData_NBack_2021_05_04.12_53_08_BLIND.mat
    [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'filtData', filtData, 'preTime', preTime, 'postTime', postTime);
elseif alreadyFilteredData ~= 1
    [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx, 'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'preTime', preTime, 'postTime', postTime);
end

%% compare identity task/emotion task within a channel
%create an "iti" baseline
% TO DO, PLOT THE ITIS TO SHOW THAT IT IS PRETTY NEUTRAL.

preStartData = dataF(1:behavioralIndex(2),:);
timeForIti = length(preStartData)/fs;
trialLength = preTime + postTime;
itiData = stats.shuffleDerivedBaseline(preStartData, 'shuffleLength', 0.05, 'trialLength', trialLength);
[itiDataFilt] = Analysis.emuEmot.nwbLFPchProcITI(itiData, 'chNum', chInterest);
%This will run stats to compare the same identities or same emotions but
%across the two different tasks
%TO DO, THE SIG CLUSTERS IS MESSED UP AND DOING HUGE SWATHS AS POSITIVE,
%MAY MAKE SENSE TO NORMALIZE FIRST? PROBABLY DOES ACTUALLY, TAKE THE MEAN,
%THEN NORMALIZE, THEN TAKE THE CLUSTERS.
[nbackCompare, sigComparison] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP, 'chInterest', chInterest, 'itiDataFilt', itiDataFilt);






