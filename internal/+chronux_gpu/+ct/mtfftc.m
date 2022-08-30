function J=mtfftc(data,tapers,nfft,Fs,gpuflag)
% Multi-taper fourier transform - continuous data
%
% Usage:
% J=mtfftc(data,tapers,nfft,Fs) - all arguments required
% Input: 
%       data (in form samples x channels/trials or a single vector) 
%       tapers (precalculated tapers from dpss) 
%       nfft (length of padded data)
%       Fs   (sampling frequency)
%                                   
% Output:
%       J (fft in form frequency index x taper index x channels/trials)
if nargin < 4; error('Need all input arguments'); end;
if nargin < 5; gpuflag=false; end;
if gpuflag
    data=gpuArray(data); % move data to GPU
    tapers=gpuArray(tapers);
    nfft=gpuArray(nfft);
    Fs=gpuArray(Fs);
end
data=chronux_gpu.hlp.change_row_to_column(data);
[NC,C]=size(data); % size of data
[NK,K]=size(tapers); % size of tapers
if NK~=NC; error('length of tapers is incompatible with length of data'); end;
tapers=tapers(:,:,ones(1,C)); % add channel indices to tapers
data=data(:,:,ones(1,K)); % add taper indices to data
data=permute(data,[1 3 2]); % reshape data to get dimensions to match those of tapers
data_proj=data.*tapers; % product of data with tapers

% move data to GPU
J=fft(data_proj,nfft)/Fs;   % fft of projected data
if ~gpuflag
    J=gather(J); % bring the results back to main memory
    if nnz(imag(J(:)))==0;J=real(J);end
end