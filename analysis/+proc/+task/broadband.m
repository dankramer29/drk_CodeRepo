function [v,relt,featdef] = broadband(task,params,debug,varargin)
% BROADBAND Collect raw field potentials for trials
%
%   [V,RELT,FEATDEF] = TRIALBROADBAND(TASK,PARAMS,DEBUGGER)
%   For the task represented by FRAMEWORKTASK object TASK, parameters
%   defined by PARAMETERS.DYNAMIC object PARAMS, and debugging object 
%   DEBUGGER, collect broadband data V, relative (to trial timing) time
%   indices RELT for all trials.  Also return table FEATDEF which describes
%   the source of each feature.
%
%   [...] = TRIALBROADBAND(...,TRIALIDX)
%   Specify which trials to process.  TRIALIDX can be defined logically or
%   numerically. Default is all available trials.
%
%   [...] = TRIALBROADBAND(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Force uniform trial size (TRUE), or allow trials of different sizes
%   (FALSE). In the former case, the outputs will be matrices. In the
%   latter case, outputs will be cell arrays with one cell per trial.
%   Default is TRUE.
%
%   PARAMETERS
%   This function depends upon the following parameters. Called functions
%   may require additional parameters.
%
%     TM.BASELINE - define a baseline period for normalization
%     TM.ANALSYIS - define the analysis period
%     TM.MIN - minimum amount of time required after buffering/discarding
%     TM.DT - specify the bin width
%     TM.LENFCN - calculate lengths for each trial from lengths of all
%     TM.BUFFERPRE - how much to read prior to trial (at trial extraction)
%     TM.BUFFERPOST - how much to read after trial (at trial extract)
%     TM.DISCARDPRE - how much to discard prior to trial (after processing)
%     TM.DISCARDPOST - how much to discard after trial (after processing)
%     LFP.FS - specify the sampling rate of spike timestamps
%     LFP.DOWNSAMPLE - whether the spike timestamps were downsampled
%     LFP.NEWFS - the downsampled spike timestamp sampling rate
%     LFP.TIMESTAMPUNITS - the units of timestamps (seconds or samples)
%     LFP.VARSTAB - whether to run variance stabilization transform
%     LFP.VARSTABMETHOD - method of variance stabilization to perform
%     LFP.VARSTABPARAMS - parameters for the selected variance stab method
%     LFP.NORM - whether to normalize the spike data
%     LFP.NORMSRC - the source data for calkulating normalizing parameters
%     LFP.NORMMETHOD - method of normalization to apply
%     LFP.NORMPARAMS - parameters for the selected norm method
%     LFP.SMOOTH - whether to smooth the data
%     LFP.SMOOTHMETHOD - method of smoothing the data
%     LFP.SMOOTHPARAMS - parameters for the selected smoothing method
%     LFP.TIMEAVG - whether to average trial data over time
%     DT.CACHEREAD - whether to read data from cache if available
%     DT.CACHEWRITE - whether to write data into the cache
%
%   See also PARAMETERS.VALIDATE, DEBUG.MESSAGE, CACHE.QUERY, CACHE.LOAD,
%   CACHE.SAVE, UTIL.NORMREF, FRAMEWORKTASK, PARAMETERS.DYNAMIC.
Parameters.validate(params,mfilename('fullpath'),[],{'tm.analysis','tm.baseline','lfp.smoothmethod','lfp.smoothparams','lfp.normmethod','lfp.normparams'});

% uniform output
[varargin,flag_uniform_output] = util.argkeyval('UniformOutput',varargin,true);

% construct the cache tag to represent this dataset in the cache
tag = proc.helper.getCacheTag(task,mfilename,'downsample',params.lfp.downsample);
if params.lfp.downsample,tag.add('newfs',params.lfp.newfs);end

% process inputs
[trialidx,~,varargin] = proc.helper.trialIndices(varargin,task,params,debug);
assert(isempty(varargin),'Unexpected inputs');

% check whether data is cached, and if so load it
set_require = list(params,'dt','lfp','tm');
set_except = {'dt.cacheread','dt.cachewrite','dt.mintrials'};
[cached,valid] = cache.query(tag,params,debug,'require',set_require,'except',set_except);
if cached && valid && params.dt.cacheread
    [v,relt,fs,featdef] = cache.load(tag,debug);
    
    % post process: subselect trials, uniform output
    if iscell(v)
        [v,relt] = postprocess(v,relt,fs,trialidx,flag_uniform_output);
        return;
    end
end

% get the BLc objects
blc = proc.helper.getBLc(task,params,debug);
fs = unique(cellfun(@(x)x.SamplingRate,blc));
assert(isscalar(fs),'Sampling frequencies must be the same in all BLc objects');

% get the lag values for this task
lag = task.getLag([],'file_mean');

% get baseline timing and broadband data
local_tmr = tic;
baseline_v = [];
if ~isempty(params.tm.baseline)
    if ~strcmpi(params.lfp.normsrc,'baseline')
        debug.log('Parameters set to process baseline data but not use it for normalization (will not be used for anything else)','warn');
    end
    baseline = params.tm.baseline;
    [baseline_v,baseline_relt,baseline_len] = getTrialData(baseline,blc,lag,task,params,debug);
end
analysis = params.tm.analysis;
[v,relt,len,featdef] = getTrialData(analysis,blc,lag,task,params,debug);

% attenuate the 60-Hz and harmonices noise frequencies
if params.lfp.linenoise
    debug.log('Attenuating 60-Hz noise','info');
    win = [2 1];
    chr = toStruct(params.chr);
    chr.Fs = newfs;
    v = cellfun(@(x)chronux.ct.rmlinesmovingwinc(x,win,10,chr,[],[],60:60:(fs/2)),v,'UniformOutput',false);
end

% detrend the data
if params.lfp.detrend
    debug.log(sprintf('Detrending the data: %s',params.lfp.detrendmethod),'info');
    switch lower(params.lfp.detrendmethod)
        case 'detrendwin'
            v = cellfun(@(x)chronux.ct.locdetrend(x,fs,params.lfp.detrendwin),v,'UniformOutput',false);
        case 'dc_offset'
            v = cellfun(@(x)bsxfun(@minus,x,nanmean(x)),v,'UniformOutput',false);
        otherwise
            error('Unknown detrend method ''%s''',params.lfp.detrendmethod);
    end
end

% re-reference the data
if params.lfp.reref
    debug.log(sprintf('Re-referencing the data: %s',util.any2str(params.lfp.rerefmethod)),'info');
    v = cellfun(@(x)proc.basic.reref(x),v,'UniformOutput',false);
end

% downsample
if fs~=params.lfp.newfs && params.lfp.downsample
    if ~isempty(baseline_v)
        baseline_v = cellfun(@(x)proc.downsample(x,fs,params,debug),baseline_v,'UniformOutput',false);
    end
    [v,fs] = cellfun(@(x)proc.downsample(x,fs,params,debug),v,'UniformOutput',false);
    assert(numel(unique(cat(1,fs{:})))==1,'No support for different sampling frequencies between channels');
    fs = fs{1};
end

% variance-stabilizing transformation
if params.lfp.varstab
    debug.log(sprintf('Applying a variance-stabilization transformation to the data: %s',util.any2str(params.lfp.varstabmethod)),'info');
    if ~isempty(baseline_v)
        baseline_v = cellfun(@(x)proc.varstab(x,params.lfp.varstabmethod,params.lfp.varstabparams),baseline_v,'UniformOutput',false);
    end
    v = cellfun(@(x)proc.varstab(x,params.lfp.varstabmethod,params.lfp.varstabparams),v,'UniformOutput',false);
end

% smooth
if params.lfp.smooth
    params.lfp.smoothparams.period = 1/fs;
    debug.log(sprintf('Smoothing the data: %s',util.any2str(params.lfp.smoothmethod)),'info');
    if ~isempty(baseline_v)
        baseline_v = cellfun(@(x)proc.smooth(x,params.lfp.smoothmethod,params.lfp.smoothparams),baseline_v,'UniformOutput',false);
    end
    v = cellfun(@(x)proc.smooth(x,params.lfp.smoothmethod,params.lfp.smoothparams),v,'UniformOutput',false);
end

% remove extra data from beginning/end of data
if ~isempty(baseline_v)
    baseline_idx_keep = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),baseline_relt,arrayfun(@(x)x,baseline_len,'UniformOutput',false),'UniformOutput',false);
    assert(all(cellfun(@any,baseline_idx_keep)),'No data left: need to adjust discardpre/discardpost');
    baseline_v = cellfun(@(x,y)x(y,:),baseline_v,baseline_idx_keep,'UniformOutput',false);
    baseline_relt = cellfun(@(x,y)x(y),baseline_relt,baseline_idx_keep,'UniformOutput',false);
