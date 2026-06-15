function [congspkSm, incongspkSm, congMean, incongMean, congSE, incongSE, congSpk, incongSpk] = conditionParsing(spk, taskData, endTrials)
   
% a simple script for parsing the conditions

flds = fields(taskData);




    for jj = 1:size(spk.spkRateSm,1)
        congspkSm{jj,1} = spk.spkRateSm{jj}(taskData.Condition(1:endTrials) == 1,:);
        incongspkSm{jj,1} = spk.spkRateSm{jj}(taskData.Condition(1:endTrials) == 2,:);
        congSpk{jj,1} = spk.spk{jj}(taskData.Condition(1:endTrials) == 1,:);
        incongSpk{jj,1} = spk.spk{jj}(taskData.Condition(1:endTrials) == 2,:);
        %now break up into responses so response to 1 is in cell 2, etc to
        %response 3. currently flds(6) is response, can do what it was
        %supposed to be as well although accuracy is generally high.
        for kk = 1:3
            congspkSm{jj,kk+1} = spk.spkRateSm{jj}(taskData.Condition(1:endTrials) == 1 & taskData.ResponseKey(1:endTrials) == kk,:);
            incongspkSm{jj,kk+1} = spk.spkRateSm{jj}(taskData.Condition(1:endTrials) == 2 & taskData.ResponseKey(1:endTrials) == kk,:);
            congSpk{jj,kk+1} = spk.spk{jj}(taskData.Condition(1:endTrials) == 1 & taskData.ResponseKey(1:endTrials) == kk,:);
            incongSpk{jj,kk+1} = spk.spk{jj}(taskData.Condition(1:endTrials) == 2 & taskData.ResponseKey(1:endTrials) == kk,:);
        end
        for kk = 1:4
            congMean{1,kk}(jj,:) = mean(congspkSm{jj,kk}); %mean
            congSE{1,kk}(jj,:) = std(congspkSm{jj,kk})/sqrt((size(congspkSm{jj,kk},1))); %se
            incongMean{1,kk}(jj,:) = mean(incongspkSm{jj,kk}); %mean
            incongSE{1,kk}(jj,:) = std(incongspkSm{jj,kk})/sqrt((size(incongspkSm{jj,kk},1))); %se
        end
    end
end

