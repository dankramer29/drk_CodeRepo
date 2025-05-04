function [Data1FreqPeakBPsSm, Data2FreqPeakBPsSm, Data1FreqPeakitiBPsSm, Data2FreqPeakitiBPsSm, shTTestMean_sd, subtractionThresh_binary, shuffleBinaryPos, subtBinary] = freqPeakBandpass(data1spectro, data1bandpass, data2spectro, data2bandpass, varargin )
%Will find the peak frequency of a spectrogram data (between the specified
%band, and then bandpass the data centered on that frequency and run
%statistical comparison

%data 1 is emt and data 2 is idt the way it's being input

%outputs
%   Data1FreqPeakBPsSm = peak frequency derived from the spectrogram and
%       then bandpassed between the peak of the data 1 peak and the data 2 peak
%       in 5hz intervals and normalized and then averaged for that band (fir,
%       filt ord 4). Same for Data 2. And this is all trials stacked.
%   Data1FreqPeakitiBPsSm = same as above but for the iti.Same for data2
%   shTTestMean_sd = a table with all of the outputs from the shuffle stats
%       (pure ttest between the data, and then takes the tmax approach)
%   subtractionThresh_binary = a table with all fo the outputs from
%       subtraction difference stats (so this is a subtraction of the tmax
%       wherever it occurs)
%   shuffleBinaryPos = a yes no if there is a positive value tmax
%       subtraction
%   subtBinary = a yes no if there is a positive value subtraction
%       stats

[varargin, ff]=util.argkeyval('ff', varargin, []); %get the frequency bands of the rows of the spectrogram data
[varargin, freqOfInterest]=util.argkeyval('freqOfInterest', varargin, [1 size(data1spectro,1)]); %get the band to look for the max between
[varargin, pwr]=util.argkeyval('pwr', varargin, 2); %different ways to get power, either square it or get hilbert
[varargin, plt]=util.argkeyval('plt', varargin, 0); %plot if you want, 1 does the SE or 2 can do the shuffle as the shaded.
[varargin, fs]=util.argkeyval('fs', varargin, 500); %sampling rate
[varargin, bandpassRange]=util.argkeyval('bandpassRange', varargin,5); %how big do we want the frequency range to be
[varargin, norm]=util.argkeyval('norm', varargin,1); % 0 is don't, 1 is normalize across all data stitched together, 2 is normalize by trial (since currently normalizing across the sub frequency bands (5 hz) i tested normalizing again and option 1 is the best))
[varargin, tt]=util.argkeyval('tt', varargin, []); % time for plotting if you want 
[varargin, mirroredEnd]=util.argkeyval('mirroredEnd', varargin, 0.5); % time you want for a mirrored end in seconds
[varargin, data1itibp]=util.argkeyval('data1itibp', varargin, []); % data1 iti band passed, need that for subtraction
[varargin, data2itibp]=util.argkeyval('data2itibp', varargin, []); % data2 iti band passed, need that for subtraction

[varargin, shuffleStatsTmax]=util.argkeyval('shuffleStatsTmax', varargin, true); % tmax shuffle stats, can do both that and subtraction or one seperately or neither if you just want the frequencies out
[varargin, subtractTmaxStats]=util.argkeyval('subtractTmaxStats', varargin, true); % tmax subtraction shuffle stats, can do both that and subtraction or one seperately or neither if you just want the frequencies out



if isempty(ff)
    ff = 1:size(data1spectro,1);
end
if size(data1bandpass,1)>size(data1bandpass,2)
    data1bandpass = data1bandpass'; %should be trials x time, so transpose if not
end
if size(data2bandpass,1)>size(data2bandpass,2)
    data2bandpass = data2bandpass'; %should be trials x time, so transpose if not
end

%handle the bandpassed frequency localization. finds the peak
%frequency in the spectrogram
%find the row for the frequency band of interest in the frequency
%range
[freqRow, freqRowI] = find(ff>freqOfInterest(1,1) & ff<freqOfInterest(1,2) );
freqRowIlow = freqRowI(1);
freqRowIhigh = freqRowI(end);
%normalize the spectrogram
Data1MeanNorm = normalize(mean(data1spectro,3),2);    %expects 3rd dimension to be trials but can be done without
[mxV, mxVi] = max(Data1MeanNorm(freqRowIlow:freqRowIhigh,:),[],'all'); %this finds the max in the frequency range of interest across the matrix (3d)
[mxViR1, mxViC] = ind2sub(size(Data1MeanNorm(freqRowIlow:freqRowIhigh,:)),mxVi);%convert to row/col
freqPeak1 = ff(freqRowIlow-1+mxViR1); %finds the peak frequency
%do the second data set to find the range
Data2MeanNorm = normalize(mean(data2spectro,3),2);
[mxV, mxVi] = max(Data2MeanNorm(freqRowIlow:freqRowIhigh,:),[],'all'); %this finds the max in the frequency range of interest across the matrix (3d)
[mxViR2, mxViC] = ind2sub(size(Data2MeanNorm(freqRowIlow:freqRowIhigh,:)),mxVi);%convert to row/col
freqPeak2 = ff(freqRowIlow-1+mxViR2); %finds the peak frequency
if freqPeak1>=freqPeak2
    fplow = freqPeak2;
    fphigh = freqPeak1;
else
    fplow = freqPeak1;
    fphigh = freqPeak2;
end
% ALSO THIS From matlab: Do not use filtfilt with differentiator and Hilbert FIR filters, because the operation of those filters depends heavily on their phase response.
%SO TRY NOT USING FILTFILT? MAYBE TRY JUST BANDPASS BUT ALSO TRY FILT

%SOMEWHERE IN HERE, THE RAMPED ENDS OF THE ITI ARE CAUSING A SEVERE CHANGE.
%SO FAR, I'VE LOOKED BACK AND IT'S NOT FROM EARLIER PREPROCESSING STEPS
%WHICH ARE JUST BANDPASS AND ACROSS ALL DATA
idx = 1;
for ii = fplow-bandpassRange:5:fphigh+bandpassRange-5 %5 hz filters until it gets to the top (will cut off a small amount that will be irrelevant).
    bandfilterData = designfilt('bandpassfir','FilterOrder', 4,'CutoffFrequency1',ii,'CutoffFrequency2',ii+5, 'SampleRate',fs);
    %add a mirrored end for edge effects
    ramp=fs*mirroredEnd;
    if ramp>0
        dataMirror = horzcat(flip(data1bandpass(:, 1:ramp-1),2), data1bandpass, flip(data1bandpass(:, end-ramp+1:end),2));
    end
    Data1FreqPeakBP(idx,:,:) = filtfilt(bandfilterData, dataMirror'); %assumes data is trials by freq
    %Data1FreqPeakBPtempN(idx,:,:) = Data1TempMirror(idx, ramp:end-ramp,:);
    if ~isempty(data1itibp) && ~isempty(data2itibp)
        clear Data1TempMirror      
        if ramp>0
            dataMirror1 = horzcat(flip(data1itibp(:, 1:ramp-1),2), data1itibp, flip(data1itibp(:, end-ramp+1:end),2));
            dataMirror2 = horzcat(flip(data2itibp(:, 1:ramp-1),2), data2itibp, flip(data2itibp(:, end-ramp+1:end),2));
        end
        Data1itiTempMirror(idx,:,:) = filtfilt(bandfilterData, dataMirror1'); %assumes data is trials by freq
        Data1FreqPeakitiBP(idx,:,:) = Data1itiTempMirror(idx, :,:);
        Data2itiTempMirror(idx,:,:) = filtfilt(bandfilterData, dataMirror2'); %assumes data is trials by freq
        Data2FreqPeakitiBP(idx,:,:) = Data2itiTempMirror(idx, :,:);
    end

    idx = idx + 1;
end
%Data1FreqPeakBP = Data1FreqPeakBPtempN;

% Data1FreqPeakBP = mean(Data1FreqPeakBPtempN); %average across all the frequencies
% Data1FreqPeakBP = permute(Data1FreqPeakBP, [3,2,1]);

%Data1FreqPeakBP = Data1FreqPeakBP';
switch pwr
    case 1
        %square for power
        Data1FreqPeakBPs = Data1FreqPeakBP.^2; %turn to power
        if ~isempty(data1itibp) && ~isempty(data2itibp)
            Data1FreqPeakitiBPs = Data1FreqPeakitiBP.^2;
            Data2FreqPeakitiBPs = Data2FreqPeakitiBP.^2;
        end
    case 2
        %hilbert for power
        Data1FreqPeakBP = permute(Data1FreqPeakBP, [2,1,3]);
        Data1FreqPeakBPs = abs(hilbert(Data1FreqPeakBP));
        Data1FreqPeakBPs = permute(Data1FreqPeakBPs, [2,1,3]);
        if ~isempty(data1itibp) && ~isempty(data2itibp)
            Data1FreqPeakitiBP = permute(Data1FreqPeakitiBP, [2,1,3]);
            Data1FreqPeakitiBPs = abs(hilbert(Data1FreqPeakitiBP));
            Data1FreqPeakitiBPs = permute(Data1FreqPeakitiBPs, [2,1,3]);
            Data2FreqPeakitiBP = permute(Data2FreqPeakitiBP, [2,1,3]);
            Data2FreqPeakitiBPs = abs(hilbert(Data2FreqPeakitiBP));
            Data2FreqPeakitiBPs = permute(Data2FreqPeakitiBPs, [2,1,3]);
        end

end

Data1FreqPeakBPsdb=10*log10(Data1FreqPeakBPs); % not doing this(or doing it after the smoothing) it creates a weirder view and it's so narrow a band.

for ii = 1:size(Data1FreqPeakBPs,1)
[Data1FreqPeakBPsSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data1FreqPeakBPs(ii,:,:)), 60, fs); %tested 60ms window and 30 and 60 is better. with hilbert the smoothing barely does anything.
[Data1FreqPeakBPsdbSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data1FreqPeakBPsdb(ii,:,:)), 60, fs);
end
%normalize for each band (can cut this totally if not using it)
Data1FreqPeakBPsSmT = permute(mean(normalize(Data1FreqPeakBPsSm,2),1), [3,2,1]); %right now the frequency should be in each row
Data1FreqPeakBPsdbSmT = permute(mean(normalize(Data1FreqPeakBPsdbSm,2),1), [3,2,1]); %right now the frequency should be in each row
Data1FreqPeakBPsSm = Data1FreqPeakBPsSmT(:, ramp:end-ramp,:); %remove mirrored ends
Data1FreqPeakBPsdbSm = Data1FreqPeakBPsdbSmT(:, ramp:end-ramp,:);


%% do for the iti data if exists
if ~isempty(data1itibp) && ~isempty(data2itibp)
    Data1FreqPeakitiBPsdb=10*log10(Data1FreqPeakitiBPs); % not doing this(or doing it after the smoothing) it creates a weirder view and it's so narrow a band.

    for ii = 1:size(Data1FreqPeakitiBPs,1)
        [Data1FreqPeakitiBPsSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data1FreqPeakitiBPs(ii,:,:)), 60, fs); %tested 60ms window and 30 and 60 is better
        [Data1FreqPeakitiBPsdbSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data1FreqPeakitiBPsdb(ii,:,:)), 60, fs);
    end
    %normalize for each band (can cut this totally if not using it)
    Data1FreqPeakitiBPsSm = permute(mean(normalize(Data1FreqPeakitiBPsSm,2),1), [3,2,1]); %right now the frequency should be in each row
    Data1FreqPeakitiBPsdb = permute(mean(normalize(Data1FreqPeakitiBPsdb,2),1), [3,2,1]); %right now the frequency should be in each row
    Data1FreqPeakitiBPsSm = Data1FreqPeakitiBPsSm(:,ramp:end-ramp,:); %remove mirrored ends
    Data1FreqPeakitiBPsdb = Data1FreqPeakitiBPsdb(:,ramp:end-ramp,:);


    Data2FreqPeakitiBPsdb=10*log10(Data2FreqPeakitiBPs); % not doing this(or doing it after the smoothing) it creates a weirder view and it's so narrow a band.

    for ii = 1:size(Data2FreqPeakitiBPs,1)
        [Data2FreqPeakitiBPsSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data2FreqPeakitiBPs(ii,:,:)), 60, fs); %tested 60ms window and 30 and 60 is better
        [Data2FreqPeakitiBPsdbSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data2FreqPeakitiBPsdb(ii,:,:)), 60, fs);
    end
    %normalize for each band (can cut this totally if not using it)
    Data2FreqPeakitiBPsSm = permute(mean(normalize(Data2FreqPeakitiBPsSm,2),1), [3,2,1]); %right now the frequency should be in each row
    Data2FreqPeakitiBPsdb = permute(mean(normalize(Data2FreqPeakitiBPsdb,2),1), [3,2,1]); %right now the frequency should be in each row
    Data2FreqPeakitiBPsSm = Data2FreqPeakitiBPsSm(:,ramp:end-ramp,:);
    Data2FreqPeakitiBPsdb = Data2FreqPeakitiBPsdb(:,ramp:end-ramp,:);
