function [S,t] = bandpower_stream_fft(blc,varargin)
% BANDPOWER_STREAM_FFT Compute bandpower using FFTs on incremental data
%
%   [S,T] = BANDPOWER_STREAM_FFT(BLC)
%   Compute the bandpower in three default frequency bands (12-30 Hz, 30-80
%   Hz, and 80-200 Hz) for the data represented by BLc.Reader object BLC.
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,'MOVINGWIN',MV)
%   Specify the moving window as [WIN STEP] in seconds. By default, the MV
%   is [1.0 0.1] seconds.
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,'FREQBAND',FB)
%   Specify the frequency bands to use as a cell array of [MIN MAX]
%   frequencies. By default, FB={[12 30],[30 80],[80 200]}.
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,'REREF','NONE')
%   [S,T] = BANDPOWER_STREAM_FFT(...,'REREF','CAR')
%   [S,T] = BANDPOWER_STREAM_FFT(...,'REREF',WEIGHTS)
%   [S,T] = BANDPOWER_STREAM_FFT(...,'REREF',LM)
%   Optionally re-reference the data prior to computing the FFT.
%
%   For common-average rereferencing (CAR), each channel is re-referenced
%   to the average of all channels except that channel (i.e., uniform
%   weights).
%
%   The user may also provide custom weights to be used when constructing
%   the software reference. Here, WEIGHTS must be a vector with one entry
%   per channel (for same weights applied to all channels), or a cell array
%   where each cell contains a vector with one entry per channel. 
%
%   The user may also provide an object with a "predict" method (see e.g.
%   the LinearModel class returned by fitlm from Mathworks). This method
%   should accept a matrix of values (columns are channels and rows are 
%   observations) and return a single vector with one entry per
%   observation for the new reference.
%
%   The default re-referencing is 'NONE'.
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,DBG)
%   Provide a Debug.Debugger object DBG. If one is not provided, one will
%   be created (for screen output only).
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,'GPU')
%   [S,T] = BANDPOWER_STREAM_FFT(...,'PARFOR')
%   Specify whether to use the GPU or parallel CPU threads for computation.
%   By default, if a GPU is available, it will be prioritized, followed by
%   parallel CPU threads.
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,'PAD',P)
%   Specify the padding for the FFT in P, where P is a signed integer
%   value. A value of P=0 corresponds to the next-power-of-2 from the
%   number of samples in the window. Nonzero values increase or decrease
%   this value by powers of 2. By default, P=0.
%
%   [S,T] = BANDPOWER_STREAM_FFT(...,'DOUBLE'|'SINGLE'|'INT16'|'INT32'|'INT64')
%   Specify the class of the data as double or single (floating point), or
%   signed integer (16-, 32-, or 64-bit).

% process inputs
has_gpu = env.get('hasgpu');
[varargin,time_window_alignment] = util.argkeyval('time_window_alignment',varargin,'middle'); % 'beginning','middle','end'
assert(any(strcmpi(time_window_alignment,{'beginning','middle','end'})),'Time window alignment must be one of "beginning", "middle", or "end"');
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug,debug=Debug.Debugger('bandpower_stream_fft','screen');end
[varargin,use_gpu] = util.argkeyval('gpu',varargin,has_gpu);
[varargin,use_parfor] = util.argkeyval('parfor',varargin,false);
[use_gpu,use_parfor] = proc.helper.getGPUParfor(use_parfor,use_gpu,has_gpu);
[varargin,pad] = util.argkeyval('pad',varargin,0);
dtclass = 'double';
if use_gpu,dtclass='single';end
[varargin,dtclass] = util.argkeyword({'double','single','int16','int32','int64'},varargin,dtclass);
[varargin,movingwin] = util.argkeyval('movingwin',varargin,[1 0.1]);
[varargin,freqband] = util.argkeyval('freqband',varargin,{[12 30],[30 80],[80 200]});
if ~iscell(freqband),freqband={freqband};end
[varargin,reref] = util.argkeyval('reref',varargin,'none'); % 'NONE', 'CAR', WEIGHTS, or LM
util.argempty(varargin);

% create nsx streamer
bls = BLc.Streamer(blc,debug);
[currpos,total] = bls.tell;

% compute parameters
channels = 1:blc.ChannelCount;
num_channels = length(channels);
Fs = blc.SamplingRate;
win_samples = round(movingwin(1)*Fs);
step_samples = round(movingwin(2)*Fs);
N = 2^(nextpow2(win_samples)+pad);
w = (0:Fs/N:Fs/2)';
idx_freqband = cell(1,length(freqband));
for kk=1:length(freqband)
    idx_freqband{kk} = w>=freqband{kk}(1) & w<freqband{kk}(2);
end
t = cast(win_samples:step_samples:total,dtclass);
S = nan(length(t),length(freqband),num_channels,dtclass);

