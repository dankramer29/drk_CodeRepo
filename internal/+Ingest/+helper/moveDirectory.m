function moveDirectory(olddir,newdir,lbl,fn,debug)
% MOVEDIRECTORY Helper function to move directories
%
%   MOVEDIRECTORY(OLDDIR,NEWDIR,LBL,FN)
%   Move the directory OLDDIR to the new directory NEWDIR,
%   with debug label LBL. Use FN to specify @movedir or
%   @copydir.
if strcmpi(newdir(end),filesep),newdir=newdir(1:end-1);end
[oldparent,olddirname] = fileparts(olddir);
newparent = fileparts(newdir);

% check move/copy
if ischar(fn),fn=str2func(fn);end
assert(isa(fn,'function_handle'),'Must provide function handle, not "%s"',class(fn));
assert(ismember(func2str(fn),{'movefile','copyfile'}),'Must provide function handle for @movefile or @copyfile, not %s',func2str(fn));
if strcmpi(func2str(fn),'movefile')
    presenttense = 'move';
    gerund = 'Moving';
elseif strcmpi(func2str(fn),'copyfile')
    presenttense = 'copy';
    gerund = 'Copying';
end

% branch based on existing of old/new directories
if exist(olddir,'dir')==7
    
    % newdir exists
    if exist(newdir,'dir')==7
        
        % newdir exists - rename with append based on
        % current date/time
        append = datestr(now,'yyyymmddHHMMSSFFF');
        newdir_bak = sprintf('%s_%s',newdir,append);
        [st,msg] = movefile(newdir,newdir_bak);
        assert(st,'Could not rename existing %s folder from "%s" to "%s": %s',lbl,newdir,newdir_bak,msg);
        assert(exist(newdir,'dir')~=7,'Directory "%s" still exists',newdir);
        debug.log(sprintf('Backed up "%s" to "%s"',newdir,newdir_bak),'info');
    end
    
    % move the old directory to the new directory
    debug.log(sprintf('%s %s folder "%s" from "%s" to "%s"',gerund,lbl,olddirname,oldparent,newparent),'debug');
    [st,msg] = feval(fn,olddir,newdir);
    assert(st,'Could not %s %s "%s" to "%s": %s',presenttense,lbl,olddirname,newparent,msg);
elseif exist(olddir,'dir')~=7 && exist(newdir,'dir')==7
    
    % old file doesn't exist, but new file does
    debug.log(sprintf('%s folder "%s" already exists in "%s"',lbl,olddirname,newparent),'debug');
elseif exist(olddir,'dir')~=7 && exist(newdir,'dir')~=7
    
    % neither the old nor the new files exist
    error('%s folder "%s" is missing!',lbl,olddir);
end