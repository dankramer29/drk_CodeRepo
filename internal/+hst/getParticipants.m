function participants = getParticipants(varargin)
% GETPARTICIPANTS Get a list of participant information
%
%   PARTICIPANTS = GETPARTICIPANTS
%   Return a list of all valid participants from Keck/Rancho experiments.

% identify the location of the participants.csv file
datadirs = env.get('data');
exists = cellfun(@(x)exist(fullfile(x,'participants.csv'),'file')==2,datadirs);
assert(any(exists),'Could not find "participants.csv" in any of the data folders %s',strjoin(datadirs));
patient_file = fullfile(datadirs{exists},'participants.csv');

% read out patient list into a table (headers "PatientID" and "Hospital")
participants = readtable(patient_file,'Delimiter',',','ReadVariableNames',true);

% subselect requested
if nargin>0
    idx = zeros(size(participants,1),1);
    for kk=1:length(varargin)
        idx = idx + strcmpi(varargin{kk},participants.PatientID) + strcmpi(varargin{kk},participants.Hospital);
    end
    maxval = max(idx);
    idx = idx==maxval;
    participants = participants(idx,:);
end