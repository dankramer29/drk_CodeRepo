% general
% usrn = 'mbarb';

usrn = 'Mike';
P012.dt = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Workspace\dt.mat'));
P012.map = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Workspace\map.mat'));
P012.phase_names = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Workspace\phase_names.mat'));
P012.targets = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Workspace\targets.mat'));
P012.cortex = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Imaging\Meshes\S14_rh_pial.mat'));
results_path = fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012');
%

chrMovingWin     = [0.25 0.1]; %[WindowSize StepSize]
chrTapers        = [3 5]; % [TW #Tapers] TW = Duration*BandwidthDesired
chrPad           = 2; % -1 no padding, 0 pad data length to ^2, 1 ^4, etc. Incr # freq bins, 
chrFPass         = [0 500]; %frequency range of the output data
chrTrialAve      = 0; %Average later
chrFs            = 2000;
P012.Params     = struct('tapers', chrTapers,'pad', chrPad, 'fpass', chrFPass, ...
    'trialave', chrTrialAve, 'MovingWin', chrMovingWin, 'Fs', chrFs); 
P012.gpuflag       = true;


%
% spec_grid = 'RSP';

% switch spec_grid

spec_grid = 'RSP';
t2 = tic;
%     case 'RSP'
        num_phase = length(P012.phase_names);
        chan_range = 1:20;
        P012.RSP.chan_range = chan_range;
        phase_names = P012.phase_names;
        P012.RSP.elecmatrix = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Imaging\elecs\individual_elecs\superior_parietal.mat'));
        %
        [dt_sel_chans, sub_chaninfo] = sel_chans(P012.dt, P012.map, chan_range);
        
        dt_sel_chans = remove_nans(dt_sel_chans);
        
        [dt_sel_chans_cavg, ~] = common_avg_ref(dt_sel_chans);
        
        [specgrams_cavg, specgrams_cavg_fbins, specgrams_cavg_tbins, spectrums_cavg, spectrums_cavg_fbins] = ...
            make_specs_from_cells(dt_sel_chans_cavg, P012.Params, P012.gpuflag, num_phase);
        
        spectrums_alltrialavg = all_trial_avg_spectrums(spectrums_cavg, spectrums_cavg_fbins, num_phase);
        
        %
        LFB_range = [8 32];
        HFB_range = [76 100];
        print_acts = 0;
        print_figs = 1;
        chans_plot = 1:length(chan_range);
        
        % --------- Response vs Cue ---------
        phases = [3 5];
        [specs_cmpr] = compare_nrml_specs(spectrums_cavg, spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
%         fprintf('past compare_nrml_specs\n')
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RSP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RSP.Ph35.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RSP.Ph35.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph35.tuning.HZ_76_100.pvals, P012.RSP.Ph35.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RSP.Ph35.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RSP.Ph35.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RSP.Ph35.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph35.tuning.HZ_8_32.pvals, P012.RSP.Ph35.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        P012.RSP.dt_sel_chans = dt_sel_chans;
        P012.RSP.sub_chaninfo = sub_chaninfo;
        P012.RSP.dt_sel_chans_cavg = dt_sel_chans_cavg;
        P012.RSP.specgrams_cavg = specgrams_cavg;
        P012.RSP.specgrams_cavg_fbins = specgrams_cavg_fbins;
        P012.RSP.specgrams_cavg_tbins = specgrams_cavg_tbins;
        P012.RSP.spectrums_cavg = spectrums_cavg;
        P012.RSP.spectrums_cavg_fbins = spectrums_cavg_fbins;
        P012.RSP.spectrums_alltrialavg = spectrums_alltrialavg;
        P012.RSP.Ph35.LFB = LFB;
        P012.RSP.Ph35.HFB = HFB;
        P012.RSP.Ph35.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Delay vs Cue ---------
        t2 = tic;
        phases = [3 4];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.RSP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.RSP.spectrums_cavg, P012.RSP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RSP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RSP.Ph34.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RSP.Ph34.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph34.tuning.HZ_76_100.pvals, P012.RSP.Ph34.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RSP.Ph34.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RSP.Ph34.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RSP.Ph34.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph34.tuning.HZ_8_32.pvals, P012.RSP.Ph34.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.RSP.Ph34.LFB = LFB;
        P012.RSP.Ph34.HFB = HFB;
        P012.RSP.Ph34.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Response vs Fix ---------
        phases = [2 5];
        t2 = tic;
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.RSP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.RSP.spectrums_cavg, P012.RSP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RSP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RSP.Ph25.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RSP.Ph25.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph25.tuning.HZ_76_100.pvals, P012.RSP.Ph25.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RSP.Ph25.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RSP.Ph25.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RSP.Ph25.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph25.tuning.HZ_8_32.pvals, P012.RSP.Ph25.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.RSP.Ph25.LFB = LFB;
        P012.RSP.Ph25.HFB = HFB;
        P012.RSP.Ph25.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Delay vs Fix ---------
        t2 = tic;
        phases = [2 4];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.RSP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.RSP.spectrums_cavg, P012.RSP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RSP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RSP.Ph24.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RSP.Ph24.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph24.tuning.HZ_76_100.pvals, P012.RSP.Ph24.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RSP.Ph24.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RSP.Ph24.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RSP.Ph24.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RSP.Ph24.tuning.HZ_8_32.pvals, P012.RSP.Ph24.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.RSP.Ph24.LFB = LFB;
        P012.RSP.Ph24.HFB = HFB;
        P012.RSP.Ph24.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
%     case 'RIP'
        t2 = tic;
        spec_grid = 'RIP';
        num_phase = length(P012.phase_names);
        chan_range = 21:40;
        P012.RIP.chan_range = chan_range;
        phase_names = P012.phase_names;
        P012.RIP.elecmatrix = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Imaging\elecs\individual_elecs\inferior_parietal.mat'));
%         chan_grid = rot90(reshape(1:20, 5, 4), 2);
%         chan_grid_x = 1:4;
%         chan_grid_y = 1:5;
        [dt_sel_chans, sub_chaninfo] = sel_chans(P012.dt, P012.map, chan_range);
        
        dt_sel_chans = remove_nans(dt_sel_chans);
        
        [dt_sel_chans_cavg, ~] = common_avg_ref(dt_sel_chans);
        
        [specgrams_cavg, specgrams_cavg_fbins, specgrams_cavg_tbins, spectrums_cavg, spectrums_cavg_fbins] = ...
            make_specs_from_cells(dt_sel_chans_cavg, P012.Params, P012.gpuflag, num_phase);
        
        spectrums_alltrialavg = all_trial_avg_spectrums(spectrums_cavg, spectrums_cavg_fbins, num_phase);
        
        %
        LFB_range = [8 32];
        HFB_range = [76 100];
        print_acts = 0;
        print_figs = 1;
        chans_plot = 1:length(chan_range);

        % --------- Response vs Cue ---------

        phases = [3 5];
        [specs_cmpr] = compare_nrml_specs(spectrums_cavg, spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
%         fprintf('past compare_nrml_specs\n')
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RIP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        P012.RIP.Ph35.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RIP.Ph35.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph35.tuning.HZ_76_100.pvals, P012.RIP.Ph35.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RIP.Ph35.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RIP.Ph35.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RIP.Ph35.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph35.tuning.HZ_8_32.pvals, P012.RIP.Ph35.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        P012.RIP.dt_sel_chans = dt_sel_chans;
        P012.RIP.sub_chaninfo = sub_chaninfo;
        P012.RIP.dt_sel_chans_cavg = dt_sel_chans_cavg;
        P012.RIP.specgrams_cavg = specgrams_cavg;
        P012.RIP.specgrams_cavg_fbins = specgrams_cavg_fbins;
        P012.RIP.specgrams_cavg_tbins = specgrams_cavg_tbins;
        P012.RIP.spectrums_cavg = spectrums_cavg;
        P012.RIP.spectrums_cavg_fbins = spectrums_cavg_fbins;
        P012.RIP.spectrums_alltrialavg = spectrums_alltrialavg;
        P012.RIP.Ph35.LFB = LFB;
        P012.RIP.Ph35.HFB = HFB;
        P012.RIP.Ph35.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
      
        % --------- Delay vs Cue ---------
        t2 = tic;
        phases = [3 4];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.RIP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.RIP.spectrums_cavg, P012.RIP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RIP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RIP.Ph34.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RIP.Ph34.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph34.tuning.HZ_76_100.pvals, P012.RIP.Ph34.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RIP.Ph34.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RIP.Ph34.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RIP.Ph34.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph34.tuning.HZ_8_32.pvals, P012.RIP.Ph34.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.RIP.Ph34.LFB = LFB;
        P012.RIP.Ph34.HFB = HFB;
        P012.RIP.Ph34.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Response vs Fix ---------
        t2 = tic;
        phases = [2 5];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.RIP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.RIP.spectrums_cavg, P012.RIP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RIP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RIP.Ph25.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RIP.Ph25.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph25.tuning.HZ_76_100.pvals, P012.RIP.Ph25.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RIP.Ph25.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RIP.Ph25.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RIP.Ph25.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph25.tuning.HZ_8_32.pvals, P012.RIP.Ph25.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.RIP.Ph25.LFB = LFB;
        P012.RIP.Ph25.HFB = HFB;
        P012.RIP.Ph25.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Delay vs Fix ---------
        t2 = tic;
        phases = [2 4];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.RIP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.RIP.spectrums_cavg, P012.RIP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.RIP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.RIP.Ph24.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.RIP.Ph24.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph24.tuning.HZ_76_100.pvals, P012.RIP.Ph24.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.RIP.Ph24.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.RIP.Ph24.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.RIP.Ph24.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.RIP.Ph24.tuning.HZ_8_32.pvals, P012.RIP.Ph24.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.RIP.Ph24.LFB = LFB;
        P012.RIP.Ph24.HFB = HFB;
        P012.RIP.Ph24.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
%     case 'MP'
        t2 = tic;
        spec_grid = 'MP';
        num_phase = length(P012.phase_names);
        chan_range = [41:43 45:71 73:104]; %ch 44 and 72 are all noise
        P012.MP.chan_range = chan_range;
        phase_names = P012.phase_names;
        P012.MP.elecmatrix = importdata(fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012\Imaging\elecs\individual_elecs\minigrid.mat'));

%         cr = [1:3 1 4:30 1 31:62];
%         chan_grid = rot90(reshape(cr, 8, 8)', 1);
%         %chan_grid(5, 1) = 1; chan_grid(1, 4) = 1;
%         chan_grid_x = 1:8;
%         chan_grid_y = 1:8; 
        [dt_sel_chans, ~] = sel_chans(P012.dt, P012.map, chan_range);
        
        dt_sel_chans = remove_nans(dt_sel_chans);
        
        [dt_sel_chans_cavg, ph_cavg] = common_avg_ref(dt_sel_chans);
        
        %add channels back as thee common avg to be able to plot
        %also good check to make sure signifigance checks are accurate
        %later
        for p = 1:num_phase
            subphase = dt_sel_chans_cavg{1,p};
            cavg = ph_cavg{1,p};
            new_phase_dt = cat(2, subphase(:,1:3,:), cavg, subphase(:,4:30,:), cavg, subphase(:,31:end,:));
            %ch 4 and 32 if 1:64
            dt_sel_chans_cavg{1,p} = new_phase_dt;
        end
        sub_chaninfo = P012.map.ChannelInfo(41:104,1:2); %get recorded channel numbers and labels
        
        [specgrams_cavg, specgrams_cavg_fbins, specgrams_cavg_tbins, spectrums_cavg, spectrums_cavg_fbins] = ...
            make_specs_from_cells(dt_sel_chans_cavg, P012.Params, P012.gpuflag, num_phase);
        
        spectrums_alltrialavg = all_trial_avg_spectrums(spectrums_cavg, spectrums_cavg_fbins, num_phase);
        
        %
        LFB_range = [8 32];
        HFB_range = [76 100];
        print_acts = 0;
        print_figs = 1;
        chans_plot = 1:64;
        
        % --------- Response vs Cue ---------
        phases = [3 5];
        spec_grid = 'MP';
        
        [specs_cmpr] = compare_nrml_specs(spectrums_cavg, spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
%         fprintf('past compare_nrml_specs\n')
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.MP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        P012.MP.Ph35.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.MP.Ph35.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph35.tuning.HZ_76_100.pvals, P012.MP.Ph35.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.MP.Ph35.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.MP.Ph35.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.MP.Ph35.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph35.tuning.HZ_8_32.pvals, P012.MP.Ph35.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        P012.MP.dt_sel_chans = dt_sel_chans;
        P012.MP.sub_chaninfo = sub_chaninfo;
        P012.MP.dt_sel_chans_cavg = dt_sel_chans_cavg;
        P012.MP.specgrams_cavg = specgrams_cavg;
        P012.MP.specgrams_cavg_fbins = specgrams_cavg_fbins;
        P012.MP.specgrams_cavg_tbins = specgrams_cavg_tbins;
        P012.MP.spectrums_cavg = spectrums_cavg;
        P012.MP.spectrums_cavg_fbins = spectrums_cavg_fbins;
        P012.MP.spectrums_alltrialavg = spectrums_alltrialavg;
        P012.MP.Ph35.LFB = LFB;
        P012.MP.Ph35.HFB = HFB;
        P012.MP.Ph35.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Delay vs Cue ---------
        t2 = tic;
        phases = [3 4];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.MP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.MP.spectrums_cavg, P012.MP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.MP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.MP.Ph34.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.MP.Ph34.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph34.tuning.HZ_76_100.pvals, P012.MP.Ph34.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.MP.Ph34.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.MP.Ph34.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.MP.Ph34.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph34.tuning.HZ_8_32.pvals, P012.MP.Ph34.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
      
        P012.MP.Ph34.LFB = LFB;
        P012.MP.Ph34.HFB = HFB;
        P012.MP.Ph34.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Response vs Fix ---------
        t2 = tic;
        phases = [2 5];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.MP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.MP.spectrums_cavg, P012.MP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.MP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.MP.Ph25.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.MP.Ph25.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph25.tuning.HZ_76_100.pvals, P012.MP.Ph25.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.MP.Ph25.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.MP.Ph25.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.MP.Ph25.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph25.tuning.HZ_8_32.pvals, P012.MP.Ph25.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.MP.Ph25.LFB = LFB;
        P012.MP.Ph25.HFB = HFB;
        P012.MP.Ph25.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn print_figs chans_plot spec_grid
        
        % --------- Delay vs Fix ---------
        t2 = tic;
        phases = [2 4];
        LFB_range = [8 32];
        HFB_range = [76 100];
        spectrums_cavg_fbins = P012.MP.spectrums_cavg_fbins;
        [specs_cmpr] = compare_nrml_specs(P012.MP.spectrums_cavg, P012.MP.spectrums_alltrialavg, phases);
        indx_move = specs_cmpr.indx_move;
        indx_rest = specs_cmpr.indx_rest;
        [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases,...
            LFB_range, HFB_range, print_figs, print_figs, P012.MP.elecmatrix, P012.cortex, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past hi_low_activation_proc\n')
        
        P012.MP.Ph24.FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, spec_grid,...
            'SavePath', fullfile('C:\Users', usrn, 'Documents\results\DelayedReach\P012'));
%         fprintf('past activations_all_fb_all_ch\n')
        P012.MP.Ph24.tuning.HZ_76_100.activation = Analysis.DelayedReach.LFP.activations_by_targ(HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph24.tuning.HZ_76_100.pvals, P012.MP.Ph24.tuning.HZ_76_100.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            HFB.HFB_trials(:,indx_move), HFB.HFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        [P012.MP.Ph24.tuning.HZ_76_100.fit_data] = Analysis.DelayedReach.LFP.check_gauss_tuning(P012.MP.Ph24.tuning.HZ_76_100.activation); %supply ch X targ matrix
%         fprintf('past Analysis.DelayedReach.LFP.check_gauss_tuning\n')
        P012.MP.Ph24.tuning.HZ_8_32.activation = Analysis.DelayedReach.LFP.activations_by_targ(LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.activations_by_targ\n')
        [P012.MP.Ph24.tuning.HZ_8_32.pvals, P012.MP.Ph24.tuning.HZ_8_32.sig] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
            LFB.LFB_trials(:,indx_move), LFB.LFB_trials(:,indx_rest), P012.targets);
%         fprintf('past Analysis.DelayedReach.LFP.bs_activation_tuning\n')
        
        P012.MP.Ph24.LFB = LFB;
        P012.MP.Ph24.HFB = HFB;
        P012.MP.Ph24.specs_cmpr = specs_cmpr;
        toc(t2)
        clearvars -except P012 usrn
        

% end
% 
% 
% %
% % %%
% %         FB_range = [74 102];
% %         [FB_trials, ~, ~] = sum_fb_stack_phase(spectrums_cavg, spectrums_cavg_fbins, FB_range);
% %         FB_act = Analysis.DelayedReach.LFP.fband_activation(FB_trials(:, indx_move), FB_trials(:, indx_rest));
% %         [FB_pbs, FB_sbs] = Analysis.DelayedReach.LFP.fband_activation_bs_pvals(FB_trials(:, indx_move), FB_trials(:, indx_rest));
% %         full_gauss_plot(FB_act, FB_sbs, elecmatrix, cortex, phase_names, phases, FB_range, spec_grid)
% 
% % P012.tuning.HZ_76_100.gof, P012.tuning.HZ_76_100.fitr, P012.tuning.HZ_76_100.shifts
% % t = 1:8;
% % chan = 7;
% % chan_as_record = table2array(sub_chaninfo(chan,1));
% % chan_label = table2array(sub_chaninfo(chan,2));
% % excl = logical(HFB_gof.excluded(chan,:));
% % ts = sprintf('Ch %d %s Tuning HFB', chan_as_record, chan_label{1});
% % figure('Name', ts, 'NumberTitle', 'off','position', [-1302 563 739 610])
% % temp_yshift = HFB_shifts.shift_amt(chan,2);
% % temp_yd = HFB_shifts.shifted_power(chan,:) + temp_yshift;
% % %temp_yd(excl) = 0;
% % 
% % fig_p1 = scatter(t, temp_yd, 'filled');
% % hold on
% % fig_p2 = plot(HFB_fit_result{chan}, 'k');
% % fig_p2.YData = fig_p2.YData + temp_yshift;
% % set(gca, 'XTickLabel', string(HFB_shifts.shifted_targets(chan,:)))
% % legend([fig_p2], {'Gaussian Fit'})
% % title(ts)
% % xlabel('Target Number')
% % ylabel('Average Activation HFB 76-100Hz')
% % fig_anno = sprintf('r^{2} = %0.3f', HFB_gof.rsquare(chan));
% % anno = annotation('textbox',...
% %         [0.7778 0.7113 0.1030 0.0628],...
% %         'VerticalAlignment','middle',...
% %         'String',fig_anno,...
% %         'HorizontalAlignment','center',...
% %         'FitBoxToText', 'on');
    

% Notes and trial and error
    % Tried without common avg reference
    % Similar differences between phases just not as pronounced.
    
%
    % fband = HFB_trials;
    % diff = fband(:,indx_move) - fband(:,indx_rest);
    % tr_acts = (diff .^3) ./ (abs(diff) .^2) .* ((1 * 1) / (2^2)); %abs(diff) squared bc just want the 
    % % variation for each trial, which is just the difference between them). 
    % %tr_acts = (diff .^3) ./ (abs(diff) .* var(fband, 0, 2)) .* ((64 * 64) / (128^2));
    % sig_targ = zeros(8, 6, length(chan_range));
    % HFB_move_mean_targ = zeros(length(chan_range), 8);
    % for chan = 1:length(chan_range)
    %     tdata = tr_acts(chan, :);%fband(chan,indx_move);%
    %     
    %     for targ = 1:8
    %         new_targets = zeros(size(targets));
    %         for tr = 1:length(new_targets)
    %             if targets(tr) == targ
    %                 new_targets(tr) = targ;
    %             else
    %                 new_targets(tr) = 9;
    %             end
    %         end
    %         HFB_move_mean_targ(chan,targ) = mean(tdata(targets == targ));
    %         [t_p, t_t, t_stats] = anova1(tdata, new_targets, 'off');
    %         [sig_targ(targ,:, chan), t_m, ~, gnames] = multcompare(t_stats, 'Display', 'off');
    %         sig_targ(targ, 1, chan) = targ; sig_targ(targ, 2, chan) = 9;
    %     end
    % end
    % sig_targ(:,7,:) = sig_targ(:,6,:) < 0.05 & sig_targ(:,3,:) > 0;

% Sort spectrums by trial target, get average power in frequency band
    % spectrums_cavg_targsort = cell(8, num_phase);
    % spectrums_cavg_targ_LF = zeros(length(chan_range), num_phase, 8);
    % spectrums_cavg_targ_HF = zeros(length(chan_range), num_phase, 8);
    % indx_LF = spectrums_cavg_fbins{1,1} >= 8 & spectrums_cavg_fbins{1,1} <= 32;
    % indx_HF = spectrums_cavg_fbins{1,1} >= 76 & spectrums_cavg_fbins{1,1} <= 100;
    % for t = 1:8
    %     for p = 1:num_phase
    %         targ_indx = targets == t;
    %         targ_specs = spectrums_cavg{1,p}(:,:,targ_indx);
    %         targ_specs_nml = targ_specs ./ repmat(spectrums_alltrialavg, [1 1 8]);
    %         spectrums_cavg_targsort{t, p} = targ_specs;
    %         spectrums_cavg_targ_LF(:,p,t) = mean(squeeze(sum(targ_specs_nml(indx_LF, :, :), 1)), 2);
    %         spectrums_cavg_targ_HF(:,p,t) = mean(squeeze(sum(targ_specs_nml(indx_HF, :, :), 1)), 2);
    %     end
    % end
    % 
    % clear targ_*

    %
    % want a feq by channel by trial array of low freq power and high freq
    % power
    % try just concat of all trials in delay phase and all trials in move phase
    % will be same as KM but with 1 extra dimmension for trial type rather than
    % indexing trials. Could also just concat the 3rd dimension and first 64
    % will be delay and next 64 movement

% LFB_sig_table = table(string(table2array(sub_chaninfo(logical(LFB_sig_bs), 'ChannelLabel'))), LFB_activation((logical(LFB_sig_bs))));
% HFB_sig_table = table(string(table2array(sub_chaninfo(logical(HFB_sig_bs), 'ChannelLabel'))), HFB_activation((logical(HFB_sig_bs))));

% Mean normalization
    % "the power at each frequency for each epoch was normalized with respect
    % to the mean power at that frequency across all epochs in the run from
    % which it came". Run being defined as an experiment. Seems to be electrode
    % specific.
    %
    % For our purposes all epochs for a run would be all the trials in a given
    % phase. So all trials in response = all movement epochs, all trials in ITI
    % would be = all rest epochs. 
    %
    % Mean normalization is (x - mean) / (max - min)
    % In the supplement it is described as "each spectra is divided by the mean
    % spectra across the entire task run". So just (x / mean). Try both.
    % Tried both, think it's just the x/mean version.
    %
    % This is just for calculating the "electrode activation", as
    % plotting an average of spectrums that have been normalized to the average
    % give you a worthless plot

    % mean_nrml_func1 = @(x, y)(x ./ y);
    % mean_nrml_func2 = @(x, y, w, z)((x - y) ./ (w - z)); % get negatives -> cant 10*log10()
    % spectrums_cavg_nrml = cell(1, num_phase);
    % for p = 1:num_phase
    %     %trial_avg = mean(spectrums_cavg{1, p}, 3);
    %     ch_tr_avg = mean(spectrums_cavg{1, p}(:,:), 2);
    %     trial_maxp = max(spectrums_cavg{1, p}, [], 3);
    %     trial_minp = min(spectrums_cavg{1, p}, [], 3);
    %     %spectrums_cavg_nrml{1, p} = mean_nrml_func1(spectrums_cavg{1, p}, ch_tr_avg);
    %     spectrums_cavg_nrml{1, p} = log(spectrums_cavg{1, p}) -  log(ch_tr_avg);
    % end
    % 
    % figure
    % plot(spectrums_cavg_fbins{1, 1}, log(spectrums_cavg_nrml{1, 1}(:, 1, 1)))
    % xlabel('Hz')
    % ylabel('log(power)')
    % title(' x ./ mean normalized Response phase channel 1 trial 1')

% check bootstrap methods (no difference after testing)
    % meth1p = zeros(20,100); %randperm(128)
    % meth1s = zeros(20,100); %randperm(128)
    % 
    % for i = 1:100
    %     [meth1p(:,i), meth1s(:,i)] = Analysis.DelayedReach.LFP.fband_activation_bs_pvals(HFB_trials(:, indx_move), HFB_trials(:, indx_rest));
    % end
    % meth2p = zeros(20,100); %randi(64, 1, 64) x2
    % meth2s = zeros(20,100); %randperm(128)
    % for i = 1:100
    %     [meth2p(:,i), meth2s(:,i)] = Analysis.DelayedReach.LFP.fband_activation_bs_pvals(HFB_trials(:, indx_move), HFB_trials(:, indx_rest));
    % end    
%

function [dt_sel_chans, sub_chaninfo] = sel_chans(dt, map, chan_range)
    % get data for the grid we want
    % dt is 1x5 cell, each cell is time x ch x trials
    dt_sel_chans = cell(size(dt));
    for p = 1:5
        dt_sel_chans{1,p} = dt{1,p}(:,chan_range,1:end); %scale to millivolts to see if it changes activation
        % scaling raw V only changes scale of spectrum plots, not relationships
        % or activation values
    end
    sub_chaninfo = map.ChannelInfo(chan_range,1:2); %get recorded channel numbers and labels

end

function dt_sel_chans = remove_nans(dt_sel_chans)
    % Remove NaNs, shorten phases to equal length
    % Try changing phase 5 (gets shortened by 1 very short trial)
    % rph = dt{1,5};
    % checknans = sum(isnan(squeeze(rph(:,1,:))),1);
%     for p = 1:5
%         minL = size(dt_sel_chans{1,p}, 1);
%         tempc = dt_sel_chans{1, p};
%         tempL = min(sum(squeeze(~any(isnan(tempc), 2))));
%         % probably an easier way to do this, but I'm checking for the shortest
%         % trial excluding nans
%         minL = min(minL, tempL);
%         dt_sel_chans{1, p} = tempc(1:minL, :,:);
%         % truncating each trial to the shortest segment in each phase
%     end
    
    %Alt Method 1
    % Clip to average trial length, replace NaNs with zeros. 
    for p = 1:5
        minL = size(dt_sel_chans{1,p}, 1);
        tempc = dt_sel_chans{1, p};
        tempL = floor(mean(sum(squeeze(~any(isnan(tempc), 2)))));
        % probably an easier way to do this, but I'm checking for the shortest
        % trial excluding nans
        minL = min(minL, tempL);
        dt_sel_chans{1, p} = fillmissing(tempc(1:minL, :,:), 'constant', 0);
        % truncating each trial to the shortest segment in each phase
    end
end

function [dt_sel_chans_cavg, ph_cavg] = common_avg_ref(dt_sel_chans)
    % Common avg reference
    dt_sel_chans_cavg = cell(size(dt_sel_chans));
    ph_cavg = cell(size(dt_sel_chans));

    for p = 1:5
        subphase = dt_sel_chans{1,p};
        cavg = mean(subphase, 2);
        dt_sel_chans_cavg{1, p} = subphase - cavg;
        ph_cavg{1, p} = cavg;
    end

end

function [specgrams_cavg, specgrams_cavg_fbins, specgrams_cavg_tbins, spectrums_cavg, spectrums_cavg_fbins] = make_specs_from_cells(dt_sel_chans_cavg, Params, gpuflag, num_phase)
    % Make Spectrograms and Spectrums from averaged Spectrograms
    specgrams_cavg = cell(1,num_phase);
    spectrums_cavg = cell(1,num_phase);
    specgrams_cavg_fbins = cell(1,num_phase);
    spectrums_cavg_fbins = cell(1,num_phase);
    specgrams_cavg_tbins = cell(1,num_phase);
    num_chan = size(dt_sel_chans_cavg{1,1},2);
    num_tri = size(dt_sel_chans_cavg{1,1},3);

    %  Get spectrograms of separate phases using chronux multi-taper fft
    for p = 1:num_phase
        [specgrams_cavg{1, p}, specgrams_cavg_fbins{1, p}, specgrams_cavg_tbins{1, p}] = Analysis.DelayedReach.LFP.multiSpec(dt_sel_chans_cavg{1,p},...
        'spectrogram', 'Parameters', Params, ...
        'gpuflag', gpuflag);
        % each cell will be T x F x Ch x Tr
    end

    % PWelch spectrums
%     pw_sample_rate = 2000;
%     pw_win = 0.25 * pw_sample_rate;
%     pw_n_overlap =  0.1 * pw_sample_rate;
%     pw_n_fbins = 2000;
%     pw_fmax = 500;
%     for p = 1:num_phase
%         pw_phdt = dt_sel_chans_cavg{1, p};
%         pw_phspecs = zeros(pw_fmax,num_chan,num_tri);
%             for tr = 1:num_tri
%                 [temp_specs, temp_f] = pwelch(squeeze(pw_phdt(:,:,tr)), pw_win, pw_n_overlap, pw_n_fbins, pw_sample_rate);
%                 pw_phspecs(:,:,tr) = temp_specs(1:pw_fmax, :);
%             end
%             spectrums_cavg_fbins{1, p} = temp_f(1:pw_fmax);
%             spectrums_cavg{1, p} = pw_phspecs;
%             % each cell will be F x Ch x Tr
%             
%     end
    
    % Chronux spectrums
    chr_fmax = 500;
    
    for p = 1:num_phase
        chr_phdt = specgrams_cavg{1, p};
        f_indx = specgrams_cavg_fbins{1, p} > 0 & specgrams_cavg_fbins{1, p} < chr_fmax;
        chr_phspecs = squeeze(mean(chr_phdt(:,f_indx, :, :), 1));
        spectrums_cavg_fbins{1, p} = specgrams_cavg_fbins{1, p}(f_indx);
        spectrums_cavg{1, p} = chr_phspecs;
            % each cell will be F x Ch x Tr
            
    end
end

function spectrums_alltrialavg = all_trial_avg_spectrums(spectrums_cavg, spectrums_cavg_fbins, num_phase)
    % Mean spectral power for each channel across all trials all phases
    spectrums_cavg_mean = cell(1,num_phase);
    num_chan = size(spectrums_cavg{1,1}, 2);
    spectrums_alltrialavg = zeros(length(spectrums_cavg_fbins{1, 1}), num_chan);
    for p = 1:num_phase
        spec_avg_ph = squeeze(mean(spectrums_cavg{1,p}, 3));
    %     if p == 1
    %         ITI_avg = spec_avg_ph;
    %     end
        spectrums_cavg_mean{1, p} = spec_avg_ph;
        spectrums_alltrialavg = spectrums_alltrialavg + spec_avg_ph;
    end
    spectrums_alltrialavg = spectrums_alltrialavg ./ num_phase;



    % % remove avg ITI psd
    % for p = 1:num_phase
    %     temp_ph = spectrums_cavg{1, p};
    %     spectrums_cavg{1, p} = temp_ph - repmat(ITI_avg, [1 1 length(targets)]);
    % end
    % clear temp_ph
end
function [specs_cmpr] = compare_nrml_specs(spectrums_cavg, spectrums_alltrialavg, phases)
    s_rest = size(spectrums_cavg{1,phases(1)}, 3);
    s_move = size(spectrums_cavg{1,phases(2)}, 3);
    s_all = s_rest + s_move;
    
    
    del_move_specs = cat(3, spectrums_cavg{1,phases(1)}, spectrums_cavg{1,phases(2)}) ...
        ./ repmat(spectrums_alltrialavg, [1 1 s_all]); %psdXchXtrials
    indx_move = logical(zeros(1, s_all)'); indx_move(s_rest+1:end) = 1;
    indx_rest = logical(zeros(1, s_all)'); indx_rest(1:s_rest) = 1;
    specs_cmpr.del_move_specs = del_move_specs;
    specs_cmpr.indx_move = indx_move;
    specs_cmpr.indx_rest = indx_rest;
    
end

function [LFB, HFB] = hi_low_activation_proc(specs_cmpr, spectrums_cavg_fbins, phases, LFB_range, HFB_range, print_acts, print_figs, elecmatrix, cortex, grid_name, varargin)
    [varargin,savepath,~,~] = util.argkeyval('SavePath',varargin,env.get('results'));
    util.argempty(varargin);
    num_tri = size(specs_cmpr.del_move_specs,3);
    
    indx_LF = spectrums_cavg_fbins{1,1} >= LFB_range(1) & spectrums_cavg_fbins{1,1} <= LFB_range(2);
    indx_HF = spectrums_cavg_fbins{1,1} >= HFB_range(1) & spectrums_cavg_fbins{1,1} <= HFB_range(2);
    LFB_trials = squeeze(sum(specs_cmpr.del_move_specs(indx_LF, :, :), 1)); %chXtrials
    HFB_trials = squeeze(sum(specs_cmpr.del_move_specs(indx_HF, :, :), 1)); %chXtrials

    % Activation calcs
    LFB.LFB_activation = Analysis.DelayedReach.LFP.fband_activation(LFB_trials(:, specs_cmpr.indx_move), LFB_trials(:, specs_cmpr.indx_rest));
    [LFB.LFB_pval_bs, LFB.LFB_sig_bs] = Analysis.DelayedReach.LFP.fband_activation_bs_pvals(LFB_trials(:, specs_cmpr.indx_move), LFB_trials(:, specs_cmpr.indx_rest));
    HFB.HFB_activation =  Analysis.DelayedReach.LFP.fband_activation(HFB_trials(:, specs_cmpr.indx_move), HFB_trials(:, specs_cmpr.indx_rest));
    [HFB.HFB_pval_bs, HFB.HFB_sig_bs] = Analysis.DelayedReach.LFP.fband_activation_bs_pvals(HFB_trials(:, specs_cmpr.indx_move), HFB_trials(:, specs_cmpr.indx_rest));
    
    LFB.LFB_trials = LFB_trials;
    HFB.HFB_trials = HFB_trials;

    [~, indx_min_LFB] = min(LFB.LFB_activation);
    [~, indx_max_HFB] = max(HFB.HFB_activation);

    if print_acts
        % Print activations
        fprintf('* %s Phase %d move vs Phase %d rest* \nmax HFB: %.2f in Channel %d \nmin LFB: %.2f in Channel %d\n',...
            grid_name, phases(2), phases(1), HFB.HFB_activation(indx_max_HFB), indx_max_HFB, LFB.LFB_activation(indx_min_LFB), indx_min_LFB)
        fprintf('HFB = [%d %d]\nLFB = [%d %d]\n', HFB_range(1), HFB_range(2), LFB_range(1), LFB_range(2))        
    end
    
    if print_figs
        % Modified from Kai Miller mot_th_master and function tail_gauss_plot_redux.m
        % function [electrodes]=tail_gauss_plot_redux(electrodes,weights)
        % projects electrode locations onto their cortical spots using a gaussian kernel
        % originally from "Location on Cortex" package, (Miller, KJ, et al NeuroImage, 2007) 
        % altered for ECoG library by kjm 1/2016

        ts = sprintf('LFB [%d %d] activation P012 Phase %d vs Phase %d - %s',...
            LFB_range(1), LFB_range(2), phases(2), phases(1), grid_name);
        figure('Name', ts, 'NumberTitle', 'off');
        weights = LFB.LFB_activation .* LFB.LFB_sig_bs;
        %pt specific brain coords as 'cortex' (a freesurfer thing)
        %pt grid electrodes as 'elecmatrix'

        Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elecmatrix, cortex);
        hold on
        plot3(elecmatrix(:,1)*1.01, elecmatrix(:,2), elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])

        title(ts);
        set(gcf, 'color', 'w')

        ts = sprintf('HFB [%d %d] activation P012 Phase %d vs Phase %d - %s', ...
            HFB_range(1), HFB_range(2), phases(2), phases(1), grid_name);
        figure('Name', ts, 'NumberTitle', 'off');
        weights = HFB.HFB_activation .* HFB.HFB_sig_bs;
        %pt specific brain coords as 'cortex' (a freesurfer thing)
        %pt grid electrodes as 'elecmatrix'

        Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elecmatrix, cortex);
        hold on
        plot3(elecmatrix(:,1)*1.01, elecmatrix(:,2), elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
        title(ts);
        set(gcf, 'color', 'w')
        
        plot.save_currfig('SavePath', savepath, 'ImageType', 'fig', 'CloseFigs', true)
    end
end

function FB_all = activations_all_fb_all_ch(specs_cmpr, spectrums_cavg_fbins, print_figs, chans_plot, phases, grid_name, varargin)
    [varargin,savepath,~,~] = util.argkeyval('SavePath',varargin,env.get('results'));
    util.argempty(varargin);
    % Get activations for every channel at every frequency bin
    del_move_specs = specs_cmpr.del_move_specs;
    indx_move = specs_cmpr.indx_move;
    indx_rest = specs_cmpr.indx_rest;
    num_chan = size(del_move_specs, 2);
    num_tri = size(del_move_specs, 3);
    temp_fband_r = spectrums_cavg_fbins{1,1};
    temp_nf = length(temp_fband_r);
    bands = zeros(temp_nf,2);
    FB_activation = zeros(num_chan, temp_nf-1);
    FB_pval_bs = zeros(num_chan, temp_nf-1);
    FB_sig_bs = zeros(num_chan, temp_nf-1);
    

    for i = 1:temp_nf
        temp_fband = [temp_fband_r(i) temp_fband_r(i)];
        bands(i,:) = temp_fband;

        temp_indx_F = spectrums_cavg_fbins{1,1} >= temp_fband(1) & spectrums_cavg_fbins{1,1} <= temp_fband(2);
        FB_trials = squeeze(sum(del_move_specs(temp_indx_F, :, :), 1)); %chXtrials

        % Activation calcs
        FB_activation(:,i) = Analysis.DelayedReach.LFP.fband_activation(FB_trials(:, indx_move), FB_trials(:, indx_rest));
        [FB_pval_bs(:,i), FB_sig_bs(:,i)] = Analysis.DelayedReach.LFP.fband_activation_bs_pvals(FB_trials(:, indx_move), FB_trials(:, indx_rest));
    end
    
    FB_all.FB_activation = FB_activation;
    FB_all.FB_pval_bs = FB_pval_bs;
    FB_all.FB_sig_bs = FB_sig_bs;

%
    if print_figs
        ts = sprintf('%s All Activations All Channels Phase %d vs Phase %d', ...
           grid_name, phases(2), phases(1));
        figure('Name', ts, 'NumberTitle', 'off');
        plot(bands(:,1),FB_activation(chans_plot,:))
        title(ts)
        legend(string(chans_plot))
        plot.save_currfig('SavePath', savepath, 'ImageType', 'fig', 'CloseFigs', true)
    end
end

function FB_trials = sum_fb_stack_phase(specs_cmpr, spectrums_cavg_fbins, FB_range)
    del_move_specs = specs_cmpr.del_move_specs;

    indx_FB = spectrums_cavg_fbins{1,1} >= FB_range(1) & spectrums_cavg_fbins{1,1} <= FB_range(2);
    FB_trials = squeeze(sum(del_move_specs(indx_FB, :, :), 1)); %chXtrials
end

function full_gauss_plot(activation, sig, elecmatrix, cortex, phase_names, phases, fb_range, grid_name)
    ts = sprintf('HFB [%d %d] activation P012 %s vs %s - %s', ...
        fb_range(1), fb_range(2), phase_names{phases(2)}, phase_names{phases(1)}, grid_name);
    figure('Name', ts, 'NumberTitle', 'off');
    weights = activation .* sig;
    %pt specific brain coords as 'cortex' (a freesurfer thing)
    %pt grid electrodes as 'elecmatrix'

    Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elecmatrix, cortex);
    hold on
    plot3(elecmatrix(:,1)*1.01, elecmatrix(:,2), elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    title(ts);
    set(gcf, 'color', 'w')
end
