%%
blockList = [7 8 9 10 11 12 13 14 15 16];

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1500 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'all'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2018.11.19' filesep];

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, blockList, [], 4.5 );

trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end

alignField = 'goCue';

allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 0.5;

allSpikes(:,tooLow) = [];
%allSpikes = gaussSmooth_fast(allSpikes, 30);

globalIdx = 0;
alignEvents = zeros(length(R),2);
allBlocks = zeros(size(allSpikes,1),1);
for t=1:length(R)
    loopIdx = (globalIdx+1):(globalIdx + length(R(t).spikeRaster));
    allBlocks(loopIdx) = R(t).blockNum;
    alignEvents(t,1) = globalIdx + R(t).(alignField);
    alignEvents(t,2) = globalIdx + R(t).trialStart;
    globalIdx = globalIdx + size(R(t).spikeRaster,2);
end

[trlCodeList,~,trlCodesRemap] = unique(trlCodes);

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
snippetMatrix = zeros(nBins, size(allSpikes,2));
blockRows = zeros(nBins, 1);
validTrl = false(length(trlCodes),1);
globalIdx = 1;

for t=1:length(trlCodes)
    disp(t);
    loopIdx = (alignEvents(t,1)+timeWindow(1)):(alignEvents(t,1)+timeWindow(2));

    if loopIdx(1)<1 || loopIdx(end)>size(allSpikes,1)
        loopIdx(loopIdx<1)=[];
        loopIdx(loopIdx>size(allSpikes,1))=[];
    else
        validTrl(t) = true;
    end
        
    newRow = zeros(nBins, size(allSpikes,2));
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    snippetMatrix(newIdx,:) = newRow;
end

%%
bNumPerTrial = [R.blockNum];
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);

for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (eventIdx(blockTrl(t))-140):(eventIdx(blockTrl(t))-100)];
    end
    msIdx(msIdx<1) = [];
    
    binIdx = find(blockRows==blockList(b));
    %snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(msIdx,:)));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(snippetMatrix(binIdx,:)));
end
rawSnippetMatrix = snippetMatrix;
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));

%%
clear R allSpikes
pack;

%%
smoothSnippetMatrix = gaussSmooth_fast(snippetMatrix, 3.0);

%across all conditions
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesRemap, [-500, 1000]/binMS, binMS/1000, {'CI','CD'},[3 3],'standard','ortho' );
close(gcf);

%%
trls_Coded = [
   94 ...
   95 ...
   96 ...
   97 ...
  218 ...
  219 ...
  220 ...
  221 ...
  222 ...
  223 ...
  224 ...
  225 ...
  226 ...
  227 ...
  228 ...
  229 ...
  230 ...
  231 ...
  232 ...
  233 ...
  234 ...
  235 ...
  236 ...
  237 ...
  238 ...
  239 ...
  240 ...
  241 ...
  242 ...
  243 ...
  244 ...
  245 ...
  246 ...
  247 ...
  248 ...
  249 ...
  250 ...
  251 ...
  252];

move_names_Coded = {...
     'ELBOW_FLEX';...
     'ELBOW_EXT';...
     'WRIST_EXT';...
     'WRIST_FLEX';...
     'NOTHING';...
     'SHOULDER_ABDUCT';...
     'SHOULDER_ADDUCT';...
     'SHOULDER_FLEX';...
     'SHOULDER_EXTEND';...
     'SHOULDER_EXT_ROT';...
     'SHOULDER_INT_ROT';...
     'WRIST_ULNAR_DEV';...
     'WRIST_RADIAL_DEV';...
     'WRIST_PRO';...
     'WRIST_SUP';...
     'HAND_CLOSE';...
     'HAND_OPEN';...
     'ANKLE_RIGHT';...
     'ANKLE_LEFT';...
     'ANKLE_GAS_UP'; ...
     'ANKLE_GAS_DOWN';    ...
     'INDEX_FLEX';...
     'INDEX_EXTEND';   ...
     'REACH_FRONT';...
     'REACH_RIGHT';...
     'REACH_UP';...
     'REACH_NOSE';...
     'REACH_HEART';...
     'REACH_BEHIND_HEAD';...
     'REACH_STEERING_RIGHT';...
     'JOYSTICK_UP';...
     'JOYSTICK_DOWN';...
     'JOYSTICK_LEFT';...
     'JOYSTICK_RIGHT';  ...
     'HIP_UP';...
     'KNEE_KICK';...
     'TOES_SPREAD';...
     'TOES_CLENCH';...
     'BIGTOE_UP'};
     
