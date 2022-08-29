function files = blc2lm(blc,varargin)

% process inputs
[varargin,basename_append,~,found_append] = util.argkeyval('append',varargin,'');
basename_append_string = '';
if found_append,basename_append_string=sprintf('_%s',basename_append);end
[varargin,model_context] = util.argkeyword({'grid','file'},varargin,'grid');
[varargin,flag_fs_in_base] = util.argflag('fsinbase',varargin,false);
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
[varargin,flag_filename_only] = util.argflag('filenames',varargin,false);
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug,debug=Debug.Debugger('blc2lm');end
[varargin,mapfile,~,found_mapfile] = util.argkeyval('mapfile',varargin,{});
[varargin,map,found_map] = util.argisa('GridMap.Interface',varargin,{});
util.argempty(varargin);

% create input arguments for blc writer object
args = {};
if flag_fs_in_base,args=[args {'fsinbase'}];end
if flag_overwrite,args=[args {'overwrite'}];end

% process map input
if ~found_map && found_mapfile
    map = GridMap.Interface(mapfile);
end
found_map = ~isempty(map);

% validate input
if ischar(blc)
    assert(exist(blc,'file')==2,'Could not find input file "%s"',blc);
    blc = BLc.Reader(blc,debug);
end
assert(isa(blc,'BLc.Reader'),'Must provide valid BLc.Reader object');

% set source file
subdir = sprintf('lm_%s',model_context);
dstdir = fullfile(blc.SourceDirectory,subdir);
dstfile_lmf = fullfile(dstdir,sprintf('%s_lmfit%s%s',blc.SourceBasename,basename_append_string,blc.SourceExtension));
dstfile_lmr = fullfile(dstdir,sprintf('%s_lmresid%s%s',blc.SourceBasename,basename_append_string,blc.SourceExtension));
files = {dstfile_lmf,dstfile_lmr};
if flag_filename_only,return;end
if exist(dstdir,'dir')~=7
    [status,msg] = mkdir(dstdir);
    assert(status>0,'Could not create directory "%s": %s',dstdir,msg);
end

% look for map file
if ~found_map
    mapfile = fullfile(blc.SourceDirectory,sprintf('%s.map',blc.SourceBasename));
    if exist(mapfile,'file')==2
        map = GridMap.Interface(mapfile);
    end
end
assert(~isempty(map)&&isa(map,'GridMap.Interface'),'Could not find map file for "%s"',blc.SourceBasename);

% construct BLc Reader object
min_digital = unique([blc.ChannelInfo.MinDigitalValue]);
max_digital = unique([blc.ChannelInfo.MaxDigitalValue]);
min_analog = unique([blc.ChannelInfo.MinAnalogValue]);
max_analog = unique([blc.ChannelInfo.MaxAnalogValue]);
range_digital = max_digital - min_digital;
range_analog = max_analog - min_analog;

% open the file for writing
args = {};
if flag_overwrite,args={'overwrite'};end
fid_lmf = util.openfile(dstfile_lmf,'w',args{:});
fid_lmr = util.openfile(dstfile_lmr,'w',args{:});

% write basic header and channel info bytes to the file
try
    basicHeaderBytes = getBLcHeaderBytes(blc);
    channelInfoBytes = getBLcChannelInfoBytes(blc);
    fwrite(fid_lmf,basicHeaderBytes,'uint8');
    fwrite(fid_lmf,channelInfoBytes,'uint8');
    fwrite(fid_lmr,basicHeaderBytes,'uint8');
    fwrite(fid_lmr,channelInfoBytes,'uint8');
catch ME
    util.closefile(dstfile_lmf);
    util.closefile(dstfile_lmr);
    rethrow(ME);
end

%%
warning('Check to verify GridMap is properly integrated');
keyboard
%%

