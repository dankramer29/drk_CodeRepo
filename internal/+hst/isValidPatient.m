function [tf,validPatients,validIdx] = isValidPatient(list)
% HST.ISVALIDPATIENT query whether inputs are valid patient IDs
%
%   TF = HST.ISVALIDPATIENT(PID)
%   For patient ID in PID, return logical value in TF indicating whether
%   PID is a valid patient ID.  PID can also be a cell array of
%   potential patient IDs.  Checks inputs agains the patients returned by
%   HST.GETPATIENTS.
%
%   [TF,PTS,IDX] = HST.ISVALIDPATIENT(PID)
%   Also return a list of all valid patients and logical indexing
%   indicating which patient matched.
%
%   See also HST.GETPATIENTS.

% default not valid
tf = false;

% return immediately if empty
if isempty(list), return; end

% list of valid subjects
validPatients = hst.getPatients;

% only chars can be valid subject
if ~iscell(list),list={list};end
validIdx = cellfun(@ischar,list);

% compare potential inputs against list of valid subjects
tf = false(1,length(list));
tf(validIdx) = cellfun(@(x)any(strcmpi(validPatients.PatientID,x)),list(validIdx));
