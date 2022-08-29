function data = read(this,varargin)
% READ Read data from the BLC file
%
%   DATA = READ(THIS)
%   Read all data available in the BLC file.
%
%   DATA = READ(THIS,'UniformOutput',TRUE|FALSE)
%   Specify whether to return data in cell arrays (FALSE) or as a
%   concatenated matrix (TRUE). This only matters when there are multiple
%   data sections (i.e., noncontiguous data in the file): the sections will
%   be returned in separate cell arrays, or they will be appended with the
%   appropriate number of NaNs representing skipped data.
%
%   DATA = READ(...,NAME,VALUE,...)
%   Specify optional NAME-VALUE pairs as listed below.
%
%   NAME            VALUE
%   channels        vector of channels to read, char of single channel
%                   label, or cell array of channel labels.
%
%   points          vector [START END] data points, only interpreted
%                   relative to file start (context input described below
%                   has no effect).
%
%   time            numerical vector [START,END] (specify time in seconds,
%                   or as datetime or duration classes) or cell {START,END}
%                   (specify time as string; see "datestrformat" below).
%                   Values will be interpreted based on "context".
%
%   context         string 'absolute', 'origin', 'file', or 'section'. With
%                   ABSOLUTE, zero is the beginning of Gregorian calendar
%                   time. With ORIGIN, zero is the file's OriginTime. With
%                   FILE, zero is the first sample in the file. With
%                   SECTION, zero is the first sample of the indicated
%                   section (see 'section' input below). Default is FILE.
%
%   section         specify the section to read data from. Only
%                   applicable when 'context' is set to 'section'.
%
%   datestrformat   provide the format (datetime style) for interpreting
%                   date strings in ABSOLUTE context. Defalt value 
%                   'dd-MMM-yyyy HH:mm:ss'. Note that in ORIGIN and FILE
%                   contexts, strings must be colon-separated values, where
%                   right-most is seconds, next left is minutes, etc. (like
%                   'dd:HH:mm:ss.SSS' for example).
%
%   units           string 'V', 'mV', 'uV' (case-insensitive), or -1 to
%                   read as stored
%
%   class           specify data class for output, e.g., 'double' or
%                   'int16'. Note that the data will be stored internally
%                   as 'double' format before converting to the output
%                   class.

% process simple inputs
[varargin,flag_uniform_output] = util.argkeyval('UniformOutput',varargin,true);
[varargin,user_requested_channels] = util.argkeyval('channels',varargin,1:this.ChannelCount,2);
[varargin,user_requested_units] = util.argkeyval('units',varargin,-1);
[varargin,user_requested_data_class] = util.argkeyval('class',varargin,'double');
[varargin,user_requested_context] = util.argkeyval('context',varargin,'file',7);
[varargin,user_requested_section] = util.argkeyval('section',varargin,nan);
[varargin,reqpoints] = util.argkeyval('points',varargin,nan,5);
[varargin,reqtime] = util.argkeyval('times',varargin,nan,4);
[varargin,datestr_format] = util.argkeyval('datestrformat',varargin,nan,8);
this.hDebug.log(sprintf('User requested channels %s',util.vec2str(user_requested_channels)),'debug');
this.hDebug.log(sprintf('User requested units %s',upper(user_requested_units)),'debug');
this.hDebug.log(sprintf('User requested data class %s',upper(user_requested_data_class)),'debug');
this.hDebug.log(sprintf('User requested context %s',upper(user_requested_context)),'debug');
this.hDebug.log(sprintf('User requested section %d',user_requested_section),'debug');

% SECTION
% select largest section if none provided
if isnan(user_requested_section)
    [~,user_requested_section] = max([this.DataInfo.NumRecords]);
end

% CHANNELS
% convert char channel labels to numeric channel numbers
if ischar(user_requested_channels)
    idxRequestedChannel = find(strcmpi(user_requested_channels,{this.ChannelInfo.Label}),1,'first');
    assert(~isempty(idxRequestedChannel),'Could not find channel labeled "%s"',user_requested_channels);
    user_requested_channels = idxRequestedChannel;
