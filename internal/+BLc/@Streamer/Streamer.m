classdef Streamer < handle
    % STREAMER Read BLc data in blocks, remembering position in the file
    %
    %   This class is an abstraction for streaming data in blocks from a
    %   BLc file, similar to how the Framework would poll neural data at
    %   regular time intervals during online control. This class may also
    %   be useful for reading blocks of data that fit in memory during
    %   analysis, implicitly keeping track of position within the data
    %   file.
    %
    %   Basic usage is:
    %
    %   >> bls = BLc.Streamer('/path/to/blc/file')
    %   >> dt = bls.read(100); % reads 100 samples of data
    %   >> bls.reset; % reset back to beginning
    %   >> bls.seek(100); % seek to 100 samples in
    %   >> [curr_pos,samples_let] = bls.tell; % get info about current pos
    %   >> bls.delete;
    %
    %   Some notes
    %     * The READ method is reading bytes directly from the blc file. It
    %       is NOT calling the read method of the BLc object stored in the
    %       property hBLc (that object is used to get information about the
    %       file, and as a point of reference in the validation function).
    %     * This class is vastly simplified from the BLc read interface. Of
    %       note is the simplification to provide timing information in
    %       "points" (samples in the data sampling rate) only - no time in
    %       seconds.
    %     * This class reads only from one section in the BLc file. The
    %       default section is the largest one.
    %
    %   Spencer Kellis
    %   20180602
    %   skellis@caltech.edu
    
    properties(SetAccess=private)
        hDebug % Debug.Debugger object
        hBLc % BLc.Reader object
        section % which section from the BLc file to read from
    end % END properties(SetAccess=private)
    properties(Access=private)
        fid % file pointer
        pos % current position in the file
        cache % holding some properties in temporary storage
    end % END properties(Access=private)
    
    methods
        function this = Streamer(varargin)
            % STREAMER stream data out of an NSx object in blocks
            %
            %  N = STREAMER(NSOBJ)
            %  N = STREAMER(NSFILE)
            %  Provide either a Blackrock.NSx object, or a char with the
            %  path to an existing NSx file.
            %
            %  N = STREAMER(...,'PACKET',PKT)
            %  Specify the section from which to read data (default is the
            %  largest section).
            
            % debugger
            [varargin,this.hDebug,found_debug] = util.argisa('Debug.Debugger',varargin,[]); % debugger
            if ~found_debug,this.hDebug=Debug.Debugger('Streamer');end
            if ~this.hDebug.isRegistered('Blackrock.NSx')
                this.hDebug.registerClient('Blackrock.NSx','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
            end
            
            % blackrock NSx object
            [varargin,blobj,found_blobj] = util.argisa('BLc.Reader',varargin,[]); % NSx object
            [varargin,blfile,found_blfile] = util.argfn(@(x)ischar(x)&&exist(x,'file')==2,varargin,''); % BLc file
            if found_blobj
                this.hBLc = blobj;
                this.hBLc.setVerbosity(Debug.PriorityLevel.CRITICAL);
            elseif found_blfile
                this.hBLc = BLc.Reader(blfile,this.hDebug);
            end
            assert(isa(this.hBLc,'BLc.Reader'),'Must provide object of class "BLc.Reader", not "%s"',class(this.hBLc));
            
            % open the file for reading
            blcfile = fullfile(this.hBLc.SourceDirectory,[this.hBLc.SourceBasename this.hBLc.SourceExtension]);
            this.fid = util.openfile(blcfile,'r');
            
            % section
            [~,def_section] = max([this.hBLc.DataInfo.NumRecords]);
            [varargin,sct] = util.argkeyval('section',varargin,def_section); % section to read data rom
            
            % make sure no leftover inputs
            util.argempty(varargin);
            
            % set the section
            this.setSection(sct);
            
            % log the configuration
            this.hDebug.log(sprintf('Streamer initialized to read from %s%s (section %d)',...
                this.hBLc.SourceBasename,this.hBLc.SourceExtension,this.section),'info');
        end % END function Streamer
        
        function setSection(this,sct)
            this.section = sct;
            this.reset;
        end % END functon setPacket
        
        function seek(this,amt,varargin)
            % SEEK move the current position without reading data
            %
            %   SEEK(THIS,AMT)
            %   Move the current position AMT samples (can be positive or
            %   negative). By default, moves relative to current position.
            %
            %   SEEK(...,'pos'|'sct')
            %   Interpret AMT relative to current position ('pos') or
            %   beginning of section ('sct'). Default 'pos'.
            
            % process inputs
            [varargin,rel] = util.argkeyword({'pos','sct'},varargin,'pos'); % relative to current position, section start
            util.argempty(varargin);
            
            % compute new position
            if strcmpi(rel,'pos')
                new_pos = this.pos + amt - 1;
            elseif strcmpi(rel,'sct')
                new_pos = amt;
            end
            
            % check for limits (<1 or >Packet_End)
            if new_pos<1
                this.hDebug.log(sprintf('Hard limiting new position to 1 (from %d)',new_pos),'info');
                new_pos = 1;
            end
            if new_pos>this.hBLc.DataInfo(this.section).NumRecords
                this.hDebug.log(sprintf('Hard limiting new position to %d (from %d)',this.hBLc.DataInfo(this.section).NumRecords,new_pos),'info');
                new_pos = this.hBLc.DataInfo(this.section).NumRecords;
            end
            
            % validate starting byte
            section_info = this.hBLc.SectionInfo(this.hBLc.DataInfo(this.section).SectionIndex);
            section_byte = section_info.byteStart + section_info.headerLength;
            data_byte = (new_pos-1)*2*this.hBLc.ChannelCount;
            start_byte = section_byte + data_byte;
            
            % identify offset from section start to requested data start
            fseek(this.fid,start_byte,'bof');
            
            % update position
            this.pos = new_pos;
        end % END function seek
        
        function [pos,left] = tell(this)
            pos = this.pos;
            left = this.hBLc.DataInfo(this.section).NumRecords - pos + 1;
        end % END function tell
        
        function [dt,t] = read(this,amt,varargin)
            % read next block of data
            % specify AMT in "points" i.e. number of samples in the source
            % BLc object's sampling rate
            % starts from the first sample available in the section, not at
            % "timestamp 0"
            
            % process inputs
            [varargin,channels] = util.argkeyval('channels',varargin,1:this.hBLc.ChannelCount,2); % channels to read
            [varargin,step] = util.argkeyval('step',varargin,amt);
            [varargin,dtclass] = util.argkeyword({'double','single','int16','uint16','int32','uint32'},varargin,'double');
            [varargin,units] = util.argkeyword({'normalized','volts','millivolts','microvolts'},varargin,'microvolts');
            util.argempty(varargin);
            
            % avoid numerical issues
            amt = double(amt);
            step = double(step);
            
            % upate cache
            if ~isfield(this.cache,'channels') || length(this.cache.channels)~=length(channels) || ~all(this.cache.channels==channels)
                this.cache = struct('channels',channels);
            end
            
            % compute number of samples to read from input AMT
            last_pos = this.pos + amt - 1;
            if last_pos>this.hBLc.DataInfo(this.section).NumRecords
                new_amt = this.hBLc.DataInfo(this.section).NumRecords-this.pos+1;
                this.hDebug.log(sprintf('Requested amount (%d samples) exceeds available remaining data (%d samples); reducing to available data',amt,new_amt),'info');
                amt = new_amt;
                if step>amt,step=new_amt;end
            end
            next_pos = this.pos + step;
            if next_pos-this.hBLc.DataInfo(this.section).NumRecords==1
                this.hDebug.log('Only one sample over, probably due to consistent loop variables running up against end of data: helpfully reducing step to last sample in the data','info');
                step = step - 1;
                next_pos = next_pos - 1;
            end
            if next_pos>this.hBLc.DataInfo(this.section).NumRecords
                new_step = amt;
                this.hDebug.log(sprintf('Requested step (%d samples) exceeds available remaining data (%d samples); reducing to available data',step,new_step),'info');
                step = new_step;
                next_pos = this.pos + step;
            end
            if amt==0
                dt = [];
                t = [];
                return;
            end
            
            % create time output: time of the last sample in AMT
            t = (this.hBLc.DataInfo(1).Timestamp+last_pos-1)/this.hBLc.SamplingRate;
            
            % validate starting byte
            pre_byte = ftell(this.fid);
            section_info = this.hBLc.SectionInfo(this.hBLc.DataInfo(this.section).SectionIndex);
            section_byte = section_info.byteStart + section_info.headerLength;
            data_byte = (this.pos-1)*2*this.hBLc.ChannelCount;
            start_byte = section_byte + data_byte;
            assert(pre_byte==start_byte,'Mismatch between current file position %d and expected start byte %d',pre_byte,start_byte);
            
            % read the appropriate number of bytes from the file
            dt = fread(this.fid,[this.hBLc.ChannelCount amt],'*int16');
            assert(size(dt,2)==amt,'Requested %d bytes, but fread returned %d bytes (file size %d bytes)',amt,size(dt,2),this.hBLc.SourceFileSize);
            try
                
                % retain only requested channels
                dt = dt(channels,:);
                
                % update current position
                this.pos = next_pos;
                
                % update file pointer
                new_byte = pre_byte + step*2*this.hBLc.ChannelCount;
                post_byte = ftell(this.fid);
                offset_bytes = new_byte - post_byte;
                offset_points = (step-amt)*2*this.hBLc.ChannelCount;
                assert(offset_bytes==offset_points,'Incorrect offset computed via bytes (%d) vs points (%d)',offset_bytes/2/this.hBLc.ChannelCount,offset_points/2/this.hBLc.ChannelCount);
                num_points = (new_byte-section_byte)/(2*this.hBLc.ChannelCount);
                assert(num_points==(this.pos-1),'Incorrect file pointer after read operation: seek indicates %d samples but position suggests %d',num_points,this.pos-1);
                fseek(this.fid,offset_bytes,'cof');
            catch ME
                util.errorMessage(ME);
                keyboard
            end
            
            % scale to units o output data
            if strcmpi(units,'normalized')
                
                % for normalized output units, convert to output class directly
                if ~strcmpi(class(dt),dtclass)
                    dt = cast(dt,dtclass);
                end
            else
                if ~isfield(this.cache,'dh')
                    this.cache.dh = unique([this.hBLc.ChannelInfo(channels).MaxDigitalValue]);
                    this.cache.dl = unique([this.hBLc.ChannelInfo(channels).MinDigitalValue]);
                    this.cache.nh = unique([this.hBLc.ChannelInfo(channels).MaxAnalogValue]);
                    this.cache.nl = unique([this.hBLc.ChannelInfo(channels).MinAnalogValue]);
                    assert(isscalar(this.cache.dh)&&isscalar(this.cache.dl),'All max/min digital values must be the same');
                    assert(isscalar(this.cache.nh)&&isscalar(this.cache.nl),'All max/min analog values must be the same');
                    this.cache.A = this.cache.nh-this.cache.nl;
                    this.cache.B = this.cache.dh-this.cache.dl;
                end
                
                % determine multiplicative factor for volt/milli/micro
                switch lower(units)
                    case {'uv','microvolts'},multfactor=1;
                    case {'mv','millivolts'},multfactor=1e-3;
                    case {'v','volts'},multfactor=1e-6;
                end
                
                % will be performing division/multiplication, need double
                if ~strcmpi(class(dt),dtclass)
                    dt = cast(dt,dtclass);
                    if multfactor<1 && (strncmpi(dtclass,'int',3)||strncmpi(dtclass,'uint',4))
                        warning('Likely to encounter significant numerical problems with "%s" units and "s" data class',units,dtclass);
                    end
                end
                
                % convert to voltage, scale to requested unit
                dt = multfactor*((dt-this.cache.dl)*this.cache.A/this.cache.B + this.cache.nl);
            end
        end % END function read
        
        function dt = read_blc(this,amt,varargin)
            % READ use BLc read method from current position (no update)
            %
            %   DT = READ(THIS,AMT)
            %   Read AMT samples of data but do not update the current
            %   position.
            %
            %   Any inputs after AMT are passed through to the NSx read
            %   method.
            
            % compute number of samples to read from input AMT
            last_pos = this.pos + amt - 1;
            if last_pos>this.hBLc.DataInfo(this.section).NumRecords
                new_amt = this.hBLc.DataInfo(this.section).NumRecords-this.pos+1;
                this.hDebug.log(sprintf('Requested amount (%d samples) exceeds available remaining data (%d samples); reducing to available data',amt,new_amt),'info');
                amt = new_amt;
            end
            
            % convert to TimestampTimeResolution timestamps
            tm_start = this.pos;
            tm_end = tm_start + amt - 1;
            
            % read the data
            dt = this.hBLc.read('section',this.section,'context','section','points',[tm_start tm_end],varargin{:});
        end % END function read_blc
        
        function varargout = validate(this,varargin)
            [varargin,reps] = util.argkeyval('reps',varargin,1e3,3);
            [varargin,pts] = util.argkeyval('pts',varargin,1e2);
            [varargin,step] = util.argkeyval('step',varargin,pts);
            util.argempty(varargin);
            
            % repetitively read blocks of data using both methods and
            % measure time for each
            tm_blc = nan(reps,1);
            tm_internal = nan(reps,1);
            for nn=1:reps
                try
                    tmr = tic; dt_blc = this.read_blc(pts,'units','microvolts','class','double'); tm_blc(nn)=toc(tmr);
                    tmr = tic; dt_internal = this.read(pts,'microvolts','double','step',step); tm_internal(nn)=toc(tmr);
                    assert(all(dt_internal(:)==dt_blc(:)),'Mismatched data');
                catch ME
                    msg = util.errorMessage(ME,'noscreen','nolink');
                    this.hDebug.log(sprintf('Block read failed at repeition %d/%d: %s',nn,reps,msg),'error');
                    break;
                end
            end
            tm_blc(nn+1:end) = [];
            tm_internal(nn+1:end) = [];
            
            % if no outputs, print out the mean/std and show a boxplot of
            % times per repetition
            if nargout==0
                fprintf('FREAD: %.3f±%.3f sec; BLC: %.3f±%.3f sec\n',nanmean(tm_internal),nanstd(tm_internal),nanmean(tm_blc),nanstd(tm_blc));
                figure;
                boxplot([tm_internal(:) tm_blc(:)]);
                set(gca,'XTickLabel',{'fread','BLc'});
                ylabel('Time (seconds)');
                title('Block read performance');
            else
                
                % otherwise assign times to the output
                if nargout>=1
                    varargout{1} = tm_internal;
                end
                if nargout>=2
                    varargout{2} = tm_blc;
                end
            end
        end % END function validate
        
        function reset(this)
            this.cache = [];
            
            % seek to beginning of the requested section
            section_info = this.hBLc.SectionInfo(this.hBLc.DataInfo(this.section).SectionIndex);
            section_byte = section_info.byteStart + section_info.headerLength;
            fseek(this.fid,section_byte,'bof');
            
            % track samples: here, in terms of the data sampling rate
            this.pos = 1;
        end % END function reset
        
        function delete(this)
            if isnumeric(this.fid) && ~isempty(this.fid) && this.fid>0
                util.closefile(this.fid);
            end
        end % END function delete
    end % END methods
end % END classdef Streamer