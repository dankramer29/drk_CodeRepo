%%
%TODO:

%decoding methods for excluding dimensions of variation in other datasets
%exclude trial-averaged modulation? sample-by-sample modulation? variable
%penalty strength term? Rigid orothongalization?

%simulation - how many channels are needed to reliably separate how many
%dimensions?

%contralateral vs. ipsilateral, directional arm imagery

%combine leg & arm to boost signal? 

%show real-time increase in independence and ability to separate

%%
%see movementTypes.m for code definitions
movTypes = {[5 6],'head'
    [8 9],'face'
    [12 13],'arm'
    [16 17],'leg'
    [18 19],'eyes'
    [20 21],'tongue'
    [2 3],'cursor_CL'};
blockList = horzcat(movTypes{:,1});
blockList = sort(blockList);

burstChans = [67, 68, 69, 73, 77, 78, 82];
smallBurstChans = [2, 46, 66, 76, 83, 85, 86, 94, 95, 96]; %  to be super careful
excludeChannels = sort( [burstChans, smallBurstChans ] );

%%
paths = getFRWPaths();
addpath(genpath(paths.codePath));

%%
binMS = 10;
timeWindow = [-1200 3000];

%%
outDir = [paths.dataPath filesep 'Derived' filesep 'MovementSweep' filesep 'all'];
mkdir(outDir);
sessionPath = [paths.dataPath filesep 'BG Datasets' filesep 't5.2017.10.16' filesep];

%%
%load cursor filter for threshold values, use these across all movement types
model = load([paths.dataPath filesep 'BG Datasets' filesep 't5.2017.10.16' filesep 'Data' filesep 'Filters' filesep ...
    '002-blocks002-thresh-4.5-ch50-bin15ms-smooth25ms-delay0ms.mat']);

%%
%load cued movement dataset
R = getSTanfordBG_RStruct( sessionPath, setdiff(blockList,[1 2 3]), model.model );

trlCodes = zeros(size(R));
for t=1:length(trlCodes)
    trlCodes(t) = R(t).startTrialParams.currentMovement;
end

alignField = 'goCue';

allSpikes = [[R.spikeRaster]', [R.spikeRaster2]'];
meanRate = mean(allSpikes)*1000;
tooLow = meanRate < 0.5;

allSpikes(:,tooLow) = [];
allSpikes = gaussSmooth_fast(allSpikes, 30);

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

%%
%load cursor dataset
R_curs = getSTanfordBG_RStruct( sessionPath, [2 3], model.model );

R_curs(1) = [];
opts.filter = false;
opts.useDecodeSpeed = true;
data = unrollR_1ms(R_curs, opts);

trlCodes_curs = data.targCodes;
centerIdx = find(trlCodes_curs==5);
trlCodes_curs(centerIdx) = trlCodes_curs(centerIdx-1)+9;

allBlockNum_curs = [R_curs.blockNum]';
alignField = 'timeGoCue';

allSpikes_curs = [[R_curs.spikeRaster]', [R_curs.spikeRaster2]'];
allSpikes_curs(:,tooLow) = [];
allSpikes_curs = gaussSmooth_fast(allSpikes_curs, 30);

globalIdx = 0;
alignEvents_curs = zeros(length(R_curs),2);
allBlocks_curs = zeros(size(allSpikes_curs,1),1);
for t=1:length(R_curs)
    loopIdx = (globalIdx+1):(globalIdx + length(R_curs(t).spikeRaster));
    allBlocks_curs(loopIdx) = R_curs(t).blockNum;
    alignEvents_curs(t,1) = globalIdx + R_curs(t).(alignField);
    alignEvents_curs(t,2) = globalIdx - 300;
    globalIdx = globalIdx + size(R_curs(t).spikeRaster,2);
end

