%% major script for running the processing of an individual patient
%%
% EMUNBACK_PROC
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

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
%% change the details for each patient
%MW13
chInterest = [23, 24, 31, 32, 33, 34, 83, 84, 97, 98]; %REMEMBER, IF THE MICROWIRES, IT'S ADTECH AND 8 IS DISTAL, IF IT'S NOT MICROWIRE (I.E. PMT OR DIXI) THEN 1 IS DISTAL 
preSpectrogramData = true; %either chop the data as already multitapered and then cut it up (true) or as raw voltage, cut it up, then process it by multitaper (false)
alreadyFilteredData = true; %toggle to true if you've run the entire dataset through LFP processing already

sessionName = '5_29_2022session';
subjName = 'MW13';

MW13 = struct;

matNameEm = 'NBack_EMOTION_2022_5_29.18_10_57_BLIND.mat';
matNameId = 'NBack_IDENTITY_2022_5_29.18_5_50_BLIND.mat';
emotionFilter = 'MW13_Session_10_filter.nwb';
identityFilter = 'MW13_Session_9_filter.nwb';

%% setup details of the processing
fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s
extraTime = 3; %amount in seconds, to add to the end of the recordings
%time in seconds to add before and after the events
preTime = 0.5; 
postTime = 2; 
% sets the shuffling parameters, so it's stitching post multi-tapered data,
% then smoothing it.
multiTaperWindow = .2; % in seconds, what window you are doing on this run for multitapering spectrograms
smoothingWindow = .025; % in seconds, gaussian smooth
shuffleLength = .05; %in seconds, the length of the stitched shuffles
stitchTrialNum = 100; %number of trials to make the stitching out of.

