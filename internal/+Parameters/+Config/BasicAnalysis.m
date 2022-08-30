function BasicAnalysis(obj,varargin)
hasGPU = env.get('hasgpu');
if isempty(hasGPU)
    hasGPU = parallel.gpu.GPUDevice.isAvailable;
    env.set('hasgpu',hasGPU);
end

% debug
if ~check(obj,'dbg')
    obj.load('Debug');
    obj.dbg.verbosity = 5;
end

% computation
if ~check(obj,'cp')
    obj.load('Computation');
    obj.cp.parallel = true;
    obj.cp.gpu = hasGPU;
end

% data
if ~check(obj,'dt')
    obj.load('Data');
    obj.dt.cacheread = true;
    obj.dt.cachewrite = true;
    obj.dt.mintrials = 10;
    obj.dt.mintrialspercat = 7;
    if obj.cp.gpu
        obj.dt.class = 'single';
    else
        obj.dt.class = 'double';
    end
end

% timing
if ~check(obj,'tm')
    obj.load('Time');
    obj.tm.bufferpre = 1;
    obj.tm.discardpre = 0;
    obj.tm.bufferpost = 1;
    obj.tm.discardpost = 0;
    obj.tm.baseline = '';
    obj.tm.analysis = '';
    obj.tm.sync = true;
end

% plotting
if ~check(obj,'fg')
    obj.load('Figure');
    obj.fg.outdir = env.get('results');
    obj.fg.plot = true;
    obj.fg.save = true;
    obj.fg.visible = false;
    obj.fg.overwrite = false;
end

% firing rates
if ~check(obj,'fr')
    obj.load('FiringRate');
    obj.fr.min = 1.5;
    obj.fr.forceresolution = true;
    obj.fr.featresolution = 1e-6;
    obj.fr.kernel = 'gauss';
end

% spikes
if ~check(obj,'spk')
    obj.load('Spike');
    obj.spk.binwidth = 50e-3;
    obj.spk.bin2fr = true;
    obj.spk.fs = 30e3;
    obj.spk.type = 'sorted';
    obj.spk.unsorted = false;
    obj.spk.noise = false;
    obj.spk.timestampunits = 'seconds';
    obj.spk.ratefilt = true;
    obj.spk.ratefiltmethod = 'max';
    obj.spk.ratefiltparams = struct(...
        'mean_threshold',obj.fr.min*obj.spk.binwidth,...
        'mean_bad_fcn',@le,...
        'median_threshold',1,...
        'median_bad_fcn',@le,...
        'max_threshold',1,...
        'max_bad_fcn',@le,...
        'min_threshold',obj.fr.min*obj.spk.binwidth,...
        'min_bad_fcn',@le);
    obj.spk.norm = false;
    obj.spk.normmethod = 'zscore';
    obj.spk.normparams = struct(...
        'percolumn',true,...
        'robust','denominator',...
        'robustmadopts',false,...
        'percentiles',[5 95],...
        'outliercheck',false,...
        'outlierpercol',true,...
        'outlierrep',nan,...
        'outliertiles',[15 85],...
        'outlierthresh',5,...
        'outliersides','both',...
        'denzeropolicy','allow',...
        'denzerorep',true,...
        'regularize','denominator',...
        'regmethod','scale',...
        'regstrength',1.25);
    obj.spk.smooth = true;
    obj.spk.smoothmethod = 'mj';
    obj.spk.smoothparams = struct(...
        'kernelwidth',1.00,...
        'period',obj.spk.binwidth,...
        'halfkernel',true,...
        'causal',true);
end

% features
if ~check(obj,'ft')
    obj.load('Feature');
    obj.ft.cvtype = 'kfold';
    obj.ft.cvarg = 5;
    obj.ft.mcreps = 3;
    obj.ft.mintest = 3;
    obj.ft.fittype = 'fitcdiscr';
    obj.ft.fitargs = {'DiscrimType','diagLinear','Prior','uniform','ScoreTransform','none'};
    % obj.ft.cvfold = 10;
end

% classification
if ~check(obj,'cl')
    obj.load('Classification');
    obj.cl.crossval = true;
    obj.cl.cvtype = 'kfold';
    obj.cl.cvarg = 5;
    obj.cl.mcreps = 20;
    obj.cl.fittype = 'fitcdiscr';
    obj.cl.fitargs = {'DiscrimType','diagLinear','Prior','uniform','ScoreTransform','none'};
end

% chronux
if ~check(obj,'chr')
    obj.load('Chronux');
    obj.chr.fpass = [0 200];
    obj.chr.tapers = [5 9];
    obj.chr.pad = 0;
    obj.chr.trialave = 0;
    obj.chr.err = 0;
end

% local fields
if ~check(obj,'lfp')
    obj.load('LocalFieldPotential');
    obj.lfp.fs = 2000;
    obj.lfp.type = 'blc';
    obj.lfp.regress = false;
    obj.lfp.downsample = true;
    obj.lfp.newfs = 2e3;
    obj.lfp.norm = false;
    obj.lfp.normsrc = 'same';
    obj.lfp.normmethod = 'zscore';
    obj.lfp.normparams = struct(...
        'percolumn',true,...
        'robust','denominator',...
        'robustmadopts',false,...
        'percentiles',[5 95],...
        'outliercheck',false,...
        'outlierpercol',true,...
        'outlierrep',nan,...
        'outliertiles',[15 85],...
        'outlierthresh',5,...
        'outliersides','both',...
        'denzeropolicy','allow',...
        'denzerorep',true,...
        'regularize','denominator',...
        'regmethod','scale',...
        'regstrength',1.25);
    obj.lfp.smooth = false;
    obj.lfp.smoothmethod = 'mj';
    obj.lfp.smoothparams = struct(...
        'kernelwidth',1.00,...
        'period',0.05,...
        'halfkernel',true,...
        'causal',true);
    obj.lfp.units = 'microvolts';
end

% spectral power
if ~check(obj,'spc')
    obj.load('SpectralPower');
    obj.spc.movingwin = [0.5 0.25];
    obj.spc.pwr2db = true;
    obj.spc.norm = false;
    obj.spc.normsrc = 'same';
    obj.spc.normmethod = 'zscore';
    obj.spc.normparams = struct(...
        'percolumn',true,...
        'robust','denominator',...
        'robustmadopts',false,...
        'percentiles',[5 95],...
        'outliercheck',false,...
        'outlierpercol',true,...
        'outlierrep',nan,...
        'outliertiles',[15 85],...
        'outlierthresh',5,...
        'outliersides','both',...
        'denzeropolicy','allow',...
        'denzerorep',true,...
        'regularize','denominator',...
        'regmethod','scale',...
        'regstrength',1.25);
    obj.spc.smooth = true;
    obj.spc.smoothmethod = 'mj';
    obj.spc.smoothparams = struct(...
        'kernelwidth',1.00,...
        'period',nan,...
        'halfkernel',true,...
        'causal',true);
    obj.spc.freqbands = {[5 10],[10 30],[30 80],[80 200]};
end

% statistics
if ~check(obj,'st')
    obj.load('Statistics');
end