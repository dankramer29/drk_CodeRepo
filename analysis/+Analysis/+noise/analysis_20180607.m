% look at coherence in regressed data

%% parameters
movingwin = [2 0.2];
params = struct('Fs',2e3,'pad',1,'fpass',[0 200],'tapers',[3 5],'trialave',0,'err',0);
channels = {'L_PAR3','R_PAR4'};

%% resources
blc_orig = BLc.Reader('C:\Users\spenc\Documents\Research\Keck\Data\P010\20170823-PH2\20170830\20170830-132252-132257-DelayedReach-AllGrids-001-fs2k.blc');
blc_lmresid = BLc.Reader('C:\Users\spenc\Documents\Research\Keck\Data\P010\20170823-PH2\20170830\lm_grid\20170830-132252-132257-DelayedReach-AllGrids-001-fs2k_lmresid.blc');
blc_lmfit = BLc.Reader('C:\Users\spenc\Documents\Research\Keck\Data\P010\20170823-PH2\20170830\lm_grid\20170830-132252-132257-DelayedReach-AllGrids-001-fs2k_lmfit.blc');
map = GridMap('C:\Users\spenc\Documents\Research\Keck\Data\P010\20170823-PH2\20170830\20170830-132252-132257-DelayedReach-AllGrids-001.map');

%% data
data_car = nan(max([blc.DataInfo.NumRecords]),2);
for cc=1:length(channels)
    channel_number = strcmpi(map.ChannelInfo.ChannelLabel,channels{cc});
    grid_number = map.ChannelInfo.GridNumber(channel_number);
    grid_channels = map.GridInfo.Channels{grid_number};
    data_car_ref = blc_orig.read('channels',grid_channels,'context','section');
    data_car(:,cc) = blc_orig.read('channels',channels{cc},'context','section');
    data_car(:,cc) = data_car(:,cc) - mean(data_car_ref,2);
end
clear data_car_ref;
data_orig = blc_orig.read('channels',channels,'context','section');
data_lmresid = blc_lmresid.read('channels',channels,'context','section');
data_lmfit = blc_lmfit.read('channels',channels,'context','section');


%% coherence
[C_car,phi_car,S12_car,S1_car,S2_car,t_car,f_car]=chronux.ct.cohgramc(data_car(:,1),data_car(:,2),movingwin,params);
[C_orig,phi_orig,S12_orig,S1_orig,S2_orig,t_orig,f_orig]=chronux.ct.cohgramc(data_orig(:,1),data_orig(:,2),movingwin,params);
[C_lmresid,phi_lmresid,S12_lmresid,S1_lmresid,S2_lmresid,t_lmresid,f_lmresid]=chronux.ct.cohgramc(data_lmresid(:,1),data_lmresid(:,2),movingwin,params);
[C_lmfit,phi_lmfit,S12_lmfit,S1_lmfit,S2_lmfit,t_lmfit,f_lmfit]=chronux.ct.cohgramc(data_lmfit(:,1),data_lmfit(:,2),movingwin,params);


%% plot 1 - magnitude/phase coherence

