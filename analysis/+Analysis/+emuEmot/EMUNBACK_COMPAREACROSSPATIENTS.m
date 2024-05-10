%% EMUNBACK COMPARE ACROSS PATIENTS
%To pull in:
%Cut and paste it into the file MWallForLoading, then import as a table to
%have it all as a table.

% RUN THE RANKSUM ON RESPONSE TIME FOR CORRECT VS INCORRECT, FIRST VS
% SECOND TRIAL, AND EMOTION TASK VS THE IDENTITY TASK. ALSO RUN KRUSKALL WALLIS? FOR EACH ID AND
% EMOTION FOR RESPONSE TASK (I.E. EMOTION 1 VS 2 VS 3 VS ID1 ETC). THEN LOOK IF CORRECT VS INCORRECT WAS DIFFERENT BETWEEN EMOTION TASK VS ID TASK
% (IF NOT NO NEED TO LOOK WITHIN THE EMOTIONS/IDS) WITH CHI2. REPORT SUMMARY ON EACH PATIENT CORRECT VS
% INCORRECT AND MEAN RESPONSE TIMES BUT NO NEED TO RUN STATS.

%THEN RUN RANKSUM ON CENTROID, RANGE OF FREQ, RANGE OF
%TIME FOR CLUSTER (MEANING WIDTH AND HEIGHT OF THE BOUNDING BOX AROUND THE CLUSTER FOR
%EACH TRIAL ON SPECTROGRAM) BASED ON BRAIN AREA. BASED ON CORRECT
%INCORRECT. AND BASED ON RESPONSE TIME.

% Then i think i'll do figures of the centroids and bounding boxes by brain
% areas, by response time, and by correct vs incorrect trials. If none are
% interesting, probably still do it anyway? Probably makes sense to do a
% histogram for each area involved. Oh and do each separately by task type.

% RUN CLUSTER SIZE AND MAYBE CENTROID BASED ON CORRECT VS INCORRECT AND
% RESPONSE TIME BOUNDING BOX?



%% run stats on all trials
%% first run overall stats
% THIS IS FAR EASIER TO JUST SET UP XX IN EXCEL THEN CHANGE THE NAME BELOW
% AND INSERT THE XXS BY CUT AND PASTE
% WAY TO DO THIS: SORT BY CORRECT VS INCORRECT (OR WHATEVER) THEN CUT THE
% RESPONSE TIMES OF THE CORRECT, AND THE RESPONSE TIMES OF THE INCORRECT.
% CHANGE THE VARIABLE NAMES BELOW. DO THE FOLLOWING:

%% Figure 2 bar graph
%IN THEORY THIS WILL WORK, FOUND IT EASIER IN EXCEL
subj = ['Amygdala Emotion', 'Amygdala Identity', 'Anterior Hippocampus Emotion', 'Anterior Hippocampus Identity', 'Posterior Hippocampus Emotion', 'Posterior Hippocampus Identity'];
testS = ['Amygdala Emotion', 'Amygdala Identity'];
totalCounts = [11	2	1;	7	3	1;	13	2	1;	14	1	1;	3	6	3;	9	0	3];
hH= bar(totalCounts, 'stacked');

%%

%%




%Response Time Emotion Task v Identity Task
%Response Time Correct v Incorrect
%
AllTrialStats = [];

TstTemp = [];
xx=[];
yy=[];
nameTable = {'Emotion Task v Identity Task'};
nameXX = {'xx is Emotion Task'};
nameYY = {'yy is Identity'};
testDone = {'ranksum'};
[pvalue, h, ci] = ranksum(xx, yy);
zval = ci.zval;
ranksumNumerical = ci.ranksum;
meanXX = nanmean(xx);
meanYY = nanmean(yy);
stdXX = nanstd(xx);
stdYY = nanstd(yy);
TstTemp = table(nameTable, nameXX, nameYY, meanXX, stdXX, meanYY, stdYY, pvalue, h, zval, ranksumNumerical, testDone);
%REMEMBER TO PLACE THESE INTO AN EXCEL
%% organize the data for plotting.
xxx = xx;
xxx(1:length(yy),2) = yy;
xxx(xxx(:,2) == 0,2) = NaN;

