%env.set('Data', '\\striatum\Data\neural\archive\')
taskObj = FrameworkTask('\\striatum\Data\neural\archive\keck\Ruiz Miguel psych task\20170830\task\20170830-133354-133456-DelayedReach.mat');

ns = taskObj.getNeuralDataObject('AllGrids', 'ns3');
ns = ns{1};

TotalChanArray = [1:10 17:26 33:42 49:58 65:74 81:90 97:104 113:120]; % all channels recording neural data
TaskString = string(regexp(taskObj.taskString, '\d*-(.*)', 'tokens'));

%gridMapObj = GridMap('D:\1_Year\Neuro_SP\Task Recording\Data\P010\20170830\AllGrids\P010_map.csv');

Targets = arrayfun(@(x)x.tr_prm.targetID,taskObj.trialdata)';


DtClass = 'single';



%%
trial_times = [taskObj.trialTimes];
phase_times = [taskObj.phaseTimes];
phase_times(:,end+1) = phase_times(:,1) + trial_times(:,2);
phase_times_relT = phase_times - phase_times(:,1);
phase_names = [taskObj.phaseNames];

%%
[ND, RelT, ~] = proc.blackrock.broadband(...
    ns, 'PROCWIN', trial_times, DtClass, 'CHANNELS', TotalChanArray);

RelT_phase_idx = Analysis.DelayedReach.LFP.match_relative_times(RelT, phase_times_relT);
% trial #2 ends less than 1s after the response phase starts


%%
X_trials = [2 19];

trial_logical = ones(length(Targets), 1, 'logical');
trial_logical(X_trials) = 0;
Targets = Targets(trial_logical);
trial_times = trial_times(trial_logical, :);
phase_times = phase_times(trial_logical, :);
phase_times_relT = phase_times_relT(trial_logical, :);
RelT = RelT(trial_logical);
RelT_phase_idx = RelT_phase_idx(trial_logical,:);
ND = ND(trial_logical);
%% Align Trials, Clip to Equal Lengths
pre_time = 2;
post_time = 1;
phase = 5;
[aligned_data, aligned_relT] = Analysis.DelayedReach.LFP.trial_align_clip(ND, RelT, RelT_phase_idx, ns.Fs, pre_time, post_time, phase);


%%
VertLineCoords = 2; % movment initiation, seconds from start of clipped data

% Analysis.DelayedReach.LFP.plotNeuralDataTrials(aligned_data, Targets, aligned_relT, TaskString, 'VertLineCoords', VertLineCoords)

%% Exclude trials
% NEED TO REMOVE ONE OF TARGET 7 TRIALS FROM ALL 
% trial #2 ends less than 1s after the response phase starts


