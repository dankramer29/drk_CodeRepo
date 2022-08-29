classdef ContinuousFeatureList < handle & Framework.FeatureList.Interface & util.Structable & util.StructableHierarchy
    % groupDefinitions -
    % {[startFrequency stopFrequency],'perchan'|'pernsp'|'allnsp',...}
    % for each row in groupDefinitions,
    % 'perchan' - one feature per channel
    % 'pernsp' - average channels from each nsp - nspCount features
    % 'allnsp' - average channels from all nsps - 1 feature
    % featureList contains the final list of features
    
    properties
        groupDefinitions = {[12 30],'perchan';[30 80],'pernsp';[80 200],'allnsp'};
        N = 512; % in samples
        fs = 2e3; % incoming sampling rate, samples/sec
        nspCount = 2;
        snrFiles = {'',''};
    end
    
    properties(SetAccess='private',GetAccess='public')
        featureLabels = {'feature','nsp','channel','freqband','type'};
        featureList
        featureCount = 0;
        buffer % buffer data for windows > processing step size
        
        avgIdx
        bufferIdx % mapping nsp number to index of "buffers" output
        chanIdx % linear index of incoming desired channels
        fsIdx % linear index of incoming desired channels' sampling rates
        nspChanOffset % for use when nsp data concatenated (offset of channel C for NSP N)
        
        dataTypes = {'CONTINUOUS'};
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        
        function this = ContinuousFeatureList(parent,varargin)
            this = this@Framework.FeatureList.Interface(parent);
            
            % parse user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % get channels to use for each NSP
            chan = cell(1,this.nspCount);
            for kk=1:this.nspCount
                % get a list of channels from this NSP
                if ~isempty(this.snrFiles{kk})
                    tmpchan = Blackrock.SNRFile2FeatureList(this.snrFiles{kk});
                    chan{kk} = tmpchan(:,1);
                else
                    chan{kk} = (1:96)';
                end
            end
            
            % numbers of channels used from the previous NSPs
            numChansPerNSP = cellfun(@length,chan)';
            this.nspChanOffset = cumsum([0; numChansPerNSP(1:end-1)]);
            
            % apply groupDefinitions to construct featureList
            this.featureCount = 0;
            this.featureList = cell(0,length(this.featureLabels));
            for ff=1:size(this.groupDefinitions,1)
                switch lower(this.groupDefinitions{ff,2})
                    case 'perchan'
                        for kk=1:this.nspCount
                            idx = (this.featureCount+1) : (this.featureCount + length(chan{kk}));
                            for ii=idx(:)'
                                if kk==1, cidx = ii;
                                else cidx = ii - this.nspChanOffset(kk);
                                end
                                this.featureList( ii, : ) = {ii,kk,chan{kk}(cidx),this.groupDefinitions{ff,1},this.groupDefinitions{ff,2}};
                            end
                            this.featureCount = size(this.featureList,1);
                        end
                    case 'pernsp'
                        for kk=1:this.nspCount
                            idx = this.featureCount+1;
                            this.featureList( idx, : ) = {idx,kk,chan{kk},this.groupDefinitions{ff,1},this.groupDefinitions{ff,2}};
                            this.featureCount = size(this.featureList,1);
                        end
                    case 'allnsp'
                        idx = this.featureCount+1;
                        chanList = cat(1,chan{:});
                        nspList = cell(size(chan));
                        for kk=1:this.nspCount, nspList{kk}=repmat(kk,size(chan{kk})); end
                        nspList = cat(1,nspList{:});
                        this.featureList( idx, : ) = {idx,nspList,chanList,this.groupDefinitions{ff,1},this.groupDefinitions{ff,2}};
                        this.featureCount = size(this.featureList,1);
                    otherwise
                        error('unknown groupDefinition parameter %s',this.groupDefinitions{ff,2});
                end
            end
            
            % initialize feature indexing
            this.chanIdx = cell(this.nspCount,1);
            
        end % END function ContinuousFeatureList
        
        function z = processFeatures(this,raw,winSize)
            z = zeros(size(this.featureList,1),1);
            
            initializeFlag = false;
            if isempty(this.chanIdx{1}), initializeFlag = true; end
            
            % pull data out of master cell array
            raw = raw{1};
            winSize = winSize{1};
            
            % require 1xN cell arrays for N NSPs
            % each cell should be 96xM for 96 channels and M samples
            if ~iscell(raw)
                error('Blackrock:ContinuousFeatureList:Error','Must provide 1x%d cell array (nspCount=%d)',this.nspCount,this.nspCount);
            end
            nchans = cellfun(@(x)size(x,1),raw);
            if ~all(nchans==96)
                error('Blackrock:ContinuousFeatureList:Error','Must provide 96-row matrix in each cell of incoming data');
            end
            
            % indices into cell array to pull out only channels we want
            % **** THIS CODE ASSUMES NO CHANNELS DISABLED IN CBMEX OUTPUT ****
            if initializeFlag
                
                % register data buffer for concatenated data from all NSPs
                % circular buffers to hold winSize*fs samples of data
                winSizeSamples = ceil(this.fs*winSize);
                this.buffer = Buffer.Circular(winSizeSamples,'r');
                
                % get list of unique channels used for each NSP
                chanList = cell(1,length(this.chanIdx));
                for ff=1:size(this.featureList,1)
                    switch this.featureList{ff,end}
                        case 'perchan'
                            chanList{this.featureList{ff,2}} = cat(2,chanList{this.featureList{ff,2}},this.featureList{ff,3});
                        case 'pernsp'
                            chanList{this.featureList{ff,2}} = cat(2,chanList{this.featureList{ff,2}},this.featureList{ff,3}(:)');
                        case 'allnsp'
                            for nn=1:this.nspCount
                                tmpList = this.featureList{ff,3}(this.featureList{ff,2}==nn);
                                chanList{nn} = cat(2,chanList{nn},tmpList(:)');
                            end
                    end
                end
                chanList = cellfun(@unique,chanList,'UniformOutput',false);
                
                % find linear indices to the unique set of channels
                for kk=1:this.nspCount
                    this.chanIdx{kk} = sub2ind(size(raw{kk}),chanList{kk},repmat(3,size(chanList{kk})));
                    this.fsIdx{kk} = sub2ind(size(raw{kk}),chanList{kk},repmat(2,size(chanList{kk})));
                end
            end
            
            % check sampling rates
            for kk=1:this.nspCount
                inputfs = raw{kk}(this.fsIdx{kk});
                inputfs = unique(cat(1,inputfs{:}));
                if numel(inputfs)>1
                    warning('Blackrock:ContinuousFeatureList:Warning','In NSP %d, multiple sampling rates %s(expected only %d)',kk,sprintf('%d ',inputfs),this.fs);
                end
            end
            
            % channel reduction
            newContinuousData = cellfun(@(x,y)x(y),raw(:),this.chanIdx(:),'UniformOutput',false);
            
            % enforce uniform amount of data for all channels
            M = zeros(size(raw));
            for kk=1:this.nspCount
                M(kk) = min(cellfun(@(x)length(x),newContinuousData{kk})); % find lengths of each desired channel
            end
            M = min(M); % smallest length among all channels, all NSPs
            for kk=1:this.nspCount
                newContinuousData{kk} = cellfun(@(x)x(end-M+1:end),newContinuousData{kk},'UniformOutput',false); % all channels same length
                newContinuousData{kk} = double(cell2mat(newContinuousData{kk})); % convert to matrix of doubles
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
            w=(0:this.fs/this.N:this.fs/2)';
            
            % create avgIdx
            if initializeFlag
                this.avgIdx = repmat(struct('freq',false(size(S,1),1),'chan',false(1,size(S,2))),[size(this.featureList,1) 1]);
                for id=1:size(this.featureList,1)
                    nsp = this.featureList{id,2};
                    chan = this.featureList{id,3};
                    freq = this.featureList{id,4};
                    
                    for ff=1:size(freq,1)
                        this.avgIdx(id).freq = this.avgIdx(id).freq | w>=freq(ff,1)&w<=freq(ff,2);
                    end
                    
                    idx = this.nspChanOffset(nsp) + chan;
                    this.avgIdx(id).chan(idx) = true;
                end
            end
            
            % assign features
            for id=1:size(this.featureList,1)
                vals = S( this.avgIdx(id).freq, this.avgIdx(id).chan );
                z(id) = mean( vals(:) );
            end
            
        end % END function processFeatures
        
        function list = getFeatureList(this)
            list = this.featureList;
        end % END function getFeatureList
        
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
end % END classdef ContinuousFeatureList