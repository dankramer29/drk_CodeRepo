function [Corr, dataClassBand] = gridCorrCoef(data, varargin)
%gridCorrCoef Runs a correlation coefficient matrix across the grid through
%the different canonical bands (delta 1-4 theta 4-8 alpha 8-13 beta 13-30 gamma 30-50 high gamma 50 to 200)

%   Detailed explanation goes here

[varargin, fs] = util.argkeyval('fs',varargin, 2000); %sampling rate
[varargin, dataClassBand] = util.argkeyval('dataClassBand',varargin, []);  % check if classic broad filters already made so you don't have to keep making them each run
[varargin, channelOrder] = util.argkeyval('channelOrder',varargin, [1:size(data,1)]); %channel order for the data
[varargin, needsCombfilter] = util.argkeyval('needsCombfilter',varargin, true); % option to comb filter/bandpass filter the data

[varargin, alph] = util.argkeyval('alph',varargin, 0.01); %CI alpha level for the correlation coeffcition
[varargin, lbl] = util.argkeyval('lbl',varargin, 'lateral grid'); %Label for the grid

[varargin, plt] = util.argkeyval('plt',varargin, true); %plot the correlation coefs

%gridlayout per idx to channel for blackrock array
%idxch2el=[78,88,68,58,56,48,57,38,47,28,37,27,36,18,45,17,46,8,35,16,24,7,26,6,25,5,15,4,14,3,13,2,77,67,76,66,75,65,74,64,73,54,63,53,72,43,62,55,61,44,52,33,51,34,41,42,31,32,21,22,11,23,10,12,96,87,95,86,94,85,93,84,92,83,91,82,90,81,89,80,79,71,69,70,59,60,50,49,40,39,30,29,19,20,1,9];

%make sure data is columns=channels and rows are time
if size(data, 1)<size(data,2)
    data=data';
end

%resort your columns
data=data(:, channelOrder);


if needsCombfilter
    % Filter for 60 Hz noise and 120 Hz and 180 Hz
    notchFilt60 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    notchFilt120 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    notchFilt180 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',179,'HalfPowerFrequency2',181, ...
        'SampleRate',fs,'DesignMethod','butter');
    
    data = filtfilt(notchFilt60,data);
    data = filtfilt(notchFilt120,data);
    data = filtfilt(notchFilt180,data);
end


if isempty(dataClassBand)
    %create the filters if not done previously, for the classic bands,
    %the Freq_BandWidth is actually not used here, but just runs it
    %smoothly
    [~, ~, ~, dataClassBand]=Analysis.PAC.bandfiltersAP(2, fs, 'AmpFreqVectorRun', false, 'ClassicBand', true); %create the band filters
end

%% set up the filtering
lblB=fieldnames(dataClassBand);



%% run the filters
for ii=1:length(lblB)
    %run the filters and make power
    tempClassicBand=filtfilt(dataClassBand.(lblB{ii}), data);
    tempCBC{ii}=tempClassicBand; %bands in cells, channels in columns
    [Corr.(lblB{ii}).R, Corr.(lblB{ii}).P, Corr.(lblB{ii}).LL, Corr.(lblB{ii}).UL]=corrcoef(tempCBC{ii}, 'Alpha', alph);
end

figtitle=['Correlation between electrodes ', lbl];
figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height

%plot the bands, right now 6 bands, will need to change if doing more bands
for ii=1:length(lblB)
    subplot(3,2, ii)    
    imagesc(Corr.(lblB{ii}).R); 
    title(lblB{ii})
    colorbar
end

end

