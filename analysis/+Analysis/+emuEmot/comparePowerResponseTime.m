function [summaryStatsSigTrials] = comparePowerResponseTime(nback, identityTaskLFP, emotionTaskLFP, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   ALSO WANT TO LOOK AT THE TIMING OF THE PEAKS FOR WHEN TASK RELEVANT AND
%   TASK IRRELEVANT

[varargin, plt]=util.argkeyval('plt', varargin, 1); %toggle on or off if you want to plot
[varargin, timeMinMax]=util.argkeyval('timeMin', varargin, [.100 .700]); %Time, in S, that you want to find the peaks between 
[varargin, freqMinMax]=util.argkeyval('freqMinMax', varargin, [50 150]); %Freq, that you want to find the peaks between 
[varargin, chName]=util.argkeyval('chName', varargin, 'chX'); %for arranging the outputs by channel
[varargin, patientName]=util.argkeyval('patientName', varargin, 'PtX'); %for storing a total table
[varargin, sdThreshold]=util.argkeyval('sdThreshold', varargin, 1.5); %the threshold for individual trial SD for checking the trial by trial peaks



summaryStatsSigTrials = [];

%grab fields
chNum = fieldnames(nback);
conditionName = fieldnames(nback.(chNum{1}));
resultName = fieldnames(nback.(chNum{1}).(conditionName{1}));
resultNameAll = fieldnames(nback.(chNum{1}).(conditionName{4}));

bandNames = fieldnames(identityTaskLFP.byidentity.(chNum{1}).image.bandPassed);

bTT = identityTaskLFP.tPlotImageBandPass;
tt = identityTaskLFP.tPlotImage;
ff = identityTaskLFP.freq;

%% find the indices of the times in bandpassed
[~, tMinBand] = min(abs(bTT-timeMinMax(1)));
[~, tMaxBand] = min(abs(bTT-timeMinMax(2)));

%%
%look at high gamma for areas that were positive
%NOTE: THIS IS GOING TO KEEP IT TASK RELEVANT RIGHT NOW MEANING ONLY
%   LOOKING AT IDS FOR THE IDENTITY TASK AND EMOTIONS FOR THE EMOTION TASK
T2 = [];
for cc = 1:length(chNum)
    %identity task
%     T1 = [];
%     ClusterCenter = [];
%     TstatCluster = [];
%     ImageType = [];
%     MaxValue =[];
%     pkIndex = [];
%     TimeofMax=[];
%     CorrectResponseId = [];
%     CorrectResponseEm = [];
%     ResponseTimeId = [];
%     ResponseTimeEm = [];
    idx2 = 1;   
    for nn = 1:3  %runs through each id      
        T1 = [];        
        pkIndex = [];
        bData = [];
       
        PatientName =[];
        ChannelNumber = [];        
        TrialType = [];
        TrialNumber = [];        
        ClusterCenter = [];
        TstatCluster = [];
        ImageType = [];
        MaxValue = [];
        TimeofMax = [];
        TimeMinMax = [];
        FreqMinMax = [];
        SecondTrial = [];
        CorrectResponse = [];
        ResponseTime = [];
        RecordingLocation = [];
        ByTrialCentroid = [];
        ByTrialArea =[];
        ByTrialBoundingBoxTimeRange = [];
        ByTrialBoundingBoxFreqRange =[];
        AllImagesSignificant=[];
        %by identity that is statistically significant
        %first check if either a single ID is significant or all IDs are
        %significant, then run through that ID or all the IDs.
        if nnz(nnz(nback.(chNum{cc}).(conditionName{4}).identityTasksigclust))>0 || nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{3})))>0
            if nnz(nnz(nback.(chNum{cc}).(conditionName{4}).identityTasksigclust))>0
                AllImages = 1;
                for ii = 1:size(nback.(chNum{cc}).(conditionName{4}).identityTaskcentroid,1)
                    %check the centroid is in the high gamma range in the
                    %region after image presentation
                    cent = nback.(chNum{cc}).(conditionName{4}).identityTaskcentroid(ii,:);
                    centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                    normS1 = normalize(nback.(chNum{cc}).(conditionName{4}).identityTaskMean,2);
                    if centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                        bData = identityTaskLFP.byidentity.(chNum{cc}).image.bandPassed.(bandNames{5}){idx2};
                        sData = identityTaskLFP.byidentity.(chNum{cc}).image.specD{idx2};
                        sData = normalize(sData,2);
                        allVsingle = 0;
                    end
                end
            elseif nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{3})))>0
                AllImages = 0;
                for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{4}),1)
                    %check the centroid is in the high gamma range in the
                    %region after image presentation
                    cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{4})(ii,:);
                    centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                    normS1 = normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{1}),2);
                    %check that it's between the frequencies desired and is a
                    %positive deflection, then go trial by trial to get trial
                    %specific statistics.
                    if centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                        bData = identityTaskLFP.byidentity.(chNum{cc}).image.bandPassed.(bandNames{5}){idx2};
                        sData = identityTaskLFP.byidentity.(chNum{cc}).image.specD{idx2};
                        sData = normalize(sData,2);
                        allVsingle = 1;

                    end
                end
            end
            %% this is for plotting the bandpassed against the spec. right now they aren't lining up that well, but i moved on to cluster stats instead
            %                     meanbData = mean(bData,1);
            %                     meanbDataS = meanbData.^2;
            %                     bDataS = bData.^2;
            %                     figure; plot(bTT,normalize(meanbDataS), 'LineWidth', 3); hold on; plot(bTT,normalize(bDataS,2))
            %                     figure; imagesc(tt,ff, normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{1}),2)); axis xy
            %                     hold on; plot(centA(1), centA(2), '*b');
            %%
            if ~isempty(bData)
                for jj = 1:size(bData,1)
                    %%check if there is a cluster on each trial and record descriptive info on it
                    sDataTemp = sData(:,:,jj); %take the normalized data
                    mask = sData(:,:,jj)>sdThreshold;
                    clustP=bwconncomp(mask,8);
                    clRPos=regionprops(clustP, 'all'); %get the region properties
                    cl_aRPos=[clRPos.Area];
                    cl_keepPos=find(cl_aRPos>100); %only keep reasonably large ones
                    trTrue = 0;
                    centKeep = []; arKeep = []; BBTemp = []; BB = [];
                    for kk=1:length(cl_keepPos)
                        centr = clRPos(cl_keepPos(kk)).Centroid;
                        centrR(1) = tt(round(centr(1))); centrR(2) = ff(round(centr(2)));
                        if centrR(2)>=freqMinMax(1) && centrR(2)<=freqMinMax(2) && centrR(1) >= timeMinMax(1) && centrR(1) <= timeMinMax(2)
                            trTrue = 1;
                            centKeep(kk,:) = centrR;
                            arKeep(kk,:) = sum(sDataTemp(clustP.PixelIdxList{cl_keepPos(kk)})); %add up the total cluster of stds
                            BBTemp(kk,:) = clRPos(cl_keepPos(kk)).BoundingBox;
                            %convert the bounding box to actual values
                            %of time and frequency
                            BB(kk,1) =  tt(round(BBTemp(kk,1)));
                            BB(kk,3) = BB(kk,1) + ((tt(2)-tt(1))*BBTemp(kk,3));
                            BB(kk,2) = ff(round(BBTemp(kk,2)));
                            BB(kk,4) = BB(kk,2) + ((ff(2)-ff(1))*BBTemp(kk,4));
                        end
                    end
                    if size(arKeep,1) > 1 && trTrue == 1
                        [mx I] = max(arKeep);
                        ByTrialCentroid(jj,:) = centKeep(I,:);
                        ByTrialArea(jj,:) = arKeep(I,:);
                        ByTrialBoundingBoxTimeRange(jj,:) = [BB(I,1) BB(I,3)];
                        ByTrialBoundingBoxFreqRange(jj,:) = [BB(I,2) BB(I,4)];
                    elseif trTrue == 1
                        ByTrialCentroid(jj,:) = centKeep(1,:);
                        ByTrialArea(jj,:) = arKeep(1,:);
                        ByTrialBoundingBoxTimeRange(jj,:) = [BB(1,1) BB(1,3)];
                        ByTrialBoundingBoxFreqRange(jj,:) = [BB(1,2) BB(1,4)];
                    elseif trTrue == 0
                        ByTrialCentroid(jj,:) = [NaN NaN];
                        ByTrialArea(jj,:) = [NaN];
                        ByTrialBoundingBoxTimeRange(jj,:) = [NaN NaN];
                        ByTrialBoundingBoxFreqRange(jj,:) = [NaN NaN];
                    end
                    RecordingLocation{jj,1} = chName{cc};
                    ChannelNumber{jj,1} = chNum{cc};
                    PatientName{jj,1} =  patientName;
                    TrialType{jj,1} = 'identityTask';
                    TrialNumber{jj,1} = jj;
                    AllImagesSignificant(jj,1) = AllImages; %if the summary of all has the cluster, then flag it.
                    TimeMinMax(jj,:) = timeMinMax;
                    FreqMinMax(jj,:) = freqMinMax;
                    ClusterCenter(jj,:) = centA;
                    if allVsingle == 0
                        TstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{4}).identityTasktstatSum(ii,1); %if it's gamma, grab that tstat for the All
                    elseif allVsingle == 1
                        TstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{5})(ii,1); %if it's gamma, grab that tstat
                    end
                    ImageType{jj,1} = (conditionName{nn});
                    [MaxValue(jj,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand).^2);
                    TimeofMax(jj,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms
                    if length(identityTaskLFP.byidentity.(chNum{cc}).correctTrial{idx2}) < jj
                        CorrectResponse(jj,1) = 0;
                        ResponseTime(jj,1) = mean(identityTaskLFP.byidentity.(chNum{cc}).responseTimesInSec{idx2});

                    else
                        CorrectResponse(jj,1) = identityTaskLFP.byidentity.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTime(jj,1) = identityTaskLFP.byidentity.(chNum{cc}).responseTimesInSec{idx2}(jj);
                    end                  
                end
                T1 = table(PatientName, RecordingLocation, ChannelNumber, TrialType, AllImagesSignificant, ImageType, TrialNumber, TimeMinMax, FreqMinMax,  ClusterCenter,...
                    TstatCluster, ByTrialCentroid, ByTrialArea, ByTrialBoundingBoxTimeRange, ByTrialBoundingBoxFreqRange, MaxValue, TimeofMax,...
                    CorrectResponse, ResponseTime);
            end        
        end
        %add each trial necessary
        T2 = [T2; T1];
        idx2 = idx2+1;
    end

    %% emotion task

    idx2 = 1;    
    for nn = 5:7  %runs through each id
        T1 = [];        
        pkIndex = [];
        bData = [];
        PatientName =[];
        ChannelNumber = [];        
        TrialType = [];
        TrialNumber = [];        
        ClusterCenter = [];
        TstatCluster = [];
        ImageType = [];
        MaxValue = [];
        AllImages = [];
        AllImagesSignificant = [];
        TimeofMax = [];
        TimeMinMax = [];
        FreqMinMax = [];
        SecondTrial = [];
        CorrectResponse = [];
        ResponseTime = [];
        RecordingLocation = [];
        ByTrialCentroid = [];
        ByTrialArea =[];
        ByTrialBoundingBoxTimeRange = [];
        ByTrialBoundingBoxFreqRange =[];
        
        %by identity that is statistically significant
        %first check if either a single ID is significant or all IDs are
        %significant, then run through that ID or all the IDs.
        if nnz(nnz(nback.(chNum{cc}).(conditionName{8}).emotionTasksigclust))>0 || nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{8})))>0
            if nnz(nnz(nback.(chNum{cc}).(conditionName{8}).emotionTasksigclust))>0
                AllImages = 1;
                for ii = 1:size(nback.(chNum{cc}).(conditionName{8}).emotionTaskcentroid,1)
                    %check the centroid is in the high gamma range in the
                    %region after image presentation
                    cent = nback.(chNum{cc}).(conditionName{8}).emotionTaskcentroid(ii,:);
                    centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                    normS1 = normalize(nback.(chNum{cc}).(conditionName{8}).emotionTaskMean,2);
                    if centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                        bData = emotionTaskLFP.byemotion.(chNum{cc}).image.bandPassed.(bandNames{5}){idx2};
                        sData = emotionTaskLFP.byemotion.(chNum{cc}).image.specD{idx2};
                        sData = normalize(sData,2);
                        allVsingle = 0;
                    end
                end
            elseif nnz(nnz(nback.(chNum{cc}).(conditionName{nn}).(resultName{8})))>0
                AllImages = 0;
                for ii = 1:size(nback.(chNum{cc}).(conditionName{nn}).(resultName{9}),1)
                    %check the centroid is in the high gamma range in the
                    %region after image presentation
                    cent = nback.(chNum{cc}).(conditionName{nn}).(resultName{9})(ii,:);
                    centA(1) = tt(round(cent(1))); centA(2) = ff(round(cent(2)));
                    normS1 = normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{5}),2);
                    %check that it's between the frequencies desired and is a
                    %positive deflection, then go trial by trial to get trial
                    %specific statistics.
                    if centA(2)>=freqMinMax(1) && centA(2)<=freqMinMax(2) && centA(1) >= timeMinMax(1) && centA(1) <= timeMinMax(2) && normS1(round(cent(2)),round(cent(1)))>0
                        bData = emotionTaskLFP.byemotion.(chNum{cc}).image.bandPassed.(bandNames{5}){idx2};
                        sData = emotionTaskLFP.byemotion.(chNum{cc}).image.specD{idx2};
                        sData = normalize(sData,2);
                        allVsingle = 1;

                    end
                end
            end
            %% this is for plotting the bandpassed against the spec. right now they aren't lining up that well, but i moved on to cluster stats instead
            %                     meanbData = mean(bData,1);
            %                     meanbDataS = meanbData.^2;
            %                     bDataS = bData.^2;
            %                     figure; plot(bTT,normalize(meanbDataS), 'LineWidth', 3); hold on; plot(bTT,normalize(bDataS,2))
            %                     figure; imagesc(tt,ff, normalize(nback.(chNum{cc}).(conditionName{nn}).(resultName{1}),2)); axis xy
            %                     hold on; plot(centA(1), centA(2), '*b');
            %%
            if ~isempty(bData)
                for jj = 1:size(bData,1)
                    %%check if there is a cluster on each trial and record descriptive info on it
                    sDataTemp = sData(:,:,jj); %take the normalized data
                    mask = sData(:,:,jj)>sdThreshold;
                    clustP=bwconncomp(mask,8);
                    clRPos=regionprops(clustP, 'all'); %get the region properties
                    cl_aRPos=[clRPos.Area];
                    cl_keepPos=find(cl_aRPos>100); %only keep reasonably large ones
                    trTrue = 0;
                    centKeep = []; arKeep = []; BBTemp = []; BB = [];
                    for kk=1:length(cl_keepPos)
                        centr = clRPos(cl_keepPos(kk)).Centroid;
                        centrR(1) = tt(round(centr(1))); centrR(2) = ff(round(centr(2)));
                        if centrR(2)>=freqMinMax(1) && centrR(2)<=freqMinMax(2) && centrR(1) >= timeMinMax(1) && centrR(1) <= timeMinMax(2)
                            trTrue = 1;
                            centKeep(kk,:) = centrR;
                            arKeep(kk,:) = sum(sDataTemp(clustP.PixelIdxList{cl_keepPos(kk)})); %add up the total cluster of stds
                            BBTemp(kk,:) = clRPos(cl_keepPos(kk)).BoundingBox;
                            %convert the bounding box to actual values
                            %of time and frequency
                            BB(kk,1) =  tt(round(BBTemp(kk,1)));
                            BB(kk,3) = BB(kk,1) + ((tt(2)-tt(1))*BBTemp(kk,3));
                            BB(kk,2) = ff(round(BBTemp(kk,2)));
                            BB(kk,4) = BB(kk,2) + ((ff(2)-ff(1))*BBTemp(kk,4));
                        end
                    end
                    if size(arKeep,1) > 1 && trTrue == 1
                        [mx I] = max(arKeep);
                        ByTrialCentroid(jj,:) = centKeep(I,:);
                        ByTrialArea(jj,:) = arKeep(I,:);
                        ByTrialBoundingBoxTimeRange(jj,:) = [BB(I,1) BB(I,3)];
                        ByTrialBoundingBoxFreqRange(jj,:) = [BB(I,2) BB(I,4)];
                    elseif trTrue == 1
                        ByTrialCentroid(jj,:) = centKeep(1,:);
                        ByTrialArea(jj,:) = arKeep(1,:);
                        ByTrialBoundingBoxTimeRange(jj,:) = [BB(1,1) BB(1,3)];
                        ByTrialBoundingBoxFreqRange(jj,:) = [BB(1,2) BB(1,4)];
                    elseif trTrue == 0
                        ByTrialCentroid(jj,:) = [NaN NaN];
                        ByTrialArea(jj,:) = [NaN];
                        ByTrialBoundingBoxTimeRange(jj,:) = [NaN NaN];
                        ByTrialBoundingBoxFreqRange(jj,:) = [NaN NaN];
                    end
                    RecordingLocation{jj,1} = chName{cc};
                    ChannelNumber{jj,1} = chNum{cc};
                    PatientName{jj,1} =  patientName;
                    TrialType{jj,1} = 'emotionTask';
                    AllImagesSignificant(jj,1) = AllImages; %if the summary of all has the cluster, then flag it.
                    TrialNumber{jj,1} = jj;
                    TimeMinMax(jj,:) = timeMinMax;
                    FreqMinMax(jj,:) = freqMinMax;
                    ClusterCenter(jj,:) = centA;
                    if allVsingle == 0
                        TstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{8}).emotionTasktstatSum(ii,1); %if it's gamma, grab that tstat for the All
                    elseif allVsingle == 1
                        TstatCluster(jj,1) = nback.(chNum{cc}).(conditionName{nn}).(resultName{10})(ii,1); %if it's gamma, grab that tstat
                    end
                    ImageType{jj,1} = (conditionName{nn});
                    [MaxValue(jj,1), pkIndex] = max(bData(jj,tMinBand:tMaxBand).^2);
                    TimeofMax(jj,1) = (pkIndex + tMinBand)/1000; %get the peak time of the filtered and adjust to ms
                    if length(emotionTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2}) < jj
                        CorrectResponse(jj,1) = 0;
                        ResponseTime(jj,1) = mean(emotionTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2});
                    else
                        CorrectResponse(jj,1) = emotionTaskLFP.byemotion.(chNum{cc}).correctTrial{idx2}(jj);
                        ResponseTime(jj,1) = emotionTaskLFP.byemotion.(chNum{cc}).responseTimesInSec{idx2}(jj);

                    end
                end
                  T1 = table(PatientName, RecordingLocation, ChannelNumber, TrialType, AllImagesSignificant, ImageType, TrialNumber, TimeMinMax, FreqMinMax,  ClusterCenter,...
                    TstatCluster, ByTrialCentroid, ByTrialArea, ByTrialBoundingBoxTimeRange, ByTrialBoundingBoxFreqRange, MaxValue, TimeofMax,...
                    CorrectResponse, ResponseTime);
            end
        end
        %add each trial necessary
        T2 = [T2; T1];
        idx2 = idx2+1;
    end

end

summaryStatsSigTrials = T2;


end