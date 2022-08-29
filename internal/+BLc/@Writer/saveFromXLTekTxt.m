function files = saveFromXLTekTxt(this,varargin)
% SAVEFROMXLTEKTXT Create a BLc file from an XLTEKTXT source
%
%   FILES = SAVEFROMXLTEKTXT(THIS)
%   Use the source XLTEKTXT object to provide data and properties to create
%   one or more binary BLC files. The BLC file(s) will be created in the
%   same directory, and with the same basename (but with a zero-based
%   numbered index appended and the BLC file extension), as the source
%   file. The output file(s) may not exist (otherwise, an error will be
%   thrown). The output FILES is a cell array of the name(s) of the saved
%   file(s).
%
%   SAVEFROMXLTEKTXT(...,'NOIDX')
%   Do not include a numerical index at the end of the filename (default is
%   to include a three-digit incrementing file index).
%
%   SAVEFROMXLTEKTXT(...,'START',IDX)
%   Optionally override the starting index appended to the filename
%   (specify as an integer value, not a char).
%
%   SAVEFROMXLTEKTXT(...,'BASE',BASENAME)
%   Optionally specify a different basename for the output file.
%
%   SAVEFROMXLTEKTXT(...,'DIR',OUTPUTDIR)
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
util.argempty(varargin);
assert(exist(outdir,'dir')==7,'Output directory "%s" does not exist',outdir);
this.hDebug.log(sprintf('Overwrite set to %d',overwrite),'debug');
this.hDebug.log(sprintf('Basename set to "%s"',outbase),'debug');
this.hDebug.log(sprintf('Output directory set to "%s"',outdir),'debug');

% validate input XLTekTxt object
assert(~isempty(regexpi(class(this.hSource),'XLTekTxt')),'Must provide a valid object of class "XLTekTxt", not "%s"',class(this.hSource));
[~,bytesPerN] = this.hSource.calculateMaxFrames('availutil',0.8,'multiplier',1.5,'data','channels',this.indexChannelToWrite);

% compute number of output files and time in each
%[framesPerFile,numFiles] = this.getFramesPerFile(this.hSource.SamplingRate,this.hSource.NumDataPoints);
framesPerFile = this.hSource.NumDataPoints;
numFiles = 1;

