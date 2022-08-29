
%% descriptive data
taskname = 'DelayedReach';
params = Parameters.Dynamic(@Parameters.Config.BasicAnalysis,...
    'dt.mintrialspercat',3);
debug = Debug.Debugger('analysis_20180430');
debug.registerClient('FrameworkTask','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('BLc.Reader','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('plot.save','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
ver = '20180507_v1';

%% create results directory
resultdir = fullfile(env.get('results'),taskname,ver);
if exist(resultdir,'dir')~=7
    [status,msg] = mkdir(resultdir);
    assert(status>=1,'Could not create directory "%s": %s',resultdir,msg);
end

%% loop over all experimental data
experiments = hst.getExperiments(taskname,'p012');
for ee=1%:size(experiments,1)
    pid = experiments.PatientID{ee};
    session = experiments.ExperimentDate(ee);
    taskfiles = hst.getTaskFiles(taskname,session,pid);
    for tt=3%1:length(taskfiles)
        
        %% load task and data objects
        try
            task = FrameworkTask(taskfiles{tt},debug);
        catch ME
            msg = util.errorMessage(ME,'noscreen','nolink');
            [~,taskbase] = fileparts(taskfiles{tt});
            debug.log(sprintf('SKIP "%s": %s',taskbase,msg),'error');
            continue;
        end
        if ~isempty(regexpi(task.userEndComment,'test run')) ||...
                ~isempty(regexpi(task.userEndComment,'do not use')) ||...
                task.numTrials<15
            debug.log(sprintf('SKIP "%s": %s',task.taskString,task.userEndComment),'warn');
            continue;
        end
        debug.log(sprintf('PROCESS "%s": %s',task.taskString,task.userEndComment),'info');
        blc = task.getNeuralDataObject('blc','fs2k');
        blc = blc{1};
        [~,largest_section] = max([blc.DataInfo.NumRecords]);
        map = task.getGridMapObject('fs2k'); map=map{1};
        phnames = task.phaseNames;
        phtimes = [task.phaseTimes sum(task.trialTimes,2)];
        num_trials = find(phtimes(:,end)<=seconds(blc.DataInfo.Duration),1,'last');
        if num_trials<task.numTrials
            debug.log(sprintf('Neural recordings only have enough data for first %d out of %d trials',num_trials,task.numTrials),'warn');
        end
        phtimes = phtimes(1:num_trials,:);
        
        %% get time series
        dt = cell(1,task.numPhases);
        relt = cell(1,task.numPhases);
        for pp=1:task.numPhases
            dt{pp} = arrayfun(@(x)blc.read(...
                'times',phtimes(x,pp:pp+1),...
                'context','section',...
                'section',largest_section),(1:num_trials)','UniformOutput',false);
            relt{pp} = cellfun(@(x,y)(y+(0:(1/blc.SamplingRate):(size(x,1)/blc.SamplingRate-1/blc.SamplingRate)))',dt{pp}(:),arrayfun(@(x)x,phtimes(:,pp),'UniformOutput',false),'UniformOutput',false);
            
            len = cellfun(@(x)size(x,1),dt{pp});
            len = max(len(~isoutlier(len)));
            idx_lt = cellfun(@(x)size(x,1)<=len,dt{pp});
            dt{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2))],dt{pp}(idx_lt),'UniformOutput',false);
            dt{pp}(~idx_lt) = cellfun(@(x)x(1:len,:),dt{pp}(~idx_lt),'UniformOutput',false);
            dt{pp} = cat(3,dt{pp}{:});
            relt{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2))],relt{pp}(idx_lt),'UniformOutput',false);
            relt{pp}(~idx_lt) = cellfun(@(x)x(1:len,:),relt{pp}(~idx_lt),'UniformOutput',false);
            relt{pp} = cellfun(@(x)x-x(1),relt{pp},'UniformOutput',false);
            relt{pp} = cat(2,relt{pp}{:});
            relt{pp} = nanmedian(relt{pp},2);
        end
        phase_end_times = cumsum([0 cellfun(@(x)x(end),relt)]);
        
        %% identify outliers (time domain)
        % use multiples of (Xth percentile) as threshold
        % threshold 1 is a percentage of samples above a relaxed threshold
        % threshold 2 is any incident above a harsh threshold
        % threshold 3 is a (large) percentage of samples below a harsh threshold
        dt_outlier = cat(1,dt{:});
        tile_prc = 90;
        multiple_relaxed = 5;
        samples_relaxed = ceil(0.03*size(dt_outlier,1));
        multiple_harsh = 7;
        samples_harsh = ceil(0.0001*size(dt_outlier,1));
        multiple_low = 0.4;
        samples_low = min(size(dt_outlier,1),ceil(0.8*size(dt_outlier,1)));
        
        % first, apply thresholds 1/2/3 to time series
        tiles_dt = prctile(abs(dt_outlier(:)),tile_prc);
        outlier_dt1 = squeeze(sum(abs(dt_outlier)>multiple_relaxed*tiles_dt))>=samples_relaxed;
        outlier_dt2 = squeeze(nansum(abs(dt_outlier)>=multiple_harsh*tiles_dt))>=samples_harsh;
        outlier_dt3 = squeeze(nansum(abs(dt_outlier)<=multiple_low*tiles_dt))>=samples_low;
        outlier_dt = outlier_dt1 | outlier_dt2 | outlier_dt3;
        
        % next, apply thresholds 1/2 to first difference in time
        ddt_outlier = diff(dt_outlier);
        tiles_ddt = prctile(abs(ddt_outlier(:)),tile_prc);
        outlier_ddt1 = squeeze(sum(abs(ddt_outlier)>multiple_relaxed*tiles_ddt))>=samples_relaxed;
        outlier_ddt2 = squeeze(nansum(abs(ddt_outlier)>=multiple_harsh*tiles_ddt))>=samples_harsh;
        outlier_ddt = outlier_ddt1 | outlier_ddt2;
        
        % outlier indication in either, then organize in cell by channel
        idx_outlier = outlier_dt | outlier_ddt;
        idx_outlier = arrayfun(@(x)idx_outlier(x,:),1:size(idx_outlier,1),'UniformOutput',false);
        
        %% common-average re-reference
        idx_usech = cellfun(@(x)nnz(x)<=0.2*numel(x),idx_outlier);
        for pp=1:task.numPhases
            for cc=1:map.NumChannels
                grid_lbl = map.GridInfo.Label{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)};
                idx_car = map.GridChannelIndex{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)}; % CAR by grid
                idx_car = idx_car(idx_usech(idx_car));
                if isempty(idx_car)
                    debug.log(sprintf('CAR-%d: No channels available in %s for CAR (channel remains unreferenced)',cc,grid_lbl),'info');
                    continue;
                end
                ref = dt{pp}(:,idx_car,~idx_outlier{cc});
                dt{pp}(:,cc,:) = dt{pp}(:,cc,:) - nanmean(ref(:,:),2);
            end
        end
        
        %% compute spectral power
        alldt = blc.read('class','single');
        for cc=1:map.NumChannels
            grid_lbl = map.GridInfo.Label{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)};
            idx_car = map.GridChannelIndex{map.GridInfo.GridNumber==map.ChannelInfo.GridNumber(cc)}; % CAR by grid
            idx_car = idx_car(idx_usech(idx_car));
            if isempty(idx_car)
                debug.log(sprintf('CAR-%d: No channels available in %s for CAR (channel remains unreferenced)',cc,grid_lbl),'info');
                continue;
            end
            ref = alldt(:,idx_car);
            alldt(:,cc) = alldt(:,cc) - nanmean(ref,2);
        end
        chr_params = struct('tapers',[5 9],'trialave',false,'Fs',blc.SamplingRate,'pad',1,'fpass',[0 500]);
        chr_movingwin = [0.25 0.05];
        [S,t,f] = chronux_gpu.ct.mtspecgramc(alldt,chr_movingwin,chr_params);
        t = t + (chr_movingwin(1)-t(1)); % moving the timestamp to the end of the time bin
        dtfreq = cell(1,task.numPhases);
        reltfreq = cell(1,task.numPhases);
        for pp=1:task.numPhases
            dtfreq{pp} = cell(1,num_trials);
            dtfreq{pp} = cell(1,num_trials);
            for rr=1:num_trials
                idx_trial = t>=phtimes(rr,pp) & t<=phtimes(rr,pp+1);
                dtfreq{pp}{rr} = S(idx_trial,:,:);
                reltfreq{pp}{rr} = t(idx_trial)';
            end
            
            len = cellfun(@(x)size(x,1),dtfreq{pp});
            len = max(len(~isoutlier(len)));
            idx_lt = cellfun(@(x)size(x,1)<=len,dtfreq{pp});
            dtfreq{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2),size(x,3))],dtfreq{pp}(idx_lt),'UniformOutput',false);
            dtfreq{pp}(~idx_lt) = cellfun(@(x)x(1:len,:,:),dtfreq{pp}(~idx_lt),'UniformOutput',false);
            dtfreq{pp} = cat(4,dtfreq{pp}{:});
            reltfreq{pp}(idx_lt) = cellfun(@(x)[x; nan(len-size(x,1),size(x,2))],reltfreq{pp}(idx_lt),'UniformOutput',false);
            reltfreq{pp}(~idx_lt) = cellfun(@(x)x(1:len,:),reltfreq{pp}(~idx_lt),'UniformOutput',false);
            reltfreq{pp} = cellfun(@(x)x-x(1),reltfreq{pp},'UniformOutput',false);
            reltfreq{pp} = cat(2,reltfreq{pp}{:});
            reltfreq{pp} = nanmedian(reltfreq{pp},2);
        end
        
        % convert to dB
        dtfreq = cellfun(@(x)10*log10(x),dtfreq,'UniformOutput',false);
        
        %% identify outliers (freq domain)
        % use multiples of (Xth-Yth percentile) as threshold
        % threshold 1 is a percentage of samples above a relaxed threshold
        % threshold 2 is any incident above a harsh threshold
        idx_outlier_freq = cell(1,map.NumGrids);
        for gg=1:map.NumGrids
            dtfreq_outlier = cellfun(@(x)squeeze(x(:,:,map.GridChannelIndex{gg},:)),dtfreq,'UniformOutput',false);
            dtfreq_outlier = cat(1,dtfreq_outlier{:});
            tile_prc = [25 75];
            multiple_relaxed = 5;
            samples_relaxed = ceil(0.05*size(dtfreq_outlier,1));
            multiple_harsh = 7;
            samples_harsh = ceil(0.0001*size(dtfreq_outlier,1));
            
            % first, apply thresholds 1/2/3 to time series
            dtfreq_outlier = permute(dtfreq_outlier,[2 1 3 4]);
            tiles_dtfreq = prctile(dtfreq_outlier(:,:),tile_prc,2);
            iq_dtfreq = diff(tiles_dtfreq,1,2);
            outlier_dtfreq1 = squeeze(nansum(dtfreq_outlier>(tiles_dtfreq(:,2)+multiple_relaxed*iq_dtfreq),2))>=samples_relaxed;
            outlier_dtfreq2 = squeeze(nansum(dtfreq_outlier>(tiles_dtfreq(:,2)+multiple_harsh*iq_dtfreq),2))>=samples_harsh;
            outlier_dtfreq = outlier_dtfreq1 | outlier_dtfreq2;
            
            % nice animated figure
            figure('Position',[400 400 800 300])
            for kk=1:length(f)
                subplot(121);
                imagesc(squeeze(outlier_dtfreq1(kk,:,:))); title(sprintf('freq %d/%d (%.2f Hz)',kk,length(f),f(kk)));
                subplot(122);
                imagesc(squeeze(outlier_dtfreq2(kk,:,:))); title(sprintf('freq %d/%d (%.2f Hz)',kk,length(f),f(kk)));
                pause(0.05);
            end
            
            % outlier indication in either, then organize in cell by channel
            idx_outlier_freq{gg} = outlier_dtfreq;
            idx_outlier_freq{gg} = arrayfun(@(x)squeeze(idx_outlier_freq{gg}(:,x,:)),1:length(map.GridChannelIndex{gg}),'UniformOutput',false);
        end
        idx_outlier_freq = cat(2,idx_outlier_freq{:});
        
        %% plot the whole trial data IDENTIFYING OUTLIERS
        
        % metadata for plotting
        phlen = cellfun(@(x)x(end),relt);
        totlen = sum(phlen);
        prclen = phlen/totlen;
        figpos = [100 100 1800 600];
        margin_left = 0.04;
        margin_bottom = 0.10;
        margin_top = 0.09;
        margin_right = 0.01;
        axes_spacing = 0.01;
        avail_width = 1 - margin_left - margin_right - (length(phlen)-1)*axes_spacing;
        axes_width = prclen*avail_width;
        axes_left = cumsum([margin_left axes_width(1:end-1)+axes_spacing]);
        
        % set up colors
        clr_trialavg = [0.2 0.2 0.2];
        clr_trials = [0.5 0.5 0.5];
        clr_outliers = [0.8 0.8 0.8];
        
        fig = figure('Position',figpos,'PaperPositionMode','auto');
        for cc=1:blc.ChannelCount
            flag_hasoutliers = any(idx_outlier{cc});
            flag_hasnormal = any(~idx_outlier{cc});
        
            grid_number = map.ChannelInfo.GridNumber(cc);
            grid_location = map.GridInfo.Location{map.GridInfo.GridNumber==grid_number};
            grid_hemisphere = map.GridInfo.Hemisphere{map.GridInfo.GridNumber==grid_number};
            grid_electrode = map.ChannelInfo.GridElectrode(cc);
            channel_label = map.ChannelInfo.Label{cc};
        
            figid_long = 'Outliers - Time';
            figid_short = 'outliers_time';
            basename = sprintf('%s--%s--%s--%s',pid,task.taskString,channel_label,figid_short);
            figname = sprintf('%s: %s (%s %s %d) (%s)',pid,task.taskString,grid_hemisphere,grid_location,grid_electrode,figid_long);
            debug.log(sprintf('%s / %s: Processing channel %s %d/%d (%s)',pid,task.taskString,channel_label,cc,blc.ChannelCount,figid_long),'info');
        
            clf;
            ax_title = axes('Position',[margin_left 1-margin_top+0.03 1-margin_left-margin_right axes_spacing]);
            title(ax_title,figname);
            set(ax_title,'Visible','off'); % axes is just there so we can use title
            set(findall(ax_title,'type','text'),'Visible','on');
        
            ax = arrayfun(@(x)axes('Position',[axes_left(x) margin_bottom axes_width(x) 1-margin_bottom-margin_top]),1:length(phnames),'UniformOutput',false);
            ax = cat(1,ax{:});
            yl = nan(length(ax),2);
            for pp=1:length(phnames)
        
                % for y-limits
                if flag_hasnormal
                    plot(ax(pp),phase_end_times(pp)+relt{pp},squeeze(dt{pp}(:,cc,~idx_outlier{cc})),'Color',clr_trials);
                elseif flag_hasoutliers
                    plot(ax(pp),phase_end_times(pp)+relt{pp},squeeze(dt{pp}(:,cc,idx_outlier{cc})),'Color',clr_outliers);
                end
                yl(pp,:) = get(ax(pp),'ylim');
        
                % for legend
                cla(ax(pp));
                hold(ax(pp),'on');
                if pp==length(phnames)
                    if flag_hasoutliers
                        plot(ax(pp),phase_end_times(pp)+relt{pp},dt{pp}(:,cc,find(idx_outlier{cc},1,'first')),'Color',clr_outliers);
                    end
                    if flag_hasnormal
                        plot(ax(pp),phase_end_times(pp)+relt{pp},dt{pp}(:,cc,find(~idx_outlier{cc},1,'first')),'Color',clr_trials);
                        plot(ax(pp),phase_end_times(pp)+relt{pp},nanmean(squeeze(dt{pp}(:,cc,~idx_outlier{cc})),2),'Color',clr_trialavg,'LineWidth',2);
                    end
                end
        
                % normal plotting
                if flag_hasoutliers
                    plot(ax(pp),phase_end_times(pp)+relt{pp},squeeze(dt{pp}(:,cc,idx_outlier{cc})),'Color',clr_outliers);
                end
                if flag_hasnormal
                    plot(ax(pp),phase_end_times(pp)+relt{pp},squeeze(dt{pp}(:,cc,~idx_outlier{cc})),'Color',clr_trials);
                    plot(ax(pp),phase_end_times(pp)+relt{pp},nanmean(squeeze(dt{pp}(:,cc,~idx_outlier{cc})),2),'Color',clr_trialavg,'LineWidth',2);
                end
                xlim(ax(pp),phase_end_times(pp)+relt{pp}([1 end]));
                xlabel(ax(pp),'Time (sec)');
                title(ax(pp),phnames{pp});
                if pp==1
                    ylabel(ax(pp),'Amplitude (uV)');
                else
                    set(ax(pp),'YTick',[]);
                end
            end
            yl = [min(yl(:,1)) max(yl(:,2))];
            arrayfun(@(x)ylim(x,yl),ax);
            if flag_hasoutliers && flag_hasnormal
                legend(ax(end),{sprintf('outliers (N=%d)',nnz(idx_outlier{cc})),sprintf('trials (N=%d)',nnz(~idx_outlier{cc})),'trial average'});
            elseif flag_hasoutliers
                legend(ax(end),{sprintf('outliers (N=%d)',nnz(idx_outlier{cc}))});
            else
                legend(ax(end),{sprintf('trials (N=%d)',nnz(~idx_outlier{cc})),'trial average'});
            end
            set(fig,'Name',figname);
            plot.save(fig,'outdir',resultdir,'basename',basename,'formats',{'png','fig'},'overwrite',debug);
        end
        close(fig);
        
        %% same but in frequency domain
        freqbands = {[1 12],[12 30],[30 80],[80 200],[200 500]};
        
        % metadata for plotting
        phlen = cellfun(@(x)x(end),relt);
        totlen = sum(phlen);
        prclen = phlen/totlen;
        figpos = [100 100 1800 600];
        margin_left = 0.04;
        margin_bottom = 0.07;
        margin_top = 0.08;
        margin_right = 0.01;
        axes_spacing = 0.01;
        avail_width = 1 - margin_left - margin_right - (length(phlen)-1)*axes_spacing;
        axes_width = prclen*avail_width;
        axes_left = cumsum([margin_left axes_width(1:end-1)+axes_spacing]);
        axes_bottom = linspace(margin_bottom,1-margin_top,length(freqbands)+1);
        axes_height = median(diff(axes_bottom))-axes_spacing;
        
        % set up colors
        clr_trialavg = [0.2 0.2 0.2];
        clr_trials = [0.5 0.5 0.5];
        clr_outliers = [0.8 0.8 0.8];
        
        fig = figure('Position',[50 50 1800 1000],'PaperPositionMode','auto');
        for cc=1:blc.ChannelCount
            
            grid_number = map.ChannelInfo.GridNumber(cc);
            grid_location = map.GridInfo.Location{map.GridInfo.GridNumber==grid_number};
            grid_hemisphere = map.GridInfo.Hemisphere{map.GridInfo.GridNumber==grid_number};
            grid_electrode = map.ChannelInfo.GridElectrode(cc);
            channel_label = map.ChannelInfo.Label{cc};
            
            figid_long = 'Outliers - Frequency';
            figid_short = 'outliers_freq';
            basename = sprintf('%s--%s--%s--%s',pid,task.taskString,channel_label,figid_short);
            figname = sprintf('%s: %s (%s %s %d) (%s)',pid,task.taskString,grid_hemisphere,grid_location,grid_electrode,figid_long);
            debug.log(sprintf('%s / %s: Processing channel %s %d/%d (%s)',pid,task.taskString,channel_label,cc,blc.ChannelCount,figid_long),'info');
            
            clf;
            ax_title = axes('Position',[margin_left 1-margin_top+0.03 1-margin_left-margin_right axes_spacing]);
            title(ax_title,figname);
            set(ax_title,'Visible','off'); % axes is just there so we can use title
            set(findall(ax_title,'type','text'),'Visible','on');
            
            for bb=1:length(freqbands)
                idx_freqband = f>=freqbands{bb}(1) & f<=freqbands{bb}(2);
                local_dtfreq = cellfun(@(x)squeeze(nanmean(x(:,idx_freqband,cc,:),2)),dtfreq,'UniformOutput',false);
                local_outlier = sum(idx_outlier_freq{cc}(idx_freqband,:),1)>=0.01*nnz(idx_freqband);
                flag_hasoutliers = any(local_outlier);
                flag_hasnormal = any(~local_outlier);
                
                ax = arrayfun(@(x)axes('Position',[axes_left(x) axes_bottom(bb) axes_width(x) axes_height]),1:length(phnames),'UniformOutput',false);
                ax = cat(1,ax{:});
                yl = nan(length(ax),2);
                for pp=1:length(phnames)
                    
                    % for y-limits
                    if flag_hasnormal
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},squeeze(local_dtfreq{pp}(:,~local_outlier)),'Color',clr_trials);
                    elseif flag_hasoutliers
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},squeeze(local_dtfreq{pp}(:,local_outlier)),'Color',clr_outliers);
                    end
                    yl(pp,:) = get(ax(pp),'ylim');
                    
                    % for legend
                    cla(ax(pp));
                    hold(ax(pp),'on');
                    if pp==length(phnames)
                        if flag_hasoutliers
                            plot(ax(pp),phase_end_times(pp)+reltfreq{pp},local_dtfreq{pp}(:,find(local_outlier,1,'first')),'Color',clr_outliers);
                        end
                        if flag_hasnormal
                            plot(ax(pp),phase_end_times(pp)+reltfreq{pp},local_dtfreq{pp}(:,find(~local_outlier,1,'first')),'Color',clr_trials);
                            plot(ax(pp),phase_end_times(pp)+reltfreq{pp},nanmean(squeeze(local_dtfreq{pp}(:,~local_outlier)),2),'Color',clr_trialavg,'LineWidth',2);
                        end
                    end
                    
                    % normal plotting
                    if flag_hasoutliers
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},squeeze(local_dtfreq{pp}(:,local_outlier)),'Color',clr_outliers);
                    end
                    if flag_hasnormal
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},squeeze(local_dtfreq{pp}(:,~local_outlier)),'Color',clr_trials);
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},nanmean(squeeze(local_dtfreq{pp}(:,~local_outlier)),2),'Color',clr_trialavg,'LineWidth',2);
                    end
                    xlim(ax(pp),phase_end_times(pp)+reltfreq{pp}([1 end]));
                    if bb==1
                        xlabel(ax(pp),'Time (sec)');
                    else
                        set(ax(pp),'XTick',[]);
                    end
                    if bb==length(freqbands)
                        title(ax(pp),phnames{pp});
                    end
                    if pp==1
                        ylabel(ax(pp),sprintf('%d-%d Hz (dB)',freqbands{bb}(1),freqbands{bb}(2)));
                    else
                        set(ax(pp),'YTick',[]);
                    end
                end
                yl = [min(yl(:,1)) max(yl(:,2))];
                arrayfun(@(x)ylim(x,yl),ax);
                if flag_hasoutliers && flag_hasnormal
                    legend(ax(end),{sprintf('outliers (N=%d)',nnz(local_outlier)),sprintf('trials (N=%d)',nnz(~local_outlier)),'trial average'});
                elseif flag_hasoutliers
                    legend(ax(end),{sprintf('outliers (N=%d)',nnz(local_outlier))});
                else
                    legend(ax(end),{sprintf('trials (N=%d)',nnz(~local_outlier)),'trial average'});
                end
            end
            set(fig,'Name',figname);
            plot.save(fig,'outdir',resultdir,'basename',basename,'formats',{'png','fig'},'overwrite',debug);
        end
        close(fig);
        
        %% get trial grouping data
        try
            [trgroup,grouplbl,shortname,longname] = TaskAnalysis.DelayedReach.groupTrialsByTarget(task,params);
        catch ME
            msg = util.errorMessage(ME,'nolink','noscreen');
            debug.log(sprintf('Skip target group plots: %s',msg),'warn');
            continue;
        end
        trgroup = cellfun(@(x)x(x<=num_trials),trgroup,'UniformOutput',false);
        
        %% group by target (time domain)
        phlen = cellfun(@(x)x(end),relt);
        totlen = sum(phlen);
        prclen = phlen/totlen;
        figpos = [100 100 1800 600];
        margin_left = 0.04;
        margin_bottom = 0.10;
        margin_top = 0.09;
        margin_right = 0.01;
        axes_spacing = 0.01;
        avail_width = 1 - margin_left - margin_right - (length(phlen)-1)*axes_spacing;
        axes_width = prclen*avail_width;
        axes_left = cumsum([margin_left axes_width(1:end-1)+axes_spacing]);
        
        fig = figure('Position',figpos,'PaperPositionMode','auto');
        for cc=1:blc.ChannelCount
            
            % meta data info on grid/channel
            grid_number = map.ChannelInfo.GridNumber(cc);
            grid_location = map.GridInfo.Location{map.GridInfo.GridNumber==grid_number};
            grid_hemisphere = map.GridInfo.Hemisphere{map.GridInfo.GridNumber==grid_number};
            grid_electrode = map.ChannelInfo.GridElectrode(cc);
            channel_label = map.ChannelInfo.Label{cc};
            
            % make sure some trials left
            if all(idx_outlier{cc})
                debug.log(sprintf('%s / %s: Skip channel %s %d/%d (all trials classified as outliers)',pid,task.taskString,channel_label,cc,blc.ChannelCount),'info');
                continue;
            end
            
            % apply outlier removal and check num trials per group
            local_grouplbl = grouplbl;
            local_trgroup = cellfun(@(x)x(ismember(x,find(~idx_outlier{cc}))),trgroup,'UniformOutput',false);
            num_pergroup = cellfun(@length,local_trgroup);
            local_trgroup(num_pergroup<2) = [];
            local_grouplbl(num_pergroup<2) = [];
            if isempty(local_trgroup)
                debug.log(sprintf('%s / %s: Skip channel %s %d/%d (not enough trials per group)',pid,task.taskString,channel_label,cc,blc.ChannelCount),'info');
                continue;
            end
            
            % colors for groups
            clrs_primary = copper(length(local_trgroup));
            clrs_faded = clrs_primary;
            for kk=1:size(clrs_faded,1)
                hsl = util.rgb2hsl(clrs_faded(kk,:));
                hsl(2) = 0.2;
                hsl(3) = 0.85;
                clrs_faded(kk,:) = util.hsl2rgb(hsl);
            end
            
            % set up labeling
            figid_long = 'Target Grouped - Time';
            figid_short = 'tgtgrp_time';
            basename = sprintf('%s--%s--%s--%s',pid,task.taskString,channel_label,figid_short);
            figname = sprintf('%s: %s (%s %s %d) (%s)',pid,task.taskString,grid_hemisphere,grid_location,grid_electrode,figid_long);
            debug.log(sprintf('%s / %s: Processing channel %s %d/%d (%s)',pid,task.taskString,channel_label,cc,blc.ChannelCount,figid_long),'info');
            
            % create figure/axes
            clf;
            ax_title = axes('Position',[margin_left 1-margin_top+0.03 1-margin_left-margin_right axes_spacing]);
            title(ax_title,figname);
            set(ax_title,'Visible','off'); % axes is just there so we can use title
            set(findall(ax_title,'type','text'),'Visible','on');
            
            % plot
            ax = arrayfun(@(x)axes('Position',[axes_left(x) margin_bottom axes_width(x) 1-margin_bottom-margin_top]),1:length(phnames),'UniformOutput',false);
            ax = cat(1,ax{:});
            for pp=1:length(phnames)
                hold(ax(pp),'on');
                
                % for legend
                if pp==length(phnames)
                    for gg=1:length(local_trgroup)
                        plot(ax(pp),phase_end_times(pp)+relt{pp},nanmean(squeeze(dt{pp}(:,cc,local_trgroup{gg})),2),'Color',clrs_primary(gg,:),'LineWidth',2);
                    end
                end
                
                % normal plotting
                for gg=1:length(local_trgroup)
                    plot(ax(pp),phase_end_times(pp)+relt{pp},squeeze(dt{pp}(:,cc,local_trgroup{gg})),'Color',clrs_faded(gg,:));
                end
                for gg=1:length(local_trgroup)
                    plot(ax(pp),phase_end_times(pp)+relt{pp},nanmean(squeeze(dt{pp}(:,cc,local_trgroup{gg})),2),'Color',clrs_primary(gg,:),'LineWidth',2);
                end
                
                % labeling/limits
                xlim(ax(pp),phase_end_times(pp)+relt{pp}([1 end]));
                xlabel(ax(pp),'Time (sec)');
                title(ax(pp),phnames{pp});
                if pp==1
                    ylabel(ax(pp),'Amplitude (uV)');
                else
                    set(ax(pp),'YTick',[]);
                end
            end
            yl = arrayfun(@(x)ylim(x),ax,'UniformOutput',false);
            yl = cat(1,yl{:});
            yl = [min(yl(:,1)) max(yl(:,2))];
            arrayfun(@(x)ylim(x,yl),ax);
            legend(ax(end),arrayfun(@(x,y)sprintf('target %d (N=%d)',x,y),local_grouplbl,cellfun(@length,local_trgroup),'UniformOutput',false));
            set(fig,'Name',figname);
            plot.save(fig,'outdir',resultdir,'basename',basename,'formats',{'png','fig'},'overwrite',debug);
        end
        close(fig);
        
        %% group by target (frequency domain)
        freqbands = {[1 12],[12 30],[30 80],[80 200],[200 500]};
        
        % metadata for plotting
        phlen = cellfun(@(x)x(end),relt);
        totlen = sum(phlen);
        prclen = phlen/totlen;
        figpos = [100 100 1800 600];
        margin_left = 0.04;
        margin_bottom = 0.07;
        margin_top = 0.08;
        margin_right = 0.01;
        axes_spacing = 0.01;
        avail_width = 1 - margin_left - margin_right - (length(phlen)-1)*axes_spacing;
        axes_width = prclen*avail_width;
        axes_left = cumsum([margin_left axes_width(1:end-1)+axes_spacing]);
        axes_bottom = linspace(margin_bottom,1-margin_top,length(freqbands)+1);
        axes_height = median(diff(axes_bottom))-axes_spacing;
        
        % colors for groups
        clrs_primary = copper(length(trgroup));
        clrs_faded = clrs_primary;
        for kk=1:size(clrs_faded,1)
            hsl = util.rgb2hsl(clrs_faded(kk,:));
            hsl(2) = 0.2;
            hsl(3) = 0.85;
            clrs_faded(kk,:) = util.hsl2rgb(hsl);
        end
        
        fig = figure('Position',[50 50 1800 1000],'PaperPositionMode','auto');
        for cc=1:blc.ChannelCount
            
            grid_number = map.ChannelInfo.GridNumber(cc);
            grid_location = map.GridInfo.Location{map.GridInfo.GridNumber==grid_number};
            grid_hemisphere = map.GridInfo.Hemisphere{map.GridInfo.GridNumber==grid_number};
            grid_electrode = map.ChannelInfo.GridElectrode(cc);
            channel_label = map.ChannelInfo.Label{cc};
            
            % set up labeling
            figid_long = 'Target Grouped - Frequency';
            figid_short = 'tgtgrp_freq';
            basename = sprintf('%s--%s--%s--%s',pid,task.taskString,channel_label,figid_short);
            figname = sprintf('%s: %s (%s %s %d) (%s)',pid,task.taskString,grid_hemisphere,grid_location,grid_electrode,figid_long);
            debug.log(sprintf('%s / %s: Processing channel %s %d/%d (%s)',pid,task.taskString,channel_label,cc,blc.ChannelCount,figid_long),'info');
            
            clf;
            ax_title = axes('Position',[margin_left 1-margin_top+0.03 1-margin_left-margin_right axes_spacing]);
            title(ax_title,figname);
            set(ax_title,'Visible','off'); % axes is just there so we can use title
            set(findall(ax_title,'type','text'),'Visible','on');
            
            for bb=1:length(freqbands)
                idx_freqband = f>=freqbands{bb}(1) & f<=freqbands{bb}(2);
                local_dtfreq = cellfun(@(x)squeeze(nanmean(x(:,idx_freqband,cc,:),2)),dtfreq,'UniformOutput',false);
                local_outlier = sum(idx_outlier_freq{cc}(idx_freqband,:),1)>=0.01*nnz(idx_freqband);
                
                % apply outlier removal and check num trials per group
                local_grouplbl = grouplbl;
                local_trgroup = cellfun(@(x)x(ismember(x,find(~local_outlier))),trgroup,'UniformOutput',false);
                num_pergroup = cellfun(@length,local_trgroup);
                idx_trgroup = num_pergroup>=2;
                local_trgroup(~idx_trgroup) = [];
                local_grouplbl(~idx_trgroup) = [];
                if isempty(local_trgroup)
                    debug.log(sprintf('%s / %s: Skip channel %s %d/%d (not enough trials per group)',pid,task.taskString,channel_label,cc,blc.ChannelCount),'info');
                    continue;
                end
                idx_trgroup = find(idx_trgroup);
                
                ax = arrayfun(@(x)axes('Position',[axes_left(x) axes_bottom(bb) axes_width(x) axes_height]),1:length(phnames),'UniformOutput',false);
                ax = cat(1,ax{:});
                yl = nan(length(ax),2);
                for pp=1:length(phnames)
                    
                    % for y-limits
                    plot(ax(pp),phase_end_times(pp)+reltfreq{pp},local_dtfreq{pp});
                    yl(pp,:) = get(ax(pp),'ylim');
                    
                    % for legend
                    cla(ax(pp));
                    hold(ax(pp),'on');
                    if bb==length(freqbands) && pp==length(phnames)
                        for gg=1:length(local_trgroup)
                            plot(ax(pp),phase_end_times(pp)+reltfreq{pp},nanmean(local_dtfreq{pp}(:,local_trgroup{gg}),2),'Color',clrs_primary(idx_trgroup(gg),:),'LineWidth',2);
                        end
                    end
                    
                    % normal plotting
                    for gg=1:length(local_trgroup)
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},squeeze(local_dtfreq{pp}(:,local_trgroup{gg})),'Color',clrs_faded(idx_trgroup(gg),:));
                    end
                    for gg=1:length(local_trgroup)
                        plot(ax(pp),phase_end_times(pp)+reltfreq{pp},nanmean(squeeze(local_dtfreq{pp}(:,local_trgroup{gg})),2),'Color',clrs_primary(idx_trgroup(gg),:),'LineWidth',2);
                    end
                    
                    % labeling/limits
                    xlim(ax(pp),phase_end_times(pp)+reltfreq{pp}([1 end]));
                    if bb==1
                        xlabel(ax(pp),'Time (sec)');
                    else
                        set(ax(pp),'XTick',[]);
                    end
                    if bb==length(freqbands)
                        title(ax(pp),phnames{pp});
                    end
                    if pp==1
                        ylabel(ax(pp),sprintf('%d-%d Hz (dB)',freqbands{bb}(1),freqbands{bb}(2)));
                    else
                        set(ax(pp),'YTick',[]);
                    end
                end
                yl = [min(yl(:,1)) max(yl(:,2))];
                arrayfun(@(x)ylim(x,yl),ax);
                if bb==length(freqbands)
                    legend(ax(end),arrayfun(@(x,y)sprintf('target %d (N=%d)',x,y),local_grouplbl,cellfun(@length,local_trgroup),'UniformOutput',false));
                end
            end
            set(fig,'Name',figname);
            plot.save(fig,'outdir',resultdir,'basename',basename,'formats',{'png','fig'},'overwrite',debug);
        end
        close(fig);
    end
end