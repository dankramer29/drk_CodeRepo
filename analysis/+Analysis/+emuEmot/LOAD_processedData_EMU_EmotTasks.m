%% Add matnwb file
addpath(genpath('C:\Users\John\Documents\MATLAB\matnwb'))
​
​
%% Load NWB
testfile = nwbRead('MW2_Session_1_filter.nwb');
​
%% Timestamp count
% NLX time [microseconds] equal to timestamp values from recording data
beh_timestamps = testfile.acquisition.get('events').timestamps.load;
​
% You can use these values to search the timestamp data from the ephys
% To check the actual time conversion
% timeA = datetime(timestamps(1)/1000000,...
%          'ConvertFrom','posixtime','TimeZone','America/Denver')
​
%% Preprocessing INFO
​
% MACROWIRE LFP
% Downsampled to 500Hz
% Notch filtered with Parra spectral interpolation 59-61Hz
% High pass at 0.1Hz
% No low pass
​
% MICROWIRE for SPIKE
% NO Downsample
% NO Notch filter
% High pass at 600Hz
% Low pass at 3000Hz
​
%% Get processed/filtered neurophysiology
macrowires = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').data.load;
​
microwires = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MicroWireSeries').data.load;
​
%% Get neurophysiology timestamps [to align with behavioral timestamps]
​
% Microwire
% NLX time [microseconds] 
mi_timestamps = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MicroWireSeries').timestamps.load;
​
% Macrowire
% NLX time [microseconds] 
ma_timestamps = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').timestamps.load;