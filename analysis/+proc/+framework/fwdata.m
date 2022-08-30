function [fd,relt,featdef,procdef] = fwdata(task,varargin)
% FWDATA Collect framework data
%
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(TASK)
%   Generate MxN matrix FD containing framework data, extracted in M bins
%   (end time of each bin indicated in RELT), and for N framework data
%   variables. The N-row matrix FEATDEF define the source of each feature.
%   By default, processes all available data from the framework.
%
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(...,'VARS',VARLIST)
%   Specify the list of framework variables to include in the output.
%
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(...,'PROCWIN',PROCWIN)
%   Specify one or more time ranges in which to group data in PROCWIN, a
%   Kx2 matrix where each row defines the start and length of a window.
%
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(...,'RESAMPLE',RESAMPLE_METHOD)
%   Resample the data to an even sampling rate, as opposed to the jittery
%   timestamps associated with raw data. Valid options for RESAMPLE_METHOD
%   include 'none' (default) or 'interp'.
%
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(...,'UNIFORMOUTPUT',TRUE|FALSE)
%   Specify whether to enforce uniform outputs, i.e., all channels/windows
%   the same size and concatenated into matrices, or to force cell array
%   output. If FALSE, C and RELT will be cell arrays. Otherwise, they
%   will be matrix and vector respectively.
%
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(...,'LOGFCN',LOGFN)
%   [FD,RELT,FEATDEF,PROCDEF] = FWDATA(...,DBG)
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

% get the log function
[varargin,logfcn] = proc.helper.getLogFcn(varargin);

% framework variable list
vars = fieldnames(task.data);
rows = cellfun(@(x)size(task.data.(x),1),vars);
vars(rows~=median(rows)) = [];
[varargin,vars] = util.argkeyval('vars',varargin,vars);

% process remaining variable inputs
[varargin,flagUniformOutput] = util.argkeyval('UniformOutput',varargin,false);
[varargin,resample] = util.argkeyval('resample',varargin,'none');
[varargin,binwidth] = util.argkeyval('binwidth',varargin,task.options.timerPeriod);
[varargin,procwin] = util.argkeyval('procwin',varargin,[task.data.neuralTime(1) diff(task.data.neuralTime([1 end]))]);

% validation
vars = util.ascell(vars);
rows = cellfun(@(x)size(task.data.(x),1),vars);
assert(numel(unique(rows))==1,'All variables must have same number of rows');
for kk=1:length(vars)
    assert(isfield(task.data,vars{kk}),'Could not find framework variable "%s"',vars{kk});
    assert(size(task.data.(vars{kk}),1)==unique(rows),'Framework variable "%s" has %d rows, but expected %d',size(task.data.(vars{kk}),1),unique(rows));
end
util.argempty(varargin);
assert(~strcmpi(resample,'none')|~flagUniformOutput,'Cannot enforce uniform output when resampling is disabled (uneven samling leads to different lengths for equal times)');

% create featdef
cols = cellfun(@(x)size(task.data.(x),2),vars);
reppedvars = arrayfun(@(x)repmat(vars(x),cols(x),1),1:length(cols),'UniformOutput',false);
reppedcols = arrayfun(@(x)(1:x)',cols,'UniformOutput',false);
reppedcols = arrayfun(@(x)x,cat(1,reppedcols{:}),'UniformOutput',false);
feat = arrayfun(@(x)x,(1:sum(cols))','UniformOutput',false);
featdef = struct('feature',feat,'var',cat(1,reppedvars{:}),'srccol',reppedcols);
featdef = struct2table(featdef);

% get trial data
fd = cell(1,size(procwin,1));
relt = cell(1,size(procwin,1));
neuraltm = task.data.neuralTime;
for kk=1:size(procwin,1)
    proc.helper.log(logfcn,sprintf('Processing win %d/%d',kk,size(procwin,1)),'debug');
    
    % find the indices just before and just after the procwin
    if neuraltm(1)<procwin(kk,1)
        st = find(neuraltm<procwin(kk,1),1,'last');
    else
        st = 1;
    end
    if neuraltm(end)>sum(procwin(kk,:))
        lt = find(neuraltm>sum(procwin(kk,:)),1,'first');
    else
        lt = length(neuraltm);
    end
    assert(lt>st,'Could not identify neural time indices containing procwin range [%.2f %.2f]',procwin(kk,1),sum(procwin(kk,:)));
    
    % pull out the matching indices
    switch lower(resample)
        case 'interp'
            relt{kk} = procwin(kk,1):binwidth:sum(procwin(kk,:));
            idx_relt = relt{kk}>=neuraltm(1) & relt{kk}<=neuraltm(end);
            first_nonzero = find(idx_relt,1,'first');
            last_nonzero = find(idx_relt,1,'last');
            if ~any(nnz(idx_relt))
                fd{kk} = cellfun(@(x)nan(length(relt{kk}),size(task.data.(x),2),class(task.data.(x))),'UniformOutput',false);
            else
                fd{kk} = cellfun(@(x)[...
                    nan(first_nonzero-1,size(task.data.(x),2),class(task.data.(x)));
                    interp1(neuraltm(st:lt),task.data.(x)(st:lt,:),relt{kk}(idx_relt));
                    nan(length(relt{kk})-last_nonzero,size(task.data.(x),2),class(task.data.(x)))],...
                    vars,'UniformOutput',false);
                fd{kk} = cat(2,fd{kk}{:});
            end
        case 'none'
            relt{kk} = neuraltm(st:lt);
            fd{kk} = cellfun(@(x)task.data.(x)(st:lt,:),vars,'UniformOutput',false);
            fd{kk} = cat(2,fd{kk}{:});
        otherwise
            error('unknown resample value "%s"',resample);
    end
end

% here is where we actually make relt a relative timing vector
% subtract off the first element
relt = cellfun(@(x)x - x(1),relt,'UniformOutput',false);

% create procdef
procdef = cell2table(...
    [arrayfun(@(x)x,procwin(:,1),'UniformOutput',false) ...
    arrayfun(@(x)sum(procwin(x,:)),1:size(procwin,1),'UniformOutput',false) ...
    cellfun(@(x)x(1),relt,'UniformOutput',false) ...
    cellfun(@(x)x(end),relt,'UniformOutput',false)],...
    'VariableNames',{'win_start','win_end','rel_start','rel_end'});

% pull out of cell array if just one processing window
if flagUniformOutput
    [fd,tmprelt,idx] = proc.helper.createUniformOutput(fd,relt);
    for kk=1:length(idx)
        tmp = relt{kk}(idx{kk});
        procdef.WinStart(kk) = procdef.win_start(kk) + (tmp(1) - relt{kk}(1));
        procdef.WinEnd(kk) = procdef.win_end(kk) - (relt{kk}(end) - tmp(end));
    end
    relt = tmprelt;
end