%% a violin plot option
%
[Ax, L] = violin(xxx, 'xlabel', {'Emotion Task', 'Identity Task'}, 'facealpha', 1, 'facecolor', [1 0.549 0; 0.12 0.85 0.98],  'mc', 'b', 'medc', '');
Ax.LineWidth = 2;
Ax.EdgeColor = 'k';
Gc = gca;
Gc.FontSize = 22;
L.FontSize = 22;
L.LineWidth = 4;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sig Cluster stats FOR STRUCTURES AND SIDES, NOT BROKEN INTO TASKS (SO AMYGDALA VS HIPPOCAMPUS, NOT EMOTION VS IDENTITY)
%Group stats

%Cut and paste it into the file MWallForLoading, then import as a table to
%have it all as a table.

%Run:
%   First look at ones when you are looking at the all trial summary stats
%       centroid by time
%       centroid by frequency
%       bounding box by time (plot this? maybe take the length and height?)
%       bounding box by frequency(plot this?)
%   Second look at the by trial summary stats
%   by structure
%     centroid by time
%     cluster centroid by frequency
%     centroid

colorTempTest = {'#fee327', '#fdca54', '#f6a570', '#f1969b', '#f08ab1', '#c78dbd', '#927db6', '#5da0d7', '#00b3e1', '#50bcbf', '#65bda5', '#87bf54' };
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = [C(12,:); C(9,:); C(7,:)];
colorTempLR = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];


clmns = MWallForLoading.Properties.VariableNames;

clmnNum = 16; %pick the column number here.
nameTable = {'Cluster Centroid By Time '};
varTested = {'Time (S)'};
testDone = {'Kruskall Wallis'};

% clmnNum = 15; %pick the column number here.
% nameTable = {'Tstat total '};
% varTested = {'tstat sum'};
% testDone = {'Kruskall Wallis'};


xx = []; %load with stats of whatever category (say Amygdala centroid time)
yy = []; %load with stats of whatever is the second category (say Hippo)
zz = []; %load with stats of the third category
Ramy = [];
Lamy= [];
RAhip= [];
LAhip= [];
RPhip= [];
LPhip= [];

%pull out the areas you want

idxX = 1; idxY = 1; idxZ = 1;
%
%delete the category and then tab through to the one you want below
Ramy = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" ); 
Lamy = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'");
xx = vertcat(Ramy, Lamy);
RAhip = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'"); 
LAhip =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'");
yy = vertcat(RAhip, LAhip);
RPhip = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'"); 
LPhip =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'");
zz = vertcat(RPhip, LPhip);

for ii = 1:length(xx); nameXX{ii,1} = 'Amygdala'; end
for ii = 1:length(yy); nameYY{ii,1} = 'Anterior Hippocampus'; end
for ii = 1:length(zz); nameZZ{ii,1} = 'Posterior Hippocampus'; end


for ii = 1:length(Ramy); nameRamy{ii,1} = 'Right Amygdala'; end
for ii = 1:length(RAhip); nameRAhip{ii,1} = 'Right Anterior Hippocampus'; end
for ii = 1:length(RPhip); nameRPhip{ii,1} = 'Right Posterior Hippocampus'; end
for ii = 1:length(Lamy); nameLamy{ii,1} = 'Left Amygdala'; end
for ii = 1:length(LAhip); nameLAhip{ii,1} = 'Left Anterior Hippocampus'; end
for ii = 1:length(LPhip); nameLPhip{ii,1} = 'Left Posterior Hippocampus'; end





