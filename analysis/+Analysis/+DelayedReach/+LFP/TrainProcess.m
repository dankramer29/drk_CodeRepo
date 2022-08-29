if ~exist('P012', 'var')
    load('C:\Users\Mike\Documents\results\DelayedReach\P012\Workspace\P012')
end

w_p35_lfb_rsp = P012.RSP.Ph35.LFB.LFB_activation .* P012.RSP.Ph35.LFB.LFB_sig_bs;
w_p35_hfb_rsp = P012.RSP.Ph35.HFB.HFB_activation .* P012.RSP.Ph35.HFB.HFB_sig_bs;

w_p34_lfb_rsp = P012.RSP.Ph34.LFB.LFB_activation .* P012.RSP.Ph34.LFB.LFB_sig_bs;
w_p34_hfb_rsp = P012.RSP.Ph34.HFB.HFB_activation .* P012.RSP.Ph34.HFB.HFB_sig_bs;

w_p35_lfb_rip = P012.RIP.Ph35.LFB.LFB_activation .* P012.RIP.Ph35.LFB.LFB_sig_bs;
w_p35_hfb_rip = P012.RIP.Ph35.HFB.HFB_activation .* P012.RIP.Ph35.HFB.HFB_sig_bs;

w_p34_lfb_rip = P012.RIP.Ph34.LFB.LFB_activation .* P012.RIP.Ph34.LFB.LFB_sig_bs;
w_p34_hfb_rip = P012.RIP.Ph34.HFB.HFB_activation .* P012.RIP.Ph34.HFB.HFB_sig_bs;

w_p35_lfb_mp = P012.MP.Ph35.LFB.LFB_activation .* P012.MP.Ph35.LFB.LFB_sig_bs;
w_p35_hfb_mp = P012.MP.Ph35.HFB.HFB_activation .* P012.MP.Ph35.HFB.HFB_sig_bs;

w_p34_lfb_mp = P012.MP.Ph34.LFB.LFB_activation .* P012.MP.Ph34.LFB.LFB_sig_bs;
w_p34_hfb_mp = P012.MP.Ph34.HFB.HFB_activation .* P012.MP.Ph34.HFB.HFB_sig_bs;

% combine all lfb_p35 weights in a stack, same for hfb and p34 combos.
% make electrodes into a stack in the same order as all the lfb p combos.
% should be able to then pass in one weight stack with all the electrodes
% and show all the grids at the same time. 


% Doesn’t make sense to all scale together, as each grid was common avg 
% referenced based on only the grid (so scaled to grid only, overlay each separately)

% RSP - RIP - MP
w_p35_lfb = [w_p35_lfb_rsp; w_p35_lfb_rip; w_p35_lfb_mp];
w_p35_hfb = [w_p35_hfb_rsp; w_p35_hfb_rip; w_p35_hfb_mp];
w_p34_lfb = [w_p34_lfb_rsp; w_p34_lfb_rip; w_p34_lfb_mp];
w_p34_hfb = [w_p34_hfb_rsp; w_p34_hfb_rip; w_p34_hfb_mp];


elec_stack = [P012.RSP.elecmatrix; P012.RIP.elecmatrix; P012.MP.elecmatrix];


% LFB P5 vs P3
fb1 = 18;
fb2 = 32;
p1 = 3;
p2 = 5;
weights = w_p35_lfb;
ts = sprintf('LFB [%d %d] activation P012 Phase %d vs Phase %d - All Grids',...
    fb1, fb2, p2, p1);
figure('Name', ts, 'NumberTitle', 'off');

%pt specific brain coords as 'cortex' (a freesurfer thing)
%pt grid electrodes as 'elecmatrix'

Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elec_stack, P012.cortex);
hold on
plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
hold off
title(ts);
set(gcf, 'color', 'w')


%% HFB P5 vs P3
fb1 = 76;
fb2 = 100;
p1 = 3;
p2 = 5;
weights = w_p35_hfb;

