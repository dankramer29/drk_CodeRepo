%% global timer
tmr_global = tic;

%% computer and user names
tmr = tic;
if ispc
    cn = getenv('computername');
    un = getenv('username');
elseif isunix
    cn = getenv('hostname');
    un = getenv('user');
end
if isempty(cn) && (ismac || isunix)
    [~,cn] = system('hostname');
    cn = deblank(cn);
end
assert(~isempty(cn),'Unable to identify the computer hostname');
if isempty(cn) && (ismac || isunix)
    [~,un] = system('whoami');
    un = deblank(un);
end
assert(~isempty(un),'Unable to identify the computer hostname');

%% root folders
% primarily, we need to get the location of hst and psychtoolbox folders
switch upper(cn)
    case 'LOCALPC'
        switch upper(un)
            case 'LOCALUSER'
                addpath('C:\Users\LOCALUSER\Documents\Code\internal');
                ptbdir = env.get('ptb');
            otherwise
                error('unknown user "%s"',un);
        end
    case 'CRUNCH-1'
        switch upper(un)
            case 'CRUNCHUSER'
                addpath('C:\Research\CRUNCHUSER\Code\internal');
                ptbdir = env.get('ptb');
            otherwise
                error('unknown user "%s"',un);
        end
    otherwise
        return;
end

%% computation threads
% this is NOT for parfor - this is for multithreading:
% https://www.mathworks.com/matlabcentral/answers/95958-which-matlab-functions-benefit-from-multithreaded-computation
% credit - Iain Murray, March 2011
% http://homepages.inf.ed.ac.uk/imurray2/code/imurray-matlab/num_cores.m
N = nan;
if exist('/proc/cpuinfo', 'file')
    % Should work on Linux in Matlab and Octave:
    fid = fopen('/proc/cpuinfo');
    N = length(strfind(char(fread(fid)'), ['processor' 9]));
    fclose(fid);
elseif ispc
    % Windows is untested
    N = str2double(getenv('NUMBER_OF_PROCESSORS'));
elseif ismac
    % Mac is untested
    [~, output] = system('sysctl hw.ncpu | awk ''{print $2}''');
    N = str2double(output);
end
if isnumeric(N) && isscalar(N) && isfinite(N) && N>0
    maxNumCompThreads(N);
    str = sprintf('+%d threads',N);
else
    str = '-threads';
end
fprintf('%s\\%s %s (%.2f sec)\n',cn,un,str,toc(tmr));
clear cn un N ans str

%% PsychToolbox
tmr = tic;
if exist(ptbdir,'dir')~=7
    warning('Could not find PsychToolbox folder');
    ptbpath = {};
else
    ptbfolders = dir(ptbdir);
    ptbpath = cell(1,length(ptbfolders));
    for dd=1:length(ptbfolders)
        if ~ptbfolders(dd).isdir,continue;end
        if strcmpi(ptbfolders(dd).name,'.svn'),continue;end
        if strcmpi(ptbfolders(dd).name,'.')||strcmpi(ptbfolders(dd).name,'..'),continue;end
        ptbpath{dd} = genpath(fullfile(ptbdir,ptbfolders(dd).name));
    end
    ptbpath = [{fullfile(ptbdir,'PsychBasic','MatlabWindowsFilesR2007a')} ptbpath];
    ptbpath(cellfun(@isempty,ptbpath)) = [];
end
fprintf(' +psychtoolbox (%.2f sec)\n',toc(tmr));
clear ptbdir ptbfolders

%% code folders
% (except hst which was already added above)
tmr = tic;
codefolders = dir(env.get('code'));
codepath = cell(1,length(codefolders));
for dd=1:length(codefolders)
    if ~codefolders(dd).isdir,continue;end
    if strcmpi(codefolders(dd).name,'PsychToolbox'),continue;end
    if strcmpi(codefolders(dd).name,'.')||strcmpi(codefolders(dd).name,'..'),continue;end
    codepath{dd} = fullfile(env.get('code'),codefolders(dd).name);
end
codepath(cellfun(@isempty,codepath)) = [];
fprintf(' +code         (%.2f sec)\n',toc(tmr));
clear codefolders dd tmr

%% setup python
tmr = tic;
condapath = env.get('python');
if ~isempty(condapath) && exist(condapath,'file')==2
    [version,exec] = pyversion;
    if ~strcmp(version,'3.6') || ~contains(exec,'Miniconda')
        pyversion(condapath);
    end
    pypath = fullfile(env.get('external'),'zmq_protobuf');
    if count(py.sys.path,pypath) == 0
        insert(py.sys.path,int32(0),pypath);
    end
    py.importlib.import_module('think_raw_wrapper');
    fprintf(' +python       (%.2f sec)\n',toc(tmr));
    clear version exec condapath
else
    pypath = '';
    clear condapath
end

%% addpath
tmr = tic;
allpath = [codepath(:); ptbpath(:); {pypath};];
addpath(allpath{:});
if exist('PsychStartup','file')==2,evalc('PsychStartup');end
fprintf(' +path         (%.2f sec)\n',toc(tmr));
clear codepath ptbpath pypath allpath tmr

%% report total time
fprintf(' #done ------+ (%.2f sec)\n',toc(tmr_global));
clear tmr_global;