function [sessions,patient,root,allsessions] = getSessionList(varargin)
% HST.GETSESSIONLIST find valid sessions
%
%   SESSIONS = HST.GETSESSIONLIST(PID)
%   Returns a list of all valid study session folder names for the patient
%   specified by PID.
%
%   SESSIONS = HST.GETSESSIONLIST(...,SESSION1,SESSION2)
%   Search for all session folders between SESSION1 and SESSION2 
%   (inclusive).  Assumes session folders are named according to date, 
%   i.e. YYYYMMDD.
%
%   SESSIONS = HST.GETSESSIONLIST(...,PATHSTR)
%   Overrides the HST environment variable DATA with the value in PATHSTR
%   (parent directory containing session data folders).  Any input 
%   containing the MATLAB FILESEP character will be used to replace the map
%   directory path.
%
%   [SESSIONS,PID,ROOT,ALLSESSIONS] = HST.GETSESSIONLIST(...)
%   Additionally return the patient ID in PID, the root path(s) used in
%   ROOT, and the full list of sessions in ALLSESSIONS.
%
%   See also HST.GETSESSIONPATH, HST.ISVALIDPATIENT, FILESEP.

% process inputs
[varargin,root] = util.argkeyval('DataDirectory',varargin,env.get('data'),4);
[varargin,patient,found] = util.argfn(@(x)ischar(x)&&hst.isValidPatient(x),varargin,'');
assert(found,'Must provide a valid patient');
patient = upper(patient);
[varargin,flag_uniform_output] = util.argkeyval('UniformOutput',varargin,true);

% single date (1 arg), or start/end dates (2 args)
daterange = {};
if length(varargin)==1
    daterange = varargin(1);
elseif length(varargin)==2
    daterange = varargin(1:2);
end
if ~isempty(daterange)
    assert(all(~cellfun(@isempty,regexp(daterange,'^\d{8}','ONCE'))),'Invalid session folder names');
end

% pull out all available sessions
allsessions = cell(1,length(root));
dIdx = 1;
keepRoot = false(1,length(root));
for kk=1:length(root)
    
    % must be directory
    flist = dir( fullfile( root{kk},'source',patient ) );
    flist( ~[flist.isdir] ) = [];
    
    % not the . or .. entries
    dotname = arrayfun(@(x)strncmpi(x.name,'.',1),flist);
    flist( dotname ) = [];
    
    % match the standard YYYYMMDD directory naming convention
    yyyymmdd = arrayfun(@(x)~isempty(regexp(x.name,'^\d{8}', 'once')),flist);
    flist( ~yyyymmdd ) = [];
    if ~isempty(flist)
        keepRoot(kk) = true;
        root{kk} = fullfile(root{kk},'source',patient);
    end
    
    % add all to cell array
    allsessions{dIdx} = {flist.name};
    dIdx = dIdx + 1;
end
allsessions = cat(2,allsessions{:});
allsessions = sort(allsessions);
root(~keepRoot) = [];

% convert all date strings into datenums
listDates = cellfun(@(x)datenum(x,'yyyymmdd'),allsessions);

% all dates, one date, or a range of dates
dIdx = 1:length(allsessions);
if length(daterange)==1
    requestedDate = datenum(daterange{1},'yyyymmdd');
    dIdx = find(listDates==requestedDate);
    if length(dIdx)>1
        warning('Multiple matches for session ''%s''',daterange{1});
        dIdx = dIdx(1);
    end
    assert(~isempty(dIdx)&&length(dIdx)==1,'Could not identify any matching sessions');
elseif length(daterange)==2
    dateStart = datenum(daterange{1},'yyyymmdd');
    dateEnd = datenum(daterange{2},'yyyymmdd');
    st = find(listDates>=dateStart,1,'first');
    lt = find(listDates<=dateEnd,1,'last');
    dIdx = st:lt;
    assert(~isempty(dIdx),'Could not identify any matching sessions');
end

% construct output
sessions = allsessions(dIdx);

% convert from cell to char if only one session
if flag_uniform_output
    if length(sessions)==1, sessions = sessions{1}; end
end