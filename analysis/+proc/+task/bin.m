function [spk,relt,featdef,trialdef] = bin(task,params,debugger,varargin)
% BIN Generate firing rates for trials
%
%   [SPK,RELT,FEATDEF,TRIALDEF] = BIN(TASK,PARAMS,DEBUGGER)
%   For the task represented by FRAMEWORKTASK object TASK, parameters
%   defined by PARAMETERS.DYNAMIC object PARAMS, and debugging object 
%   DEBUGGER, calculate binned spike data SPK and relative (to trial
%   timing) time indices RELT for all trials.  Also return FEATDEF which
%   describes the source of each feature, and TRIALDEF which describes the
%   source of each trial (depending on UNIFORMOUTPUT below).
%
%   [...] = BIN(...,'UNIFORMOUTPUT',TRUE|FALSE)
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
%     TM.BUFFERPRE - how much to read prior to trial (at trial extraction)
%     TM.BUFFERPOST - how much to read after trial (at trial extract)
%     TM.DISCARDPRE - how much to discard prior to trial (after processing)
%     TM.DISCARDPOST - how much to discard after trial (after processing)
%     SPK.BINWIDTH - specify the bin width
%     SPK.NOISE - whether to include noise units
%     SPK.UNSORTED - whether to include unsorted units
%     SPK.RATEFILT - whether to filter features on a firing rate threshold
%     SPK.RATEFILTMETHOD - method of rate filtering to perform
%     SPK.RATEFILTPARAMS - parameters for selected rate filtering method
%     SPK.VARSTAB - whether to run variance stabilization transform
%     SPK.VARSTABMETHOD - method of variance stabilization to perform
%     SPK.VARSTABPARAMS - parameters for the selected variance stab method
%     SPK.NORM - whether to normalize the spike data
%     SPK.NORMSRC - the source data for calkulating normalizing parameters
%     SPK.NORMMETHOD - method of normalization to apply
%     SPK.NORMPARAMS - parameters for the selected norm method
%     SPK.SMOOTH - whether to smooth the data
%     SPK.SMOOTHMETHOD - method of smoothing the data
%     SPK.SMOOTHPARAMS - parameters for the selected smoothing method
%     SPK.TIMEAVG - whether to average trial data over time
%     SPK.BIN2FR - whether to convert binned spike counts to firing rates
%     DT.CACHEREAD - whether to read data from cache if available
%     DT.CACHEWRITE - whether to write data into the cache
%     DT.CLASS - the data class to use (e.g., 'double' or 'single')
%
%   See also PARAMETERS.VALIDATE, CACHE.QUERY, CACHE.LOAD, CACHE.SAVE,
%   PROC.TCU, PROC.BLACKROCK.BIN, PROC.BIN2FR, UTIL.NORMREF, FRAMEWORKTASK,
%   PARAMETERS.DYNAMIC.
Parameters.validate(params,mfilename('fullpath'));

% process inputs
[varargin,flagUniformOutput] = util.argkeyval('UniformOutput',varargin,true);
[trialidx,~,varargin] = proc.helper.trialIndices(varargin,task,params,debugger);
util.argempty(varargin);

% construct the hash string to represent this dataset in the cache
tag = proc.helper.getCacheTag(task,mfilename,'baseline',params.tm.baseline,'analysis',params.tm.analysis);

% check whether data is cached, and if so load it
set_require = list(params,'dt','tm','spk','fr');
set_except = {'dt.cacheread','dt.cachewrite','dt.mintrials'};
[cached,valid] = cache.query(tag,params,debugger,'require',set_require,'except',set_except);
if cached && valid && params.dt.cacheread
    [spk,relt,fs,featdef,trialdef] = cache.load(tag,debugger);
    
    % post process: subselect trials, uniform output
    if iscell(spk)
        [spk,relt,trialdef] = postprocess(spk,relt,trialdef,fs,trialidx,flagUniformOutput);
        return;
    end
end

