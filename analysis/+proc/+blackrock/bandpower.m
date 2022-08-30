function varargout = bandpower(ns,varargin)
% BANDPOWER Generate band power
%
%   [PWR,RELT,FREQBAND,FEATDEF] = BANDPOWER(NS)
%   Generate MxN matrix PWR containing band power calculated at M time
%   indices (listed in length-M vector RELT), and for N unique combinations
%   of NSP, channel, and frequency (listed in N-row table FEATDEF).
%   Requires cell array NS containing Blackrock.NSx objects. By default,
%   will use a moving window of [0.5 0.25] seconds; a single frequency band
%   covering the full signal bandwidth; and a single processing window
%   covering all available data.
%
%   [PWR,RELT,F,FEATDEF] = BANDPOWER(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e., all channels/windows
%   the same size and concatenated into matrices, or to force cell array
%   output. If FALSE, PWR and RELT will be cell arrays. Otherwise, they
%   will be matrix and vector respectively.
%
%   BANDPOWER(NS,...)
%   TAG = BANDPOWER(NS,...)
%   Called with one or no output arguments, BANDPOWER will *not* accumulate
%   in memory the power data as it is calculated. Rather, this mode is
%   intended to be used to generate cached power data and so the CACHE
%   input below must be set to an option that enabled writing into the
%   cache ('WRITE' or 'BOTH') (otherwise, the function will return
%   immediately with an error-level log message since no data would be
%   returned or cached -- nothing to do).
%
%   [...] = BANDPOWER(...,'MOVINGWIN',[WINSIZE STEPSIZE])
%   Specify the moving window for calculating band power as a two-element
%   vector [WINSIZE STEPSIZE], all values in seconds. The default moving
%   window is [0.5 0.25].
%
%   [...] = BANDPOWER(...,'FREQBAND',[Fx_START Fx_END; ...])
%   Specify the set of N frequency bands as a cell array of N two-element
%   vectors, or a Nx2 matrix, where each row or cell contains the start and
%   end frequency for the frequency band. The default is to calculate the
%   power in [0 FS/2].
%
%   [...] = BANDPOWER(...,'PROCWIN',[Wn_START Wn_LEN; ...])
%   Specify one or more time ranges in which to process data in PROCWIN, a
%   Kx2 matrix where each row defines the start and length of a processing
%   window. All values in seconds. The default PROCWIN is the entire
%   dataset available in NS.
%
%   [...] = BANDPOWER(...,'LAG',VAL)
%   Specify a lag VAL between the times in PROCWIN and the timestamps
%   associated with the neural data. The lag VAL will be *added* to the
%   values in PROCWIN. The default value is 0 (zero).
%
%   [...] = BANDPOWER(...,'DOUBLE'|'SINGLE'|...)
%   Generate data of a specific class. The default is DOUBLE.
%
%   [...] = BANDPOWER(...,'[PACK]ETS',VAL)
%   Specify the recording packets from which to read the data specified in
%   PROCWIN. If VAL is scalar, it will be applied to all requested data
%   windows in PROCWIN. If there is one element of VAL per data window in
%   PROCWIN, the values will be applied to both arrays. If there is one
%   element of VAL per array, the values will be applied to each window for
%   the respective array. Otherwise, there must be one element of VAL per
%   array/window.
%
%   [...] = BANDPOWER(...,'CACHE','NONE'|'READ'|'WRITE'|'BOTH')
%   Enable or disable reading and writing data from/to the cache. If CACHE
%   is set to 'WRITE' or 'BOTH', the spectrogram data will be saved into
%   the cache by channel (i.e., all windows for channel K will be saved
%   into a single cache entry). If CACHE is set to 'READ' or 'BOTH', the
%   function will check whether the spectrogram data are available in the
%   cache and load them if so, rather than calculating them anew.
%
%   [...] = BANDPOWER(...,'TAG',TAGOBJ)
%   Provide a CACHE.TAGGABLE object TAGOBJ on which to base the cache tags
%   for the per-channel spectrogram data saved into the cache. The default
%   is a CACHE.TAGGABLE object with the single field "mfilename". The tag
%   objects for the per-channel cache entries add a field "channel" to this
%   baseline tag object.
%
%   [...] = BANDPOWER(...,'GPU',TRUE|FALSE)
%   Enable or disable use of the GPU (only applies if a CUDA-compatible GPU
%   is available). Default is the value of the HST environment variable
%   HASGPU, which is set to TRUE if such a GPU is available, and FALSE
%   otherwise. Cannot be set TRUE simultaneously with the PARFOR option
%   described below.
%
%   [...] = BANDPOWER(...,'PARFOR',TRUE|FALSE)
%   Enable or disable use of parfor loops. Default is the opposite of the
%   GPU option described above. Cannot be set TRUE simultaneously with the
%   GPU option.
%
%   BANDPOWER(...,'LOGFCN',LOGFN)
%   BANDPOWER(...,DBG)
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
%   See also BLACKROCK.NSX.

% assess output mode requested
returnData = true;
if nargout<=1, returnData = false; end

% pre-process info from Blackrock.NSx objects
ns = util.ascell(ns);
[numArrays,~,fs,idxLargestPacket] = proc.helper.processNSxInputs(ns);

% get the log function
[varargin,logfcn] = proc.helper.getLogFcn(varargin);

% defaults
FlagUniformOutput = false;
packets = idxLargestPacket;
min_time = cellfun(@(x,y)x.Timestamps(y)/x.TimestampTimeResolution,ns,packets);
max_time = cellfun(@(x,y)x.Timestamps(y)/x.TimestampTimeResolution+x.PointsPerDataPacket(y)/fs,ns,packets);
procwin_orig = arrayfun(@(x,y)[x y],min_time,max_time,'UniformOutput',false);
lag = arrayfun(@(x)0,1:numArrays,'UniformOutput',false);
dtclass = 'double';
cacheMode = 'none'; % 'none','read','write','both'
idx_dir = true(1,length(ns{1}.SourceDirectory));
idx_bnm = true(1,length(ns{1}.SourceBasename));
idx_ext = true(1,length(ns{1}.SourceExtension));
for kk=2:length(ns)
    idx_dir = idx_dir & ns{1}.SourceDirectory==ns{kk}.SourceDirectory;
    idx_bnm = idx_bnm & ns{1}.SourceBasename==ns{kk}.SourceBasename;
    idx_ext = idx_ext & ns{1}.SourceExtension==ns{kk}.SourceExtension;
end
tag = cache.Taggable(...
    'mfilename',mfilename,...
    'sourcedir',ns{1}.SourceDirectory(idx_dir),...
    'sourcebasename',ns{1}.SourceBasename(idx_bnm),...
    'sourceext',ns{1}.SourceExtension(idx_ext));
movingwin = [0.5 0.25];
freqband = [];

% process user input
[idx,FlagUniformOutput,procwin,lag,dtclass] = ...
    proc.helper.processCommonInputs(FlagUniformOutput,procwin_orig,lag,dtclass,numArrays,varargin{:});
varargin(idx) = [];
if ~isequal(procwin,procwin_orig)
    packets = nan; % user changed procwin, invalidating default packets
end
[idx,packets,useGPU,useParfor,cacheMode,tag,movingwin,freqband] = ...
    processLocalInputs(packets,cacheMode,tag,movingwin,freqband,fs,varargin{:});
varargin(idx) = [];
assert(isempty(varargin),'Unknown inputs');

% check for sanity
if ~returnData && any(strcmpi(cacheMode,{'none','write'}))
    proc.helper.log(logfcn,'Cache and outputs both disabled','error');
    return;
end

% read out broadband data
[dt,rt,featdef] = proc.blackrock.broadband(ns,'procwin',procwin,'lag',lag,dtclass,'packets',packets,'UniformOutput',false,'logfcn',logfcn);
numChannels = unique(cellfun(@(x)size(x,2),dt));
assert(isscalar(numChannels),'Must have same number of channels in each trial');
numTrials = length(dt);

% create cache tags for each channel and construct cache parameters
if ~strcmpi(cacheMode,'none')
    tag_ch = arrayfun(@(x)tag.copy,1:numChannels,'UniformOutput',false);
    arrayfun(@(x)tag_ch{x}.add('channel',x),1:numChannels,'UniformOutput',false);
    prm = struct(...
        'movingwin',movingwin,...
        'freqband',cat(1,freqband{:}),...
        'procwin',cat(3,procwin{:}),...
        'lag',cat(2,lag{:}),...
        'dtclass',dtclass);
end

% check/load any data already cached
chidx = 1:numChannels;
pwr = cell(1,numChannels);
if any(strcmpi(cacheMode,{'read','both'}))
    for kk=1:numChannels
        
        % check whether data is cached, and if so load it
        [cached,valid] = cache.query(tag_ch{kk},prm,'logfcn',logfcn);
        if cached && valid
            
            % load data from the cache if we're returning data
            if returnData
                pwr{kk} = cache.load(tag_ch{kk},'logfcn',logfcn);
            end
            chidx(chidx==kk)=[];
        end
    end
end

% remove channel data we don't need (to save memory)
dt = cellfun(@(x)x(:,chidx),dt,'UniformOutput',false);

% branch on parfor vs. non-parfor
local_pwr = cell(1,numTrials);
relt = cell(1,numTrials);
if useParfor
    % note that for parfor, we have to operate over the entire dataset at
    % once for it to work, and so the whole thing needs to fit in memory
    % (see above assertion). hence we check the cache first for each
    % channel, load it if necessary, calculate spectrograms for any
    % remaining channels, then save it into the cache.
    
    % calculate band power for any channels not loaded from cache
    % loop over trials and process channels in parallel (making the
    % assumption that there will be more channels than trials, thus
    % reducing total time spent in parfor setup overhead)
    parfor tt=1:numTrials
        [local_pwr{tt},relt{tt}] = proc.basic.bandpower(dt{tt},freqband,movingwin,fs,false);
    end
elseif useGPU
    % for tt=1:numTrials
    %     [local_pwr{tt},relt{tt}] = proc.basic.bandpower_gpu(dt{tt},freqband,movingwin,fs,false);
    % end
    warning('gpu is not currently available for bandpower: dropping to parfor');
    parfor tt=1:numTrials
        [local_pwr{tt},relt{tt}] = proc.basic.bandpower(dt{tt},freqband,movingwin,fs,false);
    end
else
    for tt=1:numTrials
        proc.basic.bandpower(dt{tt},freqband,movingwin,fs,false);
    end
end

% add offset to time vector
relt = cellfun(@(x,y)x+y(1),relt,rt,'UniformOutput',false);

% convert local_pwr from {TRIAL}{CHANNEL} to {CHANNEL}{TRIAL}
local_pwr = util.invertcell(local_pwr);

% merge newly generated into main data
for kk=1:length(chidx)
    pwr{chidx(kk)} = local_pwr{kk};
    local_pwr{kk} = [];
end
clear local_pwr; % free up memory

% cache the newly generated data
if any(strcmpi(cacheMode,{'write','both'}))
    
    % loop over channels and save each into the cache
    for kk=1:length(chidx)
        
        % save this channel into the cache
        cache.save(tag_ch{chidx(kk)},prm,pwr{chidx(kk)},'logfcn',logfcn);
        
        % remove data if not returning
        if ~returnData,pwr{chidx(kk)}=[];end
    end
end

% flip the cell hierarchy back to {TRIAL}{CHANNEL} then concatenate
% channels into one matrix per trial of TIME x FREQUENCY x CHANNEL
pwr = util.invertcell(pwr);
pwr = cellfun(@(x)cat(3,x{:}),pwr,'UniformOutput',false);

% force uniform size and matrix output if requested, otherwise pwr is
% already a 1 x ntrials cell array with TIME x FREQUENCY x CHANNEL
if FlagUniformOutput
    [pwr,relt] = proc.helper.createUniformOutput(pwr,relt); % TIME x FREQUENCY x TRIAL x CHANNEL
end

% assign outputs
if returnData
    varargout = {pwr,relt,freqband,featdef};
elseif nargout==1
    varargout{1} = tag_ch;
end

function [idxAll,packets,useGPU,useParfor,cacheMode,tag,movingwin,freqband] = ...
    processLocalInputs(packets,cacheMode,tag,movingwin,freqband,fs,varargin)
% collect all potential inputs

% keep track of varargin indices for theinputs
idxAll = false(size(varargin));

% allow user to specify recording blocks
idx = strncmpi(varargin,'packets',4);
if any(idx)
    packets = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% check for gpu/parfor input
useGPU = nan;
useParfor = nan;
idx = strcmpi(varargin,'gpu');
if any(idx)
    useGPU = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
idx = strcmpi(varargin,'parfor');
if any(idx)
    useParfor = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
hasGPU = env.get('hasgpu');
[useGPU,useParfor] = proc.helper.getGPUParfor(useParfor,useGPU,hasGPU);

% cache mode, cache tag
idx = strcmpi(varargin,'cache');
if any(idx)
    cacheMode = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end
idx = strcmpi(varargin,'tag');
if any(idx)
    tag = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% moving window
idx = strcmpi(varargin,'movingwin');
if any(idx)
    movingwin = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% frequency bands
idx = strcmpi(varargin,'freqband');
if any(idx)
    freqband = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
end

% validate frequency band settings
if iscell(freqband) && ~isempty(freqband)
    assert(all(cellfun(@(x)numel(x)==2,freqband)),'Must provide cell array of length-two vectors');
elseif ismatrix(freqband) && ~isempty(freqband)
    if size(freqband,2)~=2,freqband=freqband';end
    assert(size(freqband,2)==2,'Must provide Nx2 matrix of frequency bands');
    freqband = arrayfun(@(x)freqband(x,:),1:size(freqband,1),'UniformOutput',false);
else
    assert(isempty(freqband),'Unsupported freqbands input of class ''%s''',class(freqband));
    freqband = {[0 fs/2]};
end