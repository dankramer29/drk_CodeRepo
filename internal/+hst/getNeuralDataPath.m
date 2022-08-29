function [pathstr,nsp] = getNeuralDataPath(varargin)
% GETNEURALDATAPATH Retrieve path to neural data folder
%
%   [PATHSTR,NSP] = GETNEURALDATAPATH(SESSION,PATIENT,NSPS)
%   Determine the neural data folder PATHSTR for the data set named NSP. 
%   Will use SESSION and PATIENT to identify the parent session folder.
%
%   The following example searches for a neural data folder named either
%   NSP1 or ALLGRIDS in the session folder for patient P010, session date
%   20170830.
%
%     Example:
%     >> [pth,nsp] = getNeuralDataPath('p010','20170830',{'NSP1','ALLGRIDS'})
%
%   SEE ALSO HST.GETSESSIONPATH, HST.ISVALIDPATIENT.

% default empty
pathstr = '';
nsp = '';

% get subject
[varargin,patient] = util.argfn(@hst.isValidPatient,varargin,nan);
assert(ischar(patient),'Must provide char patient, not "%s"',class(patient));
assert(hst.isValidPatient(patient),'Must provide a valid patient ID, not "%s"',patient);

% find session
[varargin,session] = util.argfn(@(x)ischar(x)&&length(x)==8&&regexpi(x,'^\d{8}$'),varargin,'');
assert(ischar(session),'Must provide char session, not "%s"',class(session));
assert(~isempty(session),'Must provide a valid session ID');

% find arrays
nsps = varargin;
assert(~isempty(nsps),'Must provide NSP names');
if ~iscell(nsps),nsps={nsps};end
assert(all(cellfun(@(x)ischar(x))),'Must provide char NSP names');

% get session path
sessionpath = hst.getSessionPath(patient,session);
assert(~isempty(sessionpath)&&exist(sessionpath,'dir')==7,'Invalid session ''%s'' for subject ''%s''',session,patient);

% look for folders with NSP names
which = cellfun(@(x)exist(fullfile(sessionpath,x),'dir')==7,nsps);
if nnz(which)==0,return;end
pathstr = cellfun(@(x)fullfile(sessionpath,x),arrays(which),'UniformOutput',false);
nsp = nsps(which);

% make sure only one match (never want to return a cell array)
assert(length(pathstr)<=1,'Multiple NSP matches not supported');

% return path
pathstr = pathstr{1};
nsp = nsp{1};