%no inputs needed from here below (unless more variables needed, add
%accordingly)
xxx= vertcat(xx,yy,zz);
xxxN = vertcat(nameXX,nameYY, nameZZ);
figure
[pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
multC = multcompare(stats);
meanXX = nanmean(xx);
meanYY = nanmean(yy);
meanZZ = nanmean(zz);
medianXX = nanmedian(xx);
medianYY = nanmedian(yy);
medianZZ = nanmedian(zz);
stdXX = nanstd(xx);
stdYY = nanstd(yy);
stdZZ = nanstd(zz);
TstTempKW = table(nameTable, meanXX, stdXX, meanYY, stdYY, meanZZ, stdZZ, pvalue,  testDone);
tbleTemp = array2table(multC, "VariableNames", ["Category 1", "Category 2", "Lower Limit", "A-B", "Upper Limit", "P-value"]);
figure
title(nameTable);
wdth = 1;
x1 = ones(1,length(xx));
x2 = 2*wdth*ones(1,length(yy));
x3 = 3*wdth*ones(1,length(zz));
S1 = swarmchart(x1,xx,  5,colorTemp(1,:), 'filled');
hold on
S2 = swarmchart(x2,yy,5, colorTemp(2,:), 'filled');
S3 = swarmchart(x3,zz,5, colorTemp(3,:), 'filled');
p1=plot([0.75,0.75+(wdth/2)],[meanXX,meanXX],'LineWidth',4, 'Color', colorTemp(1,:));
p2=plot([0.75+1,0.75+1+(wdth/2)],[meanYY,meanYY],'LineWidth',4, 'Color',colorTemp(2,:));
p3=plot([0.75+2,0.75+2+(wdth/2)],[meanZZ,meanZZ],'LineWidth',4, 'Color',colorTemp(3,:));
%legend([p1 p2 p3],{'Mean 1', 'Mean 2', 'Mean 3'})
ax=gca;
ax.XTick = [1,2,3];
% ax.YLim = [0:1.5];
% ax.YTick = [0:0.2:1.50];
ax.XTickLabel = {nameXX{1}, nameYY{1}, nameZZ{1}};
ax.FontSize = 13;
ax.FontWeight = 'bold';
ylabel(varTested, 'FontSize', 18, 'FontWeight','bold')
open tbleTemp

xxx=[];
xxxN=[];

%no inputs needed from here below (unless more variables needed, add
%accordingly)
xxx= vertcat(Ramy,Lamy,RAhip, LAhip, RPhip, LPhip);
xxxN = vertcat(nameRamy,nameLamy, nameRAhip, nameLAhip, nameRPhip, nameLPhip);
figure
[pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
multC = multcompare(stats);
meanXXR = nanmean(Ramy);
meanYYR = nanmean(RAhip);
meanZZR = nanmean(RPhip);
meanXXL = nanmean(Lamy);
meanYYL = nanmean(LAhip);
meanZZL = nanmean(LPhip);
medianXXR = nanmedian(RAhip);
medianYYR = nanmedian(RAhip);
medianZZR = nanmedian(RPhip);
medianXXL = nanmedian(LAhip);
medianYYL = nanmedian(LAhip);
medianZZL = nanmedian(LPhip);
stdXXR = nanstd(Ramy);
stdYYR = nanstd(RAhip);
stdZZR = nanstd(RPhip);
stdXXL = nanstd(Lamy);
stdYYL = nanstd(LAhip);
stdZZL = nanstd(LPhip);
TstTempKWLR = table(nameTable, meanXXR, stdXXR, meanXXL, stdXXL, meanYYR, stdYYR,  meanYYL, stdYYL, meanZZR, stdZZR, meanZZL, stdZZL, pvalue,  testDone);
tbleTempLR = array2table(multC, "VariableNames", ["Category 1", "Category 2", "Lower Limit", "A-B", "Upper Limit", "P-value"]);
figure
title(nameTable);
wdth = 1;
x1 = ones(1,length(Ramy));
x2 = 2*wdth*ones(1,length(Lamy));
x3 = 3*wdth*ones(1,length(RAhip));
x4 = 4*wdth*ones(1,length(LAhip));
x5 = 5*wdth*ones(1,length(RPhip));
x6 = 6*wdth*ones(1,length(LPhip));
swarmchart(x1,Ramy,5, colorTempLR(1,:), 'filled');
hold on
swarmchart(x2,Lamy, 5, colorTempLR(2,:), 'filled');
swarmchart(x3,RAhip,5, colorTempLR(3,:), 'filled');
swarmchart(x4,LAhip,5, colorTempLR(4,:), 'filled');
swarmchart(x5,RPhip,5, colorTempLR(5,:), 'filled');
swarmchart(x6,LPhip,5, colorTempLR(6,:), 'filled');
idx = 1;
p1=plot([0.75,0.75+(wdth/2)],[meanXXR,meanXXR],'LineWidth',4, 'Color',colorTempLR(1,:));
p2=plot([0.75+idx,0.75+idx+(wdth/2)],[meanXXL,meanXXL],'LineWidth',4, 'Color',colorTempLR(2,:));
idx=idx+1;
p3=plot([0.75+idx,0.75+idx+(wdth/2)],[meanYYR,meanYYR],'LineWidth',4, 'Color',colorTempLR(3,:));
idx=idx+1;
p4=plot([0.75+idx,0.75+idx+(wdth/2)],[meanYYL,meanYYL],'LineWidth',4, 'Color',colorTempLR(4,:));
idx=idx+1;
p5=plot([0.75+idx,0.75+idx+(wdth/2)],[meanZZR,meanZZR],'LineWidth',4, 'Color',colorTempLR(5,:));
idx=idx+1;
p6=plot([0.75+idx,0.75+idx+(wdth/2)],[meanZZL,meanZZL],'LineWidth',4, 'Color',colorTempLR(6,:));
%legend([p1 p2 p3],{'Mean 1', 'Mean 2', 'Mean 3'})
ax=gca;
ax.XTick = [1,2,3,4,5,6];
% ax.YLim = [0:1.5];
% ax.YTick = [0:0.2:1.50];
ax.XTickLabel = {nameRamy{1}, nameLamy{1}, nameRAhip{1}, nameLAhip{1}, nameRPhip{1}, nameLPhip{1}};
ax.FontSize = 13;
ax.FontWeight = 'bold';
ylabel(varTested, 'FontSize', 18, 'FontWeight','bold')
open tbleTempLR

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Group stats CLUSTER FOR MEAN STATS EMOTION VS IDENTITY

%Cut and paste it into the file MWallForLoading, then import as a table to
%have it all as a table.

%Run:
%   First look at ones when you are looking at the all trial summary stats
%       centroid by time
%       centroid by frequency
%       bounding box by time (plot this? maybe take the length and height?)
%       bounding box by frequency(plot this?)
%   Second look at the by trial summary stats
%   by structure
%     centroid by time
%     cluster centroid by frequency
%     centroid
clearvars -except MWallForLoading
yLimChange = 0;

%darker
% colorTempTest = {'#1A1334', '#26294A', '#055459', '#077353', '#14C285', '#ABD96D', '#FCBF54', '#EE6C3B', '#EC0E47', '#A02C5D', '#710461', '#022B7A' };
% for ii = 1:length(colorTempTest)
%     str = colorTempTest{ii};
%     C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
% end
% colorTemp = [C(4,:); C(3,:); C(2,:); C(12,:); C(11, :); C(10,:)];


% %lighter
% colorTempTest = {'#fee327', '#fdca54', '#f6a570', '#f1969b', '#f08ab1', '#c78dbd', '#927db6', '#5da0d7', '#00b3e1', '#50bcbf', '#65bda5', '#87bf54' };
% for ii = 1:length(colorTempTest)
%     str = colorTempTest{ii};
%     C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
% end
% colorTemp = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];
% 
% colorTempLR = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];