elseif iscell(user_requested_channels)
    channelLabels = {this.ChannelInfo.Label};
    idxRequestedChannel = cellfun(@(x)find(strcmpi(x,channelLabels),1,'first'),user_requested_channels,'UniformOutput',false);
    assert(~any(cellfun(@isempty,idxRequestedChannel)),'Could not find channel labeled "%s"',user_requested_channels{find(cellfun(@isempty,idxRequestedChannel),1,'first')});
    assert(all(cellfun(@length,idxRequestedChannel)==1),'Found mismatched label "%s"',user_requested_channels{find(cellfun(@length,idxRequestedChannel)~=1,1,'first')});
    user_requested_channels = cat(2,idxRequestedChannel{:});
end
assert(isnumeric(user_requested_channels),'Must provide numeric channel index vector');

% POINTS/TIME
% convert point/time input from source context into 'file' context
user_provided_points = iscell(reqpoints)||any(isa(reqpoints,'datetime'))||any(isa(reqpoints,'duration'))||~any(isnan(reqpoints(:)));
user_provided_times = iscell(reqtime)||any(isa(reqtime,'datetime'))||any(isa(reqtime,'duration'))||~any(isnan(reqtime(:)));
if ~user_provided_times && ~user_provided_points
    user_requested_data_points = nan;
elseif user_provided_points
    
    % possible input formats include
    % [START END]
    %   - integer number of points
    %
    %            ABSOLUTE    ORIGIN    FILE     SECTION
    % int           -          x        x        x
    
    % convert context to 'file'
    assert(length(reqpoints)==2,'Input must be 1x2 vector containing [START END]');
    orig_reqpoints = reqpoints;
    switch lower(user_requested_context)
        case 'absolute'
            
            % no support for "absolute" context
            error('"Absolute" context not supported for "point" inputs');
        case 'origin'
            
            % subtract offset from origin to file start
            origin_to_file_offset = seconds( this.OriginTime-this.DataInfo(1).Datetime );
            reqpoints = reqpoints - round( origin_to_file_offset*this.SamplingRate ) + 1;
        case 'file'
            
            % nothing to do
        case 'section'
            
            % add in the offset: duration of each prior section
            for kk=1:user_requested_section-1
                reqpoints = reqpoints + round(seconds(this.DataInfo(kk).Duration)*this.SamplingRate);
            end
    end
    assert(reqpoints(2)>=reqpoints(1),'Requested start/end points [%d %d] must be non-decreasing',orig_reqpoints(1),orig_reqpoints(2));
    assert(reqpoints(1)>=0,'Requested start time %.2f seconds prior to first data in this file',abs(reqtime(1)));
    points_in_file = round(seconds(this.DataEndTime-this.DataStartTime)*this.SamplingRate);
    assert(reqpoints(2)<=points_in_file,'Requested end point is %d points after the end of data in this file',...
        reqpoints(2)-points_in_file);
    
    % save requested points
    user_requested_data_points = reqpoints;
    this.hDebug.log(sprintf('User requested POINTS [%d %d]',reqpoints(1),reqpoints(2)),'debug');
