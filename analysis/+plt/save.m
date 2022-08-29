function filenames = save(fig,varargin)
% SAVE Save a figure to disk
%
%   SAVE(FIG)
%   Save the figure represented by the graphics handle FIG to disk. By
%   default, the figure will be saved as both FIG and PNG into the
%   directory specified by the RESULTS environment variable, with the
%   generic basename "plot". If the directory does not exist, it will be
%   created. If the files already exist, an error will be thrown.
%
%   SAVE(...,'BASENAME',B)
%   Specify a basename B for the saved files.
%
%   SAVE(...,'OUTDIR',D)
%   Specify an output directory D for the saved files.
%
%   SAVE(...,'FORMATS',{FORMAT1,FORMAT2,...})
%   Specify a list of file formats. The formats should be specified as only
%   the extension (without the period '.'), and should be provided as a
%   cell array of char. Default value is {'PNG','FIG'}.
%
%   SAVE(...,'OVERWRITE')
%   Overwrite existing files.
%
%   SAVE(...,DBG)
%   Provide an object DBG of class DEBUG.DEBUGGER through which to log
%   debug messages.

% validate inputs
assert(ishandle(fig),'FIG must be a valid graphics handle');

% process inputs
[varargin,hDebug,found] = util.argisa('Debug.Debugger',varargin,[]);
if ~found,hDebug=Debug.Debugger('plot_save');end
[varargin,outdir] = util.argkeyval('outdir',varargin,env.get('results'));
[varargin,basename] = util.argkeyval('basename',varargin,'plot');
[varargin,file_formats] = util.argkeyval('formats',varargin,{'png','fig'},4);
file_formats = util.ascell(file_formats);
assert(all(cellfun(@ischar,file_formats)),'FILE_FORMATS must be a cell array of char');
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
[varargin,flag_filenames] = util.argflag('filenames',varargin,false);
util.argempty(varargin);

% set the paper position mode to auto
set(fig,'PaperPositionMode','auto');

% check whether directory exists
if exist(outdir,'dir')~=2
    [status,msg] = mkdir(outdir);
    assert(status,'Could not create directory "%s": %s',outdir,msg);
end

% loop over file formats
filenames = cell(1,length(file_formats));
for ff=1:length(file_formats)

    % full path to file
    filenames{ff} = fullfile(outdir,sprintf('%s.%s',basename,file_formats{ff}));
    if flag_filenames,continue;end
    
    % check whether file exists
    assert(flag_overwrite|exist(filenames{ff},'file')~=2,'File "%s" already exists and overwrite flag is set to false',filenames{ff});
    
    % create the file
    try
        saveas(fig,filenames{ff});
    catch ME
        util.errorMessage(ME);
        continue;
    end
    
    % log the result
    hDebug.log(sprintf('Saved figure to %s',filenames{ff}),'info');
end