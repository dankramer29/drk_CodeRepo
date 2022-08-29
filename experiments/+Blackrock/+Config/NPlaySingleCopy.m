function NPlaySingleCopy(cb)

cb.nspPaths = {['C:\Share\' datestr(now,'yyyymmdd') '\NSP1\'],['C:\Share\' datestr(now,'yyyymmdd') '\NSP2\']};
cb.nspString = {'NSP1','NSP2'};
cb.cbmexOpenArgs = {{},{}};

cb.nspCount = 1;
cb.outputCount = 2;
cb.nspIn2Out = [1 1];