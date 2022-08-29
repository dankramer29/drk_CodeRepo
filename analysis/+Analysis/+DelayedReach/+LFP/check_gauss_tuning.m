function [band_tuning, varargout] = check_gauss_tuning(chan_targ_vals)
    
    chan_range = size(chan_targ_vals, 1);
    num_targs = size(chan_targ_vals, 2);
    temp_t = (1:num_targs);
    ft = fittype( 'gauss1' );
    opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
    opts.Display = 'Off';
    opts.Lower = [-500 -100 0];
    temp_shifted_power = zeros(chan_range, num_targs);
    temp_shifted_targets = zeros(chan_range, num_targs);
    temp_shifted_amt = zeros(chan_range, 2);
    temp_tuned_targ = zeros(chan_range, 1);
    temp_sse = zeros(chan_range, 1);
    temp_rsquare = zeros(chan_range, 1);
    temp_dfe = zeros(chan_range, 1);
    temp_adjrsquare = zeros(chan_range, 1);
    temp_rmse = zeros(chan_range, 1);
    temp_excluded = zeros(chan_range,num_targs);
    fit_result = cell(chan_range, 1);
    for chan = 1:chan_range
        temp_y = chan_targ_vals(chan,:);
        
        %check and remove outliers, record which target was removed
        [Oidx,~,~,~] = util.outliers(temp_y);
        excl = zeros(1,num_targs);
        if ~isempty(Oidx)
            temp_y(Oidx) = 0;
            excl(1,Oidx) = 1;
        end
        temp_excluded(chan,:) = excl;
        
        % shift values so that everything is positive, record shift amount
        % to reverse shift the curve when plotting
        shift_y = 0;
        if any(temp_y < 0)
            shift_y = min(temp_y);
            temp_y = temp_y + abs(shift_y);
        end
                
        [temp_s, temp_col] = max(temp_y);
        opts.StartPoint = [temp_s 4 2.4495];
        temp_shiftamt = 4 - temp_col;
        temp_shiftedy = circshift(temp_y, temp_shiftamt); % get the max value at 4
        temp_shiftedx = circshift(temp_t, temp_shiftamt); % shift target values same amt for later retrieval
        [temp_xData, temp_yData] = prepareCurveData(temp_t, temp_shiftedy);

%         [Oidx,~,~,~] = util.outliers(temp_yData);
%         excludedPoints = excludedata(temp_xData, temp_yData, 'Indices', Oidx);
%         opts.Exclude = excludedPoints; % fitoptions(fitresult{}).Exclude
        [temp_fitr, goodf] = fit(temp_xData, temp_yData, ft, opts);
        temp_sse(chan,1) = goodf.sse; temp_rsquare(chan,1) = goodf.rsquare;
        temp_dfe(chan,1) = goodf.dfe; temp_adjrsquare(chan,1) = goodf.adjrsquare;
        temp_rmse(chan,1) = goodf.rmse;
        fit_result{chan,1} = temp_fitr;
        temp_shifted_power(chan,:) = temp_shiftedy;
        temp_shifted_targets(chan,:) = temp_shiftedx;
        temp_shifted_amt(chan,:) = [temp_shiftamt shift_y];
        temp_tuned_targ(chan,:) = temp_fitr.b1 - temp_shiftamt;
%         temp_excluded(chan,:) = opts.Exclude;
    end
    
    band_tuning.fit_result = fit_result;

    band_tuning.gof = struct( 'sse', temp_sse, 'rsquare', temp_rsquare, 'dfe', temp_dfe,...
        'adjrsquare', temp_adjrsquare, 'rmse', temp_rmse, 'excluded', temp_excluded);
    band_tuning.shifts = struct( 'shifted_power', temp_shifted_power, ...
        'shifted_targets', temp_shifted_targets, 'shift_amt', temp_shifted_amt, 'tuned_targ', temp_tuned_targ);
    
    if nargout > 1
        varargout{1} = temp_rsquare;
    end

end