classdef Rand < handle & Framework.NeuralSource.Interface & util.Structable & util.StructableHierarchy
    
    properties
        numChannels = 192;
        rateMin = 0;
        rateMax = 3;
        featureLabels = {'channel','unit'};
        featureList
        
        hFeatureListCollection = {}
        featureListConfig
    end % END properties
    
    properties(SetAccess='private')
        isOpen = false;
        isRecording = false;
    end % END properties(SetAccess='private')
    
    properties(Constant)
        isSimulated = true;
    end % END properties(Constant)
    
    methods
        
        function this = Rand(fw,cfg)
            this = this@Framework.NeuralSource.Interface(fw,'RANDDATA');
            feval(cfg{1},this,cfg{2:end});
            
            % create feature list
            this.featureList = {[(1:this.numChannels)' zeros(this.numChannels,1)]};
        end % END function Rand
        
        function initialize(~)
            this.isOpen = true;
        end % END function initialize
        
        function [timestamp,z] = read(this)
            timestamp = now;
            z = randi([this.rateMin this.rateMax],this.numChannels,1);
        end % END function read
        
            function [timestamp] = time(this)
            timestamp = now;
        end % END function read
        
        function close(~)
            this.isOpen = false;
        end % END function close
        
        function startRecording(~,varargin)
        end % END function startRecording
        
        function stopRecording(~)
        end % END function stopRecording
        
        function filenames = getRecordedFilenames(~)
            filenames = {''};
        end % END function getRecordedFilenames
        
        function names = getAmplifierLabels(this)
            names = {};
        end % END function getAmplifierLabels
        
        function setAmplifierLabels(this,labels,varargin)
        end % END function setAmplifierLabels
        
        function neuralComment(~,~)
        end % END function neuralComment
        
        function list = getFeatureDefinition(this)
            list = this.featureList;
        end % END function getFeatureList
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.Component(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.Component(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
end % END classdef Rand