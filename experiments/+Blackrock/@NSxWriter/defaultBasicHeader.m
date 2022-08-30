function bh = defaultBasicHeader
numch = 128;

% define basic header
bh.FileTypeID              = 'NEURALCD';
bh.FileSpecMajor           = 2;
bh.FileSpecMinor           = 3;
bh.BytesInHeaders          = 336 + 66*numch;
bh.LabelBytes              = '';
bh.CommentBytes            = '';
bh.TimestampsPerSample     = 30e3;
bh.TimestampTimeResolution = 30e3;
bh.TimeOrigin              = Blackrock.Helper.datenum2systime(now);
bh.ChannelCount            = numch;