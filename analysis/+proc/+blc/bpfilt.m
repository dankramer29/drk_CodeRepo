function S = bpfilt(blc,varargin)
% BPFILT Apply bandpass filters
%
%   [S,T] = BPFILT(BLC)
%   Compute the bandpower in three default frequency bands (12-30 Hz, 30-80
%   Hz, and 80-200 Hz) for the data represented by BLc.Reader object BLC.
%
%   [S,T] = BPFILT(...,'FREQBAND',FB)
%   Specify the frequency bands to use as a cell array of [MIN MAX]
%   frequencies. By default, FB={[12 30],[30 80],[80 200]}.
%
%   [S,T] = BPFILT(...,'OVERLAP',OV)
%   Specify the amount of overlap between windows (to avoid startup edge
%   effects in the filtering). Default OV=1.0 seconds.
%
%   [S,T] = BPFILT(...,'CAUSAL')
%   Specify that the filtering should be causal (default is to use FILTFILT
%   for noncausal filtering).
%
%   [S,T] = BPFILT(...,'CHANNELS',CH)
%   Specify the channels to process (default all channels in the BLc
%   object).
%
%   [S,T] = BPFILT(...,'REREF','NONE')
%   [S,T] = BPFILT(...,'REREF','CAR')
%   [S,T] = BPFILT(...,'REREF',WEIGHTS)
%   [S,T] = BPFILT(...,'REREF',LM)
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
%   [S,T] = BPFILT(...,DBG)
%   Provide a Debug.Debugger object DBG. If one is not provided, one will
%   be created (for screen output only).
%
%   [S,T] = BPFILT(...,'PARFOR')
%   Specify whether to use parallel CPU threads for computation. Parallel
%   operation is disabled by default.
%
%   [S,T] = BPFILT(...,'AVAILUTIL',U)
%   Specify the fraction of available memory to use  (Default U=0.2).

[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,nan);
if ~found_debug,debug=Debug.Debugger('proc_blc_bpfilt');end
if ischar(blc)&&exist(blc,'file')==2,blc=BLc.Reader(blc,debug);end
assert(isa(blc,'BLc.Reader'),'Must provide a valid BLc.Reader object');
[varargin,availutil] = util.argkeyval('availutil',varargin,0.2);
[varargin,overlap] = util.argkeyval('overlap',varargin,1.0);
[varargin,causal_filter] = util.argflag('causal',varargin,false);
if causal_filter,flt=@filter;else,flt=@filtfilt;end
[varargin,channels] = util.argkeyval('channels',varargin,1:blc.ChannelCount);
[varargin,freqband] = util.argkeyval('freqband',varargin,{[12 30],[30 80],[80 200]});
if ~iscell(freqband),freqband={freqband};end
[varargin,use_parfor,~,found_parfor] = util.argflag('parfor',varargin,false);
[varargin,reref] = util.argkeyval('reref',varargin,'none'); % 'NONE', 'CAR', WEIGHTS, or LM
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
util.argempty(varargin);

% create blc streamer
bls = BLc.Streamer(blc,debug);
[currpos,total] = bls.tell;

% compute parameters
Fs = blc.SamplingRate;
overlap_pre_samples = round(overlap*Fs);
S = nan(total,length(freqband),num_channels);

% get filters
bpfilt = proc.helper.getBandpowerFilts('freqband',freqband,'fs',Fs);

% compute amounts to fit in memory
if use_parfor
    [~,mem_samples] = util.memcheck([num_channels 1],'double',2,'AvailableUtilization',availutil/num_bands,'Multiples',win_samples);
else
    [~,mem_samples] = util.memcheck([num_channels 1],'double',2,'AvailableUtilization',availutil);
end

% loop over windows and use FFT to compute frequency data
last_overlap = 0;
sample_st = 1;
while currpos<total
    
    % compute how many samples to read and set up the next round by
    % leaving an overlap prior to the desired data window
    num_samples_left = total - currpos + 1;
    num_to_read = min(mem_samples,num_samples_left);
    num_to_step = min(num_to_read-1,mem_samples-overlap_pre_samples);
    x = bls.read(num_to_read,'step',num_to_step,'channels',channels);
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
    
    % compute the last sample
    local_sample_st = last_overlap+1;
    local_sample_et = size(x,1);
    last_overlap = num_to_read-num_to_step;
    sample_et = sample_st + (local_sample_et - local_sample_st + 1) - 1;
    
    % parfor or normal for
    if use_parfor
        local_S = cell(1,num_bands);
        parfor bb=1:num_bands
            local_S{bb} = flt(bpfilt{bb},x);
            local_S{bb} = local_S{bb}(local_sample_st:local_sample_et,:);
        end
        S(sample_st:sample_et,:,:) = permute(cat(3,local_S{:}),[1 3 2]);
    else
        for bb=1:num_bands
            local_S = flt(bpfilt{bb},x);
            S(sample_st:sample_et,bb,:) = local_S(local_sample_st:local_sample_et,:);
        end
    end
    
    % update loop variables
    sample_st = sample_et + 1;
    currpos = bls.tell;
    clear x local_S;
end

%t = t-win_samples+1;