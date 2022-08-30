env.set('Data', '\\striatum\Data\neural');
today_string = string(datetime('today', 'Format', 'yyyyMMDD'));
PNum = 'P012';
taskname = 'DelayedReach';
debug = Debug.Debugger(PNum);

%% create results directory
    resultdir = fullfile(env.get('results'),taskname,PNum);
    if exist(resultdir,'dir')~=7
        [status,msg] = mkdir(resultdir);
        assert(status>=1,'Could not create directory "%s": %s',resultdir,msg);
    end

%%
    experiments = hst.getExperiments(taskname, PNum);
    for ee=1:size(experiments,1)
        pid = experiments.PatientID{ee};
        session = experiments.ExperimentDate(ee);
        taskfiles = hst.getTaskFiles(taskname,session,pid);
        for tt=1:length(taskfiles)

            % load task and data objects
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
            phase_names = task.phaseNames;
            phtimes = [task.phaseTimes sum(task.trialTimes,2)];
            num_trials = find(phtimes(:,end)<=seconds(blc.DataInfo.Duration),1,'last');
            if num_trials<task.numTrials
                debug.log(sprintf('Neural recordings only have enough data for first %d out of %d trials',num_trials,task.numTrials),'warn');
            end
            phtimes = phtimes(1:num_trials,:);

            % get time series
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

        end
    end
    task_string = string(regexp(task.taskString, '\d*-(.*)', 'tokens'));
    
%%
% all right hemisphere
% RSP right superior parietal 1-20 macro
% RIP right inferior parietal 21-40 macro
% MP  minigrid parietal 41 - 104 mini
    FBand_name = 'High Gamma';
    spec_grid = 'MP';
    
    switch spec_grid
        case 'RSP'
            chan_range = [1 20];
            raw_v_inspected = true;
            spectrograms_compared = true;
        case 'RIP'
            chan_range = [21 40];
            raw_v_inspected = true; 
            spectrograms_compared = true;
        case 'MP'
            chan_range = [41 104];
            raw_v_inspected = true; 
            spectrograms_compared = true;
    end
    
    targets = arrayfun(@(x)x.tr_prm.targetID,task.trialdata)';
    targ_phase_dt = Analysis.DelayedReach.LFP.sort_by_target(dt, targets, task.numPhases, 'Channel_Range', chan_range);
    sub_chaninfo = map.ChannelInfo(chan_range(1):chan_range(end),1:2); %get recorded channel numbers and labels
    num_chans = size(sub_chaninfo, 1);
    num_phase = length(phase_names);


    trial_avg_nd = cell(8, num_phase);
    for i = 1:numel(targ_phase_dt)
        trial_avg_nd{i} = nanmean(targ_phase_dt{i}, 3);
    end

% Plot each channels' trials by target location with trial average overlaid

% only doing this once per grid
if ~raw_v_inspected
    yr = 300;

    for ch = 1:num_chans
        chan_as_record = table2array(sub_chaninfo(ch,1));
        chan_label = table2array(sub_chaninfo(ch,2));
        FString = sprintf('%s-Ch-%d-%s-All-Targets All-Trials', task_string, chan_as_record, chan_label{1});
        figure('Name', FString, 'NumberTitle', 'off', 'Units', 'normalized',...
            'OuterPosition', [0 0.025 0.5 0.97]); %just about half a screen
        for t = 1:8
            targ_trials = cat(1, targ_phase_dt{t,:});
            targ_trials = squeeze(targ_trials(:,ch,:));
            targ_avg = cat(1, trial_avg_nd{t,:});
            targ_avg = targ_avg(:, ch);
            full_relt = 0:(1/blc.SamplingRate):(size(targ_trials,1)/blc.SamplingRate - 1/blc.SamplingRate);

            subplot_tight(8,1,t, [0.035 0.045]);
            plot(full_relt, targ_trials, 'Color', [0.7 0.87 0.54],...
                    'LineWidth', 0.2)
            hold on
            set(gca, 'YLim', [-yr yr], 'xticklabels', '')
            ylabel('\muV', 'Interpreter','tex')
            if t == 1
                TString = sprintf('Ch %d "%s"\nTLoc %d, %d Trials', chan_as_record, chan_label{1}, t, size(targ_trials,2));
            else
                TString = sprintf('TLoc %d, %d Trials', t, size(targ_trials,2));
            end
            title(TString)
            YCoords = [-yr yr]; % plotting at YLim readjusts YLim
            Vx = [phase_end_times; phase_end_times];
            Vy = YCoords' .* ones(2, length(phase_end_times));
            plot(Vx, Vy, 'k--')
            set(gca, 'YLim', [-yr yr], 'xticklabels', '')
            plot(full_relt, targ_avg, 'Color', [0.2 0.63 0.17],...
                'LineWidth', 0.5)
            if t == 8
                xlabel('Time (s)')
                set(gca, 'xticklabelmode', 'auto')
            end

            hold off
        end %end target subplot loop
    end % end channel figure loop
    fprintf('Paused after showing all trials all channels specified\n"Enter" to saveopenfigs as .png and continue to specs\n')
    pause
    Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)