%pastel and dark
% clear colorTempTest
% clear C
% colorTempTest = {'#38761dff', '#93c47dff',  '#6d9eebff', '#c9daf8ff', '#8e7cc3ff', '#d9d2e9ff'};
% for ii = 1:length(colorTempTest)
%     str = colorTempTest{ii};
%     C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
% end
% colorTemp = C;


clear colorTempTest
clear C
colorTempTest = {'#38761dff', '#93c47dff', '#6d9eebff', '#c9daf8ff',  '#8e7cc3ff', '#d9d2e9ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = C;

clmns = MWallForLoading.Properties.VariableNames;


% Time:
% clmnNum = 13; %pick the column number here.
% nameTable = {'Cluster Centroid By Time '};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = true;

% %This one is probably not helpful:
% clmnNum = 14; %pick the column number here.
% nameTable = {'Cluster Centroid By Frequency '};
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true;
% % 
clmnNum = 15; %pick the column number here.
nameTable = {'Tstat total '};
varTested = {'Tstat sum'};
testDone = {'Kruskall Wallis'};
timeFig = 0;
meanCluster = true;

% clmnNum = 16; %pick the column number here.
% nameTable = {'Cluster Centroid By Trial '};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = false; %so run it across the clusters

% clmnNum = 17; %pick the column number here.
% nameTable = {'Cluster Centroid By Trial '};
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters

% clmnNum = 18; %pick the column number here.
% nameTable = {'Cluster Area By Trial '}; %Literally the area of the box
% varTested = {'Area A.U.'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters

% clmnNum = 23; %pick the column number here.
% nameTable = {'Peak Power in High Gamma ( '}; %The max of the bandpassed
% data 50-150 (I THINK!) in the HG band
% varTested = {'Power A.U.'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters

% clmnNum = 24; %pick the column number here.
% nameTable = {'Time of High Gamma Power Max '}; %time of the peak band
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = false; %so run it across the clusters

%pull out the areas you want

idxX = 1; idxY = 1; idxZ = 1;
%
RamyEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" & MWallForLoading.TrialType == "'emotionTask'"); 
LamyEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'" & MWallForLoading.TrialType == "'emotionTask'");
RAhipEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'"); 
LAhipEm =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'");
RPhipEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'"); 
LPhipEm =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'");

RamyId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" & MWallForLoading.TrialType == "'identityTask'"); 
LamyId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'" & MWallForLoading.TrialType == "'identityTask'");
RAhipId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'"); 
LAhipId =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'");
RPhipId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'"); 
LPhipId =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'");
if meanCluster
    RamyEm = unique(RamyEm);
    LamyEm = unique(LamyEm);
    RAhipEm = unique(RAhipEm);
    LAhipEm = unique(LAhipEm);
    RPhipEm = unique(RPhipEm);
    LPhipEm = unique(LPhipEm);
    RamyId = unique(RamyId);
    LamyId = unique(LamyId);
    RAhipId = unique(RAhipId);
    LAhipId = unique(LAhipId);
    RPhipId = unique(RPhipId);
    LPhipId = unique(LPhipId);
end

xxEm = vertcat(RamyEm, LamyEm);
yyEm = vertcat(RAhipEm, LAhipEm);
zzEm = vertcat(RPhipEm, LPhipEm);
xxId = vertcat(RamyId, LamyId);
yyId = vertcat(RAhipId, LAhipId);
zzId = vertcat(RPhipId, LPhipId);

for ii = 1:length(xxEm); nameXXEm{ii,1} = 'Amygdala Emotion'; end
for ii = 1:length(yyEm); nameYYEm{ii,1} = 'Anterior Hippocampus Emotion'; end
for ii = 1:length(zzEm); nameZZEm{ii,1} = 'Posterior Hippocampus Emotion'; end


for ii = 1:length(RamyEm); nameRamyEm{ii,1} = 'Right Amygdala Emotion'; end
for ii = 1:length(RAhipEm); nameRAhipEm{ii,1} = 'Right Anterior Hippocampus Emotion'; end
for ii = 1:length(RPhipEm); nameRPhipEm{ii,1} = 'Right Posterior Hippocampus Emotion'; end
for ii = 1:length(LamyEm); nameLamyEm{ii,1} = 'Left Amygdala Emotion'; end
for ii = 1:length(LAhipEm); nameLAhipEm{ii,1} = 'Left Anterior Hippocampus Emotion'; end
for ii = 1:length(LPhipEm); nameLPhipEm{ii,1} = 'Left Posterior Hippocampus Emotion'; end

for ii = 1:length(xxId); nameXXId{ii,1} = 'Amygdala Identity'; end
for ii = 1:length(yyId); nameYYId{ii,1} = 'Anterior Hippocampus Identity'; end
for ii = 1:length(zzId); nameZZId{ii,1} = 'Posterior Hippocampus Identity'; end

for ii = 1:length(RamyId); nameRamyId{ii,1} = 'Right Amygdala Identity'; end
for ii = 1:length(RAhipId); nameRAhipId{ii,1} = 'Right Anterior Hippocampus Identity'; end
for ii = 1:length(RPhipId); nameRPhipId{ii,1} = 'Right Posterior Hippocampus Identity'; end
for ii = 1:length(LamyId); nameLamyId{ii,1} = 'Left Amygdala Identity'; end
for ii = 1:length(LAhipId); nameLAhipId{ii,1} = 'Left Anterior Hippocampus Identity'; end
for ii = 1:length(LPhipId); nameLPhipId{ii,1} = 'Left Posterior Hippocampus Identity'; end


%no inputs needed from here below (unless more variables needed, add
%accordingly)
%data(:,1:eacharea, 'groups', groupIdx(each number = a row and associates it with a time period))
xxx= vertcat(xxEm,yyEm,zzEm, xxId,yyId,zzId);
xxxN = vertcat(nameXXEm,nameYYEm, nameZZEm, nameXXId,nameYYId, nameZZId);
figure
[pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
multC = multcompare(stats);
meanXXEm = nanmean(xxEm);
meanYYEm = nanmean(yyEm);
meanZZEm = nanmean(zzEm);
medianXXEm = nanmedian(xxEm);
medianYYEm = nanmedian(yyEm);
medianZZEm = nanmedian(zzEm);
stdXXEm = nanstd(xxEm);
stdYYEm = nanstd(yyEm);
stdZZEm = nanstd(zzEm);
meanXXId = nanmean(xxId);
meanYYId = nanmean(yyId);
meanZZId = nanmean(zzId);
medianXXId = nanmedian(xxId);
medianYYId = nanmedian(yyId);
medianZZId = nanmedian(zzId);
stdXXId = nanstd(xxId);
stdYYId = nanstd(yyId);
stdZZId = nanstd(zzId);
TstTempKW = table(nameTable, meanXXEm, stdXXEm, meanXXId, stdXXId, meanYYEm, stdYYEm,  meanYYId, stdYYId, meanZZEm, stdZZEm, meanZZId, stdZZId, pvalue, testDone);
tbleTemp = array2table(multC, "VariableNames", ["Category 1", "Category 2", "Lower Limit", "A-B", "Upper Limit", "P-value"]);
figure('Name', nameTable{:});
title(nameTable); 
xxxT{1} = xxEm;
xxxT{2} = xxId;
xxxT{3} = yyEm;
xxxT{4} = yyId;
xxxT{5} = zzEm;
xxxT{6} = zzId;
h = daviolinplot(xxxT,'violin', 'full', 'colors', colorTemp, 'outlier', 0, 'violinalpha', 0.75, 'xtlabels', {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})});
for ii = 1:length(h.ds)
h.ds(ii).LineWidth = 2;
h.ds(ii).EdgeColor = 'k';
end
Gc = gca;
Gc.FontSize = 20;
Gc.YLabel.String = varTested;
Gc.YLabel.FontSize = 24;
%Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
Gc.XTickLabelRotation = 45;
Gc.Title.String = (nameTable{:}); %gives a supertitle
Gc.Title.FontSize = 28;
if yLimChange
Gc.YLim = [-1 3];
end
if timeFig  
Gc.View =  [90 90];
Gc.Position = [0.1365    0.1    0.7685    0.8];
end


open tbleTemp

xxx=[];
xxxN=[];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% for doing the groups of say time (meaning do like the bounding box and centroid
% I THINK THIS IS GOING TO BE TOO CONFUSING. IT DOESN'T SPLIT IT UP QUITE
% THE WAY I WANT IT. PROBABLY EASIER TO DO SUBPLOTS. CURRENTLY ABANDONED.
% ALSO ONLY WOULD WORK FOR THE BOUNDING BOX BY TRIAL AND THAT'S MOSTLY
% DUMB.
%Cut and paste it into the file MWallForLoading, then import as a table to
%have it all as a table.

%Run:
%   First look at ones when you are looking at the all trial summary stats
%       centroid by time
%       centroid by frequency
%       bounding box by time (plot this? maybe take the length and height?)
%       bounding box by frequency(plot this?)
%   Second look at the by trial summary stats
%   by structure
%     centroid by time
%     cluster centroid by frequency
%     centroid
clearvars -except MWallForLoading


%darker
% colorTempTest = {'#1A1334', '#26294A', '#055459', '#077353', '#14C285', '#ABD96D', '#FCBF54', '#EE6C3B', '#EC0E47', '#A02C5D', '#710461', '#022B7A' };
% for ii = 1:length(colorTempTest)
%     str = colorTempTest{ii};
%     C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
% end
% colorTemp = [C(4,:); C(3,:); C(2,:); C(12,:); C(11, :); C(10,:)];


% %lighter
colorTempTest = {'#fee327', '#fdca54', '#f6a570', '#f1969b', '#f08ab1', '#c78dbd', '#927db6', '#5da0d7', '#00b3e1', '#50bcbf', '#65bda5', '#87bf54' };
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];

colorTempLR = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];


clmns = MWallForLoading.Properties.VariableNames;
meanCluster = false;

% Time:
clmnNumList = [16, 19, 20]; %pick the column number here.
nameTable = {'Cluster Centroid By Time '};
varTested = {'Time (S)'};
testDone = {'Kruskall Wallis'};
timeFig = 1;

%This one is probably not helpful:
% clmnNum = 14; %pick the column number here.
% nameTable = {'Cluster Centroid By Frequency '};
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};

