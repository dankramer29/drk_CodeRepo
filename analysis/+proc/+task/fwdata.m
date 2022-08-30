function [fd,relt,featdef,trialdef] = fwdata(task,params,debugger,varargin)
% FWDATA Pull out framework variables in trial blocks
%
%   [FV,RELT,FEATDEF,TRIALDEF] = FWDATA(TASK,PARAMS,DEBUGGER)
%   For the task represented by FRAMEWORKTASK object TASK, parameters
%   defined by PARAMETERS.DYNAMIC object PARAMS, and debugging object 
%   DEBUGGER, pull out trial-blocked framework variables FV and relative
%   (to trial timing) time indices RELT for all trials. Also return FEATDEF
%   which describes the source of each variable, and TRIALDEF which
%   describes the source of each trial (depending on UNIFORMOUTPUT below).
%
%   [...] = FWDATA(...,'UNIFORMOUTPUT',TRUE|FALSE)
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
%     DT.CACHEREAD - whether to read data from cache if available
%     DT.CACHEWRITE - whether to write data into the cache
%     DT.CLASS - the data class to use (e.g., 'double' or 'single')
%     FWD.SMOOTH - whether to smooth the data
%     FWD.SMOOTHMETHOD - method to use for smoothing the data
%     FWD.SMOOTHPARAMS - parameters to use when smoothing the data
%     FWD.NORM - whether to normalize the data
%     FWD.NORMMETHOD - method to use for normalizing the data
%     FWD.NORMPARAMS - parameters to use when normalizing the data
%     FWD.NORMSRC - source of the baseline for normalization
%     FWD.TIMEAVG - whether to time-average the trial data
%     FWD.RESAMPLE - whether to resamle the data
%     FWD.RESAMPLEMETHOD - method to use for resamling the data
%     FWD.RESAMPLEPARAMS - parameters to use when resampling the data
%
%   See also PARAMETERS.VALIDATE, CACHE.QUERY, CACHE.LOAD, CACHE.SAVE,
%   FRAMEWORKTASK, PARAMETERS.DYNAMIC.
Parameters.validate(params,mfilename('fullpath'));

% uniform output
[varargin,flagUniformOutput] = util.argkeyval('UniformOutput',varargin,true);

% framework variable list
vars = fieldnames(task.data);
rows = cellfun(@(x)size(task.data.(x),1),vars);
vars(rows~=median(rows)) = [];
[varargin,vars] = util.argkeyval('vars',varargin,vars);
util.argempty(varargin);
vars = util.ascell(vars);
rows = cellfun(@(x)size(task.data.(x),1),vars);
assert(numel(unique(rows))==1,'All variables must have same number of rows');
for kk=1:length(vars)
    assert(isfield(task.data,vars{kk}),'Could not find framework variable "%s"',vars{kk});
    assert(size(task.data.(vars{kk}),1)==unique(rows),'Framework variable "%s" has %d rows, but expected %d',size(task.data.(vars{kk}),1),unique(rows));
end

% construct the hash string to represent this dataset in the cache
tag = proc.helper.getCacheTag(task,mfilename,'baseline',params.tm.baseline,'analysis',params.tm.analysis,'vars',vars);

% check whether data is cached, and if so load it
set_require = list(params,'dt','tm','fwd');
set_except = {'dt.cacheread','dt.cachewrite','dt.mintrials'};
[cached,valid] = cache.query(tag,params,debugger,'require',set_require,'except',set_except);
if cached && valid && params.dt.cacheread
    [fd,relt,fs,featdef,trialdef] = cache.load(tag,debugger);
    
    % post process: subselect trials, uniform output
    if iscell(fd)
        [fd,relt] = postprocess(fd,relt,fs,flagUniformOutput);
        return;
    end
end

% get spike timing and firing rates
local_tmr = tic;
analysis = params.tm.analysis;
[fd,relt,len,featdef,trialdef] = getTrialData(analysis,vars,task,params,debugger);
fs = proc.helper.getFsFromRelt(relt);

% smooth
if params.fwd.smooth
    smoothmth = params.fwd.smoothmethod;
    smoothprm = params.fwd.smoothparams;
    smoothprm.period = 1/fs;
    debugger.log(sprintf('Smoothing the data: %s',util.any2str(smoothmth)),'info');
    fd = cellfun(@(x)proc.smooth(x,smoothmth,smoothprm),fd,'UniformOutput',false);
end

