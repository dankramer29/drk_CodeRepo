function [C,phi,S12,S1,S2,f]=coherencyxc(data,params)
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
data=chronux.hlp.change_row_to_column(data);
if nargin < 2; params=[]; end;
[tapers,pad,Fs,fpass,err,trialave]=chronux.hlp.getparams(params);
if err(1)~=0
    error('Errors are not yet implemented');
end
N=size(data,1);
nfft=max(2^(nextpow2(N)+pad),N);
[f,findx]=chronux.hlp.getfgrid(Fs,nfft,fpass);
tapers=chronux.hlp.dpsschk(tapers,N,Fs); % check tapers
J=chronux.ct.mtfftc(data,tapers,nfft,Fs);
J=J(findx,:,:);

pairs=nchoosek(1:size(J,3),2);
J1=J(:,:,pairs(:,1));
J2=J(:,:,pairs(:,2));
S12=nan([size(J,1) size(pairs,1)],class(data));
S1=nan([size(J,1) size(pairs,1)],class(data));
S2=nan([size(J,1) size(pairs,1)],class(data));
[C,phi] = arrayfun(@(pp)localcalc(J1(:,:,pp),J2(:,:,pp),trialave),1:size(pairs,1));

function [C,phi]=localcalc(J1p,J2p,trialave)
S12(:,pp)=squeeze(mean(conj(J1p).*J2p,2));
S1(:,pp)=squeeze(mean(conj(J1p).*J1p,2));
S2(:,pp)=squeeze(mean(conj(J2p).*J2p,2));
if trialave; S12=squeeze(mean(S12,2)); S1=squeeze(mean(S1,2)); S2=squeeze(mean(S2,2)); end;
C12=S12./sqrt(S1.*S2);
C(:,pp)=abs(C12);
phi(:,pp)=angle(C12);