elseif user_provided_times
    
    % possible input formats include
    % [START END]
    %   - integer/floating point number of seconds
    %   - datetime (absolute time specification)
    %   - duration (relative to something: origin, file, section)
    % {START,END}
    %   - char strings
    %
    %            ABSOLUTE    ORIGIN    FILE     SECTION
    % int/fp        -          x        x        x
    % datetime      x          -        -        -
    % duration      -          x        x        x
    % cell/char     x          x*       x*       x
    %
    % NOTE* For ORIGIN and FILE context, the input will be treated as an
    % amount of time since the beginning of the day, i.e., 
    % 
    %  >> tm = datetime(tm,'InputFormat',datestrFormat) - datetime('today')
    %
    % At the time of writing, this was the cleanest way to convert char
    % input into a duration.
    this.hDebug.log('Check recent commit to ensure the above note about beginning of the day is still true','warn');
    
    % convert context to 'file' and units to 'seconds'
    assert(length(reqtime)==2,'Input must be 1x2 vector containing [START END]');
    orig_reqtime = reqtime;
    switch lower(user_requested_context)
        case 'absolute'
            if isnan(datestr_format),datestr_format='dd-MMM-yyyy HH:mm:ss';end
            if iscell(reqtime)&&all(cellfun(@ischar,reqtime))
                reqtime = datetime(reqtime,'InputFormat',datestr_format);
                reqtime = seconds(reqtime - this.DataInfo(1).Datetime);
            elseif isa(reqtime,'datetime')
                reqtime = seconds(reqtime - this.DataInfo(1).Datetime);
            elseif isa(reqtime,'duration')
                error('In "absolute" context, time input cannot be "duration" class');
            else
                error('Unknown class "%s" for time input with context "%s"',class(reqtime),user_requested_context);
            end
        case 'origin'
            if iscell(reqtime)&&all(cellfun(@ischar,reqtime))
                numsec = [86400 3600 60 1];
                for kk=1:length(reqtime)
                    reqtime{kk} = str2double(strsplit(reqtime{kk},':'));
                    reqtime{kk} = [zeros(1,length(numsec)-length(reqtime{kk})) reqtime{kk}];
                    reqtime{kk} = seconds(sum(reqtime{kk}.*numsec));
                end
                reqtime = cat(2,reqtime{:});
                reqtime = seconds( (this.OriginTime-this.DataInfo(1).Datetime) + reqtime );
            elseif isa(reqtime,'datetime')
                error('In "origin" context, time input cannot be "datetime" class');
            elseif isa(reqtime,'duration')
                reqtime = seconds( (this.OriginTime-this.DataInfo(1).Datetime) + reqtime );
            else
                assert(isnumeric(reqtime),'Unknown class "%s" for time input with context "%s"',class(reqtime),user_requested_context);
                reqtime = seconds( (this.OriginTime-this.DataInfo(1).Datetime) ) + reqtime;
            end
        case 'file'
            if iscell(reqtime)&&all(cellfun(@ischar,reqtime))
                numsec = [86400 3600 60 1];
                for kk=1:length(reqtime)
                    reqtime{kk} = str2double(strsplit(reqtime{kk},':'));
                    reqtime{kk} = [zeros(1,length(numsec)-length(reqtime{kk})) reqtime{kk}];
                    reqtime{kk} = sum(reqtime{kk}.*numsec);
                end
                reqtime = cat(2,reqtime{:});
            elseif isa(reqtime,'datetime')
                error('In "origin" context, time input cannot be "datetime" class');
            elseif isa(reqtime,'duration')
                reqtime = seconds(reqtime);
            else
                assert(isnumeric(reqtime),'Unknown class "%s" for time input with context "%s"',class(reqtime),user_requested_context);
            end
        case 'section'
            if iscell(reqtime)&&all(cellfun(@ischar,reqtime))
                numsec = [86400 3600 60 1];
                for kk=1:length(reqtime)
                    reqtime{kk} = str2double(strsplit(reqtime{kk},':'));
                    reqtime{kk} = [zeros(1,length(numsec)-length(reqtime{kk})) reqtime{kk}];
                    reqtime{kk} = sum(reqtime{kk}.*numsec);
                end
                reqtime = cat(2,reqtime{:});
            elseif isa(reqtime,'datetime')
                error('In "section" context, time input cannot be "datetime" class');
            elseif isa(reqtime,'duration')
                reqtime = seconds(reqtime);
            else
                assert(isnumeric(reqtime),'Unknown class "%s" for time input with context "%s"',class(reqtime),user_requested_context);
            end
            
            % add in the offset: duration of each prior section
            for kk=1:user_requested_section-1
                reqtime = reqtime + seconds(this.DataInfo(kk).Duration);
            end
    end
    assert(reqtime(2)>reqtime(1),'Requested start/end times [%.2f %.2f] must be monotonically increasing',orig_reqtime(1),orig_reqtime(2));
    assert(reqtime(1)>=0,'Requested start time %.2f seconds prior to first data in this file',abs(reqtime(1)));
    assert(reqtime(2)<=seconds(this.DataEndTime-this.DataStartTime),'Requested end time is %.2f seconds after the end of data in this file',...
        reqtime(2)-seconds(this.DataEndTime-this.DataStartTime));
    
    % convert from seconds to samples (data points)
    assert(isnumeric(reqtime),'After processing inputs, expected numeric class but found "%s"',class(reqtime));
    this.hDebug.log(sprintf('User requested TIMES [%.3f %.3f]',reqtime(1),reqtime(2)),'debug');
    user_requested_data_points = [round(reqtime(1)*this.SamplingRate)+1 round(reqtime(2)*this.SamplingRate)];
