function [pwr,relt,f,featdef] = specgram(task,params,debugger,varargin)
% SPECGRAM Generate spectrograms for whole trials
%
%   [PWR,RELT,F,FEATDEF] = SPECGRAM(TASK,PARAMS)
%   For the task represented by FrameworkTask object TASK and parameters
%   defined by Parameters.Analysis object PARAMS, calculate spectrograms
%   PWR for the indicated trials, and the time and frequency indices RELT
%   and F.  Also return table FEATDEF which describes the source of each
%   feature.
%
%   SPECGRAM(...,TRIALIDX)
%   Specify which trials to process.  TRIALIDX can be defined logically or
%   numerically indexed.
%
%   SPECGRAM(...,'UNIFORMOUTPUT',FLAG)
%   Force uniform trial size (FLAG is TRUE), or allow trials of different
%   sizes (FLAG is FALSE). In the former case, the outputs will be
%   matrices. In the latter case, outputs will be cell arrays with one cell
%   per trial. Default is TRUE.
%
%   See also FRAMEWORKTASK and PARAMETERS.ANALYSIS.
Parameters.validate(params,mfilename('fullpath'),[],{'tm.analysis','tm.baseline','lfp.smoothmethod','lfp.smoothparams','lfp.normmethod','lfp.normparams'});

% uniform output
[varargin,flagUniformOutput] = util.ProcVarargin(varargin,'UniformOutput',true);

% construct the hash string to represent this dataset in the cache
tag = proc.helper.getCacheTag(task,mfilename);

% process inputs
[trialidx,~,varargin] = proc.helper.trialIndices(varargin,task,params,debugger);
assert(isempty(varargin),'Unexpected inputs');

% check whether data is cached, and if so load it
set_require = list(params,'dt','tm','spc','lfp','chr');
set_except = {'dt.cacheread','dt.cachewrite','dt.mintrials'};
[cached,valid] = cache.query(tag,params,debugger,'require',set_require,'except',set_except);
if cached && valid && params.dt.cacheread
    [pwr,relt,f,featdef] = cache.load(tag,debugger);
    
    % post process: subselect trials, uniform output
    if iscell(pwr)
        [pwr,relt,f] = postprocess(pwr,relt,f,trialidx,flagUniformOutput);
        return;
    end
end

% get the NSx objects
ns = proc.helper.getNSx(task,params);

% get the lag values for this task
lag = task.getLag([],'file_mean');

% get baseline timing and spectrogram
local_tmr = tic;
baseline_pwr = [];
if ~isempty(params.tm.baseline)
    if ~strcmpi(params.spc.normsrc,'baseline')
        debugger.log('Parameters set to process baseline data but not use it for normalization (will not be used for anything else)','warn');
    end
    baseline = params.tm.baseline;
    [baseline_pwr,baseline_relt,baseline_f,baseline_len] = getTrialData(baseline,ns,lag,task,params,debugger,tag);
end
analysis = params.tm.analysis;
[pwr,relt,f,len,featdef] = getTrialData(analysis,ns,lag,task,params,debugger,tag);

% check for empty entries (e.g., not enough data to process)
ok_ = ~cellfun(@isempty,relt);

% variance-stabilizing transformation
if params.spc.varstab
    debugger.log(sprintf('Applying a variance-stabilization transformation to the data: %s',util.any2str(params.spc.varstabmethod)),'info');
    if ~isempty(baseline_pwr)
        baseline_pwr = cellfun(@(x)proc.varstab(x,params.spc.varstabmethod,params.spc.varstabparams),baseline_pwr,'UniformOutput',false);
    end
    pwr = cellfun(@(x)proc.varstab(x,params.spc.varstabmethod,params.spc.varstabparams),pwr,'UniformOutput',false);
end

% smooth
if params.spc.smooth
    warning('smoothing not available for spectrogram data');
end

% remove extra data from beginning/end of data
if ~isempty(baseline_pwr)
    baseline_idx_keep = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),baseline_relt,arrayfun(@(x)x,baseline_len,'UniformOutput',false),'UniformOutput',false);
    assert(all(cellfun(@any,baseline_idx_keep)),'No data left: need to adjust discardpre/discardpost');
    baseline_pwr = cellfun(@(x,y)x(y,:),baseline_pwr,baseline_idx_keep,'UniformOutput',false);
    baseline_relt = cellfun(@(x,y)x(y),baseline_relt,baseline_idx_keep,'UniformOutput',false);
