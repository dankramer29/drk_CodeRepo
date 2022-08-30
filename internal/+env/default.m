function val = default(name)
% ENV.DEFAULT store default values for any BLX environment variable
%
%   ENV.DEFAULT(NAME) returns the default value for BLX environment
%   variable NAME.  If NAME has no default specified, returns an empty
%   char.
%
%   See also ENV.CLEAR, ENV.DEP, ENV.EV, ENV.GET, ENV.LOCATION, ENV.PRINT,
%   ENV.SET, ENV.STR2NAME.

% handle default values for location separately
if strcmpi(name,'location')
    
    % get the computer name 
    cn = getComputerName;
    un = getUserName;
    
    % use the computer name to identify the location
    switch upper(cn)
        case {'AMADEUS','ARMSTRONG','DAVIS','DVORAK','JOPLIN','LISZT',...
                'MOZART','PARKER','PROKOFIEV'}
            val = sk.getDeviceUserID(cn);
        case 'DEEP-BRAIN'
            switch upper(un)
                case 'MATLAB_USER'
                    val = 'MATLAB_DEEPBRAIN';
                case 'ASTURIAS'
                    val = 'ASTURIAS_DEEPBRAIN';
            end
        case 'DANIEL-XPS'
            switch upper(un)
                case 'DANIEL'
                    val = 'DANIEL-UN';
            end
        case 'DELL-NI'
            switch upper(un)
                case 'USC'
                    val = 'DELL_USC';
            end
        case 'WORKSTATION-1'
            switch upper(un)
                case 'ROBERTO'
                    val = 'WORKSTATION_ROBERTO';
            end
        case 'DELL-7567'
            switch upper(un)
                case 'BLX'
                    val = 'DELL_LAPTOP_BLX';
            end
        case {'XPS-8920-MIKE', 'DESKTOP-U0FI7UQ'}
            val = 'MIKE_BARBARO';
        case 'CRUNCH-1'
            switch upper(un)
                case 'ROBERTO'
                    val = 'ROBERTO_CRUNCH1';
                case 'DKRAMER'
                    val = 'DAN_CRUNCH1';
                case 'MBARBARO'
                    val = 'MIKE_CRUNCH1';
                case 'SKELLIS'
                    val = 'SPENCER_CRUNCH1';
                case 'RSEBASTI'
                    val = 'RINU_CRUNCH1';
            end

        otherwise
            val = upper(cn);
            warning('No LOCATION specified for PC ''%s''; setting LOCATION to ''%s''',cn,val);
    end
