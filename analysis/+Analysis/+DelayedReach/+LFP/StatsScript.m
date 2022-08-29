%%
% Process anovas of the spectrogram for each location combination for each
% channel. Returns PValues, an array = TimeBins x FreqBins x Channels x 28
% which is the # of unique combinations of 2 locations. 
% Currently takes ~ 30 minutes on 159x52x76x55 double 

Tbins = size(TestSpecgram, 1);
Fbins = size(TestSpecgram, 2);
Chs = size(TestSpecgram, 3);
%Trs = size(Specs, 4);



% for testing speed
% Tbins = 10;
% Fbins = 10;
% Chs = 10;


%%
% Statistical calculation loop

% pre allocate
% PValues = zeros(Tbins, Fbins, Chs, 28); % 28 = permutation of 8 location comparisons
TestPValues = zeros(28, Tbins, Fbins, Chs);
SpecsPermute = permute(TestSpecgram, [4 1 2 3]);
%start timer
TotalStart = tic;

% Loop over every time bin, frequency bin and channel. The Comparison Table
% output by multcompare gives the group combinations and corresponding
% confidence intervals, means, and p values. Only the p values are
% collected. 
parfor t = 1:Tbins
    for f = 1:Fbins
         for c = 1:Chs
            [~, ~, AnovaStats] = anova1(SpecsPermute(:,t,f,c), TestTargets, 'off');
            CompTable = multcompare(AnovaStats, 'Display', 'off');
            TestPValues(:,t,f,c) = CompTable(:,6);
        end % end channel loop
    end % end frequency bins loop
end % end time bins loop


TotalStop = toc(TotalStart);
fprintf('Total time elapsed %d seconds\n', TotalStop)
TTimeAverage = TotalStop/Tbins;

TestPValues = permute(TestPValues, [2 3 4 1]);

% Variable Clean Up
clear Chs Trs t f c FStart Fstop TotalStart TotalStop


%%
% Group channels from L Parietal and R parietal, take channel average for
% each location. Run anova+multcompare for each target location
LParietalChans = Specs(:,:,61:68,:);
RParietalChans = Specs(:,:,69:76,:);
LParietalChanAvg = mean(LParietalChans,3); %159x52x1x55
RParietalChanAvg = mean(RParietalChans,3); %159x52x1x55
LandR = cat(3, LParietalChanAvg, RParietalChanAvg); % 159x52x2x55 ch 1 = L Par. ch 2 = R Par.
LandR = permute(LandR, [4 1 2 3]);

Chs = 2;
ParietalPValues = zeros(28, Tbins, Fbins, Chs);

for t = 1:Tbins
    for f = 1:Fbins
         for c = 1:Chs
            [~, ~, AnovaStats] = anova1(LandR(:,t,f,c), Targets, 'off');
            CompTable = multcompare(AnovaStats, 'Display', 'off');
            ParietalPValues(:,t,f,c) = CompTable(:,6);
        end % end channel loop
    end % end frequency bins loop
end % end time bins loop

Oct27LandRP = ParietalPValues(17,:,1:30,:); % Anova P Values. Row 17 is comparing targets 3 to 7.
Oct27LandRP = permute(Oct27LandRP, [2 3 4 1]);

%%
% find significant p value regions
PValNew = permute(PValues, [2 3 4 1]);
PVals = PValNew;

TimeBins = size(PVals, 1);
%FreqBins = 1:200; 
FreqBins = size(PVals, 2);
NumChannels = size(PVals, 3);
CompRows = size(PVals, 4); %Rows in the comparison table from multcompare above

NumberSignificant = zeros(CompRows, NumChannels); % table with a value for each Channel comparison across all time and frequencies specified

for Ch = 1:NumChannels
    for Row = 1:CompRows
        NumberSignificant(Row, Ch) = size(find(PVals(:,:,Ch,Row) < 0.05), 1);
    end
end

clear Ch Row TimeBins FreqBins NumChannels CompRows PVals PValNew