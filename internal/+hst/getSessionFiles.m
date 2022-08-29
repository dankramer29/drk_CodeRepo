function fileList = getSessionFiles(session,subject,searchString,varargin)
FlagDir = 1;
FlagRegexp = 0;
if any(strcmpi(varargin,'regexp'))
    FlagDir = 0;
    FlagRegexp = 1;
end
if FlagDir, processDirectory=@processDirectoryDir;
elseif FlagRegexp, processDirectory=@processDirectoryRegexp; end

sessionDirectory = hst.getSessionPath(session,subject);
fileList = processDirectory(sessionDirectory,searchString);



function matchList = processDirectoryRegexp(dirPath,searchString)
matchList = {};
matchIdx = 1;

% get full directory listing
fileList = dir( fullfile(dirPath) );
fileList( strcmpi({fileList.name},'.')|strcmpi({fileList.name},'..') ) = [];

% loop over all entries; process directories; compare each file to search
for kk=1:length(fileList)
    
    fullPath = fullfile(dirPath,fileList(kk).name);
    if isdir( fullPath )
        tmpList = processDirectoryRegexp( fullPath,searchString );
        matchList(matchIdx + (0:length(tmpList)-1)) = tmpList;
        matchIdx = matchIdx + length(tmpList);
    else
        token = regexp(fileList(kk).name,searchString,'once');
        if ~isempty(token)
            matchList{matchIdx} = fullfile(dirPath,fileList(kk).name);
            matchIdx = matchIdx + 1;
        end
    end
end


function matchList = processDirectoryDir(dirPath,searchString)
matchList = {};
matchIdx = 1;

% get full directory listing
fileList = dir( dirPath );
fileList( strcmpi({fileList.name},'.')|strcmpi({fileList.name},'..') ) = [];

% look for subdirectories and process each of them
dirList = fileList( [fileList.isdir]==1 );
for kk=1:length(dirList)
    tmpList = processDirectoryDir( fullfile(dirPath,dirList(kk).name),searchString );
    matchList(matchIdx + (0:length(tmpList)-1)) = tmpList;
    matchIdx = matchIdx + length(tmpList);
end

% process all files in this directory
fileList = dir( fullfile(dirPath,searchString) );
fileList( strcmpi({fileList.name},'.')|strcmpi({fileList.name},'..') ) = [];
for kk=1:length(fileList)
    matchList{matchIdx} = fullfile(dirPath,fileList(kk).name);
    matchIdx = matchIdx + 1;
end