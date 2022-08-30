classdef SummaryReward < handle & Experiment2.PhaseInterface & util.Structable & util.StructableHierarchy
    
    properties
        id
        Name
        durationTimeout
    end
    
    methods
        function this = SummaryReward(varargin)
            this = this@Experiment2.PhaseInterface(varargin{:});
        end % END function SummaryReward
        
        function StartFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.expectInput({'next','RightArrow'});
            end
        end % END function StartFcn
        
        function PostDrawFcn(this,evt,hTask,varargin)
            numUnknown = nnz(isnan([hTask.TrialData(1:hTask.nTrials).ex_success]));
            numKnown = hTask.nTrials - numUnknown;
            numCorrect = nnz([hTask.TrialData(1:hTask.nTrials).ex_success]==true);
            if numKnown==0
                hTask.hSummary.finish;
            end
            if hTask.params.useDisplay && ~any(strcmpi(hTask.hDisplayClient.ImageNames,'reward'))
                if numCorrect/numKnown > 0.96
                    list1 = getFiles('Rewards','landscape');
                    list2 = getFiles('Rewards','scifi');
                    list3 = getFiles('Rewards','cute');
                    list4 = getFiles('Rewards','wildlife');
                    list = [list1 list2 list3 list4];
                elseif numCorrect/numKnown > 0.9
                    list1 = getFiles('Penalty','cute');
                    list2 = getFiles('Penalty','disappointment');
                    list = [list1 list2];
                else
                    list = getFiles('Penalty','scary');
                end
                if isempty(list)
                    hTask.hSummary.finish;
                    return;
                end
                idx = randi(length(list),1);
                hTask.hDisplayClient.loadImage(list{idx},'reward');
            end
            hTask.hDisplayClient.drawImage('reward');
            
            function list = getFiles(dir1,dir2)
                list = {};
                subdir = fullfile(dir1,dir2);
                info = dir(fullfile(env.get('media'),'img',subdir));
                if isempty(info),return;end
                info(1:2) = []; % get rid of '.' and '..'
                info(strcmpi({info.name},'Thumbs.db')) = []; % get rid of Thumbs.db
                list = cellfun(@(x)fullfile(dir1,dir2,x),{info.name},'UniformOutput',false);
            end % END function getFiles
        end % END function PostDrawFcn
        
        function PhaseFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                next = hTask.hKeyboard.check('next');
                if ~isempty(next)
                    hTask.hSummary.finish;
                end
            else
                hTask.hSummary.finish;
            end
        end % END function PhaseFcn
        
        function EndFcn(this,evt,hTask,varargin)
            if hTask.params.useKeyboard
                hTask.resetInput('next');
            end
        end % END function EndFcn
        
        function TimeoutFcn(this,evt,hTask,varargin)
            hTask.hSummary.finish;
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
end % END classdef SummaryReward