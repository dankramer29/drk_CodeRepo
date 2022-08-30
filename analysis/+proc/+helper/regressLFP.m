function [rdata,fdata,coeffs,pvals] = regressLFP(data,varargin)
% REGRESSLFP Regress out redundant information from LFP
%
%   RDATA = REGRESSLFP(DATA)
%   For LFP data in DATA, where it is assumed that there are more samples
%   than channels, REGRESSLFP will generate a linear model estimating each
%   channel with all other channels in the dataset.  RDATA will contain the
%   residuals in the estimate, that is, DATA - PREDICTED, which represents
%   the unique (in the linear sense) data on that channel that cannot be
%   formulated as a linear combination of any other channels.
%
%   [RDATA,FDATA] = REGRESSLFP(DATA)
%   Also returns the fitted data FDATA, i.e., the prediction of each
%   channel using a linear combination of all other channels, which
%   represents the potentially redundant (in the linear sense) data in the
%   dataset.
%
%   [RDATA,PDATA,COEFFS,PVALS] = REGRESSLFP(DATA)
%   Additionally returns the coefficients of each linear model, and the
%   p-values of the F-statistic that the coefficients are zero.  The Nth
%   columns in these matrices holds the intercept and coefficients (or
%   p-values) for the linear model estimating the Nth channel from all
%   other channels.  The Mth row of these matrices holds the coefficients
%   or p-values of the Mth channel as a predictor of all other channels.
%   The row of the response channel (i.e., the channel being predicted from
%   all others) will contain a NaN.
%
%   REGRESSLFP(...,'robust')
%   Enable robust fitting (incompatible with 'simplify' option below).
%
%   REGRESSLFP(...,'twostep')
%   Enable two-step creation; the first step constructs a linear model and
%   determines which observations produce large residuals in the predicted
%   response.  The second step excludes these observations when
%   constructing a new linear model.
%
%   REGRESSLFP(...,'simplify')
%   Attempts to simplify the model by adding or removing predictors (see
%   the LinearModel/step documentation).
%
%   REGRESSLFP(...,'intercept')
%   Include an intercept term in the linear model (default behavior is to
%   exclude the contant term).
%
%   REGRESSLFP(...,'nsteps',NSTEP)
%   Number of steps over which to simplify the model.  Only relevant when
%   'simplify' option provided.
%
%   REGRESSLFP(...,'nsamples',NSAMPLES)
%   Number of samples to use from the data for estimating the linear model.
%   By default, NSAMPLES is 1000.  NSAMPLES may have values between 1 and
%   the length of the data, or Inf (to specify all data).
%
%   REGRESSLFP(...,'samplemode',MODE)
%   Method of choosing samples from the data.  MODE may be 'first' or
%   'random' (default).  In the default mode, the first NSAMPLES will be
%   selected from the data in order to estimate the linear model.  When
%   MODE is 'random' NSAMPLES samples will be selected randomly from the
%   data.

% process user inputs
[varargin,robust] = util.argkeyval('robust',varargin,false); % use robust fitting
[varargin,twostep] = util.argkeyval('twostep',varargin,false); % two-step: remove outlier observations
[varargin,simplify] = util.argkeyval('simplify',varargin,false); % simplify: remove redundant channels from the predictors
[varargin,intercept] = util.argkeyval('intercept',varargin,false); % intercept: include a constant term in the model
[varargin,nsteps] = util.argkeyval('nsteps',varargin,10); % nsteps: how many steps to use when finding redundant channels
[varargin,Nsamples] = util.argkeyval('nsamples',varargin,1000); % nsamples: how many samples to use when estimating the linear model
[varargin,samplemode] = util.argkeyval('samplemode',varargin,'random'); % samplemode: 'first' or 'random'.  how to choose samples.
[varargin,coeffs] = util.argkeyval('coeffs',varargin,[]); % coeffs: reuse instead of of recalculate
util.argempty(varargin);

% error check
assert(~robust||~simplify,'Cannot request both robust and simplify (limitation of LinearModel object)');

% warning on simplify
if simplify
    warning('The ''simplify'' option introduces significant overhead and will take probably 100x - 1000x longer to run, so your request is being ignored.  Edit the code to remove this warning and keep the option if you really want it.');
    simplify = false;
