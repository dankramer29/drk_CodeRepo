function experiments = getExperiments(varargin)
% GETEXPERIMENTS Get a list of experiments
%
%   EXPERIMENTS = GETEXPERIMENTS
%   Return a list of all experiments from Keck/Rancho patients.

% identify the location of the experiments.csv file
datadirs = env.get('data');
exists = cellfun(@(x)exist(fullfile(x,'experiments.csv'),'file')==2,datadirs);
assert(any(exists),'Could not find "experiments.csv" in any of the data folders %s',strjoin(datadirs));
experiment_file = fullfile(datadirs{exists},'experiments.csv');

% read out experiment list into a table
experiments = readtable(experiment_file,'Delimiter',',','ReadVariableNames',true);

% subselect to requested patient
if nargin>0
    idx = zeros(size(experiments,1),1);
    for kk=1:length(varargin)
        idx = idx + ...
            strcmpi(experiments.PatientID,varargin{kk}) + ...
            strcmpi(experiments.ExperimentName,varargin{kk}) + ...
            strcmpi(experiments.ExperimentDate,varargin{kk});
    end
    val = max(idx);
    experiments = experiments(idx==val,:);
end