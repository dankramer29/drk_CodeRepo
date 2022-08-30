function randomTrialsCSV_old(trials,freq,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   randomTrialsCSV(trials,freq,paramName1,'paramValue1',...)
%
% Small script to generate random trials to compare set of given
% frequencies/amplitudes. User provides the number of total trials and
% valid frequency/amplitude values. The function creates freq/amp pairs
% with roughly the same number of replicates per pair. It also makes sure
% the larger/smaller value per pair are evenly distributed in the columns.
% It saves the trial pairs values as a comma-separated file,  unless
% otherwise specified, and under "randTrial.csv" in the current directory
% or the specified name and directory.
% 
% Input: 1) trials: number of trials to create;
%        2) freq: vector with freq/amp values to populate trials
%        3) Parameters (optional): 'saveDir','fileName', and 'delimiter'
%        optional inputs to specify where to save the new csv file, the
%        name of the file, and the delimiter type, respectively.
%
% Michelle Armenta Salas (Last update 05/18/16)
% michelle@vis.caltech.edu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
narginchk(2,8);

dataDir = 'D:\Data\ECoG Project\';
fileName = 'randTrial.csv';
delim = ',';
% Check if user provided 'save' directory
idxDir = find(strcmp(varargin,'saveDir'),1);
if ~isempty(idxDir); dataDir = varargin{idxDir+1}; end
idx = find(strcmp(varargin,'fileName'),1);
if ~isempty(idx); fileName = varargin{idx+1}; end
idx = find(strcmp(varargin,'delimiter'),1);
if ~isempty(idx); delim = varargin{idx+1}; end
% Check diretory name has correct format
if ~strcmp(dataDir(end),'\'); dataDir(end+1) = '\'; end

% Variable initialization
trialOrder = nan(trials,2); 
c = 1; pool = nan(sum(1:length(freq)-1),2);
% Generate initial pool of possible pairs
for kk = 1:length(freq)
    for jj = kk+1:length(freq)
        pool(c,1:2) = [freq(kk) freq(jj)];
        c = c + 1;
    end
end

replicates = floor(trials/size(pool,1));
for nn = 1:replicates
    rndIdx = randperm(size(pool,1));
    trialOrder(1+(nn-1)*size(pool,1):size(pool,1)*nn,:) = pool(rndIdx,:);
end
if any(isnan(trialOrder(:)))
    idx = find(all(isnan(trialOrder),2));
    rndIdx = randi([1 size(pool,1)],[length(idx) 1]);
    trialOrder(idx,:) = pool(rndIdx,:);
end
% Shuffle them one last time
trialOrder = trialOrder(randperm(trials),:);

% Check that the number of large responses are evenly distributed in
% left/right
idx = trialOrder(:,1) > trialOrder(:,2);

if sum(idx) > round(trials/2)
    trIdx = find(trialOrder(:,1) > trialOrder(:,2));
    delta = sum(idx) - round(trials/2);
    randIdx = randperm(length(trIdx),delta);
    temp = trialOrder(trIdx(randIdx),1);
    trialOrder(trIdx(randIdx),1) = trialOrder(trIdx(randIdx),2);
    trialOrder(trIdx(randIdx),2) = temp; 
elseif sum(~idx) > round(trials/2)
    trIdx = find(trialOrder(:,1) < trialOrder(:,2));
    delta = length(trIdx) - round(trials/2);
    randIdx = randperm(length(trIdx),delta);
    temp = trialOrder(trIdx(randIdx),1);
    trialOrder(trIdx(randIdx),1) = trialOrder(trIdx(randIdx),2);
    trialOrder(trIdx(randIdx),2) = temp;
end

% Create data set and export as csv file with in specified directory and
% under specified filename
dat = cell2dataset(num2cell(trialOrder),'ReadVarNames',false);
export(dat,'file',[dataDir,fileName],'delimiter',delim);
end