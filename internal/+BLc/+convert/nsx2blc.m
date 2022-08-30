function [exitCode,files] = nsx2blc(varargin)
exitCode = 0;
nsext = {'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'};

% process inputs
[varargin,flag_filename_only] = util.argflag('filenames',varargin,false);
[varargin,flag_idx_in_base] = util.argflag('idxinbase',varargin,false);
[varargin,flag_fs_in_base] = util.argflag('fsinbase',varargin,false);
[varargin,flag_behavioral] = util.argflag('behavioral',varargin,false);
[varargin,chlist,~,found_chlist] = util.argkeyval('channels',varargin,nan);
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,{});
[varargin,outdir,~,found_outdir] = util.argkeyval('outdir',varargin,{});
[varargin,outbase] = util.argkeyval('outbase',varargin,{});
[varargin,srcdir,~,found_srcdir] = util.argkeyval('srcdir',varargin,{});
[varargin,srcfile,~,found_srcfile] = util.argkeyval('srcfile',varargin,{});
[varargin,mapfile,~,found_mapfile] = util.argkeyval('mapfile',varargin,{});
[varargin,map,found_map] = util.argisa('GridMap.Interface',varargin,{});
[varargin,max_quantization_error] = util.argkeyval('maxquantizationerror',varargin,0.5);
util.argempty(varargin);

% set up args for save method below
args = {};
if flag_fs_in_base,args=[args {'fsinbase'}];end
if flag_overwrite,args=[args {'overwrite'}];end
if ~flag_idx_in_base,args=[args {'noidx'}];end

% make sure we have a debugger
if ~found_debug
    debug = Debug.Debugger('nsx2blc');
end

% process map input
if ~found_map && found_mapfile
    map = GridMap.Interface(mapfile);
end
found_map = ~isempty(map);

% collect list of files to process
if found_srcdir && ~found_srcfile
    
    % collect all NSX files from the potential multiple directories
    srcdir = util.ascell(srcdir);
    srcfile = cell(1,length(srcdir));
    for kk=1:length(srcdir)
        srcfile{kk} = cellfun(@(x)dir(fullfile(srcdir{kk},sprintf('*%s',x))),nsext,'UniformOutput',false);
        srcfile{kk} = cat(1,srcfile{kk}{:});
        srcfile{kk} = arrayfun(@(x)fullfile(srcdir{kk},x.name),srcfile{kk},'UniformOutput',false);
    end
    srcfile = cat(1,srcfile{:});
elseif ~found_srcdir && found_srcfile
    
    % make sure it's in a cell
    srcfile = util.ascell(srcfile);
end
assert(~isempty(srcfile),'No files found');
assert(all(cellfun(@(x)exist(x,'file')==2,srcfile)),'All input files must be full paths to existing files');

