function st = compareNEVFiles(nv1,nv2)
% COMPARENEVFILES Compare the contents of two NEV files
%
%   COMPARENEVFILES(NV1,NV2)
%   Compare the contents of the files specified by the full paths to two
%   NEV files in NV1 and NV2.

% validate inputs
if isa(nv1,'Blackrock.NEV')
    nv1 = fullfile(nv1.SourceDirectory,sprintf('%s%s',nv1.SourceBasename,nv1.SourceExtension));
end
if isa(nv2,'Blackrock.NEV')
    nv2 = fullfile(nv2.SourceDirectory,sprintf('%s%s',nv2.SourceBasename,nv2.SourceExtension));
end
assert(ischar(nv1)&&exist(nv1,'file')==2,'Must provide path to existing file for input 1');
assert(ischar(nv2)&&exist(nv2,'file')==2,'Must provide path to existing file for input 2');
[~,~,ext1] = fileparts(nv1);
[~,~,ext2] = fileparts(nv2);
assert(strcmpi(ext1,'.nev'),'Must provide path to NEV file, not ''%s'', for input 1',ext1);
assert(strcmpi(ext2,'.nev'),'Must provide path to NEV file, not ''%s'', for input 2',ext2);

% compare the components of the NEV files
fprintf('File 1: %s\n',ns1);
fprintf('File 2: %s\n',ns2);
st1 = compareBasicHeader(nv1,nv2);
st2 = compareExtendedHeaders(nv1,nv2);
st3 = compareDataPackets(nv1,nv2);
st = st1 & st2 & st3;
if st
    fprintf('The files are equivalent.\n');
end



function st = compareBasicHeader(nv1,nv2)
st = true;

% process basic header fields
fields = {'FileTypeID','FileSpec','AdditionalFlags','BytesInHeaders',...
    'BytesInDataPackets','TimeResolutionOfTimeStamps','TimeResolutionOfSamples',...
    'TimeOrigin','ApplicationToCreateFile','CommentField','NumExtendedHeaders'};
locations = {1:8,9:10,11:12,13:16,17:20,21:24,25:28,29:44,45:76,77:332,333:336};
tostring = {@nulltermstr,@(x)sprintf('%d.%d',x(1),x(2)),...
    @uint16str,@uint32str,@uint32str,@uint32str,...
    @uint32str,@(x)util.vec2str(typecast(x,'uint16'),'%d'),...
    @nulltermstr,@nulltermstr,@uint32str};

% read the basic header bytes out of the file
[fid1,msg1] = fopen(nv1,'r');
assert(fid1>=0,'Unable to open file ''%s'': %s',nv1,msg1);
[fid2,msg2] = fopen(nv2,'r');
assert(fid2>=0,'Unable to open file ''%s'': %s',nv2,msg2);
try
    bytes1 = fread(fid1,Blackrock.NEV.BasicHeaderSize,'*uint8');
    bytes2 = fread(fid2,Blackrock.NEV.BasicHeaderSize,'*uint8');
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    return;
end
fclose(fid1);
fclose(fid2);

% identify unequal bytes
assert(length(bytes1)==length(bytes2),'Different number of bytes in basic header: %d (file 1), %d (file 2)',length(bytes1),length(bytes2));
idx_different = find(bytes1~=bytes2);
if isempty(idx_different)
    fprintf('All %d basic header bytes are equivalent between the two files.\n',length(bytes1));
    return;
end

% loop over fields
val1 = {};
val2 = {};
list = {};
listIdx = 1;
for kk=1:length(fields)
    if any(ismember(idx_different,locations{kk}))
        list{listIdx} = fields{kk};
        val1{listIdx} = feval(tostring{kk},bytes1(locations{kk}));
        val2{listIdx} = feval(tostring{kk},bytes2(locations{kk}));
        listIdx = listIdx+1;
    end
end
if ~isempty(list)
    st = false;
    fprintf('The following basic header fields do not match:\n')
    for kk=1:length(list)
        fprintf('\t* %s\n',list{kk});
        fprintf('\t\tFile 1:\t%s\n',val1{kk});
        fprintf('\t\tFile 2:\t%s\n',val2{kk});
    end
end



function st = compareExtendedHeaders(nv1,nv2)
st = true;

pktid = {'ARRAYNME','ECOMMENT','CCOMMENT','MAPFILE','NEUEVWAV',...
    'NEUEVLBL','NEUEVFLT','DIGLABEL','VIDEOSYN','TRACKOBJ'};