%reorderIdx = [5 1 2 3 4 6 7 8 9 10 11 12 13 14 15 16 17 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 ...
%    18 19 20 21 37 38 39];
%reorderIdx = [5 6 7 8 9 10 11 1 2 3 4 12 13 14 15 16 17 22 23 35 36 ...
%    18 19 20 21 37 38 39];
%effSets = {1,2:19,20:28};
reorderIdx = [8 2 3 4 13 12 16 17 35 36 20 21 18 19 38 37];
effSets = {1:8, 9:16};

movLabelsReorder = move_names_Coded(reorderIdx);
movLabels_pretty = {'Shoulder Flex','Elbow Ext','Wrist Ext','Wrist Flex','Wrist Ulnar',...
    'Wrist Radial','Hand Close','Hand Open','Hip Flex','Knee Ext','Ankle Ext','Ankle Flex','Ankle Eversion',...
    'Ankle Inversion','Toes Close','Toes Open'};

cWindow = 60:100;
boxSets = [];
fa = dPCA_out.featureAverages;
fa = fa(:,reorderIdx,:);
simMatrix = plotCorrMat( fa, cWindow, movLabels_pretty, ...
    effSets, boxSets );
simMatrix = plotCorrMat( fa, cWindow, movLabels_pretty, ...
    [], boxSets );
saveas(gcf,[outDir filesep '_legArmcorrMat.png'],'png');
saveas(gcf,[outDir filesep '_legArmcorrMat.svg'],'svg');

figure('Position',[680   866   391   232]);
cMat = simMatrix(1:8, 9:16);
diagEntries = 1:(size(cMat,1)+1):numel(cMat);
otherEntries = setdiff(1:numel(cMat), diagEntries);    

subplot(1,2,1);
hold on
plot((rand(length(diagEntries),1)-0.5)*0.55, cMat(diagEntries), 'o');
plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, cMat(otherEntries), 'ro');
set(gca,'XTick',[0 1],'XTickLabel',{'Matched','Different'},'XTickLabelRotation',45);
ylim([-1.0,1.0]);
ylabel('Correlation');
set(gca,'FontSize',20,'LineWidth',2);
xlim([-0.5,1.5]);
title('Arm vs. Leg','FontSize',18);

saveas(gcf,[outDir filesep 'corrDots.png'],'png');
saveas(gcf,[outDir filesep 'corrDots.svg'],'svg');

