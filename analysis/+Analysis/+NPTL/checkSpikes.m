function [allChSpk,allTrialSpk] = checkSpikes(targetSpkAll,targetCp)
%examine the spike changes around target appearance
%   works within Analysis.NPTL.procDataGridT
% Example
%[allChSpk,allTrialSpk] = Analysis.NPTL.checkSpikes(targetSpkAll,targetCp);

%Spikes and movement over time
per=300;
perSp=per/20;


allChSpk=squeeze(mean(targetSpkAll,2));
allChSpkShort=allChSpk(round(size(allChSpk,1)/2-perSp)+1:round(size(allChSpk,1)/2+perSp),:);
allTrialSpk=squeeze(mean(targetSpkAll,3));
%remove noisey channels

allTrialSpkShort=allTrialSpk(round(size(allChSpk,1)/2-perSp)+1:round(size(allChSpk,1)/2+perSp),:);

%if speed is not already calculated, calculate it
if sum(targetCp(4,:))==0
    speedPos(1,:,:)=diff(targetCp(1,:,:));
    speedPos(2,:,:)=diff(targetCp(2,:,:));
else
    speedPos(1,:)=targetCp(2,:,:);
    speedPos(2,:)=targetCp(4,:,:);
end
%get the speed magnitude
spd=zeros(size(speedPos,2),2);
for ii=1:size(targetCp,3)
    spd(:,ii)=sqrt(speedPos(1,:,ii).^2+speedPos(2,:,ii).^2);
end
spdShort=spd(round(length(spd)/2)-per+1:round(length(spd)/2)+per, :);
tmTS=linspace(-1000, 1000, size(allTrialSpk,1));
tmTSShort=linspace(-per, per, size(allChSpkShort,1));
trials=1:size(targetSpkAll,3);
chan=1:size(targetSpkAll,2);
tmTcp=linspace(-1000, 1000, size(spd,1));
tmTcpShort=linspace(-per, per, size(spdShort,1));

figure
set(gca,'FontSize', 22) 
sgtitle('Spike changes around target appearance')

subplot(3,2,1)
imagesc(tmTS, trials, allChSpk'); axis xy;
title('Smooth spiking activity across all trials')
xlabel('Time (ms)');
ylabel('Trials');
colorbar

subplot(3,2,3)
imagesc(tmTcp, trials, spd'); axis xy;
title('Speed changes over time')
xlabel('Time (ms)');
ylabel('Trials');
colorbar

subplot(3,2,5)
imagesc(tmTS, chan, allTrialSpk'); axis xy;
title('Smooth spiking activity across all channels')
xlabel('Time (ms)');
ylabel('Channels');
colorbar

subplot(3,2,2)
imagesc(tmTSShort, trials, allChSpkShort'); axis xy;
title('Smooth spiking activity across all trials')
xlabel('Time (ms)');
ylabel('Trials');
colorbar

subplot(3,2,4)
imagesc(tmTcpShort, trials, spdShort'); axis xy;
title('Speed changes over time')
xlabel('Time (ms)');
ylabel('Trials');
colorbar

subplot(3,2,6)
imagesc(tmTSShort, chan, allTrialSpkShort'); axis xy;
title('Smooth spiking activity across all channels')
xlabel('Time (ms)');
ylabel('Channels');
colorbar


end

