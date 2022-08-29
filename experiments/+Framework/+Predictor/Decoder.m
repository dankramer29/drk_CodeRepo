classdef Decoder < handle & Framework.Predictor.Interface & util.Structable & util.StructableHierarchy
    
    properties
        hDecoder
        isTrained
    end % END properties
    
    methods
        
        function val = get.isTrained(this)
            val = this.hDecoder.isTrained;
        end % END function get.isTrained
        
        function this = Decoder(fw,cfg)
            this = this@Framework.Predictor.Interface(fw);
            
            % localConfig
            dConfig.frameworkParams.savePath = this.hFramework.options.saveDirectory;
            dConfig.frameworkParams.saveName = sprintf('%s-decoder.mat',this.hFramework.idString);
            dConfig.frameworkParams.featureDescriptions = getFeatureDefinition(this.hFramework.hNeuralSource);
            
            % bitwise indication (bit1==CONTINUOUS, bit2==EVENT) can both be set
            featType = zeros(1,sum(cellfun(@(x)x.featureCount,this.hFramework.hNeuralSource.hFeatureListCollection)),'uint8');
            featIdx = 0;
            for nn = 1:length(this.hFramework.hNeuralSource.hFeatureListCollection)
                numFeats = this.hFramework.hNeuralSource.hFeatureListCollection{nn}.featureCount;
                dataTypes = this.hFramework.hNeuralSource.hFeatureListCollection{nn}.dataTypes;
                if any(strcmpi(dataTypes,'CONTINUOUS'))
                    featType(featIdx + (1:numFeats)) = bitset(featType(featIdx + (1:numFeats)),1);
                end
                if any(strcmpi(dataTypes,'EVENT'))
                    featType(featIdx + (1:numFeats)) = bitset(featType(featIdx + (1:numFeats)),2);
                end
                featIdx = featIdx + numFeats;
            end
            
            % initialize Decoder
            this.hDecoder = Predictor.Decoder(cfg,'localConfig',dConfig,'hFramework',this.hFramework,'featType',double(featType));
            
            % register gui update function to run every timer iteration
            this.hFramework.registerUpdateFcn(@updateGUI,this.hDecoder);
            
        end % END function Decoder
        
        function prediction = Predict(this,state,features,target)
            prediction = this.hDecoder.Predict(state,features,target,this.frameId);
        end % END function Predict
        
        function enablePredictor(this)
            this.hDecoder.enableDecoder;
        end % END function enablePredictor
        
        function disablePredictor(this)
            this.hDecoder.disableDecoder;
        end % END function disablePredictor
        
        function setAssistLevel(this,val)
            this.hDecoder.runtimeParams.assistLevel = val;
        end % END function setAssistLevel
        
        function val = getAssistLevel(this)
            val = getAssistLevel(this.hDecoder);
        end % END function getAssistLevel
        
        function dc = getTrialData(this)
            dc.runtimeParams = this.hDecoder.runtimeParams;
            dc.isTrained = this.isTrained;
            dc.decoderIdx = this.hDecoder.currentDecoderINDX;
        end % END function getTrialData
        
        function skip = structableSkipFields(this)
            skip = [{'hFramework','hDecoder'} structableSkipFields@Framework.Predictor.Interface(this)];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Framework.Predictor.Interface(this);
            st.hDecoder = this.hDecoder.toStruct;
        end % END function structableManualFields
        
        function delete(this)
            delete(this.hDecoder);
        end
    end % END methods
    
end % END classdef Decoder