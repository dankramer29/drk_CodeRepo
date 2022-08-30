classdef EventFeatureListNSP1Only < handle & Framework.FeatureList.Interface & util.Structable & util.StructableHierarchy
    
    properties
        fs = 30e3;
        enableDisplay = false;
        enableStats = false;
        
        nspCount = 1;
        snrFiles = {'',''};
    end
    
    properties(SetAccess='private',GetAccess='public')
        hGUI
        handles
        histSpikeTimestamps
        
        featureLabels = {'feature','nsp','channel','unit'};
        featureList
        featureIdx
        featureCount = 0;
    
        dataTypes = {'EVENT'};
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        function this = EventFeatureListNSP1Only(parent,varargin)
            this = this@Framework.FeatureList.Interface(parent);
            
            % parse user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % create list of event features
            this.featureCount = 0;
            this.featureList = zeros(0,length(this.featureLabels));
            for kk = 1:this.nspCount
                if ~isempty(this.snrFiles{kk})
                    snrFileData = Blackrock.SNRFile2FeatureList(this.snrFiles{kk});
                    idx = (this.featureCount+1) : (this.featureCount + size(snrFileData,1));
                    this.featureList( idx, : ) = [idx(:) repmat(kk,size(idx(:))) snrFileData(:,1) snrFileData(:,2)];
                else
                    idx = (this.featureCount+1) : (this.featureCount+96);
                    this.featureList( idx, : ) = [idx(:) repmat(kk,size(idx(:))) (1:96)' zeros(96,1)];
                end
                this.featureCount = size(this.featureList,1);
            end
            
            % initialize feature indexing
            this.featureIdx = cell(this.nspCount,1);
            
            % start up the gui
            gui(this);
            
        end % END function EventFeatureList
        
        function z = processFeatures(this,raw,winSize)
            
            
            % pull data out of master cell array
            raw = raw{1};
            winSize = winSize{1};
            
            % check for consistencies
            assert(length(raw)==this.nspCount,'Incoming data suggests %d NSPs, but expected %d',length(raw),length(this.featureIdx));
            oldNSPCount = this.nspCount;
            
            this.nspCount = 1;
            % indices into cell array to pull out only chan/units we want
            if all(cellfun(@isempty,this.featureIdx))
                for kk=1:this.nspCount
                    nspIdx = this.featureList(:,2)==kk;
                    this.featureIdx{kk} = sub2ind(size(raw{kk}),this.featureList(nspIdx,3),this.featureList(nspIdx,4)+2);
                end
            end
            
            % pull out only chan/units we want
            timestamps = cell(size(raw));
            for kk=1:length(raw)
                timestamps{kk} = raw{kk}(this.featureIdx{kk});
            end
            timestamps = cat(1,timestamps{:});
            
            % create features
            z = zeros(this.featureCount,1);
            winSizeSamples = ceil(this.fs*winSize); % convert from seconds to samples
            proc = [];
            for id=1:this.featureCount
                new = timestamps{id};
                buf = new(new>0 & new<=winSizeSamples);
                z(id) = length(buf);
                if this.enableStats && ~isempty(buf)
                    proc = cat(1,proc,buf(:));
                end
            end
            
            % calculate (display) histogram of spike data
            if this.enableStats
                
                rcvd = cat(1,timestamps{:});
                [n1,x1] = hist(double(rcvd),-25:5:5000);
                [n2,x2] = hist(double(proc),-25:5:5000);
                if isempty(this.histSpikeTimestamps)
                    this.histSpikeTimestamps.raw = zeros(size(n1));
                    this.histSpikeTimestamps.proc = zeros(size(n2));
                    this.histSpikeTimestamps.bins = x1;
                    this.histSpikeTimestamps.numFrames = 0;
                end
                this.histSpikeTimestamps.raw = this.histSpikeTimestamps.raw+n1;%/n1trapz;
                this.histSpikeTimestamps.proc = this.histSpikeTimestamps.proc+n2;%/n2trapz;
                this.histSpikeTimestamps.numFrames = this.histSpikeTimestamps.numFrames + 1;
                if any(isnan(n1)) || any(isnan(n2)) || ...
                        any(isnan(this.histSpikeTimestamps.raw)) || ...
                        any(isnan(this.histSpikeTimestamps.proc))
                    warning('Framework:NeuralSource:CBMEX:Warning','Found NaNs somewhere');
                    this.histSpikeTimestamps.raw = zeros(size(n1));
                    this.histSpikeTimestamps.proc = zeros(size(n2));
                    this.histSpikeTimestamps.numFrames = 0;
                end
                
                if this.enableDisplay
                    bar(this.handles.cbmexAxes,[x1(:) x2(:)],[this.histSpikeTimestamps.raw(:) this.histSpikeTimestamps.proc(:)]);
                end
            end
             this.nspCount = oldNSPCount;
        end % END function processFeatures
        
        function list = getFeatureList(this)
            list = this.featureList;
        end % END function getFeatureList
        
        function gui(this,varargin)
            if nargin>1
                if ischar(varargin{1})
                    switch lower(varargin{1})
                        case 'on'
                            this.enableDisplay = true;
                        case 'off'
                            this.enableDisplay = false;
                    end
                else
                    this.enableDisplay = logical(varargin{1});
                end
            end
            
            if ~isempty(this.hGUI) && ishandle(this.hGUI) && ~this.enableDisplay
                close(this.hGUI);
                this.handles = [];
            elseif this.enableDisplay
                this.hGUI = figure;
                axes('Tag','cbmexAxes','Parent',this.hGUI);
                this.handles = guihandles(this.hGUI);
                xlabel(this.handles.cbmexAxes,'Spike Timestamps (samples)');
                ylabel(this.handles.cbmexAxes,'Number of Spike Timestamps');
                title(this.handles.cbmexAxes,{'Spike Timestamp Histogram (incoming vs. processed)','blue=incoming, red=processed'});
            end
        end % END function gui
        
        function close(~)
            % if this.hEventFeatureList.enableStats
            %     savePath = fullfile(this.hFramework.options.saveDirectory,[this.hFramework.idString '_cbmexStats.mat']);
            %     st = this.hEventFeatureList.histSpikeTimestamps;
            %     if ~isempty(st) && isstruct(st)
            %         save(savePath,'-struct','st');
            %         cmdWindowOutput(this,sprintf('Saved stats to <a href="matlab:load(''%s'');">''%s''</a>',savePath,savePath));
            %     end
            % end
        end % END function close
        
        function list = structableSkipFields(this)
            list1 = structableSkipFields@Framework.FeatureList.Interface(this);
            list = [list1 {'hGUI','handles'}];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@Framework.FeatureList.Interface(this);
            st2 = [];
            st = util.catstruct(st1,st2);
        end % END function structableManualFields
    end % END methods
end % END classdef EventFeatureList