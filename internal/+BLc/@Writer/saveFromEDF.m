function files = saveFromEDF(this,varargin)
% SAVEFROMEDF Create a BLc file from a BLACKROCK source
%
%   FILES = SAVEFROMEDF(THIS)
%   Use the source EDF object to provide data and properties to create one
%   or more binary BLC files. The BLC file(s) will be created in the same
%   directory, and with the same basename (but with a zero-based numbered
%   index appended and the BLC file extension), as the source file. The
%   output file(s) may not exist (otherwise, an error will be thrown). The
%   output FILES is a cell array of the name(s) of the saved file(s).
%
%   SAVEFROMEDF(...,'NOIDX')
%   Do not include a numerical index at the end of the filename (default is
%   to include a three-digit incrementing file index).
%
%   SAVEFROMEDF(...,'START',IDX)
%   Optionally override the starting index appended to the filename
%   (specify as an integer value, not a char).
%
%   SAVEFROMEDF(...,'BASE',BASENAME)
%   Optionally specify a different basename for the output file.
%
%   SAVEFROMEDF(...,'DIR',OUTPUTDIR)
%   Optionally specify a different output directory for the output file.
%
%   SAVEFROMEDF(...,'OVERWRITE')
%   Overwrite any existing files.
[varargin,fileidx] = util.argkeyval('start',varargin,0);
[varargin,outbase] = util.argkeyval('base',varargin,this.hSource.SourceBasename);
[varargin,outdir] = util.argkeyval('dir',varargin,this.hSource.SourceDirectory);
[varargin,overwrite] = util.argflag('overwrite',varargin,false);
[varargin,flagFileIndex] = util.argflag('noidx',varargin,true);
[varargin,flagSave] = util.argflag('nosave',varargin,true);
[varargin,fsinbase,~,found] = util.argflag('fsinbase',varargin,false);
if ~found,fsinbase=this.FlagIncludeFsInFilename;end
util.argempty(varargin);
assert(exist(outdir,'dir')==7,'Output directory "%s" does not exist',outdir);
this.hDebug.log(sprintf('Overwrite set to %d',overwrite),'debug');
this.hDebug.log(sprintf('Basename set to "%s"',outbase),'debug');
this.hDebug.log(sprintf('Output directory set to "%s"',outdir),'debug');

% validate input Blackrock.NSx object
assert(~isempty(regexpi(class(this.hSource),'EDFData')),'Must provide a valid object of class "EDFData", not "%s"',class(this.hSource));

% compute number of output files and time in each
numPointsInEDF = this.hSource.records*this.SamplingRate;
maxFramesPerOutputFile = this.SecondsPerOutputFile*this.SamplingRate;

% disregard segment boundaries when computing how many data points
% belong in each of the output files
framesPerOutputFile = nan(1,1e3);
currFile = 1;
numFramesLeftInFile = numPointsInEDF;
while numFramesLeftInFile > 0
    
    % write as many data points as we can, up to size of file
    numFramesInThisFile = min(numFramesLeftInFile,maxFramesPerOutputFile);
    if currFile>1 && numFramesInThisFile/framesPerOutputFile(currFile-1)<0.01
        framesPerOutputFile(currFile-1) = framesPerOutputFile(currFile-1) + numFramesInThisFile;
        numFramesInThisFile = 0;
    end
    
    % save the results and increment file index
    if numFramesInThisFile>0
        framesPerOutputFile(currFile) = numFramesInThisFile;
        currFile = currFile + 1;
        numFramesLeftInFile = numFramesLeftInFile - numFramesInThisFile;
    end
end
framesPerOutputFile(currFile:end) = [];
numOutputFiles = length(framesPerOutputFile);

% get dimensions of a single frame
try
    data = this.hSource.getUnscaledData([1 1],this.hSource.ns);
catch ME
    util.errorMessage(ME);
    keyboard
end
idxUserToSource = ismember(1:this.hSource.ns,this.indexChannelToWrite{1});
data = data(idxUserToSource);
info = whos('data');
bytesPerN = round(1.5*info.bytes);

