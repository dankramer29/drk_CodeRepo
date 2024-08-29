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

%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%start by doing this section
tbleMultCompare = [];
tbleStatsKW = [];
tbleMultCompareLR = [];
tbleStatsKWLR = [];
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

clearvars -except MWallForLoading tbleMultCompare tbleStatsKW tbleMultCompareLR tbleStatsKWLR
closePlots = 0; %turn on if you want to close the plots after each run or off if you don't
yLimChange = 0;
homeLaptop = false;%if using home laptop, make 1, if work desktop make 0


colorTempTest = {'#228E2C', '#64D413', '#0072BD', '#4DBEEE', '#7E2F8E', '#FF13A6'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTempLR = [C(1,:); C(2,:); C(3,:); C(4,:); C(5, :); C(6,:)];
colorTempTest = {'#fee327', '#fdca54', '#f6a570', '#f1969b', '#f08ab1', '#c78dbd', '#927db6', '#5da0d7', '#00b3e1', '#50bcbf', '#65bda5', '#87bf54' };
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp  = [C(12,:); C(9,:); C(6,:)];

clear colorTempTest2
clear C2
colorTempTest2 = { '#274e13ff', '#153465ff','#691060ff'};
for ii = 1:length(colorTempTest2)
    str = colorTempTest2{ii};
    C2(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTempDark = C2;

clmns = MWallForLoading.Properties.VariableNames;

% Time:
clmnNum = 13; %pick the column number here.
nameTable = {'Cluster Centroid By Time '};
varTested = {'Time After Stimulus Onset (sec)'};
testDone = {'Kruskall Wallis'};
timeFig = 1;
meanCluster = true;
yLimChange = 1;


% %This one is probably not helpful:
% clmnNum = 14; %pick the column number here.
% nameTable = {'Cluster Centroid By Frequency '};
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true;

% % % 
% clmnNum = 15; %pick the column number here.
% nameTable = {'Tstat total '};
% varTested = {'Tstat sum'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true;

% 
% clmnNum = 16; %pick the column number here.
% nameTable = {'Cluster Bounding Box Time Onset'};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = true;

% clmnNum = 17; %pick the column number here.
% nameTable = {'Cluster Bounding Box Time Offset'};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = true;


%Probably not helpful
% clmnNum = 18; %pick the column number here. 
% nameTable = {'Cluster Bounding Box Low Frequency '}; %Literally the area of the box
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true; %so run it across the clusters

%Probably not helpful
% clmnNum = 19; %pick the column number here. 
% nameTable = {'Cluster Bounding Box High Frequency '}; %Literally the area of the box
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true; %so run it across the clusters


% clmnNum = 27; %pick the column number here.
% nameTable = {'Peak Power in High Gamma '}; %The max of the bandpassed data 50-150 (I THINK!) in the HG band
% varTested = {'Power A.U.'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters

% clmnNum = 28; %pick the column number here.
% nameTable = {'Time of High Gamma Power Max '}; %time of the peak band
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = false; %so run it across the cluster


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
%for combining multiple clusters COMMENT OUT IF YOU WANT TO RUN 15 TSTAT
%WITHOUT COMBINING CLUSTERS
if clmnNum == 15 %for tstat only
    Ramy = [858.9132583
        1192.011589
        4014.954034
        1892.868625
        3003.532911
        3700.016866];
    Lamy = [8101.388613
        2996.499852
        3073.000352
        1790.493091
        4967.578241
        925.2818105
        4339.36064
        19538.53772
        14048.92154
        5387.24807];
    RAhip = [833.6640765
        1700.362278
        1118.11802
        1216.779713
        1636.87578
        2346.440204
        3167.320156
        3496.592544
        3141.302399
        3292.397784
        4614.45693
        4344.246043
        7683.055399];
    LAhip = [1410.611857
        983.6756167
        1096.154971
        3498.982882
        1397.19422
        1397.663405
        1670.172981
        1887.804942
        5174.677582
        5355.28411
        10371.44916
        24187.334];
    RPhip = [2263.179679
        3049.311268
        3560.361602
        7870.247688
        10145.54392
        11575.63296
        16186.02404
        16850.37263
        39616.07625];
    LPhip = [1049.12496
        1287.979923
        1324.765048
        1477.434387
        1748.710047
        2961.294384
        5728.419612
        7100.563933
        10256.85299
        12914.90445
        15834.60306
        23674.73003
        31491.77001
        34205.80996];
else
    Ramy = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" );
    Lamy = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'");
    RAhip = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'");
    LAhip =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'");
    RPhip = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'");
    LPhip =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'");

    if meanCluster
        Ramy = unique(Ramy);
        Lamy = unique(Lamy);
        RAhip = unique(RAhip);
        LAhip = unique(LAhip);
        RPhip = unique(RPhip);
        LPhip = unique(LPhip);

    end
end

% Ramy = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" );
% Lamy = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'");
% RAhip = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'"); 
% LAhip =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'");
% RPhip = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'"); 
% LPhip =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'");
% %now 
% Ramy(:,2) = MWallForLoading.(clmns{6})(MWallForLoading.RecordingLocation == "'R Amygdala'" );
% Lamy(:,2) = MWallForLoading.(clmns{6})(MWallForLoading.RecordingLocation == "'L Amygdala'");
% RAhip(:,2) = MWallForLoading.(clmns{6})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'"); 
% LAhip(:,2) =  MWallForLoading.(clmns{6})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'");
% RPhip(:,2) = MWallForLoading.(clmns{6})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'"); 
% LPhip(:,2) =  MWallForLoading.(clmns{6})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'");
% end
%EASIEST TO THEN COMBINE BY HAND
%do unique then combine the ones that are 2s or 3s to the one above it in
%excel.




xx = vertcat(Ramy, Lamy);
yy = vertcat(RAhip, LAhip);
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
tbleTemp.("nameTable") = repmat(nameTable,height(tbleTemp),1);

tbleMultCompare = [tbleMultCompare; tbleTemp];
tbleStatsKW = vertcat(tbleStatsKW, TstTempKW);

xxxT{1} = xx;
xxxT{2} = yy;
xxxT{3} = zz;

%just swarm chart
FigType = 'SwarmTwoColumn';
spaceBetData = 0.2; %space between the paired data
f = figure('Name', nameTable{:});
%f.WindowState = 'maximized';
title(nameTable);
fNames = unique(xxxN);
idx = 1;
for cci = 1:width(xxxT)

    hold on

    xDataAt = xxxT{cci};
    xDataA = xDataAt(~isnan(xDataAt)); 


    yDataA = (ones(size(xDataA))*idx);

    sA = scatter(yDataA,xDataA,470,colorTemp(cci,:),'filled');
    sA.XJitter = "density";
    sA.XJitterWidth = 0.3;
    sA.MarkerFaceAlpha = 0.4;
    sA.MarkerEdgeAlpha = 0.4;

    hold on
    tmpMedianA = median(xDataA);
    sAM = scatter(yDataA(1),tmpMedianA,900,colorTemp(cci,:),'filled');
    % sAM.MarkerEdgeColor = 'k';
    % sAM.LineWidth = 1;
   

    idx = idx +1;

end

Gc = gca;
%Gc.XLim = [0.5 (width(xxxT)/2)+0.5];
Gc.FontSize = 20;
Gc.YLabel.String = varTested;
Gc.YLabel.FontSize = 24;
Gc.XTick = [1:width(xxxT)];
Gc.XTickLabel = {(nameXX{1}); (nameYY{1}); (nameZZ{1})};
Gc.XTickLabelRotation = 45;
Gc.Title.String = (nameTable{:}); %gives a supertitle
Gc.Title.FontSize = 28;
if yLimChange
    Gc.YLim = [0 0.9];
end
if timeFig
    Gc.View =  [90 90];
    f.WindowState = 'maximized';
else
    %Gc.OuterPosition = [0 0 1 1];
    f.Position = [1.8000   49.8000  766.4000  732.8000]; %to change position just put it where you want then return f.Position and paste it in here.
    f.WindowState = 'maximized';

end


% h = daviolinplot(xxxT,'violin', 'full', 'colors', colorTemp, 'outlier', 0, 'violinalpha', 0.75, 'xtlabels', {(nameXX{1}); (nameYY{1}); (nameZZ{1})});
% for ii = 1:length(h.ds)
% h.ds(ii).LineWidth = 2;
% h.ds(ii).EdgeColor = 'k';
% end
% Gc = gca;
% Gc.FontSize = 20;
% Gc.YLabel.String = varTested;
% Gc.YLabel.FontSize = 24;
% %Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
% Gc.XTickLabelRotation = 45;
% Gc.Title.String = (nameTable{:}); %gives a supertitle
% Gc.Title.FontSize = 28;
% if yLimChange
% Gc.YLim = [-1 3];
% end
% if timeFig  
% Gc.View =  [90 90];
% Gc.Position = [0.1365    0.1    0.7685    0.8];
% end
% open tbleTemp

xxx=[];
xxxN=[];
nameTable{1} = strcat(nameTable{1}, ' by Laterality');


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
tbleTempLR.("nameTable") = repmat(nameTable,height(tbleTempLR),1);

tbleMultCompareLR = [tbleMultCompareLR; tbleTempLR];
tbleStatsKWLR = vertcat(tbleStatsKWLR, TstTempKWLR);

xxxT{1} = Ramy;
xxxT{2} = Lamy;
xxxT{3} = RAhip;
xxxT{4} = LAhip;
xxxT{5} = RPhip;
xxxT{6} = LPhip;

%just swarm chart
FigType = 'SwarmTwoColumn';
spaceBetData = 0.4; %space between the paired data
f = figure('Name', nameTable{:});
%f.WindowState = 'maximized';
title(nameTable);
fNames = unique(xxxN);
idx = 1; idx1 = 1;
for cci = 1:2:width(xxxT)

    hold on

    xDataAt = xxxT{cci};
    xDataA = xDataAt(~isnan(xDataAt));
    xDataBt = xxxT{cci+1};
    xDataB = xDataBt(~isnan(xDataBt));


    yDataA = (ones(size(xDataA))*idx) - spaceBetData;
    yDataB = (ones(size(xDataB))*idx) + spaceBetData;

    sA = scatter(yDataA,xDataA,270,colorTempLR(cci,:),'filled');
    sA.XJitter = "density";
    sA.XJitterWidth = 0.3;
    sA.MarkerFaceAlpha = 0.4;
    sA.MarkerEdgeAlpha = 0.4;

    hold on

    sB = scatter(yDataB,xDataB,270,colorTempLR(cci+1,:),'filled');
    sB.XJitter = "density";
    sB.XJitterWidth = 0.3;
    sB.MarkerFaceAlpha = 0.4;
    sB.MarkerEdgeAlpha = 0.4;

    tmpMedianA = median(xDataA);
    sAM = scatter(yDataA(1),tmpMedianA,500,colorTempLR(cci,:),'filled');

    tmpMedianB = median(xDataB);
    sBM = scatter(yDataB(1),tmpMedianB,500,colorTempLR(cci+1,:),'filled');

    line([yDataA(1) yDataB(1)],[tmpMedianA tmpMedianB],'Color',colorTempDark(idx1,:), 'LineWidth', 3)
    idx = idx +2; idx1 = idx1 + 1;

end

idx2 = 1;
for jj = 1:2:(width(xxxT)) %this should always work because you have paired data
    xtickcenter(idx2) = jj-spaceBetData;
    idx2 = idx2+1;
    xtickcenter(idx2) = jj+spaceBetData;
    idx2 = idx2+1;
end

Gc = gca;
%Gc.XLim = [0.5 (width(xxxT)/2)+0.5];
Gc.FontSize = 20;
Gc.YLabel.String = varTested;
Gc.YLabel.FontSize = 24;
Gc.XTick = xtickcenter; 
Gc.XTickLabel = {(nameRamy{1}); (nameLamy{1}); (nameRAhip{1}); (nameLAhip{1}); (nameRPhip{1}); (nameLPhip{1})};
Gc.XTickLabelRotation = 45;
Gc.Title.String = (nameTable{:}); %gives a supertitle
Gc.Title.FontSize = 28;
if yLimChange
    Gc.YLim = [0 0.9];
end
if timeFig
    Gc.View =  [90 90];
    f.WindowState = 'maximized';
else
    %Gc.OuterPosition = [0 0 1 1];
    f.Position = [1	1001 960 957.6];
end


hh =  findobj('type','figure'); 
nh = length(hh);
if homeLaptop %if using home laptop, make 1, if work desktop make 0
plt.save_plots([1:nh], 'folderName', 'C:\Users\kramdani\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'AnatomicStructure', ...
        'versionNum', 'v1', 'plotType', 'png');
plt.save_plots([2], 'folderName', 'C:\Users\kramdani\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'AnatomicStructure', ...
        'versionNum', 'v1', 'plotType', 'svg');
else
plt.save_plots([1:nh], 'folderName', 'C:\Users\dankr\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'AnatomicStructure', ...
        'versionNum', 'v1', 'plotType', 'png');
plt.save_plots([2,4], 'folderName', 'C:\Users\dankr\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'AnatomicStructure', ...
        'versionNum', 'v1', 'plotType', 'svg');

end
if closePlots
close all
end
% h = daviolinplot(xxxT,'violin', 'full', 'colors', colorTempLR, 'outlier', 0, 'violinalpha', 0.75, 'xtlabels', {(nameRamy{1}); (nameLamy{1}); (nameRAhip{1}); (nameLAhip{1}); (nameRPhip{1}); (nameLPhip{1})});
% for ii = 1:length(h.ds)
% h.ds(ii).LineWidth = 2;
% h.ds(ii).EdgeColor = 'k';
% end
% Gc = gca;
% Gc.FontSize = 20;
% Gc.YLabel.String = varTested;
% Gc.YLabel.FontSize = 24;
% %Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
% Gc.XTickLabelRotation = 45;
% Gc.Title.String = (nameTable{:}); %gives a supertitle
% Gc.Title.FontSize = 28;
% if yLimChange
% Gc.YLim = [-1 3];
% end
% if timeFig  
% Gc.View =  [90 90];
% Gc.Position = [0.1365    0.1    0.7685    0.8];
% end
% open tbleTempLR

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
tbleMultCompare = [];
tbleStatsKW = [];

%% Group stats CLUSTER FOR MEAN STATS EMOTION VS IDENTITY
%Run the above before running this section over and over. 
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

clearvars -except MWallForLoading tbleMultCompare tbleStatsKW
closePlots = 0;
yLimChange = 0;
homeLaptop = false;%if using home laptop, make 1, if work desktop make 0


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
colorTempTest = {'#38761dff', '#93c47dff', '#0b5394ff', '#6d9eebff', '#9c1eb0ff', '#a587c9ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = C;

clear colorTempTest2
clear C2
colorTempTest2 = { '#274e13ff', '#153465ff','#691060ff'};
for ii = 1:length(colorTempTest2)
    str = colorTempTest2{ii};
    C2(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTempDark = C2;
clmns = MWallForLoading.Properties.VariableNames;

% % % 
% clmnNum = 15; %pick the column number here.
% nameTable = {'Tstat total '};
% varTested = {'Tstat sum'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true;
% PlotType = 3; %double swarm chart

% Time:
clmnNum = 13; %pick the column number here.
nameTable = {'Cluster Centroid By Time '};
varTested = {'Time After Stimulus Onset (sec)'};
testDone = {'Kruskall Wallis'};
timeFig = 1;
meanCluster = true;
yLimChange = 1;
PlotType = 3;



%This one is probably not helpful:
% clmnNum = 14; %pick the column number here.
% nameTable = {'Cluster Centroid By Frequency '};
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = true;
% PlotType = 3; %double swarm chart


% clmnNum = 16; %pick the column number here.
% nameTable = {'Cluster Bounding Box Time Onset '};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% PlotType = 3; %double swarm chart
% meanCluster = true;
% 
% clmnNum = 17; %pick the column number here.
% nameTable = {'Cluster Bounding Box Time Offset  '};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = true; %so run it across the clusters
% PlotType = 3; %double swarm chart

% clmnNum = 18; %pick the column number here.
% nameTable = {'Cluster Bounding Box Low Frequency '}; %Literally the area of the box
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters
% PlotType = 3; %double swarm chart


% clmnNum = 19; %pick the column number here.
% nameTable = {'Cluster Bounding Box High Frequency '}; %Literally the area of the box
% varTested = {'Frequency (Hz)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters
% PlotType = 3; %double swarm chart

% clmnNum = 27; %pick the column number here.
% nameTable = {'Peak Power in High Gamma '}; %The max of the bandpassed data 50-150 (I THINK!) in the HG band
% varTested = {'Power A.U.'};
% testDone = {'Kruskall Wallis'};
% timeFig = 0;
% meanCluster = false; %so run it across the clusters
% PlotType = 3; %double swarm chart

% clmnNum = 28; %pick the column number here.
% nameTable = {'Time of High Gamma Power Max '}; %time of the peak band
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% meanCluster = false; %so run it across the clusters
% PlotType = 3; %double swarm chart

%pull out the areas you want
idxX = 1; idxY = 1; idxZ = 1;
%
if clmnNum == 15 %for tstat to combine 
    %did this by hand for ease of combining t stats across clusters for the
    %same electrode

    xxEm = [1790.49309100000
        3073.00035200000
        4339.36064000000
        19538.5377200000
        14048.9215400000
        8101.38861300000
        5387.24807000000
        3700.01686600000
        4014.95403400000
        858.913258300000];

    xxId = [2996.49985200000
        4967.57824100000
        925.281810500000
        1892.86862500000
        1192.01158900000
        3003.53291100000];

    yyEm = [1397.66340500000
        1887.80494200000
        1096.15497100000
        10371.4491600000
        1670.17298100000
        1397.19422000000
        24187.3340000000
        5355.28411000000
        5174.67758200000
        1700.36227800000
        833.664076500000
        4344.24604300000
        7183.01656700000
        3141.30239900000
        1216.77971300000
        4614.45693000000
        3667.35898800000];

    yyId = [983.675616700000
        1410.61185700000
        2901.57667600000
        1118.11802000000
        2346.44020400000
        3496.59254400000
        1636.87578000000
        3292.39778400000];

    zzEm = [2961.29438400000
        31491.7700100000
        23674.7300300000
        15834.6030600000
        1477.43438700000
        1049.12496000000
        1748.71004700000
        5728.41961200000
        10256.8529900000
        39616.0762500000
        3560.36160200000
        16186.0240400000
        7870.24768800000];

    zzId = [34205.8099600000
        12914.9044500000
        1324.76504800000
        1287.97992300000
        7100.56393300000
        2263.17967900000
        16850.3726300000
        3049.31126800000
        11575.6329600000
        10145.5439200000];
else
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
end

for ii = 1:length(xxEm); nameXXEm{ii,1} = 'Amygdala Emotion'; end
for ii = 1:length(yyEm); nameYYEm{ii,1} = 'Anterior Hippocampus Emotion'; end
for ii = 1:length(zzEm); nameZZEm{ii,1} = 'Posterior Hippocampus Emotion'; end

% 
% for ii = 1:length(RamyEm); nameRamyEm{ii,1} = 'Right Amygdala Emotion'; end
% for ii = 1:length(RAhipEm); nameRAhipEm{ii,1} = 'Right Anterior Hippocampus Emotion'; end
% for ii = 1:length(RPhipEm); nameRPhipEm{ii,1} = 'Right Posterior Hippocampus Emotion'; end
% for ii = 1:length(LamyEm); nameLamyEm{ii,1} = 'Left Amygdala Emotion'; end
% for ii = 1:length(LAhipEm); nameLAhipEm{ii,1} = 'Left Anterior Hippocampus Emotion'; end
% for ii = 1:length(LPhipEm); nameLPhipEm{ii,1} = 'Left Posterior Hippocampus Emotion'; end

for ii = 1:length(xxId); nameXXId{ii,1} = 'Amygdala Identity'; end
for ii = 1:length(yyId); nameYYId{ii,1} = 'Anterior Hippocampus Identity'; end
for ii = 1:length(zzId); nameZZId{ii,1} = 'Posterior Hippocampus Identity'; end

% for ii = 1:length(RamyId); nameRamyId{ii,1} = 'Right Amygdala Identity'; end
% for ii = 1:length(RAhipId); nameRAhipId{ii,1} = 'Right Anterior Hippocampus Identity'; end
% for ii = 1:length(RPhipId); nameRPhipId{ii,1} = 'Right Posterior Hippocampus Identity'; end
% for ii = 1:length(LamyId); nameLamyId{ii,1} = 'Left Amygdala Identity'; end
% for ii = 1:length(LAhipId); nameLAhipId{ii,1} = 'Left Anterior Hippocampus Identity'; end
% for ii = 1:length(LPhipId); nameLPhipId{ii,1} = 'Left Posterior Hippocampus Identity'; end


%no inputs needed from here below (unless more variables needed, add
%accordingly)
%data(:,1:eacharea, 'groups', groupIdx(each number = a row and associates it with a time period))
xxx= vertcat(xxEm, xxId,yyEm, yyId, zzEm, zzId);
xxxN = vertcat(nameXXEm, nameXXId, nameYYEm, nameYYId, nameZZEm, nameZZId);
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
tbleTemp.("nameTable") = repmat(nameTable,height(tbleTemp),1);
xxxT{1} = xxEm;
xxxT{2} = xxId;
xxxT{3} = yyEm;
xxxT{4} = yyId;
xxxT{5} = zzEm;
xxxT{6} = zzId;

tbleMultCompare = [tbleMultCompare; tbleTemp];
tbleStatsKW = vertcat(tbleStatsKW, TstTempKW);

switch PlotType
    case 1
        %% violin plot
        FigType = 'SwarmOneColumn';
        figure('Name', nameTable{:});
        title(nameTable);        
        h = daviolinplot(xxxT,'violin', 'full', 'colors', colorTemp, 'outlier', 0, 'violinalpha', 0.75, 'scatter', 2, 'scattersize', 55, 'scattercolors', 'w', 'xtlabels', {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})});
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
            Gc.YLim = [0 1.2];
        end
        if timeFig
            Gc.View =  [90 90];      
            f.WindowState = 'maximized';
        else
            %Gc.OuterPosition = [0 0 1 1];
            f.Position = [1	1001 960 957.6];
        end    




        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% swarm chart version
    case 2

        %% SINGLE COLUMN
        FigType = 'SwarmOneColumn';

        % Change to your cool color scheme

        f = figure('Name', nameTable{:});
        f.Position = [1	1001	960	957.6];
        title(nameTable);  
        fNames = unique(xxxN);
        for cci = 1:width(xxxT)

            xData1 = xxxT{cci};
            xData2 = xData1(~isnan(xData1));
            yData = ones(size(xData2))*(cci);
            s1 = scatter(yData,xData2,180,colorTemp(cci,:),'filled');
            s1.XJitter = "density";
            s1.XJitterWidth = 0.5;
            s1.MarkerFaceAlpha = 0.7;

            tmpMedian = median(xData2);
            line([(cci) + 0.4 (cci) - 0.4],[tmpMedian tmpMedian], 'Color',colorTemp((cci),:),...
                'LineWidth',2)

            hold on

        end


        xticks(1:width(xxxT))
        xticklabels(fNames)

        Gc = gca;
        Gc.XLim = [0 7];
        Gc.FontSize = 20;
        Gc.YLabel.String = varTested;
        Gc.YLabel.FontSize = 24;
        Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
        Gc.XTickLabelRotation = 45;
        Gc.Title.String = (nameTable{:}); %gives a supertitle
        Gc.Title.FontSize = 28;
        if yLimChange
            Gc.YLim = [0 1.2];
        end
        if timeFig
            Gc.View =  [90 90];      
            f.WindowState = 'maximized';
        else
            %Gc.OuterPosition = [0 0 1 1];
            f.Position = [1	1001 960 957.6];
        end    

        %% DOUBLE COLUMN
    case 3
        FigType = 'SwarmTwoColumn';
        spaceBetData = 0.2; %space between the paired data
        f = figure('Name', nameTable{:});
        %f.WindowState = 'maximized';
        title(nameTable);  
        fNames = unique(xxxN);
        idx = 1;
        for cci = 1:2:width(xxxT)

            hold on

            xDataAt = xxxT{cci};
            xDataA = xDataAt(~isnan(xDataAt));
            xDataBt = xxxT{cci+1};
            xDataB = xDataBt(~isnan(xDataBt));


            yDataA = (ones(size(xDataA))*idx) - spaceBetData;
            yDataB = (ones(size(xDataB))*idx) + spaceBetData;
            
            sA = scatter(yDataA,xDataA,180,colorTemp(cci,:),'filled');
            sA.XJitter = "density";
            sA.XJitterWidth = 0.3;
            sA.MarkerFaceAlpha = 0.4;
            sA.MarkerEdgeAlpha = 0.4;

            hold on

            sB = scatter(yDataB,xDataB,180,colorTemp(cci+1,:),'filled');
            sB.XJitter = "density";
            sB.XJitterWidth = 0.3;
            sB.MarkerFaceAlpha = 0.4;
            sB.MarkerEdgeAlpha = 0.4;

            tmpMedianA = median(xDataA);
            sAM = scatter(yDataA(1),tmpMedianA,300,colorTemp(cci,:),'filled');

            tmpMedianB = median(xDataB);
            sBM = scatter(yDataB(1),tmpMedianB,300,colorTemp(cci+1,:),'filled');

            line([yDataA(1) yDataB(1)],[tmpMedianA tmpMedianB],'Color',colorTempDark(idx,:), 'LineWidth', 3)
            idx = idx +1;

        end

        idx2 = 1;
        for jj = 1:(width(xxxT)/2) %this should always work because you have paired data
            xtickcenter(idx2) = jj-spaceBetData;
            idx2 = idx2+1;
            xtickcenter(idx2) = jj+spaceBetData;
            idx2 = idx2+1;
        end




        Gc = gca;
        Gc.XLim = [0.5 (width(xxxT)/2)+0.5];
        Gc.FontSize = 20;
        Gc.YLabel.String = varTested;
        Gc.YLabel.FontSize = 24;
        Gc.XTick = xtickcenter;
        Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
        Gc.XTickLabelRotation = 45;
        Gc.Title.String = (nameTable{:}); %gives a supertitle
        Gc.Title.FontSize = 28;
        if yLimChange
            Gc.YLim = [0 0.9];
        end
        if timeFig
            Gc.View =  [90 90];      
            f.WindowState = 'maximized';
        else
            %Gc.OuterPosition = [0 0 1 1];
            if homeLaptop
                f.Position = [1	1001 960 957.6];
            else
                f.Position = [1.8000   49.8000  766.4000  732.8000];
            end
        end      

end

hh =  findobj('type','figure'); 
nh = length(hh);
if homeLaptop %if using home laptop, make 1, if work desktop make 0
plt.save_plots([1:nh], 'folderName', 'C:\Users\kramdani\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'EmvId', ...
        'versionNum', 'v1', 'plotType', 'png');
plt.save_plots([2], 'folderName', 'C:\Users\kramdani\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'EmvId', ...
        'versionNum', 'v1', 'plotType', 'svg');
else
plt.save_plots([1:nh], 'folderName', 'C:\Users\dankr\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'EmvId', ...
        'versionNum', 'v1', 'plotType', 'png');
plt.save_plots([2], 'folderName', 'C:\Users\dankr\Dropbox\Attending\Projects\Amygdala BF\LFP_nBack\Figs', 'sessionName', FigType, 'subjName', 'EmvId', ...
        'versionNum', 'v1', 'plotType', 'svg');

end
if closePlots
close all
end




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
% 
% 
% % %lighter
% colorTempTest = {'#fee327', '#fdca54', '#f6a570', '#f1969b', '#f08ab1', '#c78dbd', '#927db6', '#5da0d7', '#00b3e1', '#50bcbf', '#65bda5', '#87bf54' };
% for ii = 1:length(colorTempTest)
%     str = colorTempTest{ii};
%     C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
% end
% colorTemp = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];
% 
% colorTempLR = [C(12,:); C(11,:); C(9,:); C(8,:); C(7, :); C(6,:)];
% 
% 
% clmns = MWallForLoading.Properties.VariableNames;
% meanCluster = false;
% 
% % Time:
% clmnNumList = [16, 19, 20]; %pick the column number here.
% nameTable = {'Cluster Centroid By Time '};
% varTested = {'Time (S)'};
% testDone = {'Kruskall Wallis'};
% timeFig = 1;
% 
% %This one is probably not helpful:
% % clmnNum = 14; %pick the column number here.
% % nameTable = {'Cluster Centroid By Frequency '};
% % varTested = {'Frequency (Hz)'};
% % testDone = {'Kruskall Wallis'};
% 
% % clmnNum = 15; %pick the column number here.
% % nameTable = {'Tstat total '};
% % varTested = {'Tstat sum'};
% % testDone = {'Kruskall Wallis'};
% 
% 
% 
% 
% 
% %pull out the areas you want
% 
% idxX = 1; idxY = 1; idxZ = 1;
% for ii = 1:3
% clmnNum = clmnNumList(ii); %pick the column number here.
% RamyEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" & MWallForLoading.TrialType == "'emotionTask'"); 
% LamyEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'" & MWallForLoading.TrialType == "'emotionTask'");
% RAhipEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'"); 
% LAhipEm =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'");
% RPhipEm = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'"); 
% LPhipEm =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'" & MWallForLoading.TrialType == "'emotionTask'");
% 
% RamyId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Amygdala'" & MWallForLoading.TrialType == "'identityTask'"); 
% LamyId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Amygdala'" & MWallForLoading.TrialType == "'identityTask'");
% RAhipId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'R Anterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'"); 
% LAhipId =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation ==  "'L Anterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'");
% RPhipId = MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'R Posterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'"); 
% LPhipId =  MWallForLoading.(clmns{clmnNum})(MWallForLoading.RecordingLocation == "'L Posterior Hippocampus'" & MWallForLoading.TrialType == "'identityTask'");
% if meanCluster
%     RamyEm(:,ii) = unique(RAhipEm);
%     LamyEm(:,ii) = unique(LAhipEm);
%     RAhipEm(:,ii) = unique(RAhipEm);
%     LAhipEm(:,ii) = unique(LAhipEm);
%     RPhipEm(:,ii) = unique(RPhipEm);
%     LPhipEm(:,ii) = unique(LPhipEm);
%     RamyId(:,ii) = unique(RAhipId);
%     LamyId(:,ii) = unique(LAhipId);
%     RAhipId(:,ii) = unique(RAhipId);
%     LAhipId(:,ii) = unique(LAhipId);
%     RPhipId(:,ii) = unique(RPhipId);
%     LPhipId(:,ii) = unique(LPhipId);
% end
% 
% xxEm(:,ii) = vertcat(RamyEm, LamyEm);
% yyEm(:,ii) = vertcat(RAhipEm, LAhipEm);
% zzEm(:,ii) = vertcat(RPhipEm, LPhipEm);
% xxId(:,ii) = vertcat(RamyId, LamyId);
% yyId(:,ii) = vertcat(RAhipId, LAhipId);
% zzId(:,ii) = vertcat(RPhipId, LPhipId);
% end
% 
% 
% 
% 
% 
% 
% for ii = 1:length(xxEm); nameXXEm{ii,1} = 'Amygdala Emotion'; end
% 
% for ii = 1:length(yyEm); nameYYEm{ii,1} = 'Anterior Hippocampus Emotion'; end
% for ii = 1:length(zzEm); nameZZEm{ii,1} = 'Posterior Hippocampus Emotion'; end
% 
% 
% for ii = 1:length(RamyEm); nameRamyEm{ii,1} = 'Right Amygdala Emotion'; end
% for ii = 1:length(RAhipEm); nameRAhipEm{ii,1} = 'Right Anterior Hippocampus Emotion'; end
% for ii = 1:length(RPhipEm); nameRPhipEm{ii,1} = 'Right Posterior Hippocampus Emotion'; end
% for ii = 1:length(LamyEm); nameLamyEm{ii,1} = 'Left Amygdala Emotion'; end
% for ii = 1:length(LAhipEm); nameLAhipEm{ii,1} = 'Left Anterior Hippocampus Emotion'; end
% for ii = 1:length(LPhipEm); nameLPhipEm{ii,1} = 'Left Posterior Hippocampus Emotion'; end
% 
% for ii = 1:length(xxId); nameXXId{ii,1} = 'Amygdala Identity'; end
% for ii = 1:length(yyId); nameYYId{ii,1} = 'Anterior Hippocampus Identity'; end
% for ii = 1:length(zzId); nameZZId{ii,1} = 'Posterior Hippocampus Identity'; end
% 
% for ii = 1:length(RamyId); nameRamyId{ii,1} = 'Right Amygdala Identity'; end
% for ii = 1:length(RAhipId); nameRAhipId{ii,1} = 'Right Anterior Hippocampus Identity'; end
% for ii = 1:length(RPhipId); nameRPhipId{ii,1} = 'Right Posterior Hippocampus Identity'; end
% for ii = 1:length(LamyId); nameLamyId{ii,1} = 'Left Amygdala Identity'; end
% for ii = 1:length(LAhipId); nameLAhipId{ii,1} = 'Left Anterior Hippocampus Identity'; end
% for ii = 1:length(LPhipId); nameLPhipId{ii,1} = 'Left Posterior Hippocampus Identity'; end
% 
% 
% %no inputs needed from here below (unless more variables needed, add
% %accordingly)
% %stack each area on top of each other and make the three columns the three
% %times
% %data(:,1:eacharea, 'groups', groupIdx(each number = a row and associates it with a time period))
% xxx= vertcat(xxEm,yyEm,zzEm, xxId,yyId,zzId);
% xxxN = vertcat(nameXXEm,nameYYEm, nameZZEm, nameXXId,nameYYId, nameZZId);
% figure
% [pvalue, tbl, stats] = kruskalwallis(xxx, xxxN, 'off');
% multC = multcompare(stats);
% meanXXEm = nanmean(xxEm);
% meanYYEm = nanmean(yyEm);
% meanZZEm = nanmean(zzEm);
% medianXXEm = nanmedian(xxEm);
% medianYYEm = nanmedian(yyEm);
% medianZZEm = nanmedian(zzEm);
% stdXXEm = nanstd(xxEm);
% stdYYEm = nanstd(yyEm);
% stdZZEm = nanstd(zzEm);
% meanXXId = nanmean(xxId);
% meanYYId = nanmean(yyId);
% meanZZId = nanmean(zzId);
% medianXXId = nanmedian(xxId);
% medianYYId = nanmedian(yyId);
% medianZZId = nanmedian(zzId);
% stdXXId = nanstd(xxId);
% stdYYId = nanstd(yyId);
% stdZZId = nanstd(zzId);
% TstTempKW = table(nameTable, meanXXEm, stdXXEm, meanXXId, stdXXId, meanYYEm, stdYYEm,  meanYYId, stdYYId, meanZZEm, stdZZEm, meanZZId, stdZZId, pvalue, testDone);
% tbleTemp = array2table(multC, "VariableNames", ["Category 1", "Category 2", "Lower Limit", "A-B", "Upper Limit", "P-value"]);
% figure('Name', nameTable{:});
% title(nameTable); 
% xxxT{1} = xxEm;
% xxxT{2} = xxId;
% xxxT{3} = yyEm;
% xxxT{4} = yyId;
% xxxT{5} = zzEm;
% xxxT{6} = zzId;
% h = daviolinplot(xxxT,'violin', 'groups', [1,2,3], 'full', 'colors', colorTemp, 'violinalpha', 0.75, 'xtlabels', {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})});
% for ii = 1:length(h.ds)
% h.ds(ii).LineWidth = 2;
% h.ds(ii).EdgeColor = 'k';
% end
% Gc = gca;
% Gc.FontSize = 18;
% Gc.YLabel.String = varTested;
% Gc.YLabel.FontSize = 24;
% %Gc.XTickLabel = {(nameXXEm{1}); (nameXXId{1}); (nameYYEm{1}); (nameYYId{1}); (nameZZEm{1}); (nameZZId{1})};
% Gc.XTickLabelRotation = 45;
% Gc.Title.String = (nameTable{:}); %gives a supertitle
% Gc.Title.FontSize = 28;
% Gc.YLim = [0 6e4];
% if timeFig  
% Gc.View =  [90 90];
% Gc.Position = [0.1365    0.1    0.7685    0.8];
% end
% 
% 
% open tbleTemp
% 
% xxx=[];
% xxxN=[];


