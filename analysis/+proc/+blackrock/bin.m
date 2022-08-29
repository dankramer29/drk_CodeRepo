function [c,relt,featdef,windef] = bin(nv,varargin)
% BIN Collect binned spike counts
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(NV)
%   Generate MxN matrix C containing binned counts of spike timestamps
%   calculated in M bins of (default) width 0.05 sec (with *end time* of
%   each bin indicated in RELT), and for N features extracted from
%   BLACKROCK.NEV objects NV. The N-row table FEATDEF defines the source of
%   each feature. By default, processes all available data from the neural
%   data resources.
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'UNSORTED')
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'NOISE')
%   Process unsorted and/or noise units (default is to ignore both).
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'BINWIDTH',BINWIDTH)
%   Specify a binwidth BINWIDTH to use when generating binned spike counts.
%   Default value is 0.05.
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'PROCWIN',PROCWIN)
%   Specify one or more time ranges in which to group data in PROCWIN, a
%   Kx2 matrix where each row defines the start and length of a grouping
%   window.
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'LAG',LAG)
%   Specify a lag VAL between the times in PROCWIN and the timestamps
%   associated with the neural data. The value will be *added* to the
%   timestamps in PROCWIN. The default value is 0 (zero).
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'DOUBLE'|'SINGLE'|...)
%   Return data of a specific class. Default is 'double'.
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e., all channels/windows
%   the same size and concatenated into matrices, or to force cell array
%   output. If FALSE, C and RELT will be cell arrays. Otherwise, they
%   will be matrix and vector respectively.
%
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,'LOGFCN',LOGFN)
%   [C,RELT,FEATDEF,WINDEF] = BIN(...,DBG)
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
%   See also HISTCOUNTS, PROC.FEATDEF, PROC.BIN2FR, PROC.BINFR.

% process neural data objects input
[nv,num_arrays,fs,blocks,max_time] = proc.helper.processNEVInputs(nv);

% get the log function
[varargin,logfcn] = proc.helper.getLogFcn(varargin);

% process the variable inputs
flagUniformOutput = false;
procwin_orig = arrayfun(@(x)[0 x],max_time,'UniformOutput',false);
lag = arrayfun(@(x)0,1:num_arrays,'UniformOutput',false);
dtclass = 'double';
binwidth = 0.05;
flagUnsorted = false;
flagNoise = false;

% process user input
[idx,flagUniformOutput,procwin,lag,dtclass] = ...
    proc.helper.processCommonInputs(flagUniformOutput,procwin_orig,lag,dtclass,num_arrays,varargin{:});
varargin(idx) = [];
if ~isequal(procwin,procwin_orig)
    blocks = nan; % user changed procwin, invalidating default packets
end
[idx,blocks,binwidth,flagUnsorted,flagNoise] = ...
    processLocalInputs(blocks,binwidth,flagUnsorted,flagNoise,varargin{:});
varargin(idx) = [];
assert(isempty(varargin),'Unexpected inputs');

% get timestamps, channels, units for each procwin
[timestamps,channels,units,procwin] = proc.blackrock.tcu(nv,'procwin',procwin,'lag',lag,'blocks',blocks,dtclass,'UniformOutput',false,'logfcn',logfcn);
numWins = length(timestamps);
assert(numWins==length(procwin),'Wrong number of procwins returned');

% convert timestamps from samples to seconds
timestamps = cellfun(@(x)x/fs,timestamps,'UniformOutput',false);

% get feature definitions
args = {};
if flagUnsorted,args=[args {'unsorted'}];end
if flagNoise,args=[args {'noise'}];end
[numFeatures,featdef] = proc.helper.processNEVFeatdef(timestamps,channels,units,'lag',lag,'frscale',1,'UniformOutput',true,args{:});
assert(numFeatures>0,'No units to bin');

% loop over processing windows
c = cell(1,numWins);
relt = cell(1,numWins);
for kk=1:numWins
    proc.helper.log(logfcn,sprintf('Processing win %d/%d',kk,numWins),'debug');
    [c{kk},relt{kk}] = proc.basic.bincount(timestamps{kk},channels{kk},units{kk},binwidth,featdef);
end

% create windef
windef = cell2table(...
    [cellfun(@(x)x(1),procwin(:),'UniformOutput',false) ...
    cellfun(@(x)sum(x),procwin(:),'UniformOutput',false) ...
    cellfun(@(x)x(1),relt(:),'UniformOutput',false) ...
    cellfun(@(x)x(end),relt(:),'UniformOutput',false)],...
    'VariableNames',{'win_start','win_end','rel_start','rel_end'});

% pull out of cell array if just one processing window
if flagUniformOutput
    p = 10^(floor(log10(fs))+2);
    [c,tmprelt,idx] = proc.helper.createUniformOutput(c,relt,'precision',p);
    for kk=1:length(idx)
        tmp = relt{kk}(idx{kk});
        windef.win_start(kk) = windef.win_start(kk) + (tmp(1) - relt{kk}(1));
        windef.win_end(kk) = windef.win_end(kk) - (relt{kk}(end) - tmp(end));
    end
    relt = tmprelt;
end


function [idxAll,blocks,binwidth,flagUnsorted,flagNoise] = processLocalInputs(blocks,binwidth,flagUnsorted,flagNoise,varargin)
% collect all potential inputs

% keep track of varargin indices for the inputs
idxAll = false(size(varargin));

% allow user to specify recording blocks
idx = strncmpi(varargin,'blocks',5);
if any(idx)
    blocks = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% allow user to specify recording blocks
idx = strcmpi(varargin,'binwidth');
if any(idx)
    binwidth = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
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