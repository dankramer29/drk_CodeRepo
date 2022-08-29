[~, ~, rsqrs_rsp] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
    P012.RSP.Ph35.HFB.HFB_trials(:,P012.RSP.Ph35.specs_cmpr.indx_move), P012.RSP.Ph35.HFB.HFB_trials(:,P012.RSP.Ph35.specs_cmpr.indx_rest), P012.targets);
fprintf('Done with RSP\n')
[~, ~, rsqrs_mp] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
    P012.MP.Ph35.HFB.HFB_trials(:,P012.MP.Ph35.specs_cmpr.indx_move), P012.MP.Ph35.HFB.HFB_trials(:,P012.MP.Ph35.specs_cmpr.indx_rest), P012.targets);
fprintf('Done with MP\n')
[~, ~, rsqrs_rip] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
    P012.RIP.Ph35.HFB.HFB_trials(:,P012.RIP.Ph35.specs_cmpr.indx_move), P012.RIP.Ph35.HFB.HFB_trials(:,P012.RIP.Ph35.specs_cmpr.indx_rest), P012.targets);
fprintf('Done with RIP\n')
P012.RSP.Ph35.tuning.HZ_76_100.fit_data.sh_rsqrs = rsqrs_rsp;
P012.RIP.Ph35.tuning.HZ_76_100.fit_data.sh_rsqrs = rsqrs_rip;
P012.MP.Ph35.tuning.HZ_76_100.fit_data.sh_rsqrs = rsqrs_mp;
fprintf('Done with Phase 3vs5\n')
clearvars -except P012
% rsqr_sig_RSP = P012.RSP.Ph35.tuning.HZ_76_100.fit_data.gof.rsquare > rsqrs_rsp(:, 10000 * 0.95);
% 
% rsqr_sig_MP = P012.MP.Ph35.tuning.HZ_76_100.fit_data.gof.rsquare > rsqrs_mp(:, 10000 * 0.95);
% 
% rsqr_sig_RIP = P012.RIP.Ph35.tuning.HZ_76_100.fit_data.gof.rsquare > rsqrs_rip(:, 10000 * 0.95);



%%
[~, ~, rsqrs_rsp] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
    P012.RSP.Ph34.HFB.HFB_trials(:,P012.RSP.Ph34.specs_cmpr.indx_move), P012.RSP.Ph34.HFB.HFB_trials(:,P012.RSP.Ph34.specs_cmpr.indx_rest), P012.targets);
fprintf('Done with RSP\n')

[~, ~, rsqrs_mp] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
    P012.MP.Ph34.HFB.HFB_trials(:,P012.MP.Ph34.specs_cmpr.indx_move), P012.MP.Ph34.HFB.HFB_trials(:,P012.MP.Ph34.specs_cmpr.indx_rest), P012.targets);
fprintf('Done with MP\n')
[~, ~, rsqrs_rip] = Analysis.DelayedReach.LFP.bs_activation_tuning(...
    P012.RIP.Ph34.HFB.HFB_trials(:,P012.RIP.Ph34.specs_cmpr.indx_move), P012.RIP.Ph34.HFB.HFB_trials(:,P012.RIP.Ph34.specs_cmpr.indx_rest), P012.targets);
fprintf('Done with RIP\n')


P012.RSP.Ph34.tuning.HZ_76_100.fit_data.sh_rsqrs = rsqrs_rsp;
P012.RIP.Ph34.tuning.HZ_76_100.fit_data.sh_rsqrs = rsqrs_rip;
P012.MP.Ph34.tuning.HZ_76_100.fit_data.sh_rsqrs = rsqrs_mp;
fprintf('Done with Phase 3vs4\n')

clearvars -except P012

%%
ch=8;
fprintf('Ch %d rsquare: %f\n', ch, P012.RIP.Ph34.tuning.HZ_76_100.fit_data.sh_rsqrs(ch,9500))
% histogram(rsqrs_rip(ch,:),[0:0.01:1])
% ts = sprintf('Distribution of r^2 fits for Channel %d of RIP', ch);
% title(ts)