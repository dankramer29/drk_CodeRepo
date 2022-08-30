function [pwr,t,freqband] = bandpower(v,freqband,movingwin,fs,causal)
% BANDPOWER Computer spectral power in frequency bands
%
%   [PWR,T] = BANDPOWER(V,FREQBAND,MOVINGWIN,FS)
%   Compute the spectral power in the raw data V (in FS samples/sec) in the
%   frequency bands FREQBAND, in possibly overlapping windows characterized
%   by MOVINGWIN. The frequency bands should be provided as cell array with
%   one cell per band, each cell a two-element vector. The moving window
%   should be specified as [WINSIZE STEPSIZE] in seconds.
%
%   [PWR,T] = BANDPOWER(V,FREQBAND,MOVINGWIN,FS,CAUSAL)
%   Indicate whether the bandpass and lowpass filters should be applied
%   causally (i.e., once in the forward direction) or noncausally (i.e.,
%   once forward and once backward).

if nargin<5||isempty(causal),causal=false;end
numSamples = size(v,1);
numChannels = size(v,2);
dtclass = class(v);
numFreqBands = length(freqband);
numSamplesWin = round(movingwin(1)*fs);
numSamplesStep = round(movingwin(2)*fs);

% select the filtering function
if causal
    filtfcn = @filter;
else
    filtfcn = @filtfilt;
end

% compute the bandpass filters
[bpfilt,lpfilt] = proc.helper.getBandpowerFilts(freqband,movingwin,fs);

% calculate time vector
N = size(v,1);
winstart = 1:numSamplesStep:(N-numSamplesWin+1);
winend = winstart+numSamplesWin;
t = winend/fs;
numWindows = length(t);

% pre-allocate several characterizing variables for convenience and
% performance in the parfor loop
pwr = arrayfun(@(x)nan(numWindows,numFreqBands,dtclass),1:numChannels,'UniformOutput',false);

% loop over non-cached channels
for kk=1:numChannels
    idxfinite = isfinite(v(:,kk));
    assert(max(unique(diff(find(idxfinite))))==1,'No support for non-finite values interspersed with data (must be clustered at beginning or end)');
    
    % loop over frequency bands
    for bb=1:numFreqBands
        if isa(bpfilt{bb},'digitalFilter')
            
            % apply the bandpass filter
            local_dt = nan(numSamples,1);
            local_dt(idxfinite) = filtfcn(lpfilt,filtfcn(bpfilt{bb},double(v(idxfinite,kk))).^2);
            pwr{kk}(:,bb) = cast(local_dt( winstart+round(numSamplesWin/2) ),dtclass);
        end
    end
end