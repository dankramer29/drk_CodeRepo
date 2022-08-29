%count = count + 1;
%hunits = histogram(binnedR_All.rawSpikes, 80); 
%cutoff = quantile(hunits.Data', .35)
unitsIdx = mean(binnedR_All.rawSpikes).*50 > 10; %all spikes with ave FR > 5 Hz
%rtBins = [750:150:2000]./20; %ms divided by 20 ms per bin
rtBinsBC = [250:150:1250]./20;  %ms divided by 20 ms per bin
rtBinsHM = [750:150:2000]./20; %ms divided by 20 ms per bin

rtBins = rtBinsBC; 

windowedFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
preFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
postFR = zeros(length(binnedR_All.tgt),size(binnedR_All.zSpikes,2));
tgt = nan(size(windowedFR,1),1);
coh = nan(size(tgt));
rt = nan(size(tgt));
trialNum = zeros(size(tgt));
zeroingWind = -300/20; 
windowEarly = -2500/20;   %ms before event onset / 20 ms per bin;
windowLate  = 200/20;  % ms after event onset  / 20 ms per bin;
%windowEarly = -2500/20;   %ms before move onset / 20 ms per bin;
%windowLate  = 500/20;     % ms after to include- should all be nan
slopeWindow =25+[10:35]; % 1+ abs(windowEarly) + [100/20  : 300/20];
% trialStartIdx = find(abs(diff(binnedR_All.stimCondMatrix(:,4)))>0); %not super accurate
iti = binnedR_All.state; %state values
iti(iti < 17.5) = nan; 
% get indices for where trials started- and iti precedes every trial (yes, even the first one in a block)
itiIdx = find(~isnan(iti)); %the indices for where ITI is in R struct
trialStartIdx = itiIdx(diff(itiIdx) > 1); % using the face that itiIdx is off by 1 length to our advantage
testSpikes = binnedR_All.zSpikes;
%testSpikes = binnedR_All.rawSpikes;
%testSpikes = binnedR_All.meanSSpikes;

for trial = 1:length(binnedR_All.stimOnset) %length(trialStartIdx)
    if ~isnan(binnedR_All.stimOnset(trial))
%         for windStep = windowEarly:windowLate
%             ts = ts+1;

        if trial < length(binnedR_All.stimOnset) %length(trialStartIdx)

            testSpikes(binnedR_All.speedMO(trial):trialStartIdx(trial+1),:) = nan;
        else

            testSpikes(binnedR_All.speedMO(trial):end,:) = nan;
        end
             preFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.stimOnset(trial)-5:binnedR_All.stimOnset(trial),:));
             postFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.stimOnset(trial):binnedR_All.stimOnset(trial)+5,:));
             windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate,:));
%             preFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.speedMO(trial)-5:binnedR_All.speedMO(trial),:));
%             postFR(trial, :) = nanmean(binnedR_All.rawSpikes(binnedR_All.speedMO(trial):binnedR_All.speedMO(trial)+5,:));
%             windowedFR(trial, :) = nanmean(binnedR_All.zSpikes(binnedR_All.speedMO(trial)+windowEarly:binnedR_All.speedMO(trial)+windowLate,:));
%             
            tgt(trial) = binnedR_All.tgt(trial);
            coh(trial) = binnedR_All.uCoh(trial);
            rt(trial) = binnedR_All.speedRT(trial);
            %trialNum(ts) = trial;
%         end
    end
end
tgt(isnan(coh)) = [];
rt(isnan(coh)) = [];
coh(isnan(coh)) = [];
decUnits = zeros(1,192); 
incUnits = zeros(1,192); 
for unit = 1:192
    if nanmean(preFR(:,unit)) > nanmean(postFR(:,unit))
        decUnits(unit) = 1;
    else
        incUnits(unit) = 1;
    end
