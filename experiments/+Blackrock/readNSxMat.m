function data = readNSxMat(featfile,varargin)
% READNSXMAT read data saved by the NSX2MAT function
%
% DATA = readNSxMat(FILE)
% Read all features from the file specified by FILE.  FILE can be the
% original NSx file, in which case a corresponding BinnedFeature
% file must exist in the same directory, or it can be the BinnedFeature MAT
% file itself.  DATA is a 2-D matrix with dimensions of time and channels.
%
% DATA = readNSxMat(FILE,'[q]uiet')
% Turn off warnings.
%
% DATA = readNSxMat(FILE,'[pack]et')
% Specify the data packet from which the data will be read.
%
% DATA = readNSxMat(FILE,'[time]s',TIME)
% DATA = readNSxMat(FILE,'[time]s',TIME,'[hour]s')
% DATA = readNSxMat(FILE,'[time]s',TIME,'[min]utes')
% DATA = readNSxMat(FILE,'[time]s',TIME,'[sec]onds')
% DATA = readNSxMat(FILE,'[time]s',TIME,'[milli]seconds')
% Specify the start and end points of the data to be read out.  TIME can be
% a single value, interpreted as total amount of time to read starting from
% the beginning, or a two-element vector specifying start and stop.  By
% default values in TIME will be interpreted as seconds but can be
% interpreted with other units by adding a qualifier 'hours', 'minutes',
% 'seconds', or 'milliseconds'.
%
% DATA = readNSxMat(FILE,'[point]s',POINTS)
% Specify the amount of data to read in terms of data points (where each
% point includes one sample from each channel).  POINTS can be a single
% value, specifying total number of points to read starting from beginning,
% or [FIRST LAST] specifying the specific points to read.
%
% DATA = readNSxMat(FILE,'[map]file')
% Specify a map file to use for seamless transition between channels and
% electrodes.
%
% DATA = readNSxMat(FILE,'[ch]annels',CHANLIST)
% By default, all channels will be read.  Use this option to specify
% specific channels to read.
%
% DATA = readNSxMat(FILE,'[el]ectrodes',ELECLIST)
% By default, all channels will be read.  Use this option to specify
% specific electrodes to read.  **NOTE that in order to use electrode
% numbers, a map file must be provided as specified above for option
% '[map]file'.

% verbosity
FlagVerbose = true;
if any(strncmpi(varargin,'quiet',1))
    FlagVerbose = false;
end

% which data packet to read from
UserRequestedPacket = [];
if any(strncmpi(varargin,'packet',4))
    idx = find(strncmpi(varargin,'packet',4));
    UserRequestedPacket = varargin{idx+1};
end
if ~isempty(UserRequestedPacket) && length(UserRequestedPacket)>1
    error('Can only request data from one packet at a time');
end

% which data points to read
UserRequestedTimes = [];
UserRequestedDataPoints = [];
if any(strncmpi(varargin,'times',4))
    TimeFactor = 1; % will be in terms of final (downsampled) sampling rate
    if any(strncmpi(varargin,'hours',4))
        TimeFactor = 60*60;
    elseif any(strncmpi(varargin,'minutes',3))
        TimeFactor = 60;
    elseif any(strncmpi(varargin,'seconds',3))
        TimeFactor = 1;
    elseif any(strncmpi(varargin,'milliseconds',5))
        TimeFactor = 1/1000;
    end
    idx = find(strncmpi(varargin,'times',4));
    if length(varargin{idx+1})==1
        UserRequestedTimes = [0 varargin{idx+1}]; % indicate total time required
    else
        UserRequestedTimes = [varargin{idx+1}(1) varargin{idx+1}(end)]; % indicate start and stop
    end
    UserRequestedTimes = UserRequestedTimes*TimeFactor;
elseif any(strncmpi(varargin,'points',4))
    idx = find(strncmpi(varargin,'points',4));
    if length(varargin{idx+1})==1
        UserRequestedDataPoints = [1 varargin{idx+1}]; % indicate total number of points required
    else
        UserRequestedDataPoints = [varargin{idx+1}(1) varargin{idx+1}(end)]; % indicate start and stop
    end
end

% which channel to read
hArrayMap = [];
UserRequestedChannels = [];
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
end
if ~isempty(UserRequestedChannels)
    UserRequestedChannels = sort(unique(UserRequestedChannels),'ascend');
end