ts = sprintf('HFB [%d %d] activation P012 Phase %d vs Phase %d - All Grids',...
    fb1, fb2, p2, p1);
figure('Name', ts, 'NumberTitle', 'off');
%pt specific brain coords as 'cortex' (a freesurfer thing)
%pt grid electrodes as 'elecmatrix'
Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elec_stack, P012.cortex);
hold on
plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
hold off
title(ts);
set(gcf, 'color', 'w')
%%
% LFB P4 vs P3
fb1 = 18;
fb2 = 32;
p1 = 3;
p2 = 4;
weights = w_p34_lfb;
ts = sprintf('LFB [%d %d] activation P012 Phase %d vs Phase %d - All Grids',...
    fb1, fb2, p2, p1);
figure('Name', ts, 'NumberTitle', 'off');

%pt specific brain coords as 'cortex' (a freesurfer thing)
%pt grid electrodes as 'elecmatrix'

Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elec_stack, P012.cortex);
hold on
plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
hold off
title(ts);
set(gcf, 'color', 'w')

% HFB P5 vs P3
fb1 = 76;
fb2 = 100;
p1 = 3;
p2 = 4;
weights = w_p34_hfb;

ts = sprintf('HFB [%d %d] activation P012 Phase %d vs Phase %d - All Grids',...
    fb1, fb2, p2, p1);
figure('Name', ts, 'NumberTitle', 'off');
%pt specific brain coords as 'cortex' (a freesurfer thing)
%pt grid electrodes as 'elecmatrix'
Analysis.DelayedReach.LFP.plot_gauss_activation(weights, elec_stack, P012.cortex);
hold on
plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
hold off
title(ts);
set(gcf, 'color', 'w')


%% Gather tuning info
rsquares = P012.MP.Ph34.tuning.HZ_76_100.fit_data.gof.rsquare;
rsquare_avg = mean(rsquares);
rsquare_std = std(rsquares);
rsquare_sig = rsquares > rsquare_avg + (2*rsquare_std);
rsquare_sig_chans = P012.MP.sub_chaninfo{rsquare_sig,'Channel'} - (P012.MP.sub_chaninfo{1,'Channel'} - 1)

% Plot a channel's tuning
% moved to KM_Method_Plots.m
    
%% activation over time, movie
% ITI
p1 = 3;
fr = 0;
FB_range = [8 32];
grid = P012.RSP;
grid_n = 'RSP';
vidstring = sprintf('Del-Resp-vs-Cue-LFB-%s',grid_n);
saveloc = 'C:\Users\Mike\Documents\results\DelayedReach\P012\Fig_Results';
t_FPS = 2;
VideoObj = VideoWriter(fullfile(saveloc, vidstring));
VideoObj.FrameRate = t_FPS;
open(VideoObj);

% % ITI
% phases = [p1 1];

