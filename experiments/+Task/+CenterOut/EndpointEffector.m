classdef EndpointEffector < Experiment2.MovablePTBObject & util.StructableHierarchy & util.Structable
    
    properties
        type = Experiment2.TaskObjectType.EFFECTOR;
    end
    
    methods
        function this = EndpointEffector(parent,id,nStateVars,idxStateHitTest,varargin)
            this = this@Experiment2.MovablePTBObject(parent,id,nStateVars,idxStateHitTest,varargin{:});
            this.setState(zeros(1,this.nStateVars));
            
            % set all attributes to default
            this.scale = this.defaultScale;
            this.shape = this.defaultShape;
            this.alpha = this.defaultAlpha;
            this.color = this.defaultColor;
            this.brightness = this.defaultBrightness;
            
            % disable
            this.disableEvents;
            this.lockState;
            this.setInvisible;
            
        end % END function EndpointEffector
        
        function update(this)
            
            % test whether we're hitting any targets
            testTargetEnterExit(this,this.hTask.hTarget{this.primaryTarget});
            
        end % END function update
        
        function HitFcn(this,evt,hTask,varargin)
        end % END function HitFcn
        
        function EnterFcn(this,evt,hTask,varargin)
            this.brightness = 255;
        end % END function EnterFcn
        
        function ExitFcn(this,evt,hTask,varargin)
            this.brightness = this.defaultBrightness;
        end % END function ExitFcn
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@Experiment2.MovablePTBObject(this);
            skip = [{'type'} skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st.type = char(this.type);
            st1 = structableManualFields@Experiment2.MovablePTBObject(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
end % END classdef EndpointEffector