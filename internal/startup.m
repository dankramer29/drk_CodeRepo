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
clear N ans str


% user-specific defines
def.ptbdir = '../PsychToolbox'; % full path to PsychToolbox folder
def.repodirs = {'internal','analysis','experiments'}; % git repositories - expected as subdirs of env.get('code')
def.userdirs = {}; % list of user folders to add to path
switch upper(un)
    case {'SPENCER','SKELLIS','SPENC'}
        addpath('../research-usc');
        def = sk.startup(cn,un,def);
    case {'SHERRY'}
        def.repodirs = [def.repodirs {'sherry'}];
    case {'ROBERTO'}
        def.repodirs = [def.repodirs {'roberto'}]; % Format to add more repositories: def.repodirs = [def.repodirs {'repo1','repo2','repoX'}];
        % To add a folder outside the repo folder: def.userdirs = {'Full path 1','Full path 2'}
    case 'MATLAB_USER'
        % nothing to do
    otherwise
        warning('No setup for user "%s"',un);        
end

% validate def
assert(isfield(def,'ptbdir'),'Must set the "ptbdir" field on def');
if ~isfield(def,'userdirs')
    def.userdirs = {};
else
    if ~iscell(def.userdirs)
        def.userdirs = {def.userdirs};
    end
    assert(all(cellfun(@ischar,def.userdirs)),'All userdirs entries must be char');
end


%% setup python
tmr = tic;
condapath = env.get('python');
if exist(condapath,'file')==2
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
    fprintf(' -python       (%.2f sec)\n',toc(tmr));
    clear condapath
end


%% PsychToolbox
tmr = tic;
if exist(def.ptbdir,'dir')~=7
    warning('Could not find PsychToolbox folder');
    ptbpath = {};
else
    ptbfolders = dir(def.ptbdir);
    ptbpath = cell(1,length(ptbfolders));
    for dd=1:length(ptbfolders)
        if ~ptbfolders(dd).isdir,continue;end
        if strcmpi(ptbfolders(dd).name,'.svn'),continue;end
        if strcmpi(ptbfolders(dd).name,'.')||strcmpi(ptbfolders(dd).name,'..'),continue;end
        ptbpath{dd} = genpath(fullfile(def.ptbdir,ptbfolders(dd).name));
    end
    ptbpath = [{fullfile(def.ptbdir,'PsychBasic','MatlabWindowsFilesR2007a')} ptbpath];
    ptbpath(cellfun(@isempty,ptbpath)) = [];
    clear ptbfolders
end
fprintf(' +psychtoolbox (%.2f sec)\n',toc(tmr));


%% repos
tmr = tic;
repodirs = cell(1,length(def.repodirs));
for dd=1:length(def.repodirs)
    assert(exist(fullfile(env.get('code'),def.repodirs{dd}),'dir')==7,'Could not locate repo dir "%s"',def.repodirs{dd});
    repodirs{dd} = fullfile(env.get('code'),def.repodirs{dd});
end
repodirs(cellfun(@isempty,repodirs)) = [];
fprintf(' +repos        (%.2f sec)\n',toc(tmr));
clear dd tmr


%% user folders
tmr = tic;
cellfun(@(x)assert(exist(x,'dir')==7,'Could not locate user directory "%s"',x),def.userdirs);
fprintf(' +user         (%.2f sec)\n',toc(tmr));


%% addpath
tmr = tic;
allpath = [repodirs(:); ptbpath(:); def.userdirs(:); {pypath};];
addpath(allpath{:});
if exist('PsychStartup','file')==2,evalc('PsychStartup');end
fprintf(' +path         (%.2f sec)\n',toc(tmr));
clear ans repodirs ptbpath pypath allpath tmr def


%% report total time
fprintf(' #done ------+ (%.2f sec)\n',toc(tmr_global));
clear cn un tmr_global;