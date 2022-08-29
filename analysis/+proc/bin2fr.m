function fr = bin2fr(t,c)
% BIN2FR Convert binned spike counts into firing rates
%
%   FR = BIN2FR(T,C)
%   Convert the binned spike counts in C, with bin centers listed in T,
%   into firing rate FR. The units of FR (spikes/sec, spikes/sample, etc.)
%   depend on the units of T (seconds or samples) and C (spikes/bin).
%
%   See also PROC.BIN.

% calculate the bin size
binWidth = median(diff(t)); % size of each bin

% convert the spike counts into firing rate (units of this quantity depend
% on the units of bin size - if samples, will be firing rate "per sample";
% if seconds, will be firing rate "per second".
fr = c/binWidth;