digtypes = {'serial','parallel'};
typefcn = {@(x)'ArrayName',@(x)'ExtraComment',@(x)'ContinuedComment',@(x)'Mapfile',...
    @(x)sprintf('NeuralEventWaveform (Channel %d)',typecast(x(9:10),'uint16')),...
    @(x)sprintf('NeuralEventLabel (Channel %d)',typecast(x(9:10),'uint16')),...
    @(x)sprintf('NeuralEventFilter (Channel %0)',typecast(x(9:10),'uint16')),...
    @(x)sprintf('DigitalLabel (%s)',digtypes{x(25)+1}),@(x)'VideoSynchronization',...
    @(x)'TrackableObjectInformation'};
tostr = {@(x,y)deblank(char(x)),@(x,y)deblank(char(x)),@(x,y)deblank(char(x)),...
    @(x,y)deblank(char(x)),@neuevwav2str,@neuevlbl2str,@neuevflt2str,@diglabel2str,...
    @(x,y)'VideoSync not supported',@(x,y)'TrackObj not supported'};

% read the basic header bytes out of the file
[fid1,msg] = fopen(nv1,'r');
assert(fid1>=0,'Unable to open file ''%s'': %s',nv1,msg);
fid2 = fopen(nv2,'r');
assert(fid2>=0,'Unable to open file ''%s'': %s',nv2,msg);

% read the number of extended headers
try
    fseek(fid1,Blackrock.NEV.BasicHeaderSize-4,'bof');
    NumExtendedHeaders1 = fread(fid1,1,'*uint32');
    fseek(fid2,Blackrock.NEV.BasicHeaderSize-4,'bof');
    NumExtendedHeaders2 = fread(fid2,1,'*uint32');
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end
assert(NumExtendedHeaders1==NumExtendedHeaders2,'Different number of extended headers: %d vs %d',NumExtendedHeaders1,NumExtendedHeaders2);

% read the extended headers
try
    fseek(fid1,Blackrock.NEV.BasicHeaderSize,'bof');
    bytes1 = fread(fid1,32*NumExtendedHeaders1,'*uint8');
    fseek(fid2,Blackrock.NEV.BasicHeaderSize,'bof');
    bytes2 = fread(fid2,32*NumExtendedHeaders2,'*uint8');
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end
fclose(fid1);
fclose(fid2);

% byte operations
assert(length(bytes1)==length(bytes2),'Different number of bytes in extended headers: %d (file 1), %d (file 2)',length(bytes1),length(bytes2));
idx_different = find(bytes1~=bytes2);
if isempty(idx_different)
    fprintf('All %d extended header bytes are equivalent between the two files.\n',length(bytes1));
    return;
