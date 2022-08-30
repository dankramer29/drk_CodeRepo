function SingleNSP(cb,varargin)
loc = env.get('location');

cb.nspPaths = {['C:\Share\' datestr(now,'yyyymmdd') '\NSP1\']};
cb.nspString = {'NSP1'};
if strncmpi(loc,'rancho',6)
    cb.cbmexOpenArgs = {{'central-addr','192.168.137.3'}};
    cb.cbmexInterface = {2};
else
    cb.cbmexOpenArgs = {{}};
    cb.cbmexInterface = {0};
end

cb.nspCount = 1;
cb.outputCount = 1;
cb.nspIn2Out = [1];