classdef Analysis < handle & Parameters.Interface & cache.Cacheable & util.Structable
    
    properties
        config % the config function handle (if provided)
        outdir = '.'; % where to save results
        verbosity = 3; % verbosity level: 0->off, 1->error, 2->warning, 3->info, 4->hints, 5->debug
        parallel = true; % whether to run parfor loops or not
        
        % FIGURES
        fg_plot = false; % whether to generate figures
        fg_visible = true; % whether figures should be visible
        fg_save = false; % whether to save generated figures
        fg_overwrite = false; % whether to overwrite existing files
        fg_colororder = [ % default color order for figures
            0         0.4470    0.7410
            0.8500    0.3250    0.0980
            0.9290    0.6940    0.1250
            0.4940    0.1840    0.5560
            0.4660    0.6740    0.1880
            0.3010    0.7450    0.9330
            0.6350    0.0780    0.1840];
        fg_markerorder = {'.','o','v'}; % default order of markers for figures
        fg_backgroundcolor = [0.85 0.85 0.85]; % default color for background items
        fg_backgroundmarker = '.'; % default marker for background items
        fg_noisecolor = [0.3 0.3 0.3]; % default color for noise items
        fg_noisemarker = 'x'; % default marker for noise items
        
        % TIME
        tm_baseline % time window to use for baseline (relative to trial) (or name of phase) (empty for nothing)
        tm_analysis % time window to use for analysis (relative to trial) (or phase name or cell array of phase names) (empty for full trial)
        tm_bufferpre = 0.0; % amount of time to read before the start of the phase (for filtering etc.; specify w.r.t. beginning of analysis window)
        tm_discardpre = 0.0; % amount of time to discard at the beginning of the analysis window (prior to averaging, analysis etc.; specify w.r.t. beginning of analysis window)
        tm_bufferpost = 0.0; % amount of time to read after the end of the analysis window (for filtering etc.; specify w.r.t. beginning of analysis window)
        tm_discardpost = 0.0; % amount of time to discard at the end of the analysis window (prior to averaging, analysis etc.; specify w.r.t. beginning of analysis window)
        tm_min = 0.0; % minimum amount of data required to remain after removing buffer/discard from pre/post.
        tm_dt = 0.05; % sampling interval in the returned features
        
        % DATA
        dt_cache = false; % whether to use (save to and load from) the cache
        dt_mintrials = 45; % minimum number of total trials for analysis
        dt_mintrialspercat = 8; % minimum number of trials per category
        
        % SPIKE
        spk_type = 'any'; % 'any' (priority sorted > npmk > nev), 'npmk' (MAT files with NPMK structs), 'nev' (NEV file in root array directory), 'sorted' (NEV file in SortedObjects subdirectory)
        spk_unsorted = true; % include unsorted units (true) or exclude (false)
        spk_noise = true; % include noise/hash unit (true) or exclude (false)
        spk_ts % utility field to allow calculation of the minimum interval between spike timestamps (see e.g. proc.raster)
        spk_min = 0; % minimum average binned spike count
        spk_fs = 30e3; % utility field to allow specifying the spike sampling rate
        spk_norm = false; % normalize the bin counts
        spk_normsrc = 'baseline'; % 'baseline','same' source of data used to calculate normalizing parameters
        spk_normmethod = 'zscore'; % 'zscore','minmax','adaptive','baseline'
        spk_normparams = []; % parameters for normalization routine
        spk_timeavg = false; % whether to average bin counts over time (i.e. produce one average value for analysis window)
        spk_smooth = false; % whether to the smooth the bin counts
        spk_smoothmethod = 'moving'; % method to use for smoothing the bin counts 'mj',or any of the built-in method 'smooth' methods
        spk_smoothparams = []; % parameter to be passed to the smoothing method (all lower case fields of a struct)
        spk_bin2fr = false; % convert bin counts to firing rates
        
        % SPIKE FIRING RATES
        fr_min = 0; % minimum firing rate threshold
        fr_timeavg = false; % whether to average features over time (i.e. average value for analysis window)
        fr_forceresolution = false; % force values to have a minimum resolution (i.e., minimum smallest value)
        fr_featresolution = 1e-6; % minimum feature value resolution (i.e., minimum smallest value)
        
        % LOCAL FIELD POTENTIALS
        lfp_type = 'any'; % 'any' (priority ns3 > ns6), 'ns3' (ns3 file), 'ns6' (ns6 file)
        lfp_regress = false; % whether to regress common elements out of the LFPs
        lfp_rwindowed = false; % regress out common elements in overlapping windows
        lfp_rmode = 'concat'; % 'concat','rdata','fdata' -- combine or select regressed/fitted data
        lfp_rmovingwin = [0.25 0.15]; % size of moving window for windowed LFP regression
        lfp_rsamples = 1000; % how many samples to use when estimating the linear model
        lfp_freqbins = []; % use chronux defaults or specify Nx2 for N bins with [start stop] frequencies per bin
        lfp_db = true; % whether to convert power to decibels
        lfp_norm = false; % whether to normalize the spectrogram
        lfp_normmethod = 'zscore'; % 'zscore','minmax','adaptive' method to use for normalization
        lfp_normsrc = 'baseline'; % 'baseline','same' source of data used to calculate normalizing parameters
        lfp_normparams = []; % parameters for normalization routine
        lfp_timeavg = false; % whether to average features over time (i.e. average value for analysis window)
        lfp_smooth = false; % whether to the smooth the data
        lfp_smoothmethod = 'moving'; % method to use for smoothing the data 'mj',or any of the built-in method 'smooth' methods
        lfp_smoothparams = []; % parameter to be passed to the smoothing method (all lower case fields of a struct)
        lfp_bpfreqbands = []; % frequency bands to use when plotting band power
        lfp_bpmovingwin = []; % moving window (start,step) for band power
        
        % CHRONUX
        chr_movingwin = [0.50 0.025]; % chronux window size, step size (seconds)
        chr_fpass = [0 200]; % chronux frequency band
        chr_tapers = [3 5]; % chronux time-bandwidth product and number of tapers
        chr_trialave = false; % chronux whether to trial-average or not
        chr_pad = 0; % chronux zero-padding (-1 => none; 0+n => nextpow2+n
        
        % FEATURES
        ft_outliers = false; % identify outlier observations (trials) in each feature
        ft_outlierparams = struct('perfeat',true,'global',true,'perfeat_tile',[15 85],'perfeat_thresh',1.5,'global_tile',[1 99],'global_thresh',2);
        ft_prune = false; % evaluate features individually 
        ft_prunemethod = 'numfeats'; % whether to prune based on a criterion or desired number of features 'threshold','numfeats'
        ft_prunegoal = 25; % depends on the method: for 'threshold', defines threshold on misclassification rate for removing a feature; for 'numfeats', defines number of features; if vector, defines [numfeats minimumfeats] (in cases where not enough valid features to meet requested number of features -- will generate warning instead of error and use what's available)
        ft_modthresh = 0.9; % percentage of data that can be exact same value (no modulation) without killing the feature
        ft_reduce = false; % dimensionality reduction
        ft_reducemethod = 'pca';
        ft_reducezscore = false; % whether to z-score the features prior to reduction
        ft_crittol = 0.05; % allow values within minimum +/- this amount when minimizing criteria
        ft_maxfeatmethod = 'featreduce'; % what method to use for determining the number of features 'featreduce','nfeats','inf'
        ft_maxfeatthresh = 0.8; % threshold to use when determining number of features
        ft_maxfeats = inf; % maximum number of features possible
        ft_crossval = false; % enable cross validation
        ft_cvtype = 'kfold'; % cross-validation type 'kfold','holdout','leaveout','resubstition'
        ft_cvbias = 'mintest'; % modify other parameters to satisfy the requested bias parameter 'mintest','mintrain','kfold','none'
        ft_cvarg = 10; % k-fold cross validation
        ft_mintest = 5; % minimum number of trials for a test set in cross-validation
        ft_mintrain = 10; % minimum number of trials for a training set in cross-validation
        ft_mcreps = 50; % number of Monte-Carlo repetitions for validation (see help crossval)
        ft_searchreps = 50; % number of times to repeat the sequential feature search
        ft_fittype = 'fitcdiscr'; % fit type (name of a constructor that returns a fit object)
        ft_fitargs = {'DiscrimType','diagLinear','Prior','uniform','ScoreTransform','none'}; % arguments to the fit object constructor
        ft_scoringquants = {'mcr','added','dcrit','removed'}; % which quantities to use when scoring features 'mcr','added','removed','dcrit','added_avg','added_min','removed_avg','removed_max','dcrit_avg','dcrit_min'
        ft_numftquants = {'fwdfs','bwdfs','dcrit'}; % which quantities to use when determining the number of features to keep 'fwdfs','bwdfs','dcrit'
        
        % CLASSIFICATION
        cl_crossval = false; % enable cross validation
        cl_cvtype = 'kfold'; % cross-validation type 'kfold','holdout','leaveout','resubstition'
        cl_cvarg = 10; % argument corresponding to type (i.e., for 'kfold' this is 'k', the number of folds)
        cl_cvbias = 'mintest'; % modify other parameters to satisfy the requested bias parameter 'mintest','mintrain','kfold','none'
        cl_mintest = 5; % minimum number of trials for a test set in cross-validation
        cl_mintrain = 10; % minimum number of trials for a training set in cross-validation
        cl_mcreps = 20; % number of Monte-Carlo repetitions for validation (see help crossval)
        cl_fittype = 'fitcdiscr'; % fit type (name of a constructor that returns a fit object)
        cl_fitargs = {'DiscrimType','diagLinear','Prior','uniform','ScoreTransform','none'}; % arguments to the fit object constructor
    end % END properties
    
    properties(Access=protected)
        state
        topics
    end % END properties(Access=protected)
    
    methods
        function this = Analysis(varargin)
            this = this@Parameters.Interface(varargin);
            
            % get rid of config file used by superclass constructor
            cfg_idx = cellfun(@(x)isa(x,'function_handle'),varargin);
            varargin(cfg_idx) = [];
            
            % process remaining inputs locally
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
        end % END function Analysis
        
        function push(this,varargin)
            % PUSH push parameters onto the LIFO state buffer
            %
            %   PUSH(THIS,PROP1,PROP2,...,PROPN)
            %   Save the values of PROP1, PROP2, ... PROPN into the LIFO
            %   (last-in, first-out) state buffer.  If previous values were
            %   saved, the buffer size will increase to push these values
            %   to the front of the buffer.
            %
            % See also POP.
            
            % loop over state variables
            for kk=1:length(varargin)
                
                % make sure the requested variable is actually a property
                assert(isprop(this,varargin{kk}),'Could not find property ''%s'' to save',varargin{kk});
                if ~isfield(this.state,varargin{kk})
                    
                    % create a new field with the current value
                    this.state.(varargin{kk}) = {this.(varargin{kk})};
                else
                    
                    % append current value to the existing field
                    this.state.(varargin{kk}){end+1} = this.(varargin{kk});
                end
            end
        end % END function push
        
        function pop(this,varargin)
            % POP pop parameters from the LIFO state buffer
            %
            %   POP(THIS,PROP1,PROP2,...,PROPN)
            %   Restore the values of PROP1, PROP2, ... PROPN from LIFO
            %   (last-in, first-out) state buffer.  If additional values
            %   were buffered, they will move toward the front of the
            %   buffer.
            %
            % See also PUSH.
            
            % loop over state variables
            for kk=1:length(varargin)
                
                % make sure the requested variable is actually a property
                assert(isfield(this.state,varargin{kk})&&isprop(this,varargin{kk}),'Could not find property ''%s'' to restore',varargin{kk});
                
                % restore the value
                this.(varargin{kk}) = this.state.(varargin{kk}){end};
                
                % remove the value from the LIFO buffer
                this.state.(varargin{kk})(end) = [];
                
                % remove the field for this variable if empty
                if isempty(this.state.(varargin{kk}))
                    this.state = rmfield(this.state,varargin{kk});
                end
            end
        end % END function pop
        
        function load(this,topic,cfg,varargin)
            assert(util.existp(sprintf('Parameters.Topic.%s',topic),'class')==8,'''%s'' is not a valid topic',topic);
            if nargin<3||isempty(cfg),cfg=@(x)x;end
            
            % make sure it's not already added
            assert(~any(strcmpi(this.topics,topic)),'Topic ''%s'' already exists',topic);
            
            % add the dynamic property
            addprop(this,topic);
            this.(topic) = Parameters.Topic.Interface(topic,cfg,varargin{:});
            
            % update list of added topics
            this.topics = [this.topics {topic}];
        end % END function load
    end % END methods
end % END classdef Analysis