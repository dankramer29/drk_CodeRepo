function [timestamps,channels,units,procwin] = tcu(nv,varargin)
% TCU Get timestamps, channels, and units from neural data resources
%
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(NV)
%   Get the timestamps, channels, and units associated with a set of
%   BLACKROCK.NEV objects in the cell array NV, and apply an offset of LAG
%   seconds to the timestamps. By default, all data from the entire file
%   will be read into a single cell array (but see PROCWIN input below).
%   For each PROCWIN, values read from the different BLACKROCK.NEV
%   resources will be concatenated, sorted by the timestamps, with the
%   channel number offset by (NSP-1)*CHANS_PER_NSP to avoid conflict.
%
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(...,'PROCWIN',PROCWIN
%   Specify one or more time ranges in which to group data in PROCWIN, a
%   Kx2 matrix where each row defines the start and length of a grouping
%   window.
%
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(...,'DOUBLE'|'SINGLE'|...)
%   Return data of a specific class. The default is DOUBLE.
%
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(...,'BLOCKS',BLOCKIDX)
%   Get the spike data from the specified recording blocks. By default, no
%   blocks are specified when calling the BLACKROCK.NEV/READ method, so its
%   default options will be in place (generally, that means reading from
%   the largest available recording block). If multiple blocks are
%   specified, the outputs will be cell arrays with one cell per recording
%   block. If only one block is specified, the outputs will be vectors as
%   described above.
%
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Force either uniform output (in which timestamps, channels, and units
%   will be matrices) or nonuniform output (in which the outputs will be
%   cell arrays of matrices). By default, the outputs are uniform when data
%   are read from single recording blocks, and nonuniform when data are
%   read from multiple recording blocks. If nonuniform output is specified for a
%   single recording block, the output vectors will be enclosed in single
%   cells. If uniform output is specified for multiple recording blocks,
%   the data will be concatenated together with no indication of the
%   recording block boundaries (apart from the timestamps being reset).
%
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(...,'LOGFCN',LOGFN)
%   [TIMESTAMPS,CHANNELS,UNITS] = TCU(...,DBG)
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

% constant since for us it never changes
CHANNELS_PER_NSP = 96;

% process neural data objects input
[nv,num_arrays,fs,blocks,max_time,min_time] = proc.helper.processNEVInputs(nv);

% get the log function
[varargin,logfcn] = proc.helper.getLogFcn(varargin);

% default values
flagUniformOutput = false;
procwin_orig = arrayfun(@(x,y)[x y],min_time,max_time-min_time,'UniformOutput',false);
lag = arrayfun(@(x)0,1:num_arrays,'UniformOutput',false);
dtclass = 'double';

% process user input
[idx,flagUniformOutput,procwin,lag,dtclass] = ...
    proc.helper.processCommonInputs(flagUniformOutput,procwin_orig,lag,dtclass,num_arrays,varargin{:});
varargin(idx) = [];
if ~isequal(procwin,procwin_orig)
    blocks = nan; % user changed procwin, invalidating default packets
end
[idx,blocks] = processLocalInputs(blocks,varargin{:});
varargin(idx) = [];
assert(isempty(varargin),'Unknown inputs');

% apply the lag
msg = sprintf('Will apply sync offsets of [%s] seconds to the procwin start times for arrays %s',strjoin(cellfun(@(x)sprintf('%.3f',x),lag,'UniformOutput',false),', '),util.vec2str(1:num_arrays));
proc.helper.log(logfcn,msg,'info');
procwin = cellfun(@(x,y)[x(:,1)+y x(:,2)],procwin(:),lag(:),'UniformOutput',false);

% identify recording packets associated with trial timing
num_wins = unique(cellfun(@(x)size(x,1),procwin(:)));
[blocks,tm,idx_ok] = proc.helper.processBlocksNV(nv,procwin,blocks,num_arrays,num_wins,logfcn);

% read spike data
timestamps = cell(1,num_arrays);
channels = cell(1,num_arrays);
units = cell(1,num_arrays);
for nn=1:num_arrays
    
    % read spike timestamps for all requested procwins
    prev = nv{nn}.setVerbosity(Debug.PriorityLevel.ERROR);
    spk = nv{nn}.read('time',tm{nn},'blocks',blocks{nn},'UniformOutput',false,dtclass);
    nv{nn}.setVerbosity(prev);
    
    % read in priority order: sorted, nev
    idx_bad = setdiff(1:num_wins,idx_ok{nn});
    timestamps{nn} = cell(1,num_wins);
    timestamps{nn}(idx_ok{nn}) = cellfun(@(x)x.Timestamps-round(lag{nn}*fs)+1,spk(:),'UniformOutput',false); % re-reference timestamps based on lag settings (timestamp LAG becomes timestamp 1)
    timestamps{nn}(idx_bad) = arrayfun(@(x)[],idx_bad(:),'UniformOutput',false);
    channels{nn} = cell(1,num_wins);
    channels{nn}(idx_ok{nn}) = cellfun(@(x)x.Channels,spk(:),'UniformOutput',false);
    channels{nn}(idx_bad) = arrayfun(@(x)[],idx_bad(:),'UniformOutput',false);
    units{nn} = cell(1,num_wins);
    units{nn}(idx_ok{nn}) = cellfun(@(x)x.Units,spk(:),'UniformOutput',false);
    units{nn}(idx_bad) = arrayfun(@(x)[],idx_bad(:),'UniformOutput',false);
    
    % make sure no clock resets in timestamps
    dt = cellfun(@diff,timestamps{nn},'UniformOutput',false);
    assert(~any(cellfun(@(x)any(x<0),dt(:))),'Timestamps must be non-decreasing');
end

% we want the cell arrays to indicate procwins, and to merge
% timestamps/channels/units between the two arrays
% first step is to swap the hierarchy of the cell array from {array}{block}
% to {block}{array}
timestamps = util.invertcell(timestamps);
channels = util.invertcell(channels);
units = util.invertcell(units);

% offset channel numbers by (nsp-1)*chans_per_nsp to avoid conflict
dch_offset = arrayfun(@(x)(x-1)*CHANNELS_PER_NSP,1:num_arrays,'UniformOutput',false);
channels = cellfun(@(x)cellfun(@(y,z)y+z,x,dch_offset,'UniformOutput',false),channels,'UniformOutput',false);

% combine the data from the two arrays and sort based on timestamp
timestamps = cellfun(@(x)cat(1,x{:}),timestamps,'UniformOutput',false);
channels = cellfun(@(x)cat(1,x{:}),channels,'UniformOutput',false);
units = cellfun(@(x)cat(1,x{:}),units,'UniformOutput',false);
[timestamps,idx] = cellfun(@(x)sort(x,'ascend'),timestamps,'UniformOutput',false);
channels = cellfun(@(x,y)x(y),channels,idx,'UniformOutput',false);
units = cellfun(@(x,y)x(y),units,idx,'UniformOutput',false);

% subtract the lag back out of tm (already accounted for in timestamps)
tm = cellfun(@(x,y)cellfun(@(z)z-y,x,'UniformOutput',false),tm(:),lag(:),'UniformOutput',false);

% change tm from {array}{win} to {win}(array,:)
tm = util.invertcell(tm);
tm = cellfun(@(x)cat(1,x{:}),tm,'UniformOutput',false);

% reconstruct procwin to reflect the combined data
procwin = arrayfun(@(x)[nan nan],1:num_wins,'UniformOutput',false);
for kk=1:num_wins
    if ismember(kk,idx_ok{nn})
        procwin{kk} = [min(tm{kk}(:,1)) max(tm{kk}(:,2))]; % start,end
        procwin{kk} = [procwin{kk}(1) diff(procwin{kk})]; % start,length
    else
        procwin{kk} = [];
    end
end

% convert to uniform output if requested
if flagUniformOutput
    timestamps = cat(1,timestamps{:});
    channels = cat(1,channels{:});
    units = cat(1,units{:});
end


function [idxAll,blocks] = processLocalInputs(blocks,varargin)
% collect all potential inputs

% keep track of varargin indices for the inputs
idxAll = false(size(varargin));

% allow user to specify recording blocks
idx = strncmpi(varargin,'blocks',2);
if any(idx)
    blocks = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