end
% MP raw data all trials
% not seeing much here.
% Channel 44 (4 in subarray) is 'bad' for all trials
% Channel 72 (32 in subarray) is 'bad' for all trials
% Channel 86 (46) has one bad trial in for location 5 (voltage swing from 
% Fixation through trial end (through to location 6 trial?), but no other
% channels show this 

% RSP raw data all trials 05/11/2018
% No pervasive 'bad' trials
% Ch 10 (10) 12(12) ,13-20 except 16 larger amplitude than 1-9. 
% curious about 17 vs 18 vs 19/20

% RIP raw data all trials 05/11/2018
% Everything looks ok. Lower and more even amplitudes in low (<=8)
% channels. More interesting channels high up but no outliers.
% Spectrogram Params
%Initialize Chronux Parameters
    MovingWin     = [0.25 0.1]; %[WindowSize StepSize]
    Tapers        = [3 5]; % [TW #Tapers] TW = Duration*BandwidthDesired
    Pad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
    FPass         = [0 200]; %frequency range of the output data
    TrialAve      = 0; %Average later
    Fs            = blc.SamplingRate;
    ChrParams     = struct('tapers', Tapers,'pad', Pad, 'fpass', FPass, ...
        'trialave', TrialAve, 'MovingWin', MovingWin, 'Fs', Fs); 
    gpuflag       = true;
    

%  Get specs of separate phases of trial avgd nd
    trial_avg_specs_ph = cell(8,num_phase);
    trial_avg_fbins = cell(1,num_phase);
    trial_avg_tbins = cell(1,num_phase);
    for t = 1:8
        for p = 1:num_phase
            [trial_avg_specs_ph{t, p}, trial_avg_fbins{1, p}, trial_avg_tbins{1, p}] = Analysis.DelayedReach.LFP.multiSpec(trial_avg_nd{t,p},...
            'spectrogram', 'Parameters', ChrParams, ...
            'gpuflag', gpuflag);

        end
    end

%

    % t = trial_avg_tbins{1,2} + trial_avg_tbins{1,1}(end);
    % cumu_tbins = [trial_avg_tbins{1,1}; t];
    % t = trial_avg_tbins{1,3} + t(end);
    % cumu_tbins = [cumu_tbins; t];
    % t = trial_avg_tbins{1,4} + t(end);
    % cumu_tbins = [cumu_tbins; t];
    % t = trial_avg_tbins{1,5} + t(end);
    % cumu_tbins = [cumu_tbins; t];

% Plot 1 channel, 1 target loc, specs of separate phases of trial avgd nd

% just visually checking differences between phase segmented spectrograms and
% spectrogram of entire trial. Don't want to do this every time.
if ~spectrograms_compared
    ch = 8;
    targ_loc = 1;

    fstring = sprintf("Trial Avgd Specs of Separate Phases Ch%d Targ%d", ch, targ_loc);
    figure('Name', fstring, 'NumberTitle', 'off','position', [-1919 121 1920 1083])

    for ph = 1:num_phase
        subplot(1,num_phase,ph)
        imagesc(trial_avg_tbins{1, ph}, trial_avg_fbins{1, ph}, 10*log10(trial_avg_specs_ph{targ_loc, ph}(:, :, ch))'); axis xy;
        title("Phase " + string(ph))
    end
end
% Get specs of concat trial avgd nd then check plot

%concat trial avgs
    trial_avg_nd_concat = cell(8,1);
    for t = 1:8
        trial_avg_nd_concat{t} = [trial_avg_nd{t, 1}; trial_avg_nd{t, 2}; trial_avg_nd{t, 3}; trial_avg_nd{t, 4}; trial_avg_nd{t, 5}];
    end

%specs on concat trial avgs
    trial_avg_specs_concat = cell(8,1);
    for t = 1:8
        [trial_avg_specs_concat{t}, trial_avg_fbins_concat, trial_avg_tbins_concat] = Analysis.DelayedReach.LFP.multiSpec(trial_avg_nd_concat{t},...
        'spectrogram', 'Parameters', ChrParams, ...
        'gpuflag', gpuflag);
    end


    % Note for MP grid (same is true for RSP and RIP (all trials recorded everywhere):
    % huge band of no power because of 1 row of NaNs in all targ_loc = 1 trials
    % at the end of phase 3 -> 1 row of NaNs in trial_avg_nd_concat (10226) 
    % despite nanmean of all trials -> band of NaN power as window slides 
    % over?

        t = trial_avg_nd_concat{1};
        t(10226, :) = [];

        [t_pa, t_pa_fbins, t_pa_tbins] = Analysis.DelayedReach.LFP.multiSpec(t,...
            'spectrogram', 'Parameters', ChrParams, ...
            'gpuflag', gpuflag);

        %imagesc(t_pa_tbins, t_pa_fbins, 10*log10(t_pa(:,:,8))'); axis xy;
    % problem solved. Still has same tbins as before so just
    % replacing the trial_avg_specs_concat{1,1} with t_pa

        trial_avg_specs_concat{1,1} = t_pa;



% Plot 1 channel, 1 target loc, specs of concat trial avgd nd

% just visually checking differences between phase segmented spectrograms and
% spectrogram of entire trial. Don't want to do this every time.
if ~spectrograms_compared
    ch = 8;
    targ_loc = 1;

    fstring = sprintf("Trial Avgd Specs of Concat Phases Ch%d Targ%d", ch, targ_loc);
    figure('Name', fstring, 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    imagesc(trial_avg_tbins_concat, trial_avg_fbins_concat, 10*log10(trial_avg_specs_concat{targ_loc, 1}(:, :, ch))'); axis xy;
    hold on
    vx = [phase_end_times; phase_end_times];
    vy = [0 trial_avg_fbins_concat(end)]' .* ones(2, 6);
    plot(vx, vy, 'k--')
    hold off
    set(gca, 'XMinorTick', 'on')
    title(fstring)


    fprintf('paused after comparing spectrograms \n')
    ui = input('1 to saveopenfigs as .png and continue to checktuning\n2 to stop here\nInput: ');
    switch ui
        case 1
            Analysis.DelayedReach.LFP.saveOpenFigs('ImageType','png','CloseFigs',true)
        case 2
            return
    end
end
% Check tuning of phase segmented specs

% subselect frequency band

    switch FBand_name
        case 'Theta'
            fband = [4 8];
        case 'Alpha'
            fband = [8 12];
        case 'Beta'
            fband = [12 30];
        case 'Low Gamma'
            fband = [30 80];
        case 'High Gamma'
            fband = [80 200];
    end
    
    fband_idx = trial_avg_fbins{1} > fband(1) & trial_avg_fbins{1} < fband(2);

    phase_avg_pow = zeros(num_chans, 8, num_phase);
% get avg power for each phase
    for t = 1:8
        for p = 1:num_phase
            tpcell = trial_avg_specs_ph{t,p}(:, fband_idx, :);
            tpcell = permute(tpcell, [3, 1, 2]);
            phase_avg_pow(:, t, p) = nanmean(tpcell(:,:), 2);
        end
    end



% Plot average power in each phase over that band. 1 fig per channel.
% polar plot of non-normalized power in the middle
    t_subplot_order = [8 1 2 7 0 3 6 5 4]; % makes subplotting in order easier
    theta_deg=(0:45:360)'; %for polar plot rays
    theta=deg2rad(theta_deg); %for polar plot coordinates
    target_labels = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8';};
    bar_colors = [0 0.4470 0.7410; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250; 0.4940 0.1840 0.5560; 0.4660 0.6740 0.1880];
    bc = bar_colors(1:num_phase,:);

    for ch = 1:num_chans
        chan_as_record = table2array(sub_chaninfo(ch,1));
        chan_label = table2array(sub_chaninfo(ch,2));
        ph_targ_avg = squeeze(phase_avg_pow(ch,:,:));
        if size(ph_targ_avg, 1) < length(theta)
            ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
        end
        max_val = max(ph_targ_avg(:)); %normalize all subplots for comparison

        figtitle = sprintf('%s-Polar Plot-AvgPow-%s-Channel %d %s', task_string, FBand_name, chan_as_record, chan_label{1});
        f = figure('Name', figtitle, 'NumberTitle', 'off','position', [-1919 121 1920 1083]);
        for t = 1:length(t_subplot_order)
            if t == 5
                subplot_tight(3, 3, t, [0.08 0.08])
                polarplot(theta, ph_targ_avg)
                if max_val > 0
                    set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels,...
                        'RTick', 0:max_val/5:max_val)
                else
                    set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels)
                end
                legend(phase_names)
                continue %skip the rest
            end
            target = t_subplot_order(t);
            subplot_tight(3, 3, t, [0.08 0.08])
            b = bar(ph_targ_avg(target,:));
            set(b, 'FaceColor', 'flat', 'CData', bc)
            ylbl = sprintf('Average %s Power', FBand_name);
            ylabel(ylbl)
            if max_val > 0
                ylim([0 max_val])
            end
            set(gca, 'XTickLabel', phase_names)
            ts = sprintf('Ch %d Target %d', 1, target);
            title(ts)
        end % end for subplots
        anno_string = sprintf('Average %s Power Channel %d "%s"', FBand_name, chan_as_record, chan_label{1});
        annotation(f,'textbox',...
            [0.361416666666667 0.636195752539243 0.260979166666667 0.0286241920590947],...
            'String', anno_string,...
            'HorizontalAlignment','center',...
            'FontWeight','bold',...
            'FontSize',14,...
            'FitBoxToText','off',...
            'BackgroundColor',[0.972549021244049 0.972549021244049 0.972549021244049]);

    end % end for channels

% Channel 45 (5) / 46 (6) for target 4?
% Channel 47 (7) / 48 (8) for target 2?
% Channel 64 (24) for target 2?





















