function fs = getFsFromRelt(relt)
pd = cellfun(@(x)mode(unique(diff(x))),relt);
pd = unique(round(1e4*pd)/1e4); % round to 4 decimal places
assert(isscalar(pd),'Could not identify a single unique period from the time vector');
fs = 1/pd;
fs = unique(round(1e2*fs)/1e2); % round to 2 decimal places