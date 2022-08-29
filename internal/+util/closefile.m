function closefile(file)
% CLOSEFILE Close any open files matching the input path

% get list of all open fids
fids = fopen('all');

% branch based on user input
if ischar(file)
    
    % find any that match our source/target files
    match = false(size(fids));
    for kk=1:length(fids)
        openfile = fopen(fids(kk));
        match(kk) = strcmpi(openfile,file);
    end
    
    % close any fids that matched
    if any(match)
        matched_fids = fids(match);
        status = -1*ones(size(matched_fids));
        for kk=1:length(matched_fids)
            status(kk) = fclose(matched_fids(kk));
        end
        
        % make sure it worked
        assert(all(status==0),'Could not close some files');
    end
elseif isnumeric(file)
    
    % user provided fid
    if ismember(file,fids)
        status = fclose(file);
        
        % make sure it worked
        assert(status==0,'Could not close FID %d',file);
    end
else
    
    % don't know what to do
    error('Could not process input of class "%s"',class(file));
end