%% EMUNBACK COMPARE ACROSS PATIENTS


% COMBINE THE TABLES
Ttotal = [AllPatientsSigClusterSummStats]; %add the tables together.





%% compare response times between tasks (for all trials, not just he positive ones)
G = groupsummary(Ttotal, "CorrectResponse", "mean", "ResponseTime");
GG = groupsummary(Ttotal, "CorrectResponse", @(x,y) ttest(x), {["ResponseTime", "ByTrialCentroid", "ByTrialArea"]});

[pos, ReactionTimespValueOfComparisonBetweenTasks, ci, stats] = ttest(Ttotal.ResponeTime, ResponseTimesDiffIdentitySec);
