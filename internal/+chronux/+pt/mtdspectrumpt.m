function [dS,f]=mtdspectrumpt(data,phi,params,t)
% Multi-taper spectral derivative - point process times
%
% Usage:
%
% [dS,f]=mtdspectrumpt(data,phi,params,t)
% Input: 
%   Note that all times can be in arbitrary units. But the units have to be
%   consistent. So, if E is in secs, win, t have to be in secs, and Fs has to
%   be Hz. If E is in samples, so are win and t, and Fs=1. In case of spike
%   times, the units have to be consistent with the units of data as well.
%       data        (structure array of spike times with dimension channels/trials; 
%                   also accepts 1d array of spike times) -- required
%       phi         (angle for evaluation of derivative) -- required.
%                       e.g. phi=[0,pi/2] giving the time and frequency derivatives
%       params: structure with fields tapers, pad, Fs, fpass, trialave
%       -optional
%           tapers : precalculated tapers from dpss or in the one of the following
%                    forms: 
%                   (1) A numeric vector [TW K] where TW is the
%                       time-bandwidth product and K is the number of
%                       tapers to be used (less than or equal to
%                       2TW-1). 
%                   (2) A numeric vector [W T p] where W is the
%                       bandwidth, T is the duration of the data and p 
%                       is an integer such that 2TW-p tapers are used. In
%                       this form there is no default i.e. to specify
%                       the bandwidth, you have to specify T and p as
%                       well. Note that the units of W and T have to be
%                       consistent: if W is in Hz, T must be in seconds
%                       and vice versa. Note that these units must also
%                       be consistent with the units of params.Fs: W can
%                       be in Hz if and only if params.Fs is in Hz.
%                       The default is to use form 1 with TW=3 and K=5
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
%           trialave (average over trials when 1, don't average when 0) -
%           optional. Default 0
%       t        (time grid over which the tapers are to be calculated:
%                      this argument is useful when calling the spectrum
%                      calculation routine from a moving window spectrogram
%                      calculation routine). If left empty, the spike times
%                      are used to define the grid.
% Output:
%       dS      (spectral derivative in form phi x frequency x channels/trials if trialave=0; 
%               function of phi x frequency if trialave=1)
%       f       (frequencies)
if nargin < 2; error('Need data and angle'); end;
if nargin < 3; params=[]; end;
[tapers,pad,Fs,fpass,err,trialave,params]=chronux.hlp.getparams(params);
clear err params
data=chronux.hlp.change_row_to_column(data);
dt=1/Fs; % sampling time
if nargin < 4;
   [mintime,maxtime]=chronux.pt.minmaxsptimes(data);
   t=mintime:dt:maxtime+dt; % time grid for prolates
end;
N=length(t); % number of points in grid for dpss
nfft=max(2^(nextpow2(N)+pad),N); % number of points in fft of prolates
[f,findx]=getfgrid(Fs,nfft,fpass); % get frequency grid for evaluation
tapers=dpsschk(tapers,N,Fs); % check tapers
K=size(tapers,2);
J=mtfftpt(data,tapers,nfft,t,f,findx); % mt fft for point process times
A=sqrt(1:K-1);
A=repmat(A,[size(J,1) 1]);
A=repmat(A,[1 1 size(J,3)]);
S=squeeze(mean(J(:,1:K-1,:).*A.*conj(J(:,2:K,:)),2));
if trialave; S=squeeze(mean(S,2));end;
nphi=length(phi);
for p=1:nphi;
    dS(p,:,:)=real(exp(i*phi(p))*S);
end;
dS=squeeze(dS);
dS=chronux.hlp.change_row_to_column(dS);