else
    
    % DEFAULT VALUES
    default.code        = '.'; % path to code folder
    default.data        = {'\\STRIATUM\Data\neural'}; % path to data folder
    default.archive     = fullfile(default.data{1},'archive'); 
    default.map         = '.'; % path to map file folder
    default.output      = '.'; % path to output folder
    default.backup      = fullfile('.','backup'); % path to backup folder
    default.results     = '.'; % path to results folder
    default.cache       = {'.'};
    default.temp        = fullfile('.','temp'); % path to a temporary directory
    default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
    default.external    = fullfile(default.code,'external'); % path to code external folder
    default.internal    = fullfile(default.code,'internal'); % path to code internal folder
    default.media       = fullfile(default.code,'media'); % path to code media folder
    default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
    default.type        = 'DEVELOPMENT'; % 'PRODUCTION' or 'DEVELOPMENT'
    default.numproc     = getNumProcessor;
    default.debug       = 1; % debug level
    default.verbosity   = 1;
    default.verbosityScreen = Debug.PriorityLevel.WARNING; % verbosity level for screen output
    default.verbosityLogfile = Debug.PriorityLevel.INSANITY; % verbosity level for log file output
    default.ptbopacity  = 0.5; % opacity for PsychToolbox when in debug mode
    default.ptbhid      = 0; % allow HID inputs (mouse clicks etc.) through PTB window (logical; false->transparent, true->opaque)
    default.screenid    = 0;
    default.autoitpath  = fullfile('C:','Program Files (x86)','AutoIt3','AutoIt3.exe');
    default.nsps        = {'NSP1'};
    
    % screen size in pixels and inches
    set(0,'units','pixels');
    dres = get(0,'screensize');
    default.displayresolution = dres(3:4);
    set(0,'units','inches');
    dres = get(0,'screensize');
    default.monitorsize = dres(3:4);
    %default.hasgpu = parallel.gpu.GPUDevice.isAvailable;
    
    % default values depending on location
    location = getenv(env.str2name('location'));
    switch upper(location)
        case {'SPENCER_AMADEUS','SPENCER_ARMSTRONG','SPENCER_CRUNCH1','SPENCER_LISZT','SPENCER_PROKOFIEV'}
            default = sk.getEnvDefaults(location,default);
        case 'ASTURIAS_CRUNCH1'
            default.code        = 'C:\Research\dkramer\Documents\Code';
            default.data        = {'\\STRIATUM\Data\neural','C:\Data'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.results     = 'C:\Research\dkramer\Documents\Results';
            default.output      = 'C:\Research\dkramer\Documents\Output';
            default.backup      = 'C:\Research\dkramer\Documents\Backup';
            default.cache       = {'C:\Research\dkramer\Documents\cache'};
            default.temp        = 'C:\Research\dkramer\Documents\temp';
            default.ptb         = 'C:\Research\dkramer\Documents\Code\Psychtoolbox';
        case 'ASTURIAS_DEEPBRAIN'
            default.code        = 'C:\Users\asturias\Documents\Code';
            default.data        = {'\\STRIATUM\Data\neural','C:\Data'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.results     = 'C:\Users\asturias\Documents\Results';
            default.output      = 'C:\Users\asturias\Documents\Output';
            default.backup      = 'C:\Users\asturias\Documents\Backup';
            default.cache       = {'C:\Users\asturias\Documents\cache'};
            default.temp        = 'C:\Users\asturias\Documents\temp';
            default.ptb         = 'C:\Code\Psychtoolbox';
        case 'WORKSTATION_ROBERTO'  
            default.code = 'C:\Users\Roberto\Documents\Code';
            default.data = {'C:\Users\Roberto\Documents\DATA','\\STRIATUM\Data\neural'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
            default.results     = 'C:\Users\Roberto\Documents\results';
            default.output      = 'C:\Users\Roberto\Documents\output';
        case 'DANIEL-UN'
            default.code = 'C:\Users\Daniel\Documents\Code';
            default.data = {'C:\Users\Daniel\Documents\DATA','\\STRIATUM\Data\neural'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
            default.results     = 'C:\Users\Daniel\Documents\results';
            default.output      = 'C:\Users\Daniel\Documents\output';
        case 'DAN_CRUNCH1'
            default.code        = 'C:\Research\dkramer\Code';
            default.data        = {'\\STRIATUM\Data\neural','C:\Data'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.results     = 'C:\Research\dkramer\Results';
            default.output      = 'C:\Research\dkramer\Output';
            default.backup      = 'C:\Research\dkramer\Backup';
            default.cache       = {'C:\Research\dkramer\cache'};
            default.temp        = 'C:\Research\dkramer\temp';
            default.ptb         = 'C:\Research\dkramer\Code\Psychtoolbox';
            default.screenid    = 0;
        case 'ROBERTO_CRUNCH1'
            default.code        = 'C:\Research\Roberto';
            default.data        = {'\\STRIATUM\Data\neural','C:\Data'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.results     = 'C:\Research\Roberto\Results';
            default.output      = 'C:\Research\Roberto\Output';
            default.backup      = 'C:\Research\Roberto\Backup';
            default.cache       = {'C:\Research\Roberto\cache'};
            default.temp        = 'C:\Research\Roberto\temp';
            default.ptb         = 'C:\Research\Roberto\Psychtoolbox';
            default.screenid    = 0;
        case 'DELL_USC'
            default.code = 'C:\Users\USC\Documents\Code';
            default.data = {'C:\Users\USC\Documents\Data'};
            default.output = 'C:\Users\USC\Documents\Output'; % path to output folder
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
        case 'DELL_LAPTOP_BLX'
            default.type        = 'PRODUCTION';
            default.code        = 'C:\Users\BLX\Documents\Code';
            default.data        = {'C:\Users\BLX\Documents\Data'};
            default.output      = 'C:\Output';
            default.analysis    = fullfile(default.code,'analysis');
            default.external    = fullfile(default.code,'external');
            default.internal    = fullfile(default.code,'internal');
            default.media       = fullfile(default.code,'media');
            default.ptb         = fullfile(default.code,'Psychtoolbox');
            default.ptbopacity  = 1.0;
            default.ptbhid      = 1;
            default.screenid    = 2;
        case {'MATLAB_DEEPBRAIN'}
            default.code = 'C:\Code';
            default.data = {'\\STRIATUM\Data\neural','C:\Data','C:\Keck'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
        case 'MIKE_CRUNCH1'
            default.code        = 'C:\Users\mbarbaro\Documents\Code';
            default.data        = {'\\STRIATUM\Data\neural','C:\Data'};
            default.results     = 'C:\Users\mbarbaro\Documents\Results';
            default.output      = 'C:\Users\mbarbaro\Documents\Output';
            default.backup      = 'C:\Users\mbarbaro\Documents\Backup';
            default.cache       = {'C:\Users\mbarbaro\Documents\cache'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.temp        = 'C:\Users\mbarbaro\Documents\temp';
            default.ptb         = 'C:\Users\mbarbaro\Documents\Code\Psychtoolbox';
            default.screenid    = 0;
        case {'MIKE_BARBARO'}
            un                  = getUserName;
            default.screenid    = 2;
            default.ptbopacity  = 1.0;
            default.ptbhid      = 1;
            default.debug       = 0;
            default.code        = sprintf('C:\\Users\\%s\\Documents\\Code',un);
            default.data        = {sprintf('C:\\Users\\%s\\Documents\\Data',un)};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = sprintf('C:\\Users\\%s\\Psychtoolbox', un); % path to psychtoolbox folder
            default.results     = sprintf('C:\\Users\\%s\\Documents\\results', un);
            default.output      = sprintf('C:\\Users\\%s\\Documents\\output', un);
        case {'MIKE_BARBARO2'}
            default.debug       = 0;
            default.ptbhid      = 1;
            default.screenid    = 1;
            default.results     = 'C:\Users\mbarb\Documents\results';
            default.output      = 'C:\Users\mbarb\Documents\output';
            default.code = 'C:\Users\mbarb\Documents\Code';
            default.data = {'C:\Users\mbarb\Documents\Data'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
        case {'RINU_CRUNCH1'}
            default.code = 'C:\Research\rsebasti\Code';
            default.data = {'\\STRIATUM\Data\neural','C:\Research\rsebasti\Data','C:\Keck'};
            default.analysis    = fullfile(default.code,'analysis'); % path to code analysis folder
            default.external    = fullfile(default.code,'external'); % path to code external folder
            default.internal    = fullfile(default.code,'internal'); % path to code internal folder
            default.media       = fullfile(default.code,'media'); % path to code media folder
            default.ptb         = fullfile(default.code,'psychtoolbox'); % path to psychtoolbox folder
    end
    
    % make sure all fieldnames are lower case
    default = lowerfields(default);
    
    % retrieve the default value; empty+warning if none
    name = lower(name);
    if ~isfield(default,name)
        val = '';
    else
        val = default.(name);
    end
end

function st = lowerfields(in)
names = fieldnames(in);
for kk=1:length(names)
    st.(lower(names{kk})) = in.(names{kk});
end

function cn = getComputerName
% returns the name of the computer.
if ispc,        cn = getenv('computername');
elseif isunix,  cn = getenv('hostname');
end
if isempty(cn)
    if ismac || isunix
        [~,cn] = system('hostname');
        cn = deblank(cn);
    else
        error('Unable to identify the computer hostname');
    end
end

function un = getUserName
% returns the name of the computer.
if ispc,        un = getenv('username');
elseif isunix,  un = getenv('user');
end
if isempty(un)
    if ismac || isunix
        [~,un] = system('whoami');
        un = deblank(un);
    else
        error('Unable to identify the computer hostname');
    end
end

function N = getNumProcessor
% returns number of processors
% credit - Iain Murray, March 2011
% http://homepages.inf.ed.ac.uk/imurray2/code/imurray-matlab/num_cores.m
N = 1;
% Undocumented Matlab routine.
% Could disappear and not currently (2011-03-06) in Octave:
% N = feature('numCores'); % 2015b returns # physical cores, not logical
try
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
catch ME
    util.errorMessage(ME);
end