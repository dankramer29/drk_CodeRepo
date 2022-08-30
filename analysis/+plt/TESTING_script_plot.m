


%% spectrograms for each patient
%If there is nothing positive in the cluster, do caxis([0 1]) to make it
%black
figure
set(0, 'DefaultAxesFontSize', 22)
%change the person here
tt=specgramcJR2.SoftTouch.t;
ff=specgramcJR2.SoftTouch.f;
szr=9; szc=3;

subplot(szr,szc,[1:6])
imagesc(t, f, specgramcJR2.DeepTouch.MOTOR34); axis xy; colormap(inferno);
axis xy;
xlim([-0.1 1.6])
ax=gca;
title(['Deep Touch'])
xlabel('Time (s)','Fontsize',22);
ylabel('Frequency (Hz)','Fontsize',22);
ax.YTick=(0:20:125);
colorbar;
colormap(inferno(100));
set(gca,'XTickLabel',[]);


subplot(szr,szc,7)
temp_p=double(elec_pJR2.DeepTouch{1,1}.clust_p');
imagesc(t, f, temp_p); 
colormap(inferno);
axis xy;
xlim([-0.1 1.6])
ax=gca;
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);


subplot(szr,szc,[10:15])
imagesc(t, f, specgramcJR2.LightTouch.MOTOR34); axis xy; colormap(inferno);
axis xy;
xlim([-0.1 1.6])
ax=gca;
title(['Light Touch'])
xlabel('Time (s)','Fontsize',22);
ylabel('Frequency (Hz)','Fontsize',22);
colorbar;
colormap(inferno(100));
ax.YTick=(0:20:125);
set(gca,'XTickLabel',[]);


subplot(szr,szc,16)
temp_p=double(elec_pJR2.LightTouch{1,1}.clust_p');
imagesc(t, f, temp_p); 
colormap(inferno);
axis xy;
xlim([-0.1 1.6])
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);

subplot(szr,szc,[19:24])
imagesc(t, f, specgramcJR2.SoftTouch.MOTOR34); axis xy; colormap(inferno);
axis xy;
xlim([-0.1 1.6])
ax=gca;
title(['Soft Touch'])
xlabel('Time (s)','Fontsize',22);
ylabel('Frequency (Hz)','Fontsize',22);
colorbar;
colormap(inferno(100));
ax.YTick=(0:20:125);

h=subplot(szr,szc,25)
temp_p=double(elec_pJR2.SoftTouch{1,1}.clust_p');
imagesc(t, f, temp_p); 
colormap(inferno);
axis xy;
xlim([-0.1 1.6])
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
pos=get(h, 'Position');
pos(2)=pos(2)-0.01;
set(h, 'Position', pos);



