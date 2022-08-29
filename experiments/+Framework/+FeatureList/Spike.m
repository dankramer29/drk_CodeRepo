classdef Spike < handle & Framework.FeatureList.Interface & util.Structable & util.StructableHierarchy
    
    properties
        fs
    end
    
    properties(SetAccess='private',GetAccess='public')
        featureDefinitions
        featureCount
        featureIdx
        dataTypes = {'EVENT'};
        isInitialized = false;
    end % END properties(SetAccess='private',GetAccess='public')
    
    methods
        function this = Spike(parent,varargin)
            % SPIKE Create spike feature list
            %
            %   INPUTS
            %   'fs',FS
            %   sampling frequency, default 30e3
            %
            %   'featdef',DEF
            %   table with variable names 'feature','nsp','channel','unit'
            %   and one row per desired feature (if provided, none of the
            %   below options are relevant)
            %
            %   'snrfiles',{snrfile1,snrfile2,...}
            %   must be one snr file per NSP (if provided, none of the
            %   below options are relevant)
            %
            %   'chan_unit',CH_UN
            %   cell array with one cell per NSP; each cell a matrix with
            %   two columns (channel, unit) and one row per channel-unit
            %   pair desired to be used as a feature (if provided none of
            %   the below options are relevant)
            %
            %   'channels',CHANNELS
            %   provide list of channels to use; if not provided, use all
            %   channels listed in GridMap object(s)
            %
            %   'which','unsorted'|'sorted'|'both'
            %   use only unsorted spikes, only sorted spikes, or both
            %   sorted and unsorted spikes (default unsorted only).
            this = this@Framework.FeatureList.Interface(parent);
            numNSPs = length(this.hNeuralSource.hGridMap);
            
            % parse simple inputs
            [varargin,this.fs] = util.argkeyval('fs',varargin,30e3);
            
            % create feature definitions
            [varargin,featdef,~,found_featdef] = util.argkeyval('featdef',varargin,[]);
            if found_featdef
                
                % validate user input
                assert(istable(featdef),'Must provide feature definitions as a table, not "%s"',class(featdef));
                assert(all(ismember({'nsp','channel','unit'},featdef.Properties.VariableNames)),'Feature definitions table must have variable names "nsp", "channel", and "unit" (one or more not found in list: %s)',strjoin(featdef.Properties.VariableNames));
                this.featureDefinitions = featdef;
            else
                % set channels/units
                [varargin,snrfiles,~,found_snrfiles] = util.argkeyval('snrfiles',varargin,{});
                if found_snrfiles
                    
                    % read out list of channels/units from the SNR files
                    if ~iscell(snrfiles),snrfiles={snrfiles};end
                    assert(length(snrfiles)==numNSPs,'Must provide one SNR file per NSP (found %d but expected %d)',length(snrfiles),numNSPs);
                    chan_unit = cell(1,numNSPs);
                    for kk=1:length(snrfiles)
                        chan_unit{kk} = Blackrock.SNRFile2FeatureList(this.snrFiles{kk});
                    end
                else
                    
                    % get channels
                    [varargin,channels,~,found_channels] = util.argkeyval('channels',varargin,nan);
                    [varargin,chan_unit,~,found_chan_unit] = util.argkeyval('chan_unit',varargin,nan);
                    if ~found_channels && ~found_chan_unit
                        channels = cellfun(@(x)x.ChannelInfo.Channel(:),this.hNeuralSource.hGridMap,'UniformOutput',false);
                    end
                    
                    % get units
                    if ~found_chan_unit
                        [varargin,which_spikes] = util.argkeyval('type',varargin,'unsorted'); % by default use only the unsorted units
                        
                        % create list of channels/units from scratch
                        if strcmpi(which_spikes,'unsorted')
                            
                            % only use unclassified spikes, i.e., '0' label
                            units = cellfun(@(x)zeros(size(x)),channels,'UniformOutput',false);
                        elseif strcmpi(which_spikes,'sorted')
                            
                            % use all sorted spikes
                            units = cell(1,numNSPs);
                            for kk=1:numNSPs
                                channels{kk} = repmat(channels{kk}(:),5,1);
                                units{kk} = repmat(1:5,length(this.hNeuralSource.hGridMap{kk}.ChannelInfo.Channel),1);
                                units{kk} = units{kk}(:);
                            end
                        elseif strcmpi(which_spikes,'both')
                            
                            % use both unsorted and sorted spikes
                            units = cell(1,numNSPs);
                            for kk=1:numNSPs
                                channels{kk} = repmat(channels{kk}(:),6,1);
                                units{kk} = repmat(0:5,length(this.hNeuralSource.hGridMap{kk}.ChannelInfo.Channel),1);
                                units{kk} = units{kk}(:);
                            end
                        end
                        chan_unit = cellfun(@(x,y)[x(:) y(:)],channels,units,'UniformOutput',false);
                    end
                end
                
                % create feature definition table
                numFeatures = cellfun(@(x)size(x,1),chan_unit);
                feats = cell(sum(numFeatures),3);
                idx = 0;
                for kk=1:numNSPs
                    nsp = arrayfun(@(x)x,repmat(kk,numFeatures(kk),1),'UniformOutput',false);
                    channel = arrayfun(@(x)x,chan_unit{kk}(:,1),'UniformOutput',false);
                    unit = arrayfun(@(x)x,chan_unit{kk}(:,2),'UniformOutput',false);
                    feats(idx+(1:numFeatures(kk)),:) = [nsp(:) channel(:) unit(:)];
                    idx = idx + numFeatures(kk);
                end
                this.featureDefinitions = cell2table(feats,'VariableNames',{'nsp','channel','unit'});
                this.featureCount = size(this.featureDefinitions,1);
                assert(istable(this.featureDefinitions),'Feature definitions must be a table, not a "%s"',class(this.featureDefinitions));
            end
            
            % make sure no leftover input arguments
            util.argempty(varargin);
        end % END function Spike
        
        function initialize(this,raw,~)
            numNSPs = length(this.hNeuralSource.hGridMap);
            
            % pull data out of master cell array
            raw = raw{1};
            
            % check for consistency
            assert(iscell(raw),'Expected cell array from CBMEX but found "%s"',class(raw));
            assert(numel(size(raw))==2&&any(size(raw)==1)&&any(size(raw)==numNSPs),'Expected 1x%d cell array from CBMEX, but found %s',numNSPs,util.vec2str(size(raw)));
            nchans_found = cellfun(@(x)size(x,1),raw);
            nchans_expected = cellfun(@(x)x.NumChannels,this.hNeuralSource.hGridMap);
            assert(all(nchans_found>=nchans_expected),'Expected at least %d channels in the raw data but found only %d',nchans_expected,nchans_found);
            
            % indices into cell array to pull out only chan/units we want
            for kk=1:numNSPs
                nspIdx = this.featureDefinitions.nsp==kk;
                this.featureIdx{kk} = sub2ind(size(raw{kk}),this.featureDefinitions.channel(nspIdx),this.featureDefinitions.unit(nspIdx)+2);
            end
            
            % update initialization status
            this.isInitialized = true;
        end % END function initialize
        
        function z = processFeatures(this,raw,winSize)
            assert(this.isInitialized,'Feature list not initialized');
            numNSPs = length(this.hNeuralSource.hGridMap);
            
            % pull data out of master cell array
            raw = raw{1};
            winSize = winSize{1};
            
            % check for consistency
            assert(iscell(raw),'Expected cell array from CBMEX but found "%s"',class(raw));
            assert(numel(size(raw))==2&&any(size(raw)==1)&&any(size(raw)==numNSPs),'Expected 1x%d cell array from CBMEX, but found %s',numNSPs,util.vec2str(size(raw)));
            
            % pull out only chan/units we want
            timestamps = cellfun(@(x,y)x(y),raw(:),this.featureIdx(:),'UniformOutput',false);
            timestamps = cat(1,timestamps{:});
            
            % create features
            z = zeros(this.featureCount,1);
            winSizeSamples = round(this.fs*winSize); % convert from seconds to samples
            for id=1:this.featureCount
                new = timestamps{id};
                buf = new(new>0 & new<=winSizeSamples);
                z(id) = length(buf);
            end
        end % END function processFeatures
        
        function def = getFeatureDefinition(this)
            def = this.featureDefinitions;
        end % END function getFeatureDefinition
        
        function close(~)
        end % END function close
        
        function list = structableSkipFields(this)
            list1 = structableSkipFields@Framework.FeatureList.Interface(this);
            list = [list1 {}];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@Framework.FeatureList.Interface(this);
            st2 = [];
            st = util.catstruct(st1,st2);
        end % END function structableManualFields
    end % END methods
end % END classdef Spike