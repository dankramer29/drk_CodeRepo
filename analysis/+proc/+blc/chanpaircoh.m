function [coh,phi,cx,f,t,chanpairs] = chanpaircoh(v,fs,varargin)
% CHANPAIRCOH Compute coherence between pairs of channels in a dataset
%
%   [COH,PHI,CX,F,CHANPAIRS] = CHANPAIRCOH(V,FS)
%   Compute coherence between each pair of channels in the dataset V with
%   sampling rate FS. For NxC matrix V, with N samples and C channels, the
%   output COH will be MxK with M frequency bins and K = NCHOOSEK(C,2)
%   channel pairs. By default, data will be segmented into nonoverlapping
%   2-second segments, coherence averaged over segments. Returns COH, the
%   magnitude coherence; PHI, the phase of the coherency; CX, the
%   cross-spectra; F, the frequency vector corresponding to the first
%   dimension of the other outputs; and CHANPAIRS, the Kx2 list of channel
%   pairs.
%
%   [...] = CHANPAIRCOH(V,FS,MOVINGWIN,TAPERS,FPASS,TRIALAVE)
%   Optionally specify values for MOVINGWIN as [WINSIZE STEPSIZE] (in
%   seconds); TAPERS as for Chronux, e.g., [TW K] where TW is the
%   time-bandwidth product and K is the number of tapers to be used; FPASS
%   the range of frequencies to include in the output, as [MIN_FREQ
%   MAX_FREQ]; and TRIALAVE, a logical value indicating whether to average
%   results over time windows.
%
%   [...] = CHANPAIRCOH(...,'NOPAR[ALLEL]',TRUE|FALSE);
%   [...] = CHANPAIRCOH(...,'NUMWORKERS',NUM);
%   [...] = CHANPAIRCOH(...,'GPU',TRUE|FALSE);
%   By default, will prioritize (1) gpu; (2) parfor/cpu; (3) no parfor. Use
%   these options to disable any parallel processing whatsoever (NOPAR set
%   to TRUE), set the number of workers for the PARFOR loop (if GPU is
%   disabled), or enable/disable the GPU.
assert(nargin>=2,'Must provide at least V and FS');
if size(v,2)/size(v,1)>=10
    warning('Input V should have columns as channels, rows as timestamps');
    v = v';
end

% process variable inputs
[varargin,movingwin] = util.argkeyval('movingwin',varargin,nan);
[varargin,tapers] = util.argkeyval('tapers',varargin,[2 3]);
[varargin,fpass] = util.argkeyval('fpass',varargin,[0 200]);
[varargin,trialave] = util.argkeyval('trialave',varargin,false);
[varargin,flag_single_threaded] = util.argflag('noparallel',varargin,false,5);
flag_parallel = ~flag_single_threaded;
[varargin,nworkers] = util.argkeyval('numworkers',varargin,env.get('numproc'));
[varargin,flag_gpu] = util.argflag('gpu',varargin,flag_parallel&env.get('hasgpu'));
assert(~flag_gpu|flag_parallel,'Parallel processing must be enabled for GPU');
util.argempty(varargin);

% Chronux parameters
chr.Fs = fs;
chr.tapers = tapers;
chr.fpass = fpass;
chr.pad = 0;
chr.trialave = trialave;
chr.err = [0 0.05];

% run the first pair to get dimensions
if trialave || all(isnan(movingwin))
    [f,~,~,~,findx] = util.chronux_dim(chr,size(v,1),[],class(v));
    t = nan;
else
    [f,t,~,~,findx] = util.chronux_dim(chr,size(v,1),movingwin,class(v));
    t = t - movingwin(1)/2;
end

% segment the data into moving windows
nch = size(v,2);
v = segment(v,movingwin,fs);

% set up channel pairs
chanpairs = nchoosek(1:nch,2);
npairs = size(chanpairs,1);

% init values for chronux
N = size(v,1);
nfft = max(2^(nextpow2(N)+chr.pad),N);
tapers = chronux.hlp.dpsschk(chr.tapers,N,fs); % check tapers
if flag_gpu
    nfft = gpuArray(nfft);
    f = gpuArray(f);
    findx = gpuArray(findx);
    tapers = gpuArray(tapers);
end
init = struct('nfft',nfft,'f',f,'findx',findx,'tapers',tapers);

