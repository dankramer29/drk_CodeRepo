function alignNSPs(varargin)
% ALIGNNSPS Alignment script for multiple NSPs
%
%   This function was adapted from a script provided by Blackrock
%   Microsystems (see below for acknowledgment).
%
%   ALIGNNSPS
%   Open a series of file-selection dialog boxes. Select any data file
%   (*.NEV, *.NSx) from any one of the arrays, and internally it will
%   discover all data files for all arrays for that session. This
%   functionality depends on the existence of Caltech infrastructure, e.g.,
%   HST.GETARRAYNAMES.
%
%   ALIGNNSPS(...,NFILE)
%   ALIGNNSPS(...,NOBJ)
%   Provide the full path to a single data file, or a single BLACKROCK.NSX
%   or BLACKROCK.NEV object.
%
%   ALIGNNSPS(...,DBG)
%   Provide a DEBUG.DEBUGGER object DBG. If one is not provided, it will be
%   created.
%
% FROM ORIGINAL:
% Purpose: This script produces files that are modified so that alignment
% of data from multiple NSPs is intuitive to understand. It does this by
% ensuring that the timestamps are on the same scale between all files.
%
% Author: Nick Halper for Blackrock Microsystems
% Contact: nhalper@blackrockmicro.com
% www.blackrockmicro.com

