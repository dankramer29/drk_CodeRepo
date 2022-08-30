function varargout = spectrum(ns,varargin)
% SPECTRUM Generate power spectrums
%
%   [PWR,F,FEATDEF] = SPECTRUM(NS)
%   Generate MxN matrix PWR containing power spectrums for N unique
%   combinations of NSP and channel (listed in N-row table FEATDEF).
%   Requires cell array NS containing Blackrock.NSx objects. By default,
%   processes all files from the beginning of the file to the
%   minimum of the file lengths.
%
%   [PWR,F,FEATDEF] = SPECTRUM(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e., all channels/nsps
%   the same size and concatenated into matrices, or to force cell array
%   output. If FALSE, PWR will be cell array. Otherwise, PWR will be
%   matrix.
%
%   SPECTRUM(NS,...)
%   TAG = SPECTRUM(NS,...)
%   Called with one or no output arguments, SPECTRUM will *not* accumulate
%   in memory the spectrum data as it is calculated. Rather, this mode
%   is intended to be used to generate cached power data and so the CACHE
%   input below must be set to an option that enables writing into the
%   cache ('WRITE' or 'BOTH'). Otherwise, the function will return
%   immediately and generate an error-level log message since no data would
%   be returned or cached -- nothing to do.
%
%   [...] = SPECTRUM(...,'CHR',CHRONUX_PARAMS)
%   Specify the set of chronux parameters as a struct (see Chronux
%   documentation). Default values are tapers [5 9], pad 0, fpass [0 200],
%   and trialave false.
%
%   [...] = SPECTRUM(...,'PROCWIN',[Wn_START Wn_LEN; ...])
%   Specify one or more time ranges in which to process data in PROCWIN, a
%   Kx2 matrix where each row defines the start and length of a processing
%   window. All values in seconds. The default PROCWIN is the entire
%   dataset available in NS. PWR will be MxNxK.
%
%   [...] = SPECTRUM(...,'LAG',VAL)
%   Specify a lag VAL between the times in PROCWIN and the timestamps
%   associated with the neural data. The lag VAL will be *added* to the
%   values in PROCWIN. The default value is 0 (zero).
%
%   [...] = SPECTRUM(...,'DOUBLE'|'SINGLE'|...)
%   Generate data of a specific class. The default is DOUBLE.
%
%   [...] = SPECTRUM(...,'[PACK]ETS',VAL)
%   Specify the recording packets from which to read the data specified in
%   PROCWIN. If VAL is scalar, it will be applied to all requested data
%   windows in PROCWIN. If there is one element of VAL per data window in
%   PROCWIN, the values will be applied to both arrays. If there is one
%   element of VAL per array, the values will be applied to each window for
%   the respective array. Otherwise, there must be one element of VAL per
%   array/window.
%
%   [...] = SPECTRUM(...,'CACHE','NONE'|'READ'|'WRITE'|'BOTH')
%   Enable or disable reading and writing data from/to the cache. If CACHE
%   is set to 'WRITE' or 'BOTH', the spectrogram data will be saved into
%   the cache by channel (i.e., all windows for channel K will be saved
%   into a single cache entry). If CACHE is set to 'READ' or 'BOTH', the
%   function will check whether the spectrogram data are available in the
%   cache and load them if so, rather than calculating them anew.
%
%   [...] = SPECTRUM(...,'TAG',TAGOBJ)
%   Provide a CACHE.TAGGABLE object TAGOBJ on which to base the cache tags
%   for the per-channel spectrogram data saved into the cache. The default
%   is a CACHE.TAGGABLE object with the single field "mfilename". The tag
%   objects for the per-channel cache entries add a field "channel" to this
%   baseline tag object.
%
%   [...] = SPECTRUM(...,'GPU',TRUE|FALSE)
%   Enable or disable use of the GPU (only applies if a CUDA-compatible GPU
%   is available). Default is the value of the HST environment variable
%   HASGPU, which is set to TRUE if such a GPU is available, and FALSE
%   otherwise. Cannot be set TRUE simultaneously with the PARFOR option
%   described below.
%
%   [...] = SPECTRUM(...,'PARFOR',TRUE|FALSE)
%   Enable or disable use of parfor loops. Default is the opposite of the
%   GPU option described above. Cannot be set TRUE simultaneously with the
%   GPU option.
%
%   [...] = SPECTRUM(...,'LOGFCN',LOGFN)
%   [...] = SPECTRUM(...,DBG)
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
[numArrays,numPhysicalChannels,fs,idxLargestPacket] = proc.helper.processNSxInputs(ns);

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
cacheMode = 'none';
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
chr = struct('tapers',[5 9],'pad',0,'fpass',[0 200],'trialave',false);

% process user input
[idx,FlagUniformOutput,procwin,lag,dtclass] = ...
    proc.helper.processCommonInputs(FlagUniformOutput,procwin_orig,lag,dtclass,numArrays,varargin{:});
varargin(idx) = [];
if ~isequal(procwin,procwin_orig)
    packets = nan; % user changed procwin, invalidating default packets
end
[idx,packets,useGPU,useParfor,cacheMode,tag,chr] = ...
    processLocalInputs(packets,cacheMode,tag,chr,varargin{:});
varargin(idx) = [];
assert(isempty(varargin),'Unknown inputs');

% check for sanity
if ~returnData && any(strcmpi(cacheMode,{'none','write'}))
    proc.helper.log(logfcn,'Cache and outputs both disabled','error');
    return;
end

% identify which version of chronux to use
if useGPU
    assert(util.existp('chronux_gpu','package')==9,'Cannot locate chronux_gpu dependency');
    spectrum = @chronux_gpu.ct.mtspectrumc;
    proc.helper.log(logfcn,'Spectrum will be generated using the GPU','info');
    if ~strcmpi(dtclass,'single')
        proc.helper.log(logfcn,sprintf('Data class is set to ''%s'' instead of ''single'' which could significantly impact performance when using GPU',dtclass),'warn');
    end
else
    assert(util.existp('chronux','package')==9,'Cannot locate chronux dependency');
    spectrum = @chronux.ct.mtspectrumc;
    proc.helper.log(logfcn,'Spectrum will be generated using the CPU','info');
end

% set up chronux parameters
chr.Fs = fs;
assert(all(ismember({'tapers','pad','fpass','trialave'},fieldnames(chr))),'Chronux parameters require at least tapers, pad, fpass, and trialave');
proc.helper.log(logfcn,sprintf('Spectral parameters: fs %d, tapers %s, pad %d, fpass %s, trialave %d',fs,util.vec2str(chr.tapers),chr.pad,util.vec2str(chr.fpass),chr.trialave),'info');

% read out broadband data
[dt,~,bfeatdef] = proc.blackrock.broadband(ns,'procwin',procwin,'lag',lag,dtclass,'packets',packets,'UniformOutput',false,'logfcn',logfcn);
numChannels = unique(cellfun(@(x)size(x,2),dt));
assert(isscalar(numChannels),'Must have same number of channels in each trial');
numTrials = length(dt);
numTimeBins = cellfun(@(x)size(x,1),dt);
f = arrayfun(@(x)util.chronux_dim(chr,x,[],dtclass),numTimeBins,'UniformOutput',false);

% create cache tags for each channel
if ~strcmpi(cacheMode,'none')
    tag_ch = arrayfun(@(x)tag.copy,1:numChannels,'UniformOutput',false);
    arrayfun(@(x)tag_ch{x}.add('channel',x),1:numChannels,'UniformOutput',false);
end

% make sure we have enough available memory to compute specgram
if useParfor || returnData
    
    % with parfor loops and if returning data, must all fit in memory
    numTotal = sum(cellfun(@(x)numel(x),dt)) + numChannels*sum(arrayfun(@(x)numel(x),f));
else
    
    % otherwise, only the largest processing window has to fit in memory
    numTotal = max(cellfun(@numel,dt)) + sum(arrayfun(@(x)numel(x),f));
end
util.memcheck([1 numTotal],dtclass,'assert','MinimumFree',0.5*2^30,'quiet'); % keep 0.5GB free

% check/load any data already cached
chidx = 1:numChannels;
chidx_cached = false(size(chidx));
pwr = cell(1,numChannels);
if any(strcmpi(cacheMode,{'read','both'}))
    for kk=1:numChannels
        
        % check whether data is cached, and if so load it
        params = struct('chr',chr,'dtclass',dtclass);
        [cached,valid] = cache.query(tag_ch{kk},params,'logfcn',logfcn);
        if cached && valid
            
            % load data from the cache if we're returning data
            if returnData
                pwr{kk} = cache.load(tag_ch{kk},'logfcn',logfcn);
            end
            chidx_cached(kk) = true;
        end
    end
end
chidx(chidx_cached) = [];

% remove channel data we don't need (to save memory)
dt = cellfun(@(x)x(:,chidx),dt,'UniformOutput',false);

% branch on parfor vs. non-parfor
local_pwr = cell(1,numTrials);
if useParfor
    % note that for parfor, we have to essentially be able to operate over
    % the entire dataset at once for it to work, and so the whole thing
    % needs to fit in memory (see above assertion). hence we check the
    % cache first for each channel, load it if necessary, calculate
    % spectrograms for any remaining channels, then save it into the cache.
    
    
    % calculate spectrogram for any channels not loaded from cache
    % loop over trials and process channels in parallel (making the
    % assumption that there will be more channels than trials, thus
    % reducing total time spent in parfor setup overhead)
    parfor tt=1:numTrials
        if isempty(dt{tt}),continue;end
        if any(isnan(dt{tt}))
            warning('Any NaN in the source data will result in all NaN power spectra output');
        end
        local_pwr{tt} = spectrum(dt{tt},chr);
    end
else
    % loop over trials so that we can take advantage of the parallelism in
    % operating on multiple channels simultaneously (cannot operate over
    % single channel, multiple trials simultaneously because they may have
    % different lengths)
    for tt=1:numTrials
        if isempty(dt{tt}),continue;end
        proc.helper.log(logfcn,sprintf('Processing trial %d/%d',tt,numTrials),'debug');
        if any(isnan(dt{tt}))
            warning('Any NaN in the source data will result in all NaN power spectra output');
        end
        local_pwr{tt} = spectrum(dt{tt},chr);
    end
end

% local_pwr comes as a cell array {TRIALS} of matrices (FxC)
% convert local_pwr into cell of cells {CHANNEL}{TRIAL}, each cell Fx1
local_pwr = arrayfun(@(y)cellfun(@(x)x(:,y),local_pwr,'UniformOutput',false),1:length(chidx),'UniformOutput',false);

% merge newly generated into main data
for kk=1:length(chidx)
    pwr{chidx(kk)} = local_pwr{kk};
    local_pwr{kk} = [];
end
clear local_pwr; % free up memory

% create the feature definitions
lagPerArray = arrayfun(@(x)unique(bfeatdef.lag(bfeatdef.nsp==x)),1:numArrays,'UniformOutput',false);
featdef = proc.helper.processNSxFeatdef(numPhysicalChannels,lagPerArray);

% cache the newly generated data
if any(strcmpi(cacheMode,{'write','both'}))
    
    % loop over channels and save each into the cache
    for kk=1:length(chidx)
        
        % save this channel into the cache
        params = struct('chr',chr,'dtclass',dtclass);
        cache.save(tag_ch{chidx(kk)},params,pwr{chidx(kk)},f,featdef(chidx(kk),:),'logfcn',logfcn);
        
        % remove data if not returning
        if ~returnData,pwr{chidx(kk)}=[];end
    end
end

% flip the cell hierarchy back to {TRIAL}{CHANNEL} then concatenate
% channels into one matrix per trial of TIME x FREQUENCY x CHANNEL
pwr = util.invertcell(pwr);
pwr = cellfun(@(x)cat(2,x{:}),pwr,'UniformOutput',false);

% force uniform size and matrix output if requested, otherwise pwr is
% already a 1 x ntrials cell array with TIME x FREQUENCY x CHANNEL
if FlagUniformOutput
    [pwr,f] = proc.helper.createUniformOutput(pwr,f); % TIME x FREQUENCY x TRIAL x CHANNEL
end

% assign outputs
if nargout==3
    varargout = {pwr,f,featdef};
elseif nargout==1
    varargout{1} = tag_ch;
end



function [idxAll,packets,useGPU,useParfor,cacheMode,tag,chr] = processLocalInputs(packets,cacheMode,tag,chr,varargin)
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

% chronux parameters
idx = strcmpi(varargin,'chr');
if any(idx)
    chr = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
    if ~isstruct(chr) && isobject(chr) && ismethod(chr,'toStruct')
        chr = chr.toStruct;
    end
end