% activs = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     grid.specgrams_cavg, grid.specgrams_cavg_fbins,...
%     grid.spectrums_alltrialavg, phases, FB_range);
% % now each channel has a HFB activation value for every time bin during the
% % response phase. 
% t_sig = grid.Ph34.HFB.HFB_sig_bs;
% % using significance from entire response phase instead of bootstrapping a
% % significance for each time-step (for now?).
% t_n_frames = size(activs, 1);
% for i = 1:t_n_frames
%     fr = fr + 1;
%     t_f = figure;
%     weights = activs(i,:)';% .* t_sig;
%     Analysis.DelayedReach.LFP.plot_gauss_activation(weights, grid.elecmatrix, P012.cortex);
%     hold on
%     plot3(grid.elecmatrix(:,1)*1.01, grid.elecmatrix(:,2), grid.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
%     set(gcf, 'color', 'w')
%     ts = sprintf('%d ITI', fr);
%     title(ts)
%     writeVideo(VideoObj, getframe(gcf));
%     close(t_f)
% end
% 
% % Fixate
% phases = [p1 2];

% activs = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     grid.specgrams_cavg, grid.specgrams_cavg_fbins,...
%     grid.spectrums_alltrialavg, phases, FB_range);
% % now each channel has a HFB activation value for every time bin during the
% % response phase. 
% t_sig = grid.Ph34.HFB.HFB_sig_bs;
% % using significance from entire response phase instead of bootstrapping a
% % significance for each time-step (for now?).
% t_n_frames = size(activs, 1);
% for i = 1:t_n_frames
%     fr = fr + 1;
%     t_f = figure;
%     weights = activs(i,:)';% .* t_sig;
%     Analysis.DelayedReach.LFP.plot_gauss_activation(weights, grid.elecmatrix, P012.cortex);
%     hold on
%     plot3(grid.elecmatrix(:,1)*1.01, grid.elecmatrix(:,2), grid.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
%     set(gcf, 'color', 'w')
%     ts = sprintf('%d Fixate', fr);
%     title(ts)
%     writeVideo(VideoObj, getframe(gcf));
%     close(t_f)
% end


% % Cue
% phases = [p1 3];

% activs = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     grid.specgrams_cavg, grid.specgrams_cavg_fbins,...
%     grid.spectrums_alltrialavg, phases, FB_range);
% % now each channel has a HFB activation value for every time bin during the
% % response phase. 
% t_sig = grid.Ph34.HFB.HFB_sig_bs;
% % using significance from entire response phase instead of bootstrapping a
% % significance for each time-step (for now?).
% t_n_frames = size(activs, 1);
% for i = 1:t_n_frames
%     fr = fr + 1;
%     t_f = figure;
%     weights = activs(i,:)';% .* t_sig;
%     Analysis.DelayedReach.LFP.plot_gauss_activation(weights, grid.elecmatrix, P012.cortex);
%     hold on
%     plot3(grid.elecmatrix(:,1)*1.01, grid.elecmatrix(:,2), grid.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
%     set(gcf, 'color', 'w')
%     ts = sprintf('%d Cue', fr);
%     title(ts)
%     writeVideo(VideoObj, getframe(gcf));
%     close(t_f)
% end


% Delay
phases = [p1 4];

activs = Analysis.DelayedReach.LFP.spectrogram_activations(...
    grid.specgrams_cavg, grid.specgrams_cavg_fbins,...
    grid.spectrums_alltrialavg, phases, FB_range);
% now each channel has a HFB activation value for every time bin during the
% response phase. 
t_sig = grid.Ph34.HFB.HFB_sig_bs;
% using significance from entire response phase instead of bootstrapping a
% significance for each time-step (for now?).
t_n_frames = size(activs, 1);
% t_FPS = 2;
% VideoObj = VideoWriter('C:\Users\Mike\Documents\results\DelayedReach\P012\Fig_Results\video.avi');
% VideoObj.FrameRate = t_FPS;
% open(VideoObj);
for i = 1:t_n_frames
    fr = fr + 1;
    t_f = figure;
    weights = activs(i,:)' .* t_sig;
    Analysis.DelayedReach.LFP.plot_gauss_activation(weights, grid.elecmatrix, P012.cortex);
    hold on
    plot3(grid.elecmatrix(:,1)*1.01, grid.elecmatrix(:,2), grid.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    set(gcf, 'color', 'w')
    ts = sprintf('%d Delay', fr);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end


% Respond
phases = [p1 5];
FB_range = [76 100];
activs = Analysis.DelayedReach.LFP.spectrogram_activations(...
    grid.specgrams_cavg, grid.specgrams_cavg_fbins,...
    grid.spectrums_alltrialavg, phases, FB_range);
t_sig = grid.Ph35.HFB.HFB_sig_bs;
t_n_frames = size(activs, 1);
for i = 1:t_n_frames
    fr = fr + 1;
    t_f = figure;
    weights = activs(i,:)' .* t_sig;
    Analysis.DelayedReach.LFP.plot_gauss_activation(weights, grid.elecmatrix, P012.cortex);
    hold on
    plot3(grid.elecmatrix(:,1)*1.01, grid.elecmatrix(:,2), grid.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    set(gcf, 'color', 'w')
    ts = sprintf('%d Response', fr);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end


close(VideoObj);

    
%% Trying new method to remove NaNs but increase trial length
% Remove NaNs 
% dt_sel_chans1 = cell(size(P012.dt));
%     for p = 1:5
%         minL = size(dt_sel_chans{1,p}, 1);
%         tempc = dt_sel_chans{1, p};
%         tempL = floor(mean(sum(squeeze(~any(isnan(tempc), 2)))));
%         % probably an easier way to do this, but I'm checking for the shortest
%         % trial excluding nans
%         minL = min(minL, tempL);
%         dt_sel_chans1{1, p} = fillmissing(tempc(1:minL, :,:), 'constant', 0);
%         % truncating each trial to the shortest segment in each phase
%     end
% % Cavg
% dt_sel_chans_cavg = cell(size(dt_sel_chans1));
% ph_cavg = cell(size(dt_sel_chans1));
% 
%     for p = 1:5
%         subphase = dt_sel_chans1{1,p};
%         cavg = mean(subphase, 2);
%         dt_sel_chans_cavg{1, p} = subphase - cavg;
%         ph_cavg{1, p} = cavg;
%     end
    
    
    
%% flip it
% Cavg first, ignoring NaN values, this way each channel has a cavg with
% values all the way through. When subtracted from a NaN, will yield a NaN,
% so those NaNs still hold value. 
% dt_sel_chans_cavg2 = cell(size(dt_sel_chans));
% ph_cavg2 = cell(size(dt_sel_chans));
% 
%     for p = 1:5
%         subphase = dt_sel_chans{1,p};
%         cavg = mean(subphase, 2, 'omitnan');
%         dt_sel_chans_cavg2{1, p} = subphase - cavg;
%         ph_cavg{1, p} = cavg;
%     end
%     
% % Remove NaNs 
% dt_sel_chans2 = cell(size(P012.dt));
%     for p = 1:5
%         minL = size(dt_sel_chans{1,p}, 1);
%         tempc = dt_sel_chans{1, p};
%         tempL = floor(mean(sum(squeeze(~any(isnan(tempc), 2)))));
%         % probably an easier way to do this, but I'm checking for the shortest
%         % trial excluding nans
%         minL = min(minL, tempL);
%         tc = tempc(1:minL, :, :);
%         dt_sel_chans2{1, p} = fillmissing(tempc(1:minL, :,:), 'constant', 0);
%         % truncating each trial to the shortest segment in each phase
%     end
    
%% Trying to plot all grids' activations as gaussian brain overlay, in one figure
% putting all weights together
% passing all weights at once causes all weights smaller than the max to be
% drowned out by the gaussian shading, because electrodes farther from the
% electrode of interest are shaded down more than electrodes closer. So an
% electrodes weight may be comparable to another grids, but because the
% grid is farther away, the weights get diminished. 

FB_range = [76 100];
elec_stack = [P012.MP.elecmatrix; P012.RIP.elecmatrix;  P012.RSP.elecmatrix];
grid_n = 'All Grids';
vidstring = sprintf('Del-Resp-vs-Cue-HFB-%s-b',grid_n);
saveloc = 'C:\Users\mbarb\Documents\results\DelayedReach\P012\Fig_Results';
t_FPS = 2;
VideoObj = VideoWriter(fullfile(saveloc, vidstring), 'MPEG-4');
VideoObj.FrameRate = t_FPS;
open(VideoObj);
fr = 0;
% cue vs cue
phases = [3 3];
% t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
%     P012.RSP.spectrums_alltrialavg, phases, FB_range);
% t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
%     P012.RIP.spectrums_alltrialavg, phases, FB_range);
% t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
%     P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);


