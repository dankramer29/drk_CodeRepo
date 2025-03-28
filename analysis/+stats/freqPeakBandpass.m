function [Data1FreqPeakmn, Data1FreqPeaksem, Data2FreqPeakmn, Data2FreqPeaksem, thresh_binary, freqPeak] = freqPeakBandpass(data1spectro, data1bandpass, data2spectro, data2bandpass, varargin )
%Will find the peak frequency of a spectrogram data (between the specified
%band, and then bandpass the data centered on that frequency and run
%statistical comparison


[varargin, ff]=util.argkeyval('ff', varargin, []); %get the frequency bands of the rows of the spectrogram data
[varargin, freqOfInterest]=util.argkeyval('freqOfInterest', varargin, [1 size(data1spectro,1)]); %get the band to look for the max between
[varargin, pwr]=util.argkeyval('pwr', varargin, 2); %different ways to get power, either square it or get hilbert
[varargin, plt]=util.argkeyval('plt', varargin, 0); %plot if you want, 1 does the SE or 2 can do the shuffle as the shaded.
[varargin, fs]=util.argkeyval('fs', varargin, 500); %sampling rate
[varargin, bandpassRange]=util.argkeyval('bandpassRange', varargin,5); %how big do we want the frequency range to be
[varargin, norm]=util.argkeyval('norm', varargin,1); % 0 is don't, 1 is normalize across all data stitched together, 2 is normalize by trial 
[varargin, tt]=util.argkeyval('tt', varargin, []); % time for plotting if you want 


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
bandfilterData = designfilt('bandpassfir','FilterOrder', 100,'CutoffFrequency1',fplow-bandpassRange,'CutoffFrequency2',fphigh+bandpassRange, 'SampleRate',fs);
Data1FreqPeakBP = filtfilt(bandfilterData, data1bandpass'); %assumes data is trials by freq
Data1FreqPeakBP = Data1FreqPeakBP';
switch pwr
    case 1
        %square for power
        Data1FreqPeakBPs = Data1FreqPeakBP.^2; %turn to power
    case 2
        %hilbert for power
        Data1FreqPeakBPs = abs(hilbert(Data1FreqPeakBP));
end

Data1FreqPeakBPsdb=10*log10(Data1FreqPeakBPs); %consData1er not doing this(or doing it after the smoothing) it creates a weirder view and it's so narrow a band.
[Data1FreqPeakBPsSm, tplotC]=Analysis.BasicDataProc.convSmooth(Data1FreqPeakBPs, 60, fs); %tested 60ms window and 30 and 60 is better
[Data1FreqPeakBPsdbSm, tplotC]=Analysis.BasicDataProc.convSmooth(Data1FreqPeakBPsdb, 60, fs);
Data1FreqPeakBPsSm = Data1FreqPeakBPsSm';
Data1FreqPeakBPsdbSm = Data1FreqPeakBPsdbSm';

%since it's different frequencies, normalize it.
switch norm
    case 0
        Data1FreqPeakmn = mean(Data1FreqPeakBPsSm);
        Data1FreqPeaksem = std(Data1FreqPeakBPsSm, [], 1) / sqrt(size(Data1FreqPeakBPsSm,1));
    case 1
        tempDAll = [];
        for ii = 1:size(Data1FreqPeakBPsSm,1)
            tempD = Data1FreqPeakBPsSm(ii,:);
            tempDAll = horzcat(tempDAll, tempD);
        end
        mn = mean(tempDAll); sd = std(tempDAll);
        Data1FreqPeakBPsSmNorm = (Data1FreqPeakBPsSm - mn)./sd;
        Data1FreqPeakmn = mean(Data1FreqPeakBPsSmNorm);
        Data1FreqPeaksem = std(Data1FreqPeakBPsSmNorm, [], 1) / sqrt(size(Data1FreqPeakBPsSmNorm,1));
    case 2
        Data1FreqPeakmn = mean(normalize(Data1FreqPeakBPsSm,2));
        Data1FreqPeaksem = std(normalize(Data1FreqPeakBPsSm,2), [], 1) / sqrt(size(Data1FreqPeakBPsSm,1));
end

%filter built above
Data2FreqPeakBP = filtfilt(bandfilterData, data2bandpass');
Data2FreqPeakBP = Data2FreqPeakBP';
switch pwr
    case 1
        %square for power
        Data2FreqPeakBPs = Data2FreqPeakBP.^2; %turn to power
    case 2
        %hilbert for power
        Data2FreqPeakBPs = abs(hilbert(Data2FreqPeakBP));
end

Data2FreqPeakBPsdb=10*log10(Data2FreqPeakBPs); %consider not doing this(or doing it after the smoothing) it creates a weirder view and it's so narrow a band.
[Data2FreqPeakBPsSm, tplotC]=Analysis.BasicDataProc.convSmooth(Data2FreqPeakBPs, 60, fs); %tested 60ms window and 30 and 60 is better
[Data2FreqPeakBPsdbSm, tplotC]=Analysis.BasicDataProc.convSmooth(Data2FreqPeakBPsdb, 60, fs);
Data2FreqPeakBPsSm = Data2FreqPeakBPsSm';
Data2FreqPeakBPsdbSm = Data2FreqPeakBPsdbSm';

%since it's different frequencies, normalize it.
switch norm
    case 0 %no normalization
        Data2FreqPeakmn = mean(Data2FreqPeakBPsSm);
        Data2FreqPeaksem = std(Data2FreqPeakBPsSm, [], 1) / sqrt(size(Data2FreqPeakBPsSm,1));
        %run shuffle stats
        [mean_sd, thresh_binary] = stats.shuffle_stats2d(Data1FreqPeakBPsSm, Data2FreqPeakBPsSm, 'xshuffles', 1000, 'plt', true);

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
        %run shuffle stats (already normalized) 
        % data 1 is emotion task,
        %data 2 is identity task the way it's being put in now. 
        
        [mean_sd, thresh_binary] = stats.shuffle_stats2d(Data1FreqPeakBPsSmNorm, Data2FreqPeakBPsSmNorm, 'xshuffles', 1000, 'plt', true, 'tt', tt , 'ff', ff);
    case 2 %normalize within each trial
        Data2FreqPeakBPsSmNorm = normalize(Data2FreqPeakBPsSm,2); %normalize across all trials
        Data2FreqPeakmn = mean(Data2FreqPeakBPsSmNorm);
        Data2FreqPeaksem = std(Data2FreqPeakBPsSmNorm, [], 1) / sqrt(size(Data2FreqPeakBPsSm,1));
        %run shuffle stats (already normalized)
        [mean_sd, thresh_binary] = stats.shuffle_stats2d(Data2FreqPeakBPsSmNorm, Data1FreqPeakBPsSmNorm, 'xshuffles', 1000, 'plt', true, 'tt', tt, 'ff', ff);

end

freqPeak(1,1) = freqPeak1; %Emt
freqPeak(1,2) = freqPeak2; %Idt
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