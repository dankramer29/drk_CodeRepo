classdef PhaseMoveCursor < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        PhaseOrder
        durationTimeout
    end
    
    methods
        function this = PhaseMoveCursor(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
            if isempty(this.PhaseOrder),this.PhaseOrder=1;end
        end % END function PhaseMoveCursor
        
        function StartFcn(this,evt,hTask,varargin)
            hTask.hEffector{1}.unlockState;
            hTask.hFramework.hPredictor.hDecoder.enableDecoder;
        end % END function StartFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTarget = hTask.hTarget;
            hEffector = hTask.hEffector{1};
            user = hTask.params.user;
            hitInfo = hTask.hitInfo;
            
            % check for current contact
            if ~isempty(hitInfo)
                hTask.applyObjectProfile(hTarget{hitInfo.targetID},user.target_profile.contact);
            end
            
            % set profiles for all targets
            for kk=1:length(hTarget)
                hTask.applyObjectProfile(hTarget{kk},user.target_profile.default);
            end
            
            % set profile for effector
            hTask.applyObjectProfile(hEffector,user.effector_profile.active);
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % check for contact between effector and any of the targets
            if this.PhaseOrder==1
                currTargetID = hTask.cTrialParams.targetID;
            else
                currTargetID = length(hTask.hTarget);
            end
            [hit,info] = testContact(hTask.hEffector{1},hTask.hTarget(currTargetID));
            if hit
                
                % check for rapid-fire hits
                if ~isempty(hTask.hitInfo) && (hTask.hitInfo.targetID~=info.targetID || hTask.hitInfo.effectorID~=info.effectorID)
                    
                    % process target exit
                    st1 = hTask.hEffector{hTask.hitInfo.effectorID}.toStruct;
                    st2 = hTask.hTarget{hTask.hitInfo.targetID}.toStruct;
                    if isempty(hTask.hTrial.TrialData.et_targetExit)
                        hTask.hTrial.TrialData.et_targetExit = {hTask.frameId,st1,st2,hTask.hTrial.phaseIdx};
                    else
                        hTask.hTrial.TrialData.et_targetExit(end+1,:) = {hTask.frameId,st1,st2,hTask.hTrial.phaseIdx};
                    end
                    
                    % remove old hit info
                    hTask.hitInfo = [];
                end
                
                % update trial data
                if isempty(hTask.hitInfo)
                    st1 = hTask.hEffector{info.effectorID}.toStruct;
                    st2 = hTask.hTarget{info.targetID}.toStruct;
                    if isempty(hTask.hTrial.TrialData.et_targetEnter)
                        hTask.hTrial.TrialData.et_targetEnter = {hTask.frameId,st1,st2,hTask.hTrial.phaseIdx};
                    else
                        hTask.hTrial.TrialData.et_targetEnter(end+1,:) = {hTask.frameId,st1,st2,hTask.hTrial.phaseIdx};
                    end
                    
                    % stop the trial timer
                    stopTimer(hTask.hTrial,1);
                    
                    % start the hit timer
                    startTimer(hTask.hEffector{1},hTask.hTarget{info.targetID}.durationHold);
                    
                    % store the hit information
                    hTask.hitInfo = info;
                end
            else
                
                % no hit: check whether there was a hit previously
                if ~isempty(hTask.hitInfo)
                    st1 = hTask.hEffector{hTask.hitInfo.effectorID}.toStruct;
                    st2 = hTask.hTarget{hTask.hitInfo.targetID}.toStruct;
                    if isempty(hTask.hTrial.TrialData.et_targetExit)
                        hTask.hTrial.TrialData.et_targetExit = {hTask.frameId,st1,st2,hTask.hTrial.phaseIdx};
                    else
                        hTask.hTrial.TrialData.et_targetExit(end+1,:) = {hTask.frameId,st1,st2,hTask.hTrial.phaseIdx};
                    end
                    
                    % stop the hit timer
                    stopTimer(hTask.hEffector{1});
                    
                    % re-start the trial timer
                    startTimer(hTask.hTrial,1);
                    
                    % remove the hit information
                    hTask.hitInfo = [];
                end
            end
            
            % check for a registered hit (contact for required duration)
            if hTask.hitRegistered
                hTask.hitRegistered = false;
                hTask.stats.score = hTask.stats.score + 1;
                hTask.hTrial.TrialData.ex_success = true;
                hTask.hTrial.advance;
            end
        end % END function PostDrawFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hTrial.advance;
        end % END function TimeoutFcn
        
        function EndFcn(this,evt,hTask,varargin)
            hTask.hFramework.hPredictor.hDecoder.disableDecoder;
            hTask.hEffector{1}.lockState;
        end % END function EndFcn
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef PhaseMoveCursor