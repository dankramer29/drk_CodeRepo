function [ statsT, split_corrT, fitresults, gof ] = jnd_2to100( freq, varargin )
%jnd_2to100 calculates the percent correct and the difference in
%stimulations
%   Input
%            freq=   3 columns, left freq, right freq, and correct or incorrect (1 or 0)
%Example:
% [ statsT, split_corrT, fitresults, gof ] = Analysis.JND.jnd_2to100( freqEM );

%


%remove rows
%remember to start subtraction 1 after the last one, so if 57, subtract 58:100
[varargin,row_remove] = util.argkeyval('row_remove',varargin,[]);
[varargin,categories] = util.argkeyval('categories',varargin,10); %the categories of split, set to be bins of 10
freq(row_remove,:)=[];
categories=10;

%remove empty rows

freq(isnan(freq(:,3)),:)=[];

split_corr=[];

%check percentage correct for 10hz or less, then bins of 10Hz after that
%this doesn't work well for the 2 to 100 (despite the name) but should for
%the other categories.
idx=1;
for min_freq=min(freq(:,1))+categories:categories:100   %look at the categories, but ignore the first one since all are over that
%for min_freq=categories:categories:100   
    
    idx1=1; idx2=1;
    for ii=1:length(freq)
        %capturing trials only when both are over some frequency, so if one
        %is over the min_freq, it goes into the less category, the delta
        %will capture the rest
        if freq(ii,1)> min_freq && freq(ii,2) > min_freq
            gr_freq(idx1,:)=freq(ii,:);
            idx1=idx1+1;
            if min_freq==40 %at 40, split them completely, can be chnged to 30 to see if that changes it.
                
                freq_gThreshold=gr_freq; %keep those above 40 to add to the above 40 only spot
            end
        else
            ls_freq(idx2,:)=freq(ii,:);
            idx2=idx2+1;
            if min_freq==40
                freq_lsThreshold=ls_freq;
            end
        end
        
    end
    split_corr(idx,2)=nnz(gr_freq(:,3))/length(gr_freq); %percentage correct of the greater frequency
    split_corr(idx,3)=nnz(ls_freq(:,3))/length(ls_freq); %percentage correct of the ls frequency
    temp_table=[nnz(gr_freq(:,3)),  nnz(ls_freq(:,3)); length(gr_freq(:,3))-nnz(gr_freq(:,3)), length(ls_freq(:,3))-nnz(ls_freq(:,3))];
    [split_corr(idx,4), split_corr(idx,5), sts]=fishertest(temp_table); %find out if they are different
    split_corr(idx,6)=sts.OddsRatio; split_corr(idx,7:8)=sts.ConfidenceInterval;
    split_corr(idx,1)=min_freq; %list which frequency it is
    idx=idx+1;
end

delta=[]; stats=[]; 
gof=cell(3);
fitresults=cell(3);

%check the percentage correct per delta 
freq(:,4)=freq(:,1)-freq(:,2); %get delta
tempP=freq(freq(:,4)>0, 3);
tempN=freq(freq(:,4)<0, 3);
tble=[nnz(tempP),  nnz(tempN); length(tempP)-nnz(tempP), length(tempN)-nnz(tempN)];
[stats(:,5), stats(:,6)]=fishertest(tble); %check that there is no difference in ones that came first and came second, this should really be all you need, and no need to graph in the future.

idx=1;
for min_freq=categories:categories:80
    %includes pos and negative values
    stats(idx,1)=min_freq;
    %go through categories of frequencies
    tempBelow=freq(abs(freq(:,4))>min_freq-categories & abs(freq(:,4)) <= min_freq,:);
    %tempAbove=freq(abs(freq(:,4)) > min_freq,:);
    stats(idx,2)=nnz(tempBelow(:,3))/size(tempBelow,1); %find the perc correct
    temp_n=tempBelow(tempBelow(:,4)<0,:);
    stats(idx,3)=nnz(temp_n(:,3))/size(temp_n,1);
    temp_p=tempBelow(tempBelow(:,4)>0,:);
    stats(idx,4)=nnz(temp_p(:,3))/size(temp_p,1);
    
    %%split by 
    idx=idx+1;
end




%shows the stats of percent correct when both frequencies low or both high
statsT=table(stats(:,1), stats(:,2), stats(:,3), stats(:,4), stats(:,5), stats(:,6), 'VariableNames', {'Category', 'Percent_correct', 'Percent_correct_negative', 'Percent_correct_positive', 'pValue_PosvNeg', 'pvalue'});
split_corrT=table(split_corr(:,1), split_corr(:,2), split_corr(:,3), split_corr(:,4), split_corr(:,5), split_corr(:,6), split_corr(:,7:8),...
    'VariableNames', {'freq_category', 'per_greaterfreq', 'per_lessfreq', 'fishertest', 'pvalue', 'OR', 'CI' });
stats=stats(~isnan(stats(:,3)),:);
[fitresults{1},gof{1}] = Analysis.JND.fitPsych2AFC(stats(:,1), stats(:,2));
[fitresults{2},gof{2}] = Analysis.JND.fitPsych2AFC(stats(:,1), stats(:,3));
[fitresults{3},gof{3}] = Analysis.JND.fitPsych2AFC(stats(:,1), stats(:,4));

figure
subplot(3,1,1)
plot(fitresults{1}, statsT.Category, statsT.Percent_correct, 'o')
ylabel('')
xlabel('')
xlim([10 80])
ylim([0.2 1])
title('Correct responses in first frequency and second frequency')
subplot(3,1,2)
plot(fitresults{2}, statsT.Category, statsT.Percent_correct_negative, 'o')
ylabel('Percent correct')
xlabel('')
xlim([10 80])
ylim([0.2 1])
title('Negative deltas', 'FontWeight', 'normal')
subplot(3,1,3)
plot(fitresults{3}, statsT.Category, statsT.Percent_correct_positive, 'o')
ylabel('')
xlabel('Difference in first and second frequencies (Hz)')
xlim([10 80])
ylim([0.2 1])
title('Positive deltas', 'FontWeight', 'normal')


% figure
% hold on
% plot(fitresults{1}, statsT.Category, statsT.Percent_correct, 'o')
% plot(fitresults{2}, statsT.Category, statsT.Percent_correct_negative, 'o')
% plot(fitresults{3}, statsT.Category, statsT.Percent_correct_positive, 'o')
% xlabel('Difference in first and second frequencies (Hz)')
% ylabel('Percent correct')
% legend('Difference', 'Lower freq first', 'Higher freq first')
% xlim([0 80])
% title('Correct responses in first frequency and second frequency')

end

