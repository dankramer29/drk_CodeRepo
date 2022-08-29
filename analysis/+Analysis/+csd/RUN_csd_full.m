%THE OVERALL SCRIPT TO USE FOR CSD (SO YOU DON'T GET CONFUSED AGAIN)
%9/19/18 drk was here.

%Readme
% Change the FileName and MapName to the .blc and .map file paths respectively
% Make sure the seizure date and time are in this format 16-Oct-2017 23:08:52
% Fix any params you want to change, main ones to change
%     param.ch- pick the channels you want from the blc.ChannelInfo
%     params.cuttime- [before seizure time    after seizure time], just make sure there is enough time by looking at recording start and end times in the blc file
%     params.bandpass- for now, leave at 0.5 and 40, but we could play with that potentially
%     params.savefig- this will save the figures to a new folder, just be aware as you change things that you may want to rename the old folder so it doesn't overwrite it

% also be aware you may want to change the output parameter names so you
% don't get confused with them as you output with different parameters or
% patients (like different grids)

blc=BLc.Reader('\\STRIATUM\Data\neural\working\P012\p12_ph2d6_snip-000.blc');

params = struct;
params.ch= [1 20]; %channels to look at (21 30 in GR)
params.cuttime= [30 25]; %amount of data to take around the sz, in Min
params.newfs= 400; %downsample frequency, base is 400 samples/sec (for 200Hz by nyquist)
params.fltr= 60; %notch filter of 60Hz, does not work on harmonics right now(I think)
params.proc= 2; %how many processing steps to do.
%1 - filtered voltage
%2 - 1+raw voltage squared (pwr) and then a low pass filter is
%applied, currently at 5Hz, through subsampling
%3 = 2+integral of the data and the integral filtered data (intg and
%intg_flt
params.wnd= [300 300]; %wnd1 and wnd2, set at 300s each, wdw 2 is the time constant decay
params.bandpass= [0.5 40]; %bandpass filter set at 0.5 to 70Hz
params.lowpass= 5; %the lowpass filter set at 5Hz right now, for 10 samples/second in the pwr analysis
params.bipolar= true; % to run bipolar channel outputs.
params.savefig= true; %turn on or off the saving of figures



%%
FileName='\\STRIATUM\Data\neural\working\P012\p12_ph2d6_snip-000.blc';
MapName='\\STRIATUM\Data\neural\working\P012\p12_ph2d6_snip-000.map';
map=GridMap(MapName);




[ ~, ~, outputRSP ] = Analysis.csd.blx_csd(FileName, map, params, 'Sz','16-Oct-2017 23:08:52');
