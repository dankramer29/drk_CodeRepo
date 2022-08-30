function fid = openfile(file,mode,varargin)
% OPENFILE Get handles to the source and target files
%
%   Input arguments
%   seek - key/value "seek", BYTES to seek into the file
%   overwrite - flag to allow existing file to open in write mode
%   multiple - flag to allow multiple file handles to the same file

% default/process input
if nargin<2||isempty(mode),mode='r';end
[varargin,seekbyte] = util.argkeyval('seek',varargin,0);
[varargin,overwrite] = util.argflag('overwrite',varargin,false);
[varargin,multiple] = util.argflag('allow_multiple_handles',varargin,false);
assert(ischar(mode),'Read-write input must be char, not "%s"',class(mode));
mode = lower(mode);
util.argempty(varargin);

% close first
if ~multiple
    util.closefile(file);
end

% handle overwrite
if ismember('w',mode) && ~overwrite
    assert(exist(file,'file')~=2,'File "%s" already exists (use "overwrite" flag to overwrite the file)',file);
end

% open the source file
[fid,errmsg] = fopen(file,mode);
assert(fid>0,'Could not open file "%s" with mode "%s": %s',file,mode,errmsg);

% seek if requested
if seekbyte>0
    fseek(fid,seekbyte,'bof');
end