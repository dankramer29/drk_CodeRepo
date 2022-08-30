classdef Blackrock < handle & Framework.NeuralSource.Interface & util.Structable & util.StructableHierarchy
    
    properties
        hCBMEX % handle to Blackrock Interface
        hFeatureListCollection % handle(s) to feature lists/processors
        hGridMap % handle(s) to grid map object
        cbmexAddr % Central IPv4 address -- see cbmex('help','open')
        cbmexInterface % CBMEX interface type -- see cbmex('help','open')
        featureListConfig % configs for each of the feature lists
        dtMultipleEvent % window size in multiples of the timer step size dt
        dtMultipleContinuous % window size in multiples of the timer step size dt
        enableFileStorage = true; % whether to record a neural data file
        output % output path for saving files
    end % END properties
    
    properties(SetAccess='private')
        winSizeEvent % window size in seconds
        winSizeContinuous % window size in seconds
        
        isRecording
        isOpen
    end % END properties(SetAccess='private')
    
    properties(Constant)
        isSimulated = false;
    end % END properties(Constant)
    
    methods
        function val = get.isRecording(this)
            val = this.hCBMEX.isRecording;
        end
        function val = get.isOpen(this)
            val = this.hCBMEX.isOpen;
        end
        
        function this = Blackrock(fw,cfg,varargin)
            this = this@Framework.NeuralSource.Interface(fw);
            numNSPs = length(this.hFramework.options.nsps);
            
            % load in CBMEX arguments
            this.cbmexAddr = env.get('cbmexaddr');
            this.cbmexInterface = env.get('cbmexint');
            
            % default saving directory
            this.output = this.hFramework.options.output;
            
            % configure
            feval(cfg{1},this,cfg{2:end});
            if isempty(this.cbmexInterface), this.cbmexInterface=zeros(1,numNSPs); end
            assert(length(this.cbmexInterface)>=numNSPs,'Must provide at least %d values for cbmex interface types',numNSPs);
            assert(isempty(this.cbmexAddr)||length(this.cbmexAddr)>=numNSPs,'Must provide at least %d IP addresses for cbmex open args',numNSPs);
            assert(length(this.hGridMap)>=numNSPs,'Must provide at least %d grid maps (one for each NSP)',numNSPs);
            
            % win sizes
            this.winSizeEvent = this.dtMultipleEvent*this.hFramework.options.timerPeriod;
            this.winSizeContinuous = this.dtMultipleContinuous*this.hFramework.options.timerPeriod;
            
            % set up CBMEX interface
            cbmexInt = zeros(1,numNSPs);
            cbmexOpenArg = arrayfun(@(x){},1:numNSPs,'UniformOutput',false);
            for kk=1:numNSPs
                if ~isempty(this.cbmexAddr)
                    cbmexOpenArg{kk} = {'central-addr',this.cbmexAddr{kk}};
                end
                if ~isempty(this.cbmexInterface)
                    cbmexInt(kk) = this.cbmexInterface(kk);
                end
            end
            this.hCBMEX = Blackrock.Interface(...
                'outputPath',this.output,...
                'idString',this.hFramework.idString,...
                'userString',this.hFramework.options.runName,...
                'nspString',this.hFramework.options.nsps,...
                'cbmexOpenArgs',cbmexOpenArg,...
                'cbmexInterface',cbmexInt);
            this.hCBMEX.initialize;
            
            % read data to initialize the feature lists
            pause(2);
            [~,newNeuralEvent,newNeuralContinuous] = read(this.hCBMEX);
            
            % set up feature lists
            this.hFeatureListCollection = cell(1,length(this.featureListConfig));
            for kk=1:length(this.featureListConfig)
                
                % create the feature list object
                this.hFeatureListCollection{kk} = feval(this.featureListConfig(kk).handle,this,this.featureListConfig(kk).args{:});
                
                % collect the appropriate data
                data = cell(1,length(this.hFeatureListCollection{kk}.dataTypes));
                wins = cell(1,length(this.hFeatureListCollection{kk}.dataTypes));
                for mm=1:length(this.hFeatureListCollection{kk}.dataTypes)
                    switch lower(this.hFeatureListCollection{kk}.dataTypes{mm})
                        case 'event'
                            data{mm} = newNeuralEvent;
                            wins{mm} = this.winSizeEvent;
                        case 'continuous'
                            data{mm} = newNeuralContinuous;
                            wins{mm} = this.winSizeContinuous;
                        otherwise
                            error('Framework:NeuralSource:Blackrock:Error','Unknown data type ''%s''',this.hFeatureListCollection{kk}.dataTypes{mm});
                    end
                end
                
                % process into features
                initialize(this.hFeatureListCollection{kk},data,wins);
            end
        end % END function Blackrock
        
        function initialize(~)
        end % END function initialize
        
        function startRecording(this,varargin)
            if this.enableFileStorage
                if this.isRecording
                    this.hCBMEX.stop;
                    pause(0.5);
                end
                this.hCBMEX.record(varargin{:});
                comment(this,'Started recording neural data');
            end
        end % END function startRecording
        
        function stopRecording(this)
            if this.enableFileStorage
                this.hCBMEX.stop;
            end
        end % END function stopRecording
        
        function t = time(this,varargin)
            t = this.hCBMEX.time(varargin{:});
        end % END function time
        
        function [cbmexTime,z] = read(this)
            
            % read neural data
            [cbmexTime,newNeuralEvent,newNeuralContinuous] = read(this.hCBMEX);
            
            % process features from each feature list
            z = cell(1,length(this.hFeatureListCollection));
            for kk=1:length(this.hFeatureListCollection)
                
                % collect the appropriate data
                data = cell(1,length(this.hFeatureListCollection{kk}.dataTypes));
                wins = cell(1,length(this.hFeatureListCollection{kk}.dataTypes));
                for mm=1:length(this.hFeatureListCollection{kk}.dataTypes)
                    switch lower(this.hFeatureListCollection{kk}.dataTypes{mm})
                        case 'event'
                            data{mm} = newNeuralEvent;
                            wins{mm} = this.winSizeEvent;
                        case 'continuous'
                            data{mm} = newNeuralContinuous;
                            wins{mm} = this.winSizeContinuous;
                        otherwise
                            error('Framework:NeuralSource:Blackrock:Error','Unknown data type ''%s''',this.hFeatureListCollection{kk}.dataTypes{mm});
                    end
                end
                
                % process into features
                z{kk} = processFeatures(this.hFeatureListCollection{kk},data,wins);
            end
            
            % combine into single feature output vector
            z = cat(1,z{:});
        end % END function read
        
        function neuralComment(this,msg,varargin)
            comment(this.hCBMEX,msg,varargin{:});
        end % END function neuralComment
        
        function filenames = getRecordedFilenames(this)
            filenames = this.hCBMEX.getRecordedFilenames;
        end % END function getRecordedFilenames
        
        function labels = getAmplifierLabels(this)
            labels = this.hCBMEX.nspString;
        end % END function getAmplifierLabels
        
        function setAmplifierLabels(this,labels,varargin)
            idx = 1:length(this.hCBMEX.nspString);
            if ~isempty(varargin),idx=varargin{1}; end
            this.hCBMEX.nspString(idx) = labels;
        end % END function setAmplifierLabels
        
        function close(this)
            delete(this.hCBMEX);
            for kk=1:length(this.hFeatureListCollection)
                close(this.hFeatureListCollection{kk});
            end
        end % END function close
        
        function list = getFeatureDefinition(this)
            list = cell(1,length(this.hFeatureListCollection));
            for kk=1:length(this.hFeatureListCollection)
                list{kk} = this.hFeatureListCollection{kk}.getFeatureDefinition;
            end
        end % END function getFeatureDefinition
        function skip = structableSkipFields(this)
            skip = {'hFeatureListCollection'};
            skip1 = structableSkipFields@Framework.Component(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            for kk=1:length(this.hFeatureListCollection)
                st.hFeatureListCollection{kk} = this.hFeatureListCollection{kk}.toStruct;
            end
            st1 = structableManualFields@Framework.Component(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
    
    methods(Static)
        function cleanup
            Blackrock.Interface.cleanup;
        end % END function cleanup
    end % END methods(Static)
end % END classdef Blackrock