weights = [t_a1'; t_a2'; t_a3'];


for i = 1:size(weights,2)
    fr = fr + 1;
    t_f = figure;
    Analysis.DelayedReach.LFP.plot_gauss_activation(weights(:,i), elec_stack, P012.cortex);
    hold on
    plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    hold off
    set(gcf, 'color', 'w')
    ts = sprintf('%d Cue', fr);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end

% delay vs cue
phases = [3 4];
% t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
%     P012.RSP.spectrums_alltrialavg, phases, FB_range);
% t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
%     P012.RIP.spectrums_alltrialavg, phases, FB_range);
% t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
%     P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);

% weights = [t_a1' .* P012.RSP.Ph34.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph34.HFB.HFB_sig_bs; t_a3' .* P012.MP.Ph34.HFB.HFB_sig_bs];
weights = [t_a1' .* P012.MP.Ph34.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph34.HFB.HFB_sig_bs; t_a3' .* P012.RSP.Ph34.HFB.HFB_sig_bs];

for i = 1:size(weights,2)
    fr = fr + 1;
    t_f = figure;
    Analysis.DelayedReach.LFP.plot_gauss_activation(weights(:,i), elec_stack, P012.cortex);
    hold on
    plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    hold off
    set(gcf, 'color', 'w')
    ts = sprintf('%d Delay', fr);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end

