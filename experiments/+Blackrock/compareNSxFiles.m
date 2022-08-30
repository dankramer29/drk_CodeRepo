function st = compareNSxFiles(ns1,ns2)
% COMPARENSXFILES Compare the contents of two NSx files
%
%   COMPARENSXFILES(NS1,NS2)
%   Compare the contenxt of the files specified by the full paths to two
%   NSx files in NS1 and NS2.

% validate inputs
if isa(ns1,'Blackrock.NSx')
    ns1 = fullfile(ns1.SourceDirectory,sprintf('%s%s',ns1.SourceBasename,ns1.SourceExtension));
end
if isa(ns2,'Blackrock.NSx')
    ns2 = fullfile(ns2.SourceDirectory,sprintf('%s%s',ns2.SourceBasename,ns2.SourceExtension));
end
assert(ischar(ns1)&&exist(ns1,'file')==2,'Must provide path to existing file for input 1');
assert(ischar(ns2)&&exist(ns2,'file')==2,'Must provide path to existing file for input 2');
[~,~,ext1] = fileparts(ns1);
[~,~,ext2] = fileparts(ns2);
assert(ismember(lower(ext1),{'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'}),'Must provide path to NSx file, not "%s", for input 1',ext1);
assert(ismember(lower(ext2),{'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'}),'Must provide path to NSx file, not "%s", for input 2',ext2);

% compare the components of the NSx files
fprintf('File 1: %s\n',ns1);
fprintf('File 2: %s\n',ns2);
st1 = compareBasicHeader(ns1,ns2);
st2 = compareExtendedHeaders(ns1,ns2);
st3 = compareDataPackets(ns1,ns2);
st = st1 & st2 & st3;
if st
    fprintf('The files are equivalent.\n');
end



function st = compareBasicHeader(ns1,ns2)
st = true;

% process basic header fields
fields = {'FileTypeID','FileSpec','BytesInHeaders','Label','Comment',...
    'TimestampsPerSample','TimestampTimeResolution',...
    'TimeOrigin','ChannelCount'};
locations = {1:8,9:10,11:14,15:30,31:286,287:290,291:294,295:310,311:314};
tostring = {@nulltermstr,@(x)sprintf('%d.%d',x(1),x(2)),...
    @uint32str,@nulltermstr,@nulltermstr,@uint32str,...
    @uint32str,@(x)util.vec2str(typecast(x,'uint16'),'%d'),...
    @uint32str};

% read the basic header bytes out of the file
[fid1,msg1] = fopen(ns1,'r');
assert(fid1>=0,'Unable to open file ''%s'': %s',ns1,msg1);
[fid2,msg2] = fopen(ns2,'r');
assert(fid2>=0,'Unable to open file ''%s'': %s',ns2,msg2);
try
    bytes1 = fread(fid1,Blackrock.NSx.BasicHeaderSize,'*uint8');
    bytes2 = fread(fid2,Blackrock.NSx.BasicHeaderSize,'*uint8');
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



function st = compareExtendedHeaders(ns1,ns2)
st = true;

fields = {'Type','ChannelID','PhysicalConnector','ConnectorPin',...
    'MinDigitalValue','MaxDigitalValue','MinAnalogValue','MaxAnalogValue',...
    'Units','HighFreqCorner','HighFreqOrder','HighFilterType','LowFreqCorner',...
    'LowFreqOrder','LowFilterType'};
locations = {1:2,3:4,5:20,21,22,23:24,25:26,27:28,29:30,31:46,47:50,...
    51:54,55:56,57:60,61:64,65:66};
tostring = {@char,@uint16str,@(x)char(x+64),@uint8str,@int16str,@int16str,...
    @int16str,@int16str,@nulltermstr,@uint32str,@uint32str,@uint16str,...
    @uint32str,@uint32str,@uint16str};

% read the basic header bytes out of the file
[fid1,msg] = fopen(ns1,'r');
assert(fid1>=0,'Unable to open file "%s": %s',ns1,msg);
fid2 = fopen(ns2,'r');
assert(fid2>=0,'Unable to open file "%s": %s',ns2,msg);

% read the number of extended headers (number of channels)
try
    fseek(fid1,Blackrock.NSx.BasicHeaderSize-4,'bof');
    NumExtendedHeaders1 = fread(fid1,1,'*uint32');
    fseek(fid2,Blackrock.NSx.BasicHeaderSize-4,'bof');
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
    fseek(fid1,Blackrock.NSx.BasicHeaderSize,'bof');
    bytes1 = fread(fid1,66*NumExtendedHeaders1,'*uint8');
    fseek(fid2,Blackrock.NSx.BasicHeaderSize,'bof');
    bytes2 = fread(fid2,66*NumExtendedHeaders2,'*uint8');
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
ch = {};
listIdx = 1;
for cc=1:NumExtendedHeaders1
    offset = (cc-1)*96;
    for nn=1:length(fields)
        if any(ismember(idx_different,offset+locations{nn}))
            list{listIdx} = fields{nn};
            val1{listIdx} = feval(tostring{nn},bytes1(locations{nn}));
            val2{listIdx} = feval(tostring{nn},bytes2(locations{nn}));
            ch{listIdx} = sprintf('%d',cc);
            listIdx = listIdx+1;
        end
    end
