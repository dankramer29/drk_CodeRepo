function [C,phi,S12,f,zerosp,confC,phistd,Cerr]=cohmatrixpb(data,params,fscorr)
% Multi-taper coherency matrix - binned point process
%
% Usage:
%
% [C,phi,S12,f,zerosp,confC,phistd,Cerr]=cohmatrixpb(data,params,fscorr)
% Input: 
%       data (in form samples x channels) -- required
%       params: structure with fields tapers, pad, Fs, fpass, err
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
%       fscorr   (finite size corrections, 0 (don't use finite size corrections) or 
%                1 (use finite size corrections) - optional
%                (available only for spikes). Defaults 0.
% Output:
%       C (magnitude of coherency frequency x channels x channels)
%       phi (phase of coherency frequency x channels x channels)
%       S12 (cross-spectral matrix frequency x channels x channels)
%       f (frequencies)
%       zerosp (1 for channels where no spikes were found, zero otherwise)
%       confC (confidence level for C at 1-p %) - only for err(1)>=1
%       phistd - jackknife/theoretical standard deviation for phi - Note that 
%                phi + 2 phistd and phi -2 phistd will give 95% confidence bands for phi
%                - only for err(1)>=1
%       Cerr  (Jackknife error bars for C - use only for Jackknife - err(1)=2)

[N,Ch]=size(data);
if Ch==1; error('Need at least two channels of data'); end;
if nargin < 2; params=[]; end;
[tapers,pad,Fs,fpass,err,trialave,params]=chronux.hlp.getparams(params);
clear trialave params
if nargin < 3 || isempty(fscorr); fscorr=0; end;

nfft=max(2^(nextpow2(N)+pad),N);
[f,findx]=chronux.hlp.getfgrid(Fs,nfft,fpass); 
tapers=dpsschk(tapers,N,Fs); % check tapers
[J,Msp,Nsp]=chronux.pb.mtfftpb(data,tapers,nfft);
C1=size(J,3); 
zerosp=zeros(1,C1); % initialize the zerosp variable
zerosp(Nsp==0)=0; % set the zerosp variable
J=J(findx,:,:); 
if err(1)==0;
     [C,phi,S12]=chronux.hlp.cohmathelper(J,err);
elseif err(1)==1;
     if fscorr==0;
       [C,phi,S12,confC,phistd]=chronux.hlp.cohmathelper(J,err);
    else
       [C,phi,S12,confC,phistd]=chronux.hlp.cohmathelper(J,err,Nsp);
    end;
elseif err(1)==2;
     if fscorr==0;
       [C,phi,S12,confC,phistd,Cerr]=chronux.hlp.cohmathelper(J,err);
    else
       [C,phi,S12,confC,phistd,Cerr]=chronux.hlp.cohmathelper(J,err,Nsp);
    end;
end
clear Msp
