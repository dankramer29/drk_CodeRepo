function [r,tau,err] = psth(timestamps,sampling,varargin)
% PSTH Trial-averaged spike rate smoothed by a Gaussian kernel
%
%   [R,TAU,ERR] = PSTH(TIMESTAMPS,SAMPLING)
%   Returns the trial-/channel-averaged spike rate R, with 95% confidence
%   intervals ERR, calculated at times specified by TAU, from the data in
%   TIMESTAMPS.  The input TIMESTAMPS may be either (1) a logical (possibly
%   sparse) matrix, with one row per channel or trial and one column per
%   sample, containing TRUE where spikes occurred and FALSE otherwise; or,
%   (2) a cell array with one cell per channel/trial containing a list of
%   numerical timestamps.
%
%   If SAMPLING is scalar and <=1, it is interpreted as the sampling
%   interval of the spike event timestamps.  If it is scalar and >1, it is
%   interpreted as the sampling frequency of the spike event timestamps.
%   If SAMPLING is a vector, it is interpreted as timestamp markers from
%   the sampling train that generated the spike timestamps.
%
%   If a vector, SAMPLING may have units of samples or seconds. If in
%   samples, the sampling frequence FS must also be provided (see below).
%   If in seconds, the effective sampling rate will be inferred as the
%   inverse of the median diff of SAMPLING, and this value will be used to
%   convert other inputs from units of seconds to units of samples.
%
%   PSTH(...,'ERRTYPE',ERR)
%   ERR may be 'none' (no intervals returned), 'poisson' (Poisson standard
%   error), 'bootse' (bootstrapped standard error over trials), or 'bootci'
%   (bootstrapped confidence intervals over trials).  The default value is
%   'bootci'.  If ERR is 'none', E is empty; otherwise, E will have two
%   rows: the lower and upper intervals calculated based on the method
%   assigned to ERR.
%
%   PSTH(...,'ALPHA',ALPHA)
%   When ERR is set to 3 (boostrapped confidence intervals), the value of
%   ALPHA indicates the confidence level (1-ALPHA) used in calculating the
%   intervals.  By default, ALPHA is set to 0.05, for a 95% confidence
%   level.
%
%   PSTH(...,'KERNEL_WIDTH',SD)
%   SD is the standard deviation of the Gaussian smoothing kernel.  The 
%   default is 0.05, and units of this input are in seconds.
%
%   PSTH(...,'ADAPT')
%   If the ADAPT option is set, the PSTH will be calculated adaptively by
%   first estimating with a fixed kernel width (SD), then altering the
%   kernel width so that the number of spikes falling under the kernel is
%   the same on average but is time dependent.  Regions rich in data
%   therefore have their kernel width reduced.
%
%   PSTH(...,'TIMEOFFSET',OFFT)
%   Only applies when TIMESTAMPS is a logical (sparse) matrix.  If
%   provided, will offset the time associated with each column of
%   TIMESTAMPS by OT. Otherwise, it is assumed that the first column
%   corresponds to zero time.
%
%   PSTH(...,'WIN',[ST LT])
%   Specify the time interval over which to calculate R.  The values ST and
%   LT must be consistent with the time associated with TIMESTAMPS.  If
%   TIMESTAMPS is a logical (sparse) matrix, times are calculated based on
%   the offset time OT (see above) and the sampling frequency FS. 
%   Otherwise, times are calculated based on the actual timestamps in
%   TIMESTAMPS.
%
%   Based on CHRONUX package function PSTH, but modified for clarity,
%   functional independence from other CHRONUX functions, and to add a few
%   additional features.

% process user inputs
[varargin,fs,~,found_fs] = util.argkeyval('fs',varargin,30e3);
[varargin,kernel_sd,~,found_kernel_sd] = util.argkeyval('kernel_width',varargin,0.05);
[varargin,sampling_period,~,found_sampling_period] = util.argkeyval('sampling_period',varargin,kernel_sd);
[varargin,errtype] = util.argkeyval('errtype',varargin,'bootci');
[varargin,alpha] = util.argkeyval('alpha',varargin,0.05);
[varargin,nboot] = util.argkeyval('nboot',varargin,1000);
[varargin,adapt] = util.argflag('adapt',varargin,false);
[varargin,trialave] = util.argflag('trialave',varargin,false);
[varargin,debug,found] = util.argisa('Debug.Debugger',varargin,nan);
if ~found,debug=Debug.Debugger('raster');end
util.argempty(varargin);

% construct sampling vector if not already provided
if isscalar(sampling)
    if ~found_fs
        if sampling<=1
            fs = 1/sampling;
        else
            fs = sampling;
        end
    end
    if issparse(timestamps)
        num_timestamps = max(size(timestamps)); % make an assumption that there are more timestamps than features
        sampling = (0:num_timestamps-1)'/fs;
    else
        st = min(cellfun(@min,timestamps));
        lt = max(cellfun(@max,timestamps));
        sampling = (st:lt)'/fs;
    end
