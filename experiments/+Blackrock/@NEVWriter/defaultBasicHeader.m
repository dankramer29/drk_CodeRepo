function bh = defaultBasicHeader

% define basic header
bh.FileTypeID              = 'NEURALEV';
bh.FileSpecMajor           = 2;
bh.FileSpecMinor           = 3;
bh.AdditionalFlags         = 1; % all waveforms 16-bit
bh.BytesInHeaders          = 336 + 13888;
bh.BytesPerDataPacket      = 104;
bh.ResolutionTimestamps    = 30e3;
bh.ResolutionSamples       = 30e3;
bh.TimeOrigin              = Blackrock.Helper.datenum2systime(now);
bh.ApplicationName         = sprintf('Blackrock.NEVWriter v%d.%d',Blackrock.NEVWriter.versionMajor,Blackrock.NEVWriter.versionMinor);
bh.Comment                 = '';
bh.NumExtendedHeaders      = 434;