end
%unitsIdx = (incUnits & unitsIdx); 
sum(unitsIdx)
% mean FR per unit
psth = nan(length(binnedR_All.tgt), 1+windowLate-windowEarly, sum(unitsIdx)); 
for trial = 1:length(binnedR_All.tgt)
    if ~isnan(binnedR_All.stimOnset(trial))
   % psth(trial,:,:) = binnedR_All.zSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   %psth(trial,:,:) = testSpikes(binnedR_All.stimOnset(trial)+windowEarly:binnedR_All.stimOnset(trial)+windowLate, unitsIdx).*50; %in hz
   psth(trial,:,:) = testSpikes((binnedR_All.speedMO(trial)+windowEarly):(binnedR_All.speedMO(trial)+windowLate), unitsIdx).*50; %in hz
   % subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),3)); %avg over units
    %subTrial(trial, :) = squeeze(nanmean(psth(trial,:,:),2)); % avg over time points
    %targIdx = targIdx + 1;
    end
end
%%
LFR = squeeze(nanmean(psth(tgt == 3,:,:)));  % avg over trials, time bins x units; 
RFR = squeeze(nanmean(psth(tgt == 4,:,:)));  % avg over trials, time bins x units; 
UFR = squeeze(nanmean(psth(tgt == 1,:,:)));  % avg over trials, time bins x units; 
DFR = squeeze(nanmean(psth(tgt == 2,:,:)));  % avg over trials, time bins x units; 
%V = LFR-RFR; % time bins x units; 
V1 = LFR-RFR;
V2 = UFR-DFR;

% figure; 
% plot(windowEarly:windowLate, nanmean(abs(V1),2),'g', 'LineWidth', 2);
% hold on;
% plot(windowEarly:windowLate, nanmean(abs(V2),2),'m', 'LineWidth', 2);
% ax = gca;
% ax.XTick = [windowEarly:abs(windowEarly):windowLate];
% ax.XTickLabel = [windowEarly:abs(windowEarly):windowLate].*20;
% xlabel('Time from Stim Onset (ms)');
% ylabel('Delta Population FR (Hz)');
% title('Difference in Population Firing Rate across Targets')
%%
LFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
RFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
UFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
DFR_rt = nan(length(rtBins), 1+windowLate-windowEarly, sum(unitsIdx));
diffUD_rt = nan(length(rtBins), 1+windowLate-windowEarly);
diffLR_rt = nan(length(rtBins), 1+windowLate-windowEarly); 
figure;
rtCount = 0;
slopesUD = nan(length(rtBins),2);
slopesLR = nan(length(rtBins),2);
statsLR  = nan(length(rtBins),4); 
statsUD  = nan(length(rtBins),4); 

colors = [{parula(length(rtBins))}, {parula(length(rtBins))}]; 
for rtIdx = rtBins
    rtCount = rtCount + 1;
    %%%% SF: switch the logic here to have rtIdx be the upper not lower
    %%%% bound? 
    %the minimum RT bin should catch all below: 
    if rtIdx == min(rtBins)
     %   rIdx = rt <= rtIdx & (rt < rtIdx+(500/20)); 
        rIdx = rt <= (rtIdx +(500/20)); 
    % if not the min and not the max, normal 500 ms window: 
    elseif rtIdx < max(rtBins)
        rIdx = (rt >= rtIdx) & (rt < rtIdx+(500/20)); 
    % the max should catch all above: 
    else
        rIdx = rt >= rtIdx;
    end
    LFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 3),:,:),1)); %average over trials of the same RT and targ
    RFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 4),:,:),1));
    UFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 1),:,:),1));
    DFR_rt(rtCount,:,:) = squeeze(mean(psth(rIdx & (tgt == 2),:,:),1));
    % take the absolute value of the difference per unit, average over those: 
    diffUD_rt(rtCount,:) = squeeze(nanmean(abs(UFR_rt(rtCount,:,:) - DFR_rt(rtCount,:,:)),3));
    diffLR_rt(rtCount,:) = squeeze(nanmean(abs(LFR_rt(rtCount,:,:) - RFR_rt(rtCount,:,:)),3));
    % cut plots off at max RT bin: 
    %maxX = min(windowLate, max(rtBins));
    subplot(2,2,1)
   % plot(windowEarly:windowLate, diffUD_rt(rtCount,:) - nanmean(diffUD_rt(rtCount,1:abs(windowEarly)*2)), 'Color', colors{1}(rtCount,:), 'LineWidth',2)
   % take out the hack-y baseline shift: 
    plot(windowEarly:windowLate, diffUD_rt(rtCount,:) , 'Color', colors{1}(rtCount,:), 'LineWidth',2)
    % new hack-y baseline shift: 
   % plot(windowEarly:windowLate, diffUD_rt(rtCount,:) - diffUD_rt(rtCount, find(~isnan(diffUD_rt(rtCount,:)), 1, 'first')), 'Color', colors{1}(rtCount,:), 'LineWidth',2)
    hold on;
  
    subplot(2,2,3)
   % plot(windowEarly:windowLate,  diffLR_rt(rtCount,:) - nanmean(diffLR_rt(rtCount,1:abs(windowEarly)*2)), 'Color', colors{2}(rtCount,:), 'LineWidth',2)
    plot(windowEarly:windowLate,  diffLR_rt(rtCount,:) , 'Color', colors{2}(rtCount,:), 'LineWidth',2)
    %plot(windowEarly:windowLate,  diffLR_rt(rtCount,:)  - diffLR_rt(rtCount, find(~isnan(diffLR_rt(rtCount,:)), 1, 'first')) , 'Color', colors{2}(rtCount,:), 'LineWidth',2)
    hold on;
    
    % plot number of trials per RT bin
    subplot(2,2,4)
    plot(rtIdx, sum(rIdx & ((tgt == 3)|(tgt == 4))), '*', 'Color', colors{1}(rtCount,:), 'MarkerSize', 10); 
    hold on;
    
    subplot(2,2,2)
    plot(rtIdx, sum(rIdx & ((tgt == 1)|(tgt == 2))), '*', 'Color', colors{2}(rtCount,:), 'MarkerSize', 10); 
    hold on;
    % calculate the slope on stim on + 100 to stim on + 300: 
    
     [slopesLR(rtCount,:), ~, ~, ~, statsLR(rtCount,:)] = regress(diffLR_rt(rtCount,slopeWindow)', [ones(1,length(slopeWindow)); slopeWindow]'); 
     [slopesUD(rtCount,:), ~, ~, ~, statsUD(rtCount,:)] = regress(diffUD_rt(rtCount,slopeWindow)', [ones(1,length(slopeWindow)); slopeWindow]'); 
