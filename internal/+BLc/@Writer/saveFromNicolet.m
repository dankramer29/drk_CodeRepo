function files = saveFromNicolet(this,varargin)
% SAVEFROMNICOLET Create a BLc file from a NICOLET source
%
%   FILES = SAVEFROMNICOLET(THIS)
%   Use the source NICOLET object to provide data and properties to create
%   one or more binary BLC files. The BLC file(s) will be created in the
%   same directory, and with the same basename (but with a zero-based
%   numbered index appended and the BLC file extension), as the source
%   file. The output file(s) may not exist (otherwise, an error will be
%   thrown). The output FILES is a cell array of the name(s) of the saved
%   file(s).
%
%   SAVEFROMNICOLET(...,'NOIDX')
%   Do not include a numerical index at the end of the filename (default is
%   to include a three-digit incrementing file index).
%
%   SAVEFROMNICOLET(...,'START',IDX)
%   Optionally override the starting index appended to the filename
%   (specify as an integer value, not a char).
%
%   SAVEFROMNICOLET(...,'BASE',BASENAME)
%   Optionally specify a different basename for the output file.
%
%   SAVEFROMNICOLET(...,'DIR',OUTPUTDIR)
%   Optionally specify a different output directory for the output file.
%
%   SAVEFROMXLTEKTXT(...,'OVERWRITE')
%   Overwrite any existing files.
[varargin,flagSave] = util.argflag('nosave',varargin,true);
[varargin,fileidx] = util.argkeyval('start',varargin,0);
[varargin,outbase] = util.argkeyval('base',varargin,this.hSource.SourceBasename);
[varargin,outdir] = util.argkeyval('dir',varargin,this.hSource.SourceDirectory);
[varargin,overwrite] = util.argflag('overwrite',varargin,false);
[varargin,flagFileIndex] = util.argflag('noidx',varargin,true);
[varargin,fsinbase,~,found] = util.argflag('fsinbase',varargin,false);
if ~found,fsinbase=this.FlagIncludeFsInFilename;end
[varargin,seginbase,~,found] = util.argflag('seginbase',varargin,false);
if ~found,seginbase=this.FlagIncludeSegmentInFilename;end
util.argempty(varargin);
assert(exist(outdir,'dir')==7,'Output directory "%s" does not exist',outdir);
this.hDebug.log(sprintf('Overwrite set to %d',overwrite),'debug');
this.hDebug.log(sprintf('Basename set to "%s"',outbase),'debug');
this.hDebug.log(sprintf('Output directory set to "%s"',outdir),'debug');
assert(this.FlagSplitFilesOnSegments,'There are so many potential ramifications to allowing multiple segments in the same BLC file that it is not currently supported.');

% validate input NicoletFile object
assert(~isempty(regexpi(class(this.hSource),'NicoletEFile')),'Must provide a valid object of class "Natus.NicoletEFile", not "%s"',class(this.hSource));

% compute number of output files and time in each
numDataPointsInSource = sum(this.hSource.NumDataPoints(this.Segment));
maxFramesPerOutputFile = this.SecondsPerOutputFile*this.SamplingRate;
if this.FlagSplitFilesOnSegments
    
    % compute number of data frames in output files, accounting for the
    % rule that any given file can only contain data from one segment
    framesPerOutputFile = cell(1,length(this.Segment));
    for kk=1:length(this.Segment)
        currFile = 1;
        currSegment = this.Segment(kk);
        numFramesLeftInSegment = this.hSource.NumDataPoints(currSegment);
        framesPerOutputFile{kk} = nan(1,1e3);
        while numFramesLeftInSegment > 0
            
            % write as many data points as we can, up to size of segment
            numFramesInThisFile = min(numFramesLeftInSegment,maxFramesPerOutputFile(kk));
            if currFile>1 && numFramesInThisFile/framesPerOutputFile{kk}(currFile-1)<0.01
                framesPerOutputFile(currFile-1) = framesPerOutputFile(currFile-1) + numFramesInThisFile;
                numFramesInThisFile = 0;
            end
            
            % save the results and increment file index
            if numFramesInThisFile>0
                framesPerOutputFile{kk}(currFile) = numFramesInThisFile;
                currFile = currFile + 1;
                numFramesLeftInSegment = numFramesLeftInSegment - numFramesInThisFile;
            end
        end
        
        % clean up extra entries
        framesPerOutputFile{kk}(currFile:end) = [];
    end
    framesPerOutputFile = cat(2,framesPerOutputFile{:});
else
    
    % disregard segment boundaries when computing how many data points
    % belong in each of the output files
    framesPerOutputFile = nan(1,1e3);
    currFile = 1;
    numFramesLeftInFile = sum(this.hSource.NumDataPoints(this.Segment));
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
    
    % clean up extra entries
    framesPerOutputFile(currFile:end) = [];
