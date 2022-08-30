
%% descriptive data
taskname = 'DelayedReach';
pid = 'p012';
ver = sprintf('20180514_%s_phase_changes',pid);
params = Parameters.Dynamic(@Parameters.Config.BasicAnalysis,...
    'dt.mintrialspercat',3);
debug = Debug.Debugger(sprintf('DelayedReach_%s',ver));
debug.registerClient('FrameworkTask','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('BLc.Reader','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('plot.save','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);

%% create results directory
resultdir = fullfile(env.get('results'),taskname,ver);
if exist(resultdir,'dir')~=7
    [status,msg] = mkdir(resultdir);
    assert(status>=1,'Could not create directory "%s": %s',resultdir,msg);
end

%% loop over all experimental data
experiments = hst.getExperiments(taskname,pid);
for ee=1:size(experiments,1)
    pid = experiments.PatientID{ee};
    session = experiments.ExperimentDate(ee);
    taskfiles = hst.getTaskFiles(taskname,session,pid);
    for tt=1:length(taskfiles)
        
        %% load task and data objects
        try
            [task,blc,map] = proc.helper.getAnalysisObjects(taskfiles{tt},debug);
        catch ME
            msg = util.errorMessage(ME,'noscreen','nolink');
            [~,taskbase] = fileparts(taskfiles{tt});
            debug.log(sprintf('SKIP "%s": %s',taskbase,msg),'error');
            continue;
        end
        
        %% compute phase times/names
        [dt_time,relt_time] = proc.helper.getPhaseTimeSeries(task,debug);
        [dt_pwr,freq,relt_pwr] = proc.helper.getPhaseSpectralPower(task,debug);
    end
end