% clmnNum = 15; %pick the column number here.
% nameTable = {'Tstat total '};
% varTested = {'Tstat sum'};
% testDone = {'Kruskall Wallis'};





%pull out the areas you want

idxX = 1; idxY = 1; idxZ = 1;
for ii = 1:3
clmnNum = clmnNumList(ii); %pick the column number here.
RamyEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" & MWallForLoading.TrialType == "'emotionTask'"); 
LamyEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'" & MWallForLoading.TrialType == "'emotionTask'");
RAhipEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'"); 
LAhipEm =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'");
RPhipEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'"); 
LPhipEm =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'");

RamyId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" & MWallForLoading.TrialType == "'identityTask'"); 
LamyId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'" & MWallForLoading.TrialType == "'identityTask'");
RAhipId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'"); 
LAhipId =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'");
RPhipId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'"); 
LPhipId =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'");
if meanCluster
    RamyEm(:,ii) = unique(RAhipEm);
    LamyEm(:,ii) = unique(LAhipEm);
    RAhipEm(:,ii) = unique(RAhipEm);
    LAhipEm(:,ii) = unique(LAhipEm);
    RPhipEm(:,ii) = unique(RPhipEm);
    LPhipEm(:,ii) = unique(LPhipEm);
    RamyId(:,ii) = unique(RAhipId);
    LamyId(:,ii) = unique(LAhipId);
    RAhipId(:,ii) = unique(RAhipId);
    LAhipId(:,ii) = unique(LAhipId);
    RPhipId(:,ii) = unique(RPhipId);
    LPhipId(:,ii) = unique(LPhipId);