% loop over data sections
for ss=1:length(blc.DataInfo)
    
    % write data section header bytes to file
    try
        
        % process data
        data = blc.read('section',ss,'context','section');
        numPointsInSection = size(data,1);
        data_lmr = nan(size(data)); % for residual
        data_lmf = nan(size(data)); % for fitted
        
        % check memory requires (whether parfor is possible)
        umem = memory;
        vmem = whos('data');
        scale = 3;
        if strcmpi(model_context,'file')
            scale = 15;
        end
        max_num_workers = floor(umem.MemAvailableAllArrays/(scale*vmem.bytes));
        cpu_num_threads = numThreads;
        num_workers = min(max_num_workers,cpu_num_threads);
        flag_parfor = num_workers>1;
        if flag_parfor
            p = gcp('nocreate');
            if ~isempty(p) && p.NumWorkers>num_workers
                delete(gcp('nocreate'));
                p = parpool(num_workers);
            elseif isempty(p)
                p = parpool(num_workers);
            end
            debug.log(sprintf('Data section %d/%d: computing linear models (parfor, %d workers)',ss,length(blc.DataInfo),p.NumWorkers),'info');
            parfor cc=1:size(data,2)
                if strcmpi(model_context,'grid')
                    idx_grid = map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc);
                    idx_predictors = setdiff(map.GridInfo.Channels{idx_grid},cc);
                elseif strcmpi(model_context,'file')
                    idx_predictors = setdiff(1:map.NumChannels,cc);
                else
                    warning('unknown model context "%s" (defaulting to "file")',model_context);
                    idx_predictors = setdiff(1:map.NumChannels,cc);
                end
                mdl = fitlm(data(:,idx_predictors),data(:,cc),'RobustOpts','on','intercept',true,...
                    'VarNames',[arrayfun(@(x)sprintf('chan%02d',x),idx_predictors(:)','UniformOutput',false) {sprintf('chan%02d',cc)}]);
                data_lmr(:,cc) = mdl.Residuals.Raw;
                data_lmf(:,cc) = mdl.Fitted;
            end
        else
            debug.log(sprintf('Data section %d/%d: computing linear models (single-threaded)',ss,length(blc.DataInfo)),'info');
            for cc=1:size(data,2)
                if strcmpi(model_context,'grid')
                    idx_grid = map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc);
                    idx_predictors = setdiff(map.GridInfo.Channels{idx_grid},cc);
                elseif strcmpi(model_context,'file')
                    idx_predictors = setdiff(1:map.NumChannels,cc);
                else
                    warning('unknown model context "%s" (defaulting to "file")',model_context);
                    idx_predictors = setdiff(1:map.NumChannels,cc);
                end
                mdl = fitlm(data(:,idx_predictors),data(:,cc),'RobustOpts','on','intercept',true,...
                    'VarNames',[arrayfun(@(x)sprintf('chan%02d',x),idx_predictors(:)','UniformOutput',false) {sprintf('chan%02d',cc)}]);
                data_lmr(:,cc) = mdl.Residuals.Raw;
                data_lmf(:,cc) = mdl.Fitted;
            end
        end
        clear data;
        
        % format the data
        data_lmr = min_digital + round( range_digital*(data_lmr-min_analog)/range_analog ); % convert to quantized digital units
        data_lmf = min_digital + round( range_digital*(data_lmf-min_analog)/range_analog ); % convert to quantized digital units
        switch blc.BitResolution
            case 16
                data_lmr = cast(data_lmr,'int16')'; % convert to int16
                data_lmf = cast(data_lmf,'int16')'; % convert to int16
            case 32
                data_lmr = cast(data_lmr,'int32')'; % convert to int32
                data_lmf = cast(data_lmf,'int32')'; % convert to int32
            otherwise
                error('Unknown bit resolution "%d"',blc.BitResolution);
        end
        data_lmr = typecast(data_lmr(:),'uint8'); % get byte-level representation
        data_lmf = typecast(data_lmf(:),'uint8'); % get byte-level representation
        
        % get the data section header by tes
        sectionTimestamp = blc.DataInfo(ss).Timestamp;
        sectionDatetime = blc.DataInfo(ss).Datetime;
        dataHeaderBytes = getDataSectionHeaderBytes(blc,numPointsInSection,sectionTimestamp,sectionDatetime);
        fwrite(fid_lmf,dataHeaderBytes,'uint8');
        fwrite(fid_lmr,dataHeaderBytes,'uint8');
        
        % write data to binary file
        fwrite(fid_lmf,data_lmf,'uint8');
        fwrite(fid_lmr,data_lmr,'uint8');
    catch ME
        util.closefile(dstfile_lmf);
        util.closefile(dstfile_lmr);
        rethrow(ME);
    end
end

% close the files
util.closefile(dstfile_lmf);
util.closefile(dstfile_lmr);
end % END function blc2lm


function bytes = getBLcHeaderBytes(blc)

% application name
ApplicationNameBytes = cast(blc.ApplicationName(1:min(length(blc.ApplicationName),31)),'uint8');
ApplicationNameBytes(end+1:32) = 0; % null-terminated, 32-byte

% comment
CommentBytes = cast(blc.Comment(1:min(255,length(blc.Comment))),'uint8');
CommentBytes(end+1:256) = 0; % null-terminated, 256-byte

% bytes
bytes = zeros(1,BLc.Properties.BasicHeaderSize,'uint8');
bytes(1:8)      = uint8('NEURALCD');
bytes(9:10)     = typecast(cast(BLc.Properties.BasicHeaderSize,'uint16'),'uint8');
bytes(11)       = typecast(cast(blc.FileSpecMajor,'uint8'),'uint8');
bytes(12)       = typecast(cast(blc.FileSpecMinor,'uint8'),'uint8');
bytes(13:16)    = typecast(cast(blc.SamplingRate,'uint32'),'uint8');
bytes(17:17)    = typecast(cast(blc.BitResolution,'uint8'),'uint8');
bytes(18:25)    = typecast(cast(blc.ChannelCount,'uint64'),'uint8');
bytes(26:41)    = typecast(cast(util.datenum2systime(blc.OriginTime),'uint16'),'uint8');
bytes(42:73)    = ApplicationNameBytes;
bytes(74:329)   = CommentBytes;
bytes(330:331)  = typecast(cast(blc.NumSections,'uint16'),'uint8');
bytes(332:332)  = cast(mod(sum(double(bytes(1:BLc.Properties.BasicHeaderSize-1))),256),'uint8');
end % END function getBLcHeaderBytes


function bytes = getBLcChannelInfoBytes(blc)

chanCount = blc.ChannelCount;
chanInfo = blc.ChannelInfo;
minAnalogValue = unique([chanInfo.MinAnalogValue]);
maxAnalogValue = unique([chanInfo.MaxAnalogValue]);
minDigitalValue = unique([chanInfo.MinDigitalValue]);
maxDigitalValue = unique([chanInfo.MaxDigitalValue]);

% pre-allocate byte vector
numBytes = BLc.Properties.ChannelInfoHeaderLength + BLc.Properties.ChannelInfoContentLength*chanCount;
bytes = zeros(1,numBytes,'uint8');

% add the section header
bytes(1:11)     = uint8('CHANNELINFO');
bytes(17:18)    = typecast(cast(BLc.Properties.ChannelInfoHeaderLength,'uint16'),'uint8');
bytes(19:26)    = typecast(cast(numBytes,'uint64'),'uint8');
bytes(27:34)    = typecast(cast(chanCount,'uint64'),'uint8');
bytes(35)       = cast(mod(sum(double(bytes(1:BLc.Properties.ChannelInfoHeaderLength-1))),256),'uint8');

% add the channel info packets
currByte = BLc.Properties.ChannelInfoHeaderLength;
for kk=1:chanCount
    
    % channel label
    LabelBytes = cast(chanInfo(kk).Label(1:min(15,length(chanInfo(kk).Label))),'uint8');
    LabelBytes(end+1:16) = 0; % null-terminated, 16-byte
    
    % units
    UnitBytes = cast(chanInfo(kk).AnalogUnits(1:min(15,length(chanInfo(kk).AnalogUnits))),'uint8');
    UnitBytes(end+1:16) = 0; % null-terminated, 16-byte
    
    % add bytes
    bytes(currByte + (1:8))     = typecast(cast(chanInfo(kk).ChannelNumber,'uint64'),'uint8');
    bytes(currByte + (9:24))    = LabelBytes;
    bytes(currByte + (25:28))   = typecast(cast(minDigitalValue,'int32'),'uint8');
    bytes(currByte + (29:32))   = typecast(cast(maxDigitalValue,'int32'),'uint8');
    bytes(currByte + (33:36))   = typecast(cast(minAnalogValue,'int32'),'uint8');
    bytes(currByte + (37:40))   = typecast(cast(maxAnalogValue,'int32'),'uint8');
    bytes(currByte + (41:56))   = UnitBytes;
    
    % increment currByte
    currByte = currByte + BLc.Properties.ChannelInfoContentLength;
end
end % END function getBLcChannelInfoBytes

function [bytes,numSectionBytes] = getDataSectionHeaderBytes(blc,numFramesInSection,sectionTimestamp,sectionDatetime)
bytesPerFrame = blc.ChannelCount*blc.BitResolution/8;

% compute number of bytes in the section
numSectionBytes = BLc.Properties.DataHeaderLength + numFramesInSection*bytesPerFrame;

% construct bytes
bytes = zeros(1,BLc.Properties.DataHeaderLength,'uint8');
bytes(1:4)    = uint8('DATA');
bytes(17:18)  = typecast(cast(BLc.Properties.DataHeaderLength,'uint16'),'uint8');
bytes(19:26)  = typecast(cast(numSectionBytes,'uint64'),'uint8');
bytes(27:34)  = typecast(cast(numFramesInSection,'uint64'),'uint8');
bytes(35:42)  = typecast(cast(sectionTimestamp,'uint64'),'uint8');
bytes(43:58)  = typecast(cast(util.datenum2systime(sectionDatetime),'uint16'),'uint8');
bytes(59:59)  = mod(sum(double(bytes(1:BLc.Properties.DataHeaderLength-1))),256);
end % END function getDataSectionHeaderBytes

function N = numThreads
N = nan;
if exist('/proc/cpuinfo', 'file')
    % Should work on Linux in Matlab and Octave:
    fid = fopen('/proc/cpuinfo');
    N = length(strfind(char(fread(fid)'), ['processor' 9]));
    fclose(fid);
elseif ispc
    % Windows is untested
    N = str2double(getenv('NUMBER_OF_PROCESSORS'));
elseif ismac
    % Mac is untested
    [~, output] = system('sysctl hw.ncpu | awk ''{print $2}''');
    N = str2double(output);
end
N = min(N,10);
end % END function numThreads