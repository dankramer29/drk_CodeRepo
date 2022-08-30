classdef Pupil < handle & Framework.EyeTracker.Interface & util.Structable & util.StructableHierarchy
    
    properties
        hPupil % handle to Pupil Interface
    end % END properties
    
    properties(SetAccess='private')
        isCalibrating
        isRecording
        isOpen
    end % END properties(SetAccess='private')
    
    properties(Constant)
        isSimulated = false;
    end % END properties(Constant)
    
    methods
        function val = get.isRecording(this)
            val = this.hPupil.isRecording;
        end
        function val = get.isCalibrating(this)
            val = this.hPupil.isCalibrating;
        end
        function val = get.isOpen(this)
            val = this.hPupil.isOpen;
        end
        
        function this = Pupil(fw,cfg,varargin)
            this = this@Framework.EyeTracker.Interface(fw);
            
            % construct the pupil interface
            this.hPupil = Pupil.Interface(varargin{:});
            
            % configure
            feval(cfg{1},this,cfg{2:end});
        end % END function Pupil
        
        function initialize(this)
            this.hPupil.initialize;
        end % END function initialize
        
        function startRecording(this,varargin)
            if this.isRecording
                this.hPupil.stopRecord;
                pause(0.5);
            end
            this.hPupil.startRecord(varargin{:});
            comment(this,'Started recording eye tracking data');
        end % END function startRecording
        
        function stopRecording(this)
            this.hPupil.stopRecord;
        end % END function stopRecording
        
        function t = getTime(this)
            t = this.hPupil.time;
        end % END function getTime
        
        function setTime(this,varargin)
            t = 0;
            if nargin>1,t=varargin{1};end
            this.hPupil.setTime(t);
        end % END function setTime
        
        function [timestamp,gazexy,conf] = read(this)
            [timestamp,gazexy,conf] = update(this.hPupil);
        end % END function read
        
        function startCalibrating(this,varargin)
            this.hPupil.startCalibration;
        end % END function startCalibrating
        
        function stopCalibrating(this,varargin)
            this.hPupil.stopCalibration;
        end % END function stopCalibration
        
        function close(this)
            closeall(this.hPupil);
            delete(this.hPupil);
        end % END function close
        
        function skip = structableSkipFields(this)
            skip = {};
            skip1 = structableSkipFields@Framework.EyeTracker.Interface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.EyeTracker.Interface(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
    
    methods(Static)
        function cleanup
            Pupil.Interface.cleanup;
        end % END function cleanup
    end % END methods(Static)
end % END classdef Pupil