% compute amounts to fit in memory
[~,mem_samples] = util.memcheck([num_channels 1],dtclass,2,'AvailableUtilization',0.01,'Multiples',win_samples);

% loop over windows and use FFT to compute frequency data
idx = 0;
while currpos<=(t(end)-win_samples)
    
    % read this window of data
    num_samples_left = t(end) - currpos + 1;
    num_to_read = min(mem_samples,num_samples_left);
    num_to_step = min(num_to_read,mem_samples-(win_samples-step_samples));
    x = bls.read(num_to_read,'step',num_to_step,'channels',channels,dtclass);
    x = x';
    
    % re-reference if requested
    if ~ischar(reref) || (ischar(reref) && ~strcmpi(reref,'none'))
        
        % assign weights
        if ischar(reref) && strcmpi(reref,'car')
            
            % for each channel, construct the equivalent weights for
            % averaging all except that channel
            w = arrayfun(@(y)[ones(1,y-1) 0 ones(1,size(x,2)-y)]/(size(x,2)-1),1:size(x,2),'UniformOutput',false);
            x_ref = nan(size(x));
            for kk=1:size(x,2)
                x_ref(:,kk) = sum(w{kk}.*x,2);
            end
        elseif isobject(reref) && ismethod(reref,'predict')
            
            % apply predict method to the data
            x_ref = predict(reref,x);
        elseif isnumeric(reref) && length(reref)==size(x,2)
            
            % numeric vector: same weights applied to all channels
            x_ref = repmat(reref.*x,1,size(x,2));
        elseif iscell(reref) && length(reref)==size(x,2)
            
            % custom weights for each channel
            x_ref = nan(size(x));
            for kk=1:size(x,2)
                x_ref(:,kk) = sum(reref{kk}.*x,2);
            end
        end
        assert(all(size(x_ref)==size(x)),'Invalid reference size %s (expected size %s)',util.vec2str(size(x_ref)),util.vec2str(size(x)));
        
        % apply weighted re-reference
        x = x - x_ref;
        clear x_ref;
    end
    
    % compute FFTs and average the requested bands
    local_S = cell(1,size(x,2));
    if use_gpu
        
        % GPU: move X to GPU memory and compute
        for kk=1:size(x,2)
            xbuf = gpuArray(buffer(x(:,kk),win_samples,(win_samples-step_samples),'nodelay'));
            wt = repmat(gpuArray(hann(win_samples)),[1 size(xbuf,2)]);
            tmp_S = fft(xbuf.*wt,N);
            tmp_S = tmp_S(1:N/2+1,:);
            tmp_S = (1/(Fs*N)).*abs(tmp_S).^2;
            tmp_S(2:end-1,:) = 2*tmp_S(2:end-1,:);
            tmp_S = cellfun(@(x)nanmean(tmp_S(x,:),1),idx_freqband,'UniformOutput',false);
            local_S{kk} = gather(cat(1,tmp_S{:})');
        end
    elseif use_parfor
        
        % multithreaded CPU: parfor
        parfor kk=1:size(x,2)
            xbuf = buffer(x(:,kk),win_samples,(win_samples-step_samples),'nodelay');
            wt = repmat(hann(win_samples),[1 size(xbuf,2)]);
            tmp_S = fft(xbuf.*wt,N);
            tmp_S = tmp_S(1:N/2+1,:);
            tmp_S = (1/(Fs*N)).*abs(tmp_S).^2;
            tmp_S(2:end-1,:) = 2*tmp_S(2:end-1,:);
            tmp_S = cellfun(@(x)nanmean(tmp_S(x,:),1),idx_freqband,'UniformOutput',false);
            local_S{kk} = cat(1,tmp_S{:})';
        end
    else
        
        % single-threaded CPU: for
        for kk=1:size(x,2)
            xbuf = buffer(x(:,kk),win_samples,(win_samples-step_samples),'nodelay');
            wt = repmat(hann(win_samples),[1 size(xbuf,2)]);
            tmp_S = fft(xbuf.*wt,N);
            tmp_S = tmp_S(1:N/2+1,:);
            tmp_S = (1/(Fs*N)).*abs(tmp_S).^2;
            tmp_S(2:end-1,:) = 2*tmp_S(2:end-1,:);
            tmp_S = cellfun(@(x)nanmean(tmp_S(x,:),1),idx_freqband,'UniformOutput',false);
            local_S{kk} = cat(1,tmp_S{:})';
        end
    end
    S(idx+(1:size(local_S{1},1)),:,:) = cat(3,local_S{:});
    
    % update positions
    idx = idx + size(local_S{1},1);
    currpos = bls.tell;
end

% shift time vector to middle of window
switch lower(time_window_alignment)
    case 'beginning'
        t = t - win_samples+1;
    case 'middle'
        t = t - round(win_samples/2);
    case 'end'
        t = t + 0;
end