else
    error('Provide either "points" or "time" input, but not both');
end
util.argempty(varargin);

% for convenience, compute running start/end (relative to
% the file, i.e. subtract off initial timestamp)
section_start = arrayfun(@(x)x.Timestamp-this.DataInfo(1).Timestamp+1,this.DataInfo);
section_end = arrayfun(@(x,y)x+y.NumRecords-1,section_start,this.DataInfo);

% check whether user provided times/points and infer sections
if isnan(user_requested_data_points)
    
    % user provided no input - default to largest section
    [~,which] = max([this.DataInfo.NumRecords]);
    user_requested_data_sections = {which}; % default largest data section
    user_requested_data_points = {[section_start(which) section_end(which)]}; % default all data points
else
    
    % user provided the data points; allocate across data sections
    % find data sections matching start/end of the requested data points
    idx_section_start = find(user_requested_data_points(1)>=section_start);
    idx_section_end = find(section_end>=user_requested_data_points(2));
    
    % validate start/end findings
    assert(~isempty(idx_section_start),'Could not identify a matching data section for starting data point %d',user_requested_data_points(1));
    assert(~isempty(idx_section_end),'Could not identify a matching data section for ending data point %d',user_requested_data_points(2));
    
    % make sure there is only one (max; possible zero) datasection that
    % contains the entire window
    idx_section = intersect(idx_section_start,idx_section_end);
    assert(numel(idx_section)<=1,'Multiple data sections %s contain the requested datapoint window [%d %d]',...
        util.vec2str(idx_section),user_requested_data_points(1),user_requested_data_points(2));
    
    % loop over data sections and allocate data points
    % determine first and last sections matching
    idx_section_start = max(idx_section_start);
    idx_section_end = min(idx_section_end);
    
    % split up the requested data points among the sections
    user_requested_data_sections = arrayfun(@(x)x,idx_section_start:idx_section_end,'UniformOutput',false);
    tmp_data_points = user_requested_data_points;
    st = [tmp_data_points(1) section_start(cellfun(@(x)x,user_requested_data_sections(2:end)))]; % first data section starts midway through
    et = [section_end(cellfun(@(x)x,user_requested_data_sections(1:end-1))) tmp_data_points(2)]; % last data section ends midway through
    user_requested_data_points = arrayfun(@(x,y)[x y],st(:),et(:),'UniformOutput',false);
end

% validate requested points/sections
assert(length(user_requested_data_points)==length(user_requested_data_sections),...
    'Mismatched lengths (points - %d, sections - %d)',length(user_requested_data_points),length(user_requested_data_sections));
for kk=1:length(user_requested_data_points)
    assert(...
        user_requested_data_points{kk}(1)>=section_start(user_requested_data_sections{kk}) && ...
        user_requested_data_points{kk}(2)<=section_end(user_requested_data_sections{kk}),...
        'Requested data points %s from section %d, but that section covers data points [%d %d]',...
        util.vec2str(user_requested_data_points{kk}),user_requested_data_sections{kk},...
        section_start(user_requested_data_sections{kk}),section_end(user_requested_data_sections{kk}));
end

