classdef XLTekTxt < handle
% XLTEKTXT Encapsulate ASCII-encoded text files exported from XLTek
%
% This class is intended to be used for processing text files exported from
% Natus NeuroWorks EEG as ASCII-encoded text files. These files typically
% have a few lines of headers and then print out the data as text
% characters over many lines of text.
%
% To initialize an object of this class, provide a full path to the text
% file as the input to the constructor:
%
% >> xlt = XLTekTxt('path/to/file.txt')
%
% Once the object is initialized, there are several methods to access data
% and/or properties of the data and recording.
%
% Properties of the XLTekTxt object provide some basic information such as
% source file name, path, size, etc; the date and time of the orginal
% recording; the units of the data; sampling rate; etc.
%
% To read all the data from the entire file, use the READ method.  The
% output DATA will be a MxN matrix with N channels and M samples.
%
% >> data = xlt.read;
%
% To read blocks one at a time, use the BLOCKREAD method. The first time
% this method runs, it will open the file for reading and store the file
% identifier. Additionally, the method remembers the last location read,
% and with each successive call will return the next chunk of data.
%
% >> data = xt.blockread;
%
% There have been several instances where the data for individual channels
% had an arbitrary DC offset applied to visually shift the channel up or
% down in the Natus NeuroWorks EEG viewer software. To account for this the
% possibility, the READ method will subtract the global mean from each
% channel. Internally, it calls the MEAN method of the XLTEKTXT object,
% which processes the file in blocks to calculate the global mean. In other
% words, reading the file results in two complete, consecutive passes
% through the entire file.
    
    properties(SetAccess=private,GetAccess=public)
        hDebug % handle to debugger
        
        SourceDirectory % the directory containing the source file
        SourceBasename % the basename of the source file
        SourceExtension % the file extension of the source file
        SourceFileRead = false; % flag to indicate file read successfully
        SourceFileSize % size of the source file in bytes
        
        OriginalFile % name of the original file (usually with *.ERD extension)
        OriginalStart % start date and time of the original recording
        OriginalEnd % end date and time of the original recording
        ExportedStart % start date and time of the exported data
        ExportedEnd % end date and time of the exported data
        Units % units of the exported data (typically 'V', 'mV', 'uV', 'A/D Units')
        
        PatientName % name of the patient
        PatientID % anonymous identifier of the patient
        StudyID % anonymous identifier of the study
        HeadboxSN % serial number of the headbox
        
        SamplingRate % sampling rate of the data in the source file
        NumChannelsInOriginal % number of channels recorded in the source file
        NumChannelsInASCII % number of channels listed in the ASCII file
        
        FlagPositiveFlip = true % flag to flip the sign of the data (eeg standard has positive down)
        FlagRemoveDCOffset = true; % flag to remove DC offset when reading data
        
        ChannelAverage % global average of each channel
        ChannelMinimum % global minimum of each channel
        ChannelMaximum % global maximum of each channel
        
        SectionStartDatetime % start of each section as a string
        SectionStart % start of each section of contiguous samples
        SectionLength % number of records in each section of contiguous samples
        NumDataPoints % number of data points in the whole file
        DataFieldLabels % column headers for the ASCII data
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        fid % the file identifier for block reads
        LastBlockByte % remember the last byte of the previous block
        FlagFoundNextSecond = true % look for how many samples until the time increments to the next second to infer milliseconds
        SamplesElapsed = 0; % count how many samples have elapsed since second rollover between blocks
    end % END properties(Access=private)
    
    methods
        function this = XLTekTxt(varargin)
            % XLTEKTXT Process ASCII-encoded text files exported from XLTek
            %
            %   THIS = XLTEKTXT(PATH_TO_FILE)
            %   Create an XLTEKTXT object by providing the full path to a
            %   ASCII-encoded data file exported from Natus NeuroWorks EEG
            %   software (typically from a *.ERD source file).
            %
            %   THIS = XLTEKTXT(...,'NOFLIP')
            %   Optionally specify not to flip the sign of the data coming
            %   out of the text file. Neurology convention is to view
            %   signals with signs flipped, so setting this option will
            %   return data with that convention. Default behavior is to
            %   flip the signs so that positive is positive (as recorded).
            %
            %   THIS = XLTEKTXT(...,'NOOFFSET')
            %   Optionall specify not to subtract the channel average from
            %   the data. Natus NeuroWorks EEG viewer has been known to add
            %   in a DC offset to shift channels up visually in the graph.
            %   Default behavior is to remove any DC offsets, but with this
            %   option data will be returned as stored in the file.
            %
            %   NOTE: When the object is initialized it will run through
            %   the *entire* file once to calculate the min, max, and
            %   average of each channel (but in blocks to avoid huge memory
            %   usage).
            
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
                    [srcfile,srcdir] = uigetfile(fullfile(srcdir,'*.txt'),'Select a file','MultiSelect','off');
                    assert(~isnumeric(srcfile),'Must select a valid file to continue');
                    src = fullfile(srcdir,srcfile);
                end
            end
            [varargin,this.hDebug] = util.argisa('Debug.Debugger',varargin,[]);
            if isempty(this.hDebug)
                this.hDebug = Debug.Debugger(sprintf('blc_writer_%s',datestr(now,'yyyymmdd-HHMMSS')));
            end
            assert(~isempty(src),'Must provide a valid source file');
            srcinfo = dir(src);
            [this.SourceDirectory,this.SourceBasename,this.SourceExtension] = fileparts(src);
            this.SourceFileSize = srcinfo.bytes;
            this.hDebug.log(sprintf('Source file is "%s" (%s)',src,util.bytestr(this.SourceFileSize)),'info');
            
            % capture flag overrides
            [varargin,this.FlagPositiveFlip] = util.argflag('noflip',varargin,true);
            [varargin,this.FlagRemoveDCOffset] = util.argflag('nooffset',varargin,true);
            util.argempty(varargin);
            this.hDebug.log(sprintf('Set FlagPositiveFlip to %d',this.FlagPositiveFlip),'debug');
            this.hDebug.log(sprintf('Set FlagRemoveDCOffset to %d',this.FlagRemoveDCOffset),'debug');
            
            % process the header
            header(this);
            this.hDebug.log(sprintf('Loaded header data from source file'),'info');
            
            % process stats of the file data
            preprocess(this);
            this.hDebug.log(sprintf('Finished preprocessing source file'),'info');
        end % END function XLTekTxt
        
        function [N,bytes] = calculateMaxFrames(this,varargin)
            % CALCULATEMAXFRAMES Compute number of frames to load at once
            %
            %   N = CALCULATEMAXFRAMES(THIS)
            %   Compute the number of frames that can be loaded
            %   simultaneously into memory, taking up no more than 80% of
            %   available memory.
            %
            %   [N,BYTES] = CALCULATEMAXFRAMES(THIS)
            %   Also return the number of bytes that will be taken up in
            %   memory when loading N frames.
            %
            %   [...] = CALCULATEMAXFRAMES(...,'availutil',FRAC)
            %   Set the fraction of available memory that can be used
            %   (0<FRAC<=1).
            %
            %   [...] = CALCULATEMAXFRAMES(...,'bytesperframe',BYTES)
            %   Specify the number of bytes per frame.
            %
            %   [...] = CALCULATEMAXFRAMES(...,'multiplier',MULT)
            %   Specify a multiplier to account for intermediate steps that
            %   may affect the total memory required (default 2.0).
            %
            %   [...] = CALCULATEMAXFRAMES(...,'channels',CHLIST)
            %   Specify the list of channels that will be read (default all
            %   channels).
            %
            %   *NOTE* When calling this method during operations, the
            %   number of bytes per frame MUST be provided. Otherwise, this
            %   method will reset the file to the beginning and read a
            %   single frame to compute the number of bytes.
            [varargin,chlist,~,found_chlist] = util.argkeyval('channels',varargin,nan);
            [varargin,frac] = util.argkeyval('availutil',varargin,0.8);
            [varargin,count_data,~,found_nodata] = util.argflag('nodata',varargin,true);
            [varargin,~,~,found_data] = util.argflag('data',varargin,false);
            if found_nodata && ~found_data
                count_data = false;
            elseif ~found_nodata && found_data
                count_data = true;
            end
            [varargin,count_timestrings] = util.argflag('timestrings',varargin,false,7);
            [varargin,count_timestamps] = util.argflag('timestamps',varargin,false);
            [varargin,bytes,~,found] = util.argkeyval('bytesperframe',varargin,0);
            if ~found
                
                % get dimensions of a single frame
                data = blockread(this,1,'reset','no_offset');
                reset(this);
                
                % compute how many frames will fit into 80% of
                % available memory
                if count_timestrings,tmp1=data{1};end
                if count_timestamps,tmp2=data{2};end
                if count_data,tmp3=data{3};end
                if found_chlist,tmp3=tmp3(chlist);end % subselect channels
                info = whos('tmp*');
                assert(~isempty(info),'Must count at least one of data, time strings, or timestamps');
                bytes = sum([info.bytes]); % add a 2x factor b/c textscan collectOutput method
            end
            [varargin,mult] = util.argkeyval('multiplier',varargin,1,4);
            util.argempty(varargin);
            bytes = round(mult*bytes);
            
            % compute N, bytes
            if ~ispc
                N = 1e6; % no way to check mem on mac/linux
                this.hDebug.log(sprintf('On MacOS/Linux, it is not possible to check available memory'),'debug');
            else
                [~,N] = util.memcheck([1 1],bytes,'avail',frac);
            end
            this.hDebug.log(sprintf('Max frames set to %d frames, %d bytes per frame',N,bytes),'debug');
        end % END function calculateMaxFrames
        
        function [avg,minval,maxval,len] = preprocess(this,varargin)
            % PREPROCESS Compute global mean, min, max, and length
            %
            %   [AVG,MINVAL,MAXVAL,LEN] = PREPROCESS(THIS)
            %   Compute the global average, minimum, and maximum of each
            %   channel in AVG, MINVAL, and MAXVAL, respectively, and count
            %   the total number of samples in the file in LEN. To avoid
            %   large memory overhead, this method will process the data in
            %   blocks, then compute the global average as a weighted
            %   average of the block averages; running competitions on
            %   global min/max will be offset by the final value of the
            %   global average at the end.
            %
            %   [...] = PREPROCESS(...,'numframes',N)
            %   Optionally specify how many lines should be read at once
            %   when processing the source text file. By default, on each
            %   iteration a new value of N will be computed to use 80% of
            %   available memory (but on MacOS/Linux, this will be constant
            %   1e6).
            %
            %   [...] = PREPROCESS(...,'constant')
            %   Specify that the number of frames should not be
            %   re-calculated on each iteration.
            %
            %   [...] = PREPROCESS(...,'memutil',FRAC)
            %   Specify the fraction FRAC (0<FRAC<=1) of available memory
            %   that can be used to load in frames of data.
            assert(this.SourceFileRead,'Source file has not been loaded yet');
            [varargin,flag_adapt] = util.argflag('constant',varargin,true);
            [varargin,memutil] = util.argkeyval('memutil',varargin,0.8);
            [N,bytesPerFrame] = calculateMaxFrames(this,'availutil',memutil,'multiplier',2,'timestamps','timestrings','data');
            
            [varargin,N] = util.argkeyval('numframes',varargin,N);
            util.argempty(varargin);
            this.hDebug.log(sprintf('Set flag_adapt = %d',flag_adapt),'debug');
            this.hDebug.log(sprintf('Set memutil = %.2f',memutil),'debug');
            this.hDebug.log(sprintf('Set N = %d',N),'debug');
            
            % pre-allocate many blocks
            len = nan(1e5,1);
            avg = cell(1e5,1);
            minval = inf(1,this.NumChannelsInASCII);
            maxval = -inf(1,this.NumChannelsInASCII);
            idx = 1;
            
            % read data in blocks
            currTimestamp = nan;
            pos = 0;
            h = waitbar(pos/this.SourceFileSize,'Calculating channel statistics');
            reset(this);
            try
                while pos<this.SourceFileSize
                    
                    % free up memory
                    clear data timestrings timestamps;
                    
                    % read new data
                    if flag_adapt
                        N = calculateMaxFrames(this,'availutil',memutil,'bytesperframe',bytesPerFrame,'multiplier',1,'timestamps','timestrings','data');
                        this.hDebug.log(sprintf('Will read %d frames (%d bytes per frame)',N,bytesPerFrame),'info');
                    end

                    [data,pos] = blockread(this,N,'no_offset');
                    waitbar(pos/this.SourceFileSize);
                    this.hDebug.log(sprintf('Read %d frames; position %d/%d (%.2f%% complete)',size(data{3},1),pos,this.SourceFileSize,100*pos/this.SourceFileSize),'info');
                    drawnow;
                    
                    % process the current block of data
                    timestrings = data{1}; % pull out the data time
                    timestamps = data{2}; % pull out the event byte
                    data = data{3}; % pull out just the sampled data
                    len(idx) = size(data,1); % calculate block length
                    avg{idx} = nanmean(data,1); % calculate block mean
                    minval = nanmin(minval,min(data,[],1)); % calculate running min
                    maxval = nanmax(maxval,max(data,[],1)); % calculate running max
                    
                    % keep looking for next second rollover
                    if ~this.FlagFoundNextSecond
                        for nn=1:min(size(timestrings,1),this.SamplingRate-this.SamplesElapsed)
                            tmpDatetime = datetime(strjoin(timestrings(nn,:),' '),'InputFormat','MM/dd/yyyy HH:mm:ss.SSS');
                            if seconds(tmpDatetime-this.SectionStartDatetime(end))==1.0
                                this.SamplesElapsed = this.SamplesElapsed + nn;
                                offset = seconds((this.SamplingRate-this.SamplesElapsed)/this.SamplingRate);
                                if isequal(this.OriginalStart,this.SectionStartDatetime(end))
                                    
                                    % if the origin start time was the same
                                    % as the section start time, we'll make
                                    % a big but reasonable assumption that
                                    % the origin time was the start of data
                                    % recording, so both should be updated
                                    this.OriginalStart = this.OriginalStart + offset;
                                end
                                this.SectionStartDatetime(end) = this.SectionStartDatetime(end) + offset;
                                this.FlagFoundNextSecond = true;
                                break;
                            end
                        end
                        if ~this.FlagFoundNextSecond
                            this.SamplesElapsed = this.SamplesElapsed + nn;
                        end
                    end
                    
                    % first time through - start a new data section
                    if isnan(currTimestamp)
                        
                        % first time through - initialize first section,
                        % set lastblockbyte to dummy value
                        currTimestamp = timestamps(1);
                        this.SectionStartDatetime = datetime(strjoin(timestrings(1,:),' '),'InputFormat','MM/dd/yyyy HH:mm:ss.SSS','format','dd-MMM-yyyy HH:mm:ss.SSS');
                        this.SectionStart = double(currTimestamp);
                        this.LastBlockByte = timestamps(1)-1;
                        this.hDebug.log(sprintf('Starting section 1 at timestamp %d: %s',double(currTimestamp),this.SectionStartDatetime),'info');
                        
                        % ascii text files have poor time resolution - only
                        % listed to the nearest second. here we count how
                        % many samples until the second rolls over, and use
                        % that proportion of the sampling rate to infer how
                        % many milliseconds we were into the second
                        this.SamplesElapsed = 0;
                        this.FlagFoundNextSecond = false;
                        for nn=2:min(this.SamplingRate,size(timestrings,1))
                            tmpDatetime = datetime(strjoin(timestrings(nn,:),' '),'InputFormat','MM/dd/yyyy HH:mm:ss.SSS');
                            if seconds(tmpDatetime-this.SectionStartDatetime)==1.0
                                offset = seconds((this.SamplingRate-nn)/this.SamplingRate);
                                if isequal(this.OriginalStart,this.SectionStartDatetime)
                                    
                                    % if the origin start time was the same
                                    % as the section start time, we'll make
                                    % a big but reasonable assumption that
                                    % the origin time was the start of data
                                    % recording, so both should be updated
                                    this.OriginalStart = this.OriginalStart + offset;
                                end
                                this.SectionStartDatetime = this.SectionStartDatetime + offset;
                                this.hDebug.log(sprintf('With %d frames until seconds-place rollover (Fs = %d samples/sec), adjusted section start datetime by %.3f seconds to %s',nn,this.SamplingRate,seconds(offset),this.SectionStartDatetime),'info');
                                this.FlagFoundNextSecond = true;
                                break;
                            end
                        end
                        if ~this.FlagFoundNextSecond
                            this.SamplesElapsed = this.SamplesElapsed + nn;
                        end
                    end
                    
                    % identify byte increments greater than one (these
                    % indicate data section boundaries)
                    skips = find([timestamps(1)-this.LastBlockByte; diff(timestamps)]>1) - 1; % -1 because we added the lastblockbyte up front
                    for kk=1:length(skips)
                        
                        % get end byte of the last section
                        if skips(kk)==0
                            val = this.LastBlockByte;
                        else
                            val = timestamps(skips(kk));
                        end
                        seclen = double(val - this.SectionStart(end) + 1);
                        
                        % compute length, start, timestamp for the new
                        % data section
                        secst = double(timestamps(skips(kk)+1));
                        sectm = datetime(strjoin(timestrings(skips(kk)+1,:),' '),'InputFormat','MM/dd/yyyy HH:mm:ss.SSS','format','dd-MMM-yyyy HH:mm:ss.SSS');
                        if isempty(this.SectionLength)
                            this.SectionLength = seclen;
                        else
                            this.SectionLength(end+1) = seclen;
                        end
                        this.hDebug.log(sprintf('Section %d ended with length %d timestamps',length(this.SectionLength),seclen),'info');
                        this.SectionStart(end+1) = secst;
                        this.SectionStartDatetime(end+1) = sectm;
                        this.hDebug.log(sprintf('Starting section %d at timestamp %d: %s',length(this.SectionStart),secst,this.SectionStartDatetime(end)),'info');
                        
                        % count how many samples until the second rolls
                        % over to infer milliseconds
                        this.SamplesElapsed = 0;
                        this.FlagFoundNextSecond = false;
                        for nn=2:min(this.SamplingRate,size(timestrings,1)-(skips(kk)+1))
                            tmpDatetime = datetime(strjoin(timestrings(skips(kk)+1+nn,:),' '),'InputFormat','MM/dd/yyyy HH:mm:ss.SSS');
                            if seconds(tmpDatetime-this.SectionStartDatetime(end))==1.0
                                offset = seconds((this.SamplingRate-nn)/this.SamplingRate);
                                this.SectionStartDatetime(end) = this.SectionStartDatetime(end) + offset;
                                this.hDebug.log(sprintf('With %d frames until seconds-place rollover, adjusted section start datetime by %d seconds to %s',nn,seconds(offset),this.SectionStartDatetime(end)),'info');
                                this.FlagFoundNextSecond = true;
                                break;
                            end
                        end
                        if ~this.FlagFoundNextSecond
                            this.SamplesElapsed = this.SamplesElapsed + nn;
                        end
                    end
                    this.LastBlockByte = timestamps(end);
                    
                    % update idx
                    idx = idx + 1;
                end
            catch ME
                
                % clean up before re-throwing the error
                close(h);
                rethrow(ME);
            end
            
            % close the waitbar
            close(h);
            
            % end the last section
            this.SectionLength(end+1) = timestamps(end) - this.SectionStart(end) + 1;
            this.hDebug.log(sprintf('Section %d ended with length %d timestamps',length(this.SectionLength),this.SectionLength(end)),'info');
            
            % get rid of unused elements
            len(idx:end) = [];
            avg(idx:end) = [];
            
            % concatenate used elements
            avg = cat(1,avg{:});
            
            % compute global mean from block means
            avg = sum(avg.*repmat(len/sum(len),1,this.NumChannelsInASCII),1);
            
            % sum up block lengths
            len = sum(len);
            
            % add DC-offset subtraction into min/max
            if this.FlagRemoveDCOffset
                minval = minval - avg(:)';
                maxval = maxval - avg(:)';
            end
            
            % assign properties
            this.ChannelAverage = avg;
            this.ChannelMinimum = minval;
            this.ChannelMaximum = maxval;
            this.NumDataPoints = len;
            this.hDebug.log(sprintf('Read %d frames for %d channels',len,length(this.ChannelAverage)),'info');
        end % END function preprocess
        
        function [data,pos] = blockread(this,N,varargin)%flag_reset,internal_use__no_offset)
            % BLOCKREAD Read data in consecutive blocks from the text file
            %
            %   DATA = BLOCKREAD(THIS)
            %   Read data in successive blocks from the source text file.
            %   The first time the method runs, it will open the file for
            %   reading and store the file identifier in a private property
            %   of THIS. For subsequent calls to the method, this file
            %   identifier will be used to read out the next block and so
            %   forth. When the end-of-file is encountered, the method will
            %   return the last segment of data and close the file. If the
            %   user deletes the object before encountering the
            %   end-of-file, the DELETE method of THIS will attempt to
            %   close the file.
            %
            %   DATA = BLOCKREAD(THIS,N)
            %   Optionally specify the number of lines to return. The
            %   default value of N is 1e6.
            %
            %   DATA = BLOCKREAD(THIS,N,RESET)
            %   Optionally indicate that the file identifier and read
            %   location should be reset (i.e., start reading from the
            %   beginning). Set RESET=TRUE to perform the reset. The
            %   default value is FALSE.
            assert(this.SourceFileRead,'Source file has not been loaded yet');
            if nargin<2||isempty(N),N=1e6;end
            [varargin,flag_reset] = util.argflag('reset',varargin,false);
            [varargin,chlist,~,found_chlist] = util.argkeyval('channels',varargin,nan);
            [varargin,internal_use__no_offset] = util.argflag('no_offset',varargin,false);
            util.argempty(varargin);
            srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
            data = [];
            
            % the format for interpreting each line of the ascii file
            format = strjoin(['%s %s %d' repmat({'%f'},1,this.NumChannelsInASCII) '%s']);
            
            % reset block read to start back at the file beginning
            if flag_reset && ~isempty(this.fid),reset(this);end
            
            % check whether file is already open for reading
            if isempty(this.fid)
                
                % open the file for reading
                this.fid = util.openfile(srcfile,'r');
                
                % find out how many header lines
                flagHeaderLine = true;
                numHeaderLines = 0;
                startPos = 0;
                while ~feof(this.fid) && flagHeaderLine
                    ln = fgetl(this.fid);
                    if ~strcmpi(ln(1),'%'),flagHeaderLine=false;end
                    if flagHeaderLine
                        startPos = ftell(this.fid);
                        numHeaderLines = numHeaderLines + 1;
                    end
                end
                
                % reverse back to beginning of file and skip past headers
                fseek(this.fid,startPos,'bof');
            end
            pos = ftell(this.fid);
            if N==0,return;end
            
            % check for end-of-file, or read the next chunk
            if feof(this.fid)
                pos = this.SourceFileSize;
                util.closefile(srcfile);
                this.fid = [];
            else
                try
                    % read data from the text file
                    [data,pos] = textscan(this.fid,format,N,'CommentStyle','%','CollectOutput',true,'TreatAsEmpty',{'AMPSAT','SHORT'});
                    
                    % subselect channels
                    if found_chlist
                        data{3} = data{3}(:,chlist);
                    end
                    
                    % flip the sign of the data
                    if this.FlagPositiveFlip
                        data{3} = -data{3};
                    end
                    
                    % subtract global average from each channel
                    if this.FlagRemoveDCOffset && ~internal_use__no_offset
                        chavg = this.ChannelAverage(chlist);
                        data{3} = data{3} - repmat(chavg(:)',size(data{3},1),1);
                    end
                catch ME
                    
                    % close the file
                    util.closefile(srcfile);
                    this.fid = [];
                    rethrow(ME);
                end
            end
        end % END function blockread
        
        function data = read(this,N)
            % READ Read all data from the file
            %
            %   DATA = READ(THIS)
            %   Read all data available in the text file. Will load the
            %   data in blocks, then concatenate the blocks at the end. The
            %   default behavior is to load 100,000 lines of text at once.
            %
            %   DATA = READ(THIS,N)
            %   Optionally specify a number of lines to process at once in
            %   N. The default value of N is 1e6.
            assert(this.SourceFileRead,'Source file has not been loaded yet');
            if nargin<2||isempty(N),N=1e6;end
            
            % pre-allocate cell array
            M = 1e6;
            data = cell(1,M);
            
            % read data out of the file
            idx = 1;
            ln = blockread(this,N,'reset');
            while ~isempty(ln)
                
                % pull out data
                data{idx} = ln{3};
                
                % update user
                %fprintf('Index %d: data size %d; isnan %d\n',idx,size(data{idx},1),any(isnan(data{idx}(:))));
                
                % increment pointer and read next block
                idx = idx + 1;
                ln = blockread(this,N);
            end
            
            % remove extra elements
            data(idx:end) = [];
            
            % combine cells
            data = cat(1,data{:});
        end % END function read
        
        function reset(this)
            % RESET close and re-open the file
            
            % try to close the FID if it's open
            srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
            util.closefile(srcfile);
            this.fid = [];
        end % END function reset
        
        function delete(this)
            % DELETE Delete the object
            %
            %   DELETE(THIS)
            %   This function will attempt to close the file identifier if
            %   it is not empty.
            if ~isempty(this.fid)
                srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
                try util.closefile(srcfile); this.fid=[]; catch ME, util.errorMessage(ME); end
            end
        end % END function delete
    end % END methods
    
    methods(Access=private)
        function header(this)
            % HEADER Process the headers of the ASCII-encoded file
            %
            %   HEADER(THIS)
            %   Read the header information from the ASCII file and
            %   populate relevant properties of the XLTEKTXT object THIS.
            
            % open the file for reading
            srcfile = fullfile(this.SourceDirectory,sprintf('%s%s',this.SourceBasename,this.SourceExtension));
            this.fid = util.openfile(srcfile);
            this.hDebug.log(sprintf('Processing header from source file "%s"',srcfile),'debug');
            
            try
                % read original file field
                ln = textscan(this.fid,'%s',1,'delimiter','\n','headerlines',1); % skip the first line with all %'s
                st = regexpi(ln{1},'^% Original File:\s+(?<origfile>.*\.erd)$','names');
                this.OriginalFile = st{1}.origfile;
                this.hDebug.log(sprintf('Original file: %s',this.OriginalFile),'debug');
                
                % read original file start/end date-time
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexpi(ln{1},['^% Original file start/end time:\s+' ...
                    '(?<start>\d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}:\d{2}(\.\d{3})?)\s+' ...
                    '(?<end>\d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}:\d{2}(\.\d{3})?)$'],'names');
                this.OriginalStart = datetime(st{1}.start,'InputFormat','MM/dd/yyyy HH:mm:ss.SSS','format','dd-MMM-yyyy HH:mm:ss.SSS');
                % correct for time > 24:00:00.00
                if str2num(st{1}.end(12:13))>=24
                    [Y,M,D]=ymd(this.OriginalStart);
                    splittime=strsplit(st{1}.end(12:end), {':', '.'});
                    splittime{1}(1:2)=num2str(str2num(splittime{1})-24);
                    temptime=cellfun(@(x)str2num(x),splittime,'UniformOutput',false);
                    splittimet=cell2mat(temptime);
                    tempend=datetime(Y,M,D,splittimet(1),splittimet(2),splittimet(3),splittimet(4), 'format','dd-MMM-yyyy HH:mm:ss.SSS');
                    st{1}.end=tempend+days(1);
                end
                
                this.OriginalEnd = datetime(st{1}.end,'InputFormat','MM/dd/yyyy HH:mm:ss.SSS','format','dd-MMM-yyyy HH:mm:ss.SSS');                
                this.hDebug.log(sprintf('Original start time: %s',this.OriginalStart),'debug');
                this.hDebug.log(sprintf('Original end time: %s',this.OriginalEnd),'debug');
                
                % read exported file start/end date-time
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexpi(ln{1},['^% Exported file start/end time:\s+' ...
                    '(?<start>\d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}:\d{2}(\.\d{3})?)\s+' ...
                    '(?<end>\d{2}/\d{2}/\d{4}\s+\d{1,2}:\d{2}:\d{2}(\.\d{3})?)$'],'names');
                this.ExportedStart = datetime(st{1}.start,'InputFormat','MM/dd/yyyy HH:mm:ss.SSS','format','dd-MMM-yyyy HH:mm:ss.SSS');
                if str2num(st{1}.end(12:13))>=24
                    [Y,M,D]=ymd(this.OriginalStart);
                    splittime=strsplit(st{1}.end(12:end), {':', '.'});
                    splittime{1}(1:2)=num2str(str2num(splittime{1})-24);
                    temptime=cellfun(@(x)str2num(x),splittime,'UniformOutput',false);
                    splittimet=cell2mat(temptime);
                    tempend=datetime(Y,M,D,splittimet(1),splittimet(2),splittimet(3),splittimet(4), 'format','dd-MMM-yyyy HH:mm:ss.SSS');
                    st{1}.end=tempend+days(1);
                end
                this.ExportedEnd = datetime(st{1}.end,'InputFormat','MM/dd/yyyy HH:mm:ss.SSS','format','dd-MMM-yyyy HH:mm:ss.SSS');
                this.hDebug.log(sprintf('Export start time: %s',this.ExportedStart),'debug');
                this.hDebug.log(sprintf('Export end time: %s',this.ExportedEnd),'debug');
                
                % read Units
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexp(ln{1},'^% Units:\s+(?<units>.*)$','names');
                this.Units = st{1}.units;
                this.hDebug.log(sprintf('Set Units to %s',this.Units),'debug');
                
                % read patient name
                ln = textscan(this.fid,'%s',1,'delimiter','\n','headerlines',1);
                st = regexp(ln{1},'^% Patient''s Name:\s+(?<name>.*)$','names');
                this.PatientName = strsplit(st{1}.name,' ');
                this.hDebug.log(sprintf('Set PatientName to %s',strjoin(this.PatientName,', ')),'debug');
                
                % read sampling rate
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexp(ln{1},'^% Sampling Rate\s+(?<fs>.*) Hz$','names');
                this.SamplingRate = str2double(st{1}.fs);
                this.hDebug.log(sprintf('Set SamplingRate to %d',this.SamplingRate),'debug');
                
                % read number of channels
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexp(ln{1},'^% Channels\s+(?<channels>\d+)$','names');
                this.NumChannelsInOriginal = str2double(st{1}.channels);
                this.hDebug.log(sprintf('Set NumChannelsInOriginal to %d',this.NumChannelsInOriginal),'debug');
                
                % read patient ID, study ID
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexp(ln{1},'^% Patient ID Study ID\s+(?<pid>\d+)\s+(?<sid>\d+)$','names');
                this.PatientID = str2double(st{1}.pid);
                this.StudyID = str2double(st{1}.sid);
                this.hDebug.log(sprintf('Set PatientID to %d',this.PatientID),'debug');
                this.hDebug.log(sprintf('Set StudyID to %d',this.StudyID),'debug');
                
                % read headbox serial number
                ln = textscan(this.fid,'%s',1,'delimiter','\n');
                st = regexp(ln{1},'^% Headbox SN\s+(?<sn>\d+)$','names');
                this.HeadboxSN = str2double(st{1}.sn);
                this.hDebug.log(sprintf('Set HeadboxSN to %d',this.HeadboxSN),'debug');
                
                % skip a line, then read out column labels
                fgetl(this.fid);
                fgetl(this.fid);
                ln = fgetl(this.fid);
                len_whitespace = cellfun(@length,regexpi(ln,'\s+','match'));
                idx_whitespace = regexpi(ln,'\s+');
                idx_label_st = idx_whitespace + len_whitespace;
                idx_label_lt = idx_whitespace-1;
                labels = arrayfun(@(st,lt)ln(st:lt),idx_label_st(1:end-1),idx_label_lt(2:end),'UniformOutput',false);
                labels(strcmpi(labels,'%c')) = []; % not sure what this is but it doesn't correspond to a data field
                idx_channel_labels = ~cellfun(@isempty,regexpi(labels,'^C\d{1,4}$'));
                channel_labels = labels(idx_channel_labels);
                this.NumChannelsInASCII = length(channel_labels);
                this.hDebug.log(sprintf('Set NumChannelsInASCII to %d',this.NumChannelsInASCII),'debug');
                this.DataFieldLabels = labels;
            catch ME
                util.closefile(srcfile);
                this.fid = [];
                rethrow(ME);
            end
            
            % close the file
            util.closefile(srcfile);
            this.fid = [];
            
            % set the read flag to true
            this.SourceFileRead = true;
        end % END function header
    end % END methods(Access=private)
end % END classdef xltektxt