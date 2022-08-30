function dates = getSessionDates(varargin)
[varargin,pid] = util.argfn(@hst.isValidPatient,varargin,'');
assert(~isempty(pid),'Must provide value patient ID');

% get list of procedures for this patient ID
procedures = hst.getProcedures(pid);
dates = cell(1,size(procedures,1));
for pp=1:size(procedures,1)
    procedure_path = hst.getProcedureDirectory(procedures(pp,:));
    list = dir(procedure_path);
    list(cellfun(@isempty,regexpi({list.name},'^\d{8}$'))) = [];
    dates{pp} = {list.name};
end
dates = cat(2,dates{:});

% subselect requested date range
if length(varargin)==1
    if isa(varargin{1},'datetime')
        varargin{1} = datestr(varargin{1},'yyyymmdd');
    end
    idx = strcmpi(dates,varargin{1});
    assert(nnz(idx)==1,'Could not find requested date "%s"',varargin{1});
    dates = datetime(dates{idx},'InputFormat','yyyyMMdd');
elseif length(varargin)==2
    dn = cellfun(@(x)datenum(x,'yyyymmdd'),dates,'UniformOutput',false);
    dn = cat(2,dn{:});
    if isa(varargin{1},'datetime')
        varargin{1} = datestr(varargin{1},'yyyymmdd');
    end
    if isa(varargin{2},'datetime')
        varargin{2} = datestr(varargin{2},'yyyymmdd');
    end
    ud1 = datenum(varargin{1},'yyyymmdd');
    ud2 = datenum(varargin{2},'yyyymmdd');
    idx = dn>=ud1 & dn<=ud2;
    dates = arrayfun(@(x)datetime(x,'ConvertFrom','datenum'),dn(idx),'UniformOutput',false);
    dates = cat(2,dates{:});
end
dates = arrayfun(@(x)datestr(x,'yyyymmdd'),dates,'UniformOutput',false);