function [f,t,Nwin,Nstep,findx] = chronux_dim(params,N,movingwin,dtclass)
% CHRONUX_DIM Dimension variables for chronux spectrum or spectrogram
%
%   F = CHRONUX_DIM(PARAMS,N)
%   F = CHRONUX_DIM(PARAMS,N,[],...)
%   Calculate the frequency dimension variable given the chronux parameters
%   PARAMS and the number of data samples N.
%
%   [F,T,NWIN,NSTEP] = CHRONUX_DIM(PARAMS,N,MOVINGWIN)
%   Calculate the frequency and time dimension variables given the chronux
%   parameters PARAMS, number of data samples N, and the window/step size
%   in MOVINGWIN. Also returns the number of samples per window NWIN, and
%   the number of samples stepped NSTEP. Provide empty MOVINGWIN to avoid
%   triggering the "spectrogram" mode while still providing additional
%   arguments.
%
%   [...] = CHRONUX_DIM(PARAMS,N,MOVINGWIN,DTCLASS)
%   Specify the data type to return, e.g., 'single', or 'double'.

% process params
[~,pad,Fs,fpass,~,~,~]=chronux.hlp.getparams(params);

% identify whether spectrum or specgram
flagSpectrum=true;
flagSpecgram=false;
if nargin>=3&&~isempty(movingwin)
    flagSpectrum=false;
    flagSpecgram=true;
end

% calculate frequency
if flagSpectrum
    Nwin=[];
    nfft=max(2^(nextpow2(N)+pad),N);
elseif flagSpecgram
    Nwin=round(Fs*movingwin(1)); % number of samples in window
    nfft=max(2^(nextpow2(Nwin)+pad),Nwin);
end
[f,findx]=chronux.hlp.getfgrid(Fs,nfft,fpass);

% calculate time
if flagSpectrum
    t=[];
    Nstep=[];
elseif flagSpecgram
    Nstep=round(movingwin(2)*Fs); % number of samples to step through
    winstart=(1:Nstep:N-Nwin+1)';
    winmid=winstart+round(Nwin/2);
    t=winmid/Fs;
end

% apply data class
if ~strcmpi(class(t),dtclass)
    t = cast(t,dtclass);
end
if ~strcmpi(class(f),dtclass)
    f = cast(f,dtclass);
end
if flagSpecgram && ~strcmpi(class(Nwin),dtclass)
    Nwin = cast(Nwin,dtclass);
end
if flagSpecgram && ~strcmpi(class(Nstep),dtclass)
    Nstep = cast(Nstep,dtclass);
end