function [S,f,Serr]=mtspectrumc(data,params,init,gpuflag)
% GPU-based Multi-taper spectrum - continuous process
%
% Usage:
%
% [S,f,Serr]=mtspectrumc(data,params)
% Input:
% Note units have to be consistent. See chronux.m for more information.
%       data (in form samples x channels/trials) -- required
%       params: structure with fields tapers, pad, Fs, fpass, err, trialave
%       -optional
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
%           trialave (average over trials/channels when 1, don't average when 0) - optional. Default 0
% Output:
%       S       (spectrum in form frequency x channels/trials if trialave=0;
%               in the form frequency if trialave=1)
%       f       (frequencies)
%       Serr    (error bars) only for err(1)>=1

if nargin < 1; error('Need data'); end;
if nargin < 2; params=[]; end;
if nargin < 3; init=[]; end;
if nargin < 4; gpuflag=false; end;
[tapers,pad,Fs,fpass,err,trialave,params]=chronux_gpu.hlp.getparams(params);
if nargout > 2 && err(1)==0; 
%   Cannot compute error bars with err(1)=0. Change params and run again. 
    error('When Serr is desired, err(1) has to be non-zero.');
end;
data=chronux_gpu.hlp.change_row_to_column(data);
if ~isempty(init)
    nfft = init.nfft;
    f = init.f;
    findx = init.findx;
    tapers = init.tapers;
else
    if isa(data,'gpuArray')
        datatype=classUnderlying(data);
    else
        datatype=class(data);
    end
    N=size(data,1);
    nfft=max(2^(nextpow2(N)+pad),N);
    [f,findx]=chronux_gpu.hlp.getfgrid(Fs,nfft,fpass,1);
    tapers=chronux_gpu.hlp.dpsschk(tapers,N,Fs,1,datatype); % check tapers
end
if any(isnan(data(:)))
    S = nan(length(f),size(data,2)); % we already know it will be all nans if there are any nans in input
    return;
end
if gpuflag; nfft=gpuArray(nfft); end
J=chronux_gpu.ct.mtfftc(data,tapers,nfft,Fs,1);
J=J(findx,:,:);
S=permute(mean(conj(J).*J,2),[1 3 2]);
if any(imag(S(:))~=0)
    energyR = sqrt(nansum(real(S(:)).^2));
    energyI = sqrt(nansum(imag(S(:)).^2));
    compI = energyI/(energyI+energyR);
    if compI>0.01
        warning('Imaginary component has a lot of energy...');
        keyboard;
    end
    assert(compI<=0.01,'Imaginary part accounts for more than %.2f%% of the total signal energy',100*compI);
    S=real(S); % account for rounding error
end
if trialave; S=squeeze(mean(S,2));else S=squeeze(S);end;
if nargout==3; 
   Serr=chronux_gpu.hlp.specerr(S,J,err,trialave);
end;
if gpuflag;
    if nargout>=1;
        S=gather(S);
        if nnz(imag(S(:)))==0;S=real(S);end
    end
    if nargout>=2; f=gather(f); end
    if nargout>=3;
        Serr=gather(Serr);
        if nnz(imag(Serr(:)))==0;Serr=real(Serr);end
    end
end