% get the NEV objects
%THIS IS A TEMPORARY FIX UNTIL BLC GETS NEV FILES TO WORK
warning('THIS IS A TEMPORARY FIX UNTIL BLC GETS NEV FILES TO WORK')
fileend = strcat(task.srcFile, '-NSP1-001.nev');
filebegin = erase(task.srcDir, 'Task');
filebegin = strcat(filebegin, 'NSP1');
taskfilename = fullfile(filebegin, fileend);
nv = Blackrock.NEV(taskfilename);
nv={nv};

%nv = proc.helper.getNEV(task,params);

% get the lag values for this task
lag = task.getLag([],'file_mean');

% get spike timing and firing rates
local_tmr = tic;
baseline_spk = [];
if ~isempty(params.tm.baseline)
    if ~strcmpi(params.spk.normsrc,'baseline')
        debugger.log('Parameters set to process baseline data but not use it for normalization (will not be used for anything else)','warn');
    end
    baseline = params.tm.baseline;
    [baseline_spk,baseline_relt,baseline_len,baseline_featdef,baseline_trialdef] = getTrialData(baseline,nv,lag,task,params,debugger);
end
analysis = params.tm.analysis;
[spk,relt,len,featdef,trialdef] = getTrialData(analysis,nv,lag,task,params,debugger);
fs = proc.helper.getFsFromRelt(relt);

% make sure baseline and analysis comprise a common subset of data
% (features and trials)
if ~isempty(baseline_spk)
    
    % identify trials common to both baseline/analysis
    common_trials = intersect(baseline_trialdef.trial,trialdef.trial);
    debugger.log(sprintf('Common trials %s',util.vec2str(common_trials)),'info');
    idx = ~ismember(baseline_trialdef.trial,common_trials);
    baseline_spk(idx) = [];
    baseline_relt(idx) = [];
    baseline_len(idx) = [];
    idx = ~ismember(trialdef.trial,common_trials);
    spk(idx) = [];
    relt(idx) = [];
    len(idx) = [];
    trialdef(idx,:) = [];
    
    % identify features common to both baseline/analysis
    baseline_subs = baseline_featdef(:,1:4);
    analysis_subs = featdef(:,1:4);
    common_featdef = intersect(baseline_subs,analysis_subs,'rows');
    idx = ismember(baseline_subs,common_featdef,'rows');
    baseline_spk = cellfun(@(x)x(:,idx),baseline_spk,'UniformOutput',false);
    idx = ismember(analysis_subs,common_featdef,'rows');
    spk = cellfun(@(x)x(:,idx),spk,'UniformOutput',false);
    featdef = featdef(ismember(analysis_subs,common_featdef),:);
end

% filter features based on firing rate
if params.spk.ratefilt
    ratefiltmth = params.spk.ratefiltmethod;
    ratefiltprm = params.spk.ratefiltparams;
    debugger.log(sprintf('Applying a firing rate filter to the data: %s',util.any2str(ratefiltmth)),'info');
    switch lower(ratefiltmth)
        case 'mean'
            avgspk = cellfun(@(x)nanmean(x,1),spk,'UniformOutput',false); % calculate average bin count
            bad_idx = feval(ratefiltprm.mean_bad_fcn,mean(cat(1,avgspk{:}),1),ratefiltprm.mean_threshold);
        case 'median'
            avgspk = cellfun(@(x)nanmedian(x,1),spk,'UniformOutput',false); % calculate median bin count
            bad_idx = feval(ratefiltprm.median_bad_fcn,mean(cat(1,avgspk{:}),1),ratefiltprm.median_threshold);
        case 'max'
            avgspk = cellfun(@(x)nanmax(x,[],1),spk,'UniformOutput',false); % calculate maximum bin count
            bad_idx = feval(ratefiltprm.max_bad_fcn,mean(cat(1,avgspk{:}),1),ratefiltprm.max_threshold);
        case 'min'
            avgspk = cellfun(@(x)nanmin(x,[],1),spk,'UniformOutput',false); % calculate minimum bin count
            bad_idx = feval(ratefiltprm.min_bad_fcn,mean(cat(1,avgspk{:}),1),ratefiltprm.min_threshold);
        otherwise
            error('Unknown rate filter method ''%s''',ratefiltmth);
    end
    spk = cellfun(@(x)x(:,~bad_idx),spk,'UniformOutput',false); % remove bad features from each trial
    featdef(bad_idx,:) = [];
    if ~isempty(baseline_spk)
        baseline_spk = cellfun(@(x)x(:,~bad_idx),baseline_spk,'UniformOutput',false);
    end
