
%% descriptive data
analysis_name = 'noise_reduction';
pid = 'p010';
ver = sprintf('20180526_%s',pid);
params = Parameters.Dynamic(@Parameters.Config.BasicAnalysis,...
    'dt.mintrialspercat',3,...
    'dt.lmtype','lmresid');
debug = Debug.Debugger(sprintf('%s_%s',analysis_name,ver));
debug.registerClient('FrameworkTask','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('BLc.Reader','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
debug.registerClient('plot.save','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);

%% create results directory
resultdir = fullfile(env.get('results'),analysis_name,ver);
if exist(resultdir,'dir')~=7
    [status,msg] = mkdir(resultdir);
    assert(status>=1,'Could not create directory "%s": %s',resultdir,msg);
end

%% loop over all experimental data and generate descriptive plots
experiments = hst.getExperiments(pid);
E = size(experiments,1);
freqbands = {[0 4],[4 8],[8 12],[12 30],[30 80],[80 200]};
F = length(freqbands);
for ee=1:E
    session = experiments.ExperimentDate(ee);
    taskname = experiments.ExperimentName{ee};
    taskfiles = hst.getTaskFiles(taskname,session,pid);
    T = length(taskfiles);
    for tt=1:T
        
        % acquire/validate resources
        taskfile = taskfiles{tt};
        [~,taskbase] = fileparts(taskfile);
        try
            lmtype = params.dt.lmtype;
            [task,blc_orig,map] = proc.helper.getAnalysisObjects(taskfile,debug,'neural_data_lm','none');
            blc_lmresid = task.getNeuralDataObject('lmresid','fs2k'); blc_lmresid=blc_lmresid{1};
            blc_lmfit = task.getNeuralDataObject('lmfit','fs2k'); blc_lmfit=blc_lmfit{1};
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
        G = map.NumGrids;
        basename = task.taskString;
        
        % first-pass analysis
        a_orig = BLc.Analyze(blc_orig,map,debug);
        fig_psd = a_orig.boxplot;
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_orig-boxplot',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        fig_psd = a_orig.corrmat;
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_orig-corrmat',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        a_lmresid = BLc.Analyze(blc_lmresid,map,debug);
        fig_psd = a_lmresid.boxplot;
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_lmresid-boxplot',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        fig_psd = a_lmresid.corrmat;
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_lmresid-corrmat',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        a_lmfit = BLc.Analyze(blc_lmfit,map,debug);
        fig_psd = a_lmfit.boxplot;
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_lmfit-boxplot',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        fig_psd = a_lmfit.corrmat;
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_lmfit-corrmat',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        
        % read neural data
        [~,section] = max([blc_orig.DataInfo.Duration]);
        debug.log(sprintf('ex %d/%d, tk %d/%d: Reading neural data from section %d of the BLc file',ee,E,tt,T,section),'info');
        dt = blc_orig.read('section',section,'context','section');
        dtr = blc_lmresid.read('section',section,'context','section');
        dtf = blc_lmfit.read('section',section,'context','section');
        C = size(dt,2);
        assert(C==map.NumChannels,'Wrong number of channels read from BLc file (map file indicates %d, but read %d)',map.NumChannels,C);
        
        % plot x-corr matrices before/after linear model
        [~,section] = max([blc_orig.DataInfo.Duration]);
        rho_orig = corrcoef(dt,'rows','complete');
        rho_resid = corrcoef(dtr,'rows','complete');
        rho_fit = corrcoef(dtf,'rows','complete');
        fig_psd = figure(...
            'PaperPositionMode','auto',...
            'Position',[80 80 1500 900],...
            'Name','corrmat');
        ax = [axes('Position',[0.15 0.56 0.38 0.38]) ...
            axes('Position',[0.56 0.56 0.38 0.38]) ...
            axes('Position',[0.15 0.15 0.38 0.38])];
        imagesc(ax(1),rho_orig);
        imagesc(ax(2),rho_resid);
        imagesc(ax(3),rho_fit);
        set(ax(1),'CLim',[-1 1]);
        set(ax(2),'CLim',[-1 1]);
        set(ax(3),'CLim',[-1 1]);
        h = colorbar('peer',ax(2));
        ylabel(h,'Correlation Coefficient');
        set(get(h,'ylabel'),'rotation',270);
        set(h,'YTick',[-1 1]);
        ticks = cell(1,map.NumGrids);
        lbls = cell(1,map.NumGrids);
        for gg=1:map.NumGrids
            ch = map.GridChannelIndex{gg};
            gridlbl = map.GridInfo.Label{gg};
            if length(ch)<20
                ticks{gg} = mean(ch);
                lbls{gg} = {sprintf('%s %d-%d',gridlbl,ch(1),ch(end))};
            else
                ticks{gg} = [ch(1) mean(ch)];
                lbls{gg} = {sprintf('%s-1',gridlbl),sprintf('%s %d-%d',gridlbl,ch(1),ch(end))};
            end
        end
        ticks = cat(2,ticks{:});
        ticks = ticks(:);
        lbls = cat(2,lbls{:});
        set(ax,'TickLabelInterpreter','none');
        set(ax([1 3]),'YTick',ticks,'YTickLabels',lbls);
        set(ax(2),'YTick',[],'YTickLabels',{' '});
        set(ax([2 3]),'XTick',ticks,'XTickLabels',lbls,'XTickLabelRotation',45);
        set(ax(1),'XTick',[],'XTickLabels',{' '});
        title(ax(1),['\bf{x-corr (original)}' newline '\rm{tick marks centered on grid channels}'])
        title(ax(2),'\bf{x-corr (residual)}')
        title(ax(3),'\bf{x-corr (fitted)}')
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_xcorr',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        
        % compute spectrogram before/after
        movingwin = [2 0.2];
        params_chr = struct('Fs',blc_orig.SamplingRate,'fpass',[0 200],'tapers',[5 9],'trialave',false,'pad',2);
        debug.log(sprintf('ex %d/%d, tk %d/%d: Computing spectrogram for raw data',ee,E,tt,T),'info');
        [dt_orig,t_orig,f_orig] = chronux_gpu.ct.mtspecgramc(dt,movingwin,params_chr);
        debug.log(sprintf('ex %d/%d, tk %d/%d: Computing spectrogram for model residual data',ee,E,tt,T),'info');
        [S_res,t_res,f_res] = chronux_gpu.ct.mtspecgramc(dtr,movingwin,params_chr);
        debug.log(sprintf('ex %d/%d, tk %d/%d: Computing spectrogram for model fitted data',ee,E,tt,T),'info');
        [S_fit,t_fit,f_fit] = chronux_gpu.ct.mtspecgramc(dtf,movingwin,params_chr);
        
        % plot spectrograms before/after
        debug.log(sprintf('ex %d/%d, tk %d/%d: Plotting spectrograms for each channel',ee,E,tt,T),'info');
        fig_psd = figure(...
            'PaperPositionMode','auto',...
            'Position',[100 100 1700 500],...
            'Name','specgram');
        ax = [subplot(131); subplot(132); subplot(133)];
        for cc=1:C
            debug.log(sprintf('Plotting spectrograms for channel %d/%d (%s)',cc,C,map.ChannelInfo.Label{cc}),'info');
            cla(ax(1)); cla(ax(2)); cla(ax(3));
            imagesc(ax(1),t_orig,f_orig,10*log10(dt_orig(:,:,cc))'); axis(ax(1),'xy');
            imagesc(ax(2),t_res,f_res,10*log10(S_res(:,:,cc))'); axis(ax(2),'xy');
            imagesc(ax(3),t_fit,f_fit,10*log10(S_fit(:,:,cc))'); axis(ax(3),'xy');
            ylabel(ax(1),'Frequency (Hz)');
            xlabel(ax(1),'Time (sec)');
            xlabel(ax(2),'Time (sec)');
            xlabel(ax(3),'Time (sec)');
            title(ax(1),sprintf('Channel %d (%s - original)',cc,map.ChannelInfo.Label{cc}),'Interpreter','none');
            title(ax(2),sprintf('Channel %d (%s - residual)',cc,map.ChannelInfo.Label{cc}),'Interpreter','none');
            title(ax(3),sprintf('Channel %d (%s - fitted)',cc,map.ChannelInfo.Label{cc}),'Interpreter','none');
            h1 = colorbar('peer',ax(1));
            t1 = ylabel(h1,'Power (dB)');
            t1.Position(1) = t1.Position(1) + 0.5;
            set(t1,'rotation',270);
            h2 = colorbar('peer',ax(2));
            t2 = ylabel(h2,'Power (dB)');
            t2.Position(1) = t2.Position(1) + 0.5;
            t2.Position(2) = t1.Position(2);
            set(t2,'rotation',270);
            h3 = colorbar('peer',ax(3));
            t3 = ylabel(h3,'Power (dB)');
            t3.Position(1) = t3.Position(1) + 0.5;
            t3.Position(2) = t1.Position(2);
            set(t3,'rotation',270);
            cl1 = get(ax(1),'CLim');
            cl2 = get(ax(2),'CLIm');
            cl3 = get(ax(3),'CLIm');
            cl = [min(cl1(1),min(cl2(1),cl3(1))) max(cl1(2),max(cl2(2),cl3(2)))];
            set(ax,'CLim',cl);
            plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_specgram_chan%02d',basename,cc),'formats',{'png','fig'},debug,'overwrite');
        end
        close(fig_psd);
        
        % plot bandpass (residual)
        debug.log(sprintf('ex %d/%d, tk %d/%d: Plotting bandpass data',ee,E,tt,T),'info');
        fig_psd = figure(...
            'PaperPositionMode','auto',...
            'Position',[100 100 1600 600],...
            'Name','freqbands (resid)');
        ax = [...
            axes('Position',[0.04 0.54 0.31 0.40]) ...
            axes('Position',[0.36 0.54 0.31 0.40]) ...
            axes('Position',[0.68 0.54 0.31 0.40]) ...
            axes('Position',[0.04 0.09 0.31 0.40]) ...
            axes('Position',[0.36 0.09 0.31 0.40]) ...
            axes('Position',[0.68 0.09 0.31 0.40])];
        yl = [inf -inf];
        for ff=1:F
            for gg=1:G
                idx_channels = map.GridInfo.Channels{gg};
                idx_freq = f_res>=freqbands{ff}(1) & f_res<freqbands{ff}(2);
                plot(ax(ff),t_res,nanmean(nanmean(10*log10(S_res(:,idx_freq,idx_channels)),2),3));
                if gg==1
                    hold(ax(ff),'on');
                end
            end
            lyl = get(ax(ff),'YLim');
            yl(1) = min(lyl(1),yl(1));
            yl(2) = max(lyl(2),yl(2));
            hold(ax(ff),'off');
            title(ax(ff),sprintf('resid %d-%d Hz',freqbands{ff}(1),freqbands{ff}(2)));
            if ff>=4 && ff<=6
                xlabel('Time (sec)');
            else
                set(ax(ff),'XTick',[],'XTickLabels',{' '});
            end
            if ff==1 || ff==4
                ylabel(ax(ff),'Power (dB)');
            else
                set(ax(ff),'YTick',[],'YTickLabels',{' '});
            end
        end
        ylim(ax,yl);
        xlim(ax,t_res([1 end]));
        [~,h] = legend(ax(1),map.GridInfo.Label,'Interpreter','none');
        set(h,'linewidth',3);
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_freqband-resid',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        
        % plot bandpass (fitted)
        fig_psd = figure(...
            'PaperPositionMode','auto',...
            'Position',[100 100 1600 600],...
            'Name','freqbands (fitted)');
        ax = [...
            axes('Position',[0.04 0.54 0.31 0.40]) ...
            axes('Position',[0.36 0.54 0.31 0.40]) ...
            axes('Position',[0.68 0.54 0.31 0.40]) ...
            axes('Position',[0.04 0.09 0.31 0.40]) ...
            axes('Position',[0.36 0.09 0.31 0.40]) ...
            axes('Position',[0.68 0.09 0.31 0.40])];
        yl = [inf -inf];
        for ff=1:F
            for gg=1:G
                idx_channels = map.GridInfo.Channels{gg};
                idx_freq = f_fit>=freqbands{ff}(1) & f_fit<freqbands{ff}(2);
                plot(ax(ff),t_fit,nanmean(nanmean(10*log10(S_fit(:,idx_freq,idx_channels)),2),3));
                if gg==1
                    hold(ax(ff),'on');
                end
            end
            lyl = get(ax(ff),'YLim');
            yl(1) = min(lyl(1),yl(1));
            yl(2) = max(lyl(2),yl(2));
            hold(ax(ff),'off');
            title(ax(ff),sprintf('fitted %d-%d Hz',freqbands{ff}(1),freqbands{ff}(2)));
            if ff>=4 && ff<=6
                xlabel('Time (sec)');
            else
                set(ax(ff),'XTick',[],'XTickLabels',{' '});
            end
            if ff==1 || ff==4
                ylabel(ax(ff),'Power (dB)');
            else
                set(ax(ff),'YTick',[],'YTickLabels',{' '});
            end
        end
        ylim(ax,yl);
        xlim(ax,t_fit([1 end]));
        [~,h] = legend(ax(1),map.GridInfo.Label,'Interpreter','none');
        set(h,'linewidth',3);
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_freqband-fitted',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
        
        % plot bandpass (original)
        fig_psd = figure(...
            'PaperPositionMode','auto',...
            'Position',[100 100 1600 600],...
            'Name','freqbands (orig)');
        ax = [...
            axes('Position',[0.04 0.54 0.31 0.40]) ...
            axes('Position',[0.36 0.54 0.31 0.40]) ...
            axes('Position',[0.68 0.54 0.31 0.40]) ...
            axes('Position',[0.04 0.09 0.31 0.40]) ...
            axes('Position',[0.36 0.09 0.31 0.40]) ...
            axes('Position',[0.68 0.09 0.31 0.40])];
        yl = [inf -inf];
        for ff=1:F
            for gg=1:G
                idx_channels = map.GridInfo.Channels{gg};
                idx_freq = f_orig>=freqbands{ff}(1) & f_orig<freqbands{ff}(2);
                plot(ax(ff),t_orig,nanmean(nanmean(10*log10(dt_orig(:,idx_freq,idx_channels)),2),3));
                if gg==1
                    hold(ax(ff),'on');
                end
            end
            lyl = get(ax(ff),'YLim');
            yl(1) = min(lyl(1),yl(1));
            yl(2) = max(lyl(2),yl(2));
            hold(ax(ff),'off');
            title(ax(ff),sprintf('original %d-%d Hz',freqbands{ff}(1),freqbands{ff}(2)));
            if ff>=4 && ff<=6
                xlabel('Time (sec)');
            else
                set(ax(ff),'XTick',[],'XTickLabels',{' '});
            end
            if ff==1 || ff==4
                ylabel(ax(ff),'Power (dB)');
            else
                set(ax(ff),'YTick',[],'YTickLabels',{' '});
            end
        end
        ylim(ax,yl);
        xlim(ax,t_orig([1 end]));
        [~,h] = legend(ax(1),map.GridInfo.Label,'Interpreter','none');
        set(h,'linewidth',3);
        plot.save(fig_psd,'outdir',resultdir,'basename',sprintf('%s_freqband-orig',basename),'formats',{'png','fig'},debug,'overwrite');
        close(fig_psd);
    end
end





