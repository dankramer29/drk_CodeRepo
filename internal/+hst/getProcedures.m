function procedures = getProcedures(varargin)
% GETPROCEDURES Get a list of procedures
%
%   PROCEDURES = GETPROCEDURES
%   Return a list of all procedures from Keck/Rancho patients.
[varargin,pid,found_pid] = util.argfn(@hst.isValidPatient,varargin,'');
util.argempty(varargin);

% identify the location of the procedures.csv file
datadirs = env.get('data');
exists = cellfun(@(x)exist(fullfile(x,'procedures.csv'),'file')==2,datadirs);
assert(any(exists),'Could not find "procedures.csv" in any of the data folders %s',strjoin(datadirs));
procedure_file = fullfile(datadirs{exists},'procedures.csv');

% read out procedure list into a table
procedures = readtable(procedure_file,'Delimiter',',','ReadVariableNames',true);

% subselect to requested patient
if found_pid
    procedures(~strcmpi(procedures.PatientID,pid),:) = [];
end