function [Mean_CIs] = resampleCI_single(PowerArray, Targets, NumSamp, FreqBins, specific_target, varargin)
    
    [varargin, FBand, ~, FBand_found]=util.argkeyval('FBand', varargin, []);
    [varargin, Channels, ~, ~]=util.argkeyval('Channels', varargin, 1:size(PowerArray,3));
    
    if FBand_found
        num_f_band = 1;
        switch FBand
            case 'theta'
                flo = 4;
                fhi = 8;
            case 'alpha'
                flo = 8;
                fhi = 12;
            case 'beta'
                flo = 12;
                fhi = 30;
            case 'low gamma'
                flo = 30;
                fhi = 80;
            case 'high gamma'
                flo = 80;
                fhi = 200;
        end
        Frequency_idx = FreqBins > flo  & FreqBins < fhi;

    elseif ~FBand_found
        ThetaLogical  = FreqBins > 4  & FreqBins < 8;
        AlphaLogical  = FreqBins > 8  & FreqBins < 12;
        BetaLogical   = FreqBins > 12 & FreqBins < 30;
        LGammaLogical = FreqBins > 30 & FreqBins < 80;
        HGammaLogical = FreqBins > 80 & FreqBins < 200;
        Frequency_idx = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
        
    end
    
    
    util.argempty(varargin);
    bound = 0.05 * NumSamp;
    
%     Means_LTargs_FBands = zeros(tb, chb, 5);
%     CI_Low_LTargs_FBands = zeros(tb, chb, 5);
%     CI_High_LTargs_FBands = zeros(tb, chb, 5);
%     
    Mean_CIs = cell(3,1);
    
    trial_idx = Targets == specific_target;
    
    Sub_PA = PowerArray(:, Frequency_idx, Channels, trial_idx);
    
    
    for f = 1:num_f_band
        % Left Target Trials
        unroll_specs = Sub_PA(:,:); % 59 fb 60 LTtrials
        idx_size = size(unroll_specs, 2);
        samp_avg_mat_l = zeros(size(unroll_specs, 1), NumSamp);
        for i = 1:NumSamp
            rand_idx = randi(idx_size, 1, size(unroll_specs, 2));%size(fb_lspecs, 1), size(fb_lspecs, 2));
            new_mat = unroll_specs(:, rand_idx);
            samp_avg_mat_l(:,i) = mean(new_mat, 2);
        end
        means = mean(samp_avg_mat_l, 2);
        sorted_mat = sort(samp_avg_mat_l, 2);
        CI_Low = sorted_mat(:, bound);
        CI_High = sorted_mat(:, end-bound);
    end
    Mean_CIs{1} = means;
    Mean_CIs{2} = CI_Low;
    Mean_CIs{3} = CI_High;
end