diagEntries = 1:(size(cMat,1)+1):numel(cMat);
otherEntries = setdiff(1:numel(cMat), diagEntries);
anova1([cMat(diagEntries)'; cMat(otherEntries)'], ...
    [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

armMat = simMatrix(1:8, 1:8);
legMat = simMatrix(9:16, 9:16);
armLegMat = triu(armMat)+tril(legMat);
armLegOffDiag = legMat(otherEntries);
crossMatOffDiag = cMat(otherEntries);

figure; 
hold on;
plot((rand(length(otherEntries),1)-0.5)*0.55,abs(armLegOffDiag),'bo');
plot(1+(rand(length(otherEntries),1)-0.5)*0.55,abs(crossMatOffDiag),'ro')

%%
%all movements
reorderIdx = [5 6 7 8 9 10 11 24:29 1 2 3 4 12 13 14 15 16 31:34 17 22 23 35 36 18 19 20 21 37 38 39];
effSets = {1:length(reorderIdx)};
movLabelsReorder = move_names_Coded(reorderIdx);

cWindow = 60:100;
boxSets = [];
fa = dPCA_out.featureAverages;
fa = fa(:,reorderIdx,:);

simMatrix = plotCorrMat( fa, cWindow, movLabelsReorder, ...
    effSets, boxSets );
saveas(gcf,[outDir filesep '_allMovements.png'],'png');

%%
%opposed joint movements in each of 3 categories: proximal, distal, leg
reorderIdx = [6 7 8 9 10 11 1 2 3 4 12 13 14 15 16 17 22 23 18 19 20 21 37 38];
effSets = {1:length(reorderIdx)};
movLabelsReorder = move_names_Coded(reorderIdx);

cWindow = 60:100;
boxSets = [];
fa = dPCA_out.featureAverages;
fa = fa(:,reorderIdx,:);
idx_prox = 1:8;
idx_dist = 9:18;
idx_leg = 19:24;
simMatrix = plotCorrMat( fa, cWindow, movLabelsReorder, ...
    {idx_prox, idx_dist, idx_leg}, {idx_prox, idx_dist, idx_leg} );
saveas(gcf,[outDir filesep '_allMovements_3sets.png'],'png');

%%
%within-arm organization
reorderIdx = [6 7 8 9 10 11 1 2 3 4 12 13 14 15 16 17 22 23];
effSets = {1:length(reorderIdx)};
movLabelsReorder = move_names_Coded(reorderIdx);

cWindow = 60:100;
boxSets = [];
fa = dPCA_out.featureAverages;
fa = fa(:,reorderIdx,:);
simMatrix = plotCorrMat( fa, cWindow, movLabelsReorder, ...
    {1:length(reorderIdx)}, {1:length(reorderIdx)} );

[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(squeeze(nanmean(fa(:,:,cWindow),3))');

colorSets = {1:8, 9:18};
colors = hsv(2)*0.8;

figure
hold on;
for setIdx=1:length(colorSets)
    plot3(SCORE(colorSets{setIdx},1), SCORE(colorSets{setIdx},2), SCORE(colorSets{setIdx},3), 'o', ...
        'MarkerFaceColor',colors(setIdx,:), 'Color',colors(setIdx,:), 'MarkerSize', 12);
end
axis equal;
%%
% reorderIdx = [6 7 8 9 10 11 1 2 3 4 12 13 14 15 16 17 22 23 35 36 18 19 20 21 37 38 39];
% effSets = {1:18, 19:27};
% 
% movLabels_pretty = {'Sho Abb','Sho Add','Sho Flex','Sho Ext','Sho Ext Rot','Sho Int Rot',...
%     'Elb Flex','Elb Ext','Wrist Ext','Wrist Flex','Wrist Ulnar Dev','Wrist Radial Dev',...
%     'Wrist Pro','Wrist Sup','Hand Close','Hand Open','Index Flex','Index Ext',...
%     'Hip Up','Knee Kick','Ankle Right','Ankle Left','Ankle Up','Ankle Down',...
%     'Toes Open','Toes Close','Big Toe Up'};
% 
% cWindow = 60:100;
% boxSets = effSets;
% fa = dPCA_out.featureAverages;
% fa = fa(:,reorderIdx,:);
% simMatrix = plotCorrMat( fa, cWindow, movLabels_pretty, ...
%     effSets, boxSets );
% saveas(gcf,[outDir filesep '_legArmcorrMat_all.png'],'png');
% saveas(gcf,[outDir filesep '_legArmcorrMat_all.svg'],'svg');
% 
% figure('Position',[680   866   391   232]);
% cMat = simMatrix(1:8, 9:16);
% diagEntries = 1:(size(cMat,1)+1):numel(cMat);
% otherEntries = setdiff(1:numel(cMat), diagEntries);    
% 
% subplot(1,2,1);
% hold on
% plot((rand(length(diagEntries),1)-0.5)*0.55, cMat(diagEntries), 'o');
% plot(1 + (rand(length(otherEntries),1)-0.5)*0.55, cMat(otherEntries), 'ro');
% set(gca,'XTick',[0 1],'XTickLabel',{'Matched','Different'},'XTickLabelRotation',45);
% ylim([-1.0,1.0]);
% ylabel('Correlation');
% set(gca,'FontSize',20,'LineWidth',2);
% xlim([-0.5,1.5]);
% title('Arm vs. Leg','FontSize',18);
% 
% saveas(gcf,[outDir filesep 'corrDots.png'],'png');
% saveas(gcf,[outDir filesep 'corrDots.svg'],'svg');
% 
% diagEntries = 1:(size(cMat,1)+1):numel(cMat);
% otherEntries = setdiff(1:numel(cMat), diagEntries);
% anova1([cMat(diagEntries)'; cMat(otherEntries)'], ...
%     [ones(length(diagEntries),1); ones(length(otherEntries),1)+1]);

%%
simMatrix = zeros(nCon, nCon);
for x=1:nCon
    %get the top dimensions this movement lives in
    avgTraj = squeeze(dPCA_out.featureAverages(:,x,:))';
    avgTraj = avgTraj - mean(avgTraj);
    %avgTraj = avgTraj - mean(avgTraj,2);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
    topDim = COEFF(:,1:4);
    
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_out.featureAverages(:,y,:))';
        avgTraj_y = avgTraj_y - mean(avgTraj_y);
        %avgTraj_y = avgTraj_y - mean(avgTraj_y,2);
        
        reconTraj = (avgTraj_y*topDim)*topDim';
        errTraj = avgTraj_y - reconTraj;
        
        SSTOT = sum(avgTraj_y(:).^2);
        SSERR = sum(errTraj(:).^2);
        
        simMatrix(x,y) = 1 - SSERR/SSTOT;
    end
end

figure
imagesc(simMatrix(reorderIdx, reorderIdx),[0 0.7]);
colormap(parula);
colorbar;

set(gca,'XTick',1:nCon,'XTickLabel',move_names_Coded(reorderIdx),'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',move_names_Coded(reorderIdx));
set(gca,'FontSize',16);
set(gca,'YDir','normal');

%%
%arm and leg sets, leave one out
codeSets = {[1 3 4 6 12 13 16 17 23],[35 36 18 19 20 21 37 38 39]};
for s=1:length(codeSets)
    varExpl = zeros(length(codeSets{s}),1);
    for x=1:length(codeSets{s})
        codeIdx = setdiff(codeSets{s}, codeSets{s}(x));
        avgTraj = squeeze(dPCA_out.featureAverages(:,codeIdx,:));
        avgTraj = avgTraj(:,:)';
        [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
        topDim = COEFF(:,1:10);
        
        avgTraj_y = squeeze(dPCA_out.featureAverages(:,codeSets{s}(x),:))';
        avgTraj_y = avgTraj_y - mean(avgTraj_y);

        reconTraj = (avgTraj_y*topDim)*topDim';
        errTraj = avgTraj_y - reconTraj;

        SSTOT = sum(avgTraj_y(:).^2);
        SSERR = sum(errTraj(:).^2);

        varExpl(x) = 1 - SSERR/SSTOT;
    end

    avgTraj = squeeze(dPCA_out.featureAverages(:,codeSets{s},:));
    avgTraj = avgTraj(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
    topDim = COEFF(:,1:10);

    varExpl_cross = cell(length(codeSets),1);
    for y=1:length(codeSets)
        for x=1:length(codeSets{s})
            avgTraj_y = squeeze(dPCA_out.featureAverages(:,codeSets{y}(x),:))';
            avgTraj_y = avgTraj_y - mean(avgTraj_y);

            reconTraj = (avgTraj_y*topDim)*topDim';
            errTraj = avgTraj_y - reconTraj;

            SSTOT = sum(avgTraj_y(:).^2);
            SSERR = sum(errTraj(:).^2);

            varExpl_cross{y}(x) = 1 - SSERR/SSTOT;
        end
    end
end

%%
%sets are: basis, arm test, leg test
codeSets = {[1 2 3 4 6 7 8 9 10 11 12 13 14 15 16 17 22 23],[24 25 26 27 28 29 30 31 32 33 34],...
    [35 36 18 19 20 21 37 38 39]};

%first get PCs that span the arm basis
avgTraj = squeeze(dPCA_out.featureAverages(:,codeSets{1},:));
avgTraj = avgTraj(:,:)';
[COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
topDim = COEFF(:,1:30);

%for each movement set, project into those PCs and compute fraction of
%variance explained
varExpl = cell(length(codeSets),1);
for s=1:length(codeSets)
    varExpl{s} = zeros(length(codeSets{s}),1);
    for y=1:length(codeSets{s})
        avgTraj_y = squeeze(dPCA_out.featureAverages(:,codeSets{s}(y),:))';
        avgTraj_y = avgTraj_y - mean(avgTraj_y);
        
        reconTraj = (avgTraj_y*topDim)*topDim';
        errTraj = avgTraj_y - reconTraj;
        
        SSTOT = sum(avgTraj_y(:).^2);
        SSERR = sum(errTraj(:).^2);
        
        varExpl{s}(y) = 1 - SSERR/SSTOT;
    end
end

%an anova shows a difference in variance explained between arm and leg test
%sets
anova1([varExpl{2}; varExpl{3}], [zeros(length(varExpl{3}),1); ones(length(varExpl{2}),1);]);

%%
timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
yLims = [];
axHandles=[];
plotIdx = 1;

movLabels = {'SayBa','SayGa','TurnRight','TurnLeft','TurnUp','TurnDown','TiltRight','TiltLeft','Forward','Backward',...
    'TongueUp','TongueDown','TongueLeft','TongueRight','MouthOpen','JawClench','LipsPucker','EyebrowsRaise','NoseWrinkle',...
    'ShoShrug','ArmRaise','ElbowFlex','WristExt','HandClose','HandOpen',...
    'AnkleExt','AnkleFlex','KneeExt','HipFlex','ToeCurl','ToeOpen','IndexRaise','TumbRaise','Nothing'};

codeList = unique(trlCodes);
reorderIdx = [34, ...
    1 2 11 12 13 14 15 16 17 18 19, ...
    3 4 5 6 7 8 9 10, ...
    20 21 22 23 24 25 32 33, ...
    26 27 28 29 30 31];

trlCodesReorder = trlCodes;
for t=1:length(reorderIdx)
    tmp = find(trlCodes==codeList(reorderIdx(t)));
    trlCodesReorder(tmp) = t;
end

movLabelsReorder = movLabels(reorderIdx);

movTypeText = {'Tongue','Face','Neck','Arm','Leg'};
codeSets = {4:7, [2 3 8:12], 13:20, 21:28, 29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSets{:}));

%%
dPCA_out = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSets{pIdx}));
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20, 'xval' );
    close(gcf);
end

%%
cVar = zeros(length(codeList),1);
movWindow = (20:60);
baselineWindow = -119:-80;

for pIdx = 1:length(codeSets)
    cdIdx = find(dPCA_out{pIdx}.cval.whichMarg==1);
    cdIdx = cdIdx(1:6);
    
    for codeIdx=1:length(codeSets{pIdx})
        dataLabels = [];
        dataMatrix = [];
        nTrials = size(dPCA_out{pIdx}.cval.Z_singleTrial,1);
        
        timeOffset = (-timeWindow(1)/binMS);
        movWindowActivity = squeeze(dPCA_out{pIdx}.cval.Z_singleTrial(:,cdIdx,codeIdx,timeOffset+movWindow));
        baselineWindowActivity = squeeze(dPCA_out{pIdx}.cval.Z_singleTrial(:,cdIdx,codeIdx,timeOffset+baselineWindow));
        
        dataMatrix = [nanmean(movWindowActivity,3); nanmean(baselineWindowActivity,3)];
        dataLabels = zeros(nTrials*2,1);
        dataLabels(1:nTrials) = 1;
        dataLabels((nTrials+1):end) = 2;
        
        badIdx = find(any(isnan(dataMatrix),2));
        dataMatrix(badIdx,:) = [];
        dataLabels(badIdx,:) = [];

        nResample = 10000;
        
        testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
        resampleVec = zeros(nResample,1);
        for resampleIdx=1:nResample
            shuffLabels = dataLabels(randperm(length(dataLabels)));
            resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
        end
        
        cVar(codeSets{pIdx}(codeIdx),1) = testStat;
        cVar(codeSets{pIdx}(codeIdx),2) = prctile(resampleVec,99);
        
        ci = bootci(nResample, {@normStat, dataMatrix(dataLabels==1,:), dataMatrix(dataLabels==2,:)});
        cVar(codeSets{pIdx}(codeIdx),3:4) = ci;    
    end
end    

figure;
hold on;
plot3(dataMatrix(dataLabels==1,1), dataMatrix(dataLabels==1,2),  dataMatrix(dataLabels==1,3),'o');
plot3(dataMatrix(dataLabels==2,1), dataMatrix(dataLabels==2,2),  dataMatrix(dataLabels==2,3),'ro');

%%
%single unit counting
movTypeText = {'Face','Neck','Arm','Leg'};
codeSetsReduced = {[2 3 4 5 6 7 8 9 10 11 12],13:20,21:28,29:34};
movLabelsSets = movLabelsReorder(horzcat(codeSetsReduced{:}));

dPCA_out = cell(length(movTypeText),1);
for pIdx=1:length(movTypeText)
    trlIdx = find(ismember(trlCodesReorder, codeSetsReduced{pIdx}));
    dPCA_out{pIdx} = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        trlCodesReorder(trlIdx)', timeWindow/binMS, binMS/1000, {'CI','CD'}, 20);
    close(gcf);
end

nUnits = size(dPCA_out{1}.featureAverages,1);
pVal = zeros(length(codeSetsReduced), nUnits);
modSD = zeros(length(codeSetsReduced), nUnits);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(codeSetsReduced,1),2);

timeOffset = -timeWindow(1)/binMS;
movWindow = (20:60);
baselineWindow = -119:-80;

for pIdx = 1:length(codeSetsReduced)    
    for unitIdx=1:size(dPCA_out{pIdx}.featureAverages,1)
        unitAct = squeeze(dPCA_out{pIdx}.featureVals(unitIdx,:,movWindow+timeOffset,:));
        meanAcrossTrial = squeeze(nanmean(unitAct,3))';
        meanAct = squeeze(nanmean(unitAct,2))';

        pVal(pIdx, unitIdx) = anova1(meanAct,[],'off');
        
        modSD(pIdx, unitIdx) = nanstd(mean(meanAcrossTrial));
    end
end    

sigUnit = find(any(pVal<0.001));

%num tuned
disp(mean(pVal'<0.001));

%categorize mixed tuning
isTuned = pVal<0.001;
numCategories = sum(isTuned);

%%
eVar = zeros(length(codeSetsReduced),1);
for pIdx = 1:length(codeSetsReduced)
    cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
    cdIdx = cdIdx(1:6);
    
    totalVar = sum(dPCA_out{pIdx}.explVar.margVar(1,cdIdx))*dPCA_out{pIdx}.explVar.totalMarginalizedVar(1);
    totalVar = totalVar / size(dPCA_out{pIdx}.featureAverages,2);
    eVar(pIdx) = totalVar;
end

figure; 
plot(sqrt(eVar)/max(sqrt(eVar)));

%%
%PSTHs for each feature
%get code sets for each movement type

%PSTHS
movTypes = {'Face','Head','Arm','Leg'};
lineArgs = cell(length(trlCodeList),1);
for pIdx = 1:length(movTypes)
    colors = hsv(length(codeSetsReduced{pIdx}))*0.8;
    for x=1:length(codeSetsReduced{pIdx})
        lineArgs{codeSetsReduced{pIdx}(x)} = {'LineWidth',1,'Color',colors(x,:)};
    end
end

psthOpts = makePSTHOpts();
psthOpts.gaussSmoothWidth = 0;
psthOpts.neuralData = {smoothSnippetMatrix};
psthOpts.timeWindow = timeWindow/binMS;
psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(smoothSnippetMatrix,1);
psthOpts.trialConditions = trlCodesReorder;
psthOpts.conditionGrouping = codeSetsReduced;
psthOpts.lineArgs = lineArgs;

psthOpts.plotsPerPage = 10;
psthOpts.plotDir = outDir;

featLabels = cell(192,1);
chanIdx = find(~tooLow);
for f=1:length(chanIdx)
    featLabels{f} = num2str(chanIdx(f));
end
psthOpts.featLabels = featLabels;

tooLowChans = find(tooLow);
usedChans = setdiff(1:192, tooLowChans);

psthOpts.prefix = 'TX';
makePSTH_simple(psthOpts);

%%
%similarity matrix across movements using projection
dPCA_all = apply_dPCA_simple( smoothSnippetMatrix, eventIdx, ...
    trlCodesReorder', [-500, 1000]/binMS, binMS/1000, {'CI','CD'} );

nCon = size(dPCA_all.featureAverages,2);
simMatrix = zeros(nCon, nCon);
for x=1:nCon
    %get the top dimensions this movement lives in
    avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
    avgTraj = mean(avgTraj(60:100,:));
   
    for y=1:nCon
        avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
        avgTraj_y = mean(avgTraj_y(60:100,:));
        
        simMatrix(x,y) = corr(avgTraj', avgTraj_y');
    end
end

% simMatrix = zeros(nCon, nCon);
% for x=1:nCon
%     %get the top dimensions this movement lives in
%     avgTraj = squeeze(dPCA_all.featureAverages(:,x,:))';
%     avgTraj = avgTraj - mean(avgTraj);
%     %avgTraj = avgTraj - mean(avgTraj,2);
%     
%     [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(avgTraj);
%     topDim = COEFF(:,1:4);
%     
%     for y=1:nCon
%         avgTraj_y = squeeze(dPCA_all.featureAverages(:,y,:))';
%         avgTraj_y = avgTraj_y - mean(avgTraj_y);
%         %avgTraj_y = avgTraj_y - mean(avgTraj_y,2);
%         
%         reconTraj = (avgTraj_y*topDim)*topDim';
%         errTraj = avgTraj_y - reconTraj;
%         
%         SSTOT = sum(avgTraj_y(:).^2);
%         SSERR = sum(errTraj(:).^2);
%         
%         simMatrix(x,y) = 1 - SSERR/SSTOT;
%     end
% end

figure
imagesc(simMatrix);
set(gca,'XTick',1:nCon,'XTickLabel',movLabelsReorder,'XTickLabelRotation',45);
set(gca,'YTick',1:nCon,'YTickLabel',movLabelsReorder);
set(gca,'FontSize',16);
set(gca,'YDir','normal');

colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

codeSets = {[2:12],[13:20],[21:28],[29:34]};
currentIdx = 1;
currentColor = 1;
for c=1:length(codeSets)
    newIdx = currentIdx + (1:length(codeSets{c}))';
    rectangle('Position',[newIdx(1)-0.5, newIdx(1)-0.5,length(newIdx), length(newIdx)],'LineWidth',5,'EdgeColor',colors(currentColor,:));
    currentIdx = currentIdx + length(codeSets{c});
    currentColor = currentColor + 1;
end
axis tight;

%%
%bar plot
colors = [173,150,61;
119,122,205;
91,169,101;
197,90,159;
202,94,74]/255;

figure('Position',[164   751   989   338]);
plotIdx = 1;
colorIdx = 1;

hold on
for pIdx=1:length(codeSets)
    dat = cVar(codeSets{pIdx},1) - cVar(codeSets{pIdx},2);
    CI = cVar(codeSets{pIdx},3:4) - cVar(codeSets{pIdx},2);
    
    xAxis = (plotIdx):(plotIdx + length(dat) - 1);
    bar(xAxis, dat, 'FaceColor', colors(colorIdx,:), 'LineWidth', 1);
    %for x=1:length(dat)
    %    plot([plotIdx+x-1, plotIdx+x-1], CI(x,:), '-k','LineWidth',1);
    %end
    errorbar(xAxis, dat, dat-CI(:,1), CI(:,2)-dat, '.k','LineWidth',1);
    
    plotIdx = plotIdx + length(dat);
    colorIdx = colorIdx + 1;
end
set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabelsSets,'XTickLabelRotation',45);

axis tight;
xlim([0.5, 33.5]);
ylabel('\Delta Neural Activity\newlinein Separating Dimensions\newline(a.u.)','FontSize',22);
set(gca,'TickLength',[0 0]);

saveas(gcf,[outDir filesep 'bar_dPCA.png'],'png');
saveas(gcf,[outDir filesep 'bar_dPCA.svg'],'svg');
saveas(gcf,[outDir filesep 'bar_dPCA.pdf'],'pdf');

%%
for pIdx=[2 5 1 3 4]
    dat = cVar(codes{pIdx,2},1) - cVar(codes{pIdx,2},2);
    disp(mean(dat));
end

%%
axHandles = zeros(length(movTypeText),1);
yLims = [];

figure('Position',[272         833        1551         272]);
for pIdx=1:length(movTypeText)

    cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
    axHandles(pIdx) = subtightplot(1,length(movTypeText),pIdx,[0.01 0.01],[0.05, 0.10],[0.05 0.05]);
    hold on

    colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
    lineHandles = zeros(size(dPCA_out{pIdx}.Z,2),1);
    for conIdx=1:size(dPCA_out{pIdx}.Z,2)
        lineHandles(conIdx) = plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(1),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
        errorPatch( timeAxis', squeeze(dPCA_out{pIdx}.dimCI(cdIdx(1),conIdx,:,:)), colors(conIdx,:), 0.2 );
    end

    axis tight;
    yLims = [yLims; get(gca,'YLim')];
    
    plot(get(gca,'XLim'),[0 0],'k');
    plot([0, 0],[-100, 100],'--k','LineWidth',2);
    if ismember(pIdx,[3 4])
        plot([2.5, 2.5],[-100, 100],'--k','LineWidth',2);
        text(0.95,0.8,'Return','Units','Normalized','FontSize',16);
    elseif ismember(pIdx,[1 2 5 6])
        plot([1.5, 1.5],[-100, 100],'--k','LineWidth',2);
        text(0.7,0.8,'Return','Units','Normalized','FontSize',16);
    end
    set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);

    if pIdx==length(movTypeText)
        xlabel('Time (s)');
    else
        set(gca,'XTickLabels',[]);
    end
    text(0.3,0.8,'Go','Units','Normalized','FontSize',16);
    
    
    plot([0,0.5]+0.2,[-1,-1],'-k','LineWidth',2);

    title(movTypeText{pIdx},'FontSize',22);
    lHandle = legend(lineHandles, movLabelsReorder(codeSets{pIdx}),'Location','West','box','off','FontSize',16);
    lPos = get(lHandle,'Position');
    lPos(1) = lPos(1)+0.05;
    set(lHandle,'Position',lPos);
    axis off;

end

finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
for p=1:length(axHandles)
    set(axHandles(p), 'YLim', finalLimits);
end

saveas(gcf,[outDir filesep 'dPCA_oneDim.png'],'png');
saveas(gcf,[outDir filesep 'dPCA_oneDim.svg'],'svg');

%%
%raw data test
movWindow = 20:100;
baselineWindow = -140:-100;

cVar = zeros(length(trlCodeList),1);
eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
codes = cell(size(movTypes,1),2);
all_dPCA = cell(size(movTypes,1),2);

allP = [];
for pIdx = 1:size(movTypes,1)
    trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
    trlIdx = find(trlIdx);
    codes{pIdx,1} = unique(trlCodes(trlIdx));
    codes{pIdx,2} = unique(trlCodesRemap(trlIdx));
    tmpCodes = trlCodesRemap(trlIdx);
    
    dPCA_out = apply_dPCA_simple( smoothSnippetMatrix, eventIdx(trlIdx), ...
        tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
    close(gcf);
    
    all_dPCA{pIdx} = dPCA_out;
    
    cdIdx = find(dPCA_out.whichMarg==1);
    cdIdx = cdIdx(1:8);
    
    cLoopIdx = expandEpochIdx([ eventIdx(trlIdx)', eventIdx(trlIdx)'+75]);
    
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED, MU] = pca(dPCA_out.featureAverages(:,:)');
    reducedSnippetMatrix = snippetMatrix*COEFF(:,1:5);
    %reducedSnippetMatrix = snippetMatrix;

    for codeIdx=1:length(codes{pIdx,2})
        dataLabels = [];
        dataMatrix = [];
        trlIdxForThisCode = trlIdx(tmpCodes==codes{pIdx,2}(codeIdx));
        for x=1:length(trlIdxForThisCode)
            loopIdxWindow = eventIdx(trlIdxForThisCode(x))+movWindow;
            loopIdxBaseline = eventIdx(trlIdxForThisCode(x))+baselineWindow;
            if any(loopIdxBaseline<=0) || any(loopIdxWindow<=0)
                continue;
            end
            
            dataMatrix = [dataMatrix; mean(reducedSnippetMatrix(loopIdxBaseline,:)); mean(reducedSnippetMatrix(loopIdxWindow,:))];
            dataLabels = [dataLabels; 1; 2];
        end
        
        [D,P,STATS]=manova1(dataMatrix, dataLabels);
        allP = [allP; P];
        
%         nResample = 10000;
%         testStat = norm(mean(dataMatrix(dataLabels==2,:)) - mean(dataMatrix(dataLabels==1,:)));
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             shuffLabels = dataLabels(randperm(length(dataLabels)));
%             resampleVec(resampleIdx) = norm(mean(dataMatrix(shuffLabels==2,:)) - mean(dataMatrix(shuffLabels==1,:)));
%         end
%         
%         cVar(codes{pIdx,2}(codeIdx),1) = testStat;
%         cVar(codes{pIdx,2}(codeIdx),2) = prctile(resampleVec,99);
%         
%         resampleVec = zeros(nResample,1);
%         for resampleIdx=1:nResample
%             class2 = dataMatrix(dataLabels==2,:);
%             class2 = class2(randi(size(class2,1), size(class2,1), 1),:);
%             
%             class1 = dataMatrix(dataLabels==1,:);
%             class1 = class1(randi(size(class1,1), size(class1,1), 1),:);
%             
%             testStat = norm(mean(class2) - mean(class1));
%             resampleVec(resampleIdx) = testStat;
%         end
%         cVar(codes{pIdx,2}(codeIdx),3:4) = prctile(resampleVec,[2.5,97.5]);    
    end
end    