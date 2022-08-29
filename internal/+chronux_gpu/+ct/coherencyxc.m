function [C,phi,S12,S1,S2,f,pairs]=coherencyxc(data,params)
% Multi-taper coherency,cross-spectrum and individual spectra - continuous process
%
% Usage:
% [C,phi,S12,S1,S2,f]=coherencyc(data1,data2,params)
% Input:
% Note units have to be consistent. See chronux.m for more information.
%       data1 (in form samples x trials) -- required
%       data2 (in form samples x trials) -- required
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
%       C (magnitude of coherency - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       phi (phase of coherency - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       S12 (cross spectrum -  frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       S1 (spectrum 1 - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       S2 (spectrum 2 - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       f (frequencies)
data=chronux_gpu.hlp.change_row_to_column(data);
if nargin < 2; params=[]; end;
[tapers,pad,Fs,fpass,err,trialave]=chronux_gpu.hlp.getparams(params);
if err(1)~=0
    error('Errors are not yet implemented');
end
if isa(data,'gpuArray')
    datatype=classUnderlying(data);
else
    datatype=class(data);
end
N=size(data,1);
nfft=max(2^(nextpow2(N)+pad),N);
[f,findx]=chronux_gpu.hlp.getfgrid(Fs,nfft,fpass);
tapers=chronux_gpu.hlp.dpsschk(tapers,N,Fs,0,datatype); % check tapers
pairs=nchoosek(1:size(data,2),2);
numPairs=size(pairs,1);

% calculate how many data elements will fit in GPU memory
safetyFactor=30; % Based on trial and error
elementSize=gpu.sizeof(datatype);
dev=gpuDevice();
freeMem=dev.FreeMemory;
maxNumElements=floor(freeMem/(elementSize*safetyFactor));

% determine pair indices for each computational block
elementsPerPair_data=size(data,1)*2;
elementsPerPair_J=nfft*tapers(2)*96;
elementsPerPair_S12=nfft;
elementsPerPair_S1=nfft;
elementsPerPair_S2=nfft;
elementsPerPair=...
    elementsPerPair_data+...
    elementsPerPair_J+...
    elementsPerPair_S12+...
    elementsPerPair_S1+...
    elementsPerPair_S2;
numPairsPerBlock=floor(maxNumElements/elementsPerPair);
numBlocks=ceil(numPairs/numPairsPerBlock);
blockPairIdx=reshape(1:max(numPairs,numPairsPerBlock*numBlocks),numPairsPerBlock,numBlocks);
blockPairIdx=arrayfun(@(x)blockPairIdx(:,x),1:numBlocks,'UniformOutput',false);
blockPairIdx{end}(blockPairIdx{end}>numPairs)=[];

% loop over blocks
S12=cell(1,numBlocks);
S1=cell(1,numBlocks);
S2=cell(1,numBlocks);
for bb=1:numBlocks
    numPairsInBlock=length(blockPairIdx{bb});
    blockpairs=pairs(blockPairIdx{bb},:);
    blockchannels=unique(blockpairs(:));
    for kk=1:length(blockchannels)
        blockpairs(blockpairs(:,1)==blockchannels(kk),1)=kk;
        blockpairs(blockpairs(:,2)==blockchannels(kk),2)=kk;
    end
    
    J=chronux_gpu.ct.mtfftc(data(:,blockchannels),tapers,nfft,Fs,1);
    J=J(findx,:,:);
    
    % pre-allocate for this block
    S12{bb}=nan(nnz(findx),numPairsInBlock,datatype,'gpuArray');
    S1{bb}=nan(nnz(findx),numPairsInBlock,datatype,'gpuArray');
    S2{bb}=nan(nnz(findx),numPairsInBlock,datatype,'gpuArray');
    
    % calculate cross-spectra
    for pp=1:numPairsInBlock
        J1p = J(:,:,blockpairs(pp,1));
        J2p = J(:,:,blockpairs(pp,2));
        S12{bb}(:,pp)=squeeze(mean(conj(J1p).*J2p,2));
        S1{bb}(:,pp)=squeeze(mean(conj(J1p).*J1p,2));
        S2{bb}(:,pp)=squeeze(mean(conj(J2p).*J2p,2));
    end
    
    % gather this block back into main memory
    S12{bb}=gather(S12{bb});
    S1{bb}=gather(S1{bb});
    if any(imag(S1{bb}(:))~=0)
        energyR = sqrt(nansum(real(S1{bb}(:)).^2));
        energyI = sqrt(nansum(imag(S1{bb}(:)).^2));
        compI = energyI/(energyI+energyR);
        if compI>0.01
            warning('Imaginary component has a lot of energy...');
            keyboard;
        end
        assert(compI<=0.01,'Imaginary part accounts for more than %.2f%% of the total signal energy',100*compI);
        S1{bb}=real(S1{bb}); % account for rounding error
    end
    S2{bb}=gather(S2{bb});
    if any(imag(S2{bb}(:))~=0)
        energyR = sqrt(nansum(real(S2{bb}(:)).^2));
        energyI = sqrt(nansum(imag(S2{bb}(:)).^2));
        compI = energyI/(energyI+energyR);
        if compI>0.01
            warning('Imaginary component has a lot of energy...');
            keyboard;
        end
        assert(compI<=0.01,'Imaginary part accounts for more than %.2f%% of the total signal energy',100*compI);
        S2{bb}=real(S2{bb}); % account for rounding error
    end
end
S12=squeeze(cat(2,S12{:}));
S1=squeeze(cat(2,S1{:}));
S2=squeeze(cat(2,S2{:}));
if trialave; S12=squeeze(mean(S12,2)); S1=squeeze(mean(S1,2)); S2=squeeze(mean(S2,2)); end;
C12=S12./sqrt(S1.*S2);
C=abs(C12);
phi=angle(C12);