classdef Reader < handle
    % READER Read binary data from LAY-DAT files
    %
    % This class is intended to be used to read neural data stored in the
    % open-source, binary LAY-DAT format.
    %
    % To create a LAY.Reader object, provide the full path to a LAY file to
    % the object constructor:
    %
    % >> c = LAY.Reader(PATH_TO_LAY_FILE);
    %
    % Use the READ method to read data from the file:
    %
    % >> data = c.read;
    
    properties
        hDebug % handle to debug object
        SourceDirectory % directory of the source EDF file
        SourceBasename % basename of the source EDF file
        SourceExtension % file extension of the source EDF file
        SourceFileSize % file size (in bytes) of the source EDF file
        SamplingRate % sampling rate for the data in the dataset
        BitResolution = 16 % bit resolution of the data samples (by spec 2-byte, 2's complement)
        OriginTime % datetime corresponding to date/time at which data were originally recorded
        ChannelCount % number of channels in the BLC file
        DataStartTime % datetime corresponding to the first sample in the file
        DataEndTime % datetime corresponding to the last sample in the file
        BytesPerSample % number of bytes required to store each sample
        DataType % type of data (int32 or short/int16)
        
        SampleTimes % epochs of continuous data (time is seconds from midnight)
        Montage
        Comments
        FileInfo
        PatientInfo
        ChannelInfo % array of struct, each struct containing information about a channel
        DataInfo % array of structs, each struct containing information about a section of data
    end % END properties
    
    methods
        function this = Reader(varargin)
            % READER Read binary data from LAY files
            %
            %   THIS = READER(PATH_TO_LAY_FILE)
            %   Create a READER object by providing the full path to a LAY
            %   file.
            [varargin,this.hDebug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found_debug,this.hDebug=Debug.Debugger('LAY_Reader','screen');end
            
            % capture source file
            src = [];
            srcIdx = cellfun(@(x)ischar(x)&&exist(x,'file')==2,varargin);
            if any(srcIdx)
                src = varargin{srcIdx};
                varargin(srcIdx) = [];
            else
                dirIdx = cellfun(@(x)ischar(x)&&exist(x,'dir')==7,varargin);
                if any(dirIdx)
                    srcdir = varargin{dirIdx};
                    varargin(dirIdx) = [];
                    [srcfile,srcdir] = uigetfile(fullfile(srcdir,'*.lay'),'Select a file','MultiSelect','off');
                    assert(~isnumeric(srcfile),'Must select a valid file to continue');
                    src = fullfile(srcdir,srcfile);
                end
            end
            assert(~isempty(src),'Must provide a valid source file');
            srcinfo = dir(src);
            [this.SourceDirectory,this.SourceBasename,this.SourceExtension] = fileparts(src);
            this.SourceFileSize = srcinfo.bytes;
            this.hDebug.log(sprintf('Selected source file "%s" (%d bytes)',src,srcinfo.bytes),'info');
            
            % make sure no leftover inputs
            assert(isempty(varargin),'Unexpected inputs');
            
            % read headers
            headers(this);
        end % END function Reader
        
        function headers(this)
            % HEADERS Process headers in the EDF file
            %
            %   HEADERS(THIS)
            %   Extract information from the EDF headers and populate the
            %   various properties of the READER object.
            
            % open the file for reading
            layfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,'.lay'));
            
            % create header structure
            h = fopen(layfile,'r');
            header = fscanf(h,'%c');
            fclose(h);
            
            % Get headers
            [hdrs, hdrIdx] = regexp(header,'\[\w*\]','match');
            hdrIdx = [hdrIdx (length(header)+1)];
            for ii = 1:length(hdrs)
                switch hdrs{ii}
                    case '[FileInfo]'
                        curStr = header((hdrIdx(ii) + length(hdrs{ii})):(hdrIdx(ii+1)-1) );
                        a = regexp(curStr,'\s*(?<key>[^=]+)=(?<value>[^\n]+)','names');
                        keys = regexprep({a.key},'^File$','OriginalFile');
                        values = {a.value};
                        idx_char = ismember(keys,{'OriginalFile','FileType'});
                        values(idx_char) = cellfun(@deblank,values(idx_char),'UniformOutput',false);
                        values(~idx_char) = cellfun(@str2double,values(~idx_char),'UniformOutput',false);
                        args = [keys(:) values(:)]';
                        this.FileInfo = struct(args{:});
                        if isfield(this.FileInfo,'DataType')
                            if this.FileInfo.DataType==7
                                this.DataType = 'int32';
                                this.BytesPerSample = 4;
                            else
                                this.DataType = 'short';
                                this.BytesPerSample = 2;
                            end
                        end
                        if isfield(this.FileInfo,'Calibration')
                            this.FileInfo.AnalogScale = this.FileInfo.Calibration;
                            this.FileInfo = rmfield(this.FileInfo,'Calibration');
                        end
                        if isfield(this.FileInfo,'WaveformCount')
                            aux = dir(fullfile(this.SourceDirectory, sprintf('%s.dat',this.SourceBasename)));
                            this.FileInfo.nrSamples = aux.bytes/(this.BytesPerSample*this.FileInfo.WaveformCount);
                        end
                        assert(isfield(this.FileInfo,'SamplingRate'),'Could not identify sampling rate');
                        assert(isfield(this.FileInfo,'WaveformCount'),'Could not identify channel count');
                        this.SamplingRate = this.FileInfo.SamplingRate;
                        this.ChannelCount = this.FileInfo.WaveformCount;
                        
                    case '[Patient]'
                        curStr = header((hdrIdx(ii) + length(hdrs{ii})):(hdrIdx(ii+1)-1) );
                        a = regexp(curStr,'\s*(?<key>[^=]+)=(?<value>[^\n]+)','names');
                        keys = {a.key};
                        values = cellfun(@deblank,{a.value},'UniformOutput',false);
                        args = [keys(:) values(:)]';
                        this.PatientInfo = struct(args{:});
                        if isfield(this.PatientInfo,'TestDate') && isfield(this.PatientInfo,'TestTime')
                            
                            % compute pivot year based on whether the
                            % indicated year would be in the future
                            yy = str2double(this.PatientInfo.TestDate(end-1:end));
                            curryr = year(datetime('now'));
                            if yy>rem(curryr,100)
                                pvtyr = curryr - rem(curryr,100) - 100;
                            else
                                pvtyr = curryr - rem(curryr,100);
                            end
                            
                            % convert from string to datetime
                            dn = datenum([this.PatientInfo.TestDate ' ' this.PatientInfo.TestTime],'mm/dd/yy HH:MM:SS',pvtyr);
                            this.PatientInfo.TestDateTime = datetime(dn,'ConvertFrom','datenum');
                            this.PatientInfo = rmfield(this.PatientInfo,'TestDate');
                            this.PatientInfo = rmfield(this.PatientInfo,'TestTime');
                            
                            % copy over to origin time field
                            this.OriginTime = this.PatientInfo.TestDateTime;
                        end
                        
                    case '[ChannelMap]'
                        curStr = header((hdrIdx(ii) + length(hdrs{ii})):(hdrIdx(ii+1)-1) );
                        a = regexp(curStr,'\s*(?<key>[^=]+)=(?<value>[^\n]+)','names');
                        index = arrayfun(@(x)str2double(x.value),a,'UniformOutput',false);
                        splitName = cellfun(@(x)regexpi(x,'-','split'),{a.key},'UniformOutput',false);
                        channel = cellfun(@(x)x{1},splitName,'UniformOutput',false);
                        idx_more = cellfun(@(x)length(x)>1,splitName,'UniformOutput',true);
                        ref = cellfun(@(x)'',channel,'UniformOutput',false);
                        ref(idx_more) = cellfun(@(x)x{2},splitName(idx_more),'UniformOutput',false);
                        this.ChannelInfo = struct('ChannelNumber',index(:),'Label',channel(:),'Reference',ref(:));
                        
                    case '[Comments]'
                        curStr = header((hdrIdx(ii) + length(hdrs{ii})):(hdrIdx(ii+1)-1) );
                        a = regexp(curStr,'(?<start>[0-9\.]+),(?<duration>[0-9\.]+),(?<misc1>[0-9\.]+),(?<misc2>[0-9\.]+),(?<comment>[^\r]+)','names');
                        start = cellfun(@str2double,{a.start},'UniformOutput',false);
                        dur = cellfun(@str2double,{a.duration},'UniformOutput',false);
                        misc1 = cellfun(@str2double,{a.misc1},'UniformOutput',false);
                        misc2 = cellfun(@str2double,{a.misc2},'UniformOutput',false);
                        comment = cellfun(@deblank,{a.comment},'UniformOutput',false);
                        this.Comments = struct('start',start(:),'duration',dur(:),'misc1',misc1(:),'misc2',misc2(:),'comment',comment(:));
                        
                    case '[SampleTimes]'
                        curStr = header((hdrIdx(ii) + length(hdrs{ii})):(hdrIdx(ii+1)-1) );
                        a = regexp(curStr,'\s*(?<index>[^=]+)=(?<time>[^\n]+)','names');
                        index = cellfun(@(x)str2double(x)+1,{a.index},'UniformOutput',false);
                        time = cellfun(@str2double,{a.time},'UniformOutput',false); % time is seconds from midnight
                        this.SampleTimes = struct('index',index(:),'time',time(:));
                        
                    case '[Montage]'
                        curStr = header((hdrIdx(ii) + length(hdrs{ii})):(hdrIdx(ii+1)-1) );
                        [nm, nmIdx] = regexp(curStr,'\[[\w\s]*\]','match');
                        montage_name = nm{1}(2:end-1);
                        curStr = curStr(nmIdx+length(nm{1})+2:end);
                        a = regexp(curStr,'\s*(?<key>[^=]+)=(?<value>[^\n]+)','names');
                        keys = cellfun(@(x)matlab.lang.makeValidName(x),{a.key},'UniformOutput',false);
                        values = cellfun(@deblank,{a.value},'UniformOutput',false);
                        args = [keys(:) values(:)]';
                        this.Montage.(matlab.lang.makeValidName(montage_name)) = struct(args{:});
                    otherwise
                        error('Unknown header field "%s"',hdrs{ii});
                end
            end
            
            % update comment timing
            for cc=1:length(this.Comments)
                samplenum = this.Comments(cc).start * this.SamplingRate;
                
                % this calculates sample time
                ii=1;
                while ii<numel(this.SampleTimes) && samplenum>this.SampleTimes(ii+1).index
                    ii=ii+1;
                end
                samplenum = samplenum - this.SampleTimes(ii).index + 1;
                samplesec = samplenum / this.SamplingRate;
                timesec = samplesec + this.SampleTimes(ii).time;
                commenttime = datestr(timesec/86400, 'HH:MM:SS');
                
                % use date calculated earlier
                dn = datenum(strcat(date, ',', commenttime));
                
                % put all that into a struct in the header
                this.Comments(cc).start = datetime(dn,'ConvertFrom','datenum');
            end
            
            % number of data records
            file_info = dir(fullfile(this.SourceDirectory,sprintf('%s.dat',this.SourceBasename)));
            num_samples = file_info.bytes/(this.BytesPerSample*this.ChannelCount);
            section_timestamps = arrayfun(@(x)x,[this.SampleTimes.index],'UniformOutput',false);
            section_numsamples = arrayfun(@(x)x,diff([this.SampleTimes.index num_samples+1]),'UniformOutput',false);
            section_durations = cellfun(@(x)seconds(x/this.SamplingRate),section_numsamples,'UniformOutput',false);
            ymdate = datetime(year(this.OriginTime),month(this.OriginTime),day(this.OriginTime));
            section_datetimes = arrayfun(@(x)ymdate + seconds(x),[this.SampleTimes.time],'UniformOutput',false);
            this.DataInfo = struct('Timestamp',section_timestamps,'NumSamples',section_numsamples,'Datetime',section_datetimes,'Duration',section_durations);
            this.hDebug.log(sprintf('Found %d data sections',length(this.DataInfo)),'debug');
            this.DataStartTime = this.DataInfo(1).Datetime;
            this.DataEndTime = this.DataInfo(end).Datetime + this.DataInfo(end).Duration;
        end % END function headers
        
        function [x,t] = read(this,varargin)
            % input - number of records to read
            % output - data from .dat file
            
            % process simple inputs
            channel_numbers = [this.ChannelInfo.ChannelNumber];
            channel_references = {this.ChannelInfo.Reference};
            [varargin,user_requested_channels] = util.argkeyval('channels',varargin,channel_numbers(~cellfun(@isempty,channel_references)));
            [varargin,user_requested_data_class] = util.argkeyval('class',varargin,'double');
            [varargin,user_requested_context] = util.argkeyval('context',varargin,'file',7);
            [varargin,reqseg] = util.argkeyval('segments',varargin,nan,3);
            [varargin,reqpoints] = util.argkeyval('points',varargin,nan,5);
            [varargin,reqtime] = util.argkeyval('times',varargin,nan,4);
            [varargin,datestr_format] = util.argkeyval('datestrformat',varargin,'dd-MMM-yyyy HH:mm:ss',8);
            util.argempty(varargin);
            
            % update log
            this.hDebug.log(sprintf('User requested channels %s',util.vec2str(user_requested_channels)),'debug');
            this.hDebug.log(sprintf('User requested data class %s',upper(user_requested_data_class)),'debug');
            this.hDebug.log(sprintf('User requested context %s',upper(user_requested_context)),'debug');
            
            % CHANNELS
            % convert char channel labels to numeric channel numbers
            if ischar(user_requested_channels)
                idx_requested_channel = find(strcmpi(user_requested_channels,{this.ChannelInfo.Label}),1,'first');
                assert(~isempty(idx_requested_channel),'Could not find channel labeled "%s"',user_requested_channels);
                user_requested_channels = idx_requested_channel;
            elseif iscell(user_requested_channels)
                channel_labels = {this.ChannelInfo.Label};
                idx_requested_channel = cellfun(@(x)find(strcmpi(x,channel_labels),1,'first'),user_requested_channels,'UniformOutput',false);
                assert(~any(cellfun(@isempty,idx_requested_channel)),'Could not find channel labeled "%s"',user_requested_channels{find(cellfun(@isempty,idx_requested_channel),1,'first')});
                assert(all(cellfun(@length,idx_requested_channel)==1),'Found mismatched label "%s"',user_requested_channels{find(cellfun(@length,idx_requested_channel)~=1,1,'first')});
                user_requested_channels = cat(2,idx_requested_channel{:});
            elseif islogical(user_requested_channels)
                user_requested_channels = find(user_requested_channels);
            end
            assert(isnumeric(user_requested_channels),'Must provide numeric channel index vector');
            
            % POINTS/TIME
            % convert point/time input from source context into 'file' context
            user_provided_points = iscell(reqpoints)||any(isa(reqpoints,'datetime'))||any(isa(reqpoints,'duration'))||~any(isnan(reqpoints(:)));
            user_provided_times = iscell(reqtime)||any(isa(reqtime,'datetime'))||any(isa(reqtime,'duration'))||~any(isnan(reqtime(:)));
            user_provided_segment = all(isnumeric(reqseg)) && isscalar(reqseg) && isfinite(reqseg);
            if user_provided_segment
                assert(isnumeric(reqseg)&&isscalar(reqseg)&&isfinite(reqseg),'Must provide scalar, finite segment');
            end
            if ~user_provided_times && ~user_provided_points
                if user_provided_segment
                    user_requested_data_points = [this.DataInfo(reqseg).Timestamp this.DataInfo(reqseg).Timestamp+this.DataInfo(reqseg).NumSamples-1];
                else
                    user_requested_data_points = nan;
                end
            elseif user_provided_points
                
                % possible input formats include
                % [START END]
                %   - integer number of points
                %
                %            ABSOLUTE    ORIGIN    FILE    SEGMENT
                % int           -          x        x         x
                
                % convert context to 'file'
                assert(length(reqpoints)==2,'Input must be 1x2 vector containing [START END]');
                orig_reqpoints = reqpoints;
                switch lower(user_requested_context)
                    case 'absolute'
                        
                        % no support for "absolute" context
                        error('"Absolute" context not supported for "point" inputs');
                    case 'origin'
                        
                        % subtract offset from origin to file start
                        origin_to_file_offset = seconds( this.DataStartTime-this.OriginTime );
                        reqpoints = reqpoints - round( origin_to_file_offset*this.SamplingRate ) + 1;
                    case 'file'
                        
                        % nothing to do
                    case 'segment'
                        
                        % subtract offset from origin to segment start
                        assert(user_provided_segment,'Must provide "segment" input for "segment" context');
                        origin_to_segment_offset = seconds( this.DataInfo(reqseg).Datetime-this.DataStartTime );
                        reqpoints = reqpoints + round( origin_to_segment_offset*this.SamplingRate ) + 1;
                end
                assert(reqpoints(2)>=reqpoints(1),'Requested start/end points [%d %d] must be non-decreasing',orig_reqpoints(1),orig_reqpoints(2));
                assert(reqpoints(1)>=0,'Requested start time %.2f seconds prior to first data in this file',abs(reqpoints(1)/this.SamplingRate));
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
                %   - duration (relative to something: origin, file)
                % {START,END}
                %   - char strings
                %
                %            ABSOLUTE    ORIGIN    FILE    SEGMENT
                % int/fp        -          x        x         x
                % datetime      x          -        -         -
                % duration      -          x        x         x
                % cell/char     x          x*       x*        x*
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
                        if iscell(reqtime)&&all(cellfun(@ischar,reqtime))
                            reqtime = datetime(reqtime,'InputFormat',datestr_format);
                            reqtime = seconds(reqtime - this.DataStartTime);
                        elseif isa(reqtime,'datetime')
                            reqtime = seconds(reqtime - this.DataStartTime);
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
                            reqtime = seconds( reqtime - (this.DataStartTime-this.OriginTime) );
                        elseif isa(reqtime,'datetime')
                            error('In "origin" context, time input cannot be "datetime" class');
                        elseif isa(reqtime,'duration')
                            reqtime = seconds( reqtime - (this.DataStartTime-this.OriginTime) );
                        else
                            assert(isnumeric(reqtime),'Unknown class "%s" for time input with context "%s"',class(reqtime),user_requested_context);
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
                    case 'segment'
                        assert(user_provided_segment,'Must provide "segment" input for "segment" context');
                        if iscell(reqtime)&&all(cellfun(@ischar,reqtime))
                            numsec = [86400 3600 60 1];
                            for kk=1:length(reqtime)
                                reqtime{kk} = str2double(strsplit(reqtime{kk},':'));
                                reqtime{kk} = [zeros(1,length(numsec)-length(reqtime{kk})) reqtime{kk}];
                                reqtime{kk} = seconds(sum(reqtime{kk}.*numsec));
                            end
                            reqtime = cat(2,reqtime{:});
                            reqtime = seconds( reqtime + (this.DataInfo(reqseg).Datetime-this.DataStartTime) );
                        elseif isa(reqtime,'datetime')
                            error('In "segment" context, time input cannot be "datetime" class');
                        elseif isa(reqtime,'duration')
                            reqtime = seconds( reqtime + (this.DataInfo(reqseg).Datetime-this.DataStartTime) );
                        else
                            assert(isnumeric(reqtime),'Unknown class "%s" for time input with context "%s"',class(reqtime),user_requested_context);
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
            
            % check whether user provided times/points and infer sections
            if isnan(user_requested_data_points)
                
                % user provided no input
                user_requested_data_points = [1 sum([this.DataInfo.NumSamples])]; % default all data points
            else
                
                % user provided the data points
                assert(user_requested_data_points(1)>=1,'Invalid start %d',user_requested_data_points(1));
                assert(seconds(this.DataEndTime-this.DataStartTime)*this.SamplingRate>=user_requested_data_points(2),'Invalid end %d',user_requested_data_points(2));
            end
            
            % read data by segment
            first_segment = find(user_requested_data_points(1)>=[this.DataInfo.Timestamp],1,'last');
            last_segment = find(user_requested_data_points(2)>=[this.DataInfo.Timestamp],1,'last');
            data_offset = (user_requested_data_points(1)-1)*this.BytesPerSample*this.ChannelCount;
            num_points_in_output = diff(user_requested_data_points)+1;
            dat_file = fullfile(this.SourceDirectory,sprintf('%s.dat',this.SourceBasename));
            fid = util.openfile(dat_file);
            try
                
                % seek to the data offset
                fseek(fid,data_offset,'bof');
                if last_segment>first_segment
                    segments = first_segment:last_segment;
                    x = cell(1,length(segments));
                    t = cell(1,length(segments));
                    num_total_points = num_points_in_output;
                    curr_idx = 0;
                    
                    % loop over segments
                    for ss=1:length(segments)
                        
                        % compute the indices for this segment
                        first_point_in_segment = (curr_idx + user_requested_data_points(1)) - this.DataInfo(segments(ss)).Timestamp + 1;
                        if (first_point_in_segment + num_total_points - 1) > this.DataInfo(segments(ss)).NumSamples
                            last_point_in_segment = this.DataInfo(segments(ss)).NumSamples;
                        else
                            last_point_in_segment = first_point_in_segment + num_total_points - 1;
                        end
                        num_points_in_segment = last_point_in_segment - first_point_in_segment + 1;
                        
                        % compute byte offset for this chunk
                        segment_offset = (first_point_in_segment-1)*this.BytesPerSample*this.ChannelCount;
                        fseek(fid,segment_offset,'cof');
                        
                        % read data from disk
                        x{ss} = this.FileInfo.AnalogScale * fread(fid,[this.ChannelCount,num_points_in_segment],this.DataType);
                        x{ss} = x{ss}(user_requested_channels,:);
                        
                        % construct timing vector
                        t{ss} = this.DataInfo(segments(ss)).Datetime;
                        
                        % update tracking variables
                        num_total_points = num_total_points - num_points_in_segment;
                        curr_idx = curr_idx + num_points_in_segment;
                    end
                    
                    % validate data size
                    assert(sum(cellfun(@(x)size(x,2),x))==num_points_in_output);
                    assert(num_total_points==0);
                    assert(curr_idx==num_points_in_output);
                else
                    
                    % only one segment - no cell arrays needed
                    x = this.FileInfo.AnalogScale * fread(fid,[this.ChannelCount,num_points_in_output],this.DataType);
                    x = x(user_requested_channels,:);
                end
            catch ME
                util.closefile(dat_file);
                rethrow(ME);
            end
            
            % close the file
            util.closefile(dat_file);
        end % END function layread
    end % END methods
end % END classdef Reader