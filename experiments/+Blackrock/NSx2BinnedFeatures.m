function varargout = NSx2BinnedFeatures(NSxFile,varargin)
% NSX2BINNEDFEATURES generate binned features from an NSx file
%
% All input option strings are case-insensitive.
%
% This function saves data out into a custom format in MAT files.  Use the
% READNSXBINNEDFEATURES function to read the data back.
%
% NSx2BinnedFeatures(FILE)
% Use all default settings to generate binned features from the NSx file
% specified in FILE.
% 
% NSx2BinnedFeatures(FILE,'[Q]uiet')
% Turn off warnings
%
% NSx2BinnedFeatures(FILE,'[TimeLag]gingEdge')
% Bins of data will be aligned so that the end of the bin occurs at the
% time for that bin.  Mimics the online case.  Default is for alignment to
% the leading edge of the bin (mainly for convenience so that time starts
% at zero).
%
% NSx2BinnedFeatures(FILE,'NoCopy')
% If re-generating data for a particular data packet, and therefore
% forcing a previously-generated file to be renamed, this option specifies
% that data from other packets in the renamed file will NOT be copied over
% to the new file.  See Blackrock.NSx help for information on data packets
% for NSx files.
%
% NSx2BinnedFeatures(FILE,'NoSave')
% Do not save the resulting features to file.
%
% NSx2BinnedFeatures(FILE,'SaveAsDouble')
% Only valid if output will be saved to file.  Normally, the data are saved
% in single floating-point format (32-bit instead of double 64-bit) to save
% on space.  This option specifies that the data should be saved in double
% 64-bit floating point format.
%
% NSx2BinnedFeatures(FILE,'[OutputDir]ectory',OUTPUTDIR)
% By default, if data will be saved to disk, it will be saved to the
% current MATLAB working directory.  This option allows the user to specify
% a different saving directory.  If OUTPUTDIR does not exist, the script
% will attempt to create it, and will generate an error if it cannot.
%
% NSx2BinnedFeatures(FILE,'[MovingWin]dow',[WINSIZE STEPSIZE])
% By default, the window size will be 250 msec and the step size will be 50
% msec.  Use this option specify different values.
%
% NSx2BinnedFeatures(FILE,'fftN',VALUE)
% By default, the number of points in the FFT will be 512.  Use this option
% to specify a different value.
%
% NSx2BinnedFeatures(FILE,'[Freq]uencyBand',[LOW HIGH])
% By default, frequencies between 0 and 200 Hz will be retained.  Use this
% option specify a different range of frequencies.  LOW and HIGH indicate
% the lower and higher edges of the range.
%
% NSx2BinnedFeatures(FILE,'Raw')
% By default, the data will be downsampled if necessary to get to a
% sampling rate of 2000 samples/sec.  Use this option to specify that the
% data should be left at its original sampling rate for processing.
%
% NSx2BinnedFeatures(FILE,'[Down]sampleFactor',VALUE)
% By default, the data will be downsampled if necessary to get to a
% sampling rate of 2000 samples/sec.  Use this option to specify a
% downsampling factor other than the default one that would produce 2000
% samples/sec.  VALUE must be integer.
%
% NSx2BinnedFeatures(FILE,'[FilterObj]ect',OBJ)
% By default, an elliptical will be designed with passband ripple 0.1 dB,
% stopband attenuation of 30 dB, and frequency characteristics to satisfy
% the Nyquist criterion.  Use this option to supply a custom filter in the
% form of a filter object, which must have fields SOSMatrix and
% ScaleValues, which will be present if the object is generated using the
% fdesign.lowpass and design methods in MATLAB.
%
% NSx2BinnedFeatures(FILE,'[FilterCoeff]icients',{b,a})
% By default, an elliptical will be designed with passband ripple 0.1 dB,
% stopband attenuation of 30 dB, and frequency characteristics to satisfy
% the Nyquist criterion.  Use this option to supply a custom filter in the
% form of a transfer function.  Provide the filter function as a cell array
% where the first element of the cell array is the vector 'b' (the
% denominator of the transfer function) and the second element is the
% vector 'a' (the numerator of the transfer function).
%
% NSx2BinnedFeatures(FILE,'[pack]et',VALUE)
% By default, data will be read from the largest data packet in the NSx
% file.  Use this option to specify the packet from which data should be
% read.
%
% NSx2BinnedFeatures(FILE,'[point]s',NUM_POINTS)
% NSx2BinnedFeatures(FILE,'[point]s',[FIRST LAST])
% By default, all data will be read from the requested data packet.  Use
% this option to specify the amount of data that will be read in the form 
% of samples.  Provide the number of points NUM_POINTS starting from the
% beginning, or the FIRST and LAST points.
%
% NSx2BinnedFeatures(FILE,'[time]s',TIME)
% NSx2BinnedFeatures(FILE,'[time]s',TIME,'[hour]s')
% NSx2BinnedFeatures(FILE,'[time]s',TIME,'[min]utes')
% NSx2BinnedFeatures(FILE,'[time]s',TIME,'[sec]onds')
% NSx2BinnedFeatures(FILE,'[time]s',TIME,'[milli]seconds')
% By default, all data will be read from the requested data packet.  Use
% this option to specify the amount of data that will be read in the form
% of time.  TIME can be a single element, in which case it will be
% interpreted as the total amount of time starting at the beginning, or it
% can be a two-element vector specifying the starting and ending time.
% By default, values in TIME will be interpreted as number of seconds, but
% by providing a qualifier the values can also be interpreted as numbers of
% hours, minutes, seconds, or milliseconds.
%
% NSx2BinnedFeatures(FILE,'[map]file],MAPFILE)
% Specify a map file which allows seamless translation between channels and
% electrodes.
%
% NSx2BinnedFeatures(FILE,'[ch]annels',CHANLIST)
% By default, data will be read for all channels in the NSx file.  Use this
% option to specify a list of specific channels from which to read and
% process data.
%
% NSx2BinnedFeatures(FILE,'[el]ectrodes',ELECLIST)
% By default, data will be read for all channels in the NSx file.  Use this
% option to specify a list of specific electrodes from which to read and
% process data.  **NOTE that NSx files store data in terms of channel
% numbers, not electrode numbers, and that in order to use electrode
% numbers you must also provide a map file as specified above.
%
% NSx2BinnedFeatures(FILE,'[MaxBinW]indows')
% By default, the processed, binned features will be split into chunks, or
% bins, of 256MB.  These bins all get saved into the same MAT file, but
% they can be read out individually. This option indicates how many windows
% (e.g., MOVINGWIN above) will be included in each bin.  This option is 
% linked to the MaxBinPoints option in that MaxBinPoints = MaxBinWindows *
% PointsPerWindow.  If MaxBinPoints is specified separately, it will
% overwrite anything intended via MaxBinWindows.
%
% NSx2BinnedFeatures(FILE,'[MaxBinP]oints')
% By default, the processed, binned features will be split into chunks, or
% bins, of 256MB.  These bins all get saved into the same MAT file, but
% they can be read out individually. This option indicates how many points 
% (where each point includes a sample from each channel) of the downsampled
% data will be included in each bin.  By default MaxBinPoints = 
% MaxBinWindows * PointsPerWindow.  Specifying MaxBinPoints directly means
% that MaxBinWindows will not be used for anything.
%
% NSx2BinnedFeatures(FILE,'[Win]dowKernel',KERN)
% By default each WINSIZE segment of data will be windowed with the Hann
% window before FFT.  Use this option to specify a custom kernel.  KERN
% must be either a function handle, or a string representation of a
% function handle, which is recognized by the MATLAB builtin function
% WINDOW.

% check file existence and open NSx object
if exist(NSxFile,'file')~=2
    error('File ''%s'' does not exist.',NSxFile);
end
ns = Blackrock.NSx(NSxFile);
RawFs = ns.Fs;

% verbosity
FlagVerbose = true;
if any(strncmpi(varargin,'Quiet',1))
    FlagVerbose = false;
end

% leading: time indicates leading edge of bin (default, starts at 0)
% lagging: time indicates lagging edge of bin (like online, starts at MovingWindow(2))
FlagTimeLeadingEdge = true;
if any(strncmpi(varargin,'TimeLaggingEdge',7))
    FlagTimeLeadingEdge = false;
end

% copy data from other packets to new file when renaming
FlagCopyOnRename = true;
if any(strncmpi(varargin,'NoCopy',6))
    FlagCopyOnRename = false;
end

% save output to a file (instead of or in addition to command line return)
FlagSave = true;
FlagSaveAsSingle = true;
if any(strncmpi(varargin,'NoSave',6))
    FlagSave = false;
end
if FlagSave
    % save as double (64-bit) or single (32-bit)
    if any(strncmpi(varargin,'SaveAsDouble',12))
        FlagSaveAsSingle = false;
    else
        if FlagVerbose
            warning('Default to save data to disk in single (32-bit) floating point format');
        end
    end
    
    % set output directory
    OutputDirectory = fileparts(NSxFile); % default same location as NSx file
    if any(strncmpi(varargin,'OutputDirectory',9))
        idx = find(strncmpi(varargin,'OutputDirectory',9));
        OutputDirectory = varargin{idx+1};
        if exist(OutputDirectory,'dir')~=7
            [status,msg] = mkdir(OutputDirectory);
            if status==0
                error('Could not create directory ''%s'': %s',OutputDirectory,msg);
            end
        end
    else
        if FlagVerbose
            warning('Default output directory ''%s''',OutputDirectory);
        end
    end
    
    % full path to save file
    [~,nsxBasename,nsxExt] = fileparts(NSxFile);
    OutFile = fullfile(OutputDirectory,[nsxBasename '_' nsxExt(2:end) '_BinnedFeatures.mat']);
end

% moving window
MovingWindow = [0.25 0.05];
if any(strncmpi(varargin,'MovingWindow',9))
    idx = find(strncmpi(varargin,'MovingWindow',9));
    MovingWindow = varargin{idx+1};
else
    if FlagVerbose
        warning('Default window %.2f sec and step %.2f sec',MovingWindow(1),MovingWindow(2));
    end
end

% number of points in FFT
fftN = 512;
if any(strncmpi(varargin,'fftN',4))
    idx = find(strncmpi(varargin,'fftN',4));
    fftN = varargin{idx+1};
else
    if FlagVerbose
        warning('Default FFT size %d',fftN);
    end
end

% frequency band
FrequencyBand = [0 200];
if any(strncmpi(varargin,'FrequencyBand',4))
    idx = find(strncmpi(varargin,'FrequencyBand',4));
    FrequencyBand = varargin{idx+1};
else
    if FlagVerbose
        warning('Default to retain frequencies %d Hz to %d Hz',FrequencyBand(1),FrequencyBand(2));
    end
end

% setup for downsampling the data
DownsampleFactor = RawFs/2e3;
if DownsampleFactor>1
    FlagDownsample = true;
else
    FlagDownsample = false;
end
if any(strncmpi(varargin,'Raw',3))
    FlagDownsample = false;
elseif any(strncmpi(varargin,'DownsampleFactor',4))
    idx = find(strncmpi(varargin,'DownsampleFactor',4));
    DownsampleFactor = varargin{idx+1};
    if DownsampleFactor>1
        FlagDownsample = true;
    else
        FlagDownsample = false;
    end
elseif DownsampleFactor>1
    if FlagVerbose
        warning('Default downsample to %d Hz (raw data at %d Hz, downsample factor %d)',RawFs/DownsampleFactor,RawFs,DownsampleFactor);
    end
end
if (DownsampleFactor - floor(DownsampleFactor)) ~= 0
    error('Only integer values are currently supported for downsampling (requested was %.2f)',DownsampleFactor);
end
if FlagDownsample
    zi = []; % filter initial conditions
    
    if any(strncmpi(varargin,'FilterObject',9))
        idx = find(strncmpi(varargin,'FilterObject',9));
        f = varargin{idx+1};
        [b,a] = sos2tf(f.SOSMatrix,f.ScaleValues);
    elseif any(strncmpi(varargin,'FilterCoefficients',11))
        idx = find(strncmpi(varargin,'FilterCoefficients',11));
        b = varargin{idx+1}{1};
        a = varargin{idx+1}{2};
    else
        Fst = (RawFs/DownsampleFactor)/2;
        Fp = Fst - floor(0.1*Fst);
        Ast = 30;
        Ap = 0.1;
        h = fdesign.lowpass('fp,fst,ap,ast',Fp,Fst,Ap,Ast,RawFs);
        f = design(h,'ellip','MatchExactly','both');
        [b,a] = sos2tf(f.SOSMatrix,f.ScaleValues);
        if FlagVerbose
            warning('Default anti-aliasing filter (elliptical, Order=%d, Fp=%.1f Hz, Fst=%.1f Hz, Ap=%.1f dB, Ast=%.1f dB)',length(b),Fp,Fst,Ap,Ast);
        end
    end
end

% which data packet to read from
if any(strncmpi(varargin,'packet',4))
    idx = find(strncmpi(varargin,'packet',4));
    UserRequestedPacket = varargin{idx+1};
else
    [~,UserRequestedPacket] = max(ns.PointsPerDataPacket);
    if FlagVerbose
        warning('Default to largest data packet (%d of %d)',UserRequestedPacket,length(ns.PointsPerDataPacket));
    end
end
if length(UserRequestedPacket)>1
    error('Can only operate on one data packet at a time.');
end

% which data points to read
if any(strncmpi(varargin,'points',5))
    idx = find(strncmpi(varargin,'points',5));
    if length(varargin{idx+1})==1
        UserRequestedPoints = [1 varargin{idx+1}]; % indicate total number of points required
    else
        UserRequestedPoints = [varargin{idx+1}(1) varargin{idx+1}(end)]; % indicate start and stop
    end
elseif any(strncmpi(varargin,'times',4))
    TimeFactor = RawFs;
    if any(strncmpi(varargin,'hours',4))
        TimeFactor = 60*60*RawFs;
    elseif any(strncmpi(varargin,'minutes',3))
        TimeFactor = 60*RawFs;
    elseif any(strncmpi(varargin,'seconds',3))
        TimeFactor = RawFs;
    elseif any(strncmpi(varargin,'milliseconds',5))
        TimeFactor = RawFs/1000;
    end
    idx = find(strncmpi(varargin,'times',4));
    if length(varargin{idx+1})==1
        inputTimes = [0 varargin{idx+1}]; % indicate total time required
    else
        inputTimes = [varargin{idx+1}(1) varargin{idx+1}(end)]; % indicate start and stop
    end
    UserRequestedPoints(1) = round(inputTimes(1)*TimeFactor) + 1;
    UserRequestedPoints(2) = UserRequestedPoints(1) + round(diff(inputTimes)*TimeFactor) - 1;
else
    UserRequestedPoints = [1 ns.PointsPerDataPacket(UserRequestedPacket)]; % default all available in packet
    if FlagVerbose
        warning('Default to all data points in packet (%d to %d)',UserRequestedPoints(1),UserRequestedPoints(end));
    end
end

% which channels to read
hArrayMap = [];
if any(strncmpi(varargin,'mapfile',3))
    idx = find(strncmpi(varargin,'mapfile',3));
    hArrayMap = Blackrock.ArrayMap(varargin{idx+1});
end
if any(strncmpi(varargin,'channels',2))
    idx = find(strncmpi(varargin,'channels',2));
    UserRequestedChannels = varargin{idx+1};
elseif any(strncmpi(varargin,'electrodes',2))
    if isempty(hArrayMap)
        error('Must provide map file when using electrodes instead of channels');
    end
    idx = find(strncmpi(varargin,'electrodes',2));
    UserRequestedChannels = hArrayMap.el2ch(varargin{idx+1});
else
    UserRequestedChannels = [ns.ChannelInfo.ChannelID];
    if FlagVerbose
        warning('Default to all available channels (%d total, %d to %d)',length(UserRequestedChannels),min(UserRequestedChannels),max(UserRequestedChannels));
    end
end
UserRequestedChannels = sort(unique(UserRequestedChannels),'ascend');

% configure how much data to read (1 data point = all channel samples from 1 sampling period)
PointsPerWindowRaw = round(MovingWindow(1)*RawFs);
PointsPerWindowDownsampled = PointsPerWindowRaw;
if FlagDownsample
    PointsPerWindowDownsampled = floor(PointsPerWindowRaw/DownsampleFactor);
end
PointsPerOverlapRaw = round(MovingWindow(2)*RawFs);
PointsPerOverlapDownsampled = PointsPerOverlapRaw;
if FlagDownsample
    PointsPerOverlapDownsampled = floor(PointsPerOverlapRaw/DownsampleFactor);
end
if fftN<PointsPerWindowDownsampled
    if FlagVerbose
        warning('Will not use %.1f%% of the data since fft_size=%d < win_size=%d',100*((PointsPerWindowDownsampled-fftN)/PointsPerWindowRaw),fftN,PointsPerWindowRaw);
    end
end

% calculate total number of points being requested, but bound it to
% multiples of the window size
NumPointsRequested = diff(UserRequestedPoints)+1;
NumPointsRequested = floor(NumPointsRequested/PointsPerWindowRaw)*PointsPerWindowRaw;
if diff(UserRequestedPoints)+1 ~= NumPointsRequested
    if FlagVerbose
        warning('Discarding %d points at the end for window alignment (window = %d points)',diff(UserRequestedPoints)+1-NumPointsRequested,PointsPerWindowRaw);
    end
end
UserRequestedPoints(2) = UserRequestedPoints(1)+NumPointsRequested-1;
if NumPointsRequested < PointsPerWindowRaw
    error('Must request enough data for at least one window (%.2f sec or %d data points)',MovingWindow(1),PointsPerWindowRaw);
end

% max points per bin: default 256MB of 8b (double) data
freq = (0:(RawFs/DownsampleFactor)/fftN:(RawFs/DownsampleFactor)/2)';
freq_idx = freq>=FrequencyBand(1)&freq<=FrequencyBand(2);
NumFreqBins = nnz(freq_idx);
NumChannels = length(UserRequestedChannels);
MaxWindowsPerBin = floor( (256*1024^2/8) / (NumFreqBins*NumChannels) );
if any(strncmpi(varargin,'MaxBinWindows',7))
    idx = find(strncmpi(varargin,'MaxBinWindows',7));
    MaxWindowsPerBin = varargin{idx+1};
end
MaxPointsPerBinDownsampled = MaxWindowsPerBin*PointsPerWindowDownsampled;
if any(strncmpi(varargin,'MaxBinPoints',7))
    idx = find(strncmpi(varargin,'MaxBinPoints',7));
    MaxPointsPerBinDownsampled = varargin{idx+1};
end

% windowing function
if any(strncmpi(varargin,'WindowKernel',3))
    idx = find(strncmpi(varargin,'WindowKernel',3));
    input = varargin{idx+1};
    if ischar(input)
        input = str2func(input);
    end
    if isa(input,'function_handle')
        WinKernel = window(input,min(fftN,PointsPerWindowDownsampled));
    end
else
    WinKernel = window(@hann,min(fftN,PointsPerWindowDownsampled));
    if FlagVerbose
        warning('Default to hann window');
    end
end

% loop over cells of data
DataClass = 'double';
NumPointsReadRaw = 0;
LoopTimesRaw = nan(1,1e3);
BinData = cell(1,1e3);
BinTimes = cell(1,1e3);
BinIDs = cell(1,1e3);
BinIdx = 1;
FlagRename = false; % default so variable exists when OutFile doesn't
while (NumPointsRequested - NumPointsReadRaw) > PointsPerWindowRaw
    rawTic = tic;
    
    % calculate how much downsampled data will fit in memory, and how much
    % raw data can fit at once
    [~,NumPointsToReadDownsampled] = util.memcheck(NumChannels,DataClass,...
        'Multiple',PointsPerWindowDownsampled,...
        'TotalUtilization',0.98,...
        'AvailableUtilization',(1/15));
    NumPointsToReadDownsampled = min(NumPointsToReadDownsampled,(NumPointsRequested-NumPointsReadRaw)/DownsampleFactor);
    NumPointsToReadDownsampled = min(NumPointsToReadDownsampled,MaxPointsPerBinDownsampled);
    NumPointsReadDownsampled = 0;
    
    % read raw data in increments to build up to downsampled amount
    DownsampleBinnedData = cell(1,1e3);
    DownsampleBinIdx = 1;
    while NumPointsReadDownsampled < NumPointsToReadDownsampled
        
        % calculate how many raw-data-sized windows we can read
        [~,NumPointsToReadRaw] = util.memcheck(NumChannels,DataClass,...
            'Multiple',PointsPerWindowRaw,...
            'TotalUtilization',0.99,...
            'AvailableUtilization',0.475);
        NumPointsToReadRaw = min(NumPointsToReadRaw,DownsampleFactor*(NumPointsToReadDownsampled-NumPointsReadDownsampled));
        
        % if we needed to read something but can't, generate an error
        if DownsampleBinIdx==1 && NumPointsToReadRaw==0
            error('Out of memory!');
        end
        
        % read raw data
        Points = UserRequestedPoints(1) + NumPointsReadRaw + [0 NumPointsToReadRaw-1];
        data = ns.read(...
            'channels',UserRequestedChannels,...
            'points',Points,...
            'packet',UserRequestedPacket,...
            'int16','quiet');
        data = data'; % columns are samples from one channel
        
        % downsampling the data
        if FlagDownsample && DownsampleFactor>1
            data = double(data);
            if isempty(zi)
                [data,zf] = filter(b,a,data);
            else
                [data,zf] = filter(b,a,data,zi);
            end
            zi = zf;
            data = data(1:DownsampleFactor:end,:);
        end
        NumPointsReadDownsampled = NumPointsReadDownsampled + size(data,1);
        
        % save out
        DownsampleBinnedData{DownsampleBinIdx} = data;
        DownsampleBinIdx = DownsampleBinIdx + 1;
        
        % update pointer and memory situation
        NumPointsReadRaw = NumPointsReadRaw + NumPointsToReadRaw;
    end
    data = cat(1,DownsampleBinnedData{:});
    clear DownsampleBinnedData;
    
    if size(data,1) ~= NumPointsToReadDownsampled
        error('Somehow read the wrong number of raw points to give %d downsampled points.',NumPointsToReadDownsampled);
    end
    
    % create overlapping windows of data
    WindowEdgesDownsampled = 1:PointsPerOverlapDownsampled:(NumPointsToReadDownsampled-(PointsPerWindowDownsampled-1));
    WindowIdx = repmat(WindowEdgesDownsampled(:)',[PointsPerWindowDownsampled 1]) + repmat((0:PointsPerWindowDownsampled-1)',[1 length(WindowEdgesDownsampled)]);
    data = reshape(data(WindowIdx(:),:),[size(WindowIdx,1) size(WindowIdx,2) size(data,2)]);
    clear WindowIdx;
    
    % if fft_size < PointsPerWindow, reduce to most recent fft_size points
    st = max(1,size(data,1)-fftN+1);
    if st>1
        data = data(st:end,:,:);
    end
    
    % now that permutations are done, convert to double
    % unless we downsampled in which case had to convert above
    if ~FlagDownsample
        data = double(data);
    end
    
    % window the data
    data = repmat(WinKernel,[1 size(data,2) size(data,3)]).*data;
    
    % calculate spectral power
    % see link below for indexing/scaling explanation
    % http://www.mathworks.com/help/signal/ug/psd-estimate-using-fft.html)
    data = fft(data,fftN);
    data = data(1:fftN/2+1,:,:);
    data = (1/((RawFs/DownsampleFactor)*fftN)).*abs(data).^2;
    data(2:end-1,:,:) = 2*data(2:end-1,:,:);
    time = (WindowEdgesDownsampled-1)/(RawFs/DownsampleFactor);
    time = (UserRequestedPoints(1)-1 + NumPointsReadRaw-(NumPointsToReadDownsampled*DownsampleFactor))/RawFs + time;
    if ~FlagTimeLeadingEdge
        time = time + MovingWindow(1);
    end
    
    % throw away unwanted frequencies
    data = data(freq_idx,:,:);
    freq = freq(freq_idx);
    
    % collect times and bin associations
    BinTimes{BinIdx} = time;
    BinIDs{BinIdx} = repmat(BinIdx,1,length(time));
    
    % save results
    if FlagSave
        
        % convert to single
        if FlagSaveAsSingle
            data = cast(data,'single');
        end
        
        % create variables to save out to disk
        eval(sprintf('pkt%02d_bin%04d.data = data;',UserRequestedPacket,BinIdx));
        eval(sprintf('pkt%02d_bin%04d.time = time;',UserRequestedPacket,BinIdx));
        eval(sprintf('pkt%02d_bin%04d.freq = freq;',UserRequestedPacket,BinIdx));
        
        % save to disk
        if BinIdx==1
            if exist(OutFile,'file')==2
                % Rename if PacketIDs contains UserRequestedPacket
                FlagRename = false;
                info = whos('-file',OutFile);
                vars = {info.name};
                if any(ismember(vars,'PacketIDs'))
                    fileContents = load(OutFile,'PacketIDs');
                    if any(ismember(fileContents.PacketIDs,UserRequestedPacket))
                        FlagRename = true;
                    end
                end
                
                % Rename file and save to new file, or append to existing
                if FlagRename
                    [odir,obasename,oext] = fileparts(OutFile);
                    NewFile = fullfile(odir,[obasename '_RENAMED_' datestr(now,'yyyymmdd-HHMMSS') oext]);
                    if FlagVerbose
                        warning('Renaming ''%s'' to ''%s''',OutFile,NewFile);
                    end
                    try
                        java.io.File(OutFile).renameTo(java.io.File(NewFile));
                    catch ME
                        util.errorMessage(ME);
                        return;
                    end
                    % contained UserRequestedPacket but renamed, so save 
                    save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPacket,BinIdx),'-v7.3');
                else
                    % PacketIDs didn't contain UserRequestedPacket
                    save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPacket,BinIdx),'-append','-v7.3');
                end
            else
                % file doesn't exist yet, just save it
                save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPacket,BinIdx),'-v7.3');
            end
        else
            % assume details figured out when BinIdx==1
            save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPacket,BinIdx),'-append','-v7.3');
        end
        
        % clear the created variables
        clear(sprintf('pkt%02d_bin%04d',UserRequestedPacket,BinIdx));
    end
    
    % return results
    if nargout>0
        BinData{BinIdx} = data;
    end
    
    % estimate time elapsed/remaining/total
    PointsReadThisIteration = (NumPointsToReadDownsampled*DownsampleFactor);
    PercentDoneRaw = 100*NumPointsReadRaw/NumPointsRequested;
    LoopTimesRaw(BinIdx) = toc(rawTic);
    estTimeElapsedRaw = sum(LoopTimesRaw(~isnan(LoopTimesRaw)));
    estTimeLeftRaw = (100/PercentDoneRaw)*estTimeElapsedRaw - estTimeElapsedRaw;
    if FlagVerbose
        fprintf('Processed %d points (%.1f%% done) %s elapsed (%s remaining)\n',PointsReadThisIteration,PercentDoneRaw,util.hms(estTimeElapsedRaw),util.hms(estTimeLeftRaw));
    end
    
    % If we haven't read everything yet, on the next round we need to read
    % starting MovingWindow(2) points after the start of the last window
    % (NumPointsReadRaw otherwise points to the end of the last window).
    if NumPointsReadRaw < NumPointsRequested
        PointsToNextWindow = (WindowEdgesDownsampled(end)-1)*DownsampleFactor + PointsPerOverlapRaw;
        NumPointsReadRaw = NumPointsReadRaw - PointsReadThisIteration + PointsToNextWindow;
    end
    BinIdx = BinIdx + 1;