figure('Position',[50 100 1900 800]);
axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_orig,f_orig,C_orig'); axis xy;
set(gca,'CLim',[0 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Magnitude (%s vs %s) (As Recorded)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Magnitude Coherence'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);
axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_orig,f_orig,phi_orig'/pi); axis xy;
set(gca,'CLim',[-1 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Phase (%s vs %s) (As Recorded)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Phase \times\pi'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);

figure('Position',[50 100 1900 800]);
axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_car,f_car,C_car'); axis xy;
set(gca,'CLim',[0 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Magnitude (%s vs %s) (CAR)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Magnitude Coherence'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);
axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_car,f_car,phi_car'); axis xy;
set(gca,'CLim',[-1 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Phase (%s vs %s) (CAR)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Phase \times\pi'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);

figure('Position',[50 100 1900 800]);
axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_lmresid,f_lmresid,C_lmresid'); axis xy;
set(gca,'CLim',[0 1]);
axc = colorbar; h = ylabel(axc,'Magnitude Coherence'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Magnitude (%s vs %s) (LM Residual)',channels{1},channels{2}),'Interpreter','none');
axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_lmresid,f_lmresid,phi_lmresid'); axis xy;
set(gca,'CLim',[-1 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Phase (%s vs %s) (LM Residual)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Phase \times\pi'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);

figure('Position',[50 100 1900 800]);
axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_lmfit,f_lmfit,C_lmfit'); axis xy;
set(gca,'CLim',[0 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Magnitude (%s vs %s) (LM Fitted)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Magnitude Coherence'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);
axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_lmfit,f_lmfit,phi_lmfit'); axis xy;
set(gca,'CLim',[-1 1]);
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Coherence Phase (%s vs %s) (LM Fitted)',channels{1},channels{2}),'Interpreter','none');
axc = colorbar; h = ylabel(axc,'Phase (\times\pi)'); set(h,'Rotation',270);
drawnow; pos = get(h,'Position'); set(h,'Position',[pos(1)+0.6 pos(2) pos(3)]);


%% plot 2 - mean coherence 140-144 Hz (freqency band of the touchscreen noise)
idx = f_orig>=140 & f_orig<=145;

figure('Position',[50 100 1900 700]);
axes('Position',[0.04 0.56 0.94 0.39]); 
plot(t_orig,mean(C_orig(:,idx),2),'linewidth',2); hold on;
plot(t_car,mean(C_car(:,idx),2),'linewidth',2);
plot(t_lmresid,mean(C_lmresid(:,idx),2),'linewidth',2);
plot(t_lmfit,mean(C_lmfit(:,idx),2),'linewidth',2); hold off;
xlabel('Time (sec)'); ylabel('Magnitude Coherence'); title(sprintf('Mean Coherence 140-145 Hz (%s vs %s)',channels{1},channels{2}),'Interpreter','none');
legend({'As Recorded','CAR','LM (Fitted)','LM (Residual)'});
axes('Position',[0.04 0.07 0.94 0.39]); 
plot(t_orig,mean(10*log10(abs(S12_orig(:,idx))),2),'linewidth',2); hold on;
plot(t_car,mean(10*log10(abs(S12_car(:,idx))),2),'linewidth',2);
plot(t_lmresid,mean(10*log10(abs(S12_lmresid(:,idx))),2),'linewidth',2);
plot(t_lmfit,mean(10*log10(abs(S12_lmfit(:,idx))),2),'linewidth',2); hold off;
xlabel('Time (sec)'); ylabel('Power (dB)'); title(sprintf('Mean Cross-Power 140-145 Hz (%s vs %s)',channels{1},channels{2}),'Interpreter','none');
legend({'As Recorded','CAR','LM (Fitted)','LM (Residual)'});


%% plot 3 - power spectrum of individual channels

figure('Position',[50 100 1900 700]);
axs(1) = axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_orig,f_orig,10*log10(S1_orig)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (As Recorded)',channels{1}),'Interpreter','none');
axc(1) = colorbar;
axs(2) = axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_orig,f_orig,10*log10(S2_orig)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (As Recorded)',channels{2}),'Interpreter','none');
axc(2) = colorbar;

figure('Position',[50 100 1900 700]);
axs(3) = axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_car,f_car,10*log10(S1_car)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (CAR)',channels{1}),'Interpreter','none');
axc(3) = colorbar;
axs(4) = axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_car,f_car,10*log10(S2_car)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (CAR)',channels{2}),'Interpreter','none');
axc(4) = colorbar;

figure('Position',[50 100 1900 700]);
axs(5) = axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_lmresid,f_lmresid,10*log10(S1_lmresid)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (LM Residual)',channels{1}),'Interpreter','none');
axc(5) = colorbar;
axs(6) = axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_lmresid,f_lmresid,10*log10(S2_lmresid)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (LM Residual)',channels{2}),'Interpreter','none');
axc(6) = colorbar;

figure('Position',[50 100 1900 700]);
axs(7) = axes('Position',[0.04 0.56 0.94 0.39]); imagesc(t_lmfit,f_lmfit,10*log10(S1_lmfit)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (LM Fitted)',channels{1}),'Interpreter','none');
axc(7) = colorbar;
axs(8) = axes('Position',[0.04 0.07 0.94 0.39]); imagesc(t_lmfit,f_lmfit,10*log10(S2_lmfit)'); axis xy;
xlabel('Time (sec)'); ylabel('Frequency (Hz)'); title(sprintf('Spectrum (%s) (LM Fitted)',channels{2}),'Interpreter','none');
axc(8) = colorbar;

% uniform color limits
yl = arrayfun(@(x)get(x,'CLim'),axs,'UniformOutput',false);
yl = cat(1,yl{:});
yl = [min(yl(:,1)) max(yl(:,2))];
arrayfun(@(x)set(x,'CLim',yl),axs);
drawnow;
h = arrayfun(@(x)ylabel(x,'Power (dB)'),axc,'UniformOutput',false);
cellfun(@(x)set(x,'Rotation',270),h);
drawnow;
pos = cellfun(@(x)get(x,'Position'),h,'UniformOutput',false);
cellfun(@(x,y)set(x,'Position',[y(1)+0.6 sum(yl)/2 y(3)]),h,pos);