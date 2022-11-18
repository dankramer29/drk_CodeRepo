%%Add matnwb file
%addpath(genpath('C:\Users\kramdani\Documents\Data\EMU_nBack'));

%%Load NWB
testfile = nwbRead('MW3_Session_14_filter.nwb');

%%Timestamp count
% NLX time [microseconds] equal to timestamp values from recording data
beh_timestamps = testfile.acquisition.get('events').timestamps.load;

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

%% Get processed/filtered neurophysiology
macrowires = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').data.load;

microwires = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MicroWireSeries').data.load;

%% Get neurophysiology timestamps [to align with behavioral timestamps]

% Microwire
% NLX time [microseconds] 
mi_timestamps = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MicroWireSeries').timestamps.load;

% Macrowire
% NLX time [microseconds] 
ma_timestamps = testfile.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').timestamps.load;

wireID{:,1} = testfile.general_extracellular_ephys_electrodes.vectordata.get('wireID').data.load();  
columns = testfile.general_extracellular_ephys_electrodes.vectordata;
wireID{:,2} = testfile.general_extracellular_ephys_electrodes.vectordata.get('shortBAn').data.load();  

