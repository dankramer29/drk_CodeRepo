%THIS IS FOR MATCHING THE CHANNELS IN BOXES (FIRST FIGURE) OR THE TSTAT
%SIZES WITH MATCHED BUBBLES
%% channels with matched significance (the boxes)
% Inputs, make Amy, Ahip, APhip the 1 0 inputs from the channel output
% (what i sent to meg)
% MWallForLoading

clear colorTempTest
clear C
colorTempTest = {'#38761dff', '#93c47dff', '#0b5394ff', '#6d9eebff', '#9c1eb0ff', '#a587c9ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = C;

% Sample data for the colors of the squares
% Each cell represents a color for a square in a pair of bars
% 1 represents color1, 2 represents color2
pairedChannels = {
    Amy,  % Pair 1 (6 squares)
    Ahip,  % Pair 2 (8 squares)
    APhip  % Pair 3 (6 squares)
};

% Create the figure
figure;
hold on;

% Parameters
squareSize = 0.9;  % Size of each square
barWidth = 0.4;  % Width of each bar
smallGap = 0.5;  % Small gap between paired bars
largeGap = 2;  % Large gap between pairs of bars

% Loop through each pair of bars
idx = 1; idx2 = 1;
for i = 1:length(pairedChannels)
    color1 = colorTemp(idx,:);
    idx = idx+1;
    color2 = colorTemp(idx,:);
    idx = idx+1;
    for j = 1:2
        % Get the colors for the squares in the current bar
        chTemp = pairedChannels{i}(j, :);
        if j==1
            color = color1;
        elseif j == 2
            color = color2;
        end
        % Plot each square
        for k = 1:length(chTemp)
            
            if chTemp(k) == 1
                mask = 1;
            else
                mask = 0.2;
            end
            
            % Calculate position
            x = (2*i - 2 + j) * (barWidth + smallGap) + (i - 1) * (largeGap - smallGap);
            xtickLoc(idx2,1) = x;
            idx2 = idx2 + 1;
            y = k - 1;
            
            % Define the vertices of the square
            vertices = [x, y; x+squareSize, y; x+squareSize, y+squareSize; x, y+squareSize];
            
            % Plot the square
            patch('Vertices', vertices, 'Faces', [1 2 3 4], 'FaceColor', color, 'EdgeColor', 'none', 'FaceAlpha', mask);
        end
    end
end

xtickLoct = unique(xtickLoc);

tickLabel ={'Amygdala Emotion'
'Amygdala Identity'
'Anterior Hippocampus Emotion'
'Anterior Hippocampus Identity'
'Posterior Hippocampus Emotion'
'Posterior Hippocampus Identity'};

% Set the x-axis labels
set(gca, 'XTick', xtickLoct, 'XTickLabel', tickLabel);

% Add labels and title
ylabel('Electrode Count');
title('Electrodes with High Gamma Activity During Each Task');

% Adjust the limits
xlim([0 (2*length(pairedChannels)) * (barWidth + gap)+2]);
ylim([0 max(cellfun(@(x) size(x, 2), pairedChannels)) + 2]);

hold off;

Gc = gca;
Gc.FontSize = 22;
Gc.XTickLabelRotation = 45;
Gc.Title.FontSize = 26;

%%
%THIS IS WITH BUBBLES
%first, i made a separate excel with only 'PatientName'	'RecordingLocation'	'ChannelNumber'	'TrialType'	'AllImagesSignificantAnywhere'	'ClusterNumber'	'TstatCluster'
%GAVE UP AND HAND SORTED IN EXCEL
%clmns = MWallForLoading2.Properties.VariableNames;

AmyClusterSum =[1790.49309100000	0
3073.00035200000	2996.49985200000
4339.36064000000	0
19538.5377200000	4967.57824100000
14048.9215400000	925.281810500000
8101.38861300000	0
5387.24807000000	0
3700.01686600000	1892.86862500000
4014.95403400000	1192.01158900000
858.913258300000	0
0	3003.53291100000];

AHipClusterSum = [1397.66340500000	0
1887.80494200000	983.675616700000
1096.15497100000	0
10371.4491600000	0
1670.17298100000	0
1397.19422000000	0
24187.3340000000	0
5355.28411000000	1410.61185700000
5174.67758200000	2901.57667600000
1700.36227800000	0
833.664076500000	0
4344.24604300000	0
7183.01656700000	1118.11802000000
3141.30239900000	2346.44020400000
1216.77971300000	0
4614.45693000000	0
3667.35898800000	3496.59254400000
0	1636.87578000000
0	3292.39778400000];

PHipClusterSum = [2961.29438400000	0
31491.7700100000	34205.8099600000
23674.7300300000	0
15834.6030600000	12914.9044500000
1477.43438700000	1324.76504800000
1049.12496000000	0
1748.71004700000	1287.97992300000
5728.41961200000	0
10256.8529900000	7100.56393300000
39616.0762500000	0
3560.36160200000	2263.17967900000
16186.0240400000	16850.3726300000
7870.24768800000	3049.31126800000
0	11575.6329600000
0	10145.5439200000];

   
clusterSum{1} = AmyClusterSum;
clusterSum{2} = AHipClusterSum;
clusterSum{3} = PHipClusterSum;

clusterSumT = AmyClusterSum(:,1);
clusterSumT = vertcat(clusterSumT, AHipClusterSum(:,1));
clusterSumT = vertcat(clusterSumT,PHipClusterSum(:,1));
clusterSumT = vertcat(clusterSumT,AmyClusterSum(:,2));
clusterSumT = vertcat(clusterSumT,AHipClusterSum(:,2));
clusterSumT = vertcat(clusterSumT,PHipClusterSum(:,2));
xxx= clusterSumT;
xxxT = xxx;
for ii = 1:length(AmyClusterSum(:,1)); nameXXEm{ii,1} = 'Amygdala Emotion'; end
for ii = 1:length(AHipClusterSum); nameYYEm{ii,1} = 'Anterior Hippocampus Emotion'; end
for ii = 1:length(PHipClusterSum); nameZZEm{ii,1} = 'Posterior Hippocampus Emotion'; end
for ii = 1:length(AmyClusterSum); nameXXId{ii,1} = 'Amygdala Identity'; end
for ii = 1:length(AHipClusterSum); nameYYId{ii,1} = 'Anterior Hippocampus Identity'; end
for ii = 1:length(PHipClusterSum); nameZZId{ii,1} = 'Posterior Hippocampus Identity'; end
xxxN = vertcat(nameXXEm, nameXXId, nameYYEm, nameYYId, nameZZEm, nameZZId);
xxxT(xxx==0) = [];
xxxN(xxx==0) = [];
figure
[pvalue, tbl, stats] = kruskalwallis(xxxT, xxxN, 'off');
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

clear colorTempTest xtickLoc xtickLoct
clear C
colorTempTest = {'#38761dff', '#93c47dff', '#0b5394ff', '#6d9eebff', '#9c1eb0ff', '#a587c9ff'};
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end
colorTemp = C;

% Sample data for the colors of the squares
% Each cell represents a color for a square in a pair of bars
% 1 represents color1, 2 represents color2
figure;
hold on;

% Parameters
numPairs = length(clusterSum);
smallBubbleSize = 10;  % Small bubble size for zero data
largeGap = 0.3;  % Gap between pairs of data
smallGap = 0.1;  % Gap between paired data
transparency = 0.5;  % Transparency for zero data bubbles

idx2 = 1; idx1 = 1;
% Plot each pair of data

for i = 1:numPairs
    % Get the current pair data
    pairData = clusterSum{i};
    
    % Plot each bubble in the pair
    for j = 1:2
        
        % Get the x and y coordinates for the bubbles
        x = (i-1) * largeGap + j * smallGap + (i-1) * smallGap;
        xtickLoc(idx2,1) = x;
        idx2 = idx2 + 1;
        y = (1:size(pairData, 1))'; 
        
        % Get the bubble sizes and transparency
        sizes = pairData(:, j) * 0.03; % Scale down the sizes for better visualization
        sizes(pairData(:, j) == 0) = smallBubbleSize;
        alphaData = ones(size(sizes));
        
        % Plot the bubbles
        s = scatter(repmat(x, size(pairData, 1), 1), y, sizes, 'MarkerFaceColor', colorTemp(idx1, :), 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 'flat', 'AlphaData', alphaData);
        s.MarkerFaceAlpha = 0.8;
        idx1 = idx1 + 1;
    end
end

xtickLoct = unique(xtickLoc);
tickLabel ={'Amygdala Emotion'
'Amygdala Identity'
'Anterior Hippocampus Emotion'
'Anterior Hippocampus Identity'
'Posterior Hippocampus Emotion'
'Posterior Hippocampus Identity'};
% Set the x-axis labels

set(gca, 'XTick', xtickLoct, 'XTickLabel', tickLabel);

% Add labels and title
ylabel('Electrode Count');
title('Electrodes with High Gamma Activity During Each Task');

% Adjust the limits
xlim([0 xtickLoct(end)+0.2]);
ylim([0 (max(cellfun(@(x) size(x, 2), pairedChannels))) + 2]);

hold off;

Gc = gca;
Gc.FontSize = 22;
Gc.XTickLabelRotation = 45;
Gc.Title.FontSize = 22;