end
numOutputFiles = length(framesPerOutputFile);

% loop over output files
globalNumFramesRead = 0;
globalNumFramesToRead = numDataPointsInSource;
lastSegment = nan;
currSegment = 1;
currDataPointInSegment = 1;
hWaitbar = waitbar(0/numDataPointsInSource,sprintf('Writing data to %s (%d/%d)',outbase,1,numOutputFiles));
hWaitbarTitle = get(get(findobj(hWaitbar,'Type','figure'),'currentaxes'),'title');
set(hWaitbarTitle,'interpreter','none'); % no special interpretation of text
drawnow;
files = cell(1,numOutputFiles);
for ff=1:numOutputFiles
    set(hWaitbarTitle,'String',sprintf('Processing %s (%d/%d)',outbase,ff,numOutputFiles));
    drawnow;
    this.hDebug.log(sprintf('Writing data for %s (%d/%d)',outbase,ff,numOutputFiles),'debug');
    if currSegment~=lastSegment
        fileidx = 0;
    end
    
    % set up destination file
    fsstr = '';
    if fsinbase
        if floor(this.SamplingRate/1e3)>=1
            fsstr = sprintf('-%dk',floor(this.SamplingRate/1e3));
        else
            fsstr = sprintf('-%d',this.SamplingRate);
        end
    end
    segstr = '';
    if seginbase
        segstr = sprintf('-segment%02d',this.Segment(currSegment));
    end
    if flagFileIndex
        dstfile = fullfile(outdir,sprintf('%s%s%s-%03d.blc',outbase,segstr,fsstr,fileidx));
    else
        dstfile = fullfile(outdir,sprintf('%s%s%s.blc',outbase,segstr,fsstr));
    end
    this.hDebug.log(sprintf('Destination file set to "%s"',dstfile),'debug');
    str = 'exists';
    if exist(dstfile,'file')~=2
        str = 'does not exist';
    end
    this.hDebug.log(sprintf('Destination file %s (overwrite is %d)',str,overwrite),'debug');
    if ~overwrite
        try
            assert(exist(dstfile,'file')~=2,'Output file already exists: %s',dstfile);
        catch ME
            close(hWaitbar)
            rethrow(ME)
        end
    end
    files{ff} = dstfile;
    if ~flagSave,continue;end
    
    % track how many frames we need to read total for this
    % output file (this may span multiple data segments)
    numPointsToRead = framesPerOutputFile(ff);
    numPointsRead = 0; % how many frames read
    numPointsLeftToRead = numPointsToRead; % how many frames left to read
    
    % how many data sections in this output file
    numDataSections = 1;
    
    % loop until we've read all the frames for this output file
    sections(100) = struct('nefSegment',nan,'startPoint',nan,'endPoint',nan);
    sections(1).nefSegment = this.Segment(currSegment);
    sections(1).startPoint = currDataPointInSegment;
    while numPointsRead < numPointsToRead
        
        % the number of frames to read FROM the current data
        % segment FOR the current output file
        numPointsReadFromSegment = currDataPointInSegment-1;
        numPointsLeftInSegment = this.hSource.NumDataPoints(this.Segment(currSegment)) - numPointsReadFromSegment;
        numPointsToReadFromSegment = min(numPointsLeftToRead,numPointsLeftInSegment);
        numPointsLeftToRead = numPointsLeftToRead - numPointsToReadFromSegment;
        numPointsRead = numPointsRead + numPointsToReadFromSegment;
        this.hDebug.log(sprintf('Writing %d data points from segment %d for output file "%s" (%d/%d)',numPointsToReadFromSegment,this.Segment(currSegment),outbase,ff,numOutputFiles),'info');
        
        % update segment information
        numPointsReadFromSegment = numPointsReadFromSegment + numPointsToReadFromSegment;
        lastPointInSegment = currDataPointInSegment + numPointsToReadFromSegment - 1;
        currDataPointInSegment = lastPointInSegment+1;
        if numPointsReadFromSegment >= this.hSource.NumDataPoints(this.Segment(currSegment))
            this.hDebug.log(sprintf('Rolling over to frame 1, segment %d (%d/%d)',this.Segment(currSegment),currSegment,this.hSource.NumSegments),'debug');
            
            % update end frame for the current data section
            sections(numDataSections).endPoint = lastPointInSegment;
            
            % update pointers to current segment, frame, section
            lastSegment = currSegment;
            currSegment = currSegment + 1;
            currDataPointInSegment = 1;
            
            if numPointsRead < numPointsToRead
                numDataSections = numDataSections + 1;
                
                % read current frames from current segment
                sections(numDataSections).nefSegment = this.Segment(currSegment);
                sections(numDataSections).startPoint = currDataPointInSegment;
            end
        else
            
            % avoid triggering a restart of the file index
            lastSegment = currSegment;
        end
    end
    sections((numDataSections+1):end) = [];
    sections(end).endPoint = lastPointInSegment;
    assert(numel(unique([sections.nefSegment]))==1,'No support for multiple segments coinciding in the same BLc file');
    
    % get header and channel info bytes
    basicHeaderBytes = getHeaderBytes(this,numDataSections,sections(1).nefSegment);
    channelInfoBytes = getChannelInfoBytes(this,sections(1).nefSegment);
    
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
        idxSegment = this.Segment==sections(kk).nefSegment;
        assert(nnz(idxSegment)==1,'Could not find segment %d in list of segments %s',sections(kk).nefSegment,util.vec2str(this.Segment));
        bytesPerFrame = this.BytesPerFrame(idxSegment);
        
        % compute running timestamp, frames, bytes
        pointsBeforeSegment = 0;
        if sections(kk).nefSegment>1
            pointsBeforeSegment = sum(this.hSource.NumDataPoints(1:sections(kk).nefSegment-1));
        end
        sectionTimestamp = pointsBeforeSegment + sections(kk).startPoint;
        numPointsInSection = sections(kk).endPoint - sections(kk).startPoint + 1;
        numSectionBytes = BLc.Properties.DataHeaderLength + numPointsInSection*bytesPerFrame;
        this.hDebug.log(sprintf('In data section %d of file %d/%d, writing %d frames (%d bytes)',kk,kk,numOutputFiles,numPointsInSection,numSectionBytes),'debug');
        
        % determine start datetime for this data section
        sectionDatetime = datetime(this.hSource.segments(sections(kk).nefSegment).dateStr);
        this.hDebug.log(sprintf('Section datetime set to %s',sectionDatetime),'debug');
        
        % get data segment header bytes
        dataHeaderBytes = getDataSectionHeaderBytes(this,numPointsInSection,sectionTimestamp,sectionDatetime,sections(kk).nefSegment);
        
        % write data segment header bytes to file
        try
            fwrite(fid,dataHeaderBytes,'uint8');
        catch ME
            util.closefile(dstfile);
            rethrow(ME);
        end
        this.hDebug.log(sprintf('Wrote data section header (%d bytes) to "%s"',length(dataHeaderBytes),dstfile),'debug');
        
        % get dimensions of a single frame
        try
            idxChannelsInSegment = find(ismember(this.hSource.segments(sections(kk).nefSegment).chName,this.hSource.DataChannels{sections(kk).nefSegment}));
            idxChannelsInSegment = idxChannelsInSegment(this.indexChannelToWrite{idxSegment});
            data = this.hSource.getdata(sections(kk).nefSegment, [1 1], idxChannelsInSegment);
        catch ME
            util.errorMessage(ME);
            keyboard
        end
        info = whos('data');
        bytesPerN = round(1.5*info.bytes);
        
        % read data out of the file
        if ~ispc
            maxPointsInMemory = 1e6; % no way to check mem on mac/linux
            this.hDebug.log(sprintf('On MacOS/Linux, it is not possible to check available memory'),'debug');
        else
            [~,maxPointsInMemory] = util.memcheck([1 1],2*bytesPerN,'avail',0.8);
        end
        numToRead = min(numPointsInSection,maxPointsInMemory);
        numFramesWrittenThisSection = 0;
        currStart = sections(kk).startPoint;
        try
            while numToRead>0
                
                % grab the current block of data
                this.hDebug.log(sprintf('Reading %d frames from source',numToRead),'debug');
                idxChannelsInSegment = find(ismember(this.hSource.segments(sections(kk).nefSegment).chName,this.hSource.DataChannels{this.Segment(idxSegment)}));
                idxChannelsInSegment = idxChannelsInSegment(this.indexChannelToWrite{idxSegment});
                data = this.hSource.getdata(sections(kk).nefSegment, [currStart currStart+numToRead-1], idxChannelsInSegment);
                data = data';
                numPointsRead = size(data,2);
                currStart = currStart + numPointsRead;
                globalNumFramesRead = globalNumFramesRead + numPointsRead;
                assert(~isempty(data),'Encountered end of file before expected (tried to read %d frames)',numToRead);
                waitbar(globalNumFramesRead/globalNumFramesToRead,hWaitbar);
                drawnow;
                
                % parse the data block
                data = this.MinDigitalValue + round( this.rangeDigital*(data-this.MinAnalogValue{idxSegment})/this.rangeAnalog{idxSegment} ); % convert to quantized digital units
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
                    [~,maxPointsInMemory] = util.memcheck([1 1],2*bytesPerN,'avail',0.8);
                end
                numToRead = min(maxPointsInMemory,numPointsInSection-numFramesWrittenThisSection);
            end
        catch ME
            
            % clean up before re-throwing the error
            close(hWaitbar);
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
close(hWaitbar);