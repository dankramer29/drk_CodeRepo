function master = getMaster(varargin)
% GETMASTER Get master list of identifiable patient information

% find the master file
masterfile = 'master.xlsx';
masterdir = util.ascell(env.get('data'));
exists = cellfun(@(x)exist(fullfile(x,masterfile),'file')==2,masterdir);
assert(any(exists),'Could not find master excel file "%s" in any of the data folders %s',masterfile,strjoin(masterdir));
assert(nnz(exists)==1,'There should only be one master excel file "%s" (found copies in %s)',masterfile,strjoin(masterdir(exists)));
masterdir = masterdir{exists};

% read patient list from master excel file
excel = actxserver('excel.application');

% get the master password from the user
prompt = {'Enter master password:'};
name = 'Master Authorization';
defaultans = {''};
password = util.inputdlg(prompt,name,[1 50],defaultans);

try
    
    % get access to resources
    workbook = excel.Workbooks.Open(fullfile(masterdir,masterfile), [], true, [], password{1});
    sheets = get(workbook,'sheets');
    sheet = get(sheets,'Item',1);
    cells = get(sheet,'Cells');
    
    % determine size of range containing data
    lastRow = sheet.Range('A1').End('xlDown').Row;
    lastCol = sheet.Range('A1').End('xlToRight').Column;
    
    % read information
    vars = cells.Range(sprintf('A1:%s1',uint8('A')+lastCol-1)).Value;
    master = cell(lastRow,3);
    idx = 1;
    for vv=1:length(vars)
        if any(strcmpi(vars{vv},{'PatientID','LastName','FirstName','BirthDate','Gender','MedicalRecordNumber'}))
            col = uint8('A')+vv-1;
            master(:,idx) = cells.Range(sprintf('%s1:%s%d',col,col,lastRow)).Value;
            if strcmpi(vars{vv},'Birthdate')
                dates = 1 + find(cellfun(@ischar,master(2:end,idx)));
                master(dates,idx) = cellfun(@(x)datetime(x,'InputFormat','M/d/uuuu'),master(dates,idx),'UniformOutput',false);
            end
            idx = idx + 1;
        end
    end
    master = cell2table(master(2:end,:),'VariableNames',master(1,:));
catch ME
    Quit(excel);
    delete(excel);
    rethrow(ME);
end

% clean up
Quit(excel);
delete(excel);