classdef Interface < handle & Framework.Component & util.StructableHierarchy
    
    properties(Abstract)
    end % END properties(Abstract)
    
    properties(Abstract,SetAccess='private')
        isOpen
        isRecording
    end % END properties(Abstract,SetAccess='private')
    
    properties(Abstract,Constant)
        isSimulated % define whether data is simulated or neural
    end % END properties(Abstract,Static)
    
    methods
        function this = Interface(fw,varargin)
            this = this@Framework.Component(fw,'NEURAL');
        end % END function Interface
        
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
    
    methods(Abstract)
        initialize(this);
        [z,timestamp] = read(this);
        close(this);
        startRecording(this,varargin);
        stopRecording(this);
        labels = getAmplifierLabels(this);
        setAmplifierLabels(this,labels,varargin);
        filenames = getRecordedFilenames(this);
        def = getFeatureDefinition(this);
        neuralComment(this,msg);
    end % END methods(Abstract)
    
end % END classdef Interface