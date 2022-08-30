classdef PhaseEndpointOutbound < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseEndpointOutbound(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseEndpointOutbound
        
        function StartFcn(this,evt,hTask,varargin)
            
            % set up target
            hTask.hTarget{1}.enableEvents;
            
            % set up effector
            hTask.hEffector{1}.unlockState;
            hTask.hEffector{1}.enableEvents;
            hTask.hEffector{1}.setVisible;
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
            
            % disable effector
            hTask.hEffector{1}.setInvisible;
            hTask.hEffector{1}.setState(zeros(1,hTask.hEffector{1}.nStateVars));
            hTask.hEffector{1}.lockState;
            hTask.hEffector{1}.disableEvents;
            
            % disable target
            hTask.hTarget{1}.setInvisible;
            hTask.hTarget{1}.lockState; 
            hTask.hTarget{1}.disableEvents;
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
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
            
            % move on
            hTask.hTrial.advance;
        end % END function TimeoutFcn
        
        function ObjectHitFcn(this,evt,hTask,varargin)
            
            % mark trial as a success
            hTask.hTrial.TrialData.ex_success = true;
            hTask.stats.score = hTask.stats.score + 1;
            
            % finish the trial
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
end % END classdef PhaseEndpointOutbound