function plottingSpecgrams(obj,varargin)
if ~check(obj,'fg')
    obj.load('Figure');
    obj.fg.overwrite = false;
end
if ~check(obj,'tm')
    obj.load('Time');
    obj.tm.discardpre = 0;
    obj.tm.discardpost = 0;
end
if ~check(obj,'chr')
    obj.load('Chronux');
    obj.chr.fpass = [0 100];
    obj.chr.tapers = [3 5];
    obj.chr.pad = 0;
    obj.chr.movingwin = [0.5 0.025];
    obj.chr.trialave = 0;
end
if ~check(obj,'lfp')
    obj.load('LocalFieldPotential');
    obj.lfp.type = 'ns3';
    obj.lfp.regress = false;
    obj.lfp.norm = false;
    obj.lfp.smooth = true;
    obj.lfp.smoothmethod = 'mj';
    obj.lfp.smoothparams = struct('kernelwidth',0.5,'period',0.05,'halfkernel',true,'causal',true);
end
if ~check(obj,'spc')
    obj.load('SpectralPower');
    obj.spc.pwr2db = true;
    obj.spc.norm = false;
    obj.spc.smooth = false;
end