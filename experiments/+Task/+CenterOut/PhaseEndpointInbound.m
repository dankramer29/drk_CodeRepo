classdef PhaseEndpointInbound < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseEndpointInbound(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseEndpointInbound
        
        function StartFcn(this,evt,hTask,varargin)
            
            % set up target
            hTask.hTarget{1}.homeTarget;
            
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            pos = hTask.hDisplayClient.normPos2Client([0 0]);
            diam = hTask.hDisplayClient.normScale2Client(0.02);
            hTask.hDisplayClient.drawOval(pos,diam,[0 0 1]*50)
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            
            % play sound
            if hTask.params.useSound
                hTask.hSound.play('Timeout');
            end
            
            % abort the trial
            hTask.hTrial.abort;
            
        end % END function TimeoutFcn
        
        function ObjectHitFcn(this,evt,hTask,varargin)
            
            % mark trial as a success
            hTask.hTrial.TrialData.ex_success = true;
            hTask.stats.score = hTask.stats.score + 1;
            
            % next phase
            hTask.hTrial.advance;
            
        end % END function ObjectHitFcn
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
        
    end % END methods
    
end % END classdef PhaseEndpointInbound