% look for feature file, or (eventually) create the feature file if it
% doesn't exist
[fdir,fbasename,fext] = fileparts(featfile);
if strcmpi(fext(2:3),'ns')
    featfile = fullfile(fdir,[fbasename '_' lower(fext(2:end)) '.mat']);
end
if exist(featfile,'file')~=2
    error('Feature file ''%s'' does not exist.',featfile);
    %Blackrock.NSx2Mat(featfile,
end

% check file contents
info = whos('-file',featfile);
vars = {info.name};
if ~any(ismember(vars,'PacketIDs')) || ~any(ismember(vars,'Parameters'))
    error('Invalid feature file ''%s''',featfile);
end
fl = load(featfile,'Parameters');
Parameters = fl.Parameters;
clear fl;

% calculate parameters, set defaults if left empty by user
NumPackets = length(Parameters);
NumPointsPerPacket = zeros(1,NumPackets);
for pp = 1:NumPackets
    NumPointsPerPacket(pp) = length(Parameters(pp).Bin);
end
if isempty(UserRequestedPacket)
    [~,UserRequestedPacket] = max(NumPointsPerPacket);
end
if isempty(UserRequestedChannels)
    UserRequestedChannels = Parameters(UserRequestedPacket).ChannelIDs;
end
DownsampledFs = Parameters(UserRequestedPacket).NSxObject.Fs / Parameters(UserRequestedPacket).DownsampleFactor;
if isempty(UserRequestedDataPoints)
    if ~isempty(UserRequestedTimes)
        st = round(UserRequestedTimes(1)*DownsampledFs) + 1;
        lt = st + round(diff(UserRequestedTimes)*DownsampledFs) - 1;
        UserRequestedDataPoints = [st lt];
    else
        UserRequestedDataPoints = Parameters(UserRequestedPacket).DataPoints([1 end]);
    end
end
UserRequestedDataPoints = UserRequestedDataPoints - Parameters(UserRequestedPacket).DataPoints(1) + 1; % shift to [1,N] for easier indexing
if UserRequestedDataPoints(1) < 1 || UserRequestedDataPoints(2) > (diff(Parameters(UserRequestedPacket).DataPoints)+1)
    error('Invalid data range: requested [%d %d], available [%d %d]',UserRequestedDataPoints,Parameters(UserRequestedPacket).DataPoints);
end

% pull out the data
bins = Parameters(UserRequestedPacket).Bin([UserRequestedDataPoints(1) UserRequestedDataPoints(2)]);

% pre-calculate indices from first bin
binVarName = sprintf('pkt%02d_bin%04d',UserRequestedPacket,bins(1));
bd = load(featfile,binVarName);
bin = bd.(binVarName);
bin_points = find(Parameters(UserRequestedPacket).Bin==bins(1));
pts_idx = bin_points>=UserRequestedDataPoints(1) & bin_points<=UserRequestedDataPoints(2);
chan_idx = ismember( Parameters(UserRequestedPacket).ChannelIDs,UserRequestedChannels );
tmpdata = double( bin.data( pts_idx, chan_idx ) );

% check that all requested data will fit in memory
ElementsPerPoint = nnz(chan_idx);
NumPoints = diff(UserRequestedDataPoints)+1;
util.memcheck( NumPoints*ElementsPerPoint,'double',...
    'TotalUtilization',0.98,...
    'AvailableUtilization',0.98,...
    'assert','quiet');

% pre-allocate data and fill up first segment
data = zeros(NumPoints,ElementsPerPoint);
data( 1 : nnz(pts_idx), : ) = tmpdata;
dataIdx = nnz(pts_idx);
clear bd bin tmpdata;

% loop over remaining bins
for bb = (bins(1)+1) : bins(2)
    
    % load bin data
    binVarName = sprintf('pkt%02d_bin%04d',UserRequestedPacket,bb);
    bd = load(featfile,binVarName);
    bin = bd.(binVarName);
    clear bd;
    
    % calculate indices for this bin
    bin_points = find(Parameters(UserRequestedPacket).Bin==bb);
    pts_idx = bin_points>=UserRequestedDataPoints(1) & bin_points<=UserRequestedDataPoints(2);
    chan_idx = ismember( Parameters(UserRequestedPacket).ChannelIDs,UserRequestedChannels );
    if nnz(pts_idx)==0 || nnz(chan_idx)==0
        keyboard
    end
    
    % get data points
    data( dataIdx + (1:nnz(pts_idx)), : ) = double( bin.data( pts_idx,chan_idx ) );
    dataIdx = dataIdx + nnz(pts_idx);
end