% loop over each file
files = cell(1,length(srcfile));
for kk=1:length(srcfile)
    
    % look for map file
    if ~found_map
        [pathname,basename] = fileparts(srcfile{kk});
        mapfile = fullfile(pathname,sprintf('%s.map',basename));
        if exist(mapfile,'file')==2
            map = GridMap.Interface(mapfile);
        end
    end
    assert(~isempty(map)&&isa(map,'GridMap.Interface'),'Could not find map file for "%s"',srcfile{kk});
    
    % construct objects and convert
    nsx = Blackrock.NSx(srcfile{kk},debug);
    if ~found_chlist
        if flag_behavioral
            chlist = map.BehavInfo.AmplifierChannel(:)';
        else
            chlist = map.ChannelInfo.AmplifierChannel(:)';
        end
    end
    if ~found_outdir
        outdir = nsx.SourceDirectory;
    end
    
    if flag_filename_only
        blcw = BLc.Writer(nsx,debug,'channels',chlist,'secondsperoutputfile',inf,'nosafetychecks');
        files{kk} = blcw.getOutputFilenames('dir',outdir,'base',outbase,args{:});
        continue;
    else
        blcw = BLc.Writer(nsx,debug,'channels',chlist,'secondsperoutputfile',inf,'maxquantizationerror',max_quantization_error);
        files{kk} = blcw.save('dir',outdir,'base',outbase,args{:});
        cellfun(@(x)assert(exist(x,'file')==2,'Could not find new BLc file "%s"',x),files{kk});
    end
    
    % do a quick sanity check
    for mm=1:length(files{kk})
        blc = BLc.Reader(files{kk}{mm},debug);
        currNSxPacket = 0;
        for nn=1:length(blc.DataInfo)
            newNSxPacket = currNSxPacket + find(nsx.PointsPerDataPacket((currNSxPacket+1):end)==blc.DataInfo(nn).NumRecords,1,'first');
            assert(~isempty(newNSxPacket),'Could not find NSx data packet to match BLC packet %d (%d records)',nn,blc.DataInfo(nn).NumRecords);
            currNSxPacket = newNSxPacket;
            dt_nsx = nsx.read('packet',currNSxPacket,'reference','packet','points',[1 min(1000,nsx.PointsPerDataPacket(currNSxPacket))],'channels',chlist);
            dt_blc = blc.read('section',nn,'context','section','points',[1 min(1000,blc.DataInfo(nn).NumRecords)]);
            mean_sample_sqerr_uV = arrayfun(@(x)1e6*sum((dt_blc(:,x)-dt_nsx(x,:)').^2)/size(dt_blc,1),1:size(dt_blc,2));
            if ~isequal(dt_nsx,dt_blc')
                debug.log(sprintf('NSx and BLc data are not exactly equal (mean sample squared error is %.2f ± %.2f uV)',mean(mean_sample_sqerr_uV),std(mean_sample_sqerr_uV)),'warn');
            end
            if any(mean_sample_sqerr_uV > max_quantization_error)
                idx_bad_channels = find(mean_sample_sqerr_uV>max_quantization_error);
                for ii=1:length(idx_bad_channels)
                    ch = idx_bad_channels(ii);
                    
                    % prompt user for action
                    [~,fbase] = fileparts(files{kk}{mm});
                    h = util.UserPrompt(...
                        'option','View+Keyboard','option','Ignore','option','Cancel',...
                        'default','Ignore');
                    response = h.prompt(...
                        'title',sprintf('%s',fbase),...
                        'question',sprintf('Ch. %d: BLc data not equal to original NSx data (%.2f uV mean squared sample error). Ignore, Cancel, or Keyboard?',ch,mean_sample_sqerr_uV(ch)));
                    switch lower(response)
                        case 'view+keyboard'
                            
                            % data are very different: plot the data and give user some
                            % options about how to proceed
                            fig = figure;
                            ax(1) = subplot(211);
                            plot(dt_nsx(ch,:)');
                            hold on
                            plot(dt_blc(:,ch));
                            ylabel('amplitude (uV)');
                            legend({'NSx','BLc'});
                            title('Sample data read from NSx vs. BLc files');
                            ax(2) = subplot(212);
                            plot((dt_blc(:,ch)-dt_nsx(ch,:)').^2);
                            ylabel('difference (uV^2)')
                            title('Squared difference between NSx and BLc data');
                            xlabel('samples');
                            linkaxes(ax,'x');
                            
                            % drop into keyboard
                            fprintf('Press F5 to continue.\n');
                            keyboard;
                            
                            % close the figure
                            if ~isempty(fig) && isvalid(fig)
                                close(fig);
                            end
                        case 'ignore'
                            % continue on
                        case 'cancel'
                            assert(mean_sample_sqerr_uV<=max_quantization_error,'Data from section %d, "%s" does not match the source NSx file (mean sample squared error %.2f uV is greater than allowable quantization error %.2f uV)',nn,files{kk}{mm},mean_sample_sqerr_uV,max_quantization_error);
                        otherwise
                            error('Unknown response "%s"',response);
                    end
                end
            end
        end
        blc.delete;
    end
end
files = cat(2,files{:});