end
analysis_idx_keep = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),relt(:),arrayfun(@(x)x,len(:),'UniformOutput',false),'UniformOutput',false);
assert(all(cellfun(@any,analysis_idx_keep)),'No data left: need to adjust discardpre/discardpost');
v = cellfun(@(x,y)x(y,:),v(:),analysis_idx_keep(:),'UniformOutput',false);
relt = cellfun(@(x,y)x(y),relt(:),analysis_idx_keep(:),'UniformOutput',false);
assert(all(cellfun(@(x)diff(x([1 end]))>=params.tm.min,relt)),'Insufficient data remaining to continue');

% normalize
if params.lfp.norm
    if strcmpi(params.lfp.normsrc,'baseline')
        assert(~isempty(baseline_v),'Cannot normalize to baseline unless baseline phase provided');
        ref = baseline_v;
    else
        ref = v;
    end
    debug.log(sprintf('Normalizing the data: %s',util.any2str(params.lfp.normmethod)),'info');
    v = cellfun(@(x,y)util.normref(x,y,1,params.lfp.normmethod,params.lfp.normparams),v(:),ref(:),'UniformOutput',false);
end

% time-average
if params.lfp.timeavg
    if strcmpi(params.lfp.normmethod,'zscore') && strcmpi(params.lfp.normsrc,'same')
        debug.log('These data were just z-scored, so averaging will produce all zeros!','warn');
    end
    debug.log('Time-averaging the data','info');
    v = cellfun(@(x)squeeze(mean(x,1)),v,'UniformOutput',false); % average over time
