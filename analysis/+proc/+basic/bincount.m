function [c,t] = bincount(timestamps,channels,units,binwidth,featdef)
% BINCOUNT Count spike timestamps in evenly-spaced time bins
%
%  [C,T] = BINCOUNT(TIMESTAMPS,CHANNELS,UNITS,BINWIDTH,FEATDEF)
%  Given data in TIMESTASMP, CHANNELS, and UNITS inputs, count the number
%  of spikes in time bins of width BINWIDTH. Process the channel/unit
%  combinations identified in the table FEATDEF (must have columns labeled
%  'dataset_channel' and 'unit'). BINWIDTH and TIMESTAMPS must have the
%  same units, e.g., both in samples or both in seconds. Return the counts
%  in C and the times of the training bin edges in T.

% calculate bin edges and the time vector
st = min(timestamps);
lt = max(timestamps);
binedges = max(-binwidth/2,(st-binwidth/2)):binwidth:(lt+binwidth/2);
binedges = round(binedges(:)*1e6)/1e6; % round to nearest 6th decimal place
t = binedges(2:end) - binedges(1); % mirror online case where timestammp T corresponds to spikes seen between (T-BINWIDTH) and T

% round t; first, identify precision
dt = double(median(diff(binedges)));
pwr = false(1,10);
sm = dt;
for kk=1:10 % account for max of 10 decimal places
    if floor(sm*10^kk)>1
        pwr(kk) = true;
        sm = sm - round(sm*10^kk)/10^kk;
    end
end
sigpwrs = [find(pwr(:)') 1];
[~,idx] = max(diff(sigpwrs));
pwr = max(2,sigpwrs(idx)+1);
pwr = min(6,pwr);
cl = class(t);
t = cast(round(double(t)*10^pwr)/10^pwr,cl);

% loop over features
num_bins = length(binedges)-1;
num_features = size(featdef,1);
c = zeros(num_bins,num_features,class(timestamps));
for ff=1:num_features
    ch = featdef.dataset_channel(ff);
    un = featdef.unit(ff);
    
    % handle case where no spikes
    if nnz(channels==ch)==0
        continue;
    end
    
    % use histc to bin the timestamps for this ch/unit combo
    % * note that the last bin counts the number of occurences of a spike
    % at the very last specified edge, not in between two edges (see
    % help histc).
    % * changed to histcounts: last bin includes both values in the bin
    % and at the bin edge (one fewer element than returned by histc)
    % see http://www.mathworks.com/help/matlab/creating_plots/replace-discouraged-instances-of-hist-and-histc.html
    tmpc = histcounts(timestamps(channels==ch&units==un),binedges); % spikes/bin
    
    % place into the output
    c(:,ff) = cast(tmpc(:),class(timestamps));
end