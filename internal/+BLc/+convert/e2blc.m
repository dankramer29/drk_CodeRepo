function exitCode = e2blc(varargin)
exitCode = 0; % success
args = {};

% process user inputs
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
if flag_overwrite,args=[args {'overwrite'}];end
[varargin,chlist,~,found_chlist] = util.argkeyval('channels',varargin,nan);
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
[varargin,dirnames,found_dir] = util.argfns(@(x)ischar(x)&&exist(x,'dir')==7,varargin,[]);
[varargin,filenames,found_files] = util.argfns(@(x)ischar(x)&&exist(x,'file')==2&&strcmpi(x(end),'e'),varargin,{});
[varargin,mapfile,found_mapfile] = util.argfn(@(x)exist(x,'file')==2&&(strcmpi(x(end-2:end),'map')||strcmpi(x(end-2:end),'csv')),varargin,{});
[varargin,mapobj,found_map] = util.argisa('GridMap.Interface',varargin,{});
util.argempty(varargin);

% make sure we have a debugger
if ~found_debug
    debug = Debug.Debugger('e2blc');
end

% process map input
if found_map && ~found_mapfile
    map = util.ascell(mapobj);
elseif ~found_map && found_mapfile
    map = {GridMap.Interface(mapfile)};
    found_map = true;
end

% collect list of files to process
if found_dir && ~found_files
    
    % collect all *.e files from the potential multiple directories
    dirnames = util.ascell(dirnames);
    filenames = cell(1,length(dirnames));
    for kk=1:length(dirnames)
        filenames{kk} = dir(fullfile(dirnames{kk},'*.e'));
        filenames{kk} = arrayfun(@(x)fullfile(dirnames{kk},x.name),filenames{kk},'UniformOutput',false);
    end
    filenames = cat(1,filenames{:});
elseif ~found_dir && found_files
    
    % make sure it's in a cell
    filenames = util.ascell(filenames);
end
assert(~isempty(filenames),'No files found');
assert(all(cellfun(@(x)exist(x,'file')==2,filenames)),'All input files must be full paths to existing files');

% loop over each file
flag_no_map = ~found_map;
for kk=1:length(filenames)
    efile = filenames{kk};
    [edir,ebase] = fileparts(efile);
    assert(exist(efile,'file')==2,'Could not find the data file "%s"',efile);
    
    % look for map file
    if flag_no_map
        files = dir(fullfile(edir,sprintf('%s*.map',ebase)));
        map = cell(1,length(files));
        for nn=1:length(files)
            map{nn} = GridMap.Interface(fullfile(files(nn).folder,files(nn).name));
        end
    end
    assert(~isempty(map)&&all(cellfun(@(x)isa(x,'GridMap.Interface'),map)),'Could not find any map files for "%s"',filenames{kk});
    if ~found_chlist
        chlist = cellfun(@(x)x.ChannelInfo.Channel,map,'UniformOutput',false);
    end
    assert(length(map)==length(chlist),'Must have same number of map entries as channel entries');
    
    % create NicoletEFile object (preprocess Nicolet file)
    try
        debug.log(sprintf('Opening Nicolet file "%s"',efile),'info');
        nef = Natus.NicoletEFile(efile);
        debug.log('Finished loading Nicolet file','info');
    catch ME
        util.errorMessage(ME);
        fprintf('Error encountered (see output above). Please resolve, then press F5 to continue.\n');
        keyboard
    end
    assert(length(map)==length(nef.segments),'Must have same number of map entries as segments in the *.e file');
    
    % create blc files
    try
        blcw = BLc.Writer(nef,map,debug,'channels',chlist,'SecondsPerOutputFile',inf);
        files = blcw.save('dir',edir,'base',ebase,'start',0,'noidx',args{:});
        for nn=1:length(files)
            assert(exist(files{nn},'file')==2,'Could not find new BLc file "%s"',files{nn});
        end
        debug.log(sprintf('Finished saving %d BLC file(s)',length(files)),'info');
    catch ME
        util.errorMessage(ME);
        fprintf('Error encountered (see output above). Please resolve, then press F5 to continue.\n');
        keyboard
    end
    
    % remove map object if needed
    if flag_no_map,cellfun(@delete,map);map=[];end
    
    % cleanup the writer and e objects
    delete(nef);
    delete(blcw);
end
end % END function e2blx