% translate data from digital back into analog units
min_digital_value = unique([this.ChannelInfo.MinDigitalValue]);
max_digital_value = unique([this.ChannelInfo.MaxDigitalValue]);
assert(isscalar(min_digital_value)&&isscalar(max_digital_value),'No support for different digital quantization on different channels');
min_analog_value = unique([this.ChannelInfo.MinAnalogValue]);
max_analog_value = unique([this.ChannelInfo.MaxAnalogValue]);
assert(isscalar(min_analog_value)&&isscalar(max_analog_value),'No support for different analog ranges on different channels');
range_analog = max_analog_value - min_analog_value;
range_digital = max_digital_value - min_digital_value;

% prep for converting to requested units
multfactor = 1;
analog_units = unique({this.ChannelInfo.AnalogUnits});
assert(length(analog_units)==1,'No support for different analog units on different channels');
analog_units = analog_units{1};
if isnumeric(user_requested_units) && user_requested_units==-1
    user_requested_units = analog_units;
end
assert(ischar(user_requested_units),'User requested units must be char, not ''%s''',class(user_requested_units));
if ~strcmpi(user_requested_units,analog_units)
    units_allowed = {'v','volts','mv','millivolts','uv','microvolts'};
    assert(ismember(lower(analog_units),units_allowed),'Analog units must be one of {%s}, not "%s"',strjoin(units_allowed,', '),analog_units);
    assert(ismember(lower(user_requested_units),units_allowed),'Requested units must be one of {%s}, not "%s"',strjoin(units_allowed,', '),user_requested_units);
    switch lower(user_requested_units)
        case units_allowed(1:2)
            switch lower(analog_units)
                case units_allowed(3:4), multfactor = 1e3;
                case units_allowed(5:6), multfactor = 1e6;
            end
        case units_allowed(3:4)
            switch lower(analog_units)
                case units_allowed(1:2), multfactor = 1e-3;
                case units_allowed(5:6), multfactor = 1e3;
            end
        case units_allowed(5:6)
            switch lower(analog_units)
                case units_allowed(1:2), multfactor = 1e-6;
                case units_allowed(3:4), multfactor = 1e-3;
            end
    end
end

% loop over requested data sections
srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
data = cell(1,length(user_requested_data_sections));
bytes_per_data_record = (this.BitResolution/8)*this.ChannelCount;
for kk=1:length(user_requested_data_sections)
    
    % identify starting byte of the data section
    curr_section = this.DataInfo(user_requested_data_sections{kk}).SectionIndex;
    byte_start = this.SectionInfo(curr_section).byteStart + this.SectionInfo(curr_section).headerLength;
    
    % add offset into the current data section
    byte_offset = (user_requested_data_points{kk}(1)-section_start(user_requested_data_sections{kk})+1-1)*bytes_per_data_record;
    byte_start = byte_start + byte_offset;
    
    % number of data points requested by user
    num_data_records = diff(user_requested_data_points{kk}) + 1;
    
    % read data from the file
    fid = util.openfile(srcfile,'r','seek',byte_start,'allow_multiple_handles');
    try
        data{kk} = fread(fid,[this.ChannelCount num_data_records],'*int16');
    catch ME
        util.closefile(fid);
        rethrow(ME);
    end
    util.closefile(fid);
    
    % subselect to requested channels
    data{kk} = data{kk}(user_requested_channels,:);
    
    % convert to column-major format
    data{kk} = data{kk}';
end

% process data according to user requests
for kk=1:length(data)
    
    % convert to double-class
    data{kk} = double(data{kk});
    
    % convert from digital to analog range
    data{kk} = min_analog_value + range_analog*(data{kk}-min_digital_value)/range_digital;
    
    % convert to requested units
    if multfactor~=1
        data{kk} = data{kk}*multfactor;
    end
    
    % convert to requested data class
    if ~strcmpi(class(data{kk}),user_requested_data_class)
        data{kk} = cast(data{kk},user_requested_data_class);
    end
end

% set uniform output
if flag_uniform_output
    for kk=1:length(user_requested_data_sections)-1
        num_skipped_after_this_section = section_start(user_requested_data_sections{kk}+1) - section_end(user_requested_data_sections{kk}) - 1;
        data = [data(1:kk) {nan(num_skipped_after_this_section,length(user_requested_channels))} data(kk+1:end)];
    end
    data = cat(1,data{:});
end