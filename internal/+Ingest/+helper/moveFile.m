function moveFile(oldfile,newfile,lbl,fn,debug)
% MOVEFILE Helper function to move files
%
%  MOVEFILE(OLDFILE,NEWFILE,LBL,FN)
%  Move the file OLDFILE to the new file NEWFILE, with
%  debug label LBL. Use FN to specify @movefile or
%  @copyfile.

% extract directory/basename/extension from old/new files
[olddir,oldbase,oldext] = fileparts(oldfile);
[newdir,newbase,newext] = fileparts(newfile);

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

% check for existence of target directory
if exist(newdir,'dir')~=7
    [status_ing,msg_ing] = mkdir(newdir);
    assert(status_ing,'Could not create "ingest" folder in "%s": %s',newdir,msg_ing);
end

% branch based on existence of old/new files
if exist(oldfile,'file')==2
    
    % newfile exists
    if exist(newfile,'file')==2
        
        % newfile exists - rename with append based on
        % current date/time
        append = datestr(now,'yyyymmddHHMMSSFFF');
        newfile_bak = fullfile(newdir,sprintf('%s_%s',newbase,append,newext));
        [bak_status,bak_msg] = movefile(newfile,newfile_bak);
        assert(bak_status,'Could not rename existing Natus %s file from "%s" to "%s": %s',lbl,newfile,newfile_bak,bak_msg);
        debug.log(sprintf('Backed up "%s" to "%s"',newfile,newfile_bak),'info');
    end
    
    % rename the old file to the new file (i.e., move from
    % the working directory to the source directory)
    debug.log(sprintf('%s %s file "%s%s" from "%s" to "%s"',gerund,lbl,oldbase,oldext,olddir,newdir),'debug');
    [nat_status,nat_msg] = feval(fn,oldfile,newfile);
    assert(nat_status,'Could not %s %s "%s" to "%s": %s',presenttense,lbl,oldfile,newfile,nat_msg);
elseif exist(oldfile,'file')~=2 && exist(newfile,'file')==2
    
    % old file doesn't exist, but new file does
    debug.log(sprintf('%s file "%s%s" already exists in "%s"',lbl,newbase,newext,newdir),'debug');
elseif exist(oldfile,'file')~=2 && exist(newfile,'file')~=2
    
    % neither the old nor the new files exist
    error('%s file "%s%s" is missing!',lbl,oldbase,oldext);
end