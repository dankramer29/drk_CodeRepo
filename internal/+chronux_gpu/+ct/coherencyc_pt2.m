function [C,phi,S12,S1,S2,confC,phistd,Cerr]=coherencyc_pt2(J1,J2,trialave,err)
% GPU-based multi-taper coherency,cross-spectrum and individual spectra - continuous process
%
% Usage:
% [C,phi,S12,S1,S2,f,confC,phistd,Cerr]=coherencyc(data1,data2,params)
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
%       confC (confidence level for C at 1-p %) - only for err(1)>=1
%       phistd - theoretical/jackknife (depending on err(1)=1/err(1)=2) standard deviation for phi. 
%                Note that phi + 2 phistd and phi - 2 phistd will give 95% confidence
%                bands for phi - only for err(1)>=1 
%       Cerr  (Jackknife error bars for C - use only for Jackknife - err(1)=2)

S12=squeeze(mean(conj(J1).*J2,2));
S1=squeeze(mean(conj(J1).*J1,2));
if any(imag(S1(:))~=0)
    energyR = sqrt(nansum(real(S1(:)).^2));
    energyI = sqrt(nansum(imag(S1(:)).^2));
    compI = energyI/(energyI+energyR);
    if compI>0.01
        warning('Imaginary component has a lot of energy...');
        keyboard;
    end
    assert(compI<=0.01,'Imaginary part accounts for more than %.2f%% of the total signal energy',100*compI);
    S1=real(S1); % account for rounding error
end
S2=squeeze(mean(conj(J2).*J2,2));
if any(imag(S2(:))~=0)
    energyR = sqrt(nansum(real(S2(:)).^2));
    energyI = sqrt(nansum(imag(S2(:)).^2));
    compI = energyI/(energyI+energyR);
    if compI>0.01
        warning('Imaginary component has a lot of energy...');
        keyboard;
    end
    assert(compI<=0.01,'Imaginary part accounts for more than %.2f%% of the total signal energy',100*compI);
    S2=real(S2); % account for rounding error
end
if trialave; S12=squeeze(mean(S12,2)); S1=squeeze(mean(S1,2)); S2=squeeze(mean(S2,2)); end;
C12=S12./sqrt(S1.*S2);
C=abs(C12); 
phi=angle(C12);
if nargout>=8; 
     [confC,phistd,Cerr]=chronux_gpu.hlp.coherr(C,J1,J2,err,trialave);
elseif nargout==7;
     [confC,phistd]=chronux_gpu.hlp.coherr(C,J1,J2,err,trialave);
end;
