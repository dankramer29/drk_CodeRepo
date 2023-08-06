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
AllTrialStats = vertcat(AllTrialStats, TstTemp);
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
TstTemp = [];
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
TstTemp = table(nameTable, meanXX, stdXX, meanYY, stdYY, meanZZ, stdZZ, pvalue,  testDone);
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



%% chi squared for categorical




%Response time x correct v incorrect
[p, h, ci] = ranksum(xx, yy);
meanRTc = mean(xx);
meanRTic = mean(yy);
stdRTc = std(xx);
stdRTic = std(yy);


%% run stats on sig clusters
CorrectResponseST = TtotalSigClust.CorrectResponse;
ResponseTimeST = TtotalSigClust.ResponseTime;
SecondTrialST = TtotalSigClust.SecondTrial;

%%

CentTest = TtotalSigClust.ByTrialCentroid(1:54,2);
CentTest(:,2) = TtotalSigClust.ByTrialCentroid(55:108,2);

violin(CentTest, 'xlabel', {'Amygdala', 'Hippocampus'}, 'facecolor', [1 0.549 0; 0.12 0.85 0.98], 'mc', 'b', 'medc', '');

%% compare response times between tasks (for all trials, not just he positive ones)
[G] = groupsummary(TtotalSigClust, "CorrectResponse", "ResponseTime");
[GG]  = groupsummary(TtotalSigClust, "CorrectResponse", @(x,y) ranksum(x), {["ResponseTime", "ByTrialCentroid", "ByTrialArea"]});
Gf = findgroups(TtotalSigClust.CorrectResponse);
[GG] = splitapply(@ranksum, TtotalSigClust.ResponseTime, Gf)
[GGG]  = groupsummary(TtotalSigClust, "CorrectResponse", "mean", {["ResponseTime", "ByTrialCentroid", "ByTrialArea"]});



xx = CentTest(CentTest(:,3)==1,2);
xx(xx==0) = nan;
yy(yy==0) = nan;
yy = CentTest(CentTest(:,3)==0,2);
[h, p, ci] = ttest2(CentTest(CentTest(:,2)==1),CentTest(CentTest(:,2)==0));
[h, p, ci, stats] = ttest2(xx, yy)
x = nanmean(xx)
xs = nanstd(xx)
yx = nanstd(yy)
y = nanmean(yy)

[pos, ReactionTimespValueOfComparisonBetweenTasks, ci, stats] = ttest(TtotalSigClust.ResponeTime, ResponseTimesDiffIdentitySec);
