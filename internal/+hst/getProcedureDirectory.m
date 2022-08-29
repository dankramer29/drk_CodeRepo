function d = getProcedureDirectory(varargin)
[varargin,proc,found_table] = util.argfn(@istable,varargin,[]);
if found_table
    pid = proc.PatientID{1};
    dt = proc.ProcedureDate(1);
    ph = proc.ProcedureType{1};
else
    [varargin,pid] = util.argfn(@hst.isValidPatient,varargin,'');
    assert(~isempty(pid),'Must provide valid patient ID');
    [varargin,dt] = util.argisa('datetime',varargin,'');
    assert(~isempty(dt),'Must provide valid procedure date');
    [varargin,ph] = util.argkeyword({'PH1','PH2'},varargin,'');
    assert(~isempty(ph),'Must provide valid procedure type');
end
util.argempty(varargin);

% identify data directory
roots = env.get('data');

% construct path
flag_found = false;
for kk=1:length(roots)
    d = fullfile(roots{kk},'source',pid,sprintf('%s-%s',datestr(dt,'yyyymmdd'),ph));
    if exist(d,'dir')==7
        flag_found = true;
        break;
    end
end
assert(flag_found,'Could not find procedure directory for patient %s, procedure date %s, procedure type %s',pid,datestr(dt),ph);