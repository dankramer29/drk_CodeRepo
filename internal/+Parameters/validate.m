function prm = validate(params,mfile,prmname,ignore)
if nargin<3||isempty(prmname),prmname='params';end
if nargin<4||isempty(ignore),ignore={};end

% make sure params object is correct class
if ~isstruct(params)
    assert(isa(params,'Parameters.Interface'),'Invalid parameters object');
end

% read text file to search for all instances of PRMNAME
assert(exist(mfile,'file')==2,'Cannot find mfile ''%s''',mfile);
[fid,errmsg] = fopen(sprintf('%s.m',mfile),'r');
assert(fid>=0,'Could not open file ''%s'': %s',mfile,errmsg);

% read text from the file
try
    lines = cell(1,1024);
    idx = 1;
    lines{idx} = fgetl(fid);
    while ischar(lines{idx})
        idx = idx+1;
        lines{idx} = fgetl(fid);
    end
    lines = strjoin(lines(1:idx-1));
catch ME
    util.errorMessage(ME);
end
assert(~isempty(lines),'Could not read ''%s''',mfile);

% close the text file
fclose(fid);

% get all instances of the parameter object being referenced
prm = regexp(lines,['[^\.]\<' prmname '\>\.(?<topic>[\w\d]+)\.(?<property>[\w\d]+)'],'names');
prm = arrayfun(@(x)sprintf('%s.%s',x.topic,x.property),prm,'UniformOutput',false);
prm = unique(prm);

% remove ignore properties
prm(ismember(prm,ignore)) = [];

% verify each is available %--and not empty--%
for kk=1:length(prm)
    parts = strsplit(prm{kk},'.');
    if isa(params,'Parameters.Interface')
        assert(params.check(parts{1}),'Topic ''%s'' unavailable',parts{1});
        assert(params.check(prm{kk}),'Property ''%s'' unavailable under topic ''%s''',parts{2},parts{1});
        %assert(~isempty(params.(parts{1}).(parts{2})),'Must set a value for parameter ''%s''',prm{kk});
    elseif isstruct(params)
        assert(isfield(params,parts{1}),'Topic ''%s'' unavailable',parts{1});
        assert(isfield(params.(parts{1}),parts{2}),'Property ''%s'' unavailable under topic ''%s''',parts{2},parts{1});
    end
end