end
str1 = char(bytes1(:)');
str2 = char(bytes2(:)');

% loop over packet types
list = {};
val1 = {};
val2 = {};
listIdx = 1;
for nn=1:length(pktid)
    idx_nn1 = strfind(str1,pktid{nn});
    idx_nn2 = strfind(str2,pktid{nn});
    if any(idx_nn1) || any(idx_nn2)
        has = 1; hasnot = 2;
        if any(idx_nn2)
            has = 2; hasnot = 1;
        end
        assert(~isempty(idx_nn1)&&~isempty(idx_nn2),'Packet ''%s'' found in file %d but not in file %d',pktid{nn},has,hasnot);
    end
    assert(length(idx_nn1)==length(idx_nn2),'Packet ''%s'' found in different quantities (file 1 - %d, file 2 - %d)',pktid{nn},length(idx_nn1),length(idx_nn2));
    assert(all(idx_nn1==idx_nn2),'Packet ''%s'' found in different locations in the two files',pktid{nn});
    for kk=1:length(idx_nn1)
        if any(ismember(idx_different,idx_nn1(kk)+(0:31)))
            which = find(ismember(idx_nn1(kk)+(0:31),idx_different));
            list{listIdx} = feval(typefcn{nn},bytes1(idx_nn1(kk)+(0:31)));
            val1{listIdx} = feval(tostr{nn},bytes1(idx_nn1(kk)+(0:31)),which);
            val2{listIdx} = feval(tostr{nn},bytes2(idx_nn1(kk)+(0:31)),which);
            listIdx = listIdx + 1;
        end
    end
end
if ~isempty(list)
    st = false;
    fprintf('The following extended header fields do not match:\n')
    for kk=1:length(list)
        fprintf('\t* %s\n',list{kk});
        fprintf('\t\tFile 1:\t%s\n',val1{kk});
        fprintf('\t\tFile 2:\t%s\n',val2{kk});
    end
end



function st = compareDataPackets(nv1,nv2)
st = true;

% read the basic header bytes out of the file
[fid1,msg] = fopen(nv1,'r');
assert(fid1>=0,'Unable to open file ''%s'': %s',nv1,msg);
fid2 = fopen(nv2,'r');
assert(fid2>=0,'Unable to open file ''%s'': %s',nv2,msg);

% read the number of extended headers
try
    fseek(fid1,Blackrock.NEV.BasicHeaderSize-4,'bof');
    NumExtendedHeaders1 = fread(fid1,1,'*uint32');
    fseek(fid2,Blackrock.NEV.BasicHeaderSize-4,'bof');
    NumExtendedHeaders2 = fread(fid2,1,'*uint32');
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end
assert(NumExtendedHeaders1==NumExtendedHeaders2,'Different number of extended headers: %d vs %d',NumExtendedHeaders1,NumExtendedHeaders2);

dpstart1 = Blackrock.NEV.BasicHeaderSize+32*NumExtendedHeaders1;
dpstart2 = Blackrock.NEV.BasicHeaderSize+32*NumExtendedHeaders2;

% get the file length
try
    fseek(fid1,0,'eof');
    flen1 = ftell(fid1);
    fseek(fid2,0,'eof');
    flen2 = ftell(fid2);
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end

% read the data packets
try
    fseek(fid1,dpstart1,'bof');
    bytes1 = fread(fid1,flen1-dpstart1,'*uint8');
    fseek(fid2,dpstart2,'bof');
    bytes2 = fread(fid2,flen2-dpstart2,'*uint8');
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end
fclose(fid1);
fclose(fid2);

assert(length(bytes1)==length(bytes2),'Different number of bytes: %d (nv), %d (nvw)',length(bytes1),length(bytes2));
idx_different = find(bytes1~=bytes2);
if isempty(idx_different)
    fprintf('All %d data packet bytes are equivalent between the two files.\n',length(bytes1));
    return;
else
    fprintf('Some data packet bytes do not match, but further analysis has not been implemented yet.\n');
    st = false;
end



function str = nulltermstr(bytes)
zidx = find(bytes==0,1,'first');
if isempty(zidx)
    zidx = length(bytes);
else
    zidx = zidx-1;
end
str = deblank(char(bytes(1:zidx)));



function str = int16str(bytes)
str = sprintf('%d',typecast(bytes,'int16'));



function str = uint16str(bytes)
str = sprintf('%d',typecast(bytes,'uint16'));



function str = uint32str(bytes)
str = sprintf('%d',typecast(bytes,'uint32'));



function str = nofrmtstr(bytes)
str = sprintf('%d',bytes);



function str = neuevwav2str(bytes,idx_different)
fields = {'ChannelID','PhysicalConnector','ConnectorPin','DigFactor',...
    'EnergyThresh','HighThresh','LowThresh','NumSortedUnits',...
    'BytesPerWaveform','SpikeWidth'};
locations = {9:10,11,12,13:14,15:16,17:18,19:20,21,22,23:24};
tostr = {@uint16str,@(x)deblank(char(64+x)),@nofrmtstr,@uint16str,...
    @uint16str,@int16str,@int16str,@nofrmtstr,@nofrmtstr,@uint16str};
str = procbytes(bytes,idx_different,fields,locations,tostr);



function str = neuevlbl2str(bytes,idx_different)
fields = {'ChannelID','Label'};
locations = {9:10,11:26};
tostr = {@uint16str,@nulltermstr};
str = procbytes(bytes,idx_different,fields,locations,tostr);



function str = neuevflt2str(bytes,idx_different)
fields = {'ChannelID','HighFreqCorner','HighFreqOrder','HighFiltType',...
    'LowFreqCorner','LowFreqOrder','LowFiltType'};
locations = {9:10,11:14,15:18,19:20,21:24,25:28,29:30};
tostr = {@uint16str,@uint32str,@uint32str,@uint16str,@uint32str,...
    @uint32str,@uint16str};
str = procbytes(bytes,idx_different,fields,locations,tostr);



function str = diglabel2str(bytes,idx_different)
fields = {'Label','Mode'};
locations = {9:24,25};
tostr = {@nulltermstr,@nofrmtstr};
str = procbytes(bytes,idx_different,fields,locations,tostr);



function str = procbytes(bytes,idx_different,fields,locations,tostr)
str = '';
for kk=1:length(fields)
    if any(ismember(idx_different,locations{kk}))
        str = sprintf('%s%s (%s), ',str,fields{kk},feval(tostr{kk},bytes(locations{kk})));
    end
end
str(end-1:end) = [];