% respond vs cue
phases = [3 5];
% t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
%     P012.RSP.spectrums_alltrialavg, phases, FB_range);
% t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
%     P012.RIP.spectrums_alltrialavg, phases, FB_range);
% t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
%     P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);
% weights = [t_a1' .* P012.RSP.Ph35.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph35.HFB.HFB_sig_bs; t_a3' .* P012.MP.Ph35.HFB.HFB_sig_bs];
weights = [t_a1' .* P012.MP.Ph35.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph35.HFB.HFB_sig_bs; t_a3' .* P012.RSP.Ph35.HFB.HFB_sig_bs];
for i = 1:size(weights,2)
    fr = fr + 1;
    t_f = figure;
    Analysis.DelayedReach.LFP.plot_gauss_activation(weights(:,i), elec_stack, P012.cortex);
    hold on
    plot3(P012.RSP.elecmatrix(:,1)*1.01, P012.RSP.elecmatrix(:,2), P012.RSP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(P012.RIP.elecmatrix(:,1)*1.01, P012.RIP.elecmatrix(:,2), P012.RIP.elecmatrix(:,3),'.','MarkerSize',12,'Color',[.99 .99 .99])
    plot3(P012.MP.elecmatrix(:,1)*1.01, P012.MP.elecmatrix(:,2), P012.MP.elecmatrix(:,3),'.','MarkerSize',5,'Color',[.99 .99 .99])
    hold off
    set(gcf, 'color', 'w')
    ts = sprintf('%d Response', fr);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end

      
      
close(VideoObj);
      
      
      
      
%%
% elec_stack = [P012.MP.elecmatrix; P012.RIP.elecmatrix;  P012.RSP.elecmatrix];
phases = [3 5];
FB_range = [76 100];
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);

% Analysis.DelayedReach.LFP.plot_gauss_activation_multi(...
%     P012.MP.Ph35.HFB.HFB_activation, P012.MP.elecmatrix,...
%     P012.RIP.Ph35.HFB.HFB_activation, P012.RIP.elecmatrix,...
%     P012.RSP.Ph35.HFB.HFB_activation, P012.RSP.elecmatrix,...
%     P012.cortex)

Analysis.DelayedReach.LFP.plot_gauss_activation_multi(...
    mean(t_a1)', P012.MP.elecmatrix,...
    mean(t_a2)', P012.RIP.elecmatrix,...
    mean(t_a3)', P012.RSP.elecmatrix,...
    P012.cortex)

%%
% putting all weights together
% passing all weights at once causes all weights smaller than the max to be
% drowned out by the gaussian shading, because electrodes farther from the
% electrode of interest are shaded down more than electrodes closer. So an
% electrodes weight may be comparable to another grids, but because the
% grid is farther away, the weights get diminished. 