% compute coherence
if flag_parallel
    if flag_gpu
        
        % initialize variables
        coh = zeros(length(f),length(t),npairs,class(v),'gpuArray');
        phi = zeros(length(f),length(t),npairs,class(v),'gpuArray');
        cx = zeros(length(f),length(t),npairs,class(v),'gpuArray');
        
        % first, create J
        nch = size(v,3);
        J = cell(1,nch);
        for cc=1:nch
            local_J = nan(length(f),chr.tapers(2),length(t),'gpuArray');
            for tt=1:length(t)
                local_J(:,:,tt) = chronux_gpu.ct.coherencyc_pt1(v(:,tt,cc),chr,init);
            end
            J{cc} = local_J;
        end
        
        % now loop over pairs (all J already in GPU memory)
        J1 = J(chanpairs(:,1));
        J2 = J(chanpairs(:,2));
        for pp=1:size(chanpairs,1)
            
            % generate new data
            local_J1 = J1{pp};
            local_J2 = J2{pp};
            
            % run coherence
            [coh(:,:,pp),phi(:,:,pp),cx(:,:,pp)] = chronux_gpu.ct.coherencyc_pt2(local_J1,local_J2,chr.trialave,chr.err);
        end
        
        % transfer results back to CPU memory
        coh = gather(coh);
        phi = gather(phi);
        cx = gather(cx);
    else
        
        % initialize variables
        coh = zeros(length(f),length(t),npairs,class(v));
        phi = zeros(length(f),length(t),npairs,class(v));
        cx = zeros(length(f),length(t),npairs,class(v));
        
        % run NUMWORKERS channels in parallel using PARFOR
        for cp=1:nworkers:npairs
            
            % get indices into chanpairs
            idx_ch = cp:min(npairs,cp+nworkers-1);
            nch = length(idx_ch);
            
            % pull out just the data for this iteration
            v1 = v(:,:,chanpairs(idx_ch,1));
            v2 = v(:,:,chanpairs(idx_ch,2));
            tmpcoh = zeros(length(f),length(t),nch);
            tmpphi = zeros(length(f),length(t),nch);
            tmpcx = zeros(length(f),length(t),nch);
            parfor kk=1:length(idx_ch)
                [tmpcoh(:,:,kk),tmpphi(:,:,kk),tmpcx(:,:,kk)] = chronux.ct.coherencyc(v1(:,:,kk),v2(:,:,kk),chr);
            end
            
            % save results
            coh(:,:,idx_ch) = tmpcoh;
            phi(:,:,idx_ch) = tmpphi;
            cx(:,:,idx_ch) = tmpcx;
        end
    end
else
    
    % initialize variables
    coh = zeros(length(f),length(t),npairs,class(v));
    phi = zeros(length(f),length(t),npairs,class(v));
    cx = zeros(length(f),length(t),npairs,class(v));
    
    % run single-threaded loop
    for kk=1:npairs
        [coh(:,:,kk),phi(:,:,kk),cx(:,:,kk)] = chronux.ct.coherencyc(v(:,:,chanpairs(kk,1)),v(:,:,chanpairs(kk,2)),chr);
    end
end

% remove singleton dimensions
coh = squeeze(coh);
phi = squeeze(phi);
cx = squeeze(cx);


function v = segment(v,movingwin,fs)

% segment the data
if all(isnan(movingwin))
    
    % nothing to do
    v = permute(v,[1 3 2]);
elseif movingwin(1)==movingwin(2)
    
    % compute number of segments
    nseg = floor(size(v,1)/(movingwin(1)*fs));
    
    % reshape the data to that many segments (no overlap, so no change in
    % number of elements in v)
    v = reshape(v(1:movingwin(1)*fs*nseg,:),movingwin(1)*fs,nseg,size(v,2));
    
    % get rid of any segment with a nan in it
    idxnan = arrayfun(@(x)any(any(isnan(squeeze(v(:,x,:))))),1:nseg);
    v(:,idxnan,:) = [];
else
    
    % compute number of segments
    N = size(v,1);
    nch = size(v,2);
    nwin = round(fs*movingwin(1)); % number of samples in window
    nstep = round(movingwin(2)*fs); % number of samples to step through
    winstart=(1:nstep:N-nwin+1)';
    t=winstart/fs;
    nseg = length(t);
    
    % pre-allocate v
    oldv = v;
    v = nan(nwin,nseg,nch);
    for ss=1:nseg
        v(:,ss,:) = oldv((winstart(ss)-1) + (1:nwin),:);
    end
    clear oldv;
end