end

% finalize saving
if FlagSave
    
    % copy over other PacketID data from renamed files
    if FlagRename && FlagCopyOnRename
        info = whos('-file',NewFile);
        vars = {info.name};
        FileContents = load(NewFile,'PacketIDs');
        OtherPacketIDs = setdiff(FileContents.PacketIDs,UserRequestedPacket);
        for pp = 1:length(OtherPacketIDs)
            if FlagVerbose
                warning('Copying packet %d data into new file',OtherPacketIDs(pp));
            end
            WhichVars = cellfun(@(x)strcmpi(x(1:5),sprintf('pkt%02d',OtherPacketIDs(pp))),vars);
            PktVars = vars(WhichVars);
            PktData = load(NewFile,PktVars{:});
            save(OutFile,'-struct','PktData','-append','-v7.3');
        end
    end
    
    % collect parameterization data and save them to OutFile
    info = whos('-file',OutFile);
    vars = {info.name};
    if any(ismember(vars,'PacketIDs'))
        FileContents = load(OutFile,'PacketIDs','Parameters');
        FileContents.PacketIDs = sort([FileContents.PacketIDs(:)' UserRequestedPacket],'ascend');
    else
        FileContents.PacketIDs = UserRequestedPacket;
    end
    FileContents.Parameters(UserRequestedPacket).Time = cat(2,BinTimes{:});
    FileContents.Parameters(UserRequestedPacket).Bin = cat(2,BinIDs{:});
    FileContents.Parameters(UserRequestedPacket).ChannelIDs = UserRequestedChannels;
    FileContents.Parameters(UserRequestedPacket).DataPoints = UserRequestedPoints;
    FileContents.Parameters(UserRequestedPacket).FrequencyBand = FrequencyBand;
    FileContents.Parameters(UserRequestedPacket).MovingWindow = MovingWindow;
    FileContents.Parameters(UserRequestedPacket).SizeFFT = fftN;
    FileContents.Parameters(UserRequestedPacket).WinKernel = WinKernel;
    FileContents.Parameters(UserRequestedPacket).NSxFile = NSxFile;
    FileContents.Parameters(UserRequestedPacket).NSxObject = ns.toStruct;
    FileContents.Parameters(UserRequestedPacket).DownsampleFactor = DownsampleFactor;
    save(OutFile,'-struct','FileContents','-append','-v7.3');
    if FlagVerbose
        fprintf('Saved data to <a href="matlab:load(''%s'');">''%s''</a>\n',OutFile,OutFile);
    end
end

% assign outputs
if nargout>0
    varargout{1} = cat(1,BinData{:});
end
if nargout>1
    varargout{2} = cat(2,BinTimes{:});
end
if nargout>2
    varargout{3} = freq;
end