% look at p012 TEST CHANGES

%% descriptive data
analysis_name = 'noise_reduction';
pid = 'p012';
ver = sprintf('20180618_%s',pid);
params = Parameters.Dynamic(@Parameters.Config.BasicAnalysis,...
    'dt.mintrialspercat',3,...
    'dt.lmcontext','grid',...
    'dt.lmtype','lmresid');
debug = Debug.Debugger(sprintf('%s_%s',analysis_name,ver));
debug.registerClient('FrameworkTask','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('BLc.Reader','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('plot.save','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);


%% experimental info
experiments = hst.getExperiments(pid);
E = size(experiments,1);
movingwin = [1 0.25];
freqbands = {[12 30],[30 80],[80 200],[200 500]};
F = length(freqbands);


%% create results directory
resultdir = fullfile(env.get('results'),analysis_name,ver);
if exist(resultdir,'dir')~=7
    [status,msg] = mkdir(resultdir);
    assert(status>=1,'Could not create directory "%s": %s',resultdir,msg);
end


%% linear model computation

% get a list of data files
blcfiles = cell(1,E);
for ee=1:E
    session = experiments.ExperimentDate(ee);
    taskname = experiments.ExperimentName{ee};
    taskfiles = hst.getTaskFiles(taskname,session,pid);
    T = length(taskfiles);
    blcfiles{ee} = cell(1,T);
    for tt=1:T
        
        % acquire/validate resources
        taskfile = taskfiles{tt};
        [~,taskbase] = fileparts(taskfile);
        try
            lmtype = params.dt.lmtype;
            [task,blc] = proc.helper.getAnalysisObjects(taskfile,debug,'neural_data_lmtype','none');
        catch ME
            msg = util.errorMessage(ME,'noscreen','nolink');
            debug.log(sprintf('SKIP "%s": %s',taskbase,msg),'error');
            continue;
        end
        try
            assert(task.numTrials>=params.dt.mintrials,'Not enough trials in the task (%d found, %d required)',task.numTrials,params.dt.mintrials);
        catch ME
            msg = util.errorMessage(ME,'noscreen','nolink');
            debug.log(sprintf('SKIP "%s": %s',taskbase,msg),'error');
            continue;
        end
        
        % keep this one
        debug.log(sprintf('KEEP "%s"',taskbase),'info');
        blcfiles{ee}{tt} = fullfile(blc.SourceDirectory,sprintf('%s%s',blc.SourceBasename,blc.SourceExtension));
    end
end
blcfiles = cat(2,blcfiles{:});
blcfiles(cellfun(@isempty,blcfiles)) = [];

% generate linear model-based files
for kk=1:length(blcfiles)
    lmdir = sprintf('lm_%s',params.dt.lmcontext);
    srcfile = blcfiles{kk};
    [srcdir,srcbase] = fileparts(srcfile);
    if exist(fullfile(srcdir,lmdir,sprintf('%s_lmresid.blc',srcbase)),'file')==2 && ...
           exist(fullfile(srcdir,lmdir,sprintf('%s_lmfit.blc',srcbase)),'file')==2
       continue;
    end
    debug.log(sprintf('Processing file %d/%d: %s',kk,length(blcfiles),srcbase),'info');
    mapfile = fullfile(srcdir,sprintf('%s.map',regexprep(srcbase,'^(.*)-fs\d+k','$1')));
    assert(exist(mapfile,'file')==2,'Could not find map file for "%s"',srcbase);
    BLc.convert.blc2lm(srcfile,'mapfile',mapfile,debug,'overwrite',params.dt.lmcontext);
end


%% loop over all experimental data and generate descriptive plots
for ee=1:E
    session = experiments.ExperimentDate(ee);
    taskname = experiments.ExperimentName{ee};
    taskfiles = hst.getTaskFiles(taskname,session,pid);
    T = length(taskfiles);
    for tt=1:T
        
        %% acquire/validate resources
        taskfile = taskfiles{tt};
        [~,taskbase] = fileparts(taskfile);
        try
            [task,blc_orig,map] = proc.helper.getAnalysisObjects(taskfile,debug,'neural_data_lmtype','none');
            blc_lmresid = task.getNeuralDataObject('lmresid','fs2k','lmcontext',params.dt.lmcontext); blc_lmresid=blc_lmresid{1};
            blc_lmfit = task.getNeuralDataObject('lmfit','fs2k','lmcontext',params.dt.lmcontext); blc_lmfit=blc_lmfit{1};
        catch ME
            msg = util.errorMessage(ME,'noscreen','nolink');
            debug.log(sprintf('SKIP "%s": %s',taskbase,msg),'error');
            continue;
        end
        try
            assert(task.numTrials>=params.dt.mintrials,'Not enough trials in the task (%d found, %d required)',task.numTrials,params.dt.mintrials);
        catch ME
            msg = util.errorMessage(ME,'noscreen','nolink');
            debug.log(sprintf('SKIP "%s": %s',taskbase,msg),'error');
            continue;
        end
        debug.log(sprintf('KEEP: "%s"',taskbase),'info');
        C = blc_orig.ChannelCount;
        basename = task.taskString;
        phlabel = task.phaseNames;
        phtime = [0 cumsum(mean(diff(task.phaseTimes,1,2),1)) mean(task.trialTimes(:,2))];
        P = length(phlabel);
        switch task.taskName
            case 'DelayedReach'
                [trgroup,grouplbl,shortname,longname] = Analysis.DelayedReach.groupTrialsByTarget(task,params);
            case 'DirectReach'
                [trgroup,grouplbl,shortname,longname] = Analysis.DirectReach.groupTrialsByTarget(task,params);
            otherwise
                error('Unknown task "%s"',task.taskName);
        end
        clr = plot.distinguishable_colors(length(trgroup));
        targetLocations = task.task.params.user.targetlocations;
        
        
        %% compute spectral power
        [psd_data_orig,psd_time_orig] = proc.blc.bandpower_stream_fft(blc_orig,'gpu',true,'pad',1,'single','movingwin',movingwin,'freqband',freqbands,debug);
        psd_time_orig = psd_time_orig/blc_orig.SamplingRate;
        psd_data_orig = 10*log10(psd_data_orig);
        
        car_grid_weights = arrayfun(@(x)zeros(1,blc_orig.ChannelCount),1:blc_orig.ChannelCount,'UniformOutput',false);
        for kk=1:blc_orig.ChannelCount
            grid_number = map.ChannelInfo.GridNumber(kk);
            grid_channels = map.GridInfo.Channels{map.GridInfo.GridNumber==grid_number};
            car_grid_weights{kk}(grid_channels) = 1/length(grid_channels);
        end
        [psd_data_car,psd_time_car] = proc.blc.bandpower_stream_fft(blc_orig,'gpu',true,'pad',1,'single','movingwin',movingwin,'freqband',freqbands,debug,'reref',car_grid_weights);
        psd_time_car = psd_time_car/blc_orig.SamplingRate;
        psd_data_car = 10*log10(psd_data_car);
        
        [psd_data_lmfit,psd_time_lmfit] = proc.blc.bandpower_stream_fft(blc_lmfit,'gpu',true,'pad',1,'single','movingwin',movingwin,'freqband',freqbands,debug);
        psd_time_lmfit = psd_time_lmfit/blc_lmfit.SamplingRate;
        psd_data_lmfit = 10*log10(psd_data_lmfit);
        
        [psd_data_lmresid,psd_time_lmresid] = proc.blc.bandpower_stream_fft(blc_lmresid,'gpu',true,'pad',1,'single','movingwin',movingwin,'freqband',freqbands,debug);
        psd_time_lmresid = psd_time_lmresid/blc_lmresid.SamplingRate;
        psd_data_lmresid = 10*log10(psd_data_lmresid);
        
        % z-score the power data
        psd_data_orig = zscore(psd_data_orig);
        psd_data_car = zscore(psd_data_car);
        psd_data_lmfit = zscore(psd_data_lmfit);
        psd_data_lmresid = zscore(psd_data_lmresid);
        
        % break into trials (bandpass data)
        psd_time_super = psd_time_orig;
        [psd_trial_orig,psd_time_orig] = proc.helper.getTrialSegments(psd_data_orig,psd_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        [psd_trial_car,psd_time_car] = proc.helper.getTrialSegments(psd_data_car,psd_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        [psd_trial_lmresid,psd_time_lmresid] = proc.helper.getTrialSegments(psd_data_lmresid,psd_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        [psd_trial_lmfit,psd_time_lmfit] = proc.helper.getTrialSegments(psd_data_lmfit,psd_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
    end
end