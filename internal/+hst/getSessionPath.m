function [pathstr,pid,session] = getSessionPath(varargin)
% HST.GETSESSIONPATH get the full path to a session data directory
%
%   PATHSTR = HST.GETSESSIONPATH(SESSION,PID)
%   Look for session ('YYYYMMDD') for the patient identified by valid
%   patient ID in PID. Checks PID against HST.ISVALIDPATIENT to determine
%   whether it's a valid patient ID.
%
%   See also HST.ISVALIDPATIENT, FILESEP.
pathstr = '';

% get the data directories
[varargin,pid] = util.argfn(@hst.isValidPatient,varargin,'');
assert(hst.isValidPatient(pid),'Must provide a valid patient, not ''%s''',pid);

% session string
assert(~isempty(varargin),'Must provide a session-identifying string');
session = varargin{1};
varargin(1) = [];
util.argempty(varargin);
assert(ischar(session),'Must provide a valid session string, not a ''%s''',class(session));

% get list of procedures
procedures = hst.getProcedures(pid);

% look for the session directory (return the first match only if multiple)
flag_found = false;
for kk=1:size(procedures,1)
    procdir = hst.getProcedureDirectory(procedures(kk,:));
    pathstr = fullfile(procdir,session);
    if exist(pathstr,'dir')==7
        flag_found = true;
        break;
    end
end
assert(flag_found,'Could not find path to session "%s"',session);