FB_range = [8 32];
elec_stack = [P012.MP.elecmatrix; P012.RIP.elecmatrix;  P012.RSP.elecmatrix];
grid_n = 'All Grids';
fb = 'LFB';
vidstring = sprintf('Del-Resp-Cue-vs-Fixate-%s-%s',fb, grid_n);
saveloc = 'C:\Users\Mike\Documents\results\DelayedReach\P012\Fig_Results';
t_FPS = 2;
VideoObj = VideoWriter(fullfile(saveloc, vidstring));
VideoObj.FrameRate = t_FPS;
open(VideoObj);
fr = 0;
% cue vs cue
phases = [2 3];
% t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
%     P012.RSP.spectrums_alltrialavg, phases, FB_range);
% t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
%     P012.RIP.spectrums_alltrialavg, phases, FB_range);
% t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
%     P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);



for i = 1:size(t_a1,1)
    fr = fr + 1;
    t_f = figure;
    Analysis.DelayedReach.LFP.plot_gauss_activation_multi(...
    t_a1(i,:)', P012.MP.elecmatrix,...
    t_a2(i,:)', P012.RIP.elecmatrix,...
    t_a3(i,:)', P012.RSP.elecmatrix,...
    P012.cortex)
    set(gcf, 'color', 'w')
    ts = sprintf('%d Cue %s', fr, fb);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end

% delay vs cue
phases = [2 4];
% t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
%     P012.RSP.spectrums_alltrialavg, phases, FB_range);
% t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
%     P012.RIP.spectrums_alltrialavg, phases, FB_range);
% t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
%     P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);

% weights = [t_a1' .* P012.RSP.Ph34.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph34.HFB.HFB_sig_bs; t_a3' .* P012.MP.Ph34.HFB.HFB_sig_bs];

for i = 1:size(t_a1,1)
    fr = fr + 1;
    t_f = figure;
    Analysis.DelayedReach.LFP.plot_gauss_activation_multi(...
    t_a1(i,:)', P012.MP.elecmatrix,...
    t_a2(i,:)', P012.RIP.elecmatrix,...
    t_a3(i,:)', P012.RSP.elecmatrix,...
    P012.cortex)
    ts = sprintf('%d Delay %s', fr, fb);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end

% respond vs cue
phases = [2 5];
% t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
%     P012.RSP.spectrums_alltrialavg, phases, FB_range);
% t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
%     P012.RIP.spectrums_alltrialavg, phases, FB_range);
% t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
%     P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
%     P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a1 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.MP.specgrams_cavg, P012.MP.specgrams_cavg_fbins,...
    P012.MP.spectrums_alltrialavg, phases, FB_range);
t_a2 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RIP.specgrams_cavg, P012.RIP.specgrams_cavg_fbins,...
    P012.RIP.spectrums_alltrialavg, phases, FB_range);
t_a3 = Analysis.DelayedReach.LFP.spectrogram_activations(...
    P012.RSP.specgrams_cavg, P012.RSP.specgrams_cavg_fbins,...
    P012.RSP.spectrums_alltrialavg, phases, FB_range);
% weights = [t_a1' .* P012.RSP.Ph35.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph35.HFB.HFB_sig_bs; t_a3' .* P012.MP.Ph35.HFB.HFB_sig_bs];
% weights = [t_a1' .* P012.MP.Ph35.HFB.HFB_sig_bs; t_a2' .* P012.RIP.Ph35.HFB.HFB_sig_bs; t_a3' .* P012.RSP.Ph35.HFB.HFB_sig_bs];



for i = 1:size(t_a1,1)
    fr = fr + 1;
    t_f = figure;
    Analysis.DelayedReach.LFP.plot_gauss_activation_multi(...
    t_a1(i,:)', P012.MP.elecmatrix,...
    t_a2(i,:)', P012.RIP.elecmatrix,...
    t_a3(i,:)', P012.RSP.elecmatrix,...
    P012.cortex)
    ts = sprintf('%d Response %s', fr, fb);
    title(ts)
    writeVideo(VideoObj, getframe(gcf));
    close(t_f)
end

      
      
close(VideoObj);
