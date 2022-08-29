classdef LocalAvgLFPFeatureList < handle & Framework.FeatureList.Interface & util.Structable
    % groupDefinitions -
    % {[startFrequency stopFrequency],'perchan'|'pernsp'|'allnsp',...}
    % for each row in groupDefinitions,
    % 'perchan' - one feature per channel
    % 'pernsp' - average channels from each nsp - nspCount features
    % 'allnsp' - average channels from all nsps - 1 feature
    % featureList contains the final list of features
    
    properties
        
        snrFiles = {'',''};
        
        groupDefinitions = [... % see matlab help fspecial for types and parameters
            struct('FrequencyBand',[12 30],'KernelType','gaussian','KernelParameters',{{9,1.3}},'SubsamplingFactor',5),...
            struct('FrequencyBand',[30 80],'KernelType','gaussian','KernelParameters',{{7,0.9}},'SubsamplingFactor',4),...
            struct('FrequencyBand',[80 200],'KernelType','gaussian','KernelParameters',{{5,0.5}},'SubsamplingFactor',3)];
        
        N = 1024; % in samples
        fs = 2e3; % incoming sampling rate, samples/sec
        nspCount = 2;
        
        vec2layout % for converting vectors into 10x10 layout
        cornerIdx
        cornerAvgIdx
        
        enablePlot = false;
    end
    
    properties(SetAccess='private',GetAccess='public')
        kernelCollection
        
        featureLabels = {'feature','nsp','group','row','column','freqband','subsampleradius'};
        featureCount = 0;
        featureList
        featureListIdx
        buffer % buffer data for windows > processing step size
        
        nspChanOffset
        chanIdx
        fsIdx
        groupFreqIdx
        fftWin
        
        figureHandles
        
        dataTypes = {'CONTINUOUS'};
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        function this = LocalAvgLFPFeatureList(parent,varargin)
            this = this@Framework.FeatureList.Interface(parent);
            
            % parse user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % get channels to use for each NSP
            chan = cell(1,this.nspCount);
            for nn=1:this.nspCount
                if ~isempty(this.snrFiles{nn})
                    tmpchan = Blackrock.SNRFile2FeatureList(this.snrFiles{nn});
                    chan{nn} = tmpchan(:,1);
                else
                    chan{nn} = (1:96)';
                end
            end
            
            % numbers of channels used from the previous NSPs
            numChansPerNSP = cellfun(@length,chan)';
            this.nspChanOffset = cumsum([0; numChansPerNSP(1:end-1)]);
            
            % apply groupDefinitions to construct featureList
            this.featureCount = 0;
            this.featureList = cell(0,length(this.featureLabels));
            flIdx = 1;
            for gg=1:length(this.groupDefinitions)
                
                % create smoothing kernel
                this.kernelCollection{gg} = fspecial(this.groupDefinitions(gg).KernelType,this.groupDefinitions(gg).KernelParameters{:});
                
                % define subsampling indices
                step = this.groupDefinitions(gg).SubsamplingFactor;
                [subx,suby] = meshgrid(1:step:10,1:step:10);
                if 10-subx(end) >= 2 % shift toward middle of array
                    subx = subx + floor( (10-subx(end))/2 );
                end
                if 10-suby(end) >= 2 % shift toward middle of array
                    suby = suby + floor( (10-suby(end))/2 );
                end
                
                % populate featureList
                for nn=1:this.nspCount
                    for kk=1:numel(subx)
                        fband = this.groupDefinitions(gg).FrequencyBand;
                        subsfac = this.groupDefinitions(gg).SubsamplingFactor;
                        row = suby(kk);
                        col = subx(kk);
                        this.featureList(flIdx,:) = {flIdx,nn,gg,row,col,fband,subsfac};
                        flIdx = flIdx + 1;
                    end
                end
            end
            this.featureCount = flIdx-1;
            
            % initialize feature indexing
            this.chanIdx = cell(this.nspCount,1);
        end % END function LocalAvgLFPFeatureList
        
        function z = processFeatures(this,raw,winSize)
            z = zeros(this.featureCount,1);
            
            % initialization phase
            initializeFlag = false;
            if isempty(this.buffer), initializeFlag = true; end
            
            % pull data out of master cell array
            raw = raw{1};
            winSize = winSize{1};
            
            % require 1xN cell arrays for N NSPs
            % each cell should be 96xM for 96 channels and M samples
            if ~iscell(raw)
                error('Blackrock:LocalAvgLFPFeatureList:Error','Must provide 1x%d cell array (nspCount=%d)',this.nspCount,this.nspCount);
            end
            nchans = cellfun(@(x)size(x,1),raw);
            if ~all(nchans>=96)
                nchanStr = '';
                for kk=1:length(nchans)
                    nchanStr = sprintf('%sNSP%d: %d; ',nchanStr,kk,nchans(kk));
                end
                error('Blackrock:LocalAvgLFPFeatureList:Error','Must provide 96-row (or larger) matrix in each cell of incoming data (incoming %s)',nchanStr(1:end-2));
            end
            
            % register data buffer for concatenated data from all NSPs
            % circular buffers to hold winSize*fs samples of data
            if initializeFlag
                winSizeSamples = ceil(this.fs*winSize);
                this.buffer = Buffer.Circular(winSizeSamples,'r');
                
                % find linear indices to the unique set of channels
                for kk=1:this.nspCount
                    this.chanIdx{kk} = sub2ind(size(raw{kk}),1:96,repmat(3,1,96));
                    this.fsIdx{kk} = sub2ind(size(raw{kk}),1:96,repmat(2,1,96));
                end
            end
            
            % check sampling rates
            for kk=1:this.nspCount
                inputfs = raw{kk}(this.fsIdx{kk});
                inputfs = unique(cat(1,inputfs{:}));
                if numel(inputfs)>1
                    warning('Blackrock:LocalAvgLFPFeatureList:Warning','In NSP %d, multiple sampling rates %s(expected only %d)',kk,sprintf('%d ',inputfs),this.fs);
                end
            end
            
            % channel reduction; enforce uniform amount of data for all channels
            newContinuousData = cellfun(@(x,y)x(y),raw(:),this.chanIdx(:),'UniformOutput',false);
            newContinuousData = cat(2,newContinuousData{:}); % concatenate data from all NSPs
            M = cellfun(@length,newContinuousData); % find lengths of each desired channel
            minM = min(M); % smallest length among all channels, all NSPs
            largeIdx = M>minM;
            newContinuousData(largeIdx) = cellfun(@(x)x(end-minM+1:end),newContinuousData(largeIdx),'UniformOutput',false); % all channels same length
            newContinuousData = double(cell2mat(newContinuousData)); % convert to matrix of doubles
            add(this.buffer,newContinuousData); % add new data to buffer
            
            % get buffered data
            bufferData = get(this.buffer); % retrieve data from buffer
            
            % if N < num_samples, reduce data to most recent N samples
            st = max(1,size(bufferData,1)-this.N+1);
            lt = size(bufferData,1);
            bufferData = bufferData(st:lt,:);
            
            % create window kernel
            if initializeFlag
                num_samples = size(bufferData,1);
                this.fftWin = repmat(hann(num_samples),[1 size(bufferData,2)]);
            end
            
            % power spectral density estimate using windowed FFT
            % see link below for indexing/scaling explanation
            % http://www.mathworks.com/help/signal/ug/psd-estimate-using-fft.html
            S = fft(bufferData.*this.fftWin,this.N);
            S = S(1:this.N/2+1,:);
            S = (1/(this.fs*this.N)).*abs(S).^2;
            S(2:end-1,:) = 2*S(2:end-1,:);
            w = (0:this.fs/this.N:this.fs/2)';
            
            % plot the spectra
            if this.enablePlot
                if isempty(this.figureHandles)
                    figure;
                    this.figureHandles = plot(w,10*log10(abs(S)));
                else
                    for kk=1:length(this.figureHandles)
                        set(this.figureHandles(kk),'XData',w,'YData',10*log10(abs(S(:,kk))));
                    end
                end
            end
            
            % create index of frequencies to be averaged for each group
            % definition
            if initializeFlag
                this.groupFreqIdx = zeros(length(w),length(this.groupDefinitions));
                for gg = 1:length(this.groupDefinitions)
                    freq = this.groupDefinitions(gg).FrequencyBand;
                    for ff = 1:size(freq,1)
                        this.groupFreqIdx(:,gg) = this.groupFreqIdx(:,gg) | w>=freq(ff,1)&w<=freq(ff,2);
                    end
                end
            end
            
            % prep for converting vectors into layouts
            if initializeFlag
                for nn=1:this.nspCount
                    [crx,cry] = this.hNeuralSource.hArrayMaps{nn}.ch2cr(1:96);
                    this.vec2layout{nn} = sub2ind([10 10],cry(:)+1,crx(:)+1);
                end
                this.cornerIdx = sub2ind([10 10],[1 1 10 10],[1 10 1 10]);
                this.cornerAvgIdx(:,1) = sub2ind([10 10],[2 2 1],[1 2 2]);
                this.cornerAvgIdx(:,2) = sub2ind([10 10],[1 2 2],[9 9 10]);
                this.cornerAvgIdx(:,3) = sub2ind([10 10],[9 9 10],[1 2 2]);
                this.cornerAvgIdx(:,4) = sub2ind([10 10],[10 9 9],[9 9 10]);
            end
            
            % average over group frequency bands, transform from
            % vector into array layout, smooth, and subsample
            freqAvgS = cell(length(this.groupDefinitions),this.nspCount);
            for gg=1:length(this.groupDefinitions)
                tmpFreqAvgS = mean(S( logical(this.groupFreqIdx(:,gg)), : ));
                kernelSize = min(10,max(size(this.kernelCollection{gg})));
                for nn=1:this.nspCount
                    nspS = tmpFreqAvgS(this.nspChanOffset(nn)+1:this.nspChanOffset(nn)+96);
                    
                    %tic; layoutS = this.hArrayMapCollection{nn}.ch2layout(nspS,'interp'); toc
                    layoutS = nan(10,10);
                    layoutS(this.vec2layout{nn}) = nspS;
                    layoutS = flipud(layoutS);
                    layoutS(this.cornerIdx) = mean(layoutS(this.cornerAvgIdx));
                    
                    paddedS = util.PadSymmetricReflectionMatrix(layoutS,kernelSize);
                    smoothedS = filter2(this.kernelCollection{gg},paddedS,'same');
                    freqAvgS{gg,nn} = smoothedS(kernelSize+1:end-kernelSize,kernelSize+1:end-kernelSize);
                end
            end
            
            % prep for assigning features
            if initializeFlag
                for id=1:this.featureCount
                    this.featureListIdx(id).nsp = this.featureList{id,strcmpi(this.featureLabels,'nsp')};
                    this.featureListIdx(id).group = this.featureList{id,strcmpi(this.featureLabels,'group')};
                    this.featureListIdx(id).row = this.featureList{id,strcmpi(this.featureLabels,'row')};
                    this.featureListIdx(id).col = this.featureList{id,strcmpi(this.featureLabels,'column')};
                end
            end
            
            % assign features
            for id=1:this.featureCount
                z(id) = freqAvgS{this.featureListIdx(id).group,this.featureListIdx(id).nsp}(this.featureListIdx(id).row,this.featureListIdx(id).col);
            end
        end % END function processFeatures
        
        function list = getFeatureList(this)
            list = this.featureList;
        end % END function getFeatureList
        
        function plotKernels(this)
            row_range = 1:length(this.kernelCollection);
            col_range = length(this.kernelCollection)./row_range;
            [~,idx] = min(row_range+col_range);
            nr = row_range(idx);
            nc = ceil(col_range(idx));
            
            figure;
            for k=1:length(this.kernelCollection)
                [meshx,meshy] = meshgrid(1:size(this.kernelCollection{k},2),1:size(this.kernelCollection{k},1));
                subplot(nr,nc,k);
                surf(meshx,meshy,this.kernelCollection{k})
                paramStr = sprintf('%.1f, ',this.groupDefinitions(k).KernelParameters{:});
                title([sprintf('%d-%d Hz',this.groupDefinitions(k).FrequencyBand) ': ' this.groupDefinitions(k).KernelType ' (' sprintf('%s',paramStr(1:end-2)) ')']);
            end
        end % END function plotKernels
        
        function close(~)
        end % END function close
        
        function st = toStruct(this,varargin)
            
            % collect all fields to skip, adding 'hCards'
            skip = [varargin {'buffer','hNeuralSource','figureHandles'}];
            
            % get all other fields
            st = toStruct@util.Structable(this,skip{:});
        end % END function toStruct
        
    end % END methods
    
    methods(Static)
        
        function evaluateKernel(type,varargin)
            switch type
                case {'average','disk','gaussian','log','motion'}, num=varargin{1};
                case {'laplacian','sobel'}, num=3;
            end
            [x,y] = meshgrid(1:num,1:num);
            h = fspecial(type,varargin{:});
            
            % dummy data 10x10
            orig = [...
                0.8     0.0     0.7     0.0     0.5     0.0     0.5     0.0     0.7     0.0
                0.0     0.6     0.0     0.4     0.0     0.4     0.0     0.4     0.0     0.9
                0.7     0.0     0.5     0.0     0.3     0.0     0.3     0.0     0.5     0.0
                0.0     0.5     0.0     0.2     0.0     0.2     0.0     0.3     0.0     0.8
                0.6     0.0     0.3     0.0     0.1     0.0     0.2     0.0     0.4     0.0
                0.0     0.4     0.0     0.4     0.0     0.0     0.0     0.2     0.0     0.7
                0.5     0.0     0.3     0.0     0.1     0.0     0.2     0.0     0.5     0.0
                0.0     0.3     0.0     0.5     0.0     0.2     0.0     0.4     0.0     0.8
                0.4     0.0     0.2     0.0     0.2     0.0     0.4     0.0     0.7     0.0
                0.0     0.5     0.0     0.4     0.0     0.4     0.0     0.5     0.0     0.9];
            [origx,origy] = meshgrid(1:10,1:10);
            
            % pad the signal with symmetric reflections of itself (kernel size)
            pad = util.PadSymmetricReflectionMatrix(orig,num);
            
            % filter the signal with the kernel
            filt = filter2(h,pad,'same');
            filt = filt(num+1:end-num,num+1:end-num); % remove edges
            
            % show retained values after subsampling
            [subx,suby] = meshgrid(1:num:10,1:num:10);
            if 10-subx(end) >= 2 % shift toward middle of array
                subx = subx + floor( (10-subx(end))/2 );
            end
            if 10-suby(end) >= 2 % shift toward middle of array
                suby = suby + floor( (10-suby(end))/2 );
            end
            kept = nan(10,10);
            kept(subx,suby) = filt(subx,suby);
            
            % display results
            paramStr = sprintf('%.1f, ',varargin{:});
            figure('Name',[type ' (' sprintf('%s',paramStr(1:end-2)) ')'],'Position',[10,400,1840,370]);
            
            subplot(151)
            xplot = x;%*0.4;
            yplot = y;%*0.4;
            surf(xplot,yplot,h);
            xlim([xplot(1) xplot(end)]);
            ylim([yplot(1) yplot(end)]);
            zlim([0 1]);
            set(gca,'CLim',[0 1]);
            % xlabel('distance (mm)');
            % ylabel('distance (mm)');
            % zlabel('weight');
            title([type ' (' sprintf('%s',paramStr(1:end-2)) ')']);
            
            subplot(152)
            [maxHXIdx,maxHYIdx] = find(h==max(h(:)),1);
            xplot = x(1,maxHXIdx:end)-x(1,maxHXIdx);%x(1,maxHXIdx:end)*0.4-x(1,maxHXIdx)*0.4;
            plot(xplot,h(maxHYIdx,maxHXIdx:end));
            title('weighting dropoff');
            % xlabel('distance (mm)');
            % ylabel('weight');
            
            subplot(153)
            surf(origx,origy,orig)
            xlim([1 10]); ylim([1 10]); zlim([0 1]);
            set(gca,'CLim',[0 1]);
            title('original signal');
            
            subplot(154);
            surf(origx,origy,filt);
            xlim([1 10]); ylim([1 10]); zlim([0 1]);
            set(gca,'CLim',[0 1]);
            title('filtered signal');
            
            subplot(155)
            h = bar3(kept);
            for k = 1:length(h)
                idx = logical(kron(isnan(kept(:,k)),ones(6,1)));
                zdata = get(h(k),'ZData');
                zdata(idx,:) = nan;
                set(h(k),'CData',zdata,'FaceColor','interp')
            end
            xlim([0 11]);
            ylim([0 11]);
            set(gca,'CLim',[0 1]);
            title('selected values');
            
        end % END function evaluateKernel
    end % END methods(Static)
    
end % END classdef LocalAvgLFPFeatureList