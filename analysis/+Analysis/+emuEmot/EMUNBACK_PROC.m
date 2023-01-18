% %set to 0 if running this with a new data set for the first time, set to
% 1 if you saved the filtered data after running
% Analysis.emuEmot.nwbLFPchProc and don't want to keep running it
%Set up if you are saving and then loading the filtered data
alreadyFilteredData = 0; 

%%
% EMUNBACK_PROC
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

%% setup details of the processing
fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s
chInterest = [1, 57, 77];
% locationsInt = ['LAMY', 'RAMY', 'LAH', 'RAH', 'LPOL', 'RPOL']; % can
% return to this, for now probably easier to pick by hand, this was a setup
% to automatically pull the electrode numbers
extraTime = 3; %amount in seconds, to add to the end of the recordings


%% Event files
%% Load NWB
% Emotion

rawData = 1; %turn to 0 if wanting to use the filtered data
if rawData == 0
        testfile = nwbRead('MW3_Session_13_filter.nwb');
elseif rawData == 1
        testfile = nwbRead('MW3_Session_11_raw.nwb');
end




%MW3_Session14_filter.nwb (NBack Emotion): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3_Session12_filter.nwb (NBack Identity): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%(MW3_Session11_filter.nwb = MW3_Session12_filter.nwb but the filtering is
%better)
%What this means is that beh_timestamps(2) = ImageTimes(1) = Image 1 and then beh_timestamps(4) = ImageTimes(2) = Image 2 
%run the script to pull in the data from nwb if needed

run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
load('C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession\NBack_2021_05_04.12_53_08_BLIND.mat')
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

%high pass if raw data
lpFiltHigh = designfilt('highpassiir','FilterOrder',8, ...
'PassbandFrequency',1,'PassbandRipple',0.2, ...
'SampleRate',500);

%cut data to channels of interest
data = double(macrowiresCAR(chInterest, :));

%lowpass filter
dataF = filtfilt(lpFilt,data');

%highpass filter
dataF = filtfilt(lpFiltHigh,dataF);

%% find the behavioral timestamps
%downsamle the timestamps
ma_timestampsDS=downsample(ma_timestamps, 8);

%finds the index in the data of the behavioral indices
%behavioralIndex now points to the row in data that is closest to the
%behavioral time stamps. 
[behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps, ma_timestampsDS);

%% take the data down to what you need so not filtering the whole recording session, gives a buffer but mostly removes the beginning
taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);


%% process data with main proc function (see above to set this)

if alreadyFilteredData == 1
    load C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession\FiltData_NBack_2021_05_04.12_53_08_BLIND.mat
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'filtData', filtData);
elseif alreadyFilteredData ~= 1
    [emotionTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx, 'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% second set of data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%Identity run
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));
        testfile = nwbRead('MW3_Session_11_filter.nwb');
run Analysis.emuEmot.LOAD_processedData_EMU_EmotTasks.m
load('C:\Users\kramdani\Documents\Data\EMU_nBack\FacialRecSession\NBack_2021_05_04.12_43_46_BLIND.mat')
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

dataC = dataF(behavioralIndex(2)-500:behavioralIndex(end-1)+100,:);
if alreadyFilteredData == 1
    load C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession\FiltData_NBack_2021_05_04.12_53_08_BLIND.mat
    [identityTaskLFP] = Analysis.emuEmot.nwbLFPchProc(dataF, PresentedEmotionIdx, PresentedIdentityIdx,'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest, 'filtData', filtData);
elseif alreadyFilteredData ~= 1
    [identityTaskLFPT] = Analysis.emuEmot.nwbLFPchProc(dataC, PresentedEmotionIdx, PresentedIdentityIdx, 'timeStamps', behavioralIndex, 'fs', fs, 'chNum', chInterest);
end

%% compare

[nbackCompare] = Analysis.emuEmot.nbackCompareLFP(identityTaskLFP, emotionTaskLFP, 'chInterest', chInterest);




%% this is all scratch pad stuff for now.

dataC = dataF(behavioralIndex(2):behavioralIndex(4));
    [filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(dataC, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps

%this does not work, gives complex outputs for some reason.
spectrogram(dataC, [], [], [], 500, "power", "yaxis");

figure
spectrogram(dataC*sqrt(2), 100, 95, [1:200], 500, "power", "yaxis");
figure
spectrogram(dataC, 'yaxis');

[trum, ft] = pspectrum(dataC, 500);

trumDB = 10*log10(trum);
figure
plot(ft, trumdb)

%% set up plotting
tt = filtData.dataSpec.tplot(1:size(identityTaskLFPT.byemotion.ch1.image{1}, 2));
ff = filtData.dataSpec.f;

S = identityTaskLFPT.byemotion.ch1.image{1}(:, :, 2);

SS1 = identityTaskLFPT.byemotion.ch77.image{1};
SS2 = identityTaskLFPT.byidentity.ch77.image{2};

SS1m = mean(SS1, 3);
SS2m = mean(SS2, 3);
SSt = SS1m-SS2m;
figure
imagesc(tt, ff, SSt); axis xy;


figure
imagesc(tt, ff, S); axis xy;

for ii = 1:9
    S = SS(: , : , ii);
    figure
    imagesc(tt, ff, S); axis xy;
end

figure
S = dataTemp(:, 1:1000, 1);
tt = tplot(1:1000);
imagesc(tt, ff, S); axis xy

%%
% for the test output in nwbLFPchProc NEXT THING TO CHECK IS DIFFERENT
% CHANNELS? ALSO IS THE Z SCORING DOING TOO MUCH? PROBABLY AND PROBABLY CAN
% Z SCORE FOR JUST THE CHUNKS, DOUBLE CHECK IN THE STUFF YOU JUST DID THAT
% IT Z SCORED ONLY ACROSS EACH TRIAL INSTEAD OF ACROSS ALL OF THE DATA
% WHERE ONE LARGE OUTPUT WOULD REALLY DOMINATE.

%NO IDEA WHAT IS HAPPENING, THE PROCESSING IS REALLY JUST DOING CHRONUX.
%AT THIS POINT, LOOK BACK THROUGH YOUR OWN FILTERING PROCESS AND THEN TRY
%THE RAW DATA
        [dataTempM, tplotTemp, ff]=mtspecgramc(dataM, params.win, params); %time by freq, need to ' to plot with imagesc


tt = filtDataTemp.dataSpec.tplot;
ff = filtDataTemp.dataSpec.tplot;
Stest = filtDataTemp.dataSpec.dataZ;

xx= nback.byidentity.ch77.image.specDzscore{1};
StestM = nanmean(nback.byidentity.ch77.image.specDzscore{1}, 3);

figure

imagesc(tt, ff, StestM); axis xy

for ii = 1:18
    figure
    imagesc(tt, ff, xx(:,:,ii)); axis xy
end