end

xxEm(:,ii) = vertcat(RamyEm, LamyEm);
yyEm(:,ii) = vertcat(RAhipEm, LAhipEm);
zzEm(:,ii) = vertcat(RPhipEm, LPhipEm);
xxId(:,ii) = vertcat(RamyId, LamyId);
yyId(:,ii) = vertcat(RAhipId, LAhipId);
zzId(:,ii) = vertcat(RPhipId, LPhipId);
end






for ii = 1:length(xxEm); nameXXEm{ii,1} = 'Amygdala Emotion'; end

for ii = 1:length(yyEm); nameYYEm{ii,1} = 'Anterior Hippocampus Emotion'; end
for ii = 1:length(zzEm); nameZZEm{ii,1} = 'Posterior Hippocampus Emotion'; end


for ii = 1:length(RamyEm); nameRamyEm{ii,1} = 'Right Amygdala Emotion'; end
for ii = 1:length(RAhipEm); nameRAhipEm{ii,1} = 'Right Anterior Hippocampus Emotion'; end
for ii = 1:length(RPhipEm); nameRPhipEm{ii,1} = 'Right Posterior Hippocampus Emotion'; end
for ii = 1:length(LamyEm); nameLamyEm{ii,1} = 'Left Amygdala Emotion'; end
for ii = 1:length(LAhipEm); nameLAhipEm{ii,1} = 'Left Anterior Hippocampus Emotion'; end
for ii = 1:length(LPhipEm); nameLPhipEm{ii,1} = 'Left Posterior Hippocampus Emotion'; end

