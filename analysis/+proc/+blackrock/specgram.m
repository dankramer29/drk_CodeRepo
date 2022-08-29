function varargout = specgram(ns,varargin)
% SPECGRAM Generate spectrograms
%
%   [PWR,RELT,F,FEATDEF] = SPECGRAM(NS)
%   Generate MxN matrix PWR containing spectrogram calculated at M time
%   indices (listed in length-M vector RELT), and for N unique combinations
%   of NSP, channel, and frequency (listed in N-row table FEATDEF).
%   Requires cell array NS containing Blackrock.NSx objects. By default,
%   will use a moving window of [0.5 0.25] seconds and a single processing
%   window covering all available data.
%
%   [PWR,RELT,F,FEATDEF] = SPECGRAM(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e., all channels/windows
%   the same size and concatenated into matrices, or to force cell array
%   output. If FALSE, PWR and RELT will be cell arrays. Otherwise, they
%   will be matrix and vector respectively.
%
%   SPECGRAM(NS,...)
%   TAGS = SPECGRAM(...,'TAGSONLY')
%   Called with no output arguments, or with the TAGSONLY input flag,
%   SPECGRAM will *not* accumulate in memory the spectrogram data as it is
%   calculated. Rather, this mode is intended to be used to generate cached
%   power data and so the CACHE input below must be set to an option that
%   enables writing into the cache ('WRITE' or 'BOTH'). Otherwise, the
%   function will return immediately and generate an error-level log
%   message since no data would be returned or cached -- nothing to do. If
%   the TAGSONLY input flag is indicated, the output TAGS will contain the
%   cache tags for the cached data.
%
%   [...] = SPECGRAM(...,'MOVINGWIN',[WINSIZE STEPSIZE])
%   Specify the moving window for calculating band power as a two-element
%   vector [WINSIZE STEPSIZE], all values in seconds. The default moving
%   window is [0.5 0.25].
%
%   [...] = SPECGRAM(...,'CHR',CHRONUX_PARAMS)
%   Specify the set of chronux parameters as a struct (see Chronux
%   documentation). Default values are tapers [5 9], pad 0, fpass [0 200],
%   and trialave false.
%
%   [...] = SPECGRAM(...,'PROCWIN',[Wn_START Wn_LEN; ...])
%   Specify one or more time ranges in which to process data in PROCWIN, a
%   Kx2 matrix where each row defines the start and length of a processing
%   window. All values in seconds. The default PROCWIN is the entire
%   dataset available in NS.
%
%   [...] = SPECGRAM(...,'LAG',VAL)
%   Specify a lag VAL between the times in PROCWIN and the timestamps
%   associated with the neural data. The lag VAL will be *added* to the
%   values in PROCWIN. The default value is 0 (zero).
%
%   [...] = SPECGRAM(...,'DOUBLE'|'SINGLE'|...)
%   Generate data of a specific class. The default is DOUBLE.
%
%   [...] = SPECGRAM(...,'[PACK]ETS',VAL)
%   Specify the recording packets from which to read the data specified in
%   PROCWIN. If VAL is scalar, it will be applied to all requested data
%   windows in PROCWIN. If there is one element of VAL per data window in
%   PROCWIN, the values will be applied to both arrays. If there is one
%   element of VAL per array, the values will be applied to each window for
%   the respective array. Otherwise, there must be one element of VAL per
%   array/window.
%
%   [...] = SPECGRAM(...,'CACHE','NONE'|'READ'|'WRITE'|'BOTH')
%   Enable or disable reading and writing data from/to the cache. If CACHE
%   is set to 'WRITE' or 'BOTH', the spectrogram data will be saved into
%   the cache by channel (i.e., all windows for channel K will be saved
%   into a single cache entry). If CACHE is set to 'READ' or 'BOTH', the
%   function will check whether the spectrogram data are available in the
%   cache and load them if so, rather than calculating them anew.
%
%   [...] = SPECGRAM(...,'TAG',TAGOBJ)
%   Provide a CACHE.TAGGABLE object TAGOBJ on which to base the cache tags
%   for the per-channel spectrogram data saved into the cache. The default
%   is a CACHE.TAGGABLE object with the single field "mfilename". The tag
%   objects for the per-channel cache entries add a field "channel" to this
%   baseline tag object.
%
%   [...] = SPECGRAM(...,'GPU',TRUE|FALSE)
%   Enable or disable use of the GPU (only applies if a CUDA-compatible GPU
%   is available). Default is the value of the HST environment variable
%   HASGPU, which is set to TRUE if such a GPU is available, and FALSE
%   otherwise. Cannot be set TRUE simultaneously with the PARFOR option
%   described below.
%
%   [...] = SPECGRAM(...,'PARFOR',TRUE|FALSE)
%   Enable or disable use of parfor loops. Default is the opposite of the
%   GPU option described above. Cannot be set TRUE simultaneously with the
%   GPU option.
%
%   [...] = SPECGRAM(...,'LOGFCN',LOGFN)
%   [...] = SPECGRAM(...,DBG)
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
FlagReturnData = true;
if nargout<=1, FlagReturnData = false; end

% pre-process info from Blackrock.NSx objects
ns = util.ascell(ns);
[numArrays,numPhysicalChannels,fs,idxLargestPacket] = proc.helper.processNSxInputs(ns);

% get the log function
[varargin,logfcn] = proc.helper.getLogFcn(varargin);

% defaults
FlagUniformOutput = false;
FlagTagsOnly = false;
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
movingwin = [0.5 0.25];
chr = struct('tapers',[5 9],'pad',0,'fpass',[0 200],'trialave',false);

% process user input
[idx,FlagUniformOutput,procwin,lag,dtclass] = ...
    proc.helper.processCommonInputs(FlagUniformOutput,procwin_orig,lag,dtclass,numArrays,varargin{:});
varargin(idx) = [];
if ~isequal(procwin,procwin_orig)
    packets = nan; % user changed procwin, invalidating default packets
end
[idx,packets,useGPU,useParfor,cacheMode,tag,movingwin,chr,FlagTagsOnly] = ...
    processLocalInputs(packets,cacheMode,tag,movingwin,chr,FlagTagsOnly,varargin{:});
varargin(idx) = [];
util.argempty(varargin);

% check for sanity
if ~FlagReturnData && any(strcmpi(cacheMode,{'none','read'}))
    proc.helper.log(logfcn,'Cache and outputs both disabled','error');
    return;
end

% identify which version of chronux to use
if useGPU
    assert(util.existp('chronux_gpu','package')==9,'Cannot locate chronux_gpu dependency');
    specgram = @chronux_gpu.ct.mtspecgramc;
    genstr = 'GPU';
    if ~strcmpi(dtclass,'single')
        proc.helper.log(logfcn,sprintf('Data class is set to ''%s'' instead of ''single'' which could significantly impact performance when using GPU',dtclass),'warn');
    end
else
    assert(util.existp('chronux','package')==9,'Cannot locate chronux dependency');
    specgram = @chronux.ct.mtspecgramc;
    genstr = 'CPU';
end

% create the feature definitions
featdef = proc.helper.processNSxFeatdef(numPhysicalChannels,lag);

% create cache tags for each channel
numChannels = sum(numPhysicalChannels);
tag.add('procwin',procwin,'lag',lag,'dtclass',dtclass);
if ~strcmpi(cacheMode,'none')
    tag_ch = arrayfun(@(x)tag.copy,1:numChannels,'UniformOutput',false);
    arrayfun(@(x)tag_ch{x}.add('channel',x),1:numChannels,'UniformOutput',false);
end

% check/load any data already cached
chr.Fs = fs;
chidx = 1:numChannels;
arridx = arrayfun(@(x)x*ones(1,numPhysicalChannels(x)),1:numArrays,'UniformOutput',false);
arridx = cat(2,arridx{:});
arrchidx = arrayfun(@(x)1:x,numPhysicalChannels,'UniformOutput',false);
arrchidx = cat(2,arrchidx{:});
chidx_cached = false(size(chidx));
pwr = cell(1,numChannels);
if any(strcmpi(cacheMode,{'read','both'}))
    for kk=1:numChannels
        
        % check whether data is cached, and if so load it
        params = struct('chr',chr,'movingwin',movingwin,'dtclass',dtclass);
        [cached,valid] = cache.query(tag_ch{kk},params,'logfcn',logfcn);
        if cached && valid
            
            % load data from the cache if we're returning data
            if FlagReturnData
                [pwr{kk},relt,f] = cache.load(tag_ch{kk},'logfcn',logfcn);
            end
            chidx_cached(kk) = true;
        end
    end
end
chidx(chidx_cached) = [];
arridx(chidx_cached) = [];
arrchidx(chidx_cached) = [];
channels_per_array = arrayfun(@(x)arrchidx(arridx==x),1:numArrays,'UniformOutput',false);

% process channels not already cached
if ~isempty(chidx)
    
    % validate chronux parameters
    assert(all(ismember({'tapers','pad','fpass','trialave'},fieldnames(chr))),'Chronux parameters require at least tapers, pad, fpass, and trialave');
    proc.helper.log(logfcn,sprintf('Spectrogram will be generated using the %s',genstr),'info');
    proc.helper.log(logfcn,sprintf('Spectral parameters: movingwin %s, fs %d, tapers %s, pad %d, fpass %s, trialave %d',util.vec2str(movingwin),fs,util.vec2str(chr.tapers),chr.pad,util.vec2str(chr.fpass),chr.trialave),'info');

    % read out broadband data for channels not in the cache
    dt = proc.blackrock.broadband(ns,'procwin',procwin,'lag',lag,dtclass,'packets',packets,'channels',channels_per_array,'UniformOutput',false,'logfcn',logfcn);
    assert(isscalar(unique(cellfun(@(x)size(x,2),dt))),'Must have same number of channels in each trial');
    num_trials = length(dt);
    num_time_bins = cellfun(@(x)size(x,1),dt);
    [f,relt] = arrayfun(@(x)util.chronux_dim(chr,x,movingwin,dtclass),num_time_bins,'UniformOutput',false);
    
    % check for trials that are too short and would return empty spectra
    ok_ = ~cellfun(@isempty,relt);
    num_trials_ok = nnz(ok_);
    dt(~ok_) = arrayfun(@(x)[],1:(num_trials-num_trials_ok),'UniformOutput',false);
    relt(~ok_) = arrayfun(@(x)[],1:(num_trials-num_trials_ok),'UniformOutput',false);
    
    % just like for spikes, create time vector such that data associated with
    % time T was read between (T-t) and T (mirroring the online case).
    % chronux returns time as window centers, so add the first value returned
    % by chronux to each of the the time bins.
    relt(ok_) = cellfun(@(x)x+x(1),relt(ok_),'UniformOutput',false);
    
    % branch on parfor vs. non-parfor
    local_pwr = cell(1,num_trials);
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
        proc.helper.log(logfcn,'Starting parfor loop','debug');
        parfor tt=1:num_trials
            if isempty(dt{tt})
                local_pwr{tt} = nan(0,length(f{tt}),numChannels,dtclass);
            else
                local_pwr{tt} = specgram(dt{tt},movingwin,chr);
            end
        end
    else
        % loop over trials so that we can take advantage of the parallelism in
        % operating on multiple channels simultaneously (cannot operate over
        % single channel, multiple trials simultaneously because they may have
        % different lengths)
        for tt=1:num_trials
            if isempty(dt{tt})
                local_pwr{tt} = nan(0,length(f{tt}),numChannels,dtclass);
            else
                proc.helper.log(logfcn,sprintf('Processing trial %d/%d',tt,num_trials),'debug');
                local_pwr{tt} = specgram(dt{tt},movingwin,chr);
            end
        end
    end
    
    % local_pwr comes as a cell array {TRIALS} of matrices (TxFxC)
    % convert local_pwr into cell of cells {CHANNEL}{TRIAL}, each cell TxF
    local_pwr = arrayfun(@(y)cellfun(@(x)x(:,:,y),local_pwr,'UniformOutput',false),1:length(chidx),'UniformOutput',false);
    
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
            params = struct('chr',chr,'movingwin',movingwin,'dtclass',dtclass);
            cache.save(tag_ch{chidx(kk)},params,pwr{chidx(kk)},relt,f,featdef(chidx(kk),:),'logfcn',logfcn);
            
            % remove data if not returning
            if ~FlagReturnData,pwr{chidx(kk)}=[];end
        end
    end
end

% flip the cell hierarchy back to {TRIAL}{CHANNEL} then concatenate
% channels into one matrix per trial of TIME x FREQUENCY x CHANNEL
pwr = util.invertcell(pwr);
pwr = cellfun(@(x)cat(3,x{:}),pwr,'UniformOutput',false);

% force uniform size and matrix output if requested, otherwise pwr is
% already a 1 x ntrials cell array with TIME x FREQUENCY x CHANNEL
if FlagUniformOutput
    [pwr,relt,f] = proc.helper.createUniformOutput(pwr,relt,f); % TIME x FREQUENCY x TRIAL x CHANNEL
end

% assign outputs
if FlagTagsOnly
    varargout{1} = tag_ch;
else
    varargout = {pwr,relt,f,featdef};
end


function [idxAll,packets,useGPU,useParfor,cacheMode,tag,movingwin,chr,FlagTagsOnly] = processLocalInputs(packets,cacheMode,tag,movingwin,chr,FlagTagsOnly,varargin)
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

% chronux parameters
idx = strncmpi(varargin,'chronux',3);
if any(idx)
    chr = varargin{circshift(idx,1,2)};
    idxAll = idxAll|idx|circshift(idx,1,2);
    if ~isstruct(chr) && isobject(chr) && ismethod(chr,'toStruct')
        chr = chr.toStruct;
    end
end

% tags only flag
idx = strcmpi(varargin,'tagsonly');
if any(idx)
    FlagTagsOnly = true;
    idxAll = idxAll|idx;
end