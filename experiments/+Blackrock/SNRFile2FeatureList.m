function featureList = SNRFile2FeatureList(snrFile)

% generate list of sorted/unsorted units based on BlackRock SNR file
% example input : snrFile='Y:\P3\20130521\NSP1\20130521_NSP1_snr.txt';

% validate input
assert(ischar(snrFile),'Must provide char path for snrFile input, not "%s"',class(snrFile));
assert(exist(snrFile,'file')==2,'Could not find SNR file "%s"',snrFile);

% read the file
fid = fopen(snrFile); % open file
try
    filedata = textscan(fid,'%u %u %u %u %f %f %*[^\n]','HeaderLines',10); % read info
catch ME
    msg = util.errorMessage(ME,'noscreen','nolink');
    fclose(fid);
    error('Could not read SNR file: %s',msg);
end
fclose(fid); % close file

% create output array with columns "channel","unit"
featureList = zeros(size(filedata{1},1),2); % [channel,unit]
for m=1:size(filedata{1},1) % add features
    featureList(m,:) = [filedata{1}(m),filedata{2}(m)];
end