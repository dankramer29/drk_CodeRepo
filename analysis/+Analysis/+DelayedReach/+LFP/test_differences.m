function [exp_diffs, chann_name] = test_differences(diff_func, Ltrial_array, Rtrial_array, chan_num)
   num_f_bin = size(Ltrial_array, 3);
   exp_diffs = cell(num_f_bin,1);
   for i = 1:num_f_bin
       exp_diffs{i} = diff_func(Ltrial_array(:,chan_num,i), Rtrial_array(:,chan_num,i));
   end
   chann_name = string(chan_num);
end