end
%since it's different frequencies, normalize it. given that normalizing
%across each 5 hz band already makes a normalization scheme, it doesn't
%need to be normalized, however I ran all three and the case 1 gives the
%widest range of variability and is the most honest normalization anyway.
switch norm
    case 0 %no normalization)
        Data1FreqPeakmn = mean(Data1FreqPeakBPsSm);
        Data1FreqPeaksem = std(Data1FreqPeakBPsSm, [], 1) / sqrt(size(Data1FreqPeakBPsSm,1));
    case 1 %normalization across all data
        tempDAll = [];
        for ii = 1:size(Data1FreqPeakBPsSm,1)
            tempD = Data1FreqPeakBPsSm(ii,:);
            tempDAll = horzcat(tempDAll, tempD);
        end
        mn = mean(tempDAll); sd = std(tempDAll);
        Data1FreqPeakBPsSmNorm = (Data1FreqPeakBPsSm - mn)./sd;
        Data1FreqPeakmn = mean(Data1FreqPeakBPsSmNorm);
        Data1FreqPeaksem = std(Data1FreqPeakBPsSmNorm, [], 1) / sqrt(size(Data1FreqPeakBPsSmNorm,1));
    case 2 %normalize by trial
        Data1FreqPeakmn = mean(normalize(Data1FreqPeakBPsSm,2));
        Data1FreqPeaksem = std(normalize(Data1FreqPeakBPsSm,2), [], 1) / sqrt(size(Data1FreqPeakBPsSm,1));