end

tm=toc(local_tmr);
debug.log(sprintf('Took %.2f seconds to generate data from scratch',tm),'debug');

% place raw data into cache
if params.dt.cachewrite
    cache.save(tag,params,debug,v,relt,fs,featdef);
end

% post process prior to return (trial subselect, uniform output
[v,relt] = postprocess(v,relt,fs,trialidx,flag_uniform_output);



function [v,relt,len,featdef] = getTrialData(window,blc,lag,task,params,debugger)
% GETTRIALDATA Extract trials from full bin dataset
%
%   [V,RELT,LEN] = GETTRIALDATA(WINDOW,LENFCN,NS,LAG,TASK,PARAMS,DEBUGGER)
%   Extract trials as defined by the FRAMEWORKTASK object TASK and return
%   in the cell arrays V and RELT, with the lengths of each trial in LEN.
%   Each cell of V contains a MxN matrix of M time points and N features;
%   each cell of RELT contains a Mx1 vector of time points. Each entry of
%   vector LEN contains the length (in seconds) of the trial.
[tm,len] = proc.helper.trialTimeLength(window,task,params,debugger);

% get baseline data
tm = tm(:)-params.tm.bufferpre;
len = len(:)+params.tm.bufferpre+params.tm.bufferpost;
[v,relt,featdef] = proc.blc.broadband(blc,'procwin',[tm(:) len(:)],'lag',lag,params.dt.class,debugger,'UniformOutput',false,'units',params.lfp.units);
relt = cellfun(@(x)x-params.tm.bufferpre,relt,'UniformOutput',false);



function [v,relt] = postprocess(v,relt,fs,trialidx,flagUniformOutput)
% POSTPROCESS Final steps to take before returning data
%
%   [V,RELT] = POSTPROCESS(V,RELT,TRIALIDX,FLAGUNIFORMOUTPUT)
%   Subselect requested trials, and if requested convert to uniform output.

% subselect just the requested trials
v = v(trialidx);
relt = relt(trialidx);

% enforce uniform output if requested
if flagUniformOutput
    p = 10^(floor(log10(fs))+2); % precision is next higher power of 10 than the sampling frequency
    [v,relt] = proc.helper.createUniformOutput(v,relt,'precision',p);
end