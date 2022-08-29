function [ts,featdef,windef] = timestamps(nv,varargin)
% TIMESTAMPS Get spike timestamps
%
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(NV)
%   Extract spike timestamps from the BLACKROCK.NEV objects in cell array
%   NV (one cell per electrode array) into output cell array TS (one cell
%   per PROCWIN, see below). The table FEATDEF defines the source electrode
%   array, channel, unit, etc. for each feature in TS. By default,
%   processes all available data from NV.
%
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(...,'PROCWIN',PROCWIN)
%   Specify one or more time ranges (with units of 'seconds') in which to
%   group data in PROCWIN, a Kx2 matrix where each row defines the start
%   and length of a grouping window.
%
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(...,'LAG',LAG)
%   Specify a lag LAG between the times in PROCWIN and the timestamps
%   associated with the neural data. The value will be *added* to the
%   times in PROCWIN (i.e., reading neural data recorded slightly after the
%   indicated PROCWIN times) and *subtracted* from the timestamp values (to
%   account for the imposed lag). The default value is 0 (zero).
%
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(NV,PROCWIN,LAG,DTCLASS)
%   Return data of class DTCLASS. Default is 'double' but may be any of the
%   numerical data classes (int16, single, double, etc.).
%
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   By default, returns list of timestamps for each time range in PROCWIN
%   as cell arrays, with each cell containing a cell array of timestamp for
%   each unique feature (channel/unit). This behavior is equivalent to
%   setting UNIFORMOUTPUT to FALSE. When set to TRUE, the data will be
%   converted to one-level-deep cell array, with one cell per PROCWIN, and
%   each cell containing a logical sparse matrix of dimensions TIME x
%   FEATURE (MATLAB does not yet support multidimensional sparse matrices).
%
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(...,'LOGFCN',LOGFN)
%   [TS,FEATDEF,WINDEF] = TIMESTAMPS(...,DBG)
%   Provide a means to log messages to the screen and other outputs. In the
%   first case, LOGFN is a two-cell cell array in which the first cell
%   contains the function handle and any arguments that precede the message
%   and priority; the second cell contains any arguments to be provided
%   after the message and priority. For example, to use a method 'log' of
%   an object 'obj' which does not require any additional arguments,
%   provide LOGFN as the following:
%
%     LOGFN = {{@obj.log},{}};
%
%   In the second case, provide an object of class DEBUG.DEBUGGER and the
%   necessary elements of LOGFN will be automatically inferred.
%
%   NOTE: Clock resets occur regularly at the beginning of recording files
%   (within the first three seconds of recording) in order to synchronize
%   multiple NSPs.  They may also occur later in recording files when
%   Central detects high system load or encounters an error. Take care to
%   provide only the timestamps corresponding to the recording block of
%   interest to avoid inflated bin counts due to overlapping timestamps.
%
%   See also PROC.FEATDEF.

% process neural data objects input
[nv,num_arrays,fs,blocks,max_time,min_time] = proc.helper.processNEVInputs(nv);

% get the log function
[varargin,logfcn] = proc.helper.getLogFcn(varargin);

% process the variable inputs
flagUniformOutput = false;
flagSparseOutput = false;
procwin_orig = arrayfun(@(x,y)[x y],min_time,max_time-min_time,'UniformOutput',false);
lag = arrayfun(@(x)0,1:num_arrays,'UniformOutput',false);
dtclass = 'double';
flagUnsorted = false;
flagNoise = false;

% process user input
[idx,flagUniformOutput,procwin,lag,dtclass] = ...
    proc.helper.processCommonInputs(flagUniformOutput,procwin_orig,lag,dtclass,num_arrays,varargin{:});
varargin(idx) = [];
if ~isequal(procwin,procwin_orig)
    blocks = nan; % user changed procwin, invalidating default packets
end
[idx,blocks,flagSparseOutput,flagUnsorted,flagNoise] = ...
    processLocalInputs(blocks,flagSparseOutput,flagUnsorted,flagNoise,varargin{:});
varargin(idx) = [];
assert(isempty(varargin),'Unexpected inputs');

% apply uniform output request to the processing windows
if flagUniformOutput
    procwin = proc.helper.uniformProcwin(procwin);
end

% get timestamps, channels, units for each procwin
[allts,allch,allun,procwin] = proc.blackrock.tcu(nv,'procwin',procwin,'lag',lag,'blocks',blocks,dtclass,'UniformOutput',false,'logfcn',logfcn);
num_wins = length(allts);
assert(num_wins==length(procwin),'Wrong number of procwins returned');
assert(~any(cellfun(@iscell,procwin)),'Procwin must be composed of matrices');

% subtract off procwin starts from the timestamps (make them relative)
allts = cellfun(@(x,y)x-fs*y(1),allts,procwin,'UniformOutput',false);

% create windef
windef = cell2table([...
    cellfun(@(x)x(1),procwin(:),'UniformOutput',false) ...
    cellfun(@(x)sum(x),procwin(:),'UniformOutput',false)],...
    'VariableNames',{'win_start','win_end'});

% construct list of features to include and sort by firing rate
args = {};
if flagUnsorted,args=[args {'unsorted'}];end
if flagNoise,args=[args {'noise'}];end
[num_features,featdef] = proc.helper.processNEVFeatdef(allts,allch,allun,'lag',lag,'frscale',fs,'UniformOutput',true,args{:});
assert(num_features>0,'No units to process');

% collect timestamps
ts = cell(1,num_wins);
for kk=1:num_wins
    proc.helper.log(logfcn,sprintf('Processing win %d/%d',kk,num_wins),'debug');
    ts{kk} = proc.basic.timestamps(allts{kk},allch{kk},allun{kk},featdef);
end

% create uniform output
if flagUniformOutput
    
    % find the shortest procwin segment
    mints = inf;
    for kk=1:length(ts)
        mints = min(mints,max(cellfun(@max,ts{kk})));
    end
    for kk=1:length(ts) % remove timestamps greater than minrelt
        ts{kk} = cellfun(@(x)x(x<=mints),ts{kk},'UniformOutput',false);
        windef.win_end(kk) = mints/fs;
    end
end

% create sparse representation
if flagSparseOutput
    
    % construct sparse matrices for each procwin
    for kk=1:num_wins
        num_timestamps = ceil(procwin{kk}(2)*fs);
        ts{kk} = proc.helper.ts2sparse(ts{kk},'numsamples',num_timestamps);
    end
end


function [idxAll,blocks,flagSparseOutput,flagUnsorted,flagNoise] = processLocalInputs(blocks,flagSparseOutput,flagUnsorted,flagNoise,varargin)
% collect all potential inputs

% keep track of varargin indices for the inputs
idxAll = false(size(varargin));

% allow user to specify recording blocks
idx = strncmpi(varargin,'blocks',5);
if any(idx)
    blocks = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

idx = strncmpi(varargin,'sparse',6);
if any(idx)
    flagSparseOutput = true;
    idxAll = idxAll|idx;
end

% check for unsorted/noise requests
idx = strncmpi(varargin,'unsorted',6);
if any(idx)
    flagUnsorted = true;
    idxAll = idxAll|idx;
end
idx = strncmpi(varargin,'noise',5);
if any(idx)
    flagNoise = true;
    idxAll = idxAll|idx;
end