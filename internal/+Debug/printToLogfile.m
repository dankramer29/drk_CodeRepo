function fid = printToLogfile(msg,fid)

% special input case to close the file
if isnumeric(msg) && msg<0
    if isnumeric(fid)
        
        % close the file
        fclose(fid);
    else
        
        % if no I/O specified, create default output log file
        if nargin<2||isempty(fid)
            logfile = fullfile('.',sprintf('%s.log',datestr(now,'yyyymmdd-HHMMSS')));
        elseif ischar(fid)
            logfile = fid;
        end
        
        % check whether directory exists
        iodir = fileparts(logfile);
        if exist(iodir,'dir')~=7
            [status,errmsg] = mkdir(iodir);
            assert(status>0,'Could not create directory ''%s'' for log file: %s',iodir,errmsg);
        end
        
        % open the file for writing
        [fid,errmsg] = fopen(logfile,'a');
        assert(fid>0,'Could not open log file ''%s'' for writing: %s',logfile,errmsg);
    end
    
    % return immediately
    return;
end

% make sure string input for message
assert(ischar(msg),'Invalid input: must be ''char'', not ''%s''',class(msg));

% write message to log file
fprintf(fid,'%s\n',msg);