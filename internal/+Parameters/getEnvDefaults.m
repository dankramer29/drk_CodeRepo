function default = getEnvDefaults(loc,default)
% default environment variables for my personal accounts

% common to all locations
default.researcher  = 'spencer';
default.project     = 'rp';
default.type        = 'DEVELOPMENT';
default.arrays      = {'SIM1'};
default.opengl      = 'hardware';
default.subject     = 'P3';
default.ptbopacity  = 0.5;
default.ptbhid      = 0;
default.debug       = 1;
default.verbosity   = Debug.PriorityLevel.INFO;
default.verbosityScreen = Debug.PriorityLevel.INFO;
default.verbosityLogfile = Debug.PriorityLevel.INSANITY;

% screen size in pixels and inches
set(0,'units','pixels');
dres = get(0,'screensize');
default.displayresolution = dres(3:4);
set(0,'units','inches');
dres = get(0,'screensize');
default.monitorsize = dres(3:4);
default.hasgpu = parallel.gpu.GPUDevice.isAvailable;

% location-dependent properties
switch upper(loc)
    case 'SPENCER_AMADEUS'
        default.code        = 'C:\Users\spenc\Documents\Code';
        default.data        = {'C:\Users\spenc\Documents\Data\Caltech'};
        default.results     = 'C:\Users\spenc\Documents\Results';
        default.map         = 'C:\Users\spenc\Documents\Data\Caltech\MapFiles';
        default.output      = 'C:\Users\spenc\Documents\Share';
        default.backup      = 'C:\Users\spenc\Documents\Backup';
        default.cache       = {'C:\Users\spenc\Documents\cache'};
        default.temp        = 'C:\Users\spenc\Documents\temp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        if exist('Screen','file')==3
            screenids = Screen('Screens');
            default.screenid = max(screenids);
        else
            default.screenid = 0;
        end
        
    case 'SPENCER_ARMSTRONG'
        default.code        = 'C:\Users\Spencer\Documents\Code_Caltech';
        default.data        = {'C:\Users\Spencer\Documents\Data'};
        default.results     = 'C:\Users\Spencer\Documents\Results';
        default.map         = 'C:\Users\Spencer\Documents\Data';
        default.output      = 'C:\Users\Spencer\Documents\Output';
        default.backup      = 'C:\Users\Spencer\Documents\Backup';
        default.cache       = {'C:\Users\Spencer\Documents\cache'};
        default.temp        = 'C:\Users\Spencer\Documents\temp';
        default.screenid    = 1;
        
    case 'SPENCER_CEREBELLUM'
        default.code        = '/home/skellis/Code';
        default.data        = {'/mnt/sinus/Data'};
        default.results     = '/data/skellis/results';
        default.map         = '/mnt/rphst1/MapFiles';
        default.output      = '/data/skellis/output';
        default.backup      = '/data/skellis/backup';
        default.cache       = {'/data/skellis/cache','/home/skellis/mnt/gamma/skcache','/home/skellis/mnt/joplin/cache'};
        default.temp        = '/data/skellis/temp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        default.screenid    = 1;
        default.opengl      = 'software';
        
    case 'SPENCER_DVORAK'
        default.code        = 'D:\Code';
        default.data        = {'Z:\Research\Data'};
        default.results     = 'Z:\Research\Results';
        default.map         = 'D:\Box Sync\MapFiles';
        default.output      = 'D:\Share';
        default.backup      = 'Z:\Backups';
        default.cache       = {'D:\cache'};
        default.temp        = 'D:\temp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        default.screenid    = 1;
        
    case 'SPENCER_GAMMA'
        default.code        = 'E:\skellis\Code';
        default.data        = {'\\131.215.27.24\raid01\Data'};
        default.results     = 'E:\skellis\Results';
        default.map         = '\\131.215.27.24\raid01\MapFiles';
        default.output      = 'E:\skellis\Share';
        default.backup      = 'E:\skellis\Backup';
        default.cache       = {'E:\skellis\Cache'};
        default.temp        = 'E:\skellis\Temp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        default.screenid    = 0;
        
    case 'SPENCER_JOPLIN'
        default.code        = 'D:\Code_TRUNK';
        default.data        = {'\\131.215.27.24\raid01\Data'};
        default.results     = 'E:\results';
        default.map         = '\\131.215.27.24\raid01\MapFiles';
        default.output      = 'C:\Share';
        default.backup      = 'E:\Backup';
        default.cache       = {'E:\cache'};
        default.temp        = 'E:\temp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        default.screenid    = 1;
        
    case 'SPENCER_LISZT'
        default.code        = 'C:\Users\spenc\Documents\Code';
        default.data        = {'C:\Users\spenc\Documents\Data'};
        default.results     = 'C:\Users\spenc\Documents\Results';
        default.map         = 'C:\Users\spenc\Documents\Data';
        default.output      = 'C:\Share';
        default.backup      = 'C:\Backup';
        default.cache       = {'C:\cache'};
        default.temp        = 'C:\temp';
        default.screenid    = 0;
        
    case 'SPENCER_MOZART'
        default.code        = 'C:\Users\Spencer\Documents\Code';
        default.data        = {'C:\Users\Spencer\Documents\Data'};
        default.results     = 'C:\Users\Spencer\Documents\Results';
        default.map         = 'C:\Users\Spencer\Documents\Data';
        default.output      = 'C:\Share';
        default.backup      = 'C:\Backup';
        default.cache       = {'C:\cache'};
        default.temp        = 'C:\temp';
        default.screenid    = 1;
        
    case 'SPENCER_PDP'
        default.code        = 'D:\Code';
        default.data        = {'\\131.215.27.24\raid01\Data'};
        default.results     = 'D:\skresult';
        default.map         = '\\131.215.27.24\raid01\MapFiles';
        default.output      = 'C:\Share';
        default.backup      = 'D:\Backup';
        default.cache       = {'D:\skcache'};
        default.temp        = 'D:\sktemp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        default.screenid    = 0;
        
    case 'SPENCER_SULCUS'
        default.code        = '/home/skellis/Code';
        default.data        = {'\\131.215.27.24\raid01\Data'};
        default.results     = '/home/skellis/results';
        default.map         = '\\131.215.27.24\raid01\MapFiles';
        default.output      = '/home/skellis/output';
        default.backup      = '/home/skellis/backup';
        default.cache       = {'/home/skellis/cache'};
        default.temp        = '/home/skellis/temp';
        default.cbmexaddr   = {};
        default.cbmexint    = 0;
        default.screenid    = 1;
        
    otherwise
        error('Unrecognized location ''%s''',loc);
end

% common relative to other dependent variables
default.analysis    = fullfile(default.code,'analysis');
default.external    = fullfile(default.code,'external');
default.hst         = fullfile(default.code,'hst');
default.media       = fullfile(default.code,'media');
default.nih         = fullfile(default.code,'nih');
default.rphst       = fullfile(default.code,'rphst');
default.user        = fullfile(default.code,'spencer');