% remove extra data from beginning/end of data
analysis_idx_keep = cellfun(@(x,y)x>=(x(1)+params.tm.discardpre) & x<=(y+params.tm.bufferpost-params.tm.discardpost),relt(:),arrayfun(@(x)x,len,'UniformOutput',false),'UniformOutput',false);
assert(all(cellfun(@any,analysis_idx_keep)),'No data left: need to adjust discardpre/discardpost');
fd = cellfun(@(x,y)x(y,:),fd(:),analysis_idx_keep(:),'UniformOutput',false);
relt = cellfun(@(x,y)x(y),relt(:),analysis_idx_keep(:),'UniformOutput',false);
assert(all(cellfun(@(x)diff(x([1 end]))>=params.tm.min,relt)),'Insufficient data remaining to continue');

% normalize
if params.fwd.norm
    normmth = params.fwd.normmethod;
    normprm = params.fwd.normparams;
    if strcmpi(params.fwd.normsrc,'baseline')
        assert(~isempty(baseline_fv),'Cannot normalize to baseline unless baseline phase provided');
        ref = baseline_fv;
    else
        ref = fd;
    end
    debugger.log(sprintf('Normalizing the data: %s',util.any2str(normmth)),'info');
    fd = cellfun(@(x,y)util.normref(x,y,1,normmth,normprm),fd,ref,'UniformOutput',false);
end

% time-average
if params.fwd.timeavg
    if params.fwd.norm && strcmpi(params.fwd.normmethod,'zscore') && strcmpi(params.fwd.normsrc,'same')
        debugger.log('These data were just z-scored, so averaging will produce all zeros!','warn');
    end
    debugger.log('Time-averaging the data','info');
    fd = cellfun(@(x)squeeze(nanmean(x,1)),fd,'UniformOutput',false); % average over time
end

tm=toc(local_tmr);
debugger.log(sprintf('Took %.2f seconds to generate data from scratch',tm),'debug');

% place raw data into cache
if params.dt.cachewrite
    cache.save(tag,params,debugger,fd,relt,fs,featdef,trialdef);
end

% post process prior to return (trial subselect, uniform output
[fd,relt] = postprocess(fd,relt,fs,flagUniformOutput);



function [fd,relt,len,featdef,trialdef] = getTrialData(window,vars,task,params,debugger)
% GETTRIALDATA Extract trials from full fw variable dataset
%
%   [FV,RELT,LEN,FEATDEF] = GETTRIALDATA(WINDOW,FWVARS,TASK,PARAMS,DEBUGGER)
%   Extract trials as defined by the FRAMEWORKTASK object TASK and return
%   in the cell arrays FV and RELT, with the lengths of each trial in LEN.
%   Each cell of FV contains a MxN matrix of M time points and N variables;
%   each cell of RELT contains a Mx1 vector of time points. Each entry of
%   vector LEN contains the length (in seconds) of the trial.
[tm,len] = proc.helper.trialTimeLength(window,task,params,debugger);
idxKeep = find(~isnan(tm)&~isnan(len));
if isempty(idxKeep),warning('No trials kept');end
tm = tm(idxKeep);
len = len(idxKeep);
bhv = task.trialdata(idxKeep);

% create trialdef
trialdef = arrayfun(@(w,x,y,z){w,x,y,z},idxKeep(:),tm(:),len(:),bhv(:),'UniformOutput',false);
trialdef = cell2table(cat(1,trialdef{:}),'VariableNames',{'trial','time','length','behavioral'});

% get the data
tm = tm(:)-params.tm.bufferpre;
len = len(:)+params.tm.bufferpre+params.tm.bufferpost;
args = {};
if params.fwd.resample
    resampmth = params.fwd.resamplemethod;
    resampprm = params.fwd.resampleparams;
    resampprm.binwidth = task.options.timerPeriod;
    args = [args {'resample',resampmth,'binwidth',resampprm.binwidth}];
end
[fd,relt,featdef] = proc.framework.fwdata(task,debugger,'procwin',[tm(:) len(:)],...
    'vars',vars,'UniformOutput',false,args{:});
relt = cellfun(@(x)x-params.tm.bufferpre,relt,'UniformOutput',false);



function [fd,relt] = postprocess(fd,relt,fs,flagUniformOutput)
% POSTPROCESS Final steps to take before returning binned spike data
%
%   [SPK,RELT] = POSTPROCESS(SPK,RELT,FS,FLAGUNIFORMOUTPUT)
%   Subselect requested trials, and if requested convert to uniform output.

% enforce uniform output if requested
if flagUniformOutput
    p = 10^(floor(log10(fs))+2);
    [fd,relt] = proc.helper.createUniformOutput(fd,relt,'precision',p);
end