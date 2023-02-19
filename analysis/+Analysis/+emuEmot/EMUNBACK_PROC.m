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

% Structure: image 1 on, then off with fixation
% cross on, then image 2 on and response about same/different at any time
% after that, but then image off, fixation on, then image 3 and decision
% about if 2 and 3 were the same. TTLs are image on (TTL 2) then fixation
% (TTL 3) and back and forth like that.

% set to 0 if running this with a new data set for the first time, set to
% 1 if you saved the filtered data after running
% Analysis.emuEmot.nwbLFPchProc and don't want to keep running it
%Set up if you are saving and then loading the filtered data
sessionName = '5_29_2022session';
subjName = 'MW13';
taskName = 'Emotion';
matName = 'NBack_EMOTION_2022_5_29.18_10_57_BLIND.mat';

folderName=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName, '\', taskName, '\', matName);


alreadyFilteredData = 0; 

%% choose raw data or not
rawData = 0; %turn to 0 if wanting to use the filtered data

%%
% EMUNBACK_PROC
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

%% setup details of the processing
%MW3
%chInterest = [69, 77, 148];
%MW13
chInterest = [23, 24, 31, 32, 33, 34, 83, 84, 97, 98];
%REMEMBER, IF THE MICROWIRES, IT'S ADTECH AND 8 IS DISTAL, IF IT'S NOT MICROWIRE (I.E. PMT
%OR DIXI) THEN 1 IS DISTAL 


fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s

extraTime = 3; %amount in seconds, to add to the end of the recordings

%time in seconds to add before and after the events
preTime = 0.5; 
postTime = 2; 


%% Event files
%MW3_Session14_filter.nwb (NBack Emotion): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3_Session12_filter.nwb (NBack Identity): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%(MW3_Session11_filter.nwb = MW3_Session12_filter.nwb but the filtering is
%better)
% MW13_Session_9_filter.nwb — NBack_IDENTITY_2022_5_29…
% MW13_Session_10_filter.nwb — NBack_EMOTION_2022_5_29…
%What this means is that beh_timestamps(2) = ImageTimes(1) = Image 1 and then beh_timestamps(4) = ImageTimes(2) = Image 2 
%run the script to pull in the data from nwb if needed

%% Load NWB
% Emotion

if rawData == 0
       % testfile = nwbRead('MW3_Session_13_filter.nwb');
                testfile = nwbRead('MW13_Session_10_filter.nwb');
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
    if timeStampDiff(idx1) == 500000 %50000/500 = 1000ms
        imageOn(idx2) = ii-1; %record the relevant image onsets, here we are assuming the ttls that are on for 1 second, the start of that 1s ttl is image on (this is possibly not true!)
        idx2 = idx2 + 1;
    end
    idx1 = idx1 +1;
end



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
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataFemotion, PresentedEmotionIdx, PresentedIdentityIdx,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'filtData', filtData, 'preTime', preTime, 'postTime', postTime);
elseif alreadyFilteredData ~= 1
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataFemotion, PresentedEmotionIdx, PresentedIdentityIdx, 'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'preTime', preTime, 'postTime', postTime);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% second set of data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Identity run
taskName = 'Identity';
matName = 'NBack_IDENTITY_2022_5_29.18_5_50_BLIND.mat';

folderName=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName, '\', taskName, '\', matName);

     %   testfile = nwbRead('MW3_Session_11_filter.nwb');
            testfile = nwbRead('MW13_Session_9_filter.nwb');
run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
%mw3
%load('C:\Users\kramdani\Documents\Data\EMU_nBack\4_12_2022session\FacialRecSession\NBack_2021_05_04.12_43_46_BLIND.mat')
%mw13
load(folderName)
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
dataFidentity = filtfilt(lpFiltlow,data');
%highpass filter if raw
%dataF = filtfilt(lpFilthigh,dataF');

%% find the behavioral timestamps
%downsamle the timestamps
ma_timestampsDS=downsample(ma_timestamps, 8);

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);

if alreadyFilteredData == 1
    load C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession\FiltData_NBack_2021_05_04.12_53_08_BLIND.mat
    [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataFidentity, PresentedEmotionIdx, PresentedIdentityIdx,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'filtData', filtData, 'preTime', preTime, 'postTime', postTime);
elseif alreadyFilteredData ~= 1
    [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataFidentity, PresentedEmotionIdx, PresentedIdentityIdx, 'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'preTime', preTime, 'postTime', postTime);
end

%% compare identity task/emotion task within a channel
%create an "iti" baseline

preStartData = dataFidentity;
trialLength = preTime + postTime;
itiDataTemp = stats.shuffleDerivedBaseline(preStartData, 'trialLength', trialLength, 'trials', 20, 'timeStamps', behavioralIndex(3:107));
%THIS APPEARS NOT TO WORK, IT REALLY MUTES THE ITI DATA AND ENDS UP WITH IT
%MAKING THE ENTIRE TRIAL LOOK POSITIVE.
% idx3 = 1;
% for ii = 1:10:480
%     itiDataCompare(:, :, idx3) = mean(itiDataTemp(:,:,ii:ii+10),3);
%     idx3 = idx3 + 1;
% end
% itiData = itiDataTemp;

[itiDataFiltIdentity] = Analysis.emuEmot.nwbLFPchProcITI(itiDataTemp, 'chNum', chInterest);

for ff=1:length(chInterest)
    ch = num2str(chInterest(ff));
    channelName{ff} = ['ch' ch];
end


%itiDataFilt is not averaged across chunks of trials, and itiDataCompareFilt is

%this is for creating a central threshold, but I'M NOT SURE IT REALLY WORKS
%BECAUSE I CAN'T FIGURE OUT WHAT TO COMPARE THE REGULAR DATA TO
% for ii =1:length(chInterest)
%     itiDataTest = itiDataFiltIdentity.iti.(channelName{ii}).specD; %itiDataFilt is not averaged across chunks of trials, and itiDataCompareFilt is
%     [thresh(ii), tstatHisto{ii}] = stats.cluster_timeShift_Ttest_gpu3d(itiDataTest, 'xshuffles', 200);
%     [thresh(ii), tstatHisto{ii}] = stats.cluster_shuffleMeanBaseline_gpu3d(itiDataTest, 'xshuffles', 200);
% 
% end
% 






%This will run stats to compare the same identities or same emotions but
%across the two different tasks


%  allEmotions and allIdentities are the same since it's just all images
%  shown
% NO IDEA WHY THE CLUSTERS ARE SO SMALL FOR THE REAL BUT NOT FOR THE ITI
[nbackCompare, sigComparison] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP, 'chInterest', chInterest, 'itiDataFilt', itiDataFiltIdentity, 'xshuffles', 100);

tt = identityTaskLFP.time;
ff = identityTaskLFP.freq;

plt.nbackPlotSpectrogram(nbackCompare,'timePlot', tt, 'frequencyRange', ff, 'chName', chName, 'comparison', 1); %comparison 1 is identitytask-emotiontask, 2 is identity only, 3 emotiontask only


savePlot = 1;
if savePlot
    plt.save_plots([1:20], 'sessionName', sessionName, 'subjName', subjName, 'versionNum', 'v1');
end

