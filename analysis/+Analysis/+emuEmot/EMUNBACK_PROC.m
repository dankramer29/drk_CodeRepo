% EMUNBACK_PROC
addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack\EmotionSession'));

%% setup details of the processing
fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s
chInterest = [1, 57, 77];
% locationsInt = ['LAMY', 'RAMY', 'LAH', 'RAH', 'LPOL', 'RPOL']; % can
% return to this, for now probably easier to pick by hand, this was a setup
% to automatically pull the electrode numbers
extraTime = 3; %amount in seconds, to add to the end of the recordings


%% Event files
%MW3_Session14_filter.nwb (NBack Emotion): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%MW3_Session12_filter.nwb (NBack Identity): start event stamp = 2; end event stamp = 109 (final event stamp (or 110) - 1)
%What this means is that beh_timestamps(2) = ImageTimes(1) = Image 1 and then beh_timestamps(4) = ImageTimes(2) = Image 2 
%run the script to pull in the data from nwb if needed
nwbFile ='MW3_Session_14_filter.nwb';
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


%this pulls a whole set of data in, that you can pull info from, if more
%than wireID is needed:
%columns = testfile.general_extracellular_ephys_electrodes.vectordata; 

%% low pass the data (nyquist 250)
lpFilt = designfilt('lowpassiir','FilterOrder',8, ...
'PassbandFrequency',200,'PassbandRipple',0.2, ...
'SampleRate',500);

%cut data to channels of interest
data = double(macrowires(chInterest, :));

%lowpass filter
dataF = filtfilt(lpFilt,data');

%% take the data down to task only with ends
%downsamle the timestamps
ma_timestampsDS=downsample(ma_timestamps, 8);

[behavioralIndex, closestValue] = Analysis.emuEmot.timeStampConversion(beh_timestamps,ma_timestampsDS);

taskTimeSt = closestValue(1);
taskTimeEnd = closestValue(end);

%check the time is long enough for the ends, fs * extraTime is the number of samples you want extra * the time in seconds 
if taskTimeSt-(fs * extraTime) < 0
    extraTimeSt = 0;
else 
    extraTimeSt = extraTime * fs;
end
if taskTimeEnd+(fs * extraTime) > length(dataF)
    extraTimeEnd = length(dataF) - taskTimeEnd;
else 
    extraTimeEnd = extraTime * fs;
end


dataFcut = dataF(taskTimeSt(1,1) - extraTimeSt:taskTimeEnd(end,1) + extraTimeEnd, :);



%% process data with main proc function

[lfpData] = Analysis.emuEmot.nwbLFPchProc(dataF, 'timeStamps', behavioralIndex, 'fs', fs);