end

% check data orientation - assume more samples than channels
if size(data,1)<size(data,2)
    data = data';
end

% data parameters
Nchan = size(data,2);
if isinf(Nsamples)
    Nsamples = size(data,1);
else
    assert(Nsamples>0 && Nsamples<=size(data,1),'Number of samples (input %d) must be Inf or between [1,%d]',Nsamples,size(data,1));
end

% determine which elements of the data to use for the linear model
if Nsamples==size(data,1)
    idx = 1:Nsamples;
else
    switch samplemode
        case 'first',idx = 1:Nsamples;
        case 'random',idx = randperm(size(data,1),Nsamples);
        otherwise, error('Unknown samplemode ''%s''',samplemode);
    end
end

% convert data to table for input to LinearModel object
tbl = array2table(data(idx,:),'VariableNames',arrayfun(@(x)sprintf('ch%02d',x),1:Nchan,'UniformOutput',false));

% if no coeffs provided, calculate them
pvals = [];
if isempty(coeffs)
    
    % loop over channels
    coeffs = nan(Nchan+intercept,Nchan);
    pvals = nan(Nchan+intercept,Nchan);
    parfor ch=1:Nchan
        
        % set up input data
        pvars = setdiff(1:Nchan,ch);
        rvar = ch;
        
        if robust
            mdl = fitlm(tbl,'PredictorVars',pvars,'ResponseVar',rvar,'RobustOpts','on','Intercept',intercept);
        else
        end
        
        % fit the model
        mdl = fitlm(tbl,'PredictorVars',pvars,'ResponseVar',rvar,'RobustOpts',robust,'Intercept',intercept);
        
        % two step: identify and remove outlier observations (not channels)
        if twostep
            outlier_idx = util.outliers(mdl.Residuals.Raw,[20 80],1.5);
            mdl = fitlm(tbl,'PredictorVars',pvars,'ResponseVar',rvar,'RobustOpts',robust,'Intercept',intercept,'Exclude',outlier_idx);
        end
        
        % simplify: try to remove predictors (channels)
        if simplify
            mdl = step(mdl,'NSteps',nsteps,'Verbose',2);
        end
        
        try
            
            % pull coefficients and p-values from linear model
            vars = mdl.Coefficients.Properties.RowNames;
            pred_idx = strncmpi(vars,'ch',2);
            pred_chs = cellfun(@(x)str2double(x(3:end)),vars(pred_idx));
            intr_idx = ~pred_idx;
            
            %chids = str2double(cellfun(@(x)x(3:4),vars(channel_idx),'UniformOutput',false));
            all_coeffs = mdl.Coefficients.Estimate;
            all_pvals = mdl.Coefficients.pValue;
            
            % construct vectors of each for this channel
            save_coeffs = nan(Nchan+intercept,1);
            save_coeffs(pred_chs+intercept) = all_coeffs(pred_idx);
            save_coeffs(intr_idx) = all_coeffs(intr_idx);
            save_pvals = nan(Nchan+intercept,1);
            save_pvals(pred_chs+intercept) = all_pvals(pred_idx);
            save_pvals(intr_idx) = all_pvals(intr_idx);
            
            % save into output
            pvals(:,ch) = save_pvals; % pval >0.05 means coeff likely to be zero
            coeffs(:,ch) = save_coeffs;
            
        catch ME
            util.errorMessage(ME);
            keyboard;
        end
    end
end

% calculate regressed/fitted data from model coefficients
fdata = nan(size(data,1),Nchan);
rdata = nan(size(data,1),Nchan);
for ch=1:Nchan
    
    % set up input data
    pvars = setdiff(1:Nchan,ch);
    rvar = ch;
    
    % fitted (prediction), residual (regressed)
    if intercept
        coeff_idx = [1 pvars+1];
        fdata(:,ch) = [ones(size(data,1),1) data(:,pvars)] * coeffs(coeff_idx,ch); % fitted data
    else
        coeff_idx = pvars;
        fdata(:,ch) = data(:,pvars) * coeffs(coeff_idx,ch); % fitted data
    end
    rdata(:,ch) = data(:,rvar) - fdata(:,ch); % residual (regressed) data
end