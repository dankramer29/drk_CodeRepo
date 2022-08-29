function createDefaultChannelInfoScript(nvfile)

assert(ischar(nvfile)&&exist(nvfile,'file')==2,'Must provide a valid path to an existing NEV file');
nv = Blackrock.NEV(nvfile);

thisfile = mfilename('fullpath');
nvdir = fileparts(thisfile);
dcfile = fullfile(nvdir,'defaultChannelInfo.m');

% open the defaultChannelInfo.m file
try
    [fid,msg] = fopen(dcfile,'wt');
    assert(fid>=0,'Could not open file: %s',msg);
catch ME
    util.errorMessage(ME);
    return;
end

% write out the ChannelInfo struct to the file
try
    fprintf(fid,'function ci = defaultChannelInfo\n');
    for cc = 1:length(nv.ChannelInfo)
        fprintf(fid,'\n%% Channel %d\n',cc);
        fprintf(fid,'ci(%d).ChannelID = %d;\n',cc,nv.ChannelInfo(cc).ChannelID);
        fprintf(fid,'ci(%d).PhysicalConnector = ''%s'';\n',cc,nv.ChannelInfo(cc).PhysicalConnector);
        fprintf(fid,'ci(%d).ConnectorPin = %d;\n',cc,nv.ChannelInfo(cc).ConnectorPin);
        fprintf(fid,'ci(%d).DigitizationFactor = %d;\n',cc,nv.ChannelInfo(cc).DigitizationFactor);
        fprintf(fid,'ci(%d).EnergyThreshold = %d;\n',cc,nv.ChannelInfo(cc).EnergyThreshold);
        fprintf(fid,'ci(%d).HighThreshold = %d;\n',cc,nv.ChannelInfo(cc).HighThreshold);
        fprintf(fid,'ci(%d).LowThreshold = %d;\n',cc,nv.ChannelInfo(cc).LowThreshold);
        fprintf(fid,'ci(%d).NumSortedUnits = %d;\n',cc,nv.ChannelInfo(cc).LowThreshold);
        fprintf(fid,'ci(%d).BytesPerWaveformSample = %d;\n',cc,nv.ChannelInfo(cc).BytesPerWaveformSample);
        fprintf(fid,'ci(%d).SpikeWidthSamples = %d;\n',cc,nv.ChannelInfo(cc).SpikeWidthSamples);
        fprintf(fid,'ci(%d).Label = ''%s'';\n',cc,nv.ChannelInfo(cc).Label);
        fprintf(fid,'ci(%d).HighFreqCorner = %d;\n',cc,nv.ChannelInfo(cc).HighFreqCorner);
        fprintf(fid,'ci(%d).HighFreqOrder = %d;\n',cc,nv.ChannelInfo(cc).HighFreqOrder);
        fprintf(fid,'ci(%d).HighFilterType = ''%s'';\n',cc,nv.ChannelInfo(cc).HighFilterType);
        fprintf(fid,'ci(%d).LowFreqCorner = %d;\n',cc,nv.ChannelInfo(cc).LowFreqCorner);
        fprintf(fid,'ci(%d).LowFreqOrder = %d;\n',cc,nv.ChannelInfo(cc).LowFreqOrder);
        fprintf(fid,'ci(%d).LowFilterType = ''%s'';\n',cc,nv.ChannelInfo(cc).LowFilterType);
    end
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

fclose(fid);