end
if ~isempty(list)
    st = false;
    fprintf('The following extended header fields do not match:\n')
    for kk=1:length(list)
        fprintf('\t* %s (channel %d)\n',list{kk},ch{kk});
        fprintf('\t\tFile 1:\t%s\n',val1{kk});
        fprintf('\t\tFile 2:\t%s\n',val2{kk});
    end
end



function st = compareDataPackets(ns1,ns2)
st = true;
% [~,~,ext1] = fileparts(ns1);
% [~,~,ext2] = fileparts(ns2);
% switch lower(ext1)
%     case '.ns1',fs1=500;
%     case '.ns2',fs1=1000;
%     case '.ns3',fs1=2000;
%     case '.ns4',fs1=10000;
%     case '.ns5',fs1=30000;
%     case '.ns6',fs1=30000;
% end
% switch lower(ext2)
%     case '.ns1',fs2=500;
%     case '.ns2',fs2=1000;
%     case '.ns3',fs2=2000;
%     case '.ns4',fs2=10000;
%     case '.ns5',fs2=30000;
%     case '.ns6',fs2=30000;
% end

% read the basic header bytes out of the file
[fid1,msg] = fopen(ns1,'r');
assert(fid1>=0,'Unable to open file ''%s'': %s',ns1,msg);
fid2 = fopen(ns2,'r');
assert(fid2>=0,'Unable to open file ''%s'': %s',ns2,msg);

% get number of bytes
try
    fseek(fid1,0,'eof');
    fseek(fid2,0,'eof');
catch ME
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end
fileBytes1 = ftell(fid1);
fileBytes2 = ftell(fid2);

% read the number of extended headers
try
    fseek(fid1,Blackrock.NSx.BasicHeaderSize-4,'bof');
    NumExtendedHeaders1 = fread(fid1,1,'*uint32');
    fseek(fid2,Blackrock.NSx.BasicHeaderSize-4,'bof');
    NumExtendedHeaders2 = fread(fid2,1,'*uint32');
catch ME
    util.errorMessage(ME);
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end
assert(NumExtendedHeaders1==NumExtendedHeaders2,'Different number of extended headers: %d vs %d',NumExtendedHeaders1,NumExtendedHeaders2);

% seek start of first packet
packetStart1 = Blackrock.NSx.BasicHeaderSize+66*NumExtendedHeaders1;
packetStart2 = Blackrock.NSx.BasicHeaderSize+66*NumExtendedHeaders2;
try
    fseek(fid1,packetStart1,'bof');
    fseek(fid2,packetStart2,'bof');
catch ME
    fclose(fid1);
    fclose(fid2);
    rethrow(ME);
end

currPacket = 0;
while ftell(fid1)<fileBytes1 && ftell(fid2)<fileBytes2
    currPacket = currPacket + 1;
    flagLoadData = true;
    
    % read header bytes
    try
        packetHeaderBytes1 = uint8(fread(fid1,9,'*uint8'));
        packetHeaderBytes2 = uint8(fread(fid2,9,'*uint8'));
        if packetHeaderBytes1(1)~=1
            fprintf('File one has an incorrect packet header byte (expected 1 but found %d)\n',packetHeaderBytes1(1));
            st = false;
        end
        if packetHeaderBytes2(1)~=1
            fprintf('File two has an incorrect packet header byte (expected 1 but found %d)\n',packetHeaderBytes2(1));
            st = false;
        end
        packetTimestamp1 = double(typecast(packetHeaderBytes1(2:5),'uint32'));
        packetTimestamp2 = double(typecast(packetHeaderBytes2(2:5),'uint32'));
        if packetTimestamp1~=packetTimestamp2
            fprintf('Packet %d: mismatched packet timestamp (%d vs %d)\n',currPacket,packetTimestamp1,packetTimestamp2);
            st = false;
        end
        packetNumDataPoints1 = double(typecast(packetHeaderBytes1(6:9),'uint32'));
        packetNumDataPoints2 = double(typecast(packetHeaderBytes2(6:9),'uint32'));
        if packetNumDataPoints1~=packetNumDataPoints2
            fprintf('Packet %d: mismatched packet number of data points (%d vs %d)\n',currPacket,packetNumDataPoints1,packetNumDataPoints2);
            st = false;
            flagLoadData = false;
        end
    catch ME
        fclose(fid1);
        fclose(fid2);
        rethrow(ME);
    end
    
    % check data
    if flagLoadData
        try
            data1 = fread(fid1,[NumExtendedHeaders1 packetNumDataPoints1],'*int16');
            data2 = fread(fid2,[NumExtendedHeaders2 packetNumDataPoints2],'*int16');
        catch ME
            fclose(fid1);
            fclose(fid2);
            rethrow(ME);
        end
        idx_different = data1(:)~=data2(:);
        if any(idx_different)
            fprintf('%d/%d bytes (%.1f%%) in packet %d do not match between the two files\n',nnz(idx_different),numel(idx_different),100*nnz(idx_different)/numel(idx_different),currPacket);
            st = false;
        else
            fprintf('All %d bytes in packet %d are equivalent between the two files\n',length(idx_different),currPacket);
        end
    end
    
    % set packet starts
    packetStart1 = packetStart1 + 2*NumExtendedHeaders1*packetNumDataPoints1 + 9;
    packetStart2 = packetStart2 + 2*NumExtendedHeaders2*packetNumDataPoints2 + 9;
    try
        fseek(fid1,packetStart1,'bof');
        fseek(fid2,packetStart2,'bof');
    catch ME
        fclose(fid1);
        fclose(fid2);
        rethrow(ME);
    end
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