% process inputs
[varargin,selected_extension] = util.argkeyword({'nev','ns6','ns5','ns4','ns3','ns2','ns1','all'},varargin,'all');
[varargin,append_string] = util.argkeyval('append_string',varargin,'_aligned',6);
[varargin,record_start_interval] = util.argkeyval('record_start_interval',varargin,2); % the interval (in seconds) between starting the different NSPs
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
args = {}; if flag_overwrite,args={'overwrite'};end
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,'');
if ~found_debug,debug=Debug.Debugger('alignNSPs');end
if ~debug.isRegistered('Blackrock.NSx')
    debug.registerClient('Blackrock.NSx','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('Blackrock.NEV')
    debug.registerClient('Blackrock.NEV','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('Blackrock.NSxWriter')
    debug.registerClient('Blackrock.NSxWriter','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('Blackrock.NEVWriter')
    debug.registerClient('Blackrock.NEVWriter','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
[varargin,nfile,found_nfile] = util.argfns(@(x)ischar(x)&&exist(x,'file')==2,varargin,'');
[varargin,nobj,found_nobj] = util.argfns(@(x)isa(x,'Blackrock.NSx')||isa(x,'Blackrock.NEV'),varargin,'');
util.argempty(varargin);

% get a path to an existing data file
tmr = tic;
if ~found_nfile && ~found_nobj
    
    % allow user to select a file
    datadir = env.get('data');
    if iscell(datadir),datadir=datadir{1};end
    [filename,pathname] = uigetfile({'*.nev;*.ns6;*.ns5;*.ns4;*.ns3;*.ns2;*.ns1','Blackrock data files (*.nev;*.ns6;*.ns5;*.ns4;*.ns3;*.ns2;*.ns1)'},'Select a data file',datadir);
    if isnumeric(filename) && filename==0
        return; % no file selected, just return
    end
    nfile = fullfile(pathname,filename);
elseif found_nobj
    nfile = cellfun(@(x)fullfile(x.SourceDirectory,sprintf('%s%s',x.SourceBasename,x.SourceExtension)),nobj,'un',0);
end
if ~iscell(nfile),nfile={nfile};end
cellfun(@(x)assert(exist(x,'file')==2,'Could not find selected file "%s"',x),nfile);
debug.log(sprintf('User provided %d files',length(nfile)),'info');

% infer subject and array names
ndir = fileparts(nfile{1});
tokens = strsplit(ndir,filesep);
idx_subject = cellfun(@hst.helper.isValidSubject,tokens);
assert(any(idx_subject),'Could not find subject in pathname "%s"',ndir);
subject_id = tokens{idx_subject};
subject = hst.Subject(subject_id,debug);
session_id = tokens{circshift(idx_subject,1,2)};
session = hst.Session(session_id,subject,debug);
arraynames = session.ArrayInfo.FolderName;
debug.log(sprintf('Subject set to "%s" with %d arrays',subject.ID,length(arraynames)),'info');

% identify other files in the data set (if not provided)
if length(nfile)==1
    nfile = nfile{1};
    [ndir,nbase,next] = fileparts(nfile);
    
    % identify data files from all arrays
    tokens = strsplit(ndir,filesep);
    nfiles = cell(1,length(arraynames));
    for aa=1:length(arraynames)
        nm = util.ascell(arraynames{aa});
        idx_nm = find(cellfun(@(x)any(strcmpi(x,nm)),tokens),1,'first');
        if ~isempty(idx_nm)
            
            % identify parent directory and other arrays' subfolders
            nfiles{aa} = nfile;
            arraynames{aa} = tokens{idx_nm};
            pdir = ndir(1:strfind(ndir,arraynames{aa})-2);
            assert(~isempty(pdir),'Could not identify parent directory to array folder in "%s"',ndir);
            subdirs = dir(pdir);
            subdirs = {subdirs([subdirs.isdir]).name};
            for aaa=setdiff(1:length(arraynames),aa)
                nm = util.ascell(arraynames{aaa});
                idx_nm = cellfun(@(x)any(strcmpi(x,nm)),subdirs);
                assert(~isempty(idx_nm),'Could not find subfolder for arrayname "%s"',nm);
                arraynames{aaa} = subdirs{idx_nm};
                
                % check for sames file as selected one but for this array
                nfiles{aaa} = fullfile(pdir,arraynames{aaa},sprintf('%s%s',strrep(nbase,arraynames{aa},arraynames{aaa}),next));
            end
            break;
        end
    end
    nfiles(cellfun(@isempty,nfiles)) = [];
    arraynames(cellfun(@isempty,arraynames)) = [];
end
num_arrays = length(arraynames);
assert(length(nfiles)>=3,'Alignment not required for fewer than three NSPs (found %d matching files)',length(nfiles));
assert(length(nfiles)==num_arrays,'Must have one arrayname per nfile');

% break out into directory, basename, extension for each file
[ndirs,nbases] = cellfun(@fileparts,nfiles,'UniformOutput',false);

% look for all data extensions available
for aa=1:num_arrays
    nbase_matches = dir(fullfile(ndirs{aa},sprintf('%s.*',nbases{aa})));
    nbase_matches = {nbase_matches.name};
    [~,~,nbase_ext] = cellfun(@fileparts,nbase_matches,'UniformOutput',false);
    if strcmpi(selected_extension, 'all')
        data_ext = ismember(cellfun(@lower,nbase_ext,'UniformOutput',false),{'.nev','.ns6','.ns5','.ns4','.ns3','.ns2','.ns1'});
    elseif strcmpi(selected_extension, 'ns5')
        data_ext = ismember(cellfun(@lower,nbase_ext,'UniformOutput',false),{strcat('.', selected_extension)});
    else
        data_ext = ismember(cellfun(@lower,nbase_ext,'UniformOutput',false),{strcat('.', selected_extension), '.ns5'});
    end
    
    %%
    fmt = nbase_ext(data_ext); % remove non-data file extensions
    if aa==1
        formats = fmt;
    else
        formats(~ismember(formats,fmt)) = []; % remove non-matching formats
    end
end
num_formats = length(formats);
debug.log(sprintf('Found %d formats (%s) for %d arrays (%s) (%.2f sec)',length(formats),strjoin(formats,', '),length(arraynames),strjoin(arraynames,', '),toc(tmr)),'info');

% require ns5; others are possible but not required
idx_ns5 = strcmpi(formats,'.ns5'); assert(any(idx_ns5),'Must provide at least the *.ns5 format');

% create objects for each of the data types
tmr = tic;
obj = cell(1,num_formats);
for ff=1:num_formats
    switch lower(formats{ff})
        case '.nev'
            obj{ff} = cellfun(@(x,y)Blackrock.NEV(fullfile(x,sprintf('%s.nev',y)),debug),ndirs,nbases,'UniformOutput',false);
        case {'.ns6','.ns5','.ns4','.ns3','.ns2','.ns1'}
            obj{ff} = cellfun(@(x,y)Blackrock.NSx(fullfile(x,sprintf('%s%s',y,formats{ff})),debug),ndirs,nbases,'UniformOutput',false);
        otherwise
            error('Unknown format "%s"',formats{ff});
    end
end
debug.log(sprintf('Finished loading objects (%.2f sec)',toc(tmr)),'info');

% get sync pulse data
codes = cell(1,num_arrays);
for aa=1:num_arrays
    
    % identify the sync channel and the number of packets in each file
    idx_sync_ch = find(strcmpi({obj{idx_ns5}{aa}.ChannelInfo.Label},'nsp_sync'));
    assert(~isempty(idx_sync_ch),'Could not identify single nsp sync channel');
    dt = [zeros(1,obj{idx_ns5}{aa}.Timestamps(1)) obj{idx_ns5}{aa}.read('channel',idx_sync_ch,'normalized','packet',1)];
    
    % get the sync codes
    if max(dt)-min(dt) < 1e3
        debug.log(sprintf('No sync signal found for array %d/%d',aa,num_arrays),'warn');
        continue;
    else
        codes{aa} = syncPatternDetectNSx(dt(1:min(size(dt,2),30*obj{idx_ns5}{aa}.Fs)));
    end
end
clear dt

% get rid of arrays without sync info
idx_empty = cellfun(@isempty,codes);
codes(idx_empty) = [];
for kk=1:length(obj)
    obj{kk}(idx_empty) = [];
end
num_arrays = length(codes);
task_id = regexprep(nbase,sprintf('^(.*)-%s.*$',arraynames{1}),'$1');
assert(num_arrays>0,'No sync information available for any NSP associated with %s',task_id);

% find timestamp of earliest common code
TempIntersection = codes{1}{1};
for aa=2:num_arrays
    TempIntersection = intersect(TempIntersection,codes{aa}{1});
end
FinalIntersection = TempIntersection;
clear TempIntersection;
FirstCommonCode = FinalIntersection(1);
CodeTimestamps = nan(1,num_arrays);
for aa=1:num_arrays
    CodeTimestamps(aa) = codes{aa}{2}(find(codes{aa}{1}==FirstCommonCode,1));
end
debug.log(sprintf('Processed sync pulse (code timestamps %s)',util.vec2str(CodeTimestamps,'%d')),'info');

% validation check on the timestamp values
tsdiff_actual = max(CodeTimestamps) - min(CodeTimestamps);
tsdiff_expected = 30e3*(length(obj{1})-1)*record_start_interval;
tsdiff_margin = 30e3;
assert(tsdiff_actual<=(tsdiff_expected+tsdiff_margin),...
    'Measured timestamp difference (%.2f sec) exceeds the expected value (%.2f sec)',...
    tsdiff_actual/30e3,(tsdiff_expected+tsdiff_margin)/30e3);

% perform alignment for all the arrays/formats
for aa=1:num_arrays
    
    % compute the prepend and loop over formats
    offset_timestamp = max(CodeTimestamps)-CodeTimestamps(aa);
    for nn=1:num_formats
        
        % update user
        tmr = tic;
        
        % process the data files
        if strcmpi(formats{nn},'.nev')
            
            % update timestamps
            dt = obj{nn}{aa}.read('all');
            fields = fieldnames(dt);
            for ff=1:length(fields)
                dt.(fields{ff}) = util.ascell(dt.(fields{ff}));
                assert(length(dt.(fields{ff}))==obj{nn}{aa}.NumRecordingBlocks,'For data type "%s", found %d recording blocks but expected %d',fields{ff},length(dt.(fields{ff})),obj{nn}{aa}.NumRecordingBlocks);
                for bb=1:obj{nn}{aa}.NumRecordingBlocks
                    if isempty(dt.(fields{ff}){bb}),continue;end
                    dt.(fields{ff}){bb}.Timestamps = dt.(fields{ff}){bb}.Timestamps + offset_timestamp;
                end
            end
            
            % initialize NEVWriter object
            nvw = Blackrock.NEVWriter(fullfile(obj{nn}{aa}.SourceDirectory,sprintf('%s%s.nev',obj{nn}{aa}.SourceBasename,append_string)),...
                'like',obj{nn}{aa},args{:},debug); % force it to ignore existing files, which will be handled below
            
            % check how many recording blocks (cells)
            for bb=1:obj{nn}{aa}.NumRecordingBlocks
                arg = arrayfun(@(x)dt.(fields{x}){bb},1:length(fields),'UniformOutput',false);
                idx = find(cellfun(@isempty,arg));
                for cc=1:length(idx)
                    arg{idx(cc)} = fields{idx(cc)};
                end
                nvw.addData(arg{:});
            end
            
            % save the file
            nvw.save;
        else
            
            % NOTE this could also be done easily by just altering the
            % packet header to update the packet timestamp, rather than
            % writing an entire new file...
            
            % create file with updated (aligned) timestamp
            nsw = Blackrock.NSxWriter('like',obj{nn}{aa},args{:},debug,...
                'target',fullfile(obj{nn}{aa}.SourceDirectory,sprintf('%s%s%s',obj{nn}{aa}.SourceBasename,append_string,obj{nn}{aa}.SourceExtension)));
            nsw.writeFileHeaders;
            for pp=1:length(obj{nn}{aa}.Timestamps)
                nsw.writePacketHeader(obj{nn}{aa}.Timestamps(pp)+offset_timestamp,obj{nn}{aa}.PointsPerDataPacket(pp));
                
                % read memory in blocks that fit into memory
                currPoint = 1;
                while currPoint <= obj{nn}{aa}.PointsPerDataPacket(pp)
                    [~,numPointsInMemory] = util.memcheck([obj{nn}{aa}.ChannelCount 1],'double','AvailableUtilization',0.5);
                    numPointsLeft = obj{nn}{aa}.PointsPerDataPacket(pp) - currPoint + 1;
                    numPointsToRead = min(numPointsInMemory,numPointsLeft);
                    dt = obj{nn}{aa}.read('ref','packet','packet',pp,'points',[1 numPointsToRead],'normalized');
                    nsw.writePacketData(dt,'normalized');
                    currPoint = currPoint + numPointsToRead;
                    clear dt;
                end
            end
            
            % clean up
            nsw.delete;
        end
        
        % update user
        debug.log(sprintf('Finished %s / %s (%.2f sec)',arraynames{aa},formats{nn},toc(tmr)),'info');
    end
end





function codeKeeper = syncPatternDetectNSx(data)
% from NPMK packet, written by Kian Torab originally

% Detect the rising edges
separationVar = 'D';
edgeTS = edgeDetect(data, 10000);
differenceTS = diff(edgeTS);
pulseDifferenceLenght = mode(differenceTS);

convertedChar = [];
for idx = 1:length(differenceTS)
    if differenceTS(idx) < pulseDifferenceLenght*1.1
        convertedChar = [convertedChar, '1'];
    elseif differenceTS(idx) < 9*pulseDifferenceLenght
        convertedChar = [convertedChar, repmat('0', 1, round((differenceTS(idx) - pulseDifferenceLenght)/pulseDifferenceLenght)), '1'];
    else
        convertedChar = [convertedChar, separationVar];
    end
end

begTS = edgeTS(find(differenceTS > pulseDifferenceLenght * 12) + 1);
begTS = [edgeTS(1) begTS];

codeKeeper{1} = bin2dec(regexp(convertedChar, separationVar, 'split'))';
codeKeeper{2} = begTS;





function timestamps = edgeDetect(signal, threshold, type)
% from NPMK, written by Kian Torab originally

% Validating input arguments.
if nargin < 1 || nargin > 3
    disp('Invalid number of input arguments. Use ''help edgeDetect'' for more information.');
    return;
end

if ~exist('threshold', 'var')
    threshold = 0.8 * max(signal);
    disp(['Threshold was not provided. It wss automatically calculated and set at ' num2str(threshold) '.']);
end

% Validating variable 'type'
if ~exist('type', 'var')
    type = 'rising';
end

% Validating type and determining the threshold crossing points
if strcmpi(type, 'rising')
    timestamps = signal>threshold;
elseif strcmpi(type, 'falling')
    timestamps = signal<threshold;
else
    disp('Type does not exist. Please type ''help edgeDetect'' to see all available types.');
    timestamps = 0;
    return;
end

% Finding all the points where the signal crosses the threshold
timestamps = diff(timestamps);
timestamps = find(timestamps==1);