% loop over output files
globalNumFramesRead = 0;
currPacket = 1;
currDataPointInPacket = 1;
files = cell(1,numOutputFiles);
for ff=1:numOutputFiles
    this.hDebug.log(sprintf('Writing data for %s (%d/%d)',outbase,ff,numOutputFiles),'debug');
    
    % set up destination file
    fsstr = this.getSamplingRateString(fsinbase);
    if flagFileIndex
        dstfile = fullfile(outdir,sprintf('%s%s-%03d.blc',outbase,fsstr,fileidx));
    else
        dstfile = fullfile(outdir,sprintf('%s%s.blc',outbase,fsstr));
    end
    this.hDebug.log(sprintf('Destination file set to "%s"',dstfile),'debug');
    str = 'exists';
    if exist(dstfile,'file')~=2
        str = 'does not exist';
    end
    this.hDebug.log(sprintf('Destination file %s (overwrite is %d)',str,overwrite),'debug');
    assert(overwrite||exist(dstfile,'file')~=2,'Output file already exists: %s',dstfile);
    files{ff} = dstfile;
    if ~flagSave,continue;end
    
    % track how many frames we need to read total for this
    % output file (this may span multiple data packets)
    numPointsToRead = framesPerOutputFile(ff);
    numPointsRead = 0; % how many frames read
    numPointsLeftToRead = numPointsToRead; % how many frames left to read
    
    % how many data sections in this output file
    numDataSections = 1;
    
    % loop until we've read all the frames for this output file
    packets(100) = struct('edfPacket',nan,'startPoint',nan,'endPoint',nan);
    packets(1).edfPacket = currPacket;
    packets(1).startPoint = currDataPointInPacket;
    while numPointsRead < numPointsToRead
        
        % the number of frames to read FROM the current data
        % packet FOR the current output file
        numPointsReadFromPacket = currDataPointInPacket-1;
        numPointsLeftInPacket = this.hSource.PointsPerDataPacket(currPacket) - numPointsReadFromPacket;
        numPointsToReadFromPacket = min(numPointsLeftToRead,numPointsLeftInPacket);
        numPointsLeftToRead = numPointsLeftToRead - numPointsToReadFromPacket;
        numPointsRead = numPointsRead + numPointsToReadFromPacket;
        if numPointsToReadFromPacket==0
            this.hDebug.log(sprintf('Skipping empty data packet %d for output file "%s" (%d/%d)',currPacket,outbase,ff,numOutputFiles),'info');
            
            % update pointers to current packet
            currPacket = currPacket + 1;
            currDataPointInPacket = 1;
            
            % update packet data
            packets(numDataSections).edfPacket = currPacket;
            packets(numDataSections).startPoint = currDataPointInPacket;
        else
            this.hDebug.log(sprintf('Writing %d data points from packet %d for output file "%s" (%d/%d)',numPointsToReadFromPacket,currPacket,outbase,ff,numOutputFiles),'info');
            
            % update packet information
            numPointsReadFromPacket = numPointsReadFromPacket + numPointsToReadFromPacket;
            lastPointInPacket = currDataPointInPacket + numPointsToReadFromPacket - 1;
            currDataPointInPacket = lastPointInPacket+1;
            if numPointsReadFromPacket >= this.hSource.PointsPerDataPacket(currPacket) && currPacket < this.hSource.NumDataPackets
                this.hDebug.log(sprintf('Rolling over to frame 1, packet %d/%d',currPacket,this.hSource.NumDataPackets),'debug');
                
                % update end frame for the current data section
                packets(numDataSections).endPoint = lastPointInPacket;
                
                % update pointers to current packet, frame, section
                currPacket = currPacket + 1;
                currDataPointInPacket = 1;
                numDataSections = numDataSections + 1;
                
                % read current frames from current packet
                packets(numDataSections).edfPacket = currPacket;
                packets(numDataSections).startPoint = currDataPointInPacket;
            end
        end
    end
    packets((numDataSections+1):end) = [];
    packets(end).endPoint = lastPointInPacket;
    
    % get header and channel info bytes
    basicHeaderBytes = getHeaderBytes(this,numDataSections);
    channelInfoBytes = getChannelInfoBytes(this);
    
    % open the file for writing
    args = {};
    if overwrite,args={'overwrite'};end
    fid = util.openfile(dstfile,'w',args{:});
    
    % write basic header and channel info bytes to the file
    try
        fwrite(fid,basicHeaderBytes,'uint8');
        fwrite(fid,channelInfoBytes,'uint8');
    catch ME
        util.closefile(dstfile);
        rethrow(ME);
    end
    this.hDebug.log(sprintf('Wrote basic header (%d bytes) and channel info (%d bytes) to "%s"',length(basicHeaderBytes),length(channelInfoBytes),dstfile),'debug');
    
    % write data sections (if there are skips, they will be written
    % as different sections; otherwise, all data will be in a
    % single section)
    numFramesWritten = 0;
    for kk=1:numDataSections
        
        % compute running timestamp, frames, bytes
        pointsBeforePacket = 0;
        if packets(kk).edfPacket>1
            pointsBeforePacket = sum(this.hSource.PointsPerDataPacket(1:packets(kk).edfPacket-1));
        end
        sectionTimestamp = pointsBeforePacket + packets(kk).startPoint;
        numPointsInSection = packets(kk).endPoint - packets(kk).startPoint + 1;
        numSectionBytes = BLc.Properties.DataHeaderLength + numPointsInSection*this.BytesPerFrame;
        this.hDebug.log(sprintf('In data section %d of file %d/%d, writing %d frames (%d bytes)',kk,kk,numOutputFiles,numPointsInSection,numSectionBytes),'debug');
        
        % determine start datetime for this data section
        secondsBeforeThisPacket = this.hSource.Timestamps(packets(kk).edfPacket)/this.hSource.Fs;
        secondsIntoThisPacket = (packets(kk).startPoint-1)/this.hSource.Fs;
        sectionDatetime = datetime(this.hSource.OriginTimeDatenum,'ConvertFrom','datenum') + ...
            seconds(secondsBeforeThisPacket+secondsIntoThisPacket);
        this.hDebug.log(sprintf('Section datetime set to %s',sectionDatetime),'debug');
        
        % get data packet header bytes
        dataHeaderBytes = getDataSectionHeaderBytes(this,numPointsInSection,sectionTimestamp,sectionDatetime);
        
        % write data packet header bytes to file
        try
            fwrite(fid,dataHeaderBytes,'uint8');
        catch ME
            util.closefile(dstfile);
            rethrow(ME);
        end
        this.hDebug.log(sprintf('Wrote data section header (%d bytes) to "%s"',length(dataHeaderBytes),dstfile),'debug');
        
        % read data out of the file
        if ~ispc
            maxPointsInMemory = 1e6; % no way to check mem on mac/linux
            this.hDebug.log(sprintf('On MacOS/Linux, it is not possible to check available memory'),'debug');
        else
            [~,maxPointsInMemory] = util.memcheck([1 1],bytesPerN,'avail',0.8);
        end
        numToRead = min(numPointsInSection,maxPointsInMemory);
        numFramesWrittenThisSection = 0;
        currStart = packets(kk).startPoint;
        try
            while numToRead>0
                
                % grab the current block of data
                this.hDebug.log(sprintf('Reading %d frames from source',numToRead),'debug');
                data = this.hSource.read('packet',packets(kk).edfPacket,'points',[currStart currStart+numToRead-1],'ref','packet','microvolts','channels',this.indexChannelToWrite{1});
                numPointsRead = size(data,2);
                currStart = currStart + numPointsRead;
                globalNumFramesRead = globalNumFramesRead + numPointsRead;
                assert(~isempty(data),'Encountered end of file before expected (tried to read %d frames)',numToRead);
                if flagSave
                    %waitbar(globalNumFramesRead/globalNumFramesToRead,hWaitbar);
                end
                drawnow;
                
                % parse the data block
                data = this.MinDigitalValue + round( this.rangeDigital*(data-this.MinAnalogValue)/this.rangeAnalog ); % convert to quantized digital units
                switch this.BitResolution
                    case 16, data = cast(data,'int16'); % convert to int16
                    case 32, data = cast(data,'int32'); % convert to int32
                    otherwise, error('Unknown bit resolution "%d"',this.BitResolution);
                end
                data = typecast(data(:),'uint8'); % get byte-level representation
                
                % write data to binary file
                fwrite(fid,data,'uint8');
                
                % update count of written numFramesWrittens
                numFramesWrittenThisSection = numFramesWrittenThisSection + numPointsRead;
                this.hDebug.log(sprintf('Wrote %d frames (%d bytes) (%d frames total in section %d)',...
                    numPointsRead,length(data),numFramesWrittenThisSection,kk),'debug');
                clear data;
                
                % read next block
                if ~ispc
                    maxPointsInMemory = 1e6; % no way to check mem on mac/linux
                    this.hDebug.log(sprintf('On MacOS/Linux, it is not possible to check available memory'),'debug');
                else
                    [~,maxPointsInMemory] = util.memcheck([1 1],bytesPerN,'avail',0.8);
                end
                numToRead = min(maxPointsInMemory,numPointsInSection-numFramesWrittenThisSection);
            end
        catch ME
            
            % clean up before re-throwing the error
            if flagSave
                %close(hWaitbar);
            end
            util.closefile(dstfile);
            rethrow(ME);
        end
        
        % update current numFramesWritten to reflect the numFramesWrittens written;
        % adjust if needed to to beginning of next section
        numFramesWritten = numFramesWritten + numFramesWrittenThisSection;
        this.hDebug.log(sprintf('%d frames written for data section %d',numFramesWritten,kk),'debug');
    end
    
    % close the fle
    util.closefile(dstfile);
    this.hDebug.log(sprintf('Finished writing %s',dstfile),'info');
    
    % increment the file index
    fileidx = fileidx + 1;
end

% close the waitbar
if flagSave
    %close(hWaitbar);
end