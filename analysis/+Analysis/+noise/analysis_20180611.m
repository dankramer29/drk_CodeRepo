

%% descriptive data
analysis_name = 'noise_reduction';
pid = 'p010';
ver = sprintf('20180611_%s',pid);
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
        
        
        %% classify directions
        % INCONCLUSIVE
        R = 50;%params.st.nshuf;
        B = size(psd_trial_orig,1);
        loss_orig = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_car = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_lmfit = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_lmresid = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_orig_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        loss_car_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        loss_lmfit_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        loss_lmresid_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        lt = util.LoopTimer;
        lt.initialize;
        for cc=1:C
            lt.iterationStart;
            cc_trial_orig = squeeze(psd_trial_orig(:,:,cc,:));
            cc_trial_car = squeeze(psd_trial_car(:,:,cc,:));
            cc_trial_lmfit = squeeze(psd_trial_lmfit(:,:,cc,:));
            cc_trial_lmresid = squeeze(psd_trial_lmresid(:,:,cc,:));
            
            % plot the data
            for ff=1:F
                
                %% identify outlier trials
                idx_outlier_orig = util.outliers(max(abs(squeeze(cc_trial_orig(:,ff,:)))),[20 80],2);
                n_orig = size(cc_trial_orig,3)-numel(idx_outlier_orig);
                
                idx_outlier_car = util.outliers(max(abs(squeeze(cc_trial_car(:,ff,:)))),[20 80],2);
                n_car = size(cc_trial_car,3)-numel(idx_outlier_car);
                
                idx_outlier_lmfit = util.outliers(max(abs(squeeze(cc_trial_lmfit(:,ff,:)))),[20 80],2);
                n_lmfit = size(cc_trial_lmfit,3)-numel(idx_outlier_lmfit);
                
                idx_outlier_lmresid = util.outliers(max(abs(squeeze(cc_trial_lmresid(:,ff,:)))),[20 80],2);
                n_lmresid = size(cc_trial_lmresid,3)-numel(idx_outlier_lmresid);
                
                
                %% collect data and labels
                idx_orig = cellfun(@(x)setdiff(x,idx_outlier_orig),trgroup,'UniformOutput',false);
                lbl_orig = arrayfun(@(x)repmat({sprintf('target%d',grouplbl(x))},1,length(idx_orig{x})),1:length(grouplbl),'UniformOutput',false);
                X_orig = cellfun(@(x)squeeze(cc_trial_orig(:,ff,x)),idx_orig,'UniformOutput',false);
                
                idx_car = cellfun(@(x)setdiff(x,idx_outlier_car),trgroup,'UniformOutput',false);
                lbl_car = arrayfun(@(x)repmat({sprintf('target%d',grouplbl(x))},1,length(idx_car{x})),1:length(grouplbl),'UniformOutput',false);
                X_car = cellfun(@(x)squeeze(cc_trial_car(:,ff,x)),idx_car,'UniformOutput',false);
                
                idx_lmfit = cellfun(@(x)setdiff(x,idx_outlier_lmfit),trgroup,'UniformOutput',false);
                lbl_lmfit = arrayfun(@(x)repmat({sprintf('target%d',grouplbl(x))},1,length(idx_lmfit{x})),1:length(grouplbl),'UniformOutput',false);
                X_lmfit = cellfun(@(x)squeeze(cc_trial_lmfit(:,ff,x)),idx_lmfit,'UniformOutput',false);
                
                idx_lmresid = cellfun(@(x)setdiff(x,idx_outlier_lmresid),trgroup,'UniformOutput',false);
                lbl_lmresid = arrayfun(@(x)repmat({sprintf('target%d',grouplbl(x))},1,length(idx_lmresid{x})),1:length(grouplbl),'UniformOutput',false);
                X_lmresid = cellfun(@(x)squeeze(cc_trial_lmresid(:,ff,x)),idx_lmresid,'UniformOutput',false);
                
                
                %% loop over time bins
                bb_loss_orig = nan(B,1);
                bb_loss_car = nan(B,1);
                bb_loss_lmfit = nan(B,1);
                bb_loss_lmresid = nan(B,1);
                bb_loss_orig_shuf = nan(B,R);
                bb_loss_car_shuf = nan(B,R);
                bb_loss_lmfit_shuf = nan(B,R);
                bb_loss_lmresid_shuf = nan(B,R);
                parfor bb=1:B
                    
                    % create classifier inputs
                    local_X_orig = cellfun(@(x)x(bb,:),X_orig,'UniformOutput',false);
                    local_X_orig = cat(2,local_X_orig{:})';
                    local_lbl_orig = cat(2,lbl_orig{:})';
                    
                    local_X_car = cellfun(@(x)x(bb,:),X_car,'UniformOutput',false);
                    local_X_car = cat(2,local_X_car{:})';
                    local_lbl_car = cat(2,lbl_car{:})';
                    
                    local_X_lmfit = cellfun(@(x)x(bb,:),X_lmfit,'UniformOutput',false);
                    local_X_lmfit = cat(2,local_X_lmfit{:})';
                    local_lbl_lmfit = cat(2,lbl_lmfit{:})';
                    
                    local_X_lmresid = cellfun(@(x)x(bb,:),X_lmresid,'UniformOutput',false);
                    local_X_lmresid = cat(2,local_X_lmresid{:})';
                    local_lbl_lmresid = cat(2,lbl_lmresid{:})';
                    
                    % cross-validated classification
                    mdl = fitcdiscr(local_X_orig,categorical(local_lbl_orig),'LeaveOut','on');
                    bb_loss_orig(bb)= kfoldLoss(mdl);
                    
                    mdl = fitcdiscr(local_X_car,categorical(local_lbl_car),'LeaveOut','on'); 
                    bb_loss_car(bb) = kfoldLoss(mdl);
                    
                    mdl = fitcdiscr(local_X_lmfit,categorical(local_lbl_lmfit),'LeaveOut','on'); 
                    bb_loss_lmfit(bb) = kfoldLoss(mdl);
                    
                    mdl = fitcdiscr(local_X_lmresid,categorical(local_lbl_lmresid),'LeaveOut','on'); 
                    bb_loss_lmresid(bb) = kfoldLoss(mdl);
                    
                    for rr=1:R
                        
                        % create classifier inputs
                        idx_perm_orig = randperm(length(local_lbl_orig));
                        local_lbl_orig_shuf = local_lbl_orig(idx_perm_orig);
                        
                        idx_perm_car = randperm(length(local_lbl_car));
                        local_lbl_car_shuf = local_lbl_car(idx_perm_car);
                        
                        idx_perm_lmfit = randperm(length(local_lbl_lmfit));
                        local_lbl_lmfit_shuf = local_lbl_lmfit(idx_perm_lmfit);
                        
                        idx_perm_lmresid = randperm(length(local_lbl_lmresid));
                        local_lbl_lmresid_shuf = local_lbl_lmresid(idx_perm_lmresid);
                        
                        % cross-validated classification
                        mdl = fitcdiscr(local_X_orig,categorical(local_lbl_orig_shuf),'LeaveOut','on');
                        bb_loss_orig_shuf(bb,rr) = kfoldLoss(mdl);
                        
                        mdl = fitcdiscr(local_X_car,categorical(local_lbl_car_shuf),'LeaveOut','on');
                        bb_loss_car_shuf(bb,rr) = kfoldLoss(mdl);
                        
                        mdl = fitcdiscr(local_X_lmfit,categorical(local_lbl_lmfit_shuf),'LeaveOut','on');
                        bb_loss_lmfit_shuf(bb,rr) = kfoldLoss(mdl);
                        
                        mdl = fitcdiscr(local_X_lmresid,categorical(local_lbl_lmresid_shuf),'LeaveOut','on');
                        bb_loss_lmresid_shuf(bb,rr) = kfoldLoss(mdl);
                    end
                end
                
                % place outputs back
                loss_orig{cc}(:,ff) = bb_loss_orig';
                loss_car{cc}(:,ff) = bb_loss_car';
                loss_lmfit{cc}(:,ff) = bb_loss_lmfit';
                loss_lmresid{cc}(:,ff) = bb_loss_lmresid';
                loss_orig_shuf{cc}(:,ff,:) = bb_loss_orig_shuf;
                loss_car_shuf{cc}(:,ff,:) = bb_loss_car_shuf;
                loss_lmfit_shuf{cc}(:,ff,:) = bb_loss_lmfit_shuf;
                loss_lmresid_shuf{cc}(:,ff,:) = bb_loss_lmresid_shuf;
            end
            
            % update loop timer
            lt.iterationEnd;
            [~,msg] = lt.getStats('num_left',C-cc,'msg_format',sprintf('Channel %d/%d: #TOTAL_ELAPSED#; #TOTAL_REMAINING#',cc,C));
            debug.log(msg,'info');
        end
        
        
        
        %% plot
        hFigure = plot.MultiPanelFigure('Position',[50 50 1600 1000],'NumRows',4,'NumCols',F);
        hFigure.newLayout('title','Minimum kfoldLoss for 8-way direction classification');
        for ff=1:F
            vals_orig = cellfun(@(x)nanmin(x(:,ff)),loss_orig);
            hFigure.stem(1,ff,vals_orig);
            hFigure.text(1,ff,0.6*C,0.1,sprintf('min %.2f',min(vals_orig)),'FontWeight','bold','FontSize',15);
            vals_car = cellfun(@(x)nanmin(x(:,ff)),loss_car);
            hFigure.stem(2,ff,vals_car);
            hFigure.text(2,ff,0.6*C,0.1,sprintf('min %.2f',min(vals_car)),'FontWeight','bold','FontSize',15);
            vals_lmfit = cellfun(@(x)nanmin(x(:,ff)),loss_lmfit);
            hFigure.stem(3,ff,vals_lmfit);
            hFigure.text(3,ff,0.6*C,0.1,sprintf('min %.2f',min(vals_lmfit)),'FontWeight','bold','FontSize',15);
            vals_lmresid = cellfun(@(x)nanmin(x(:,ff)),loss_lmresid);
            hFigure.stem(4,ff,vals_lmresid);
            hFigure.text(4,ff,0.6*C,0.1,sprintf('min %.2f',min(vals_lmresid)),'FontWeight','bold','FontSize',15);
        end
        hFigure.setGroupedYLim('all','minmax');
        title_strings = cellfun(@(x)sprintf('%d-%d Hz',x(1),x(2)),freqbands,'UniformOutput',false);
        hFigure.setGroupTitle(title_strings,'toprow');
        ylabel_strings = {...
            {'As Recorded','loss'},...
            {'CAR','loss'},...
            {'LM Fit','loss'},...
            {'LM Residual','loss'}};
        hFigure.setGroupYLabel(ylabel_strings,'leftcolumn');
        hFigure.removeGroupXTickLabel('except','bottomrow');
        hFigure.removeGroupYTickLabel('except','leftcolumn');
        hFigure.setGroupProperties('all','XGrid','on','YGrid','on');
        hFigure.setGroupXLabel('Channel','bottomrow');
        hFigure.setGroupedXLim('all',[1 C]);
        hFigure.save('outdir',resultdir,'basename',sprintf('%s_tgt_kfoldloss',basename),'formats',{'png','fig'},debug,'overwrite');
        hFigure.delete;
        
        
        
        
        
        %% classify action vs. ITI
        loss_orig = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_car = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_lmfit = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_lmresid = arrayfun(@(x)nan(B,F),1:C,'UniformOutput',false);
        loss_orig_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        loss_car_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        loss_lmfit_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        loss_lmresid_shuf = arrayfun(@(x)nan(B,F,R),1:C,'UniformOutput',false);
        lt = util.LoopTimer;
        lt.initialize;
        for cc=1:C
            lt.iterationStart;
            cc_trial_orig = squeeze(psd_trial_orig(:,:,cc,:));
            cc_trial_car = squeeze(psd_trial_car(:,:,cc,:));
            cc_trial_lmfit = squeeze(psd_trial_lmfit(:,:,cc,:));
            cc_trial_lmresid = squeeze(psd_trial_lmresid(:,:,cc,:));
            
            % plot the data
            for ff=1:F
                
                
                %% identify outlier trials
                idx_outlier_orig = util.outliers(max(abs(squeeze(cc_trial_orig(:,ff,:)))),[20 80],2);
                n_orig = size(cc_trial_orig,3)-numel(idx_outlier_orig);
                
                idx_outlier_car = util.outliers(max(abs(squeeze(cc_trial_car(:,ff,:)))),[20 80],2);
                n_car = size(cc_trial_car,3)-numel(idx_outlier_car);
                
                idx_outlier_lmfit = util.outliers(max(abs(squeeze(cc_trial_lmfit(:,ff,:)))),[20 80],2);
                n_lmfit = size(cc_trial_lmfit,3)-numel(idx_outlier_lmfit);
                
                idx_outlier_lmresid = util.outliers(max(abs(squeeze(cc_trial_lmresid(:,ff,:)))),[20 80],2);
                n_lmresid = size(cc_trial_lmresid,3)-numel(idx_outlier_lmresid);
                
                
                %% collect data and labels
                idx_orig = cellfun(@(x)setdiff(x,idx_outlier_orig),trgroup,'UniformOutput',false);
                X_orig = cellfun(@(x)squeeze(cc_trial_orig(:,ff,x)),idx_orig,'UniformOutput',false);
                
                idx_car = cellfun(@(x)setdiff(x,idx_outlier_car),trgroup,'UniformOutput',false);
                X_car = cellfun(@(x)squeeze(cc_trial_car(:,ff,x)),idx_car,'UniformOutput',false);
                
                idx_lmfit = cellfun(@(x)setdiff(x,idx_outlier_lmfit),trgroup,'UniformOutput',false);
                X_lmfit = cellfun(@(x)squeeze(cc_trial_lmfit(:,ff,x)),idx_lmfit,'UniformOutput',false);
                
                idx_lmresid = cellfun(@(x)setdiff(x,idx_outlier_lmresid),trgroup,'UniformOutput',false);
                X_lmresid = cellfun(@(x)squeeze(cc_trial_lmresid(:,ff,x)),idx_lmresid,'UniformOutput',false);
                
                % compute indices for ITI
                st_iti = phtime(1)+movingwin(1)/2;
                lt_iti = phtime(2)-movingwin(1)/2;
                idx_time_iti = psd_time_orig>=st_iti & psd_time_orig<=lt_iti;
                
                % extract ITI from the data
                local_X_iti_orig = cellfun(@(x)mean(x(idx_time_iti,:),1),X_orig,'UniformOutput',false);
                local_X_iti_orig = cat(2,local_X_iti_orig{:})';
                local_lbl_iti_orig = repmat({'rest'},size(local_X_iti_orig,1),1);
                
                local_X_iti_car = cellfun(@(x)mean(x(idx_time_iti,:),1),X_car,'UniformOutput',false);
                local_X_iti_car= cat(2,local_X_iti_car{:})';
                local_lbl_iti_car = repmat({'rest'},size(local_X_iti_car,1),1);
                
                local_X_iti_lmfit = cellfun(@(x)mean(x(idx_time_iti,:),1),X_lmfit,'UniformOutput',false);
                local_X_iti_lmfit= cat(2,local_X_iti_lmfit{:})';
                local_lbl_iti_lmfit = repmat({'rest'},size(local_X_iti_lmfit,1),1);
                
                local_X_iti_lmresid = cellfun(@(x)mean(x(idx_time_iti,:),1),X_lmresid,'UniformOutput',false);
                local_X_iti_lmresid= cat(2,local_X_iti_lmresid{:})';
                local_lbl_iti_lmresid = repmat({'rest'},size(local_X_iti_lmresid,1),1);
                
                %% loop over time bins
                bb_loss_orig = nan(B,1);
                bb_loss_car = nan(B,1);
                bb_loss_lmfit = nan(B,1);
                bb_loss_lmresid = nan(B,1);
                bb_loss_orig_shuf = nan(B,R);
                bb_loss_car_shuf = nan(B,R);
                bb_loss_lmfit_shuf = nan(B,R);
                bb_loss_lmresid_shuf = nan(B,R);
                parfor bb=1:B
                    
                    % create classifier inputs
                    local_X_orig = cellfun(@(x)mean(x(bb,:),1),X_orig,'UniformOutput',false);
                    local_X_orig = cat(2,local_X_orig{:})';
                    local_lbl_orig = repmat({'action'},size(local_X_orig,1),1);
                    
                    local_X_car = cellfun(@(x)mean(x(bb,:),1),X_car,'UniformOutput',false);
                    local_X_car = cat(2,local_X_car{:})';
                    local_lbl_car = repmat({'action'},size(local_X_car,1),1);
                    
                    local_X_lmfit = cellfun(@(x)mean(x(bb,:),1),X_lmfit,'UniformOutput',false);
                    local_X_lmfit = cat(2,local_X_lmfit{:})';
                    local_lbl_lmfit = repmat({'action'},size(local_X_lmfit,1),1);
                    
                    local_X_lmresid = cellfun(@(x)mean(x(bb,:),1),X_lmresid,'UniformOutput',false);
                    local_X_lmresid = cat(2,local_X_lmresid{:})';
                    local_lbl_lmresid = repmat({'action'},size(local_X_lmresid,1),1);
                    
                    % cross-validated classification
                    local_X_orig_combined = [local_X_iti_orig; local_X_orig];
                    local_lbl_orig_combined = categorical([local_lbl_iti_orig; local_lbl_orig]);
                    mdl = fitcdiscr(local_X_orig_combined,local_lbl_orig_combined,'LeaveOut','on');
                    bb_loss_orig(bb) = kfoldLoss(mdl);
                    
                    local_X_car_combined = [local_X_iti_car; local_X_car];
                    local_lbl_car_combined = categorical([local_lbl_iti_car; local_lbl_car]);
                    mdl = fitcdiscr(local_X_car_combined,local_lbl_car_combined,'LeaveOut','on');
                    bb_loss_car(bb) = kfoldLoss(mdl);
                    
                    local_X_lmfit_combined = [local_X_iti_lmfit; local_X_lmfit];
                    local_lbl_lmfit_combined = categorical([local_lbl_iti_lmfit; local_lbl_lmfit]);
                    mdl = fitcdiscr(local_X_lmfit_combined,local_lbl_lmfit_combined,'LeaveOut','on');
                    bb_loss_lmfit(bb) = kfoldLoss(mdl);
                    
                    local_X_lmresid_combined = [local_X_iti_lmresid; local_X_lmresid];
                    local_lbl_lmresid_combined = categorical([local_lbl_iti_lmresid; local_lbl_lmresid]);
                    mdl = fitcdiscr(local_X_lmresid_combined,local_lbl_lmresid_combined,'LeaveOut','on');
                    bb_loss_lmresid(bb) = kfoldLoss(mdl);
                    
                    for rr=1:R
                        idx_perm_orig = randperm(length(local_lbl_orig_combined));
                        local_lbl_orig_shuf = local_lbl_orig_combined(idx_perm_orig);
                        
                        idx_perm_car = randperm(length(local_lbl_car_combined));
                        local_lbl_car_shuf = local_lbl_car_combined(idx_perm_car);
                        
                        idx_perm_lmfit = randperm(length(local_lbl_lmfit_combined));
                        local_lbl_lmfit_shuf = local_lbl_lmfit_combined(idx_perm_lmfit);
                        
                        idx_perm_lmresid = randperm(length(local_lbl_lmresid_combined));
                        local_lbl_lmresid_shuf = local_lbl_lmresid_combined(idx_perm_lmresid);
                        
                        mdl = fitcdiscr(local_X_orig_combined,local_lbl_orig_shuf,'LeaveOut','on');
                        bb_loss_orig_shuf(bb,rr) = kfoldLoss(mdl);
                        
                        mdl = fitcdiscr(local_X_car_combined,local_lbl_car_shuf,'LeaveOut','on');
                        bb_loss_car_shuf(bb,rr) = kfoldLoss(mdl);
                        
                        mdl = fitcdiscr(local_X_lmfit_combined,local_lbl_lmfit_shuf,'LeaveOut','on');
                        bb_loss_lmfit_shuf(bb,rr) = kfoldLoss(mdl);
                        
                        mdl = fitcdiscr(local_X_lmresid_combined,local_lbl_lmresid_shuf,'LeaveOut','on');
                        bb_loss_lmresid_shuf(bb,rr) = kfoldLoss(mdl);
                    end
                end
                
                % place outputs back
                loss_orig{cc}(:,ff) = bb_loss_orig';
                loss_car{cc}(:,ff) = bb_loss_car';
                loss_lmfit{cc}(:,ff) = bb_loss_lmfit';
                loss_lmresid{cc}(:,ff) = bb_loss_lmresid';
                loss_orig_shuf{cc}(:,ff,:) = bb_loss_orig_shuf;
                loss_car_shuf{cc}(:,ff,:) = bb_loss_car_shuf;
                loss_lmfit_shuf{cc}(:,ff,:) = bb_loss_lmfit_shuf;
                loss_lmresid_shuf{cc}(:,ff,:) = bb_loss_lmresid_shuf;
            end
            
            % update loop timer
            lt.iterationEnd;
            [~,msg] = lt.getStats('num_left',C-cc,'msg_format',sprintf('Channel %d/%d: #TOTAL_ELAPSED#; #TOTAL_REMAINING#',cc,C));
            debug.log(msg,'info');
        end
        
        %% plot
        hFigure = plot.MultiPanelFigure('Position',[50 50 1600 1000],'NumRows',4,'NumCols',F);
        hFigure.newLayout('title','Minimum kfoldLoss for time bin vs ITI classification');
        for ff=1:F
            vals_orig = cellfun(@(x)nanmin(x(:,ff)),loss_orig);
            hFigure.stem(1,ff,vals_orig);
            hFigure.text(1,ff,0.1*C,0.05,sprintf('mean %.2f / min %.2f / max %.2f',mean(vals_orig),min(vals_orig),max(vals_orig)),'FontWeight','bold','FontSize',15);
            vals_car = cellfun(@(x)nanmin(x(:,ff)),loss_car);
            hFigure.stem(2,ff,vals_car);
            hFigure.text(2,ff,0.1*C,0.05,sprintf('mean %.2f / min %.2f / max %.2f',mean(vals_car),min(vals_car),max(vals_car)),'FontWeight','bold','FontSize',15);
            vals_lmfit = cellfun(@(x)nanmin(x(:,ff)),loss_lmfit);
            hFigure.stem(3,ff,vals_lmfit);
            hFigure.text(3,ff,0.1*C,0.05,sprintf('mean %.2f / min %.2f / max %.2f',mean(vals_lmfit),min(vals_lmfit),max(vals_lmfit)),'FontWeight','bold','FontSize',15);
            vals_lmresid = cellfun(@(x)nanmin(x(:,ff)),loss_lmresid);
            hFigure.stem(4,ff,vals_lmresid);
            hFigure.text(4,ff,0.1*C,0.05,sprintf('mean %.2f / min %.2f / max %.2f',mean(vals_lmresid),min(vals_lmresid),max(vals_lmresid)),'FontWeight','bold','FontSize',15);
        end
        hFigure.setGroupedYLim('all','minmax');
        title_strings = cellfun(@(x)sprintf('%d-%d Hz',x),freqbands,'UniformOutput',false);
        hFigure.setGroupTitle(title_strings,'toprow');
        ylabel_strings = {...
            {'As Recorded','loss'},...
            {'CAR','loss'},...
            {'LM Fit','loss'},...
            {'LM Residual','loss'}};
        hFigure.setGroupYLabel(ylabel_strings,'leftcolumn');
        hFigure.removeGroupXTickLabel('except','bottomrow');
        hFigure.removeGroupYTickLabel('except','leftcolumn');
        hFigure.setGroupProperties('all','XGrid','on','YGrid','on');
        hFigure.setGroupXLabel('Channel','bottomrow');
        hFigure.setGroupedXLim('all',[1 C]);
        %hFigure.save('outdir',resultdir,'basename',sprintf('%s_vITI_kfoldloss',basename),'formats',{'png','fig'},debug,'overwrite');
        %hFigure.delete;
    end
end