%% choose raw data or not
rawData = 0; %turn to 0 if wanting to use the filtered data (DON'T NEED TO DO THIS)

%%
taskName = 'Emotion';
folderName=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName, '\', taskName, '\', matNameEm);

%%
% set to 0 if running this with a new data set for the first time, set to
% 1 if you saved the filtered data after running
% Analysis.emuEmot.nwbLFPchProc and don't want to keep running it
%Set up if you are saving and then loading the filtered data

if alreadyFilteredData
   load('C:\Users\kramdani\Documents\Data\EMU_nBack\5_29_2022session\Identity\allDataFiltered_IdentityTask.mat');
   load('C:\Users\kramdani\Documents\Data\EMU_nBack\5_29_2022session\Emotion\allDataFiltered_EmotionTask.mat'); 
else
    itiDataFiltEmotion = [];
    itiDataFiltIdentity = [];
end

%% Load NWB
% Emotion
if rawData == 0
                testfile = nwbRead(emotionFilter);
elseif rawData == 1
        testfile = nwbRead('MW3_Session_11_raw.nwb');
end

run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m

%load('C:\Users\kramdani\Documents\Data\EMU_nBack\4_12_2022session\EmotionSession\NBack_2021_05_04.12_53_08_BLIND.mat')
load(folderName)
nbackData.task = matchStr;

%% pull in wire ids
%pull wire numbers and wire ids
wireID{:,1} = testfile.general_extracellular_ephys_electrodes.vectordata.get('wireID').data.load();  
wireID{:,2} = testfile.general_extracellular_ephys_electrodes.vectordata.get('shortBAn').data.load(); 
wireID{:,3} = testfile.general_extracellular_ephys_electrodes.vectordata.get('channID').data.load(); 

%setup for accessing channels
%channels in dixi and pmt are 1=distal contact, adtech is 1=proximal
%contact and 
for ii = 1:length(wireID{2})
    chName{ii,1} = wireID{2}(ii,:);
    chName{ii,2} = wireID{3}(ii,:);
end

for ff=1:length(chInterest)
    ch = num2str(chInterest(ff));
    channelName{ff} = ['ch' ch];
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
dataFemotion = filtfilt(lpFilt,data');

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
ImageTimesAdjEm = ttl_beh+ImageTimesDiff; %moves the time into neural time scale

ResponseTimesDiffEmotion = (ResponseTimes-TTLTimes)*24*60*60*1e6;
ResponseTimesAdjEm = ttl_beh+ResponseTimesDiffEmotion; %moves the time into neural time scale

%find if the responses were correct or not
Response(isnan(Response)) = [];
CorrectTrialsEm = CorrectResponse == Response;


%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndexTTL, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);
[behavioralIndexImageOn, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjEm, ma_timestampsDS);
[behavioralIndexResponse, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjEm, ma_timestampsDS);


%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
preStartData = dataFemotion; %can adjust if want to exclude part of the data
%filters the entire trial.
if alreadyFilteredData == 0
    [itiDataFiltEmotion] = Analysis.emuEmot.nwbLFPchProcITI(preStartData, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
end

%% process data with main proc function (see above to set this)
%this will break up the data. Can adjust the spectrogram window center
%point here (so beginning (1), middle(2), or end(3) of the moving window)
if preSpectrogramData
   [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(itiDataFiltEmotion, PresentedEmotionIdx,...
       PresentedIdentityIdx, behavioralIndexImageOn, behavioralIndexResponse, ...
       'fs', fs, 'chNum', chInterest,...
       'preTime', preTime, 'postTime', postTime, 'multiTaperWindow', multiTaperWindow);
else
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataFemotion, PresentedEmotionIdx,...
        PresentedIdentityIdx, behavioralIndexImageOn, behavioralIndexResponse,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest,...
        'preTime', preTime, 'postTime', postTime, 'multiTaperWindow', multiTaperWindow);
end
%% create and iti
itiDataStitch = struct;
trialLength = preTime + postTime;
%stritch the iti trials together
for ii= 1:length(channelName)
    S1 = itiDataFiltEmotion.iti.(channelName{ii}).specD;
    
    [itiDataStitch.EmotionTask.(channelName{ii})] = stats.shuffleDerivedBaseline(S1, 'fs',...
        size(emotionTaskLFP.byemotion.(channelName{ii}).image.specD{1}, 2)/trialLength, ...
        'shuffleLength', shuffleLength, 'trials', stitchTrialNum, 'stitchSmooth',...
        true, 'TimeFreqData', true, 'smoothingWindow', smoothingWindow);
end
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

%% high pass the data (nyquist 250)
lpFilthigh = designfilt('highpassiir','FilterOrder',8, ...
'PassbandFrequency',1,'PassbandRipple',0.2, ...
'SampleRate',fs);

%cut data to channels of interest
data = double(macrowiresCAR(chInterest, :));

%lowpass filter
dataFidentity = filtfilt(lpFiltlow,data');
%highpass filter if raw
%dataF = filtfilt(lpFilthigh,dataF');

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
ResponseTimesAdjId = ttl_beh+ResponseTimesDiffIdentity; %moves the time into neural time scale

%find if the responses were correct or not
Response(isnan(Response)) = [];
CorrectTrialsId = CorrectResponse == Response;


%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndexTTL, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);
[behavioralIndexImageOn, closestValue] = Analysis.emuEmot.timeStampConversion(ImageTimesAdjId, ma_timestampsDS);
[behavioralIndexResponse, closestValue] = Analysis.emuEmot.timeStampConversion(ResponseTimesAdjId, ma_timestampsDS);


%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%% Filter all the data
preStartData = dataFidentity; %can adjust if want to exclude part of the data
%filters the entire trial.
if alreadyFilteredData == 0
    [itiDataFiltIdentity] = Analysis.emuEmot.nwbLFPchProcITI(preStartData, 'chNum', chInterest, 'multiTaperWindow', multiTaperWindow);
end

%% process data with main proc function (see above to set this)
%this will break up the data. Can adjust the spectrogram window center
%point here (so beginning (1), middle(2), or end(3) of the moving window)
if preSpectrogramData
   [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(itiDataFiltIdentity, PresentedEmotionIdx,...
       PresentedIdentityIdx, behavioralIndexImageOn, behavioralIndexResponse, ...
       'fs', fs, 'chNum', chInterest,...
       'preTime', preTime, 'postTime', postTime, 'multiTaperWindow', multiTaperWindow);
else
    [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataFidentity, PresentedEmotionIdx,...
        PresentedIdentityIdx, behavioralIndexImageOn, behavioralIndexResponse,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest,...
        'preTime', preTime, 'postTime', postTime, 'multiTaperWindow', multiTaperWindow);
end
%% create and iti
trialLength = preTime + postTime;
%stritch the iti trials together
for ii= 1:length(channelName)
    S1 = itiDataFiltIdentity.iti.(channelName{ii}).specD;

    [itiDataStitch.IdentityTask.(channelName{ii})] = stats.shuffleDerivedBaseline(S1, 'fs',...
        size(emotionTaskLFP.byemotion.(channelName{ii}).image.specD{1}, 2)/trialLength, ...
        'shuffleLength', shuffleLength, 'trials', stitchTrialNum, 'stitchSmooth',...
        true, 'TimeFreqData', true, 'smoothingWindow', smoothingWindow);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compare the tasks

%  allEmotions and allIdentities are the same since it's just all images
%  shown
[nbackCompareImageOn, sigComparisonImageOn] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP,...
    'chInterest', chInterest, 'itiDataFilt', itiDataStitch, 'xshuffles', 100, 'eventChoice', 1);
[nbackCompareResponse, sigComparisonResponse] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP,...
    'chInterest', chInterest, 'itiDataFilt', itiDataStitch, 'xshuffles', 100, 'eventChoice', 1);


%% plotting
tt = identityTaskLFP.time;
ff = identityTaskLFP.freq;

comparisonName = 'Image On';
plt.nbackPlotSpectrogram(nbackCompareImageOn,'timePlot', tt, 'frequencyRange', ff, 'chName', chName, 'comparison', 1, 'figTitleName', comparisonName); %comparison 1 is emot task compared to id task, 2 is half set up to just show one subtracted from the other
comparisonName = 'Response';
plt.nbackPlotSpectrogram(nbackCompareResponse,'timePlot', tt, 'frequencyRange', ff, 'chName', chName, 'comparison', 1, 'figTitleName', comparisonName); %comparison 1 is emot task compared to id task, 2 is half set up to just show one subtracted from the other

%% response times



%% save plots
hh =  findobj('type','figure'); 
nn = length(hh);
savePlot = 1;
if savePlot
    plt.save_plots([1:nn], 'sessionName', sessionName, 'subjName', subjName, 'versionNum', 'v1');
end

[MW13.ResponseTimesEmotionTask, MW13.ResponseTimesIdentityTask] = Analysis.emuEmot.comparePowerResponseTime(nbackCompareImageOn, ResponseTimesDiffIdentity, ResponseTimesDiffEmotion, identityTaskLFP, emotionTaskLFP);