else
    if ~found_fs
        fs = 1/median(diff(sampling));
    end
end

% enforce desired orientation on sparse arrays
if ~issparse(timestamps)
    timestamps = proc.helper.ts2sparse(timestamps,'numsamples',length(sampling));
end
if size(timestamps,1)~=length(sampling),timestamps=timestamps';end
assert(size(timestamps,1)==length(sampling),'Sampling (%d) must be the same size as the second dimension of TIMESTAMPS (%d).',length(sampling),size(timestamps,1));
num_timestamps = length(sampling);

% compute range and sampling period for gaussian kernel
win = sampling([1 end]);
if ~found_kernel_sd
    if fs==1 % this means sampling is in samples not seconds
        
        % try to fit ~200 kernels into the range of the data
        kernel_sd = round(num_timestamps/200);
        kernel_sd = min(kernel_sd,6000);
        kernel_sd = max(kernel_sd,60);
    end
end
if ~found_sampling_period
    sampling_period = kernel_sd;
end
metric = diff(win)/kernel_sd;
assert(metric>=10&&metric<=length(sampling),'Probable mismatch between units of the sampling input (win=%s) and the Gaussian kernel s.d. (%g)', util.vec2str(win), kernel_sd);

% calculate number of trials and check error type against it
num_trials = size(timestamps,2);
if num_trials<4 && strncmpi(errtype,'boot',4)
    debug.log('Switching to Poisson standard error since number of trials is too small for bootstrap','info');
    errtype = 'poisson';
end

% create sampling points based on window and sampling interval
tau = win(1):sampling_period:win(2);

% avoid negative numbers in the time vector for now
time_offset = tau(1);
tau = tau - time_offset;

% Smear each spike out
% std dev is sqrt(rate*(integral over kernal^2)/trials)
% for Gaussian integral over Kernal^2 is 1/(2*sig*srqt(pi))
num_samples = length(tau);
RR = zeros(num_trials,num_samples);
f = 1/(2*kernel_sd^2);
for nn=1:num_trials
    ts = find(timestamps(:,nn)')/fs;
    num_timestamps = length(ts);
    for mm=1:num_timestamps
        RR(nn,:) = RR(nn,:) + exp(-f*(tau-ts(mm)).^2);
    end
end
RR = RR*(1/sqrt(2*pi*kernel_sd^2));
if trialave
    r = mean(RR,1);
else
    r = RR;
end

% if adaptive, warp SD so that on average the number of spikes under the
% kernel is the same, but regions with more data have a smaller kernel
if adapt
    if ~trialave,warning('This code probably will not work b/c of trialave');end
    
    % calculate adaptive rate
    sdt = mean(r)*kernel_sd./r;
    RR = zeros(num_trials,num_samples);
    f = 1./(2*sdt.^2);
    for nn=1:num_trials
        ts = find(timestamps(:,nn)')/fs;
        num_timestamps = length(ts);
        for mm=1:num_timestamps
            RR(nn,:) = RR(nn,:) + exp(-f.*(tau-ts(mm)).^2);
        end
        RR(nn,:) = RR(nn,:).*(1./sqrt(2*pi*sdt.^2));
    end
    if trialave
        r = mean(RR,1);
    else
        r = RR;
    end
else
    
    % for convienence in calculating poisson standard error below
    sdt = kernel_sd*ones(1,size(r,2));
end

% add time offset back in
tau = tau + time_offset;

% calculate standard error or confidence intervals
if nargout>=3
    switch lower(errtype)
        case 'none'
            err = [];
        case 'poisson'
            err = sqrt(r./(2*num_trials*sdt*sqrt(pi)));
            err = [r(:)'-err; r(:)'+err];
        case 'bootse'
            mE = 0;
            sE = 0;
            for b=1:nboot
                idx = floor(num_trials*rand(1,num_trials)) + 1;
                mtmp = mean(RR(idx,:));
                mE = mE + mtmp;
                sE = sE + mtmp.^2;
            end
            err = sqrt((sE/nboot - mE.^2/nboot^2));
            err = [r(:)'-err; r(:)'+err];
        case 'bootci'
            if numel(RR)>=1e5
                opt = statset('UseParallel',true);
            else
                opt = statset('UseParallel',false);
            end
            err = bootci(nboot,{@nanmean,RR,1},'alpha',alpha,'type','bca','options',opt); % bootstrapped 95% confidence intervals
            
            % turn nan's to zeros
            err(1,isnan(err(1,:))) = 0;
            err(2,isnan(err(2,:))) = 0;
        otherwise
            error('Unknown error type ''%s''',errtype);
    end
end

% re-orient so channels are columns
r = r';
tau = tau';