function [ts,relt,fs,featdef,trialdef] = timestamps(task,params,debugger,varargin)
% TRIALTIMESTAMPS Collect spike timestamps for whole trials
%
%   [TS,RELT,FEATDEF,FEATLBL] = TIMESTAMPS(TASK,PARAMS,DEBUGGER)
%   For the task represented by FRAMEWORKTASK object TASK and parameters
%   defined by PARAMETERS.DYNAMIC object PARAMS, collect spike timestamps
%   TS all trials in TASK and return the relative timing of the trials in
%   RELT.  Also return the sampling frequency FS and FEATDEF and FEATLBL
%   which describe the source of each feature.
%
%   TIMESTAMPS(...,TRIALIDX)
%   Specify which trials to process.  TRIALIDX can be defined logically or
%   numerically indexed.
%
%   See also FRAMEWORKTASK, PARAMETERS.DYNAMIC.
Parameters.validate(params,mfilename('fullpath'));

% process inputs
[varargin,flagSparseOutput] = util.argflag('sparse',varargin,false);
[varargin,flagUniformOutput] = util.argkeyval('UniformOutput',varargin,true);
[trialidx,~,varargin] = proc.helper.trialIndices(varargin,task,params,debugger);
util.argempty(varargin);

% construct the hash string to represent this dataset in the cache
tag = proc.helper.getCacheTag(task,mfilename,'analysis',params.tm.analysis);

% check whether data is cached, and if so load it
set_require = list(params,'dt','spk','tm');
set_except = {'dt.cacheread','dt.cachewrite','dt.mintrials'};
[cached,valid] = cache.query(tag,params,debugger,'require',set_require,'except',set_except);
if cached && valid && params.dt.cacheread
    [ts,relt,fs,featdef,trialdef] = cache.load(tag,debugger);
    
    % post process: subselect trials, uniform output
    if iscell(ts)
        [ts,relt,trialdef] = postprocess(ts,relt,fs,trialdef,trialidx,flagSparseOutput,flagUniformOutput);
        return;
    end
end

% get the NSx objects
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

% get baseline timing and spectrogram
local_tmr = tic;
analysis = params.tm.analysis;
[ts,relt,fs,featdef,trialdef] = getTrialData(analysis,nv,lag,task,params,debugger);

% update on timing
tm=toc(local_tmr);
debugger.log(sprintf('Took %.2f seconds to generate data from scratch',tm),'debug');

% place raw data into cache
if params.dt.cachewrite
    cache.save(tag,params,debugger,ts,relt,fs,featdef,trialdef);
end

% post process prior to return (trial subselect, uniform output
[ts,relt,trialdef] = postprocess(ts,relt,fs,trialdef,trialidx,params,task,flagSparseOutput,flagUniformOutput);




function [ts,relt,fs,featdef,trialdef] = getTrialData(window,nv,lag,task,params,debugger)
% GETTIMESTAMPTRIALDATA Extract trials from full bin dataset
%
%   [TS,RELT,LEN] = GETTIMESTAMPTRIALDATA(WINDOW,NV,LAG,TASK,PARAMS,DEBUGGER)
%   Extract trials as defined by the FRAMEWORKTASK object TASK and return
%   in the cell arrays TS and RELT, with the lengths of each trial in LEN.
%   Each cell of TS contains a MxN matrix of M time points and N features;
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
dtclass = params.dt.class;
[ts,featdef,windef] = proc.blackrock.timestamps(nv,'procwin',[tm(:) len(:)],'lag',lag,dtclass,'UniformOutput',false,debugger,args{:});
fs = unique(cellfun(@(x)x.ResolutionTimestamps,nv));
relt = arrayfun(@(x)round (-(params.tm.bufferpre*fs):((x-params.tm.bufferpre)*fs-1))',len,'UniformOutput',false);

% update trialdef with relstart, reltend
rel_start = cellfun(@(x)x(1)/fs,relt,'UniformOutput',false);
rel_end = cellfun(@(x)x(end)/fs,relt,'UniformOutput',false);
trialdef = [trialdef(:,1:3) windef cell2table([rel_start(:) rel_end(:)],'VariableNames',{'rel_start','rel_end'}) trialdef(:,4:end)];



function [ts,relt,trialdef] = postprocess(ts,relt,fs,trialdef,trialidx,params,task,flagSparseOutput,flagUniformOutput)
% POSTPROCESS Final steps to take before returning data
%
%   [V,RELT] = POSTPROCESS(V,RELT,TRIALIDX,FLAGUNIFORMOUTPUT)
%   Subselect requested trials, and if requested convert to uniform output.

% subselect just the requested trials
% it is conceivable that trialTimeLength (in getTrialData) might have
% removed some trials, but we keep track of which ones in trialdef, so
% match up user-requested trialidx with the remaining trials from trialdef
% before subselecting just what the user requested.
idxselect = ismember(trialdef.trial,trialidx);
ts = ts(idxselect);
relt = relt(idxselect);
trialdef = trialdef(idxselect,:);

% enforce uniform output if requested
if flagUniformOutput
    
    % find the shortest trial segment
    minrelt = min(cellfun(@(x)x(end),relt));    
    for kk=1:length(ts) % remove timestamps greater than minrelt
        
        ts{kk}=cellfun(@(x)x-(params.tm.bufferpre*task.eventFs),ts{kk}, 'UniformOutput',false);
        ts{kk} = cellfun(@(x)x(x<=minrelt),ts{kk},'UniformOutput',false);
        relt{kk}(relt{kk}>minrelt) = [];
        trialdef.rel_end(kk) = relt{kk}(end)/fs;
    end
end

% convert to sparse output if requested
if flagSparseOutput
    numProcwin = length(relt);
    numFeatures = unique(cellfun(@length,ts));
    assert(length(numFeatures)==1,'Should be same number of features in each trial');
    for kk=1:numProcwin
        numTimestamps = length(relt{kk});
        ts{kk} = proc.helper.ts2sparse(ts{kk},'numsamples',numTimestamps);
        relt{kk} = relt{kk}(1) + (0:numTimestamps-1)';
    end
    ts = ts(:);
    relt = relt(:);
end

% reduce time vector now
if flagUniformOutput
    relt = relt{1};
end