function [C,phi,S12,S1,S2,t,f,confC,phistd,Cerr]=cohgramc(data1,data2,movingwin,params)
% GPU-based multi-taper time-frequency coherence,cross-spectrum and individual spectra - continuous processes
%
% Usage:
%
% [C,phi,S12,S1,S2,t,f,confC,phistd,Cerr]=cohgramc(data1,data2,movingwin,params)
% Input: 
% Note units have to be consistent. Thus, if movingwin is in seconds, Fs
% has to be in Hz. see chronux.m for more information.
%
%       data1 (in form samples x trials) -- required
%       data2 (in form samples x trials) -- required
%       movingwin (in the form [window winstep] -- required
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
%           trialave (average over trials when 1, don't average when 0) - optional. Default 0
% Output:
%       C (magnitude of coherency time x frequencies x trials for trialave=0; 
%             time x frequency for trialave=1)
%       phi (phase of coherency time x frequencies x trials for no trial averaging; 
%             time x frequency for trialave=1)
%       S12 (cross spectrum - time x frequencies x trials for no trial averaging; 
%             time x frequency for trialave=1)
%       S1 (spectrum 1 - time x frequencies x trials for no trial averaging; 
%             time x frequency for trialave=1)
%       S2 (spectrum 2 - time x frequencies x trials for no trial averaging; 
%             time x frequency for trialave=1)
%       t (time)
%       f (frequencies)
%       confC (confidence level for C at 1-p %) - only for err(1)>=1
%       phistd - theoretical/jackknife (depending on err(1)=1/err(1)=2) standard deviation for phi
%                Note that phi + 2 phistd and phi - 2 phistd will give 95% confidence
%                bands for phi - only for err(1)>=1 
%       Cerr  (Jackknife error bars for C - use only for Jackknife - err(1)=2)

if nargin < 3; error('Need data1 and data2 and window parameters'); end;
if nargin < 4; params=[];end;

if ~isempty(params) && length(params.tapers)==3 && movingwin(1)~=params.tapers(2);
    error('Duration of data in params.tapers is inconsistent with movingwin(1), modify params.tapers(2) to proceed')
end

[tapers,pad,Fs,fpass,err,trialave,params]=chronux_gpu.hlp.getparams(params);

if nargout > 9 && err(1)~=2; 
    error('Cerr computed only for Jackknife. Correct inputs and run again');
end;
if nargout > 7 && err(1)==0;
    error('When errors are desired, err(1) has to be non-zero.');
end;
[N,Ch]=chronux_gpu.hlp.check_consistency(data1,data2);

Nwin=round(Fs*movingwin(1)); % number of samples in window
Nstep=round(movingwin(2)*Fs); % number of samples to step through
nfft=max(2^(nextpow2(Nwin)+pad),Nwin);
[f,findx]=chronux_gpu.hlp.getfgrid(Fs,nfft,fpass); 
Nf=length(f);
params.tapers=chronux_gpu.hlp.dpsschk(tapers,Nwin,Fs,0); % check tapers

init.nfft = nfft;
init.f = f;
init.findx = findx;
init.tapers = params.tapers;

winstart=1:Nstep:N-Nwin+1;
nw=length(winstart);

% calculate how much space will be needed for full output
if trialave
    sz_C=[nw Nf 1];
    sz_S12=[nw Nf 1];
    sz_S1=[nw Nf 1];
    sz_S2=[nw Nf 1];
    sz_phi=[ns Nf 1];
    if nargout>=10; sz_Cerr=[2 nw Nf 1]; end
    if nargout>=9; sz_phistd=[nw Nf 1]; end
else
    sz_C=[nw Nf Ch];
    sz_S12=[nw Nf Ch];
    sz_S1=[nw Nf Ch];
    sz_S2=[nw Nf Ch];
    sz_phi=[nw Nf Ch];
    if nargout>=10; sz_Cerr=[2 nw Nf Ch]; end
    if nargout>=9; sz_phistd=[nw Nf Ch]; end
end

% calculate how many data elements will fit in GPU memory
datatype=class(data1); datatype2=class(data2);
assert(strcmpi(datatype,datatype2),'Data must be of same class (classes were %s)',strjoin({datatype,datatype2},', '));
safetyFactor=10; % Based on trial and error. Requiring 10x the input seems safe.
elementSize=gpu.sizeof(datatype);
gpd=gpuDevice();
freeMem=gpd.FreeMemory;
maxNumElements=floor(freeMem/(elementSize*safetyFactor));

% determine window indices for each computational block
elementsPerWin_C=sz_C(2)*sz_C(3);
elementsPerWin_S12=sz_S12(2)*sz_S12(3);
elementsPerWin_S1=sz_S1(2)*sz_S1(3);
elementsPerWin_S2=sz_S2(2)*sz_S2(3);
elementsPerWin_phi=sz_phi(2)*sz_phi(3);
elementsPerWin_Cerr=0;
if nargout>=10; elementsPerWin_Cerr=sz_Cerr(1)*sz_Cerr(3)*sz_Cerr(4); end
elementsPerWin_phistd=0;
if nargout>=9; elementsPerWin_phistd=sz_phistd(2)*sz_phistd(3); end
elementsPerWin_data1=Nwin*Ch;
elementsPerWin_data2=Nwin*Ch;
elementsPerWin=...
    elementsPerWin_C+...
    elementsPerWin_S12+...
    elementsPerWin_S1+...
    elementsPerWin_S2+...
    elementsPerWin_phi+...
    elementsPerWin_Cerr+...
    elementsPerWin_phistd+...
    elementsPerWin_data1+...
    elementsPerWin_data2;
numWinsPerBlock=floor(maxNumElements/elementsPerWin);
numBlocks=ceil(nw/numWinsPerBlock);
blockWinIdx=reshape(1:max(nw,numWinsPerBlock*numBlocks),numWinsPerBlock,numBlocks);
blockWinIdx=arrayfun(@(x)blockWinIdx(:,x),1:numBlocks,'UniformOutput',false);
blockWinIdx{end}(blockWinIdx{end}>nw)=[];
blockDataIdx=arrayfun(@(x)winstart(blockWinIdx{x}(1)):winstart(blockWinIdx{x}(end))+Nwin-1,1:numBlocks,'UniformOutput',false);

% loop over blocks
C = cell(1,numBlocks);
S12 = cell(1,numBlocks);
S1 = cell(1,numBlocks);
S2 = cell(1,numBlocks);
phi = cell(1,numBlocks);
Cerr = cell(1,numBlocks);
phistd = cell(1,numBlocks);
for bb=1:numBlocks
    numWinsInBlock=length(blockWinIdx{bb});
    
    % pre-allocate data for this block
    C{bb}=zeros([numWinsInBlock sz_C(2) sz_C(3)],datatype,'gpuArray');
    S12{bb}=zeros([numWinsInBlock sz_S12(2) sz_S12(3)],datatype,'gpuArray');
    S1{bb}=zeros([numWinsInBlock sz_S1(2) sz_S1(3)],datatype,'gpuArray');
    S2{bb}=zeros([numWinsInBlock sz_S2(2) sz_S2(3)],datatype,'gpuArray');
    phi{bb}=zeros([numWinsInBlock sz_phi(2) sz_phi(3)],datatype,'gpuArray');
    if nargout>=9; phistd{bb}=zeros([numWinsInBlock sz_phistd(2) sz_phistd(3)],datatype,'gpuArray'); end
    if nargout>=10; Cerr{bb}=zeros([sz_Cerr(1) numWinsInBlock sz_Cerr(3) sz_Cerr(4)],datatype,'gpuArray'); end
    
    % pull out all data for this block
    winstartblock=winstart(blockWinIdx{bb});
    winstartblock_zeroed=winstartblock-winstartblock(1)+1;
    data1block=gpuArray(data1(blockDataIdx{bb},:));
    data2block=gpuArray(data2(blockDataIdx{bb},:));
        
    % calculate cohgram for this block
    for nn=1:numWinsInBlock;
        indx=winstartblock_zeroed(nn):winstartblock_zeroed(nn)+Nwin-1;
        datawin1=data1block(indx,:);
        datawin2=data2block(indx,:);
        if nargout==10;
            [C{bb}(nn,:,:),phi{bb}(nn,:,:),S12{bb}(nn,:,:),S1{bb}(nn,:,:),S2{bb}(nn,:,:),f,confC,phistd{bb}(nn,:,:),Cerr{bb}(:,nn,:,:)]=chronux_gpu.ct.coherencyc(datawin1,datawin2,params,init,1);
        elseif nargout==9;
            [C{bb}(nn,:,:),phi{bb}(nn,:,:),S12{bb}(nn,:,:),S1{bb}(nn,:,:),S2{bb}(nn,:,:),f,confC,phistd{bb}(nn,:,:)]=chronux_gpu.ct.coherencyc(datawin1,datawin2,params,init,1);
        else
            [C{bb}(nn,:,:),phi{bb}(nn,:,:),S12{bb}(nn,:,:),S1{bb}(nn,:,:),S2{bb}(nn,:,:),f]=chronux_gpu.ct.coherencyc(datawin1,datawin2,params,init,1);
        end;
        
        % gather this block back into main memory
        C{bb}=gather(C{bb});
        S12{bb}=gather(S12{bb});
        S1{bb}=gather(S1{bb});
        S2{bb}=gather(S2{bb});
        phi{bb}=gather(phi{bb});
        if nargout>=10;Cerr{bb}=gather(Cerr{bb});end
        if nargout>=9;phistd{bb}=gather(phistd{bb});end
        
        % check for imaginary data
        if nnz(imag(C{bb}(:)))==0;C{bb}=real(C{bb});end
        if nnz(imag(S12{bb}(:)))==0;S12{bb}=real(S12{bb});end
        if nnz(imag(S1{bb}(:)))==0;S1{bb}=real(S1{bb});end
        if nnz(imag(S2{bb}(:)))==0;S2{bb}=real(S2{bb});end
        if nnz(imag(phi{bb}(:)))==0;phi{bb}=real(phi{bb});end
    end
end
C=squeeze(cat(1,C{:}));
S12=squeeze(cat(1,S12{:}));
S1=squeeze(cat(1,S1{:}));
S2=squeeze(cat(1,S2{:}));
phi=squeeze(cat(1,phi{:}));
if nargout>=10;Cerr=squeeze(cat(2,Cerr{:}));end
if nargout>=9;phistd=squeeze(cat(1,phistd{:}));end
% if nargout>=9; phierr=squeeze(phierr);end
winmid=winstart+round(Nwin/2);
t=winmid/Fs;
