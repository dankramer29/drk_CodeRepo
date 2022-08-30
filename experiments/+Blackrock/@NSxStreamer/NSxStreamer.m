classdef NSxStreamer < handle
    % NSXSTREAMER Read NSx data in blocks, remembering position in the file
    %
    %   This class is an abstraction for streaming data in blocks from an
    %   NSx file, similar to how the Framework would poll neural data at
    %   regular time intervals during online control. This class may also
    %   be useful for reading blocks of data that fit in memory during
    %   analysis, implicitly keeping track of position within the data
    %   file.
    %
    %   Basic usage is:
    %
    %   >> nss = Blackrock.NSxStreamer('/path/to/nsx/file')
    %   >> dt = nss.read(100); % reads 100 samples of data
    %   >> nss.reset; % reset back to beginning
    %   >> nss.seek(100); % seek to 100 samples in
    %   >> [curr_pos,samples_let] = nss.tell; % get info about current pos
    %   >> nss.delete;
    %
    %   Some notes
    %     * The READ method is reading bytes directly from the nsx file. It
    %       is NOT calling the read method of the NSx object stored in the
    %       property hNSx (that object is used to get information about the
    %       file, and as a point of reference in the validation function).
    %     * This class is vastly simplified rom the NSx read interface. Of
    %       note is the simplification to provide timing information in
    %       "points" (samples in the data sampling rate) only - no time in
    %       seconds or timestamps in TimestampTimeResolution sampling rate.
    %     * This class reads only from one packet in the NSx file. The
    %       default packet is the largest one.
    %
    %   Spencer Kellis
    %   20180411
    %   skellis@caltech.edu
    
    properties(SetAccess=private)
        hDebug % Debug.Debugger object
        hNSx % Blackrock.NSx object
        packet % which packet from the NSx to read from
    end % END properties(SetAccess=private)
    properties(Access=private)
        fid % file pointer
        pos % current position in the file
        cache % holding some properties in temporary storage
    end % END properties(Access=private)
    
    methods
        function this = NSxStreamer(varargin)
            % NSXSTREAMER stream data out of an NSx object in blocks
            %
            %  N = NSXSTREAMER(NSOBJ)
            %  N = NSXSTREAMER(NSFILE)
            %  Provide either a Blackrock.NSx object, or a char with the
            %  path to an existing NSx file.
            %
            %  N = NSXSTREAMER(...,'PACKET',PKT)
            %  Specify the packet from which to read data (default is the
            %  largest packet).
            
            % debugger
            [varargin,this.hDebug,found_debug] = Utilities.argisa('Debug.Debugger',varargin,[]); % debugger
            if ~found_debug,this.hDebug=Debug.Debugger('NSxStreamer');end
            if ~this.hDebug.isRegistered('Blackrock.NSx')
                this.hDebug.registerClient('Blackrock.NSx','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
            end
            
            % blackrock NSx object
            [varargin,nsobj,found_nsobj] = Utilities.argisa('Blackrock.NSx',varargin,[]); % NSx object
            [varargin,nsfile,found_nsfile] = Utilities.argfn(@(x)ischar(x)&&exist(x,'file')==2,varargin,''); % NSx file
            if found_nsobj
                this.hNSx = nsobj;
                this.hNSx.setVerbosity(Debug.PriorityLevel.CRITICAL);
            elseif found_nsfile
                this.hNSx = Blackrock.NSx(nsfile,this.hDebug);
            end
            assert(isa(this.hNSx,'Blackrock.NSx'),'Must provide object of class "Blackrock.NSx", not "%s"',class(this.hNSx));
            
            % open the file for reading
            nsxfile = fullfile(this.hNSx.SourceDirectory,[this.hNSx.SourceBasename this.hNSx.SourceExtension]);
            this.fid = util.openfile(nsxfile,'r');
            
            % packet
            [~,def_packet] = max(this.hNSx.PointsPerDataPacket);
            [varargin,pkt] = Utilities.argkeyval('packet',varargin,def_packet); % set the packet to read data rom
            
            % make sure no leftover inputs
            Utilities.argempty(varargin);
            
            % set the packet
            this.setPacket(pkt);
            
            % log the configuration
            this.hDebug.log(sprintf('NSxStreamer initialized to read from %s%s (pkt %d)',...
                this.hNSx.SourceBasename,this.hNSx.SourceExtension,this.packet),'info');
        end % END function NSxStreamer
        
        function setPacket(this,pkt)
            this.packet = pkt;
            this.reset;
        end % END functon setPacket
        
        function seek(this,amt,varargin)
            % SEEK move the current position without reading data
            %
            %   SEEK(THIS,AMT)
            %   Move the current position AMT samples (can be positive or
            %   negative). By default, moves relative to current position.
            %
            %   SEEK(...,'pos'|'pkt')
            %   Interpret AMT relative to current position ('pos') or
            %   beginning of packet ('pkt'). Default 'pos'.
            
            % process inputs
            [varargin,rel] = Utilities.argkeyword({'pos','pkt'},varargin,'pos'); % relative to current position, packet start, packet end
            Utilities.argempty(varargin);
            
            % compute new position
            if strcmpi(rel,'pos')
                new_pos = this.pos + amt - 1;
            elseif strcmpi(rel,'pkt')
                new_pos = amt;
            end
            
            % check for limits (<1 or >Packet_End)
            if new_pos<1
                this.hDebug.log(sprintf('Hard limiting new position to 1 (from %d)',new_pos),'info');
                new_pos = 1;
            end
            if new_pos>this.hNSx.PointsPerDataPacket(this.packet)
                this.hDebug.log(sprintf('Hard limiting new position to %d (from %d)',this.hNSx.PointsPerDataPacket(this.packet),new_pos),'info');
                new_pos = this.hNSx.PointsPerDataPacket(this.packet);
            end
            
            % validate starting byte
            packet_byte = this.hNSx.DataPacketByteIdx(this.packet,1)+9;
            data_byte = (new_pos-1)*2*this.hNSx.ChannelCount;
            start_byte = packet_byte + data_byte;
            
            % identify offset from packet start to requested data start
            fseek(this.fid,start_byte,'bof');
            
            % update position
            this.pos = new_pos;
        end % END function seek
        
        function [pos,left] = tell(this)
            pos = this.pos;
            left = this.hNSx.PointsPerDataPacket(this.packet) - pos + 1;
        end % END function tell
        
        function [dt,t] = read(this,amt,varargin)
            % read next block of data
            % specify AMT in "points" i.e. number of samples in the source
            % NSx object's sampling rate
            % starts from the first sample available in the packet, not at
            % "timestamp 0"
            
            % process inputs
            [varargin,channels] = Utilities.argkeyval('channels',varargin,1:this.hNSx.ChannelCount,2); % channels to read
            [varargin,step] = Utilities.argkeyval('step',varargin,amt);
            [varargin,dtclass] = Utilities.argkeyword({'double','single','int16','uint16','int32','uint32'},varargin,'double');
            [varargin,units] = Utilities.argkeyword({'normalized','volts','millivolts','microvolts'},varargin,'microvolts');
            Utilities.argempty(varargin);
            
            % avoid numerical issues
            amt = double(amt);
            step = double(step);
            
            % upate cache
            if ~isfield(this.cache,'channels') || length(this.cache.channels)~=length(channels) || ~all(this.cache.channels==channels)
                this.cache = struct('channels',channels);
            end
            
            % compute number of samples to read from input AMT
            last_pos = this.pos + amt - 1;
            if last_pos>this.hNSx.PointsPerDataPacket(this.packet)
                new_amt = this.hNSx.PointsPerDataPacket(this.packet)-this.pos+1;
                this.hDebug.log(sprintf('Requested amount (%d samples) exceeds available remaining data (%d samples); reducing to available data',amt,new_amt),'info');
                amt = new_amt;
                if step>amt,step=new_amt;end
            end
            next_pos = this.pos + step;
            if next_pos>this.hNSx.PointsPerDataPacket(this.packet)
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
            t = this.hNSx.Timestamps(this.packet)/this.hNSx.TimestampTimeResolution + last_pos/this.hNSx.Fs;
            
            % validate starting byte
            pre_byte = ftell(this.fid);
            packet_byte = this.hNSx.DataPacketByteIdx(this.packet,1)+9; % +9 for packet headers
            data_byte = (this.pos-1)*2*this.hNSx.ChannelCount;
            start_byte = packet_byte + data_byte;
            assert(pre_byte==start_byte,'Mismatch between current file position %d and expected start byte %d',pre_byte,start_byte);
            
            % read the appropriate number of bytes from the file
            dt = fread(this.fid,[this.hNSx.ChannelCount amt],'*int16');
            assert(size(dt,2)==amt,'Requested %d bytes, but fread returned %d bytes (file size %d bytes)',amt,size(dt,2),this.hNSx.SourceFileSize);
            try
                
                % retain only requested channels
                dt = dt(channels,:);
                
                % update current position
                this.pos = next_pos;
                
                % update file pointer
                new_byte = pre_byte + step*2*this.hNSx.ChannelCount;
                post_byte = ftell(this.fid);
                offset_bytes = new_byte - post_byte;
                offset_points = (step-amt)*2*this.hNSx.ChannelCount;
                assert(offset_bytes==offset_points,'Incorrect offset computed via bytes (%d) vs points (%d)',offset_bytes/2/this.hNSx.ChannelCount,offset_points/2/this.hNSx.ChannelCount);
                num_points = (new_byte-packet_byte)/(2*this.hNSx.ChannelCount);
                assert(num_points==(this.pos-1),'Incorrect file pointer after read operation: seek indicates %d samples but position suggests %d',num_points,this.pos-1);
                fseek(this.fid,offset_bytes,'cof');
            catch ME
                Utilities.errorMessage(ME);
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
                    this.cache.dh = unique([this.hNSx.ChannelInfo(channels).MaxDigitalValue]);
                    this.cache.dl = unique([this.hNSx.ChannelInfo(channels).MinDigitalValue]);
                    this.cache.nh = unique([this.hNSx.ChannelInfo(channels).MaxAnalogValue]);
                    this.cache.nl = unique([this.hNSx.ChannelInfo(channels).MinAnalogValue]);
                    assert(isscalar(this.cache.dh)&&isscalar(this.cache.dl),'All max/min digital values must be the same');
                    assert(isscalar(this.cache.nh)&&isscalar(this.cache.nl),'All max/min analog values must be the same');
                    this.cache.A = this.cache.nh-this.cache.nl;
                    this.cache.B = this.cache.dh-this.cache.dl;
                end
                
                % determine multiplicative factor for volt/milli/micro
                switch lower(units)
                    case 'microvolts',multfactor=1;
                    case 'millivolts',multfactor=1e-3;
                    case 'volts',multfactor=1e-6;
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
        
        function dt = read_nsx(this,amt,varargin)
            % READ use NSx read method from current position (no update)
            %
            %   DT = READ(THIS,AMT)
            %   Read AMT samples of data but do not update the current
            %   position.
            %
            %   Any inputs after AMT are passed through to the NSx read
            %   method.
            
            % compute number of samples to read from input AMT
            last_pos = this.pos + amt - 1;
            if last_pos>this.hNSx.PointsPerDataPacket(this.packet)
                new_amt = this.hNSx.PointsPerDataPacket(this.packet)-this.pos+1;
                this.hDebug.log(sprintf('Requested amount (%d samples) exceeds available remaining data (%d samples); reducing to available data',amt,new_amt),'info');
                amt = new_amt;
            end
            
            % convert to TimestampTimeResolution timestamps
            tm_start = this.pos;
            tm_end = tm_start + amt - 1;
            
            % read the data
            dt = this.hNSx.read('packet',this.packet,'ref','packet','points',[tm_start tm_end],varargin{:});
        end % END function read_nsx
        
        function varargout = validate(this,varargin)
            [varargin,reps] = Utilities.argkeyval('reps',varargin,1e3,3);
            [varargin,pts] = Utilities.argkeyval('pts',varargin,1e2);
            [varargin,step] = Utilities.argkeyval('step',varargin,pts);
            Utilities.argempty(varargin);
            
            % repetitively read blocks of data using both methods and
            % measure time for each
            tm_nsx = nan(reps,1);
            tm_internal = nan(reps,1);
            for nn=1:reps
                try
                    tmr = tic; dt_nsx = this.read_nsx(pts,'microvolts','double'); tm_nsx(nn)=toc(tmr);
                    tmr = tic; dt_internal = this.read(pts,'microvolts','double','step',step); tm_internal(nn)=toc(tmr);
                    assert(all(dt_internal(:)==dt_nsx(:)),'Mismatched data');
                catch ME
                    msg = Utilities.errorMessage(ME,'noscreen','nolink');
                    this.hDebug.log(sprintf('Block read failed at repeition %d/%d: %s\n',nn,reps,msg),'error');
                    break;
                end
            end
            tm_nsx(nn+1:end) = [];
            tm_internal(nn+1:end) = [];
            
            % if no outputs, print out the mean/std and show a boxplot of
            % times per repetition
            if nargout==0
                fprintf('FREAD: %.3f±%.3f sec; NSX: %.3f±%.3f sec\n',nanmean(tm_internal),nanstd(tm_internal),nanmean(tm_nsx),nanstd(tm_nsx));
                figure;
                boxplot([tm_internal(:) tm_nsx(:)]);
                set(gca,'XTickLabel',{'fread','NSx'});
                ylabel('Time (seconds)');
                title('Block read performance');
            else
                
                % otherwise assign times to the output
                if nargout>=1
                    varargout{1} = tm_internal;
                end
                if nargout>=2
                    varargout{2} = tm_nsx;
                end
            end
        end % END function validate
        
        function reset(this)
            this.cache = [];
            
            % seek to beginning of the requested packet
            packet_byte = this.hNSx.DataPacketByteIdx(this.packet,1)+9; % 9 bytes of header data
            fseek(this.fid,packet_byte,'bof');
            
            % track samples: here, in terms of the data sampling rate
            this.pos = 1;
        end % END function reset
        
        function delete(this)
            if isnumeric(this.fid) && ~isempty(this.fid) && this.fid>0
                util.closefile(this.fid);
            end
        end % END function delete
    end % END methods
end % END classdef NSxStreamer