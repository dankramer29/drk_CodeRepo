classdef EndpointTarget < Experiment2.MovablePTBObject & util.Structable & util.StructableHierarchy
    
    properties
        type = Experiment2.TaskObjectType.TARGET;
        
        % target properties
        locationHome
        targetLocations
        targetUseCount
        targetCurrentIdx
    end % END properties
    
    methods
        function this = EndpointTarget(parent,id,nStateVars,idxStateHitTest,varargin)
            this = this@Experiment2.MovablePTBObject(parent,id,nStateVars,idxStateHitTest,varargin{:});
            this.targetUseCount = zeros(size(this.targetLocations,1),1);
            this.setState(this.locationHome);
            
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
            
        end % END function EndpointTarget
        
        function newTarget(this)
            
            % prepare to update target/distractor positions
            randIdx = randperm(size(this.targetLocations,1));
            usedIdx = 1;
            
            % even out the number of times the target appears at each 
            % object location over time
            avgLocationCount = mean(this.targetUseCount);
            while this.targetUseCount(randIdx(usedIdx))>avgLocationCount
                usedIdx = usedIdx + 1;
            end
            if usedIdx > length(randIdx)
                error('Experiment:Task:Error','Could not find a location that was used less than the average (?!)');
            end
            this.targetUseCount(randIdx(usedIdx)) = this.targetUseCount(randIdx(usedIdx)) + 1;
            this.targetCurrentIdx = randIdx(usedIdx);

%             if isempty(this.targetCurrentIdx)
%                 idx = 1;
%             else
%                 idx = this.targetCurrentIdx + 1;
%             end
%             
%             if idx>size(this.targetLocations,1)
%                 idx = 1;
%             end
%             this.targetUseCount(idx) = this.targetUseCount(idx) + 1;
%             this.targetCurrentIdx = idx;

            setState(this,this.targetLocations(this.targetCurrentIdx,:));
        end % END function newTarget
        
        function homeTarget(this)
            setState(this,this.locationHome);
        end % END function homeTarget
        
        function update(~)
        end % END function update
        
        function HitFcn(this,evt,hTask,varargin)
        end % END function HitFcn
        
        function EnterFcn(this,evt,hTask,varargin)
        end % END function EnterFcn
        
        function ExitFcn(this,evt,hTask,varargin)
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
    
end % END classdef EndpointTarget