function convert_to_pkg(basedir)

% make sure valid input
assert(exist(basedir,'dir')==7,'Must provide valid path to existing directory');

% make sure correct directory
dirs = struct('continuous','ct','helper','hlp','hybrid','hyb','plots','plt','pointbinned','pb','pointtimes','pt','specscope','spc','statistical_tests','stat');
olddir = fieldnames(dirs);
for kk=1:length(olddir)
    assert(exist(fullfile(basedir,olddir{kk}),'dir')==7,'Must provide valid path to directory which contains ''%s'' subdirectory',olddir{kk});
end

% get a list of all functions in chronux
fcns = getFunctionList(basedir);
fcns = strsplit(fcns,',');

% create new package-ified functions
oldfcns = cell(1,length(fcns));
newfcns = cell(1,length(fcns));
for ff=1:length(fcns)
    [~,fcnbase,fcnext]= fileparts(fcns{ff});
    stripfcn = strrep(fcns{ff},basedir,'');
    if strcmpi(stripfcn(1),filesep),stripfcn=stripfcn(2:end);end
    stripdir = strrep(stripfcn,sprintf('%s%s',fcnbase,fcnext),'');
    if isempty(stripdir),continue;end
    if strcmpi(stripdir(end),filesep),stripdir=stripdir(1:end-1);end
    
    which = cellfun(@(x)strcmpi(stripdir,x),olddir);
    assert(any(which),'Could not identify new package for ''%s''',fcns{ff});
    
    oldfcns{ff} = fcnbase;
    newfcns{ff} = sprintf('chronux.%s.%s',dirs.(stripdir),fcnbase);
end
fcns(cellfun(@isempty,oldfcns)) = [];
oldfcns(cellfun(@isempty,oldfcns)) = [];
newfcns(cellfun(@isempty,newfcns)) = [];

% replace occurences of old function with new function name
for ff=1:length(fcns)
    
    fcndir = fileparts(fcns{ff});
    tmpfile = fullfile(fcndir,sprintf('%s.m',cache.hash(fcns{ff})));
    
    % read the file contents
    [fin,errmsg] = fopen(fcns{ff},'r');
    assert(fin>=3,'Could not open file ''%s'': %s',fcns{ff},errmsg);
    [fout,errmsg] = fopen(tmpfile,'wt');
    assert(fout>=3,'Could not open file ''%s'': %s',tmpfile,errmsg);
    try
        
        % read the next line
        ln = fgetl(fin);
        idx = 1;
        while ischar(ln)
            
            % if line starts with "function", skip
            % if first non-whitespace character is "%", skip
            if ~isempty(regexpi(ln,'\s*function')) || ~isempty(regexpi(ln,'\s*%'))
                fprintf(fout,'%s\n',ln);
                ln = fgetl(fin);
                idx = idx + 1;
                continue;
            end
            
            % loop over functions and perform string replacements
            for nn=1:length(newfcns)
                strm = sprintf('\\<%s\\>',oldfcns{nn});
                if isempty(regexpi(ln,strm)),continue;end
                strr = sprintf('%s',newfcns{nn});
                ln = regexprep(ln,strm,strr);
            end
            
            % update loop variables
            fprintf(fout,'%s\n',ln);
            ln = fgetl(fin);
            idx = idx + 1;
        end
    catch ME
        fclose(fin);
        fclose(fout);
        rethrow(ME);
    end
    fclose(fin);
    fclose(fout);
    
    % replace the files
    java.io.File(fcns{ff}).renameTo(java.io.File(fullfile(env.get('temp'),sprintf('%s.m',oldfcns{ff}))));
    java.io.File(tmpfile).renameTo(java.io.File(fcns{ff}));
end


function list = getFunctionList(srcdir)

% read directory entries
entries = dir(srcdir);
discard = arrayfun(@(x)~isempty(regexpi(x.name,'^\.{1,2}$')),entries);
entries(discard) = [];

% loop over entries
list = cell(1,length(entries));
for ee=1:length(entries)
    if isdir(fullfile(srcdir,entries(ee).name))
        
        % recursively process subdirectories
        list{ee} = getFunctionList(fullfile(srcdir,entries(ee).name));
        if iscell(list{ee})
            list{ee} = strjoin(list{ee},',');
        end
    else
        
        % get the file extension (must be *.m)
        [~,~,ext] = fileparts(entries(ee).name);
        if ~strcmpi(ext,'.m'),continue;end
        
        % look for the word "function" in the file contents
        [fid,errmsg] = fopen(fullfile(srcdir,entries(ee).name),'r');
        assert(fid>=3,'Could not open file ''%s'': %s',fullfile(srcdir,entries(ee).name),errmsg);
        try
            contents = fread(fid);
            contents = char(contents(:)');
        catch ME
            fclose(fid);
            rethrow(ME);
        end
        fclose(fid);
        
        % if word function present, add to list
        if ~isempty(strfind(contents,'function'))
            list{ee} = sprintf('%s',fullfile(srcdir,entries(ee).name));
        end
    end
end

% remove empty entries
list(cellfun(@isempty,list)) = [];
list = strjoin(list,',');