end

% variance-stabilizing transformation
if params.spk.varstab
    varstabmth = params.spk.varstabmethod;
    varstabprm = params.spk.varstabparams;
    debugger.log(sprintf('Applying a variance-stabilization transformation to the data: %s',util.any2str(varstabmth)),'info');
    if ~isempty(baseline_spk)
        baseline_spk = cellfun(@(x)proc.varstab(x,varstabmth,varstabprm),baseline_spk,'UniformOutput',false);
    end
    spk = cellfun(@(x)proc.varstab(x,varstabmth,varstabprm),spk,'UniformOutput',false);
end

% smooth
if params.spk.smooth
    smoothmth = params.spk.smoothmethod;
    smoothprm = params.spk.smoothparams;
    smoothprm.period = 1/fs;
    debugger.log(sprintf('Smoothing the data: %s',util.any2str(smoothmth)),'info');
    if ~isempty(baseline_spk)
        baseline_spk = cellfun(@(x)proc.smooth(x,smoothmth,smoothprm),baseline_spk,'UniformOutput',false);
    end
    spk = cellfun(@(x)proc.smooth(x,smoothmth,smoothprm),spk,'UniformOutput',false);
end

% remove extra data from beginning/end of data
if ~isempty(baseline_spk)
    baseline_idx_keep = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),baseline_relt,arrayfun(@(x)x,baseline_len,'UniformOutput',false),'UniformOutput',false);
    assert(all(cellfun(@any,baseline_idx_keep)),'No data left: need to adjust discardpre/discardpost');
    baseline_spk = cellfun(@(x,y)x(y,:),baseline_spk,baseline_idx_keep,'UniformOutput',false);
    baseline_relt = cellfun(@(x,y)x(y),baseline_relt,baseline_idx_keep,'UniformOutput',false);
end
analysis_idx_keep = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),relt(:),arrayfun(@(x)x,len,'UniformOutput',false),'UniformOutput',false);
assert(all(cellfun(@any,analysis_idx_keep)),'No data left: need to adjust discardpre/discardpost');
spk = cellfun(@(x,y)x(y,:),spk(:),analysis_idx_keep(:),'UniformOutput',false);
relt = cellfun(@(x,y)x(y),relt(:),analysis_idx_keep(:),'UniformOutput',false);
assert(all(cellfun(@(x)diff(x([1 end]))>=params.tm.min,relt)),'Insufficient data remaining to continue');

% normalize
if params.spk.norm
    normmth = params.spk.normmethod;
    normprm = params.spk.normparams;
    if strcmpi(params.spk.normsrc,'baseline')
        assert(~isempty(baseline_spk),'Cannot normalize to baseline unless baseline phase provided');
        ref = baseline_spk;
    else
        ref = spk;
    end
    debugger.log(sprintf('Normalizing the data: %s',util.any2str(normmth)),'info');
    spk = cellfun(@(x,y)util.normref(x,y,1,normmth,normprm),spk,ref,'UniformOutput',false);
end

% convert to firing rates
if params.spk.bin2fr
    debugger.log('Converting from binned spike counts to binned firing rates','info');
    spk = cellfun(@(x,y)proc.bin2fr(x,y),relt,spk,'UniformOutput',false);
end

% time-average
if params.spk.timeavg
    if params.spk.norm && strcmpi(params.spk.normmethod,'zscore') && strcmpi(params.spk.normsrc,'same')
        debugger.log('These data were just z-scored, so averaging will produce all zeros!','warn');
    end
    debugger.log('Time-averaging the data','info');
    spk = cellfun(@(x)squeeze(nanmean(x,1)),spk,'UniformOutput',false); % average over time
