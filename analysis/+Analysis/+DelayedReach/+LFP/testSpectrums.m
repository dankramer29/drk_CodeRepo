function [ChannelAverages, SampleAverages, SampleTimes, NeuralData, Spectrums] = testSpectrums(varargin)
%testSpectrums(varargin) generate and plot spectrums from samples of neural data
% User will be prompted to select a task file, specify the folder
% containing the data file, and specify which recording format to use
% (ns3,ns6, etc).
%
%  varargin:
%     'ActiveChannels': Channels that recorded neural signal.  If none provided,
%     user will be prompted to provide them in the Command Window. 
%  
%     'PlotSpecs': true/false. Default: true. Plots the ChannelAvgStats and 
%     SampleAvgStats with confidence intervals, one figure per column in each.
%     
%     
%     'ProcessNoise': true/false. Default: false. Processes all channels in the ns
%     object NOT listed in 'ActiveChannels'.
%     
%     'Mode': 'BootCI', 'Mean'. Default: bootci. Specify which statistical method
%     to use to calculate an average. 'bootci' will use @mean on 1000 bootstrapped
%     samples of the Spectrum data, and will also return a 95% confidence interval.
%     'bootci' uses a Parfor loop to speed up this process.
%     'mean' will simply average the Spectrum array across each dimension, and 
%     should produce results faster.
%
%     'NameMod': String to add to figure names. By default, all figures will contain
%     the task name and time stamps, along with Channel# or Sample#. If
%     'ProcessNoise' is true, 'Noise' will be appended to the name as a
%     prefix. Ex: 'MicroChannels', 'MacroChannels', 'LHippo', etc. 
%
% Outputs: 
%     ChannelAvgStats: 2xNumSamples cell array. Row 1 is the average of all 
%     channels for each sample; the second row is the lower and upper bound 95% 
%     confidence interval if 'mode' = 'bootstrap'.
%    
%     SampleAvgStats: 2xNumChannels cell array. Row 1 is the average of all
%     samples for each channel the second row is the lower and upper bound 95% 
%     confidence interval if 'mode' = 'bootstrap'.
% 
%     SampleTimes: 2xNumSamples cell array. 1st column are start times, 2nd
%     column are the sample windows.
%     
%     NeuralData: Samples x NumChannels x NumSamples . That's all I got!
%     
%     Spectrums: Struct with PowerArray (FrequencyBins x NumChannels x NumSamples)
%     and FreqBins (1xFrequencyBins). Calls multiSpec on NeuralData. 

    [varargin, PlotSpecs] = util.argkeyval('PlotSpecs', varargin, true);
    [varargin, ProcNoise] = util.argkeyval('ProcessNoise', varargin, false);
    [varargin, ActiveChannels, ~, Found] = util.argkeyval('ActiveChannels', varargin, []);
    if ~Found
        ActiveChannels = input('Provide Active Channels: ', 's');
    end
    assert(length(ActiveChannels) >= 1, 'At least 1 active channel must be provided')
    [varargin, NameMod, ~, NameModFound]  = util.argkeyval('NameMod', varargin, '');
    [varargin, Mode] = util.argkeyval('Mode', varargin, 'BootCI');
    
    util.argempty(varargin);

    %Initialize task specifics
    [fullTaskName, nsGrids, nsType] = Analysis.DelayedReach.LFP.getObjInfo;
    taskObj       = FrameworkTask(fullTaskName);
    ns            = taskObj.getNeuralDataObject(nsGrids, nsType);
    ns            = ns{1};
    ChanRange     = 1:max([ns.ChannelInfo.ChannelID]);
    ActiveChanLogical = ismember(ChanRange, ActiveChannels);
    ChannelArray      = ChanRange(ActiveChanLogical); %Long way to get same array as ActiveChannels, but
    % can now pull noise channels without directly listing. See 
    % if ProcNoise loop below. 
    
    TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));
    if NameModFound
        TaskString = sprintf('%s-%s', NameMod, TaskString); %Add user specified prefix
    end
    
    if ProcNoise
        Prefix = 'Noise';
        TaskString = sprintf('%s-%s', Prefix, TaskString); %Add Noise to figure names while plotting
        NoiseChanLogical = logical((ActiveChanLogical - 1) .* -1); %Invert Active logical
        ChannelArray = ChanRange(NoiseChanLogical);
    end
    
    fprintf('Processing %s \n', TaskString);
    %Possible data times to use; length of sample to pull; num samples to
    %extract
    NeuralTime    = [taskObj.data.neuralTime];
    MaxTime       = floor(max(NeuralTime));
    SampleWindow  = 5;
    NumSamples    = 20;

    %Make NumSamples x 2 array of start times and sample lengths to extract
    RandStarts    = rand(NumSamples,1);
    StartTimes    = RandStarts .* MaxTime;
    SampleLength  = ones(20,1) .* SampleWindow;
    SampleTimes   = [StartTimes SampleLength];
    DtClass       = 'single';

    %Initialize Chronux Parameters
    MovingWin     = [1.0 0.250]; %[WindowSize StepSize]
    Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
    Pad           = -1; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
    FPass         = [0 10000]; %frequency range of the output data
    TrialAve      = 0; %we want it all
    Fs            = ns.Fs;
    ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
    gpuflag       = true;

    % Call Functions, store output
    [NeuralData, Spectrums] = makeSpectrumData(ns, ChannelArray, SampleTimes, DtClass, ChrParams, gpuflag);
    [MeanCorrCoef, StDCorrCoef, CorrCoefMat] = rawCorrCoef(NeuralData, TaskString);

    %Compute Stats on Spectrums
    switch Mode
        case 'BootCI'
            SampleAverages = Analysis.DelayedReach.LFP.specStats([Spectrums.PowerArray], 'Mode', Mode, 'Dimension', 3);
            ChannelAverages = Analysis.DelayedReach.LFP.specStats([Spectrums.PowerArray], 'Mode', Mode, 'Dimension', 2);
        case 'Mean'
            SampleAverages = squeeze(mean([Spectrums.PowerArray], 3));
            ChannelAverages = squeeze(mean([Spectrums.PowerArray], 2));
    end
    
    % Plots a lot of figures, eats a lot of RAM
    if PlotSpecs
        plotSpectrumData(Spectrums, SampleAverages, ChannelAverages, TaskString, ChannelArray, Mode)
    end
    
    function [NeuralData, Spectrums] = makeSpectrumData(ns, ChannelArray, SampleTimes, DtClass, ChrParams, gpuflag)
        %Extract samples, timing and FeatureDef
        [NeuralData, ~, ~] = proc.blackrock.broadband(...
            ns, 'PROCWIN', SampleTimes, 'CHANNELS', ChannelArray,...
            DtClass, 'Uniformoutput', true);
        fprintf('Extracted NeuralData\n')


        %Create spectrums for all channels and samples
        fprintf('Making Spectrums\n')
        [PowerArray, FreqBins, ~] = Analysis.DelayedReach.LFP.multiSpec(NeuralData, 'spectrum', 'Parameters', ChrParams, 'DtClass', DtClass, 'gpuflag', gpuflag);
        Spectrums = struct();
        Spectrums.PowerArray = PowerArray;
        Spectrums.FreqBins   = FreqBins;

        fprintf('Done with makeSpectrumData\n')
    
    end %end function makeSpectrumData
    
    function [MeanCorrCoef, StDCorrCoef, CorrCoefMat] = rawCorrCoef(NeuralData, TaskString)
        NSamp = size(NeuralData,3);
        NChan = size(NeuralData,2);
        CorrCoefMat = zeros(NChan, NChan, NSamp);
        for i = 1:NSamp
            CorrCoefMat(:,:,i) = corrcoef(squeeze(NeuralData(:,:,i)));
        end
        MeanCorrCoef = mean(CorrCoefMat, 3);
        StDCorrCoef = std(CorrCoefMat, [], 3);
        
        TString = sprintf('%s-CorrCoef', TaskString);
        figure('Name', TString, 'NumberTitle', 'off',...
            'position', [50 100 600 1200]);
        subplot(2,1,1)
        imagesc(1:NChan, 1:NChan, MeanCorrCoef); axis xy; colorbar;
        set(gca, 'XMinortick', 'on', 'XGrid', 'on', 'XMinorGrid', 'on',...
            'YMinorTick', 'on', 'YGrid', 'on', 'TickDir', 'out',...
            'YMinorGrid', 'on')
        title('Mean Correlation Coeff');
        subplot(2,1,2)
        imagesc(1:NChan, 1:NChan, StDCorrCoef); axis xy; colorbar;
        set(gca, 'XMinortick', 'on', 'XGrid', 'on', 'XMinorGrid', 'on',...
            'YMinorTick', 'on', 'YGrid', 'on', 'TickDir', 'out',...
            'YMinorGrid', 'on')
        title('Standard Dev Correlation Coeff');
        
    end
    
    function plotSpectrumData(Spectrums, SampleAvgStats, ChannelAvgStats, TaskString, ChannelArray, Mode)
        switch Mode
            case 'BootCI'
                FreqBins = Spectrums.FreqBins;
                Channels = size(SampleAvgStats,2);
                % Plot each channels' averaged spectrum and confidence intervals
                fprintf('Plotting %d Channels\n', Channels);
                for Ch = 1:Channels
                    TString = sprintf('%s-TestSpectrum-Chan%d', TaskString, ChannelArray(Ch));
                    figure('Name', TString, 'NumberTitle', 'off', 'units', 'normalized',...
                        'outerposition', [0 0 1 1]);
                    YMean = 10*log10(SampleAvgStats{1,Ch})';
                    YCI   = 10*log10(SampleAvgStats{2,Ch})';
                    plot_ci(FreqBins, [YMean YCI(:,1) YCI(:,2)],...
                        'PatchColor', [0.7 0.87 0.54], 'PatchAlpha', 0.2,...
                        'MainLineWidth', 2, 'MainLineStyle', '-',...
                        'MainLineColor', [0.2 0.63 0.17] , 'LineWidth', 1,...
                        'LineStyle','-', 'LineColor', [0.7 0.87 0.54]);
                    ylim([-40 50])
                    title(TString);
                    ylabel('10*log10(Power)')
                    xlabel('Frequency')
                end

                % Plot each samples' averaged spectrum and confidence intervals
                Samples = size(ChannelAvgStats,2);
                fprintf('Plotting %d Samples\n', Samples)
                for S = 1:Samples
                    TString = sprintf('%s-TestSpectrum-Sample%d', TaskString, S);
                    figure('Name', TString, 'NumberTitle', 'off', 'units', 'normalized',...
                        'outerposition', [0 0 1 1]);
                    YMean = 10*log10(ChannelAvgStats{1,S})';
                    YCI   = 10*log10(ChannelAvgStats{2,S})';
                    plot_ci(FreqBins, [YMean YCI(:,1) YCI(:,2)],...
                        'PatchColor', [0.65 0.805 0.89], 'PatchAlpha', 0.2,...
                        'MainLineWidth', 2, 'MainLineStyle', '-',...
                        'MainLineColor', [0.12 0.47 0.703] , 'LineWidth', 1,...
                        'LineStyle','-', 'LineColor', [0.65 0.805 0.89]);
                    ylim([-40 50])
                    title(TString);
                    ylabel('10*log10(Power)')
                    xlabel('Frequency')            
                end
                
            case 'Mean'
                FreqBins = Spectrums.FreqBins;
                Channels = size(SampleAvgStats,2);
                fprintf('Plotting %d Channels\n', Channels);
                for Ch = 1:Channels
                    TString = sprintf('%s-TestSpectrum-Chan%d', TaskString, ChannelArray(Ch));
                    figure('Name', TString, 'NumberTitle', 'off', 'units', 'normalized',...
                        'outerposition', [0 0 1 1]);
                    YMean = 10*log10(SampleAvgStats(:,Ch))';
                    plot(FreqBins, YMean, 'Color', [0.2 0.63 0.17]);
                    ylim([-40 50])
                    title(TString);
                    ylabel('10*log10(Power)')
                    xlabel('Frequency')
                end

                % Plot each samples' averaged spectrum and confidence intervals
                Samples = size(ChannelAvgStats,2);
                fprintf('Plotting %d Samples\n', Samples)
                for S = 1:Samples
                    TString = sprintf('%s-TestSpectrum-Sample%d', TaskString, S);
                    figure('Name', TString, 'NumberTitle', 'off', 'units', 'normalized',...
                        'outerposition', [0 0 1 1]);
                    YMean = 10*log10(ChannelAvgStats(:,S))';
                    plot(FreqBins, YMean, 'Color', [0.12 0.47 0.703])
                    ylim([-40 50])
                    title(TString);
                    ylabel('10*log10(Power)')
                    xlabel('Frequency')
                end
        end
    
    end %end function plotSpectrumData

end %End Function
