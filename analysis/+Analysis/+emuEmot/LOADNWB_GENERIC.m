%For pulling in nwb files and the task data



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

%Timing info:
%Timestamps: 
%Short version: ma_timestamps and beh_timestamps are on the neural clock
%(see below for conversion). 1.6xxxe15. 
%rest are on the now command psychtoolbox clock and are in microseconds
%(see below) 

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

% Structure (for nback, see documentation in the folder for other taks,
% there is some nice documentation in MW_2): image 1 on, then off with
% fixation cross on, then image 2 on and response about same/different at
% any time after that, but then image off, fixation on, then image 3 and
% decision about if 2 and 3 were the same. TTLs are image on (TTL 2) then
% next image (TTL 4) and back and forth like that. The other TTL is some
% TTL artifact like TTL off. CorrectResponse is the right answer and
% Response is if the images matched (1) or didn't match (0) (i.e. if they
% are correct CorrectResponse == Response) %Hex code 19 task start; 29
% image on; 39 fixation on; response 49;

addpath(genpath('Z:\KramerEmotionID_2023\Data\EMU_nBack'));
sessionName = 'MW_23';
subjName = 'MW_23';
hexDecTTL = 0; %toggle this on if the hexidecimal system is in place which occurs from MW_16 on, but can also live 
rawData = 0; %you can pull in the raw data files, but recommend the filtered
fs = 500; %sampling rate, original is 4000, so ma_timestamps, it's every 2000 microseconds or 0.002 seconds, which is 500samples/s

dwnSampleFactor = round(4000/fs); %can convert this for microwires where original fs is 32khz if desired.

%% add the apprpriate behavioral file
matNameEm = 'NBack_EMOTION_2023_06_27.13_29_53'; 

%% add the appropriate nwb file
%This is for nback task
emotionFilter = 'JM_MW23_Session_9_filter.nwb';


taskName = 'Emotion';
%change the folder name
folderName=strcat('Z:\KramerEmotionID_2023\Data\EMU_nBack', '\', sessionName, '\', matNameEm);


%% Load NWB
% Emotion
%NOTE: a few of them are all one file, notably MW_16 and I think MW_18 and
%the hex code splits them.
%get nwbRead and related folders from the nwb github
testfile = nwbRead(emotionFilter); 



%% Load the behavioral data
%runs nwb

%%Timestamp count
% NLX time [microseconds] equal to timestamp values from recording data

beh_timestamps = testfile.acquisition.get('events').timestamps.load;

if hexDecTTL
    cellVar = [];
    cellVar = testfile.acquisition.get('events').data.load;
    if ~isempty(cellVar)
        for ii = 1:size(cellVar,1)
            if contains(cellVar(ii,:), 'TTL')
                hexStr(ii,:) = extractBetween(cellVar(ii,:),'(',')');
            else
                hexStr(ii,:) = {'0x0000'};
            end
        end
        hexNum = hex2dec(hexStr);
    end
end


%% Get processed/filtered neurophysiology
%these two are for .filtered file

macrowires = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').data.load;
%microwires = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MicroWireSeries').data.load;



%this is for .raw file, can toggle on
if rawData == 1
macroData = testfile.acquisition.get('MacroWireSeries').data.load();
macroDataD = downsample(macroData', dwnSampleFactor); %raw dara is 4000 and want 500 so downsample by 8
macroDataD = macroDataD';
macrowires = macroDataD;
end


%% Get neurophysiology timestamps [to align with behavioral timestamps]

% Microwire
% NLX time [microseconds] 
%mi_timestamps = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MicroWireSeries').timestamps.load;

% Macrowire
% NLX time [microseconds] 
ma_timestamps = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').timestamps.load;

%downsamle the timestamps 
ma_timestampsDS=downsample(ma_timestamps, dwnSampleFactor); 

%loads behavioral
load(folderName)


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





