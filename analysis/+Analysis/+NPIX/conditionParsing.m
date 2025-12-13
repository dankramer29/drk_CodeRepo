function [congspkSm, incongspkSm, congMean, incongMean, congSE, incongSE, congSpk, incongSpk] = conditionParsing(spk, taskData, endTrials)
   
% a simple script for parsing the conditions

for jj = 1:size(spk.spkRateSm,1)
    congspkSm{jj,1} = spk.spkRateSm{jj}(taskData.Condition(1:endTrials) == 1,:);
    incongspkSm{jj,1} = spk.spkRateSm{jj}(taskData.Condition(1:endTrials) == 2,:);
    congSpk{jj,1} = spk.spk{jj}(taskData.Condition(1:endTrials) == 1,:);
    incongSpk{jj,1} = spk.spk{jj}(taskData.Condition(1:endTrials) == 2,:);
    congMean(jj,:) = mean(congspkSm{jj}); %mean
    congSE(jj,:) = std(congspkSm{jj})/sqrt((size(congspkSm{jj},1))); %se
    incongMean(jj,:) = mean(incongspkSm{jj}); %mean
    incongSE(jj,:) = std(incongspkSm{jj})/sqrt((size(incongspkSm{jj},1))); %se
end
end