% process each output file
sectionstartPoints = this.hSource.SectionStart;
sectionendPoints = this.hSource.SectionStart + this.hSource.SectionLength - 1;
currFrame = sectionstartPoints(1);
this.hSource.reset;
hWaitbar = waitbar(0/this.hSource.SourceFileSize,sprintf('Writing data to %s (%d/%d)',outbase,1,numFiles));
hWaitbarTitle = get(get(findobj(hWaitbar,'Type','figure'),'currentaxes'),'title');
set(hWaitbarTitle,'interpreter','none'); % no special interpretation of text
drawnow;
files = cell(1,numFiles);
for ff=1:numFiles
    set(hWaitbarTitle,'String',sprintf('Processing %s (%d/%d)',outbase,ff,numFiles));
    drawnow;
    this.hDebug.log(sprintf('Writing data for %s (%d/%d)',outbase,ff,numFiles),'debug');
    
    % identify the first data section
    sectionStart = find(currFrame>=sectionstartPoints & sectionendPoints>=currFrame,1,'first');
    if isempty(sectionStart)
        
        % if no data section contains the current sample, most
        % likely scenario is that the current sample is between
        % sections, so look for the section after the current
        % sample, and update current numFramesWritten to first
        % sample in that section
        sectionStart = find(sectionstartPoints>=currFrame,1,'first');
        assert(~isempty(sectionStart),'Could not identify the next data section after %d',currFrame);
        this.hDebug.log(sprintf('No data section contained current frame %d, so updated to start of section %d: %d',...
            currFrame,sectionStart,sectionstartPoints(sectionStart)),'debug');
        currFrame = sectionstartPoints(sectionStart);
    end
    assert(~isempty(sectionStart),'Could not identify starting data section for %d',currFrame);
    
    % identify the last data section
    frameEnd = currFrame + framesPerFile(ff) - 1;
    sectionEnd = find(frameEnd>=sectionstartPoints & sectionendPoints>=frameEnd,1,'first');
    if isempty(sectionEnd)
        
        % if no data section contains the end numFramesWritten,
        % most likely scenario is that the end numFramesWritten
        % is between sections, so look for the section before
        % the end numFramesWritten, and update end
        % numFramesWritten to last point in that section
        sectionEnd = find(frameEnd>=sectionstartPoints,1,'last');
        assert(~isempty(sectionEnd),'Could not identify the section following end point %d',frameEnd);
        this.hDebug.log(sprintf('No data section contained last frame %d of current file, so updated to end of section %d: %d',...
            frameEnd,sectionEnd,sectionendPoints(sectionEnd)),'debug');
        frameEnd = sectionendPoints(sectionEnd);
    end
    assert(~isempty(sectionEnd),'Could not identify ending data section for %d',frameEnd);
    assert(frameEnd>currFrame,'The end numFramesWritten %d must be greater than the start numFramesWritten %d',frameEnd,currFrame);
    dataSections = sectionStart:sectionEnd;
    numDataSections = length(dataSections);
    this.hDebug.log(sprintf('Current file will have %d data sections (sections %s from source)',numDataSections,util.vec2str(dataSections)),'debug');
    
    % set up destination file
    fsstr = '';
    if fsinbase
        if floor(this.SamplingRate/1e3)>=1
            fsstr = sprintf('-%dk',floor(this.SamplingRate/1e3));
        else
            fsstr = sprintf('-%d',this.SamplingRate);
        end
    end
    if flagFileIndex
        dstfile = fullfile(outdir,sprintf('%s%s-%03d.blc',outbase,fsstr,fileidx));
    else
        dstfile = fullfile(outdir,sprintf('%s%s.blc',outbase,fsstr));
    end
    this.hDebug.log(sprintf('Destination file set to "%s"',dstfile),'debug');
    str = 'does not exist';
    if exist(dstfile,'file')==2
        str = 'exists';
    end
    this.hDebug.log(sprintf('Destination file %s (overwrite is %d)',str,overwrite),'debug');
    if ~overwrite
        assert(exist(dstfile,'file')~=2,'Output file already exists: %s',dstfile);
    end
    files{ff} = dstfile;
    if ~flagSave,continue;end
    
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
        sectionTimestamp = currFrame;
        assert(sectionTimestamp>=sectionstartPoints(dataSections(kk)) && sectionTimestamp<sectionendPoints(dataSections(kk)),...
            'Section timestamp %d must be included in the section timestamp range [%d %d]',...
            sectionTimestamp,sectionstartPoints(dataSections(kk)),sectionendPoints(dataSections(kk)));
        numFramesInSection = min(framesPerFile(ff)-numFramesWritten,sectionendPoints(dataSections(kk)) - currFrame + 1);
        
        % determine start datetime for this data section
        sectionDatetime = this.hSource.SectionStartDatetime(dataSections(kk)) + ...
            seconds((sectionTimestamp-sectionstartPoints(dataSections(kk)))/this.hSource.SamplingRate);
        this.hDebug.log(sprintf('Section datetime set to %s',sectionDatetime),'debug');
        
        % get data packet header bytes
        [dataHeaderBytes,numSectionBytes] = getDataSectionHeaderBytes(this,numFramesInSection,sectionTimestamp,sectionDatetime);
        this.hDebug.log(sprintf('In data section %d of file %d/%d, writing %d frames (%d bytes)',kk,ff,numFiles,numFramesInSection,numSectionBytes),'debug');
        
        % write data packet header bytes to file
        try
            fwrite(fid,dataHeaderBytes,'uint8');
        catch ME
            util.closefile(dstfile);
            rethrow(ME);
        end
        this.hDebug.log(sprintf('Wrote data section header (%d bytes) to "%s"',length(dataHeaderBytes),dstfile),'debug');
        
        % read data out of the file
        maxFramesInMemory = this.hSource.calculateMaxFrames('availutil',0.8,'bytesperframe',bytesPerN,'multiplier',1.5,'data','channels',this.indexChannelToWrite);
        numToRead = min(numFramesInSection,maxFramesInMemory);
        numFramesWrittenThisSection = 0;
        try
            while numToRead>0
                
                % grab the current block of data
                this.hDebug.log(sprintf('Reading %d frames from source',numToRead),'debug');
                [ln,pos] = blockread(this.hSource,numToRead,'channels',this.indexChannelToWrite);
                numFramesRead = size(ln{3},1);
                assert(~isempty(ln),'Encountered end of file before expected (tried to read %d frames)',numToRead);
                waitbar(pos/this.hSource.SourceFileSize,hWaitbar);
                drawnow;
                
                % parse the data block
                assert(max(diff(ln{2}))==1,'Attempted to write noncontiguous data within a data section');
                data = ln{3}(:,this.indexChannelToWrite); % pull out sampled data, subselect channels to be written to disk
                clear ln;
                if ~this.hSource.FlagRemoveDCOffset
                    mn = this.hSource.ChannelAverage(this.indexChannelToWrite);
                    data = data - repmat(mn(:)',size(data,1),1); % subtract global channel average
                end
                data = this.MinDigitalValue + round( this.rangeDigital*(data-this.MinAnalogValue)/this.rangeAnalog ); % convert to quantized digital units
                data = data'; % transpose to channels x samples
                switch this.BitResolution
                    case 16, data = cast(data,'int16'); % convert to int16
                    case 32, data = cast(data,'int32'); % convert to int32
                    otherwise, error('Unknown bit resolution "%d"',this.BitResolution);
                end
                data = typecast(data(:),'uint8'); % get byte-level representation
                
                % write data to binary file
                fwrite(fid,data,'uint8');
                
                % update count of written numFramesWrittens
                numFramesWrittenThisSection = numFramesWrittenThisSection + numFramesRead;
                this.hDebug.log(sprintf('Wrote %d frames (%d bytes) (%d frames total in section %d)',...
                    numFramesRead,length(data),numFramesWrittenThisSection,kk),'debug');
                clear data;
                
                % read next block
                maxFramesInMemory = this.hSource.calculateMaxFrames('availutil',0.8,'bytesperframe',bytesPerN,'multiplier',1.5,'data','channels',this.indexChannelToWrite);
                numToRead = min(numFramesInSection-numFramesWrittenThisSection,maxFramesInMemory);
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
        currFrame = currFrame + numFramesWrittenThisSection;
        if currFrame>sectionendPoints(dataSections(kk)) && dataSections(kk)<length(this.hSource.SectionStart)
            currFrame = sectionstartPoints(dataSections(kk)+1);
        end
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