function [Means_CIs_Left, Means_CIs_Right] = shuffleCI(LTSpecs, RTSpecs, NumSamp, FreqBins)
    ThetaLogical  = FreqBins > 4  & FreqBins < 8;
    AlphaLogical  = FreqBins > 8  & FreqBins < 12;
    BetaLogical   = FreqBins > 12 & FreqBins < 30;
    LGammaLogical = FreqBins > 30 & FreqBins < 80;
    HGammaLogical = FreqBins > 80 & FreqBins < 200;
    FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
    tb = size(LTSpecs, 1);
    chb = size(LTSpecs, 3);
    
    bound = 0.05 * NumSamp;

    Means_LTargs_FBands = zeros(tb, chb, 5);
    CI_Low_LTargs_FBands = zeros(tb, chb, 5);
    CI_High_LTargs_FBands = zeros(tb, chb, 5);
    Means_RTargs_FBands = zeros(tb, chb, 5);
    CI_Low_RTargs_FBands = zeros(tb, chb, 5);
    CI_High_RTargs_FBands = zeros(tb, chb, 5);
    Sample_Var = zeros(tb, chb, 5);
    Means_CIs_Left = cell(3,1);
    Means_CIs_Right = cell(3,1);
    for f = 1:5
        % Left Target Trials
        fb_lspecs = LTSpecs(:,FreqLog(f,:),:,:); % 59 fb 60 LTtrials
        fb_lspecs = permute(fb_lspecs, [1 3 2 4]);% 59 60 fb LTtrials
        fb_lspecs = fb_lspecs(:,:,:);% 59 60 fb*numLTtrials
        idx_size = size(fb_lspecs, 3);
        samp_avg_mat_l = zeros(size(fb_lspecs, 1), size(fb_lspecs, 2), NumSamp);
        parfor i = 1:NumSamp
            rand_idx = randi(idx_size, 1, size(fb_lspecs, 3));%size(fb_lspecs, 1), size(fb_lspecs, 2));
            new_mat = fb_lspecs(:, :, rand_idx);
            samp_avg_mat_l(:,:,i) = mean(new_mat, 3);
        end
        fprintf('Left Trials Fband: %d \n', f);
        fb_L_means = mean(samp_avg_mat_l, 3);
        sorted_mat = sort(samp_avg_mat_l, 3);
        fb_L_CI_Low = sorted_mat(:,:, bound);
        fb_L_CI_High = sorted_mat(:,:, end-bound);

        % Right Target Trials
        fb_rspecs = RTSpecs(:,FreqLog(f,:),:,:); % 59 fb 60 numRTtrials
        fb_rspecs = permute(fb_rspecs, [1 3 2 4]);% 59 60 fb numRTtrials
        fb_rspecs = fb_rspecs(:,:,:);% 59 60 fb*numRTtrials
        idx_size = size(fb_rspecs, 3);

        samp_avg_mat_r = zeros(size(fb_rspecs, 1), size(fb_rspecs, 2), NumSamp);
        parfor i = 1:NumSamp
            rand_idx = randi(idx_size, 1, size(fb_rspecs, 3));
            new_mat = fb_rspecs(:, :, rand_idx);
            samp_avg_mat_r(:,:,i) = mean(new_mat, 3);
        end
        % --- plot random tbin and ch histogram of resamples to verify ---
%         fig_idx = randi(tb, 1, 2);
        t_bin = randi(tb, 1);
        ch_bin = randi(chb, 1);
        figure('position', [-1919 121 1920 1083])
        subplot(1,2,1)
        hist(squeeze(samp_avg_mat_l(t_bin, ch_bin, :)), 100)
        ts = sprintf('Left Tr Fband (%d) Tbin (%d) Ch (%d)', f, t_bin, ch_bin);
        title(ts)
        fprintf('Right Trials Fband: %d \n', f);
        subplot(1,2,2)
        hist(squeeze(samp_avg_mat_r(t_bin, ch_bin, :)), 100)
        ts = sprintf('Right Tr Fband (%d) Tbin (%d) Ch (%d)', f, t_bin, ch_bin);
        title(ts)
        % --- end verification plot ---
        
        fb_R_means = mean(samp_avg_mat_r, 3);
        sorted_mat = sort(samp_avg_mat_r, 3);
        fb_R_CI_Low = sorted_mat(:,:, bound);
        fb_R_CI_High = sorted_mat(:,:, end-bound);
        
        %Sample Variance
        mean_diff_L = (samp_avg_mat_l - fb_L_means) .^ 2;
        sum_md_L = sum(mean_diff_L, 3);
        mean_diff_R = (samp_avg_mat_r - fb_L_means) .^ 2;
        sum_md_R = sum(mean_diff_R, 3);
        Sample_Var(:,:,f) = (sum_md_L + sum_md_R) ./ ((2*NumSamp) - 2);
        
        


        Means_LTargs_FBands(:, :, f) = fb_L_means;
        CI_Low_LTargs_FBands(:, :, f) = fb_L_CI_Low;
        CI_High_LTargs_FBands(:, :, f) = fb_L_CI_High;
        Means_RTargs_FBands(:, :, f) = fb_R_means;
        CI_Low_RTargs_FBands(:, :, f) = fb_R_CI_Low;
        CI_High_RTargs_FBands(:, :, f) = fb_R_CI_High;
    end %end frequency for loop
    
    Means_CIs_Left{1} = Means_LTargs_FBands;
    Means_CIs_Left{2} = CI_Low_LTargs_FBands;
    Means_CIs_Left{3} = CI_High_LTargs_FBands;
    
    Means_CIs_Right{1} = Means_RTargs_FBands;
    Means_CIs_Right{2} = CI_Low_RTargs_FBands;
    Means_CIs_Right{3} = CI_High_RTargs_FBands;
    
    
    %Sample Variance

end %end function