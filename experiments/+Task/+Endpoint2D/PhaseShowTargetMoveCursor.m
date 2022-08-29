classdef PhaseShowTargetMoveCursor < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = PhaseShowTargetMoveCursor(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function PhaseShowTargetMoveCursor
        
        function StartFcn(this,evt,hTask,varargin)
            
            % set state mode (pro or anti)
            for kk=1:length(hTask.hTarget)
                hTask.hTarget{kk}.setMode(hTask.cTrialParams.stateMode);
            end
            hTask.hEffector{1}.setMode(hTask.cTrialParams.stateMode);
            
            % raise sync pulse on even target IDs
            if hTask.params.useSync && mod(hTask.cTrialParams.targetID,2)==0
                tag = sprintf('tr%03dph%02d',hTask.cTrial,hTask.hTrial.phaseIdx);
                sync(hTask.hFramework,@high,'tag',tag);
                comment(hTask,'Sending sync high',3);
            end
        end % END function StartFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useSync && mod(hTask.cTrialParams.targetID,2)==0
                sync(hTask.hFramework,@low);
            end
        end % END function EndFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
        end % END function PhaseFcn
        
        function PreDrawFcn(this,evt,hTask,varargin)
            hTarget = hTask.hTarget;
            hEffector = hTask.hEffector{1};
            user = hTask.params.user;
            hitInfo = hTask.hitInfo;
            cTrialParams = hTask.cTrialParams;
            targets_unique = nan(1,2);
            
            % check for current contact
            if ~isempty(hitInfo)
                hTask.applyObjectProfile(hTarget{hitInfo.targetID},user.target_profile.contact);
                targets_unique(1) = hitInfo.targetID;
            end
            
            % set profile for active target
            if isempty(hitInfo) || hTask.cTrialParams.targetID ~= hitInfo.targetID
                hTask.applyObjectProfile(hTarget{cTrialParams.targetID},user.target_profile.active);
                targets_unique(2) = hTask.cTrialParams.targetID;
            end
            
            % set profiles for rest of targets
            targets_unique = unique(targets_unique);
            targets_unique = targets_unique(~isnan(targets_unique));
            for kk=setdiff(1:length(hTarget),targets_unique)
                hTask.applyObjectProfile(hTarget{kk},user.target_profile.default);
            end
            
            % set profile for effector
            hTask.applyObjectProfile(hEffector,user.effector_profile.active);
        end % END function PreDrawFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            
            % check for contact between effector and any of the targets
            [hit,info] = testContact(hTask.hEffector{1},hTask.hTarget(hTask.cTrialParams.targetID));
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
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Experiment2.PhaseInterface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.PhaseInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef PhaseShowTargetMoveCursor