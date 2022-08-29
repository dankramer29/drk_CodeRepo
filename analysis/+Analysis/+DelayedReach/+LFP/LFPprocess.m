% script to prompt user for inputs, and plot all lead groups over small
% time window to look for noise / channel differences

% will extend this to do averaging and spectrograms and compare locations
% etc so that new patient data can be run in one script. 

% NTS: would be nice to have lead:channel info stored for a patient so it
% can be used with analysis of direct, delayed etc. 

exitCode = 0;
while exitCode == 0
    [fullTaskName, nsGrids, nsType] = center_out.getObjInfo;
    disp(['|File selected: ', fullfile(fullTaskName)])
    disp(['|Grids selected: ', nsGrids, ' |Type selected: ', nsType])

    prompt = 'Is this information correct? [y/n]: ';
    in = input(prompt, 's');
        if in == 'y'
            exitCode = 1;
        else 
            prompt = 'Would you like to change input? [y/n]: ';
            in = input(prompt, 's');
                if in == 'y'
                    exitCode = 0;
                else
                    disp('Ending LFPtrialProcess')
                    return
                end
        end

end

% initialize objects based on user input
taskObj = FrameworkTask(fullTaskName);
ns = taskObj.getNeuralDataObject(nsGrids, nsType);
ns = ns{1};

% default values to 
trialKeys = {'location', 'success', 'startPhase', 'stopPhase'};
trialValues = [7, 200, 1, 0];
trialDefaults = containers.Map(trialKeys, trialValues);
timeStart = 10;
timeEnd = 15;

keys = chMap.keys;
values = chMap.values;

for i = 1:length(keys)
    leadName = keys{i};
    channels = str2num(values{i});
    Analysis.DelayedReach.LFP.inspectChannels(ns, channels, leadName, timeStart, timeEnd)
end

% [LtrialNums, LtrialStarts, LtrialEnds, LlogArray] = pullTrials(taskObj, trialDefaults.locations, trialDefaults.successDistance, trialDefaults.startPhase, trialDefaults.stopPhase);
%     [LneuralStarts, LneuralEnds, Lwindow] = pullNeural(taskObj, LtrialStarts, LtrialEnds);
%     [RtrialNums, RtrialStarts, RtrialEnds, RlogArray] = pullTrials(taskObj, 3, trialDefaults.successDistance, trialDefaults.startPhase, trialDefaults.stopPhase);
%     [RneuralStarts, RneuralEnds, Rwindow] = pullNeural(taskObj, RtrialStarts, RtrialEnds);
%     window = max(Lwindow, Rwindow);



