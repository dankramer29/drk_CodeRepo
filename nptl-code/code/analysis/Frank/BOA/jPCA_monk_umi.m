datasets = {'R-2019-03-18','R-2019-03-19','R-2019-02-25'};

%%
for datasetIdx=1:length(datasets)
    %%
    %2d reaching split
    load(['/Users/frankwillett/Data/Monk/UmiData/' datasets{datasetIdx} '.mat']);
    outDir = ['/Users/frankwillett/Data/Derived/BOA/UmiJPCA/' datasets{datasetIdx}];
    mkdir(outDir);
    nDim = 2;

    for t=1:length(R)
        R(t).currentTarget = repmat(R(t).startTrialParams.posTarget(1:nDim),1,length(R(t).cursorPos));
        R(t).saveTag = R(t).startTrialParams.saveTag;
        R(t).blockNum = R(t).saveTag;
    end

    rtIdxAll = zeros(length(R),1);
    [B,A] = butter(4, 5/500);
    for t=1:length(R)
        %RT
        if t>1 && t<length(R)
            concatPos = double([R(t-1).cursorPos, R(t).cursorPos, R(t+1).cursorPos]');
            concatPos = filtfilt(B,A,concatPos); %reseed
            pos = concatPos((length(R(t-1).cursorPos)+1):(length(R(t-1).cursorPos)+length(R(t).cursorPos)),:);
            pos = pos(:,1:2);
        else   
            pos = double(R(t).cursorPos(1:2,:)');
            pos(21:end,:) = filtfilt(B,A,pos(21:end,:)); %reseed
        end

        vel = [0 0; diff(pos)];
        vel(1:21,:) = 0;

        speed = matVecMag(vel,2)*1000;
        speed(speed>1000) = 0;
        R(t).speed = speed';
        R(t).maxSpeed = max(speed);
    end

    tPos = zeros(length(R),2);
    for t=1:length(R)
        tPos(t,:) = R(t).startTrialParams.posTarget(1:nDim);
    end

    [targList,~,targCodes] = unique(tPos,'rows');
    centerCode = find(targList(:,1)==0 & targList(:,2)==0);

    ms = [R.maxSpeed];
    avgMS = zeros(length(targList),1);
    for t=1:length(targList)
        tmp = ms(targCodes==t);
        tmp(tmp>900)=[];
        avgMS(t) = median(tmp);
    end

    for t=1:length(R)
        useThresh = max(avgMS(targCodes(t))*0.3,30);

        rtIdx = find(R(t).speed>useThresh,1,'first');
        if isempty(rtIdx)
            rtIdx = 150;
            rtIdxAll(t) = nan;
        else
            rtIdxAll(t) = rtIdx;
        end       
        R(t).rtTime = rtIdx;
    end

    rtTime = [R.rtTime];
    for x=1:length(R)
        pos = R(x).cursorPos';
        vel = [zeros(1,nDim); diff(pos)];
        vel = gaussSmooth_fast(vel,10);
        R(x).cursorVel = vel';
    end
    
    %%
    %umi spike raster
    for t=1:length(R)
        R(t).spikeRaster = [R(t).spikeRasterM1M; R(t).spikeRasterM1L];
        R(t).spikeRaster2 = R(t).spikeRasterPMd;
    end
        
    %%
    afSet = {'timeTargetOn_a','rtTime_a'};
    twSet = {[-400,1000],[-740,740]};
    pfSet = {'goCue','moveOnset'};

    tto = [R.delayLength];
    delayTime = [R.delayLength];
    rtTime_use = rtTime;

    validTrl = cell(length(afSet),1);
    validTrl{1} = find(~isnan(tto) & delayTime>300);
    validTrl{2} = find(~isnan(rtTime) & delayTime>300);

    tto(isnan(tto)) = 300;
    rtTime_use(isnan(rtTime_use)) = 300;

    for t=1:length(R)
        R(t).timeTargetOn_a = tto(t);
        R(t).rtTime_a = rtTime_use(t);
        R(t).trialStart = 1;
    end

    for alignSetIdx=2:length(afSet)
        alignFields = afSet(alignSetIdx);
        smoothWidth = 0;
        datFields = {'cursorPos','currentTarget','cursorVel','speed'};
        timeWindow = twSet{alignSetIdx};
        binMS = 10;

        clear alignDat;
        alignDat = binAndAlignR( R, timeWindow, binMS, smoothWidth, alignFields, datFields );

        vt = validTrl{alignSetIdx};
        alignDat.eventIdx = alignDat.eventIdx(vt);
        alignDat.allZScoreSpikes = alignDat.zScoreSpikes;
        alignDat.zScoreSpikes = gaussSmooth_fast(alignDat.zScoreSpikes,3);
        meanRate = mean(alignDat.rawSpikes)*1000/binMS;
        tooLow = meanRate < 1.0;
        goodChans = find(~tooLow);
        alignDat.zScoreSpikes(:,tooLow) = [];

        chanSet = {find(ismember(goodChans, 1:96)),...
            find(ismember(goodChans, 97:192))};

        arrayNames = {'M1','PMd'};
        for arrayIdx=1:length(chanSet)
            %%
            %get trials
            trlIdx = [R(vt).isSuccessful]';
            trlIdx = find(trlIdx);
            %trlIdx = trlIdx(1:(end-1));

            tPos = alignDat.currentTarget(alignDat.eventIdx(trlIdx)+10,:);
            [targList, ~, targCodes] = unique(tPos,'rows');
            centerCode = find(all(targList(:,1:2)==0,2));
            targDist = matVecMag(tPos(:,1:2),2);

            if isempty(centerCode)
                outerIdx = 1:length(trlIdx);
            else
                outerIdx = find(targCodes~=centerCode);
            end

            speedProfile = triggeredAvg(alignDat.speed, alignDat.eventIdx(trlIdx(outerIdx)), timeWindow/binMS);
            speedProfile = nanmean(speedProfile)';

            %%
            %apply marginalized PCA
            margGroupings = {{1, [1 2]}, ...
                {2}};
            margNames = {'Target','Time'};

            opts_m.margNames = margNames;
            opts_m.margGroupings = margGroupings;
            opts_m.nCompsPerMarg = 5;
            opts_m.makePlots = true;
            opts_m.nFolds = 10;
            opts_m.readoutMode = 'singleTrial';
            opts_m.alignMode = 'rotation';
            opts_m.plotCI = true;

            [tcList,~,tcReorder] = unique(targCodes(outerIdx));
            mPCA_cue = apply_mPCA_general( alignDat.zScoreSpikes(:,chanSet{arrayIdx}), alignDat.eventIdx(trlIdx(outerIdx)), ...
                tcReorder, [-70,70], 0.010, opts_m);

            %%
            %save mPCA plot with forced axes
            mp = mPCA_cue.margPlot;
            mp.layoutInfo.nPerMarg = 5;
            [yAxesFinal, allHandles, allYAxes] = marg_mPCA_plot( mPCA_cue.margResample, mp.timeAxis, mp.lineArgs, ...
                mp.plotTitles, 'sameAxes', [], [], [], mp.lineArgsPerMarg, opts_m.margGroupings, opts_m.plotCI, mp.layoutInfo );
            set(gcf,'Position',[136   194   596   868]);
            saveas(gcf,[outDir filesep arrayNames{arrayIdx} '_mPCA.png'],'png');

            %%
            %jPCA
            nCon = size(mPCA_cue.featureAverages,2);
            tw_all = [-70, 70];
            timeStep = binMS/1000;
            timeAxis = (tw_all(1):tw_all(2))*timeStep;

            Data = struct();
            timeMS = round(timeAxis*1000);
            for n=1:nCon
                Data(n).A = squeeze(mPCA_cue.featureAverages(:,n,:))';
                Data(n).times = timeMS;
            end

            jPCA_params.normalize = true;
            jPCA_params.softenNorm = 0;
            jPCA_params.suppressBWrosettes = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.suppressHistograms = true;  % these are useful sanity plots, but lets ignore them for now
            jPCA_params.meanSubtract = true;
            jPCA_params.numPCs = 6;  % default anyway, but best to be specific

            winStart = [-300,-250,-200,-150,-100,-50];
            freq = zeros(length(winStart),6);
            for wIdx=1:length(winStart)
                windowIdx = [winStart(wIdx), winStart(wIdx)+200];

                %short window
                jPCATimes = windowIdx(1):10:windowIdx(2);
                for x = 1:length(jPCATimes)
                    [~,minIdx] = min(abs(jPCATimes(x) - Data(1).times));
                    jPCATimes(x) = Data(1).times(minIdx);
                end

                [Projections, jPCA_Summary] = jPCA(Data, jPCATimes, jPCA_params);
                phaseSpace(Projections, jPCA_Summary);  % makes the plot
                saveas(gcf, [outDir filesep arrayNames{arrayIdx} '_' num2str(windowIdx(1)) '_to_' num2str(windowIdx(2)) '_jPCA.png'],'png');
            
                % get the eigenvalues and eigenvectors
                [V,D] = eig(jPCA_Summary.Mskew); % V are the eigenvectors, D contains the eigenvalues
                evals = diag(D); % eigenvalues

                % the eigenvalues are usually in order, but not always.  We want the biggest
                [~,sortIndices] = sort(abs(evals),1,'descend');
                evals = evals(sortIndices);  % reorder the eigenvalues
                evals = imag(evals);  % get rid of any tiny real part
                V = V(:,sortIndices);  % reorder the eigenvectors (base on eigenvalue size)
                
                freq(wIdx,:) = (abs(evals)*100)/(2*pi);
            end
            close all;
            
            save([outDir filesep arrayNames{arrayIdx} '_jPCA_freq.mat'],'freq','winStart');

            %%
            %population image plot
            movLabels = {'t1','t2','t3','t4','t5','t6','t7','t8'};
            nTargsToShow = 8;
            nDimToShow = 5;

            figure('Position',[680   185   692   913]);
            for c=1:nTargsToShow
                concatDat = squeeze(mPCA_cue.featureVals(:,c,:,:));
                concatDat(isnan(concatDat)) = 0;
                concatDat = permute(concatDat,[3 2 1]);

                reducedDat = zeros(size(concatDat,1), size(concatDat,2), nDimToShow);
                for trialIdx=1:size(concatDat,1)
                    reducedDat(trialIdx,:,:) = squeeze(concatDat(trialIdx,:,:))*mPCA_cue.readouts(:,1:nDimToShow);
                end

                for dimIdx=1:nDimToShow
                    subtightplot(nTargsToShow,nDimToShow,(c-1)*nDimToShow + dimIdx);
                    hold on;

                    imagesc(timeAxis, 1:size(reducedDat,1), squeeze(reducedDat(:,:,dimIdx)),prctile(reducedDat(:),[2.5, 97.5]));
                    axis tight;
                    plot([0,0],get(gca,'YLim'),'-k','LineWidth',2);

                    cMap = diverging_map(linspace(0,1,100),[0 0 1],[1 0 0]);
                    colormap(cMap);

                    if dimIdx==1
                        ylabel(movLabels{c},'FontSize',16,'FontWeight','bold');
                    end
                    if c==1
                        title(['Dimension ' num2str(dimIdx)],'FontSize',16);
                    end

                    set(gca,'FontSize',16);
                    if c==length(movLabels)
                        set(gca,'YTick',[]);
                        xlabel('Time (s)');
                    else
                        set(gca,'XTick',[],'YTick',[]);
                    end
                end
            end

            saveas(gcf,[outDir filesep arrayNames{arrayIdx} '_popRaster.png'],'png');
            saveas(gcf,[outDir filesep arrayNames{arrayIdx} '_popRaster.fig'],'fig');
            close all;
        end
    end
    close all;
end

%%
%summarize frequencies
freq = zeros(length(datasets),2);
for datasetIdx=1:length(datasets)
    for arrayIdx=1:2
        outDir = ['/Users/frankwillett/Data/Derived/BOA/JenkinsJPCA/' datasets{datasetIdx}];
        tmp = load([outDir filesep arrayNames{arrayIdx} '_jPCA_freq.mat']);
        freq(datasetIdx,arrayIdx) = tmp.freq(2,1);
    end
end