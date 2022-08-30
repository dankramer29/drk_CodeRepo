function [r,t] = bandpower_stream_fft(ns,varargin)
has_gpu = env.get('hasgpu');
[varargin,use_gpu] = Utilities.argkeyval('gpu',varargin,has_gpu);
[varargin,use_parfor] = Utilities.argkeyval('parfor',varargin,false);
[use_gpu,use_parfor] = proc.helper.getGPUParfor(use_parfor,use_gpu,has_gpu);
[varargin,pad] = Utilities.argkeyval('pad',varargin,0);
dtclass = 'double';
if use_gpu,dtclass='single';end
[varargin,dtclass] = Utilities.argkeyword({'double','single','int16','int32','int64'},varargin,dtclass);
[varargin,movingwin] = Utilities.argkeyval('movingwin',varargin,[0.25 0.05]);
[varargin,freqband] = Utilities.argkeyval('freqband',varargin,{[12 30],[30 80],[80 200]});
if ~iscell(freqband),freqband={freqband};end
Utilities.argempty(varargin);

% create nsx streamer
nss = Blackrock.NSxStreamer(ns);
[currpos,total] = nss.tell;

% compute parameters
channels = 1:96;
num_channels = length(channels);
win_samples = round(movingwin(1)*ns.Fs);
step_samples = round(movingwin(2)*ns.Fs);
N = 2^(nextpow2(win_samples)+pad);
Fs = ns.Fs;
w = (0:Fs/N:Fs/2)';
idx_freqband = cell(1,length(freqband));
for kk=1:length(freqband)
    idx_freqband{kk} = w>=freqband{kk}(1) & w<freqband{kk}(2);
end
t = cast(win_samples:step_samples:total,dtclass);
r = nan(length(t),length(freqband),num_channels,dtclass);

% compute amounts to fit in memory
[~,mem_samples] = Utilities.memcheck([num_channels 1],dtclass,2,'AvailableUtilization',0.01,'Multiples',win_samples);

% loop over windows and use FFT to compute frequency data
idx = 0;
while currpos<=(t(end)-win_samples)
    num_samples_left = t(end) - currpos + 1;
    num_to_read = min(mem_samples,num_samples_left);
    num_to_step = min(num_to_read,mem_samples-(win_samples-step_samples));
    x = nss.read(num_to_read,'step',num_to_step,'channels',channels,dtclass);
    x = x';
    localr = cell(1,size(x,2));
    if use_gpu
        for kk=1:size(x,2)
            xbuf = gpuArray(buffer(x(:,kk),win_samples,(win_samples-step_samples),'nodelay'));
            wt = repmat(gpuArray(hann(win_samples)),[1 size(xbuf,2)]);
            S = fft(xbuf.*wt,N);
            S = S(1:N/2+1,:);
            S = (1/(Fs*N)).*abs(S).^2;
            S(2:end-1,:) = 2*S(2:end-1,:);
            tmpr = cellfun(@(x)nanmean(S(x,:),1),idx_freqband,'UniformOutput',false);
            localr{kk} = gather(cat(1,tmpr{:})');
        end
    elseif use_parfor
        parfor kk=1:size(x,2)
            xbuf = buffer(x(:,kk),win_samples,(win_samples-step_samples),'nodelay');
            wt = repmat(hann(win_samples),[1 size(xbuf,2)]);
            S = fft(xbuf.*wt,N);
            S = S(1:N/2+1,:);
            S = (1/(Fs*N)).*abs(S).^2;
            S(2:end-1,:) = 2*S(2:end-1,:);
            tmpr = cellfun(@(x)nanmean(S(x,:),1),idx_freqband,'UniformOutput',false);
            localr{kk} = cat(1,tmpr{:})';
        end
    else
        for kk=1:size(x,2)
            xbuf = buffer(x(:,kk),win_samples,(win_samples-step_samples),'nodelay');
            wt = repmat(hann(win_samples),[1 size(xbuf,2)]);
            S = fft(xbuf.*wt,N);
            S = S(1:N/2+1,:);
            S = (1/(Fs*N)).*abs(S).^2;
            S(2:end-1,:) = 2*S(2:end-1,:);
            tmpr = cellfun(@(x)nanmean(S(x,:),1),idx_freqband,'UniformOutput',false);
            localr{kk} = cat(1,tmpr{:})';
        end
    end
    r(idx+(1:size(localr{1},1)),:,:) = cat(3,localr{:});
    idx = idx + size(localr{1},1);
    currpos = nss.tell;
end