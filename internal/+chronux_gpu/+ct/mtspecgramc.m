function [S,t,f,Serr]=mtspecgramc(data,movingwin,params)
% GPU-based Multi-taper time-frequency spectrum - continuous process
%
% Usage:
% [S,t,f,Serr]=mtspecgramc(data,movingwin,params)
% Input:
% Note units have to be consistent. Thus, if movingwin is in seconds, Fs
% has to be in Hz. see chronux.m for more information.
%       data        (in form samples x channels/trials) -- required
%       movingwin         (in the form [window winstep] i.e length of moving
%                                                 window and step size)
%                                                 Note that units here have
%                                                 to be consistent with
%                                                 units of Fs - required
%       params: structure with fields tapers, pad, Fs, fpass, err, trialave
%       - optional
%           tapers : precalculated tapers from dpss or in the one of the following
%                    forms:
%                    (1) A numeric vector [TW K] where TW is the
%                        time-bandwidth product and K is the number of
%                        tapers to be used (less than or equal to
%                        2TW-1).
%                    (2) A numeric vector [W T p] where W is the
%                        bandwidth, T is the duration of the data and p
%                        is an integer such that 2TW-p tapers are used. In
%                        this form there is no default i.e. to specify
%                        the bandwidth, you have to specify T and p as
%                        well. Note that the units of W and T have to be
%                        consistent: if W is in Hz, T must be in seconds
%                        and vice versa. Note that these units must also
%                        be consistent with the units of params.Fs: W can
%                        be in Hz if and only if params.Fs is in Hz.
%                        The default is to use form 1 with TW=3 and K=5
%                     Note that T has to be equal to movingwin(1).
%
%	        pad		    (padding factor for the FFT) - optional (can take values -1,0,1,2...).
%                    -1 corresponds to no padding, 0 corresponds to padding
%                    to the next highest power of 2 etc.
%			      	 e.g. For N = 500, if PAD = -1, we do not pad; if PAD = 0, we pad the FFT
%			      	 to 512 points, if pad=1, we pad to 1024 points etc.
%			      	 Defaults to 0.
%           Fs   (sampling frequency) - optional. Default 1.
%           fpass    (frequency band to be used in the calculation in the form
%                                   [fmin fmax])- optional.
%                                   Default all frequencies between 0 and Fs/2
%           err  (error calculation [1 p] - Theoretical error bars; [2 p] - Jackknife error bars
%                                   [0 p] or 0 - no error bars) - optional. Default 0.
%           trialave (average over trials/channels when 1, don't average when 0) - optional. Default 0
% Output:
%       S       (spectrum in form time x frequency x channels/trials if trialave=0;
%               in the form time x frequency if trialave=1)
%       t       (times)
%       f       (frequencies)
%       Serr    (error bars) only for err(1)>=1

if nargin < 2; error('Need data and window parameters'); end;
if nargin < 3; params=[]; end;
if isa(data,'gpuArray')
    datatype=classUnderlying(data);
else
    datatype=class(data);
end

assert(isempty(params)||length(params.tapers)~=3||movingwin(1)==params.tapers(2),'Duration of data in params.tapers is inconsistent with movingwin(1), modify params.tapers(2) to proceed');

[tapers,pad,Fs,fpass,err,trialave,params]=chronux_gpu.hlp.getparams(params);
assert(nargout<=3||err(1)~=0,'When Serr is desired, err(1) has to be non-zero.');
[N,Ch]=size(data);

Nwin=round(Fs*movingwin(1)); % number of samples in window
Nstep=round(movingwin(2)*Fs); % number of samples to step through
nfft=max(2^(nextpow2(Nwin)+pad),Nwin);
[f,findx]=chronux_gpu.hlp.getfgrid(Fs,nfft,fpass);
Nf=length(f);
params.tapers=chronux_gpu.hlp.dpsschk(tapers,Nwin,Fs,0,datatype); % check tapers

init.nfft = nfft;
init.f = f;
init.findx = findx;
init.tapers = params.tapers;

winstart=1:Nstep:N-Nwin+1;
nw=length(winstart);

% calculate how much space will be needed for full output
if trialave
    sz_S=[nw Nf 1];
    if nargout==4; sz_Serr=[2 nw Nf 1]; end
else
    sz_S=[nw Nf Ch];
    if nargout==4; sz_Serr=[2 nw Nf Ch]; end
end

% calculate how many data elements will fit in GPU memory
safetyFactor=10; % Based on trial and error. Requiring 10x the input seems safe.
elementSize=gpu.sizeof(datatype);
gpd=gpuDevice();
freeMem=gpd.FreeMemory;
maxNumElements=floor(freeMem/(elementSize*safetyFactor));

% determine window indices for each computational block
elementsPerWin_S=nfft*sz_S(3);
if nargout==4
    elementsPerWin_Serr=sz_Serr(1)*sz_Serr(3)*sz_Serr(4);
else
    elementsPerWin_Serr=0;
end
elementsPerWin_data=Nwin*Ch;
elementsPerWin=elementsPerWin_S+elementsPerWin_Serr+elementsPerWin_data;
numWinsPerBlock=floor(maxNumElements/elementsPerWin);
numBlocks=ceil(nw/numWinsPerBlock);
blockWinIdx=reshape(1:max(nw,numWinsPerBlock*numBlocks),numWinsPerBlock,numBlocks);
blockWinIdx=arrayfun(@(x)blockWinIdx(:,x),1:numBlocks,'UniformOutput',false);
blockWinIdx{end}(blockWinIdx{end}>nw)=[];
blockDataIdx=arrayfun(@(x)winstart(blockWinIdx{x}(1)):winstart(blockWinIdx{x}(end))+Nwin-1,1:numBlocks,'UniformOutput',false);

% loop over blocks
S = cell(1,numBlocks);
Serr = cell(1,numBlocks);
for bb=1:numBlocks
    numWinsInBlock=length(blockWinIdx{bb});
    
    % pre-allocate data for this block
    S{bb}=nan([numWinsInBlock sz_S(2) sz_S(3)],datatype,'gpuArray');
    if nargout==4; Serr{bb}=zeros([sz_Serr(1) numWinsInBlock sz_Serr(3) sz_Serr(4)],datatype,'gpuArray'); end
    
    % pull out all data for this block
    winstartblock=winstart(blockWinIdx{bb});
    winstartblock_zeroed=winstartblock-winstartblock(1)+1;
    datablock=gpuArray(data(blockDataIdx{bb},:));
    
    % calculate specgram for this block
    for nn=1:numWinsInBlock
        indx=winstartblock_zeroed(nn):winstartblock_zeroed(nn)+Nwin-1;
        datawin=datablock(indx,:);
        if any(isnan(datawin(:))),continue;end
        if nargout==4
            [S{bb}(nn,:,:),f,Serr{bb}(:,nn,:,:)]=chronux_gpu.ct.mtspectrumc(datawin,params,init,1);
        else
            [S{bb}(nn,:,:),f]=chronux_gpu.ct.mtspectrumc(datawin,params,init,1);
        end
    end
    
    % gather this block back into main memory
    S{bb}=gather(S{bb});
    if nargout==4;Serr{bb}=gather(Serr{bb});end
    
    % check for imaginary data
    imparts = imag(S{bb});
    if nnz(imparts(:))==0,S{bb}=real(S{bb});end
end
S=cat(1,S{:}); % concatenate cells of S into one large array
if nargout==4;Serr=cat(2,Serr{:});end;
winmid=winstart+round(Nwin/2);
if nargout>=1; S=gather(S); end
if nargout>=2; t=gather(winmid/Fs); end
if nargout>=3; f=gather(f); end
if nargout>=4; Serr=gather(Serr); end