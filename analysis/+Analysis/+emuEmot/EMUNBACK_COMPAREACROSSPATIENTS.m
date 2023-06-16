%% EMUNBACK COMPARE ACROSS PATIENTS


% COMBINE THE TABLES
TtotalAllTrials = [statsAllTrialsId];
TtotalSigClust = [AllPatientsSigClusterSummStats]; %add the tables together.

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
CorrectResponseT = TtotalAllTrials.CorrectResponse;
ResponseTimeT = TtotalAllTrials.ResponseTime;
SecondTrialST = TtotalAllTrials.SecondTrial;

%Response time x correct v incorrect
[p, h, ci] = ranksum(ResponseTimeT(CorrectResponse==1,1), ResponseTimeT(CorrectResponseT==0,1));
meanRTc = mean(ResponseTimeT(CorrectResponse==1,1));
meanRTic = mean(ResponseTimeT(CorrectResponseT==0,1));
stdRTc = std(ResponseTimeT(CorrectResponse==1,1));
stdRTic = std(ResponseTimeT(CorrectResponseT==0,1));


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
