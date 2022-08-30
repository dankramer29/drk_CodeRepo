function [J2, zerosp, Nsp2]=coherencycpt_pt1_spk(data2,params,t)
% Multi-taper coherency,cross-spectrum and individual spectra -continuous data and point process as times
%
% Usage:
%
% [C,phi,S12,S1,S2,f,zerosp,confC,phistd,Cerr]=coherencycpt(data1,data2,params,fscorr,t)
% Input:
%       data1        (continuous data in time x trials form) -- required
%       data2        (structure array of spike times with dimension trials;
%                     also accepts 1d array of spike times) -- required
%       params: structure with fields tapers, pad, Fs, fpass, err, trialave
%       - optional
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
%           err  (error calculation [1 p] - Theoretical error bars; [2 p] - Jackknife error bars
%                                   [0 p] or 0 - no error bars) - optional. Default 0.
%           trialave (average over trials when 1, don't average when 0) - optional. Default 0
%       fscorr   (finite size corrections, 0 (don't use finite size corrections) or
%                                          1 (use finite size corrections) - optional
%                (available only for spikes). Defaults 0.
%       t        (time grid over which the tapers are to be calculated:
%                      this argument is useful when calling the spectrum
%                      calculation routine from a moving window spectrogram
%                      calculation routine). If left empty, the spike times
%                      are used to define the grid.
% Output:
%       C (magnitude of coherency - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       phi (phase of coherency - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       S12 (cross spectrum -  frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       S1 (spectrum 1 - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       S2 (spectrum 2 - frequencies x trials if trialave=0; dimension frequencies if trialave=1)
%       f (frequencies)
%       zerosp (1 for trials where no spikes were found, 0 otherwise)
%       confC (confidence level for C at 1-p %) - only for err(1)>=1
%       phistd - theoretical/jackknife (depending on err(1)=1/err(1)=2) standard deviation for phi
%                Note that phi + 2 phistd and phi - 2 phistd will give 95% confidence
%                bands for phi - only for err(1)>=1
%       Cerr  (Jackknife error bars for C - use only for Jackknife - err(1)=2)

if nargin < 1; error('Need data2 (spike data)'); end;
if nargin < 2; params=[]; end;
[tapers,pad,Fs,fpass,err,trialave,params]=chronux_gpu.hlp.getparams(params);
clear params
if nargin < 3 || isempty(t);    error('Need time grid for spike data'); end;
if nargout > 7 && err(1)==0;
    %   Errors computed only if err(1) is non-zero. Need to change params and run again.
    error('When errors are desired, err(1) has to be non-zero.');
end;
if nargout > 9 && err(1)~=2;
    error('Cerr computed only for Jackknife. Correct inputs and run again');
end;

[N,Ch]=size(data2);
zerosp=zeros(1,Ch); % intialize the zerosp variable
N=length(t); % number of points in grid for dpss
nfft=max(2^(nextpow2(N)+pad),N); % number of points in fft of prolates
[f,findx]=chronux_gpu.hlp.getfgrid(Fs,nfft,fpass);
tapers=chronux_gpu.hlp.dpsschk(tapers,N,Fs); % check tapers

[J2,Msp2,Nsp2]=chronux.pt.mtfftpt(data2,tapers,nfft,t,f,findx); % fourier transform of discrete data
zerosp(Nsp2==0)=1; % set zerosp to 1 for trials where no spikes were found