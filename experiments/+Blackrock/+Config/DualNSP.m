function DualNSP(cb)
loc = env.get('location');

cb.nspPaths = {['C:\Share\' datestr(now,'yyyymmdd') '\NSP1\'],['C:\Share\' datestr(now,'yyyymmdd') '\NSP2\']};
cb.nspString = {'NSP1','NSP2'};
if strncmpi(loc,'rancho',6)
    cb.cbmexOpenArgs = {{'central-addr','192.168.137.3'},{'central-addr','192.168.137.19'}};
    cb.cbmexInterface = {2,2};
else
    cb.cbmexOpenArgs = {{},{}};
    cb.cbmexInterface = {0,0};
end

cb.nspCount = 2;
cb.outputCount = 2;
cb.nspIn2Out = [1 2];