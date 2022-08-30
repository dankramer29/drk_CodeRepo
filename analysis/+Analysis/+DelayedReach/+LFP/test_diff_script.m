%%

% run script up to line 234, Spec average gen
%  Left Targets = 8, 7, 6
%  Right targets = 2, 3, 4

% a = char(string(log10(0.0869)))
% 
% a =
% 
%     '-1.061'
% 
% a(1) == '-'
% function plot_test_differences(test_differences, chan_str, func_str, test_ID)

%%

avail_channels = 1:60;
avail_channels(30) = [];
test_channel_indx = randperm(length(avail_channels));


%% Function 1


test_func1 = @(right,left) ((right - left) ./ (right + left));
tf1_str = '@(right,left) ((right - left) ./ (right + left))';

[tdiff_1, tchan_1] = Analysis.DelayedReach.LFP.test_differences(test_func1, LTAvgSpecs_Favg, RTAvgSpecs_Favg, test_channel_indx(1));

Analysis.DelayedReach.LFP.plot_test_differences(tdiff_1, tchan_1, tf1_str, 'f1-Ch-a')


[tdiff_1, tchan_1] = Analysis.DelayedReach.LFP.test_differences(test_func1, LTAvgSpecs_Favg, RTAvgSpecs_Favg, test_channel_indx(2));

Analysis.DelayedReach.LFP.plot_test_differences(tdiff_1, tchan_1, tf1_str, 'f1-Ch-b')

% try 10*log10 of the values

tf1_str = '@(r,l) ((r - l) ./ (r + l))  r = 10*log10(right) l = 10*log10(left)';

[tdiff_1, tchan_1] = Analysis.DelayedReach.LFP.test_differences(test_func1, 10*log10(LTAvgSpecs_Favg), 10*log10(RTAvgSpecs_Favg), test_channel_indx(1));
Analysis.DelayedReach.LFP.plot_test_differences(tdiff_1, tchan_1, tf1_str, 'f1-Ch-a-10log')

% scaling everything prior to getting proportion just makes diff narrower

[tdiff_1, tchan_1] = Analysis.DelayedReach.LFP.test_differences(test_func1, 10*log10(LTAvgSpecs_Favg), 10*log10(RTAvgSpecs_Favg), test_channel_indx(2));
Analysis.DelayedReach.LFP.plot_test_differences(tdiff_1, tchan_1, tf1_str, 'f1-Ch-b-10log')


%% Function 2

test_func1 = @(right,left) (abs(right - left) ./ abs(right + left));
tf1_str = '@(right,left) (abs(right - left) ./ abs(right + left))';

[tdiff_1, tchan_1] = Analysis.DelayedReach.LFP.test_differences(test_func1, LTAvgSpecs_Favg, RTAvgSpecs_Favg, test_channel_indx(1));
Analysis.DelayedReach.LFP.plot_test_differences(tdiff_1, tchan_1, tf1_str, 'f2-Ch-a')

tf1_str = '@(right,left) (abs(right - left) ./ abs(right + left)) *10log10()';
[tdiff_1, tchan_1] = Analysis.DelayedReach.LFP.test_differences(test_func1, 10*log10(LTAvgSpecs_Favg), 10*log10(RTAvgSpecs_Favg), test_channel_indx(1));
Analysis.DelayedReach.LFP.plot_test_differences(tdiff_1, tchan_1, tf1_str, 'f2-Ch-a-10log')


%%
ch30_change = ones(59,5);
LTAvgSpecs_Favg(:, 30, :) = ch30_change;
RTAvgSpecs_Favg(:, 30, :) = ch30_change;

New_LTAv = zeros(size(LTAvgSpecs_Favg);
New_RTAv = zeros(size(LTAvgSpecs_Favg);

%%

for f = 1:5
    fs = sprintf('f%d', f);
    figure('Name', fs,'position', [-1794 351 1675 610])
    lt = squeeze(LTAvgSpecs_Favg(:,:,f));
    lt = lt(:);
    rt = squeeze(RTAvgSpecs_Favg(:,:,f));
    rt = rt(:);
    subplot(1,2,1)
    hist(lt, 100)
    title('left')
    subplot(1,2,2)
    hist(rt, 100)
    title('right')
end