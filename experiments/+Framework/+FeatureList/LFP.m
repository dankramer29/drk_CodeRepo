classdef LFP < handle & Framework.FeatureList.Interface & util.Structable & util.StructableHierarchy
    % groupDefinitions -
    % {[startFrequency stopFrequency],'perchan'|'pernsp'|'allnsp',...}
    % for each row in groupDefinitions,
    % 'perchan' - one feature per channel
    % 'pernsp' - average channels from each nsp - nspCount features
    % 'allnsp' - average channels from all nsps - 1 feature
    % featureList contains the final list of features
    
    properties
        N % FFT size in samples
        fs % incoming sampling rate, samples/sec
    end % END properties
    
    properties(SetAccess='private',GetAccess='public')
        featureDefinitions
        featureCount = 0;
        buffer % buffer data for windows > processing step size
        
        avgIdx
        bufferIdx % mapping nsp number to index of "buffers" output
        chanIdx % linear index of incoming desired channels
        fsIdx % linear index of incoming desired channels' sampling rates
        nspChanOffset % for use when nsp data concatenated (offset of channel C for NSP N)
        
        dataTypes = {'CONTINUOUS'};
        isInitialized = false;
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        
        function this = LFP(parent,varargin)
            % LFP Create feature list for LFP frequency band power
            %
            %  INPUTS
            %  'N',N
            %  Specify number of points in FFT (default 1024)
            %
            %  'featdef',FEATDEF
            %  provide feature definitions table with variable names
            %  'nsp' (integer; start at 1 for first NSP and count up),
            %  'channel' (integer; corresponds to channel number in CBMEX),
            %  and 'frequencyBand' (cell array with matrix; columns
            %  indicate start/stop frequencies, rows indicate ranges to
            %  include in the average). if provided, none of the below
            %  inputs are relevant.
            %
            %  'frequencyBands',FREQBANDS
            %  cell array, with one cell per NSP, where each cell lists the
            %  range(s) of frequencies to be averaged for that feature,
            %  i.e., the cell can be one or more rows where each row
            %  contains start/stop frequency for that range. by default,
            %  {[12 30],[30 55; 65 80],[80 200]}
            %
            %  'snrfiles',SNRFILES
            %  provide cell array of char specifying full path to SNR text
            %  files, one per NSP. if provided, none of the below inputs
            %  are relevant.
            %
            %  'channels',CHANNELS
            %  Specify list of channels to use, with one cell per NSP and
            %  channels specified relative to the NSP (i.e. second NSP
            %  channels start at 1). default is all channels listed in the
            %  GridMap object (property of hNeuralSource)
            this = this@Framework.FeatureList.Interface(parent);
            numNSPs = length(this.hNeuralSource.hGridMap);
            
            % parse simple inputs
            [varargin,this.N] = util.argkeyval('N',varargin,1024);
            
            % create feature definitions
            [varargin,featdef,~,found_featdef] = util.argkeyval('featdef',varargin,[]);
            if found_featdef
                
                % validate user input
                assert(istable(featdef),'Must provide feature definitions as a table, not "%s"',class(featdef));
                assert(all(ismember({'nsp','channel','frequencyBand'},featdef.Properties.VariableNames)),'Feature definitions table must have variable names "nsp", "channel", and "frequencyBand" (one or more not found in list: %s)',strjoin(featdef.Properties.VariableNames));
                this.featureDefinitions = featdef;
            else
                
                % get list of frequency bands
                [varargin,frequencyBands] = util.argkeyval('frequencyBands',varargin,{[12 30],[30 55; 65 80],[80 200]});
                
                % set channels
                [varargin,snrfiles,~,found_snrfiles] = util.argkeyval('snrfiles',varargin,{});
                channels = cell(1,numNSPs);
                if found_snrfiles
                    
                    % load channels from SNR file(s)
                    if ~iscell(snrfiles),snrfiles={snrfiles};end
                    assert(length(snrfiles)==numNSPs,'Must provide one SNR file per NSP (found %d but expected %d)',length(snrfiles),numNSPs);
                    for kk=1:numNSPs
                        tmpchan = Blackrock.SNRFile2FeatureList(snrfiles{kk});
                        channels{kk} = tmpchan(:,1);
                    end
                else
                    
                    % check for user-specified channels
                    [varargin,channels,~,found_channels] = util.argkeyval('channels',varargin,[]);
                    if ~found_channels
                        
                        % generate list of channels from the grid map
                        channels = cellfun(@(x)x.ChannelInfo.Channel,this.hNeuralSource.hGridMap,'UniformOutput',false);
                    end
                end
                numChansPerNSP = cellfun(@length,channels)';
                
                % construct featureList
                numFreq = length(frequencyBands);
                feats = cell(sum(numChansPerNSP)*numFreq,3);
                idx = 0;
                for kk=1:numNSPs
                    nsp = repmat(arrayfun(@(x)x,repmat(kk,numChansPerNSP(kk),1),'UniformOutput',false),numFreq,1);
                    channel = repmat(arrayfun(@(x)x,channels{kk},'UniformOutput',false),numFreq,1);
                    frequencyBand = cellfun(@(x)repmat({x},numChansPerNSP(kk),1),frequencyBands(:),'UniformOutput',false);
                    frequencyBand = cat(1,frequencyBand{:});
                    frequencyBand = arrayfun(@(x)frequencyBand(x,:),(1:size(frequencyBand,1))','UniformOutput',false);
                    feats(idx+(1:numFreq*numChansPerNSP(kk)),:) = [nsp(:) channel(:) frequencyBand(:)];
                    idx = idx + numFreq*numChansPerNSP(kk);
                end
                this.featureDefinitions = cell2table(feats,'VariableNames',{'nsp','channel','frequencyBand'});
            end
            this.featureCount = size(this.featureDefinitions,1);
            
            % make sure no leftover input arguments
            util.argempty(varargin);
        end % END function LFP
        
        function initialize(this,raw,winSize)
            numNSPs = length(this.hNeuralSource.hGridMap);
            
            % pull data out of master cell array
            raw = raw{1};
            winSize = winSize{1};
            
            % require 1xN cell arrays for N NSPs
            % each cell should be 96xM for 96 channels and M samples
            assert(iscell(raw),'Expected cell array from CBMEX but found "%s"',class(raw));
            assert(numel(size(raw))==2&&any(size(raw)==1)&&any(size(raw)==numNSPs),'Expected 1x%d cell array from CBMEX, but found %s',numNSPs,util.vec2str(size(raw)));
            nchans_found = cellfun(@(x)size(x,1),raw);
            nchans_expected = cellfun(@(x)x.NumChannels,this.hNeuralSource.hGridMap);
            % assert(all(nchans_found>=nchans_expected),'Expected at least %d channels in the raw data but found only %d',nchans_expected,nchans_found);
            
            % find linear indices to the unique set of channels
            cbmexChannels = cellfun(@(x)[x{:,1}],raw,'UniformOutput',false);
            featdefChannels = arrayfun(@(x)unique(this.featureDefinitions.channel(this.featureDefinitions.nsp==x)),1:numNSPs,'UniformOutput',false);
            this.chanIdx = cell(numNSPs,1);
            for kk=1:numNSPs
                
                % match up channel number with the CBMEX channel
                row = nan(length(featdefChannels{kk}),1);
                for cc=1:length(featdefChannels{kk})
                    try
                        row(cc) = find(cbmexChannels{kk}==featdefChannels{kk}(cc));
                    catch ME
                        util.errorMessage(ME);
                        keyboard
                    end
                    assert(~isempty(row(cc)),'Could not find channel %d in list of CBMEX channels %s',featdefChannels{kk}(cc),util.vec2str(cbmexChannels{kk}));
                    assert(numel(row(cc))==1,'Found multiple instances of channel %d in list of CBMEX channels %s',featdefChannels{kk}(cc),util.vec2str(cbmexChannels{kk}));
                end
                
                % compute linear indices into the CBMEX cell output for
                % the channel data and the channel sampling frequency
                numRows = length(cbmexChannels{kk});
                this.chanIdx{kk} = row + 2*numRows;
                this.fsIdx{kk} = row + 1*numRows;
            end
            
            % pull out sampling frequency
            local_fs = nan(1,numNSPs);
            for kk=1:numNSPs
                inputfs = raw{kk}(this.fsIdx{kk});
                inputfs = unique(cat(1,inputfs{:}));
                assert(numel(inputfs)==1,'No support for multiple sampling rates (found %s)',util.vec2str(inputfs));
                local_fs(kk) = inputfs;
            end
            assert(numel(unique(local_fs))==1,'No support for multiple sampling rates (found %s)',util.vec2str(inputfs));
            this.fs = unique(local_fs);
            
            % register data buffer for concatenated data from all NSPs
            % circular buffers to hold winSize*fs samples of data
            winSizeSamples = ceil(this.fs*winSize);
            this.buffer = Buffer.Circular(winSizeSamples,'r');
            
            % set up FFT frequencies
            w = (0:this.fs/this.N:this.fs/2)';
            
            % set up indices for averaging frequency bins
            this.avgIdx = cell(this.featureCount,1);
            for id=1:this.featureCount
                nsp = this.featureDefinitions.nsp(id);
                idx_chan = find(featdefChannels{nsp}==this.featureDefinitions.channel(id));
                assert(~isempty(idx_chan),'Could not find channel %d in list of CBMEX channels %s',this.featureDefinitions.channel(id),util.vec2str(cbmexChannels{kk}));
                
                % compute index into FFT output matrix for this feature
                freq = this.featureDefinitions.frequencyBand{id};
                idx_freq = false(length(w),1);
                for ff=1:size(freq,1)
                    idx_freq = idx_freq | w>=freq(ff,1)&w<=freq(ff,2);
                end
                
                % compute linear indices into the FFT output matrix
                this.avgIdx{id} = sub2ind([length(w) sum(cellfun(@length,featdefChannels))],find(idx_freq),repmat(idx_chan,nnz(idx_freq),1));
            end
            
            % update initialized flag
            this.isInitialized = true;
        end % END function initialize
        
        function z = processFeatures(this,raw,~)
            assert(this.isInitialized,'Feature list not initialized');
            numNSPs = length(this.hNeuralSource.hGridMap);
            
            % pull data out of master cell array
            raw = raw{1};
            
            % require 1xN cell arrays for N NSPs
            % each cell should be 96xM for 96 channels and M samples
            assert(iscell(raw),'Expected cell array from CBMEX but found "%s"',class(raw));
            assert(numel(size(raw))==2&&any(size(raw)==1)&&any(size(raw)==numNSPs),'Expected 1x%d cell array from CBMEX, but found %s',numNSPs,util.vec2str(size(raw)));
            nchans_found = cellfun(@(x)size(x,1),raw);
            nchans_expected = cellfun(@(x)x.NumChannels,this.hNeuralSource.hGridMap);
            assert(all(nchans_found>=nchans_expected),'Expected at least %d channels in the raw data but found only %d',nchans_expected,nchans_found);
            
            % check sampling rates
            for kk=1:numNSPs
                inputfs = raw{kk}(this.fsIdx{kk});
                inputfs = unique(cat(1,inputfs{:}));
                assert(numel(inputfs)==1,'No support for multiple sampling rates (found %s)',util.vec2str(inputfs));
            end
            
            % channel reduction
            newContinuousData = cellfun(@(x,y)x(y),raw(:),this.chanIdx(:),'UniformOutput',false);
            
            % enforce uniform amount of data for all channels
            M = zeros(size(raw));
            for kk=1:numNSPs
                M(kk) = min(cellfun(@(x)length(x),newContinuousData{kk})); % find lengths of each desired channel
            end
            M = min(M); % smallest length among all channels, all NSPs
            for kk=1:numNSPs
                newContinuousData{kk} = cellfun(@(x)x(end-M+1:end),newContinuousData{kk},'UniformOutput',false); % all channels same length
                newContinuousData{kk} = double(cat(2,newContinuousData{kk}{:})); % convert to matrix of doubles
            end
            newContinuousData = cat(2,newContinuousData{:}); % concatenate data from all NSPs
            add(this.buffer,newContinuousData); % add new data to buffer
            
            % get buffered data
            bufferData = get(this.buffer); % retrieve data from buffer
            
            % if N < num_samples, reduce data to most recent N samples
            st = max(1,size(bufferData,1)-this.N+1);
            lt = size(bufferData,1);
            bufferData = bufferData(st:lt,:);
            
            % create window kernel
            num_samples = size(bufferData,1);
            wt = repmat(hann(num_samples),[1 size(bufferData,2)]);
            
            % windowed FFT
            % see link below for indexing/scaling explanation
            % http://www.mathworks.com/help/signal/ug/psd-estimate-using-fft.html)
            S = fft(bufferData.*wt,this.N);
            S = S(1:this.N/2+1,:);
            S = (1/(this.fs*this.N)).*abs(S).^2;
            S(2:end-1,:) = 2*S(2:end-1,:);
            
            % assign features
            z = cellfun(@(x)mean(S(x)),this.avgIdx);
        end % END function processFeatures
        
        function def = getFeatureDefinition(this)
            def = this.featureDefinitions;
        end % END function getFeatureDefinition
        
        function close(~)
        end % END function close
        
        function list = structableSkipFields(this)
            list1 = structableSkipFields@Framework.FeatureList.Interface(this);
            list = [list1 {'buffer'}];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@Framework.FeatureList.Interface(this);
            st2 = [];
            st = util.catstruct(st1,st2);
        end % END function structableManualFields
    end % END methods
end % END classdef LFP