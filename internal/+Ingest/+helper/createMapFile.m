function exitCode = createMapFile(varargin)
exitCode = 0; % success

% process inputs
[varargin,maptable] = util.argkeyval('maptable',varargin,{},4);
[varargin,outdir] = util.argkeyval('outdir',varargin,'.',3);
assert(~isempty(outdir)&&exist(outdir,'dir')==7,'Must provide valid recording directory');
[varargin,mapfile] = util.argkeyval('mapfile',varargin,fullfile(outdir,'mapfile.csv'),4);
util.argempty(varargin);
assert(all(ismember({'GridID','Location','Hemisphere','Template','Label','Channel'},maptable.Properties.VariableNames)),'Invalid map table');

% check whether mapfile already exists
if exist(mapfile,'file')==2
    
    % file exists: check whether it contains the same, or
    % different information than we would be writing to it
    tmptable = readtable(mapfile);
    if isequal(tmptable,maptable)
        return; % no need to write anything - they're the same already
    else
        
        % file exists and tables are different: query user on
        % how to proceed
        info = dir(mapfile);
        bytestr = util.bytestr(info.bytes);
        queststr = sprintf('Map file already exists (%s)! Use existing, overwrite, or cancel?',bytestr);
        response = questdlg(queststr,'Map File Exists','Existing','Overwrite','Cancel','Overwrite');
        switch lower(response)
            case 'existing'
                
                % recover: use the existing map file and move on
                return;
            case 'overwrite'
                true;
            case 'cancel'
                
                % cancel: return
                exitCode = -1;
                return;
            otherwise
                error('bad code somewhere - no option for "%s"',response);
        end
    end
end

% write the map file
util.mkdir(outdir);
mapfile = fullfile(outdir,sprintf('%s.map',mapfile));
fid = util.openfile(mapfile,'wt');
try
    fprintf(fid,'%s\n',strjoin(maptable.Properties.VariableNames,','));
    for kk=1:size(maptable,1)
        fprintf(fid,'%d,%s,%s,%s,%s,%d:%d\n',maptable.GridID(kk),maptable.Template{kk},maptable.Location{kk},maptable.Hemisphere{kk},maptable.Label{kk},maptable.Channel{kk}(1),maptable.Channel{kk}(end));
    end
catch ME
    util.closefile(fid);
    rethrow(ME);
end
util.closefile(fid);