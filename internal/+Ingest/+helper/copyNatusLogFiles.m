

function exitCode = copyNatusLogFiles(this)
exitCode = 0; % success
setUserStatus(this,'Copying log and metadata files into the source directory');

% identify working directory and source directory
workdir = getWorkingDirectory(this);
srcdir = this.SourceFiles.directory{this.currFileIndex};

% move Natus STATUS file
if strcmpi(this.SourceFiles.mode{this.currFileIndex},'Natus')
    status_base = sprintf('%s.STATUS',this.SourceFiles.basename{this.currFileIndex});
    status_old = fullfile(workdir,status_base);
    status_new = fullfile(srcdir,'ingest',status_base);
    try
        Ingest.helper.moveFile(status_old,status_new,'Natus status',@movefile);
    catch ME
        util.errorMessage(ME);
    end
    this.hDebug.log(sprintf('Moved "%s" to "%s"',status_old,status_new),'info');
end

% move Natus channel file
if strcmpi(this.SourceFiles.mode{this.currFileIndex},'Natus')
    channel_base = sprintf('%s_channel.txt',this.SourceFiles.basename{this.currFileIndex});
    channel_old = fullfile(workdir,channel_base);
    channel_new = fullfile(srcdir,'ingest',channel_base);
    try
        Ingest.helper.moveFile(channel_old,channel_new,'Natus channel',@movefile);
    catch ME
        util.errorMessage(ME);
    end
    this.hDebug.log(sprintf('Moved "%s" to "%s"',channel_old,channel_new),'info');
end

% move Natus log file
if strcmpi(this.SourceFiles.mode{this.currFileIndex},'Natus')
    log_base = sprintf('%s_log.txt',this.SourceFiles.basename{this.currFileIndex});
    log_old = fullfile(workdir,log_base);
    log_new = fullfile(srcdir,'ingest',log_base);
    try
        Ingest.helper.moveFile(log_old,log_new,'Natus log',@movefile);
    catch ME
        util.errorMessage(ME);
    end
    this.hDebug.log(sprintf('Moved "%s" to "%s"',log_old,log_new),'info');
end

% move Natus event file
if strcmpi(this.SourceFiles.mode{this.currFileIndex},'Natus')
    event_base = sprintf('%s_event.txt',this.SourceFiles.basename{this.currFileIndex});
    event_old = fullfile(workdir,event_base);
    event_new = fullfile(srcdir,'ingest',event_base);
    try
        Ingest.helper.moveFile(event_old,event_new,'Natus event',@movefile);
    catch ME
        util.errorMessage(ME);
    end
    this.hDebug.log(sprintf('Moved "%s" to "%s"',event_old,event_new),'info');
end
end % END function copyNatusLogFiles