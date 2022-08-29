function [r,t] = bandpower_stream_bpfilt(ns,varargin)
[varargin,availutil] = Utilities.argkeyval('availutil',varargin,0.2);
[varargin,movingwin] = Utilities.argkeyval('movingwin',varargin,[0.25 0.05]);
[varargin,overlap] = Utilities.argkeyval('overlap',varargin,1.0);
[varargin,causal_filter] = Utilities.argflag('causal',varargin,false);
if causal_filter,flt=@filter;else,flt=@filtfilt;end
[varargin,channels] = Utilities.argkeyval('channels',varargin,1:96);
[varargin,freqband] = Utilities.argkeyval('freqband',varargin,{[12 30],[30 80],[80 200]});
if ~iscell(freqband),freqband={freqband};end
[varargin,offset] = Utilities.argkeyval('offset',varargin,-0.1);
[varargin,use_parfor,~,found_parfor] = Utilities.argflag('parfor',varargin,false);
num_channels = length(channels);
num_bands = length(freqband);

% if user didn't specify, use parfor if we have to calculate enough
% frequency bands in parallel to use at least 80% of the workers
if ~found_parfor
    N = maxNumCompThreads;
    use_parfor = num_bands/N>=0.8;
    if use_parfor
        gcp;
    end
end
Utilities.argempty(varargin);

% create nsx streamer
nss = Blackrock.NSxStreamer(ns);
[currpos,total] = nss.tell;

% compute parameters
Fs = ns.Fs;
overlap_pre_samples = round(overlap*Fs);
win_samples = round(movingwin(1)*Fs);
step_samples = round(movingwin(2)*Fs);
offset_samples = round(offset*Fs);
assert(win_samples+offset_samples>=1,'Offset must be greater than -%.3f\n',movingwin(1));
t = win_samples:step_samples:total;
r = nan(length(t),length(freqband),num_channels);

% get filters
[bpfilt,lpfilt] = proc.helper.getBandpowerFilts(freqband,movingwin,Fs);

% compute amounts to fit in memory
if use_parfor
    [~,mem_samples] = Utilities.memcheck([num_channels 1],'double',2,'AvailableUtilization',availutil/num_bands,'Multiples',win_samples);
else
    [~,mem_samples] = Utilities.memcheck([num_channels 1],'double',2,'AvailableUtilization',availutil,'Multiples',win_samples);
end

% loop over windows and use FFT to compute frequency data
idx = 0;
last_overlap = 0;
while currpos<t(end)
    
    % compute how many samples to read and set up the next round by
    % leaving an overlap prior to the desired data window
    num_samples_left = t(end) - currpos + 1;
    num_to_read = min(mem_samples,num_samples_left);
    num_to_step = min(num_to_read,mem_samples-overlap_pre_samples);
    x = nss.read(num_to_read,'step',num_to_step,'channels',channels);
    x = x';
    
    % set up the indices into the output
    if currpos<=(mem_samples-overlap_pre_samples)
        
        % first time around, we start with the last sample of the first
        % window (i.e., this represents the average value for that window)
        start_win = win_samples;
    else
        
        % subsequent times through, we start with the first step into the
        % dataset, i.e., only "step" samples in (hence overlap)
        start_win = step_samples;
    end
    idx_win = ((start_win+last_overlap):step_samples:num_to_read)+offset_samples+1;
    num_win = length(idx_win);
    
    % parfor or normal for
    try
    if use_parfor
        S = cell(1,num_bands);
        parfor bb=1:num_bands
            S{bb} = flt(bpfilt{bb},x);
            S{bb} = flt(lpfilt,S{bb}.^2);
            S{bb} = S{bb}(idx_win,:);
        end
        r(idx+(1:num_win),:,:) = permute(cat(3,S{:}),[1 3 2]);
    else
        for bb=1:num_bands
            S = flt(bpfilt{bb},x);
            S = flt(lpfilt,S.^2);
            S = S(idx_win,:);
            r(idx+(1:num_win),bb,:) = S;
        end
    end
    catch ME
        Utilities.errorMessage(ME);
        keyboard
    end
    
    % update loop variables
    idx = idx + num_win;
    last_overlap = overlap_pre_samples;
    currpos = nss.tell;
    clear x S;
end

%t = t-win_samples+1;