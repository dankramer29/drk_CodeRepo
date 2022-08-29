function [v,relt,featdef] = broadband(blc,varargin)
% BROADBAND Collect raw field potentials
%
%   [V,RELT,FEATDEF] = BROADBAND(NS)
%   Generate MxN matrix V containing raw time series data calculated at M
%   time indices (with timing of each index indicated in RELT), and for N
%   unique combinations of NSP and channel (listed in N-row table FEATDEF).
%   By default, processes all available data from the neural data
%   resources. Requires cell array NS containing Blackrock.NSx objects.
%
%   [...] = BROADBAND(...,'PROCWIN',VAL)
%   Specify one or more time ranges in which to group data in VAL, a Kx2
%   matrix where each row defines the *start* and *length* of a grouping
%   window. V and RELT will be K-element cell arrays, with each cell of V
%   of size MxN, and RELT Mx1.
%
%   [...] = BROADBAND(...,'CHANNELS',CH)
%   Specify a list of channels to read. For multiple input Blackrock.NSx
%   objects, provide a cell array of channel lists (one per NSx object). By
%   default, will read channels 1:96 from each NSx object.
%
%   [...] = BROADBAND(...,'LAG',VAL)
%   Specify a lag VAL between the times in PROCWIN and the timestamps
%   associated with the neural data. The lag VAL will be *added* to the
%   values in PROCWIN. The default value is 0 (zero).
%
%   [...] = BROADBAND(...,'DOUBLE'|'SINGLE'|...)
%   Return data of a specific class. The default is DOUBLE.
%
%   [...] = BROADBAND(...,'[PACK]ETS',VAL)
%   Specify the recording packets from which to read the data specified in
%   PROCWIN. If VAL is scalar, it will be applied to all requested data
%   windows in PROCWIN. If there is one element of VAL per data window in
%   PROCWIN, the values will be applied to both arrays. If there is one
%   element of VAL per array, the values will be applied to each window for
%   the respective array. Otherwise, there must be one element of VAL per
%   array/window.
%
%   [...] = BROADBAND(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e., all channels/windows
%   the same size and concatenated into matrices, or to force cell array
%   output. If FALSE, V and RELT will be cell arrays. Otherwise, they will
%   be matrix and vector respectively.
%
%   [...] = BROADBAND(...,DBG)
%   Provide a means to log messages to the screen and other outputs.
%
%   [...] = BROADBAND(...,'UNIT', 'NORMALIZED'|'MICROVOLTS'|'MILLIVOLTS'|'VOLTS')
%   Return the raw broadband data with the units specified in UNITS: 'NORMALIZED',
%   'MICROVOLTS', 'MILLIVOLTS', or 'VOLTS'. The default is 'MICROVOLTS'.
%
%   In the second case, provide an object of class DEBUG.DEBUGGER and the
%   necessary elements of LOGFN will be automatically inferred.
%
%   See also BLACKROCK.NSX.

% pre-process info from BLc.Reader objects
blc = util.ascell(blc);
[num_nsps,num_physical_channels,fs,idx_largest_section] = proc.helper.processBLcInputs(blc);

% process inputs
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
[varargin,procwin] = util.argkeyval('procwin',varargin,[]);
[varargin,channels] = util.argkeyval('channels',varargin,arrayfun(@(x)1:x,num_physical_channels,'UniformOutput',false));
assert(length(channels)==num_nsps,'Must provide one channel list per array');
[varargin,dtclass] = util.argkeyword({'double','single','int16'},varargin,'double');
[varargin,units] = util.argkeyword({'microvolts','normalized'},varargin,'microvolts');
[varargin,flag_uniform_output] = util.argkeyval('uniformoutput',varargin,true);
[varargin,lag] = util.argkeyval('lag',varargin,0);
if ~found_debug,debug=Debug.Debugger('proc_blc_broadband');end
util.argempty(varargin);

% construct feature definitions table
featdef = proc.helper.processBLcFeatdef(num_physical_channels,lag);

% apply the lag
debug.log(sprintf('Lag set to [%s] seconds',strjoin(cellfun(@(x)sprintf('%.3f',x),lag,'UniformOutput',false),', ')),'info');
procwin = cellfun(@(x,y)[x(:,1)+y x(:,2)],procwin(:),lag(:),'UniformOutput',false);

% identify recording packets associated with trial timing
num_wins = unique(cellfun(@(x)size(x,1),procwin));

% read broadband data
v = cell(1,num_nsps);
relt = cell(1,num_nsps);
for nn=1:num_nsps
    
    % read broadband data for all requested procwins
    try
        dt = cell(1,num_wins);
        for kk=1:num_wins
            
            [varargin,user_requested_context] = util.argkeyval('context',varargin,'file',7);
            [varargin,user_requested_section] = util.argkeyval('section',varargin,nan);
            [varargin,reqpoints] = util.argkeyval('points',varargin,nan,5);
            [varargin,reqtime] = util.argkeyval('times',varargin,nan,4);
            [varargin,datestr_format] = util.argkeyval('datestrformat',varargin,nan,8);
            
            dt{kk} = blc{nn}.read('times',procwin{kk},'channels',channels{nn},'class',dtclass,'units',units,'UniformOutput',flag_uniform_output)';
        end
    catch ME
        blc{nn}.setVerbosity(prev);
        rethrow(ME);
    end
    
    % place in correct procwin indices
    v{nn} = cell(1,num_wins);
    v{nn}(idx_ok{nn}) = dt;
    clear dt; % save memory
    relt{nn}(idx_ok{nn}) = arrayfun(@(x)cast((0:x-1)'/fs,dtclass),num_samples_in_output{nn},'UniformOutput',false);
    idx_bad = setdiff(1:num_wins,idx_ok{nn});
    relt{nn}(idx_bad) = arrayfun(@(x)[],idx_bad,'UniformOutput',false);
end

% concatenate the arrays within each procwin
v = util.invertcell(v);
relt = util.invertcell(relt);

% loop over cells of v
for kk=1:num_wins
    
    % first, need to account for the possibility that one or more
    % cells might be empty. fill up with nans matching the timing
    % of one of the full cells, with the appropriate number of
    % channels
    idx_full = ~cellfun(@isempty,relt{kk});
    assert(any(idx_full),'Logical problem - there should be at least one nonempty cell');
    idx_empty = find(~idx_full);
    for nn=1:length(idx_empty)
        v{kk}{idx_empty(nn)} = nan(size(v{kk}{idx_full(1)},1),num_physical_channels(idx_empty(nn)),dtclass);
        relt{kk}{idx_empty(nn)} = relt{kk}{idx_full(1)};
    end
    assert(~any(cellfun(@isempty,relt{kk})),'There can be no empty cells');
    
    % concatenate the data, pull out unified timing
    v{kk} = cat(2,v{kk}{:});
    relt{kk} = relt{kk}{1};
end
nchan = unique(cellfun(@(x)size(x,2),v));
assert(length(nchan)==1,'Problem with channel count');

% pull out of cell array if just one processing window
if flag_uniform_output
    [v,relt] = proc.helper.createUniformOutput(v,relt);
end


function [idxAll,packets,channels,units] = processLocalInputs(packets,channels,units,varargin)
% collect all potential inputs

% keep track of varargin indices for the inputs
idxAll = false(size(varargin));

% allow user to specify recording blocks
idx = strncmpi(varargin,'packets',4);
if any(idx)
    packets = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% allow user to specify channels
idx = strncmpi(varargin,'channels',2);
if any(idx)
    channels = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
channels = util.ascell(channels);

idx = strncmpi(varargin,'units',4);
if any(idx)
    units = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

%{
    % now find the superset timing vector, create NaNs to match,
    % and put original data in the appropriate subset of these NaNs
    warning('This is terribly inefficient with memory use!!!');
    relt_combined = min(cellfun(@(x)x(1),relt{kk})):(1/fs):max(cellfun(@(x)x(end),relt{kk}));
    [~,idxst_in_relt] = cellfun(@(x)min(abs(relt_combined-x(1))),relt{kk});
    [~,idxet_in_relt] = cellfun(@(x)min(abs(relt_combined-x(end))),relt{kk});
    
    orig_v = v{kk};
    v{kk} = arrayfun(@(x,y)nan(length(relt_combined),y,dtclass),1:num_arrays,cellfun(@(x)size(x,2),orig_v),'UniformOutput',false);
    for nn=1:num_arrays
        v{kk}{nn}(idxst_in_relt(nn):idxet_in_relt(nn),:) = orig_v{nn};
    end
    v{kk} = cat(2,v{kk}{:});
    relt{kk} = relt_combined;
%}