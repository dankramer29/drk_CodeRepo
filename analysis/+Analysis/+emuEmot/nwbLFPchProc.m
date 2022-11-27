function [outputArg1,outputArg2] = nwbLFPchProc(data)
%nwbLFPchProc Basic processing function for EMU 
%   Inputs:
%        channel - vector or matrix of channels

% example: 


[varargin, fs] = util.argkeyval('fs',varargin, 500); %sampling rate, default is 500


%% separate the data

[filtData, params, bandfilter] = Analysis.BasicDataProc.dataPrep(data, 'needsCombfilter', 0, 'fs', fs); %calls this function for my basic processing steps




end