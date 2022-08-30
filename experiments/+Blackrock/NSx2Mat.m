function NSx2Mat(NSxFile,varargin)
% NSX2MAT generate a MAT file with raw or downsampled neural data
%
% All input option strings are case-insensitive.
%
% This function saves data out into a custom format in MAT files.  Use the
% READNSXMAT function to read the data back.
%
% NSx2Mat(FILE)
% Use all default settings to generate MAT files from the NSx file
% specified in FILE.
% 
% NSx2Mat(FILE,'[Q]uiet')
% Turn off warnings
%
% NSx2Mat(FILE,'NoCopy')
% If re-generating data for a particular data packet, and therefore
% forcing a previously-generated file to be renamed, this option specifies
% that data from other packets in the renamed file will NOT be copied over
% to the new file.  See Blackrock.NSx help for information on data packets
% for NSx files.
%
% NSx2Mat(FILE,'SaveAsDouble')
% Only valid if output will be saved to file.  Normally, the data are saved
% in single floating-point format (32-bit instead of double 64-bit) to save
% on space.  This option specifies that the data should be saved in double
% 64-bit floating point format.
%
% NSx2Mat(FILE,'[OutputDir]ectory',OUTPUTDIR)
% By default, if data will be saved to disk, it will be saved to the
% current MATLAB working directory.  This option allows the user to specify
% a different saving directory.  If OUTPUTDIR does not exist, the script
% will attempt to create it, and will generate an error if it cannot.
%
% NSx2Mat(FILE,'Raw')
% By default, the data will be downsampled if necessary to get to a
% sampling rate of 2000 samples/sec.  Use this option to specify that the
% data should be left at its original sampling rate for processing.
%
% NSx2Mat(FILE,'[Down]sampleFactor',VALUE)
% By default, the data will be downsampled if necessary to get to a
% sampling rate of 2000 samples/sec.  Use this option to specify a
% downsampling factor other than the default one that would produce 2000
% samples/sec.  VALUE must be integer.
%
% NSx2Mat(FILE,'[FilterObj]ect',OBJ)
% By default, an elliptical will be designed with passband ripple 0.1 dB,
% stopband attenuation of 30 dB, and frequency characteristics to satisfy
% the Nyquist criterion.  Use this option to supply a custom filter in the
% form of a filter object, which must have fields SOSMatrix and
% ScaleValues, which will be present if the object is generated using the
% fdesign.lowpass and design methods in MATLAB.
%
% NSx2Mat(FILE,'[FilterCoeff]icients',{b,a})
% By default, an elliptical will be designed with passband ripple 0.1 dB,
% stopband attenuation of 30 dB, and frequency characteristics to satisfy
% the Nyquist criterion.  Use this option to supply a custom filter in the
% form of a transfer function.  Provide the filter function as a cell array
% where the first element of the cell array is the vector 'b' (the
% denominator of the transfer function) and the second element is the
% vector 'a' (the numerator of the transfer function).
%
% NSx2Mat(FILE,'[pack]et',VALUE)
% By default, data will be read from the largest data packet in the NSx
% file.  Use this option to specify the packet from which data should be
% read.
%
% NSx2Mat(FILE,'[point]s',NUM_POINTS)
% NSx2Mat(FILE,'[point]s',[FIRST LAST])
% By default, all data will be read from the requested data packet.  Use
% this option to specify the amount of data that will be read in the form 
% of samples.  Provide the number of points NUM_POINTS starting from the
% beginning, or the FIRST and LAST points.
%
% NSx2Mat(FILE,'[time]s',TIME)
% NSx2Mat(FILE,'[time]s',TIME,'[hour]s')
% NSx2Mat(FILE,'[time]s',TIME,'[min]utes')
% NSx2Mat(FILE,'[time]s',TIME,'[sec]onds')
% NSx2Mat(FILE,'[time]s',TIME,'[milli]seconds')
% By default, all data will be read from the requested data packet.  Use
% this option to specify the amount of data that will be read in the form
% of time.  TIME can be a single element, in which case it will be
% interpreted as the total amount of time starting at the beginning, or it
% can be a two-element vector specifying the starting and ending time.
% By default, values in TIME will be interpreted as number of seconds, but
% by providing a qualifier the values can also be interpreted as numbers of
% hours, minutes, seconds, or milliseconds.
%
% NSx2Mat(FILE,'[map]file],MAPFILE)
% Specify a map file which allows seamless translation between channels and
% electrodes.
%
% NSx2Mat(FILE,'[ch]annels',CHANLIST)
% By default, data will be read for all channels in the NSx file.  Use this
% option to specify a list of specific channels from which to read and
% process data.
%
% NSx2Mat(FILE,'[el]ectrodes',ELECLIST)
% By default, data will be read for all channels in the NSx file.  Use this
% option to specify a list of specific electrodes from which to read and
% process data.  **NOTE that NSx files store data in terms of channel
% numbers, not electrode numbers, and that in order to use electrode
% numbers you must also provide a map file as specified above.
%
% NSx2Mat(FILE,'[MaxBinP]oints')
% By default, the processed, binned features will be split into chunks, or
% bins, of 256MB.  These bins all get saved into the same MAT file, but
% they can be read out individually. This option indicates how many points 
% (where each point includes a sample from each channel) of the downsampled
% data will be included in each bin.  By default MaxBinPoints = 
% MaxBinWindows * PointsPerWindow.  Specifying MaxBinPoints directly means
% that MaxBinWindows will not be used for anything.

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

% copy data from other packets to new file when renaming
FlagCopyOnRename = true;
if any(strncmpi(varargin,'NoCopy',6))
    FlagCopyOnRename = false;
end

% save as double (64-bit) or single (32-bit)
FlagSaveAsSingle = true;
if any(strncmpi(varargin,'SaveAsDouble',12))
    FlagSaveAsSingle = false;
else
    if FlagVerbose
        warning('Default to save data to disk in single (32-bit) floating point format');
    end
end

% set output directory
OutputDirectory = fileparts(NSxFile); % default same location as NSx file
if any(strncmpi(varargin,'OutputDirectory',3))
    idx = find(strncmpi(varargin,'OutputDirectory',3));
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
OutFile = fullfile(OutputDirectory,[nsxBasename '_' nsxExt(2:end) '.mat']);

% setup for downsampling the data
DownsampleFactor = RawFs/2e3;
if DownsampleFactor>1
    FlagDownsample = true;
else
    FlagDownsample = false;
end
if any(strncmpi(varargin,'raw',3))
    FlagDownsample = false;
end
if FlagDownsample || any(strncmpi(varargin,'DownsampleFactor',4))
    FlagDownsample = true;
    zi = []; % filter initial conditions
    if any(strncmpi(varargin,'DownsampleFactor',4))
        idx = find(strncmpi(varargin,'DownsampleFactor',4));
        DownsampleFactor = varargin{idx+1};
    else
        if (DownsampleFactor - floor(DownsampleFactor)) ~= 0
            error('Only integer values are currently supported for downsampling (requested was %.2f)',DownsampleFactor);
        end
        if FlagVerbose
            warning('Default downsample to %d Hz (raw data at %d Hz, downsample factor %d)',RawFs/DownsampleFactor,RawFs,DownsampleFactor);
        end
    end
    if any(strncmpi(varargin,'FilterObject',4))
        idx = find(strncmpi(varargin,'FilterObject',6));
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
if any(strncmpi(varargin,'packets',4))
    idx = find(strncmpi(varargin,'packets',4));
    UserRequestedPackets = varargin{idx+1};
else
    UserRequestedPackets = 1:length(ns.PointsPerDataPacket);
    if FlagVerbose
        warning('Default to all data packets');
    end
end

% which data points to read
if any(strncmpi(varargin,'points',4))
    idx = find(strncmpi(varargin,'points',4));
    PointsInput = varargin{idx+1};
    if ~iscell(PointsInput)
        PointsInput = {PointsInput};
    end
    UserRequestedPoints = cell(1,length(PointsInput));
    for pp = 1:length(PointsInput)
        if length(PointsInput{pp})==1
            UserRequestedPoints{pp} = [1 PointsInput{pp}]; % indicate total number of points required
        else
            UserRequestedPoints{pp} = [PointsInput{pp}(1) PointsInput{pp}(end)]; % indicate start and stop
        end
    end
elseif any(strncmpi(varargin,'times',4))
    idx = find(strncmpi(varargin,'times',4));
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
    TimeInput = varargin{idx+1};
    if ~iscell(TimeInput)
        TimeInput = {TimeInput};
    end
    UserRequestedPoints = cell(1,length(TimeInput));
    for tt = 1:length(TimeInput)
        if length(TimeInput)==1
            UserRequestedPoints{tt} = [1 round(TimeInput{tt}*TimeFactor)]; % indicate total time required
        else
            UserRequestedPoints{tt} = [round(TimeInput{tt}(1)*TimeFactor)+1 round(diff(TimeInput{tt})*TimeFactor)]; % indicate start and stop
        end
    end
else
    UserRequestedPoints = cell(1,length(UserRequestedPackets));
    for pp=1:length(UserRequestedPackets)
        UserRequestedPoints{pp} = [1 ns.PointsPerDataPacket(UserRequestedPackets(pp))]; % default all available in packet
    end
    if FlagVerbose
        warning('Default to all data points in each requested packet');
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

% max bin size (256MB as double-format data in memory)
MaxPointsPerBin = floor( (256*1024^2/8) / length(UserRequestedChannels) );
if any(strncmpi(varargin,'MaxBinPoints',7))
    idx = find(strncmpi(varargin,'MaxBinPoints',7));
    MaxPointsPerBin = varargin{idx+1};
end

% calculate number of points being requested for each packet
NumPointsRequested = zeros(1,length(UserRequestedPackets));
for pp = 1:length(UserRequestedPackets)
    NumPointsRequested(pp) = diff(UserRequestedPoints{pp})+1;
    NumPointsRequested(pp) = floor(NumPointsRequested(pp)/DownsampleFactor)*DownsampleFactor;
    UserRequestedPoints{pp} = [UserRequestedPoints{pp}(1) UserRequestedPoints{pp}(1)+NumPointsRequested(pp)-1];
end
NumChannels = length(UserRequestedChannels);

% loop over cells of data
DataClass = 'double';
for pp = 1:length(UserRequestedPackets)
    NumPointsReadRaw = 0;
    LoopTimesRaw = nan(1,1e3);
    BinIDs = cell(1,1e3);
    BinIdx = 1;
    FlagRename = false; % default so variable exists when OutFile doesn't
    while NumPointsReadRaw < NumPointsRequested(pp)
        rawTic = tic;
        
        % calculate how much downsampled data will fit in memory, and how much
        % raw data can fit at once
        [~,NumPointsToReadDownsampled] = util.memcheck(NumChannels,DataClass,...
            'TotalUtilization',0.98,...
            'AvailableUtilization',(1/2));
        NumPointsToReadDownsampled = min(NumPointsToReadDownsampled,floor((NumPointsRequested(pp)-NumPointsReadRaw)/DownsampleFactor));
        NumPointsToReadDownsampled = min(NumPointsToReadDownsampled,MaxPointsPerBin);
        NumPointsReadDownsampled = 0;
        
        % read raw data in increments to build up to downsampled amount
        DownsampleBinnedData = cell(1,1e3);
        DownsampleBinIdx = 1;
        while NumPointsReadDownsampled < NumPointsToReadDownsampled
            
            % calculate how many raw-data-sized windows we can read
            [~,NumPointsToReadRaw] = util.memcheck(NumChannels,DataClass,...
                'Multiple',DownsampleFactor,...
                'TotalUtilization',0.99,...
                'AvailableUtilization',0.475);
            NumPointsToReadRaw = min(NumPointsToReadRaw,DownsampleFactor*(NumPointsToReadDownsampled-NumPointsReadDownsampled));
            
            % if we needed to read something but can't, generate an error
            if DownsampleBinIdx==1 && NumPointsToReadRaw==0
                error('Out of memory!');
            end
            
            % read raw data
            Points = UserRequestedPoints{pp}(1) + NumPointsReadRaw + [0 NumPointsToReadRaw-1];
            data = ns.read(...
                'channels',UserRequestedChannels,...
                'points',Points,...
                'packet',UserRequestedPackets(pp),...
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
        
        % collect times and bin associations
        BinIDs{BinIdx} = repmat(BinIdx,1,size(data,1));
        
        % convert to single
        if FlagSaveAsSingle
            data = cast(data,'single');
        end
        
        % create variables to save out to disk
        eval(sprintf('pkt%02d_bin%04d.data = data;',UserRequestedPackets(pp),BinIdx));
        
        % save to disk
        if BinIdx==1
            if exist(OutFile,'file')==2
                % Rename if PacketIDs contains UserRequestedPacket
                FlagRename = false;
                info = whos('-file',OutFile);
                vars = {info.name};
                if any(ismember(vars,'PacketIDs'))
                    fileContents = load(OutFile,'PacketIDs');
                    if any(ismember(fileContents.PacketIDs,UserRequestedPackets(pp)))
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
                    save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPackets(pp),BinIdx),'-v7.3');
                else
                    % PacketIDs didn't contain UserRequestedPacket
                    save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPackets(pp),BinIdx),'-append','-v7.3');
                end
            else
                % file doesn't exist yet, just save it
                save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPackets(pp),BinIdx),'-v7.3');
            end
        else
            % assume details figured out when BinIdx==1
            save(OutFile,sprintf('pkt%02d_bin%04d',UserRequestedPackets(pp),BinIdx),'-append','-v7.3');
        end
        
        % clear the created variables
        clear(sprintf('pkt%02d_bin%04d',UserRequestedPackets(pp),BinIdx));
        
        % estimate time elapsed/remaining/total
        PointsReadThisIteration = (NumPointsToReadDownsampled*DownsampleFactor);
        PercentDoneRaw = 100*NumPointsReadRaw/NumPointsRequested(pp);
        LoopTimesRaw(BinIdx) = toc(rawTic);
        estTimeElapsedRaw = sum(LoopTimesRaw(~isnan(LoopTimesRaw)));
        estTimeLeftRaw = (100/PercentDoneRaw)*estTimeElapsedRaw - estTimeElapsedRaw;
        if FlagVerbose
            fprintf('(Pkt %d/%d) Processed %d points (%.1f%% done) %s elapsed (%s remaining)\n',pp,length(UserRequestedPackets),PointsReadThisIteration,PercentDoneRaw,util.hms(estTimeElapsedRaw),util.hms(estTimeLeftRaw));
        end
        
        % update bin idx
        BinIdx = BinIdx + 1;
    end
    
    % copy over other PacketID data from renamed files
    if FlagRename && FlagCopyOnRename
        info = whos('-file',NewFile);
        vars = {info.name};
        FileContents = load(NewFile,'PacketIDs');
        OtherPacketIDs = setdiff(FileContents.PacketIDs,UserRequestedPackets(pp));
        for oo = 1:length(OtherPacketIDs)
            if FlagVerbose
                warning('Copying packet %d data into new file',OtherPacketIDs(oo));
            end
            WhichVars = cellfun(@(x)strcmpi(x(1:5),sprintf('pkt%02d',OtherPacketIDs(oo))),vars);
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
        FileContents.PacketIDs = sort([FileContents.PacketIDs(:)' UserRequestedPackets(pp)],'ascend');
    else
        FileContents.PacketIDs = UserRequestedPackets(pp);
    end
    FileContents.Parameters(UserRequestedPackets(pp)).Bin = cat(2,BinIDs{:});
    FileContents.Parameters(UserRequestedPackets(pp)).ChannelIDs = UserRequestedChannels;
    FileContents.Parameters(UserRequestedPackets(pp)).DataPoints = UserRequestedPoints{pp};
    FileContents.Parameters(UserRequestedPackets(pp)).NSxFile = NSxFile;
    FileContents.Parameters(UserRequestedPackets(pp)).NSxObject = ns.toStruct;
    FileContents.Parameters(UserRequestedPackets(pp)).DownsampleFactor = DownsampleFactor;
    save(OutFile,'-struct','FileContents','-append','-v7.3');
    if FlagVerbose
        fprintf('(Pkt %d/%d) Saved data to <a href="matlab:load(''%s'');">''%s''</a>\n',UserRequestedPackets(pp),length(UserRequestedPackets),OutFile,OutFile);
    end
end