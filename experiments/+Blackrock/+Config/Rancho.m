function Rancho(cb,varargin)

% all arguments for maximum of two NSPs
fullCBMEXOpenArgs = {{'central-addr','192.168.137.3'},{'central-addr','192.168.137.19'}};
fullCBMEXInterface = [2 2];

% subselect based on number of array strings
for kk=1:length(cb.arrays)
    cb.cbmexOpenArgs{kk} = fullCBMEXOpenArgs{kk};
    cb.cbmexInterface(kk) = fullCBMEXInterface(kk);
end