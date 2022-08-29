NumSamp = 1000;
low_i = floor(0.5 * NumSamp);
high_i = ceil(0.95 * NumSamp);


ThetaLogical  = FreqBins > 4  & FreqBins < 8;
AlphaLogical  = FreqBins > 8  & FreqBins < 12;
BetaLogical   = FreqBins > 12 & FreqBins < 30;
LGammaLogical = FreqBins > 30 & FreqBins < 80;
HGammaLogical = FreqBins > 80 & FreqBins < 200;
FreqLog = gpuArray(logical([ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical]));
fb = size(FreqLog, 1);
tb = size(PowerArray, 1);
ch = size(PowerArray, 3);

LTTrialsIdx = targetsT2 == 6 | targetsT2 == 7 | targetsT2 == 8;
RTTrialsIdx = targetsT2 == 2 | targetsT2 == 3 | targetsT2 == 4;
NotAvailIdx = gpuArray(~(LTTrialsIdx | RTTrialsIdx));

PA_lr_trials = gpuArray(PowerArray(:,:,:,~NotAvailIdx));
listlength = size(PA_lr_trials, 4);


lsampleidx = logical(gpuArray.zeros(listlength, 1));
rsampleidx = logical(gpuArray.zeros(listlength, 1));


%------------Method 1-------------------

mean_diff_low = zeros(tb, ch, fb);
mean_diff_high = zeros(tb, ch, fb);
t_val_low = zeros(tb, ch, fb);
t_val_high = zeros(tb, ch, fb);
% accum_mean_diff = cell(fb, 1);
% accum_sample_var = cell(fb, 1);
% accum_t_val = cell(fb, 1);

for f = 1:fb
    fb_array = PA_lr_trials(:, FreqLog(f,:), :, :);
    fb_array = permute(fb_array, [1 3 2 4]);
    %sample_var = gpuArray.zeros(tb, ch, NumSamp);
    sample_mean_diffs = gpuArray.zeros(tb, ch, NumSamp);
    sample_t_val = gpuArray.zeros(tb, ch, NumSamp);

    tic
    for i = 1:NumSamp
        lsampleidx = gpuArray(logical(randi(2, listlength, 1) - 1));
        %rsampleidx = logical(randi(2, listlength, 1) - 1);
        rsampleidx = gpuArray(~lsampleidx);
        num_L = sum(lsampleidx);
        num_R = sum(rsampleidx);
        
        lsamples = fb_array(:, :, :, lsampleidx);
        ur_lsamples = lsamples(:,:,:);
        lsample_mean = squeeze(mean(ur_lsamples, 3));

        
        rsamples = fb_array(:, :, :, rsampleidx);
        ur_rsamples = rsamples(:,:,:);
        rsample_mean = squeeze(mean(ur_rsamples, 3));

        
%         md =  rsample_mean - lsample_mean;
        md =  abs(rsample_mean - lsample_mean); % difference of group means
        sample_mean_diffs(:, :, i) = md;
        L_md_sq = (ur_lsamples - lsample_mean) .^2;
        sum_L_md_sq = sum(L_md_sq, 3);
        R_md_sq = (ur_rsamples - rsample_mean) .^2;
        sum_R_md_sq = sum(R_md_sq, 3);
        sv = (sum_R_md_sq + sum_L_md_sq) ./ (num_R + num_L - 2); %sample variance equation
        %sample_var(:, :, i) = sv;
%         sample_t_val(:, :, i) = md ./ sqrt((sv./num_R) + (sv./num_L));
        sample_t_val(:, :, i) = abs(md ./ sqrt((sv./num_R) + (sv./num_L))); %t-test equation

    end
    toc


    smd_sort = gather(sort(sample_mean_diffs, 3));
    mean_diff_low(:, :, fb) = smd_sort(:, :, low_i);
    mean_diff_high(:, :, fb) = smd_sort(:, :, high_i);
    stv_sort = gather(sort(sample_t_val, 3));
    t_val_low(:, :, fb) = stv_sort(:, :, low_i);
    t_val_high(:, :, fb) = stv_sort(:, :, high_i);
end

gather(FreqLog, NotAvailIdx, lsampleidx, rsampleidx, PA_lr_trials, sample_var);
clear FreqLog NotAvailIdx lsampleidx rsampleidx PA_lr_trials sample_var smd_sort stv_sort

% rand_idx = randi(59, 2);
% t = rand_idx(1);
% c = rand_idx(2);
% figure
% hist(squeeze(sample_mean_diffs(t, c, :)), 100);
% ts = sprintf('Fband (%d) Tbin (%d) Ch (%d) mean-diff', f, t, c);
% title(ts)
% figure
% hist(squeeze(sample_var(t, c, :)), 100);
% ts = sprintf('Fband (%d) Tbin (%d) Ch (%d) sample-var', f, t, c);
% title(ts)
% figure
% hist(squeeze(sample_t_val(t, c, :)), 100);
% ts = sprintf('Fband (%d) Tbin (%d) Ch (%d) sample-t-val', f, t, c);
% title(ts)
% accum_mean_diff(f) = sample_mean_diffs;
% accum_sample_var(f) = sample_var;
% accum_t_val(f) = sample_t_val;




