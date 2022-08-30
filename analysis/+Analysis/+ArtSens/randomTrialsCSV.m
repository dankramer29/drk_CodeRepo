function randomTrialsCSV(trials,differences,range,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   randomTrialsCSV(trials,differences,range,paramName1,'paramValue1',...)
%
% Small script to generate random trials to compare set of given
% frequencies/amplitudes differences. User provides the number of total 
% trials and differences to test (e.g. [5 10] Hz) and accepted ranges for 
% the parameter.
% The function creates freq/amp pairs with roughly the same number of 
% replicates per pair. It saves the trial pairs values as a comma-separated 
% file,  unless otherwise specified, with  name "randTrial.csv" in the 
% results/data directory
%   
%   1) RANDOMTRIALSCSV(TRIALS,DIFFERENCES,RANGE): Function generates TRIALS
%   for discrimnation task, using random parameters from RANGE, with
%   uniformly distributed DIFFERENCES between the parameter values. TRIALS
%   is a scalar integer value, DIFFERENCES can be a scalar or N-by-1 vector
%   of N differences to test, and RANGE is a 1-by-2 vector with [min max]
%   values the test parameters can take.
%
%   2) RANDOMTRIALSCSV(...,'SAVE',STRING1,'FILENAME',STRING2,'DELIMITER',CHAR1):
%   Optional paramter pair-value to update directory to save resulting csv
%   file.
%
% Michelle Armenta Salas (Last update 10/24/16)
% michelle@vis.caltech.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
narginchk(3,8);

dataDir = fullfile(env.get('results'),'ECoG'); % NOTE: You can replace/comment out this line if no env variables are set up in env.default
datestmp = datestr(datetime('today','Format','yyyyMMdd'),'yyyymmdd');
filename = ['randTrial_',datestmp,'.csv'];
delim = ',';
% Check if user provided 'save' directory and output parameters
idxDir = find(strcmpi(varargin,'saveDir'),1);
if ~isempty(idxDir); dataDir = varargin{idxDir+1}; end
idx = find(strcmpi(varargin,'fileName'),1);
if ~isempty(idx); filename = varargin{idx+1}; end
idx = find(strcmpi(varargin,'delimiter'),1);
if ~isempty(idx); delim = varargin{idx+1}; end


% Variable initialization
set = nan(trials,2); 
% Generate initial pool of possible values
values = range(1):5:range(2); % for convineance we'll keep increments of five
pairpool = nchoosek(values(:),2);
diffpool = diff(pairpool,1,2);
idx = (diffpool > 0) & ismember(diffpool,differences); % get the pairs that meet the given criteria
pairpool(~idx,:) = [];
diffpool(~idx) = [];

% check the differences are uniformly distributed
fraction = floor(trials/length(differences));
ndiff = cellfun(@(x)sum(abs(diffpool) == x),num2cell(differences));
if length(unique(ndiff)) > 1
    set = [];
    idx = cellfun(@(x)abs(diffpool) == x,num2cell(differences),'UniformOutput',false);
    for nn = 1:length(differences)
        tempset = pairpool(idx{nn},:);
        if ndiff(nn) > fraction
            tempset(randi(length(tempset),[1 ndiff(nn)-fraction]),:) = [];
        elseif ndiff(nn) < fraction
            tempset2 = tempset(randi(length(tempset),[1 fraction-ndiff(nn)]),:);
            tempset = [tempset;tempset2];
        end
        set = [set;tempset];
    end
end

% Randomize trials
set = set(randperm(size(set,1)),:);
% Check trial length is correct
if size(set,1) > trials
    set(randi([1 size(set,1)],[1 size(set,1)-trials]),:) = [];
end


% Check that the number of large responses are evenly distributed in
% left/right
idx = set(:,1) > set(:,2);

if sum(idx) > round(trials/2)
    trIdx = find(set(:,1) > set(:,2));
    delta = sum(idx) - round(trials/2);
    randIdx = randperm(length(trIdx),delta);
    temp = set(trIdx(randIdx),1);
    set(trIdx(randIdx),1) = set(trIdx(randIdx),2);
    set(trIdx(randIdx),2) = temp; 
elseif sum(~idx) > round(trials/2)
    trIdx = find(set(:,1) < set(:,2));
    delta = length(trIdx) - round(trials/2);
    randIdx = randperm(length(trIdx),delta);
    temp = set(trIdx(randIdx),1);
    set(trIdx(randIdx),1) = set(trIdx(randIdx),2);
    set(trIdx(randIdx),2) = temp;
end

% Create data set and export as csv file with in specified directory and
% under specified filename
dat = cell2dataset(num2cell(set),'ReadVarNames',false);
export(dat,'file',fullfile(dataDir,filename),'delimiter',delim);
end