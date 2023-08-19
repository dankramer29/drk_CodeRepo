%% EMUNBACK COMPARE ACROSS PATIENTS

C=linspecer(100); %sets up plotting colors

% COMBINE THE TABLES (doing this in excel, much easier)
% TtotalAllTrials = [statsAllTrialsId];
% TtotalSigClust = [AllPatientsSigClusterSummStats]; %add the tables together.

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

%% run stats on all trials
%% first run overall stats
% THIS IS FAR EASIER TO JUST SET UP XX IN EXCEL THEN CHANGE THE NAME BELOW
% AND INSERT THE XXS BY CUT AND PASTE
% WAY TO DO THIS: SORT BY CORRECT VS INCORRECT (OR WHATEVER) THEN CUT THE
% RESPONSE TIMES OF THE CORRECT, AND THE RESPONSE TIMES OF THE INCORRECT.
% CHANGE THE VARIABLE NAMES BELOW. DO THE FOLLOWING:
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
[Ax, L] = violin(xxx, 'xlabel', {'Emotion Task', 'Identity Task'}, 'facealpha', 1, 'facecolor', [1 0.549 0; 0.12 0.85 0.98],  'mc', 'b', 'medc', '');
Ax.LineWidth = 2;
Ax.EdgeColor = 'k';
Gc = gca;
Gc.FontSize = 22;
L.FontSize = 22;
L.LineWidth = 4;
%% a scatter plot option
%need to work on something for this. like rex perhaps. scatter will work
%but will need to be spread out by some factor. rex might have a nice
%program for it. look to documentation of scatter for how it's done.
figure
sz = 25;
c = linspace(1,10,length(x));
scatter(x,y,sz,c,'filled')

%% kruskall wallis for individual emotion identity types
TstTempKW = [];
xx(xx==0) = NaN;
nameTable = {'Response Time By Each Emotion'};
testDone = {'Kruskall Wallis'};
nameXX = {'Emotion 1'};
nameYY = {'Emotion 2'};
nameZZ = {'Emotion 3'};
[pvalue, tbl, stats] = kruskalwallis(xx, [], 'off');
multC = multcompare(stats);
meanXX = nanmean(xx(:,1));
meanYY = nanmean(xx(:,2));
meanZZ = nanmean(xx(:,3));
stdXX = nanstd(xx(:,1));
stdYY = nanstd(xx(:,2));
stdZZ = nanstd(xx(:,3));
colorTemp = [C(1,:); C(7,:); C(13,:)];
TstTempKW = table(nameTable, meanXX, stdXX, meanYY, stdYY, meanZZ, stdZZ, pvalue,  testDone);
tbleTemp = array2table(multC, "VariableNames", ["Emotion A", "Emotion B", "Lower Limit", "A-B", "Upper Limit", "P-value"]);
figure
[Ax, L] = violin(xx, 'xlabel', {'Emotion One', 'Emotion Two', 'Emotion Three'}, 'facealpha', 1, 'facecolor', colorTemp,  'mc',  'k', 'medc', '', 'LineWidth', 2);
%Ax.LineWidth = ;
Ax.LineWidth
Ax.EdgeColor =  'k';
Gc = gca;
Gc.FontSize = 22;
L.FontSize = 22;
L.LineWidth = 4;



%% Sig Cluster stats
%Group stats
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

TstTemp = [];
nameTable = {'Cluster Centroid By Time'};
testDone = {'Kruskall Wallis'};

xx = []; %load with stats of whatever category (say Amygdala centroid time)
yy = []; %load with stats of whatever is the second category (say Hippo)
zz = []; %load with stats of the third category
%HAND ADD THE ONES YOU WANT, IT'S MUCH EASIER
for ii = 1:length(xx); nameXX{ii,1} = 'Amygdala'; end
for ii = 1:length(yy); nameYY{ii,1} = 'Hippocampus'; end
for ii = 1:length(zz); nameZZ{ii,1} = 'Insula'; end
colorTemp = [C(3,:); C(28,:); C(80,:)];

%no inputs needed from here below (unless more variables needed, add
%accordingly)
xxx= vertcat(xx,yy,zz);
xxxN = vertcat(nameXX,nameYY, nameZZ);
[pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
multC = multcompare(stats);
meanXX = nanmean(xx);
meanYY = nanmean(yy);
meanZZ = nanmean(zz);
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
swarmchart(x1,xx,5, colorTemp(1,:), 'filled');
hold on
swarmchart(x2,yy,5, colorTemp(2,:), 'filled');
swarmchart(x3,zz,5, colorTemp(3,:), 'filled');
p1=plot([0.75,0.75+(wdth/2)],[meanXX,meanXX],'LineWidth',4, 'Color',C(5,:));
p2=plot([0.75+1,0.75+1+(wdth/2)],[meanYY,meanYY],'LineWidth',4, 'Color',C(30,:));
p3=plot([0.75+2,0.75+2+(wdth/2)],[meanZZ,meanZZ],'LineWidth',4, 'Color',C(82,:));
%legend([p1 p2 p3],{'Mean 1', 'Mean 2', 'Mean 3'})
ax=gca;
ax.XTick = [1,2,3];
ax.YLim = [0:1.5];
ax.YTick = [0:0.2:1.50];
ax.XTickLabel = {nameXX{1}, nameYY{1}, nameZZ{1}};
ax.FontSize = 13;
ax.FontWeight = 'bold';
ylabel('Time (S)', 'FontSize', 18, 'FontWeight','bold')


 %% a repeat for frequency based stuff to make it easier 
TstTemp = [];
nameTable = {'Cluster Centroid By Frequency'};
testDone = {'Kruskall Wallis'};

xx = []; %load with stats of whatever category (say Amygdala centroid time)
yy = []; %load with stats of whatever is the second category (say Hippo)
zz = []; %load with stats of the third category
%HAND ADD THE ONES YOU WANT, IT'S MUCH EASIER
for ii = 1:length(xx); nameXX{ii,1} = 'Amygdala'; end
for ii = 1:length(yy); nameYY{ii,1} = 'Hippocampus'; end
for ii = 1:length(zz); nameZZ{ii,1} = 'Insula'; end
colorTemp = [C(3,:); C(28,:); C(80,:)];


xxx= vertcat(xx,yy,zz);
xxxN = vertcat(nameXX,nameYY, nameZZ);
[pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
multC = multcompare(stats);
meanXX = nanmean(xx);
meanYY = nanmean(yy);
meanZZ = nanmean(zz);
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
swarmchart(x1,xx,5, colorTemp(1,:), 'filled');
hold on
swarmchart(x2,yy,5, colorTemp(2,:), 'filled');
swarmchart(x3,zz,5, colorTemp(3,:), 'filled');
p1=plot([0.75,0.75+(wdth/2)],[meanXX,meanXX],'LineWidth',4, 'Color',C(5,:));
p2=plot([0.75+1,0.75+1+(wdth/2)],[meanYY,meanYY],'LineWidth',4, 'Color',C(30,:));
p3=plot([0.75+2,0.75+2+(wdth/2)],[meanZZ,meanZZ],'LineWidth',4, 'Color',C(82,:));
%legend([p1 p2 p3],{'Mean 1', 'Mean 2', 'Mean 3'})
ax=gca;
ax.XTick = [1,2,3];
ax.YLim = [0:1.5];
ax.YTick = [0:0.2:1.50];
ax.XTickLabel = {nameXX{1}, nameYY{1}, nameZZ{1}};
ax.FontSize = 13;
ax.FontWeight = 'bold';
ylabel('Time (S)', 'FontSize', 18, 'FontWeight','bold')


