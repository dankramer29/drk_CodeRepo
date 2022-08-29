function [rdata,fdata,coeffs,pvals] = regressLFPwin(data,win,varargin)
% REGRESSLFPWIN Use linear regression to extract common elements in LFP
%
%   RDATA = REGRESSLFPWIN(DATA,WIN)
%   For LFP data in DATA, where it is assumed that there are more samples
%   than channels, REGRESSLFPWIN will step through DATA in WIN(1)-sample
%   chunks with WIN(2) samples of overlap.  For each window of data, a
%   linear model will be generated to estimate each channel in DATA with
%   all other channels in the dataset.  The windowed results will be merged
%   back together by using a sigmoidal function to gradually weight
%   overlapping portions of windows.  RDATA will contain the residuals in
%   the estimate, that is, DATA - PREDICTED, which represents the unique
%   (in the linear sense) data on that channel that cannot be formulated
%   as a linear combination of any other channels.
%
%   [RDATA,FDATA] = REGRESSLFPWIN(DATA,WIN)
%   Also returns the fitted data FDATA, i.e., the prediction of each
%   channel using a linear combination of all other channels, which
%   represents the potentially redundant (in the linear sense) data in the
%   dataset.
%
%   [RDATA,PDATA,COEFFS,PVALS] = REGRESSLFP(DATA,WIN)
%   Additionally returns the coefficients of each linear model, and the
%   p-values of the F-statistic that the coefficients are zero.  Matrices
%   COEFFS and PVALS have three dimensions: channels x channels x windows.
%   For the Kth window, the Nth columns holds the coefficients or p-values
%   for the linear model estimating the Nth channel from all other
%   channels.  The Mth row holds the coefficients or p-values of the Mth
%   channel as a predictor of all other channels.
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
%   REGRESSLFP(...,'verbosity',VERBOSITY)
%   Verbosity level: 0: off, 1: errors, 2: warnings, 3: info, 4: hints, 5:
%   debug.  Most messages in this function are information-level priority.
%
%   See also PROC.REGRESSLFP.

% process inputs
[varargin,verbosity] = util.argkeyval('verbosity',varargin,2);
[varargin,tau] = util.argkeyval('tau',varargin,nan); % smoothing parameter for sigmoidal overlap function
[varargin,robust] = util.argflag('robust',varargin,false); % use robust fitting
[varargin,twostep] = util.argflag('twostep',varargin,false); % two-step: remove outlier observations
[varargin,simplify] = util.argflag('simplify',varargin,false); % simplify: remove redundant channels from the predictors
[varargin,intercept] = util.argflag('intercept',varargin,false); % intercept: include a constant term in the model
[varargin,nsteps] = util.argkeyval('nsteps',varargin,10); % nsteps: how many steps to use when finding redundant channels
[varargin,Nwinsamples] = util.argkeyval('nsamples',varargin,min(1000,win(1))); % nsamples: how many samples to use when estimating the linear model (maximum is the window size)
[varargin,samplemode] = util.argkeyval('samplemode',varargin,'random'); % samplemode: 'first' or 'random'.  how to choose samples.
util.argempty(varargin);

% arguments for calling regressLFP
assert(Nwinsamples<=win(1),'Number of samples limited to window size (%d samples)',win(1));
args = {'nsteps',nsteps,'nsamples',Nwinsamples,'samplemode',samplemode};
if intercept,args=[args {'intercept'}];end
if simplify,args=[args {'simplify'}];end
if twostep,args=[args {'twostep'}];end
if robust,args=[args {'robust'}];end

% check parallel pool
poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
    parpool;
end

% check data orientation - assume more samples than channels
if size(data,1)<size(data,2)
    data = data';
end

% data parameters
Nwin = win(1);
Nstep = win(2);
Nchan = size(data,2);
Nsamples = size(data,1);
Noverlap = -diff(win);
assert(Noverlap*2<=Nwin,'Overlap (%d) must be smaller than than SAMPLES/2 (%d)',Noverlap,round(Nwin/2));
winst = 1:Nstep:Nsamples;
nw = length(winst);
winsz = [repmat(Nwin,1,nw-1),(Nsamples-winst(end)+1)];

% set tau adaptively to achieve 0 or 1 ± 0.01 at the ends of the window
if isnan(tau)
    tau = ceil(abs(log((0.01/(Noverlap/2)))));
end

% sigmoidal function (for smooth transitions between overlapping windows)
x = (1:Noverlap)';
smooth = 1./(1+exp(-(tau/Noverlap).*(x-Noverlap/2))); % sigmoidal function

% scale amplitude -> [0,1] so that 50% windows on even Nwin doesn't attenuate
smooth = smooth - min(smooth);
smooth = smooth / max(smooth);

% repmat for all channels
smooth = repmat(smooth,[1 Nchan]);

% run the regression
if intercept
    rows = Nchan+1;
else
    rows = Nchan;
end
coeffs = nan(rows,Nchan,nw);
pvals = nan(rows,Nchan,nw);
rdata = zeros(Nsamples,Nchan);
fdata = zeros(Nsamples,Nchan);
looptimes = nan(1,nw);
for kk=1:nw
    stopwatch = tic;
    midx = (winst(kk)-1) + (1:winsz(kk));
    
    % smoothing for this window
    winsmooth = ones(winsz(kk),Nchan);
    
    % if not the first window, apply weight to first Noverlap samples
    if kk>1
        stidx = 1:Noverlap;
        winsmooth(stidx,:) = winsmooth(stidx,:).*smooth;
    end
    
    % if not the last window, apply weight to last Noverlap samples
    if kk<nw
        ltidx = (Nstep+1):Nwin;
        winsmooth(ltidx,:) = winsmooth(ltidx,:).*(1-smooth);
    end
    
    % regress on this window
    [tmpr,tmpf,tmpc,tmpp] = proc.helper.regressLFP(data(midx,:),args{:});
    
    % merge sigmoid-weighted data back into reconstructed output
    rdata(midx,:) = rdata(midx,:) + tmpr.*winsmooth;
    fdata(midx,:) = fdata(midx,:) + tmpf.*winsmooth;
    
    % place coefficients and pvals into the results
    coeffs(:,:,kk) = tmpc;
    pvals(:,:,kk) = tmpp;
    
    % update user
    looptimes(kk) = toc(stopwatch);
    Debug.message(sprintf('Window %d/%d: %s per window, %s remaining',kk,length(winst),...
        util.hms(nanmean(looptimes),'hh:mm:ss'),...
        util.hms((length(winst)-kk)*nanmean(looptimes),'hh:mm:ss')),3,struct('verbosity',verbosity),mfilename);
end