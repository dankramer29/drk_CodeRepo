%% REACTION TIMES AND CORRECT VS INCORRECT
%%%%%
%correct vs incorrect
% REMEMBER TO PASTE BIPALLPATIENTSBEHAVIORAL INSTEAD OF THE USUAL
%use MWallForLoading33
clmns = MWallForLoading3.Properties.VariableNames;

nmsort = {'S2'
'S5'
'S9'
'S13'
'S16'
'S18'
'S19'
'S21'
'S22'
'S23'
'S24'};
%nmsortt = nmsort(sI); %do this after you get sI and can reinsert the
%names.

colorTempTest = {'#90eaeaff', '#f49ac0ff', '#58d4caff', '#ffb351ff', '#439f98ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = [C(1,:); C(2,:); C(3,:); C(4,:)];
colorTemp2 = [C(3,:); C(4,:); C(5,:)];

ptNameT = MWallForLoading3.PatientName;
ptName = unique(ptNameT);
ptName(isnan(ptName))=[];

%

clmnNum = 6; %correct response

%pull the correct trials for the total
EmotTaskTot = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'emotionTask'" ); 
IdTaskTot = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'identityTask'");
corEmT = nnz(EmotTaskTot);
corIdT = nnz(IdTaskTot);
perCorEmIdT(1,1) = corEmT/length(EmotTaskTot);
perCorEmIdT(1,2) = corIdT/length(IdTaskTot);


for ii = 1:length(ptName)
    EmotTask = []; IdTask = [];
    %collect emotion task and id task by patient
    EmotTask = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'emotionTask'" &  MWallForLoading3.PatientName == ptName(ii));
    IdTask = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'identityTask'" &  MWallForLoading3.PatientName == ptName(ii));
    corEm = nnz(EmotTask);
    corId = nnz(IdTask);
    perCorEmId(ii,1) = corEm/length(EmotTask); %this is in numerical order so MW2 is first
    perCorEmId(ii,2) = corId/length(IdTask);
end

%sort by lowest to highest as mean
mn1 = mean(perCorEmId,2); %get the means
[sorted, sI] = sort(mn1); %sort the means and get the index
perCorEmId =perCorEmId(sI,:); 

perCorEmIdTall = vertcat(perCorEmIdT,perCorEmId); 

figure

b=bar(perCorEmIdTall*100);

b(1).FaceColor = colorTemp(1,:);
b(2).FaceColor = colorTemp(2,:);

Gc = gca;
%Gc.XLim = [0.5 (width(xxxT)/2)+0.5];
Gc.FontSize = 24;
Gc.YLabel.String = 'Percent Correct';
Gc.YLabel.FontSize = 28;
%this is resorted as per above, it could be different, at which point just
nmsortt = nmsort(sI);
nmsorttF = vertcat('All', nmsortt);
Gc.XTickLabel = nmsorttF;
Gc.XTickLabelRotation = 45;
Gc.Title.FontSize = 28;
Gc.Title.String = 'Percent Correct By Participant'; %gives a supertitle
legend('Emotion Task', 'Identity Task')

%% REACTION TIMES
colorTempTest = {'#90eaeaff', '#f49ac0ff', '#58d4caff', '#f3de15ff', '#439f98ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = [C(1,:); C(2,:); C(3,:); C(4,:)];
colorTemp2 = [C(3,:); C(4,:); C(5,:)];

clmnNum = 7; %reaction times
%pull the correct trials for the total
for ii = 1:length(ptName)
xxxTt{ii}(:,1) = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'emotionTask'"  &  MWallForLoading3.PatientName == ptName(ii)); 
xxxTt{ii}(:,2) = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'identityTask'"  &  MWallForLoading3.PatientName == ptName(ii));
xxxTt{ii}(xxxTt{ii} <= 0.1) = NaN;
xxxTt{ii}(xxxTt{ii} >= 5.9) = NaN;
mn1(ii,1) = nanmean(nanmean(xxxTt{ii},1)); %get the mean rt
end

[sorted, sI] = sort(mn1); %sort the means and get the index
xxxT{1} = [];
for ii = 1:length(sI)    
    xxxT{ii+1} = xxxTt{sI(ii)};
end
xxxT{1}(:,1) = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'emotionTask'" ); 
xxxT{1}(:,2) = MWallForLoading3.(clmns{clmnNum})(MWallForLoading3.TrialType == "'identityTask'" );
xxxT{1}(xxxT{1} <= 0.1) = NaN;
xxxT{1}(xxxT{1} >= 5.9) = NaN;

FigType = 'SwarmTwoColumn';
spaceBetData = 0.2; %space between the paired data
f = figure('Name', 'Reaction Times');
%f.WindowState = 'maximized';
title('Reaction Times');

idx = 1;
for cci = 1:width(xxxT)

    hold on

    xDataAt = xxxT{cci}(:,1);
    xDataA = xDataAt(~isnan(xDataAt));
    xDataBt = xxxT{cci}(:,2);
    xDataB = xDataBt(~isnan(xDataBt));


    yDataA = (ones(size(xDataA))*idx) - spaceBetData;
    yDataB = (ones(size(xDataB))*idx) + spaceBetData;

    sA = scatter(yDataA,xDataA,140,colorTemp2(1,:),'filled');
    sA.XJitter = "density";
    sA.XJitterWidth = 0.2;
    sA.MarkerFaceAlpha = 0.5;
    sA.MarkerEdgeAlpha = 0.5;

    hold on

    sB = scatter(yDataB,xDataB,140,colorTemp2(2,:),'filled');
    sB.XJitter = "density";
    sB.XJitterWidth = 0.2;
    sB.MarkerFaceAlpha = 0.5;
    sB.MarkerEdgeAlpha = 0.5;

    tmpMedianA = median(xDataA);
    sAM = scatter(yDataA(1),tmpMedianA,300,colorTemp2(1,:),'filled');
    sAM.MarkerEdgeColor = 'k';
    sAM.LineWidth = 2;

    tmpMedianB = median(xDataB);
    sBM = scatter(yDataB(1),tmpMedianB,300,colorTemp2(2,:),'filled');
    sBM.MarkerEdgeColor = 'k';
    sBM.LineWidth = 2;

    line([yDataA(1) yDataB(1)],[tmpMedianA tmpMedianB],'Color',colorTemp2(3,:), 'LineWidth', 3)
    idx = idx +1;

end

Gc = gca;
%Gc.XLim = [0.5 (width(xxxT))+0.5];
Gc.FontSize = 20;
Gc.YLabel.String = 'Reaction Time (S)';
Gc.YLabel.FontSize = 24;
Gc.XTick = [1:width(xxxT)];
nmsortt = nmsort(sI);
nmsorttF = vertcat('All', nmsortt);
Gc.XTickLabel = nmsorttF;
Gc.XTickLabelRotation = 45;
Gc.Title.FontSize = 28;
    Gc.View =  [90 90];
legend('Emotion Task', 'Identity Task');