for ii = 1:length(xxId); nameXXId{ii,1} = 'Amygdala Identity'; end
for ii = 1:length(yyId); nameYYId{ii,1} = 'Anterior Hippocampus Identity'; end
for ii = 1:length(zzId); nameZZId{ii,1} = 'Posterior Hippocampus Identity'; end

for ii = 1:length(RamyId); nameRamyId{ii,1} = 'Right Amygdala Identity'; end
for ii = 1:length(RAhipId); nameRAhipId{ii,1} = 'Right Anterior Hippocampus Identity'; end
for ii = 1:length(RPhipId); nameRPhipId{ii,1} = 'Right Posterior Hippocampus Identity'; end
for ii = 1:length(LamyId); nameLamyId{ii,1} = 'Left Amygdala Identity'; end
for ii = 1:length(LAhipId); nameLAhipId{ii,1} = 'Left Anterior Hippocampus Identity'; end
for ii = 1:length(LPhipId); nameLPhipId{ii,1} = 'Left Posterior Hippocampus Identity'; end


%no inputs needed from here below (unless more variables needed, add
%accordingly)
%stack each area on top of each other and make the three columns the three
%times
%data(:,1:eacharea, 'groups', groupIdx(each number = a row and associates it with a time period))
xxx= vertcat(xxEm,yyEm,zzEm, xxId,yyId,zzId);
xxxN = vertcat(nameXXEm,nameYYEm, nameZZEm, nameXXId,nameYYId, nameZZId);
figure
[pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
multC = multcompare(stats);
meanXXEm = nanmean(xxEm);
meanYYEm = nanmean(yyEm);
meanZZEm = nanmean(zzEm);
medianXXEm = nanmedian(xxEm);
medianYYEm = nanmedian(yyEm);
medianZZEm = nanmedian(zzEm);
stdXXEm = nanstd(xxEm);
stdYYEm = nanstd(yyEm);
stdZZEm = nanstd(zzEm);
meanXXId = nanmean(xxId);
meanYYId = nanmean(yyId);
meanZZId = nanmean(zzId);
medianXXId = nanmedian(xxId);
medianYYId = nanmedian(yyId);
medianZZId = nanmedian(zzId);
stdXXId = nanstd(xxId);
stdYYId = nanstd(yyId);
stdZZId = nanstd(zzId);
TstTempKW = table(nameTable, meanXXEm, stdXXEm, meanXXId, stdXXId, meanYYEm, stdYYEm,  meanYYId, stdYYId, meanZZEm, stdZZEm, meanZZId, stdZZId, pvalue, testDone);
tbleTemp = array2table(multC, "VariableNames", ["Category 1", "Category 2", "Lower Limit", "A-B", "Upper Limit", "P-value"]);
figure('Name', nameTable{:});
title(nameTable); 
xxxT{1} = xxEm;
xxxT{2} = xxId;
xxxT{3} = yyEm;
xxxT{4} = yyId;
xxxT{5} = zzEm;
xxxT{6} = zzId;
h = daviolinplot(xxxT,'violin', 'groups', [1,2,3], 'full', 'colors', colorTemp, 'violinalpha', 0.75, 'xtlabels', {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})});
for ii = 1:length(h.ds)
h.ds(ii).LineWidth = 2;
h.ds(ii).EdgeColor = 'k';
end
Gc = gca;
Gc.FontSize = 18;
Gc.YLabel.String = varTested;
Gc.YLabel.FontSize = 24;
%Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
Gc.XTickLabelRotation = 45;
Gc.Title.String = (nameTable{:}); %gives a supertitle
Gc.Title.FontSize = 28;
%Gc.YLim = [0 200];
if timeFig  
Gc.View =  [90 90];
Gc.Position = [0.1365    0.1    0.7685    0.8];
end


open tbleTemp

xxx=[];
xxxN=[];

%% channels with matched significance

figure
meshgrid(1:11)


colorTempTest = {'#228E2C', '#64D413', '#0072BD', '#4DBEEE', '#7E2F8E', '#FF13A6'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = C;