end

tm=toc(local_tmr);
debugger.log(sprintf('Took %.2f seconds to generate data from scratch',tm),'debug');

% place raw data into cache
if params.dt.cachewrite
    cache.save(tag,params,debugger,spk,relt,fs,featdef,trialdef);
end

% post process prior to return (trial subselect, uniform output
[spk,relt,trialdef] = postprocess(spk,relt,trialdef,fs,trialidx,flagUniformOutput);



function [spk,relt,len,featdef,trialdef] = getTrialData(window,nv,lag,task,params,debugger)
% GETTRIALDATA Extract trials from full bin dataset
%
%   [SPK,RELT,LEN,FEATDEF] = GETTRIALDATA(WINDOW,NV,LAG,TASK,PARAMS,DEBUGGER)
%   Extract trials as defined by the FRAMEWORKTASK object TASK and return
%   in the cell arrays SPK and RELT, with the lengths of each trial in LEN.
%   Each cell of SPK contains a MxN matrix of M time points and N features;
%   each cell of RELT contains a Mx1 vector of time points. Each entry of
%   vector LEN contains the length (in seconds) of the trial.
[tm,len,trialdef] = proc.helper.trialTimeLength(window,task,params,debugger);
assert(~isempty(tm)&&all(isfinite(tm)),'Invalid window start times');
assert(~isempty(len)&&all(isfinite(len)),'Invalid window lengths');

% check whether recording file is abnormal (need to localize each data
% window to a single recording packet, or else throw an error)
blocks = cellfun(@(y)arrayfun(@(x)getBlocksContainingTime(y,x),tm,'UniformOutput',false),nv,'UniformOutput',false);
num = cellfun(@(x)cellfun(@length,x),blocks,'UniformOutput',false);
assert(all(cellfun(@(x)all(x<=1),num)),'One or more processing windows cannot be reliably located to a single recording packet');

% get trial data
args = {};
if params.spk.unsorted
    args = [args {'unsorted'}];
end
if params.spk.noise
    args = [args {'noise'}];
end
binwidth = params.spk.binwidth;
dtclass = params.dt.class;
[spk,relt,featdef,windef] = proc.blackrock.bin(nv,'binwidth',binwidth,'procwin',[tm(:) len(:)],'lag',lag,dtclass,'UniformOutput',false,debugger,args{:});
relt = cellfun(@(x)x - params.tm.bufferpre,relt,'UniformOutput',false); % align to window start

% update trialdef with relstart, reltend
rel_start = cellfun(@(x)x(1),relt,'UniformOutput',false);
rel_end = cellfun(@(x)x(end),relt,'UniformOutput',false);
trialdef = [trialdef(:,1:3) windef(:,1:2) cell2table([rel_start(:) rel_end(:)],'VariableNames',{'rel_start','rel_end'}) trialdef(:,4:end)];
featdef = [featdef cell2table(repmat({task.taskString},size(featdef,1),1),'VariableNames',{'task_id'})];



function [spk,relt,trialdef] = postprocess(spk,relt,trialdef,fs,trialidx,flagUniformOutput)
% POSTPROCESS Final steps to take before returning binned spike data
%
%   [SPK,RELT] = POSTPROCESS(SPK,RELT,FS,FLAGUNIFORMOUTPUT)
%   Subselect requested trials, and if requested convert to uniform output.

% subselect just the requested trials
% it is conceivable that trialTimeLength (in getTrialData) might have
% removed some trials, but we keep track of which ones in trialdef, so
% match up user-requested trialidx with the remaining trials from trialdef
% before subselecting just what the user requested.
idxselect = ismember(trialdef.trial,trialidx);
spk = spk(idxselect);
relt = relt(idxselect);
trialdef = trialdef(idxselect,:);

% enforce uniform output if requested
if flagUniformOutput
    p = 10^(floor(log10(fs))+2);
    [spk,relt] = proc.helper.createUniformOutput(spk,relt,'precision',p);
end