end
subplot(2,2,1)
    ax = gca;
ax.XTick = [windowEarly:abs(windowEarly)/2.5:windowLate];
ax.XTickLabel = ax.XTick.*20;
xlabel('Time from Movement Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Up/Down Targets')
%line([slopeWindow(1)-abs(windowEarly), slopeWindow(1)-abs(windowEarly)], [4 13])
%line([slopeWindow(end)-abs(windowEarly), slopeWindow(end)-abs(windowEarly)], [4 13])
legend({num2str((rtBins.*20)')})
axis([windowEarly windowLate -inf inf])
subplot(2,2,3)
    ax = gca;
ax.XTick = [windowEarly:abs(windowEarly)/2.5:windowLate];
ax.XTickLabel = ax.XTick.*20;
xlabel('Time from Movement Onset (ms)');
ylabel('Delta Population FR (Hz)');
title('Difference in Population Firing Rate across Left/Right Targets')
axis([windowEarly windowLate -inf inf])
%line([slopeWindow(1)-abs(windowEarly), slopeWindow(1)-abs(windowEarly)], [4 13])
%line([slopeWindow(end)-abs(windowEarly), slopeWindow(end)-abs(windowEarly)], [4 13])
legend({num2str((rtBins.*20)')})

subplot(2,2,2)
xlabel('Reaction Time')
ylabel('Number of trials')
title('Num Trials per RT Bin')
ax = gca;
ax.XTickLabel = ax.XTick .* 20;

subplot(2,2,4)
xlabel('Reaction Time')
ylabel('Number of trials')
title('Num Trials per RT Bin')
ax = gca;
ax.XTickLabel = ax.XTick .* 20;

bigfonts(14)
%%
[cohSlopesLR, ~, ~, ~, cohStatsLR] = regress(slopesLR(:,2), [ones(length(rtBins),1), rtBins']);
[cohSlopesUD, ~, ~, ~, cohStatsUD] = regress(slopesUD(:,2), [ones(length(rtBins),1), rtBins']);
% figure;
% plot(rtBins, slopesLR(:,2),'g');
% hold on;
% plot(rtBins, slopesUD(:,2),'m');
count = sesh;
slopeUDpVal(count) = cohStatsUD(3); 
slopeLRpVal(count) = cohStatsLR(3); 