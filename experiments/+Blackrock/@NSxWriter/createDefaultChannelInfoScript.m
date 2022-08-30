function createDefaultChannelInfoScript(nsfile,dcfile)

assert(ischar(nsfile)&&exist(nsfile,'file')==2,'Must provide a valid path to an existing NSx file');
ns = Blackrock.NSx(nsfile);

thisfile = mfilename('fullpath');
nsdir = fileparts(thisfile);
if nargin<2||isempty(dcfile)
    dcfile = fullfile(nsdir,'defaultChannelInfo.m');
end
assert(exist(dcfile,'file')~=2,'Cannot overwrite existing file');

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
    for cc=1:length(ns.ChannelInfo)
        fprintf(fid,'\n%% Channel %d\n',cc);
        fprintf(fid,'ci(%d).Type = ''CC'';\n',cc);
        fprintf(fid,'ci(%d).ChannelID = %d;\n',cc,ns.ChannelInfo(cc).ChannelID);
        fprintf(fid,'ci(%d).ElectrodeID = %d;\n',cc,ns.ChannelInfo(cc).ElectrodeID);
        fprintf(fid,'ci(%d).Label = ''%s'';\n',cc,ns.ChannelInfo(cc).Label);
        fprintf(fid,'ci(%d).PhysicalConnector = ''%s'';\n',cc,ns.ChannelInfo(cc).PhysicalConnector);
        fprintf(fid,'ci(%d).ConnectorPin = %d;\n',cc,ns.ChannelInfo(cc).ConnectorPin);
        fprintf(fid,'ci(%d).MinDigitalValue = %d;\n',cc,ns.ChannelInfo(cc).MinDigitalValue);
        fprintf(fid,'ci(%d).MaxDigitalValue = %d;\n',cc,ns.ChannelInfo(cc).MaxDigitalValue);
        fprintf(fid,'ci(%d).MinAnalogValue = %d;\n',cc,ns.ChannelInfo(cc).MinAnalogValue);
        fprintf(fid,'ci(%d).MaxAnalogValue = %d;\n',cc,ns.ChannelInfo(cc).MaxAnalogValue);
        fprintf(fid,'ci(%d).Units = %d;\n',cc,ns.ChannelInfo(cc).Units);
        fprintf(fid,'ci(%d).HighFreqCorner = %d;\n',cc,ns.ChannelInfo(cc).HighFreqCorner);
        fprintf(fid,'ci(%d).HighFreqOrder = %d;\n',cc,ns.ChannelInfo(cc).HighFreqOrder);
        fprintf(fid,'ci(%d).HighFilterType = ''%s'';\n',cc,ns.ChannelInfo(cc).HighFilterType);
        fprintf(fid,'ci(%d).LowFreqCorner = %d;\n',cc,ns.ChannelInfo(cc).LowFreqCorner);
        fprintf(fid,'ci(%d).LowFreqOrder = %d;\n',cc,ns.ChannelInfo(cc).LowFreqOrder);
        fprintf(fid,'ci(%d).LowFilterType = ''%s'';\n',cc,ns.ChannelInfo(cc).LowFilterType);
    end
catch ME
    util.errorMessage(ME);
    fclose(fid);
    return;
end

fclose(fid);