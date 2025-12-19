function [Qsh] = shuffleTangling(spk, taskData, endTrials, varargin)
% take the spks and shuffle the tangling so that it is tanngling within
% condition
% inputs:
% the output from conditionParsing, the taskdata and the endtrials

[varargin, qshuffles]=util.argkeyval('qshuffles', varargin, 100); %how many shuffles to do
[varargin, tt]=util.argkeyval('tt', varargin, []); %the times
[varargin, analyzett]=util.argkeyval('analyzett', varargin, []); %the time period to analyze tangling between

%create the structs with times input (if blank should just analyze all)
condDataTempC(1).times = tt;
condDataTempC(2).times = tt;
condDataTempI(1).times = tt;
condDataTempI(2).times = tt;
condDataTempC(1).analyzeTimes = analyzett;
condDataTempC(2).analyzeTimes = analyzett;
condDataTempI(1).analyzeTimes = analyzett;
condDataTempI(2).analyzeTimes = analyzett;

%break the data up into the conditions

congTrialNum = size(spk.cong{1},1);
incongTrialNum = size(spk.incong{1},1);
warning('off', 'stats:pca:ColRankDefX');
for ii = 1:qshuffles
    r1 = randperm(congTrialNum);
    r2 = randperm(incongTrialNum);
    hlfR1 = round(length(r1)/2);
    hlfR2 = round(length(r2)/2);
    for jj = 1:length(spk.spkRateSm)        
        dataCtemp1(:,jj) = mean(spk.cong{jj}(r1(1:hlfR1),:)); %create two arbitrarily separated conditions to run tangling between
        dataCtemp2(:,jj) = mean(spk.cong{jj}(r1(hlfR1+1:end),:));

        dataItemp1(:,jj) = mean(spk.incong{jj}(r2(1:hlfR2),:));
        dataItemp2(:,jj) = mean(spk.incong{jj}(r2(hlfR2+1:end),:));
    end
    condDataTempC(1).A = dataCtemp1;
    condDataTempC(2).A = dataCtemp2;
    condDataTempI(1).A = dataItemp1;
    condDataTempI(2).A = dataItemp2;
    [Qsh.cong(ii,:)] = tangleAnalysis(condDataTempC, .001, 'softenNorm', 5); % for data collected at 1kHz
    [Qsh.incong(ii,:)] = tangleAnalysis(condDataTempI, .001, 'softenNorm', 5); % for data collected at 1kHz

end

Qsh.mxCong(:,1) = max(Qsh.cong, [], 2);
Qsh.mxIncong(:,1) = max(Qsh.incong, [], 2);
Qsh.meanCong = mean(Qsh.mxCong);
Qsh.medianCong = median(Qsh.mxCong);
Qsh.meanIncong = mean(Qsh.mxIncong);
Qsh.medianIncong = median(Qsh.mxIncong);

warning('on', 'stats:pca:ColRankDefX');


end


