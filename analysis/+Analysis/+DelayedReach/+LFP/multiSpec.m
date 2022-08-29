function [OutputArray, FreqBins, TimeBins] = multiSpec(DataArray, SpecType, varargin)
% multiSpec(DataArray, SpecType, varargin)
%
% Wrapper to generate array of Chronux spectrums or spectrograms from
% neural data array
% 
% Required: 
%  - DataArray:  TimeXChannels/Trials. Can also have extra
%    dimension for channels or trials (ex: TimeXChXTrials, TimeXTrialsXCh)
%  - SpecType as 'spectrum' or 'spectrogram'. Will run mtdspectrumc or
%    mtdspecgramc, respectively. (To-Do: add more function options)
% 
% multiSpec(..., ..., 'Parameters', ParamStruct)
% Pass custom parameters to use with Chronux. If none given, will use
% defaults.
%
% multiSpec('DtClass', 'single')
% data class of the output either 'single' or 'double'. Default: 'single'

    [varargin, ChrParams, ~, found] = util.argkeyval('Parameters', varargin, '');
    if ~found
        fprintf('Using default Chronux parameters\n')
        MovingWin     = [1.0 0.250]; %[WindowSize StepSize]
        Tapers        = [5 9]; % [TW #Tapers] TW = Duration*BandwidthDesired
        Pad           = 0; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
        FPass         = [0 1000]; %frequency range of the output data
        TrialAve      = 0; %we want it all
        ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, 'trialave', TrialAve, 'MovingWin', MovingWin); 
        if exist('ns', 'var')
            ChrParams.Fs = ns.Fs;
        else
            ChrParams.Fs = 2000;
        end
    end
    assert(isa(ChrParams, 'struct'), 'Parameters must be entered as a struct')
    
    [varargin, DtClass] = util.argkeyval('DtClass', varargin, 'single');
    [varargin, init]    = util.argkeyval('init', varargin, []);
    [varargin, gpuflag] = util.argkeyval('gpuflag', varargin, true);
    
    % make sure no orphan input arguments
    util.argempty(varargin);

    NumDimensions = length(size(DataArray));
    assert(NumDimensions > 1 & NumDimensions < 4, 'DataArray has incorrect number of dimensions')


    switch SpecType
        case 'spectrum'
            [OutputArray, FreqBins, TimeBins] = makeSpectrums(DataArray, ChrParams, NumDimensions, DtClass, init, gpuflag);
        case 'spectrogram'
            [OutputArray, FreqBins, TimeBins] = makeSpectrograms(DataArray, ChrParams, NumDimensions, ChrParams.MovingWin, DtClass, init, gpuflag);
    end
    
    
    function [OutputArray, FreqBins, TimeBins] = makeSpectrums(DataArray, ChrParams, NumDimensions, DtClass, init, gpuflag)
        % get chronux output dimensions for preallocation
        [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(DataArray,1), [], DtClass);
        
        % mtspectrumc takes TxCh/Tr input array and outputs FreqxCh/Tr
        % spectrums. Need to loop through 3rd dimension if available to
        % generate multiple spectrums
        if NumDimensions == 2
            [~, SecondDim] = size(DataArray);
            OutputArray = zeros(size(FreqBins, 2), SecondDim, 'single');
            OA = chronux_gpu.ct.mtspectrumc(DataArray, ChrParams, init, gpuflag);
            OutputArray = gather(OA);
        elseif NumDimensions == 3
            [~, SecondDim, ThirdDim] = size(DataArray);
            OutputArray = zeros(size(FreqBins, 2), SecondDim, ThirdDim, 'single');
            for i = 1:ThirdDim
                x = chronux_gpu.ct.mtspectrumc(DataArray(:,:,i),ChrParams, init, gpuflag);
                OutputArray(:,:,i) = gather(x);
            end
        else
            fprintf('No code yet for NumDimensions (%d) provided\n', NumDimensions)
        end
        
    end
        
    
    
    function [OutputArray, FreqBins, TimeBins] = makeSpectrograms(DataArray, ChrParams, NumDimensions, MovingWin, DtClass, init, gpuflag)
        % get chronux output dimensions for preallocation
        [FreqBins,TimeBins] = util.chronux_dim(ChrParams, size(DataArray,1), MovingWin, DtClass);
        
        if NumDimensions == 2
            [~, SecondDim] = size(DataArray);
            OutputArray = zeros(size(TimeBins,2), size(FreqBins, 2), SecondDim, 'single');
            OutputArray = chronux_gpu.ct.mtspecgramc(DataArray, MovingWin, ChrParams);
        elseif NumDimensions == 3
            [~, SecondDim, ThirdDim] = size(DataArray);
            OutputArray = zeros(size(TimeBins,1), size(FreqBins, 2), SecondDim, ThirdDim, 'single');
            for i = 1:ThirdDim
                x = chronux_gpu.ct.mtspecgramc(DataArray(:,:,i), MovingWin, ChrParams);
                OutputArray(:,:,:,i) = x;
            end
        else
            fprintf('No code yet for NumDimensions (%d) provided\n', NumDimensions)
        end
        
    end % end makeSpectrograms
end % end multiSpec