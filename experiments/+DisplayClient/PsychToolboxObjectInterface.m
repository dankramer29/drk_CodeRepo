classdef PsychToolboxObjectInterface < handle & util.StructableHierarchy
    
    properties
        
        defaultScale            % default size of object
        defaultShape            % default shape of object
        defaultAlpha            % default transparency of object
        defaultColor            % default color of object
        defaultBrightness       % default brightness of object
        
        scale                   % size of the object
        shape                   % shape of the object
        alpha                   % percent (0 -> 100) transparency
        color                   % normalized (0 -> 1) color triplet (R G B)
        brightness              % multiplier (0 -> 255) on the normalized (0 -> 1) color triplet (R G B)
        imagefile               % image file for images
        angles                   % orientation for images
    end % END properties
    
    methods
        function this = PsychToolboxObjectInterface(varargin)
            % process inputs
            idx = 1;
            while idx <= length(varargin)
                if isprop(this,varargin{idx})
                    this.(varargin{idx}) = varargin{idx+1};
                    idx = idx + 1;
                end
                idx = idx + 1;
            end
            
            % set all attributes to default
            this.scale = this.defaultScale;
            this.shape = this.defaultShape;
            this.alpha = this.defaultAlpha;
            this.color = this.defaultColor;
            this.brightness = this.defaultBrightness;
            %this.imagefile = '';
        end % END function PsychToolboxObjectInterface
        
        function skip = structableSkipFields(this,varargin)
            skip = {};
        end % END function structableSkipFields
        
        function st = structableManualFields(this,varargin)
            st = [];
        end % END function structableManual
    end % END methods
    
    methods(Abstract)
        pos = getDisplayPosition(this);
    end % END methods(Abstract)
    
end % END classdef PsychToolboxObjectInterface