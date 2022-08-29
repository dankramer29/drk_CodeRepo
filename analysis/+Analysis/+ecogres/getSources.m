function src = getSources(varargin)
% get grid/patient information for data sources
%
% examples:
%
% get all macro grids for patient p1
% i.e., search is "pid==p1" AND "type==macro"
% >> src = getSources('pid','p1','type','macro');
%
% get all grids for p1 or p2
% i.e., search is "pid==p1" OR "pid==p2"
% >> src = getSources('pid','p1','pid','p2','andor',@or);

% construct source table
patients = keck.ecogres.defPatients;
grids = keck.ecogres.defGrids;
grid_vars = grids.Properties.VariableNames;

% process inputs
[varargin,datadir] = util.argkeyval('datadir',varargin,'C:\Users\Spencer\Documents\Data',4);
[varargin,andor] = util.argkeyval('andor',varargin,@and);
assert(ischar(datadir),'Must provide valid data directory of class char, not %s',class(datadir));
assert(exist(datadir,'dir')==7,'Data directory ''%s'' does not exist',datadir);
if ischar(andor),try andor=str2func(andor); catch ME, util.errorMessage(ME); end, end
assert(isa(andor,'function_handle'),'Must provide logical joining function as a function handle, not %s',class(andor));
assert(any(strcmpi(func2str(andor),{'and','or'})),'Logical joining function must be either @and or @or, not %s',func2str(andor));

% perform search if terms provided
if strcmpi(func2str(andor),'and')
    idx = true(size(grids,1),1);
elseif strcmpi(func2str(andor),'or')
    idx = false(size(grids,1),1);
end
search_vars = {};
search_terms = {};
for kk=1:length(grid_vars)
    [varargin,term] = util.argkeyvals(grid_vars{kk},varargin,[]);
    for nn=1:length(term)
        if isempty(term{nn}),continue;end
        search_vars = [search_vars grid_vars(kk)];
        search_terms = [search_terms term(nn)];
        if ischar(term{nn})
            idx = andor(idx,strcmpi(grids.(grid_vars{kk}),term{nn}));
        elseif isnumeric(term{nn}) && isscalar(term{nn})
            idx = andor(idx,grids.(grid_vars{kk})==term{nn});
        else
            error('Unknown variable type ''%s''',class(term{nn}));
        end
    end
end
assert(any(idx)||isempty(search_vars),'No grids match search terms %s',...
    strjoin(cellfun(@(x,y)sprintf('(%s = %s)',x,util.any2str(y)),search_vars,search_terms,'UniformOutput',false),sprintf(' %s ',upper(func2str(andor)))));
if ~any(idx),idx=true(1,size(grids,1));end
util.argempty(varargin);
src = grids(idx,:);

% create full directory path
new_patients = cell2table(cell(0,length(patients.Properties.VariableNames)),'VariableNames',patients.Properties.VariableNames);
for kk=1:size(src,1)
    idx = find(strcmpi(patients.pid,src.pid(kk)));
    assert(~isempty(idx),'Could not find patient ''%s'' for grid ''%s''',src.pid(kk),src.gid(kk));
    new_patients = cat(1,new_patients,patients(idx,:));
    new_patients.directory{kk} = fullfile(datadir,new_patients.institution{kk},new_patients.directory{kk});
end
new_patients.pid = [];
src = cat(2,src,new_patients);