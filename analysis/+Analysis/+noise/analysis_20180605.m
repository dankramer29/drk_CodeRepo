

%% descriptive data
analysis_name = 'noise_reduction';
pid = 'p010';
ver = sprintf('20180610_%s',pid);
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
movingwin = [1 0.05];
freqbands = {[12 30],[30 80],[80 200],[200 500]};
F = length(freqbands);
outer_margin = [0.06 0.08 0.03 0.06]; % left, bottom, right, top
ax_spacing = [0.04 0.03]; % horizontal, vertical
ax_width = ((1-outer_margin(1)-outer_margin(3)) - (F-1)*ax_spacing(1))/F;
ax_height = ((1-outer_margin(2)-outer_margin(4)) - (3-1)*ax_spacing(2))/3;


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
for ee=1%:E
    session = experiments.ExperimentDate(ee);
    taskname = experiments.ExperimentName{ee};
    taskfiles = hst.getTaskFiles(taskname,session,pid);
    T = length(taskfiles);
    for tt=2%1:T
        
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
        phtime = [0 cumsum(mean(diff(task.phaseTimes,1,2),1))];
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
        
        
        %% plot
        hFigure = plot.MultiPanelFigure(...
            'position',[50 50 1600 1000],...
            'margin',outer_margin,...
            'axspacing',ax_spacing,...
            'numrows',4,...
            'numcols',F);
        
        % figure 
        for cc=1%:C
            hFigure.newLayout('inset');
            hFigure.setGroupHold('on','all');
            hFigure.setInsetGroupHold('on','all');
            
            % plot the data
            for ff=1:F
                
                % identify outlier trials
                idx_outlier_orig = util.outliers(max(abs(squeeze(psd_trial_orig(:,ff,cc,:)))),[20 80],2);
                n_orig = size(psd_trial_orig,4)-numel(idx_outlier_orig);
                idx_outlier_car = util.outliers(max(abs(squeeze(psd_trial_car(:,ff,cc,:)))),[20 80],2);
                n_car = size(psd_trial_car,4)-numel(idx_outlier_car);
                idx_outlier_lmfit = util.outliers(max(abs(squeeze(psd_trial_lmfit(:,ff,cc,:)))),[20 80],2);
                n_lmfit = size(psd_trial_lmfit,4)-numel(idx_outlier_lmfit);
                idx_outlier_lmresid = util.outliers(max(abs(squeeze(psd_trial_lmresid(:,ff,cc,:)))),[20 80],2);
                n_lmresid = size(psd_trial_lmresid,4)-numel(idx_outlier_lmresid);
                
                % loop over groups (different colored lines)
                for gg=1:length(trgroup)
                    
                    % plot the original data (top row)
                    idx_trial_orig = setdiff(trgroup{gg},idx_outlier_orig);
                    local_tr_orig = squeeze(psd_trial_orig(:,ff,cc,idx_trial_orig));
                    hFigure.plot(1,ff,psd_time_orig,mean(local_tr_orig,2),'Color',clr(gg,:),'LineWidth',2);
                    
                    % plot the car data (2nd row)
                    idx_trial_car = setdiff(trgroup{gg},idx_outlier_car);
                    local_tr_car = squeeze(psd_trial_car(:,ff,cc,idx_trial_car));
                    hFigure.plot(2,ff,psd_time_car,mean(local_tr_car,2),'Color',clr(gg,:),'LineWidth',2);
                    
                    % plot the fit (3rd row)
                    idx_trial_lmfit = setdiff(trgroup{gg},idx_outlier_lmfit);
                    local_tr_lmfit = squeeze(psd_trial_lmfit(:,ff,cc,idx_trial_lmfit));
                    hFigure.plot(3,ff,psd_time_lmfit,mean(local_tr_lmfit,2),'Color',clr(gg,:),'LineWidth',2);
                    
                    % plot the residual (bottom row)
                    idx_trial_lmresid = setdiff(trgroup{gg},idx_outlier_lmresid);
                    local_tr_lmresid = squeeze(psd_trial_lmresid(:,ff,cc,idx_trial_lmresid));
                    hFigure.plot(4,ff,psd_time_lmresid,mean(local_tr_lmresid,2),'Color',clr(gg,:),'LineWidth',2);
                end
                
                for dd=1:4
                    for kk=1:size(targetLocations,1)
                        hFigure.plotInset(dd,ff,targetLocations(kk,1),targetLocations(kk,2),'Marker','.','Color',clr(kk,:),'MarkerSize',20);
                    end
                end
            end
            
            % finish up inset axes
            hFigure.setInsetGroupHold('off','all');
            hFigure.setInsetGroupProperties('all','box','off','XTick',[],'YTick',[],'XColor','none','YColor','none','Color','none');
            
            % finish up axes
            hFigure.setGroupHold('off','all');
            hFigure.setGroupProperties('all','box','on','xgrid','on','ygrid','on');
            hFigure.setGroupXLabel('Time (sec)','bottomrow');
            hFigure.setGroupedXLim('all',psd_time_orig([1 end]));
            hFigure.setGroupedYLim('all','minmax');
            ylabel_strings = {...
                {sprintf('Original Data (N=%d)',n_orig),'Power (z-scored))'},...
                {sprintf('CAR Data (N=%d)',n_car),'Power (z-scored))'},...
                {sprintf('Model Fit (N=%d)',n_lmfit),'Power (z-scored)'},...
                {sprintf('Model Residual (N=%d)',n_lmresid),'Power (z-scored)'}};
            hFigure.setGroupYLabel(ylabel_strings,'leftcolumn');
            title_strings = cellfun(@(x)sprintf('%d-%d Hz',x(1),x(2)),freqbands,'UniformOutput',false);
            hFigure.setGroupTitle(title_strings,'toprow','Interpreter','none');
            hFigure.removeGroupXTickLabel('except','bottomrow');
            hFigure.removeGroupYTickLabel('except','leftcolumn');
            hFigure.addMarkerLines('allaxes',phtime,'MarkerLabels',phlabel);
            hFigure.addTitle(sprintf('Channel %d (%s)',cc,map.ChannelInfo.Label{cc}),'Interpreter','none')
            %hFigure.save('outdir',resultdir,'basename',sprintf('%s_psdtgtavg_chan%02d',basename,cc),'formats',{'png','fig'},debug,'overwrite');
        end
        %hFigure.delete;
        
        
        
        %% compute bandpass filtered traces
        bp_data_orig = proc.blc.bpfilt(blc_orig,'freqband',freqbands,debug);
        car_grid_weights = arrayfun(@(x)zeros(1,blc_orig.ChannelCount),1:blc_orig.ChannelCount,'UniformOutput',false);
        for kk=1:blc_orig.ChannelCount
            grid_number = map.ChannelInfo.GridNumber(kk);
            grid_channels = map.GridInfo.Channels{map.GridInfo.GridNumber==grid_number};
            car_grid_weights{kk}(grid_channels) = 1/length(grid_channels);
        end
        bp_data_car = proc.blc.bpfilt(blc_orig,'freqband',freqbands,debug,'reref',car_grid_weights);
        bp_data_lmresid = proc.blc.bpfilt(blc_lmresid,'freqband',freqbands,debug);
        bp_data_lmfit = proc.blc.bpfilt(blc_lmfit,'freqband',freqbands,debug);
        
        % z-score the power data
        bp_data_orig = zscore(bp_data_orig);
        bp_data_car = zscore(bp_data_car);
        bp_data_lmresid = zscore(bp_data_lmresid);
        bp_data_lmfit = zscore(bp_data_lmfit);
        
        % break into trials (bandpass data)
        bp_time_super = (0:blc_orig.DataInfo(1).NumRecords-1)/blc_orig.SamplingRate;
        [bp_trial_orig,bp_time_orig] = proc.helper.getTrialSegments(bp_data_orig,bp_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        [bp_trial_car,bp_time_car] = proc.helper.getTrialSegments(bp_data_car,bp_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        [bp_trial_lmresid,bp_time_lmresid] = proc.helper.getTrialSegments(bp_data_lmresid,bp_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        [bp_trial_lmfit,bp_time_lmfit] = proc.helper.getTrialSegments(bp_data_lmfit,bp_time_super,task,'bufferpre',movingwin(1),'bufferpost',movingwin(1));
        
        
        %% plot
        hFigure = plot.MultiPanelFigure(...
            'position',[50 50 1600 1000],...
            'axesareamargin',outer_margin,...
            'axspacing',ax_spacing,...
            'numrows',4,...
            'numcols',F);
        
        % figure
        for cc=1:C
            hFigure.newLayout('inset');
            hFigure.setGroupHold('on','all');
            hFigure.setInsetGroupHold('on','all');
            
            % plot the data
            for ff=1:F
                
                % identify outlier trials
                idx_outlier_orig = util.outliers(max(abs(squeeze(bp_trial_orig(:,ff,cc,:)))),[20 80],2);
                n_orig = size(bp_trial_orig,4)-numel(idx_outlier_orig);
                idx_outlier_car = util.outliers(max(abs(squeeze(bp_trial_car(:,ff,cc,:)))),[20 80],2);
                n_car = size(bp_trial_car,4)-numel(idx_outlier_car);
                idx_outlier_lmresid = util.outliers(max(abs(squeeze(bp_trial_lmresid(:,ff,cc,:)))),[20 80],2);
                n_lmresid = size(bp_trial_lmresid,4)-numel(idx_outlier_lmresid);
                idx_outlier_lmfit = util.outliers(max(abs(squeeze(bp_trial_lmfit(:,ff,cc,:)))),[20 80],2);
                n_lmfit = size(bp_trial_lmfit,4)-numel(idx_outlier_lmfit);
                
                % loop over groups (different colored lines)
                for gg=1:length(trgroup)
                    
                    % plot the original data (top row)
                    idx_trial_orig = setdiff(trgroup{gg},idx_outlier_orig);
                    local_tr_orig = squeeze(bp_trial_orig(:,ff,cc,idx_trial_orig));
                    hFigure.plot(1,ff,bp_time_orig,mean(local_tr_orig,2),'Color',clr(gg,:));
                    
                    % plot the original data (top row)
                    idx_trial_car = setdiff(trgroup{gg},idx_outlier_car);
                    local_tr_car = squeeze(bp_trial_car(:,ff,cc,idx_trial_car));
                    hFigure.plot(2,ff,bp_time_car,mean(local_tr_car,2),'Color',clr(gg,:));
                    
                    % plot the fit (middle row)
                    idx_trial_lmfit = setdiff(trgroup{gg},idx_outlier_lmfit);
                    local_tr_lmfit = squeeze(bp_trial_lmfit(:,ff,cc,idx_trial_lmfit));
                    hFigure.plot(3,ff,bp_time_lmfit,mean(local_tr_lmfit,2),'Color',clr(gg,:));
                    
                    % plot the residual (bottom row)
                    idx_trial_lmresid = setdiff(trgroup{gg},idx_outlier_lmresid);
                    local_tr_lmresid = squeeze(bp_trial_lmresid(:,ff,cc,idx_trial_lmresid));
                    hFigure.plot(4,ff,bp_time_lmresid,mean(local_tr_lmresid,2),'Color',clr(gg,:));
                end
                
                for dd=1:4
                    for kk=1:size(targetLocations,1)
                        hFigure.plotInset(dd,ff,targetLocations(kk,1),targetLocations(kk,2),'Marker','.','Color',clr(kk,:),'MarkerSize',20);
                    end
                end
            end
            
            % finish up inset axes
            hFigure.setInsetGroupHold('off','all');
            hFigure.setInsetGroupProperties('all','box','off','XTick',[],'YTick',[],'XColor','none','YColor','none','Color','none');
            
            % finish up axes
            hFigure.setGroupHold('off','all');
            hFigure.setGroupProperties('all','box','on','xgrid','on','ygrid','on','xlim',bp_time_orig([1 end]));
            hFigure.setGroupXLabel('Time (sec)','bottomrow');
            hFigure.setGroupYLim('global','minmax');
            ylabel_strings = {...
                {sprintf('Original Data (N=%d)',n_orig),'Power (z-scored))'},...
                {sprintf('CAR Data (N=%d)',n_car),'Power (z-scored))'},...
                {sprintf('Model Fit (N=%d)',n_lmfit),'Power (z-scored)'},...
                {sprintf('Model Residual (N=%d)',n_lmresid),'Power (z-scored)'}};
            hFigure.setGroupYLabel(ylabel_strings,'leftcolumn');
            title_strings = cellfun(@(x)sprintf('%d-%d Hz',x(1),x(2)),freqbands,'UniformOutput',false);
            hFigure.setGroupTitle(title_strings,'toprow','Interpreter','none');
            hFigure.removeGroupXTickLabel('except','bottomrow');
            hFigure.removeGroupYTickLabel('except','leftcolumn');
            hFigure.addMarkerLines('allaxes',phtime,'MarkerLabels',phlabel);
            hFigure.addTitle(sprintf('Channel %d (%s)',cc,map.ChannelInfo.Label{cc}),'Interpreter','none')
            hFigure.save('outdir',resultdir,'basename',sprintf('%s_bptgtavg_chan%02d',basename,cc),'formats',{'png','fig'},debug,'overwrite');
        end
        hFigure.delete;
    end
end