cursPosErr = data.targetPos(:,1:4) - data.cursorPos(:,1:4);
%%
%combine cursor & cued movement conditions
trlCodes = [trlCodes_curs', trlCodes];
[trlCodeList,~,trlCodesRemap] = unique(trlCodes);
alignEvents = [alignEvents_curs; alignEvents+size(allSpikes_curs,1)];
allSpikes = [allSpikes_curs; allSpikes];
allBlocks = [allBlocks_curs; allBlocks];
allPosErr = [cursPosErr; zeros(size(allSpikes,1),4)];

%%
nBins = (timeWindow(2)-timeWindow(1))/binMS;
posErrMatrix = zeros(nBins, size(allPosErr,2));
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
    newPosErrRow = zeros(nBins, 4);
    binIdx = 1:binMS;
    for b=1:nBins
        if binIdx(end)>length(loopIdx)
            continue;
        end
        newRow(b,:) = sum(allSpikes(loopIdx(binIdx),:));
        newPosErrRow(b,:) = mean(allPosErr(loopIdx(binIdx),:));
        binIdx = binIdx + binMS;
    end

    newIdx = (globalIdx):(globalIdx+nBins-1);
    globalIdx = globalIdx+nBins;
    blockRows(newIdx) = repmat(allBlocks(loopIdx(binIdx(1))), size(newRow,1), 1);
    posErrMatrix(newIdx,:) = newPosErrRow;
    snippetMatrix(newIdx,:) = newRow;
end

%%
bNumPerTrial = [[R_curs.blockNum],[R.blockNum]];
for b=1:length(blockList)
    disp(b);
    blockTrl = find(bNumPerTrial==blockList(b));
    msIdx = [];
    for t=1:length(blockTrl)
        msIdx = [msIdx, (alignEvents(blockTrl(t),2)):(alignEvents(blockTrl(t),2)+400)];
    end
    
    binIdx = find(blockRows==blockList(b));
    snippetMatrix(binIdx,:) = bsxfun(@plus, snippetMatrix(binIdx,:), -mean(allSpikes(binIdx,:))*binMS);
end
rawSnippetMatrix = snippetMatrix;
snippetMatrix = bsxfun(@times, snippetMatrix, 1./std(snippetMatrix));

%%
shuffPostfix = {'','_shuff'};
for doShuff = 1:2
    dPCA_out = cell(size(movTypes,1),1);
    eventIdx = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
    codes = cell(size(movTypes,1),2);
    for pIdx = 1:size(movTypes,1)
        trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
        if strcmp(movTypes{pIdx,2},'cursor_CL')
            %ignore return
            trlIdx(trlCodes(trlIdx)>9)=false;
        end
        
        codes{pIdx,1} = unique(trlCodes(trlIdx));
        codes{pIdx,2} = unique(trlCodesRemap(trlIdx));

        tmpCodes = trlCodesRemap(trlIdx);
        shuffIdx = randperm(length(tmpCodes));
        if doShuff == 2
            tmpCodes = tmpCodes(shuffIdx);
        end

        dPCA_out{pIdx} = apply_dPCA_simple( snippetMatrix, eventIdx(trlIdx), ...
            tmpCodes, timeWindow/binMS, binMS/1000, {'CI','CD'} );
        close(gcf);
    end    

    timeAxis = (timeWindow(1)/1000):(binMS/1000):(timeWindow(2)/1000);
    yLims = [];
    axHandles=[];
    plotIdx = 1;
    topN = 8;
    
    movTypeText = {'Head','Mouth &\newlineFace','Arm','Leg','Eyes','Tongue','4D Cursor'};
    movLegends = {{'Right','Left','Up','Down','TiltRight','TiltLeft','Forward','Backward'}
        {'Ba','Ga','MouthOpen','JawClench','Pucker','Eyebrows','NoseWrinkle'}
        {'Shrug','ArmRaise','ElbowFlex','WristExt','CloseHand','OpenHand','Index','Thumb'}
        {'AnkleUp','AnkleDown','KneeExtend','LegUp','ToeCurl','ToeOpen'}
        {'EyesUp','EyesDown','EyesLeft','EyesRight'}
        {'TongueUp','TongueDown','TongueLeft','TongueRight'}
        {'Cursor -X','Cursor -Y','Cursor -Z','Cursor -R','Cursor R','Cursor Z','Cursor Y','Cursor X'}};

    figure('Position',[272         108        1551         997]);
    for pIdx=1:length(movTypes)
        cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
        for c=1:topN
            axHandles(plotIdx) = subtightplot(length(movTypes),topN,(pIdx-1)*topN+c);
            hold on

            colors = jet(size(dPCA_out{pIdx}.Z,2))*0.8;
            for conIdx=1:size(dPCA_out{pIdx}.Z,2)
                plot(timeAxis, squeeze(dPCA_out{pIdx}.Z(cdIdx(c),conIdx,:)),'LineWidth',2,'Color',colors(conIdx,:));
            end

            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            plotIdx = plotIdx + 1;

            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k');
            if ismember(pIdx,[3 4])
                plot([2.5, 2.5],[-100, 100],'--k');
            elseif ismember(pIdx,[1 2 5 6])
                plot([1.5, 1.5],[-100, 100],'--k');
            end
            set(gca,'LineWidth',1.5,'YTick',[],'FontSize',12);
            
            if pIdx==length(movTypes)
                xlabel('Time (s)');
            else
                set(gca,'XTickLabels',[]);
            end
            if pIdx==1
                text(0.025,0.8,'Prep','Units','Normalized','FontSize',12);
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);
                text(0.7,0.8,'Return','Units','Normalized','FontSize',12);
                title(['Dim ' num2str(c)],'FontSize',11)
            elseif pIdx==7
                text(0.3,0.8,'Go','Units','Normalized','FontSize',12);
            end

            if c==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
            if c==topN
                lHandle = legend(movLegends{pIdx});
                lPos = get(lHandle,'Position');
                lPos(1) = lPos(1)+0.05;
                set(lHandle,'Position',lPos);
            end
            set(gca,'FontSize',14);
        end
    end

    if doShuff == 1
        finalLimits = [min(yLims(:,1)), max(yLims(:,2))];
    end
    for p=1:length(axHandles)
        set(axHandles(p), 'YLim', finalLimits);
    end

    saveas(gcf,[outDir filesep 'dPCA_all' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'dPCA_all' shuffPostfix{doShuff} '.svg'],'svg');

    %%
    colors = hsv(length(movTypes))*0.8;
    colors = colors(randperm(length(movTypes)),:);
    windows = {150:170, 80:120};
    windowNames = {'Move','Prep'};

    figure('Position',[802         173        1197         897]);
    for windowIdx = 1:length(windows)
        cVar = zeros(length(trlCodeList),1);
        for pIdx = 1:size(movTypes,1)
            cdIdx = find(dPCA_out{pIdx}.whichMarg==1);
            for x=1:size(dPCA_out{pIdx}.Z,2)
                %tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:5),x,:))';
                %cVar(codes{pIdx,2}(x)) = sqrt(sum(var(tmp)));
                %tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:10),x,windows{windowIdx}));
                %cVar(codes{pIdx,2}(x)) = (sum(tmp(:).^2));
                tmp = squeeze(dPCA_out{pIdx}.Z(cdIdx(1:8),x,windows{windowIdx}))';
                cVar(codes{pIdx,2}(x)) = (sum(abs(mean(tmp))));
            end
        end    

        cVar = cVar - 0.35;
        if strcmp(windowNames{windowIdx},'Prep')
            cVar(1:16)=0;
        end
        movLabels = horzcat(movLegends{:});
        plotIdx = 1;

        subtightplot(2,1,windowIdx,[0.05 0.05],[0.15 0.05],[0.05 0.01]);
        hold on
        for pIdx=1:size(movTypes,1)
            dat = (cVar(codes{pIdx,2}));
            bar((plotIdx):(plotIdx + length(dat) - 1), dat, 'FaceColor', colors(pIdx,:));
            plotIdx = plotIdx + length(dat);
        end
        title(windowNames{windowIdx});
        set(gca,'LineWidth',1.5,'FontSize',18,'XTick',[]);
        if windowIdx==2
            set(gca,'XTick',1:length(trlCodeList),'XTickLabel',movLabels,'XTickLabelRotation',45);
        end

        ylim([0 12]);
        xlim([0.5, 45.5]);
        ylabel('Neural Modulation');
        set(gca,'TickLength',[0 0]);
    end
    
    saveas(gcf,[outDir filesep 'bar_all_window' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'bar_all_window' shuffPostfix{doShuff} '.svg'],'svg');
    
    %%
    %cross dPCA application
    for pIdx = 1:size(movTypes,1)
        cross_dPCA = cell(size(dPCA_out));
        for pInner = 1:size(movTypes,1)
            cross_dPCA{pInner} = do_dPCA_cross( dPCA_out{pIdx}, dPCA_out{pInner} );
        end
        dPCA_sweep_plot( cross_dPCA, timeAxis, movTypeText, movLegends );
        
        saveas(gcf,[outDir filesep 'dPCA_cross_' movTypes{pIdx,2} shuffPostfix{doShuff} '.png'],'png');
        saveas(gcf,[outDir filesep 'dPCA_cross_' movTypes{pIdx,2} shuffPostfix{doShuff} '.svg'],'svg');
    end
    
    %%
    %measure trial-averaged result of applying cursor decoder to other
    %conditions
    cursorLoopIdx = 1:106973;
    nonCursorIdx = setdiff(1:size(rawSnippetMatrix,1), cursorLoopIdx);
    
    decoder = model.model.K([2 4 6 8],1:192);
    decoder = bsxfun(@times, decoder, model.model.invSoftNormVals(1:192)');
    decoder = decoder(:,~tooLow)';
    decOut = rawSnippetMatrix * decoder;
    decOut(nonCursorIdx,2) = -decOut(nonCursorIdx,2);
    
    axHandles = zeros(length(movTypes), 4);
    yLims = [];
    decTitle = {'X','Y','Z','Rot'};
    
    figure('Position',[680          82        1075        1016]);
    for pIdx = 1:size(movTypes,1)
        trlIdx = ismember(bNumPerTrial, movTypes{pIdx,1});
        if strcmp(movTypes{pIdx,2},'cursor_CL')
            %ignore return
            trlIdx(trlCodes(trlIdx)>9)=false;
        end
       
        trlIdx = find(trlIdx);
        tmpCodes = trlCodesRemap(trlIdx);
        codeList = unique(tmpCodes);
        conAvg = cell(length(codeList),1);
        
        for c=1:length(codeList)
            innerIdx = find(tmpCodes == codeList(c));
            ta = triggeredAvg(decOut, eventIdx(trlIdx(innerIdx)), timeWindow/binMS);
            conAvg{c} = squeeze(mean(ta));
        end
        
        for decDim=1:4
            axHandles(pIdx, decDim) = subplot(length(movTypes), 4, decDim + (pIdx-1)*4);
            hold on;
            for c=1:length(conAvg)
                plot(timeAxis, conAvg{c}(:,decDim),'LineWidth',1.5);
            end
            
            if decDim==4
                lHandle = legend(movLegends{pIdx},'AutoUpdate','off');
                lPos = get(lHandle,'Position');
                lPos(1) = lPos(1)+0.05;
                set(lHandle,'Position',lPos);
            end
            
            axis tight;
            yLims = [yLims; get(gca,'YLim')];
            
            plot(get(gca,'XLim'),[0 0],'k');
            plot([0, 0],[-100, 100],'--k');
            if ismember(pIdx,[3 4])
                plot([2.5, 2.5],[-100, 100],'--k');
            elseif ismember(pIdx,[1 2 5 6])
                plot([1.5, 1.5],[-100, 100],'--k');
            end
            
            set(gca,'FontSize',14);
            if pIdx==1
                title(decTitle{decDim});
                text(0.025,0.2,'Prep','Units','Normalized','FontSize',12);
                text(0.3,0.2,'Go','Units','Normalized','FontSize',12);
                text(0.7,0.2,'Return','Units','Normalized','FontSize',12);
            end
            if pIdx<length(movTypes)
                set(gca,'XTickLabels',[]);
            end
            if decDim==1
                text(-0.45,0.5,movTypeText{pIdx},'Units','normalized','FontSize',14,'HorizontalAlignment','Left');
            end
        end
    end    
    
    finalLims = [min(yLims(:,1)), max(yLims(:,2))];
    for pIdx=1:length(movTypes)
        for decDim=1:4
            set(axHandles(pIdx, decDim), 'YLim', finalLims);
            set(axHandles(pIdx, decDim),'LineWidth',1.5,'YTick',[]);
        end
    end
    
    saveas(gcf,[outDir filesep 'decoder_cross' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'decoder_cross' shuffPostfix{doShuff} '.svg'],'svg');
    
    %%
    
    %%
    %make cursor decoder with additional requirement of zero tuning for
    %head movement; 
    orthoDec = buildLinFilts(posErrMatrix(1:106973,:), rawSnippetMatrix(1:106973,:), 'standard');
    
    orthoDec = buildLinFilts(posErrMatrix, rawSnippetMatrix, 'standard');
    
    %orthoganlize to PCA dimensions
    expFeature = dPCA_out{1}.featureAverages(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(expFeature);
    projValues = orthoDec' * COEFF(:,1:6);
    orthoDec = orthoDec - COEFF(:,1:6) * projValues';     
    
    %orthogonalize all together to V
    cdAx = find(dPCA_out{pIdx}.whichMarg==1);
    normAx = bsxfun(@times, dPCA_out{pIdx}.V(:,cdAx(1:topN)), 1./matVecMag(dPCA_out{pIdx}.V(:,cdAx(1:topN)),1));
    projValues = orthoDec' * normAx;
    orthoDec = orthoDec - normAx * projValues';     
    
    %strictly orthogonalize (doesn't actually work perfectly since W is not
    %orthonormal)
    topN = 4;
    for pIdx=1:1
        for t=1:topN
            cdAx = find(dPCA_out{pIdx}.whichMarg==1);
            normAx = dPCA_out{pIdx}.W(:,cdAx(t))/norm(dPCA_out{pIdx}.W(:,cdAx(t)));
            projValues = orthoDec' * normAx;
            orthoDec = orthoDec - bsxfun(@times, normAx, projValues');
        end
    end
    
    %%
    %use quadprog to find optimal decoder in the orthogonal space
    expFeature = dPCA_out{1}.featureAverages(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(expFeature);
    cdAx = find(dPCA_out{1}.whichMarg==1);
    normAx = COEFF(:,1:20);
    
    orthoDec = zeros(size(rawSnippetMatrix,2), 4);
    for dimIdx=1:4
        predictors = rawSnippetMatrix(:,:);
        response = posErrMatrix(:,dimIdx);

        A = predictors'*predictors;
        q = zeros(size(predictors,2),1);
        for n=1:size(predictors,2)
            q(n) = -sum(predictors(:,n).*response);
        end
        quadOpts = optimoptions('quadprog', 'display', 'off');

        orthoDec(:,dimIdx) = quadprog(A,q,[],[],normAx',zeros(size(normAx,2),1),[],[],[],quadOpts);
    end
    
    decOut = rawSnippetMatrix * orthoDec;
    
    %%
    %measure penalty incurred from head-orthogonalization
    expFeature = dPCA_out{1}.featureAverages(:,:)';
    [COEFF, SCORE, LATENT, TSQUARED, EXPLAINED] = pca(expFeature);
    
    orthoDims = 0:40;
    decCorr = zeros(length(orthoDims), 4);
    for o=1:length(orthoDims)
        disp(o);
        
        if orthoDims(o)>0
            normAx = COEFF(:,1:orthoDims(o));
        else
            normAx = [];
        end
        
        orthoDec = zeros(size(rawSnippetMatrix,2), 4);
        for dimIdx=1:4
            predictors = rawSnippetMatrix(:,:);
            response = posErrMatrix(:,dimIdx);

            A = predictors'*predictors;
            q = zeros(size(predictors,2),1);
            for n=1:size(predictors,2)
                q(n) = -sum(predictors(:,n).*response);
            end
            quadOpts = optimoptions('quadprog', 'display', 'off');

            if isempty(normAx)
                orthoDec(:,dimIdx) = quadprog(A,q,[],[],[],[],[],[],[],quadOpts);
            else
                orthoDec(:,dimIdx) = quadprog(A,q,[],[],normAx',zeros(size(normAx,2),1),[],[],[],quadOpts);
            end
        end

        decOut = rawSnippetMatrix * orthoDec;
        tmp = corr(decOut(1:106973,:), posErrMatrix(1:106973,:));
        decCorr(o,:) = diag(tmp);
    end
    
    figure; 
    plot(decCorr,'-o','LineWidth',1.5);
    legend({'X','Y','Z','Rot'});
    set(gca,'LineWidth',1.5,'FontSize',14);
    ylim([0 0.75]);
    saveas(gcf,[outDir filesep 'decoder_orthoCorr' shuffPostfix{doShuff} '.png'],'png');
    saveas(gcf,[outDir filesep 'decoder_orthoCorr' shuffPostfix{doShuff} '.svg'],'svg');
    
end

%%
lineArgs = cell(length(trlCodeList),1);
colors = jet(length(lineArgs));
for l=1:length(lineArgs)
    lineArgs{l} = {'LineWidth',1,'Color',colors(l,:)};
end

psthOpts = makePSTHOpts();
psthOpts.gaussSmoothWidth = 0;
psthOpts.neuralData = {snippetMatrix};
psthOpts.timeWindow = timeWindow/binMS;
psthOpts.trialEvents = (-timeWindow(1)/binMS):nBins:size(snippetMatrix,1);
psthOpts.trialConditions = trlCodesRemap;
psthOpts.conditionGrouping = {1:length(trlCodeList)};
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

in = psthOpts;
in.neuralData{1} = psthOpts.neuralData{1}(:,~ismember(usedChans, excludeChannels));
psthOpts.prefix = 'clean';
makePSTH_simple(in);
close all;

in = psthOpts;
in.neuralData{1} = psthOpts.neuralData{1}(:,ismember(usedChans, excludeChannels));
psthOpts.prefix = 'excluded';
makePSTH_simple(in);
close all;

% %%
% nCon = length(trlCodeList);
% nChan = size(snippetMatrix,2);
% cSNR = zeros(nChan, nCon);
% 
% binWindow = [20:40];
% for t=1:length(trlCodeList)
%     trlIdx = find(trlCodes==trlCodeList(t));
%     binIdx = [];
%     for x=1:length(trlIdx)
%         binIdx = [binIdx, eventIdx(trlIdx(x)) + binWindow];
%     end
%     
%     mnMod = mean(snippetMatrix(binIdx,:));
%     sdMod = std(snippetMatrix(binIdx,:))+0.1;
%     cSNR(:,t) = abs(mnMod)./sdMod;
% end

%%
%      TURN_HEAD_RIGHT(67)
%       
%       %FRW - head movement experiment 2017-09-23
%       TURN_HEAD_LEFT(71)
%       TURN_HEAD_UP(72)
%       TURN_HEAD_DOWN(73)
%       
%       %FRW broad movement sweep for 2017-10-15
%       HEAD_TILT_RIGHT(74)
%       HEAD_TILT_LEFT(75)
%       HEAD_FORWARD(76)
%       HEAD_BACKWARD(77)
%       
%       TONGUE_UP(78)
%       TONGUE_DOWN(79)
%       TONGUE_LEFT(80)
%       TONGUE_RIGHT(81)
%       
%       EYES_UP(82)
%       EYES_DOWN(83)
%       EYES_LEFT(84)
%       EYES_RIGHT(85)
%       
%       MOUTH_OPEN(86)
%       JAW_CLENCH(87)
%       PUCKER_LIPS(88)
%       RAISE_EYEBROWS(89)
%       NOSE_WRINKLE(90)
%       
%       SHO_SHRUG(91)
%       ARM_RAISE(92)
%       ARM_LOWER(93)
%       ELBOW_FLEX(94)
%       ELBOW_EXT(95)
%       WRIST_EXT(96)
%       WRIST_FLEX(97)
%       CLOSE_HAND(98)
%       OPEN_HAND(99)
%       
%       THUMB_JOY_FORWARD(100)
%       THUMB_JOY_BACK(101)
%       THUMB_JOY_RIGHT(102)
%       THUMB_JOY_LEFT(103)
%       
%       ANKLE_UP(104)
%       ANKLE_DOWN(105)
%       KNEE_EXTEND(106)
%       KNEE_FLEX(107)
%       LEG_UP(108)
%       LEG_DOWN(109)
%       TOE_CURL(110)
%       TOE_OPEN(111)
%       
%       TORSO_UP(112)
%       TORSO_DOWN(113)
%       TORSO_TWIST_RIGHT(114)
%       TORSO_TWIST_LEFT(115)
% 
%       INDEX_RAISE(116)
%       THUMB_UP(117)