end

%% for data 2 (right now data 2 is identity task)
idx = 1;
for ii = fplow-bandpassRange:5:fphigh+bandpassRange-5 %5 hz filters until it gets to the top (will cut off a small amount that will be irrelevant).
    bandfilterData = designfilt('bandpassfir','FilterOrder', 4,'CutoffFrequency1',ii,'CutoffFrequency2',ii+5, 'SampleRate',fs);

    if ramp>0
        dataMirror = horzcat(flip(data2bandpass(:, 1:ramp-1),2), data2bandpass, flip(data2bandpass(:, end-ramp+1:end),2));
    end
    Data2FreqPeakBP(idx,:,:) = filtfilt(bandfilterData, dataMirror'); %assumes data is trials by freq
    %Data2FreqPeakBPtempN(idx,:,:) = Data2TempMirror(idx, ramp:end-ramp,:);
    idx = idx + 1;
end
%Data2FreqPeakBP = Data2FreqPeakBPtempN;
% Data2FreqPeakBP = mean(Data2FreqPeakBPtempN); %average across all the frequencies
% Data2FreqPeakBP = permute(Data2FreqPeakBP, [3,2,1]);

%filter built above
% Data2FreqPeakBP = filtfilt(bandfilterData, data2bandpass');
% Data2FreqPeakBP = Data2FreqPeakBP';
switch pwr
    case 1
        %square for power
        Data2FreqPeakBPs = Data2FreqPeakBP.^2; %turn to power
    case 2
        %hilbert for power
        Data2FreqPeakBP = permute(Data2FreqPeakBP, [2,1,3]);
        Data2FreqPeakBPs = abs(hilbert(Data2FreqPeakBP));
        Data2FreqPeakBPs = permute(Data2FreqPeakBPs, [2,1,3]);

end

Data2FreqPeakBPsdb=10*log10(Data2FreqPeakBPs); %consider not doing this(or doing it after the smoothing) it creates a weirder view and it's so narrow a band.
for ii = 1:size(Data2FreqPeakBPs,1)
[Data2FreqPeakBPsSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data2FreqPeakBPs(ii,:,:)), 60, fs); %tested 60ms window and 30 and 60 is better
[Data2FreqPeakBPsdbSm(ii,:,:), tplotC]=Analysis.BasicDataProc.convSmooth(squeeze(Data2FreqPeakBPsdb(ii,:,:)), 60, fs);
end

%normalize for each band (can cut this totally if not using it)
Data2FreqPeakBPsSmT = permute(mean(normalize(Data2FreqPeakBPsSm,2),1), [3,2,1]); %right now the frequency should be in each row
Data2FreqPeakBPsdbSmT = permute(mean(normalize(Data2FreqPeakBPsdbSm,2),1), [3,2,1]); %right now the frequency should be in each row
Data2FreqPeakBPsSm = Data2FreqPeakBPsSmT(:,ramp:end-ramp,:); %remove the mirrored ends
Data2FreqPeakBPsdbSm = Data2FreqPeakBPsdbSmT(:,ramp:end-ramp,:);
% [Data2FreqPeakBPsSm, tplotC]=Analysis.BasicDataProc.convSmooth(Data2FreqPeakBPs, 60, fs); %tested 60ms window and 30 and 60 is better
% [Data2FreqPeakBPsdbSm, tplotC]=Analysis.BasicDataProc.convSmooth(Data2FreqPeakBPsdb, 60, fs);
% Data2FreqPeakBPsSm = Data2FreqPeakBPsSm';
% Data2FreqPeakBPsdbSm = Data2FreqPeakBPsdbSm';

%since it's different frequencies, normalize it.
switch norm
    case 0 %no normalization
        Data2FreqPeakmn = mean(Data2FreqPeakBPsSm);
        Data2FreqPeaksem = std(Data2FreqPeakBPsSm, [], 1) / sqrt(size(Data2FreqPeakBPsSm,1));
        %run shuffle stats
        if shuffleStatsTmax
            [shTTestMean_sd, shuffleBinary, shuffle_binaryDirection] = stats.shuffle_stats2d(Data1FreqPeakBPsSm, Data2FreqPeakBPsSm, 'xshuffles', 1000, 'plt', true, 'tt', tt , 'ff', ff);
            shTTestMean_sd.task{1,1} = 'EmotionTask';
            shTTestMean_sd.task{2,1} = 'IdentityTask';
            shTTestMean_sd.freqPeak{1,1} = freqPeak1; %emt
            shTTestMean_sd.freqPeak{2,1} = freqPeak2; %idt
            shTTestMean_sd.freqPeak{1,1} = shuffleBinary; %the actual output at each time point
            shuffleBinaryPos = shuffle_binaryDirection; %0 for not positive, 1 for data 1 positive (emt), 2 for data 2 positive (idt)
            shTTestMean_sd.shuffleBinaryPos{1,1} = shuffle_binaryDirection;
        else
            shTTestMean_sd = [];
            shuffleBinaryPos = [];
            shuffleBinary = [];
        end
        %run the subtraction stats
        if subtractTmaxStats
        [subtractionThresh_binary, subtBinary] = stats.shuffle_subtraction_stats2d(Data1FreqPeakBPsSm, Data1FreqPeakitiBPsSm, Data2FreqPeakBPsSm, Data2FreqPeakitiBPsSm,...
                'xshuffles', 1000, 'tt', tt, 'timeRange', [100 900], 'plt', true);
        subtractionThresh_binary.task{1,1} = 'EmotionTask';
        subtractionThresh_binary.task{2,1} = 'IdentityTask';
        subtractionThresh_binary.freqPeak{1,1} = freqPeak1; %emt
        subtractionThresh_binary.freqPeak{2,1} = freqPeak2; %emt
        else
            subtractionThresh_binary = [];
            subtBinary = [];
        end
    case 1 %normalize across all the data (can do this in shuffle too, but better here) (since the frequency is the same, fine to do it across all)
        tempDAll = [];
        for ii = 1:size(Data2FreqPeakBPsSm,1)
            tempD = Data2FreqPeakBPsSm(ii,:);
            tempDAll = horzcat(tempDAll, tempD);
        end
        mn = mean(tempDAll); sd = std(tempDAll);
        Data2FreqPeakBPsSmNorm = (Data2FreqPeakBPsSm - mn)./sd;
        Data2FreqPeakmn = mean(Data2FreqPeakBPsSmNorm);
        Data2FreqPeaksem = std(Data2FreqPeakBPsSmNorm, [], 1) / sqrt(size(Data2FreqPeakBPsSmNorm,1));
        % run shuffle stats (already normalized) 
        % data 1 is emotion task,
        %data 2 is identity task the way it's being put in now. 
        
        if shuffleStatsTmax
            [shTTestMean_sd, shuffleBinary, shuffle_binaryDirection] = stats.shuffle_stats2d(Data1FreqPeakBPsSm, Data2FreqPeakBPsSm, 'xshuffles', 1000, 'plt', true, 'tt', tt , 'ff', ff);
            shTTestMean_sd.task{1,1} = 'EmotionTask';
            shTTestMean_sd.task{2,1} = 'IdentityTask';
            shTTestMean_sd.freqPeak{1,1} = freqPeak1; %emt
            shTTestMean_sd.freqPeak{2,1} = freqPeak2; %idt
            shTTestMean_sd.freqPeak{1,1} = shuffleBinary; %the actual output at each time point
            shuffleBinaryPos = shuffle_binaryDirection; %0 for not positive, 1 for data 1 positive (emt), 2 for data 2 positive (idt)
            shTTestMean_sd.shuffleBinaryPos{1,1} = shuffle_binaryDirection;            
        else
            shTTestMean_sd = [];
            shuffleBinaryPos = [];
            shuffleBinary = [];
        end

        if subtractTmaxStats
            [subtractionThresh_binary, subtBinary] = stats.shuffle_subtraction_stats2d(Data1FreqPeakBPsSm, Data1FreqPeakitiBPsSm, Data2FreqPeakBPsSm, Data2FreqPeakitiBPsSm,...
                'xshuffles', 1000, 'tt', tt, 'timeRange', [100 900], 'plt', true);
            subtractionThresh_binary.task{1,1} = 'EmotionTask';
            subtractionThresh_binary.task{2,1} = 'IdentityTask';
            subtractionThresh_binary.freqPeak{1,1} = freqPeak1; %emt
            subtractionThresh_binary.freqPeak{2,1} = freqPeak2; %idt
            subtractionThresh_binary.subtBinary{1,1} = subtBinary; %0 if not positive, 1 is data 1 (emt) and 2 if data 2 (idt)

        else
            subtractionThresh_binary = [];
            subtBinary = [];
        end
    case 2 %normalize within each trial
        Data2FreqPeakBPsSmNorm = normalize(Data2FreqPeakBPsSm,2); %normalize across all trials
        Data2FreqPeakmn = mean(Data2FreqPeakBPsSmNorm);
        Data2FreqPeaksem = std(Data2FreqPeakBPsSmNorm, [], 1) / sqrt(size(Data2FreqPeakBPsSm,1));
        %run shuffle stats (already normalized)
        if shuffleStatsTmax
            [shTTestMean_sd, shuffleBinary, shuffle_binaryDirection] = stats.shuffle_stats2d(Data1FreqPeakBPsSm, Data2FreqPeakBPsSm, 'xshuffles', 1000, 'plt', true, 'tt', tt , 'ff', ff);
            shTTestMean_sd.task{1,1} = 'EmotionTask';
            shTTestMean_sd.task{2,1} = 'IdentityTask';
            shTTestMean_sd.freqPeak{1,1} = freqPeak1; %emt
            shTTestMean_sd.freqPeak{2,1} = freqPeak2; %idt
            shTTestMean_sd.freqPeak{1,1} = shuffleBinary; %the actual output at each time point
            shuffleBinaryPos = shuffle_binaryDirection; %0 for not positive, 1 for data 1 positive (emt), 2 for data 2 positive (idt)
            shTTestMean_sd.shuffleBinaryPos{1,1} = shuffle_binaryDirection;
        else
            shTTestMean_sd = [];
            shuffleBinaryPos = [];
            shuffleBinary = [];
        end
        %run the subtraction stats
        if subtractTmaxStats
            [subtractionThresh_binary, subtBinary] = stats.shuffle_subtraction_stats2d(Data1FreqPeakBPsSm, Data1FreqPeakitiBPsSm, Data2FreqPeakBPsSm, Data2FreqPeakitiBPsSm,...
                'xshuffles', 1000, 'tt', tt, 'timeRange', [100 900], 'plt', true);
            subtractionThresh_binary.task{1,1} = 'EmotionTask';
            subtractionThresh_binary.task{2,1} = 'IdentityTask';
            subtractionThresh_binary.freqPeak{1,1} = freqPeak1; %emt
            subtractionThresh_binary.freqPeak{2,1} = freqPeak2; %emt
        else
            subtractionThresh_binary = [];
            subtBinary =[];
        end
end


%optional plotting
switch plt
    case 1


        figure
        colorTempTest = {'#1A1334', '#26294A', '#055459', '#077353', '#14C285', '#ABD96D', '#FCBF54', '#EE6C3B', '#EC0E47', '#A02C5D', '#710461', '#022B7A' };
        for ii = 1:length(colorTempTest)
            str = colorTempTest{ii};
            C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
        end
        H = shadedErrorBar([],Data1FreqPeakmn,Data1FreqPeaksem*2,'lineprops', {'-b'});
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(5,:);
        H.patch.EdgeColor=C(6,:);
        H.mainLine.Color=C(6,:);
        H.edge(1).Color=C(6,:);
        H.edge(2).Color=C(6,:);
        hold on
        H = shadedErrorBar([],Data2FreqPeakmn,Data2FreqPeaksem*2,'lineprops', {'-b'});
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(11,:);
        H.patch.EdgeColor=C(10,:);
        H.mainLine.Color=C(10,:);
        H.edge(1).Color=C(10,:);
        H.edge(2).Color=C(10,:);

    case 2


        figure
        colorTempTest = {'#1A1334', '#26294A', '#055459', '#077353', '#14C285', '#ABD96D', '#FCBF54', '#EE6C3B', '#EC0E47', '#A02C5D', '#710461', '#022B7A' };
        for ii = 1:length(colorTempTest)
            str = colorTempTest{ii};
            C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
        end
        H = shadedErrorBar([],Data1FreqPeakmn,Data1FreqPeaksem*2,'lineprops', {'-b'});
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(5,:);
        H.patch.EdgeColor=C(6,:);
        H.mainLine.Color=C(6,:);
        H.edge(1).Color=C(6,:);
        H.edge(2).Color=C(6,:);
        hold on
        H = shadedErrorBar([],Data2FreqPeakmn,Data2FreqPeaksem*2,'lineprops', {'-b'});
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(11,:);
        H.patch.EdgeColor=C(10,:);
        H.mainLine.Color=C(10,:);
        H.edge(1).Color=C(10,:);
        H.edge(2).Color=C(10,:);
end
        


end