end
analysis_idx_keep = cell(size(relt));
analysis_idx_keep(ok_) = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),relt(ok_),arrayfun(@(x)x,len(ok_),'UniformOutput',false),'UniformOutput',false);
assert(all(cellfun(@any,analysis_idx_keep(ok_))),'No data left: need to adjust discardpre/discardpost');
pwr(ok_) = cellfun(@(x,y)x(y,:,:),pwr(ok_),analysis_idx_keep(ok_),'UniformOutput',false);
relt(ok_) = cellfun(@(x,y)x(y),relt(ok_),analysis_idx_keep(ok_),'UniformOutput',false);
assert(all(cellfun(@(x)diff(x([1 end]))>=params.tm.min,relt(ok_))),'Insufficient data remaining to continue');

% normalize
if params.spc.norm
    if strcmpi(params.spc.normsrc,'baseline')
        assert(~isempty(baseline_pwr),'Cannot normalize to baseline unless baseline phase provided');
        ref = baseline_pwr;
    else
        ref = pwr;
    end
    pwr = cellfun(@(x,y)util.normref(x,y,1,params.spc.normmethod,params.spc.normparams),pwr(:),ref(:),'UniformOutput',false);
end

% time-average
if params.spc.timeavg
    if strcmpi(params.spc.normmethod,'zscore') && strcmpi(params.spc.normsrc,'same')
        debugger.log('These data were just z-scored, so averaging will produce all zeros!','warn');
    end
    pwr = cellfun(@(x)squeeze(nanmean(x,1)),pwr,'UniformOutput',false); % average over time
end

tm=toc(local_tmr);
debugger.log(sprintf('Took %.2f seconds to generate data from scratch',tm),'debug');

% place raw data into cache
if params.dt.cachewrite
    cache.save(tag,params,debugger,pwr,relt,f,featdef);
end

% post process prior to return (trial subselect, uniform output
[pwr,relt,f] = postprocess(pwr,relt,f,trialidx,flagUniformOutput,params);




function [pwr,relt,f,len,featdef] = getTrialData(window,ns,lag,task,params,debugger,tag)
% GETTRIALDATA Extract trials from full dataset
%
%   [PWR,RELT,LEN] = GETTRIALDATA(WINDOW,LENFCN,ALLT,ALLBIN,TASK,PARAMS,DEBUGGER)
%   Extract trials as defined by the FRAMEWORKTASK object TASK and return
%   in the cell arrays SPK and RELT, with the lengths of each trial in LEN.
%   Each cell of PWR contains a MxN matrix of M time points and N features;
%   each cell of RELT contains a Mx1 vector of time points. Each entry of
%   vector LEN contains the length (in seconds) of the trial.
[tm,len] = proc.helper.trialTimeLength(window,task,params,debugger);

% get trial data
cachearg = 'none';
if params.dt.cachewrite && params.dt.cacheread
    cachearg = 'both';
elseif params.dt.cachewrite
    cachearg = 'write';
elseif params.dt.cacheread
    cachearg = 'read';
end
gpuarg = false;
if params.cp.gpu
    gpuarg = true;
end
pararg = false;
if params.cp.parallel
    pararg = true;
end
tm = tm(:)'-params.tm.bufferpre;
len = len(:)'+params.tm.bufferpre+params.tm.bufferpost;
[pwr,relt,f,featdef] = proc.blackrock.specgram(ns,...
    'movingwin',params.spc.movingwin,...
    'chr',params.chr,...
    'procwin',[tm(:) len(:)],...
    'lag',lag,...
    'cache',cachearg,...
    'gpu',gpuarg,...
    'parfor',pararg,...
    'UniformOutput',false,...
    'tag',tag,...
    params.dt.class,...
    debugger);
relt = cellfun(@(x)x-params.tm.bufferpre,relt,'UniformOutput',false);



function [pwr,relt,f] = postprocess(pwr,relt,f,trialidx,flagUniformOutput,params)
% POSTPROCESS Final steps to take before returning data
%
%   [PWR,RELT] = POSTPROCESS(PWR,RELT,TRIALIDX,FLAGUNIFORMOUTPUT)
%   Subselect requested trials, and if requested convert to uniform output.

% subselect just the requested trials
pwr = pwr(trialidx);
relt = relt(trialidx);
f = f(trialidx);

% enforce uniform output if requested
if flagUniformOutput
    fs = 1/params.spc.movingwin(2);
    assert(isscalar(fs)&&isfinite(fs),'Sampling frequency must be common to all trials and finite');
    p = 10^(floor(log10(fs))+2); % precision is next-next higher power of 10 than the sampling frequency
    [pwr,relt,f] = proc.helper.createUniformOutput(pwr,relt,f,'precision',p);
end