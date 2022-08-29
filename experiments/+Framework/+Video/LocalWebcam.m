classdef LocalWebcam < handle & Framework.Video.Interface & Framework.Component & util.Structable & util.StructableHierarchy
    % LOCALWEBCAM Framework wrapper for the webcam server
    %
    %   See also Video.Webcam.Server.
    
    properties
        hVideo % handle to the webcam server object
    end % END properties
    
    methods
        function this = LocalWebcam(fw,cfg)
            % LOCALWEBCAM Constructor for the LocalWebcam object
            %
            %   LOCALWEBCAM(FW,CFG)
            %   Create the LocalWebcam object with the handle to the
            %   framework FW and the config function handle CFG.
            
            % initialize the superclass
            this = this@Framework.Video.Interface(fw);
            
            % create the webcam client object
            this.hVideo = Video.Webcam.Server;
            
            % configure
            if ~iscell(cfg),cfg={cfg};end
            feval(cfg{1},this,cfg{2:end});
        end % END function LocalWebcam
        
        function initialize(this)
            % INITIALIZE Initialize the LocalWebcam object
            %
            %   INITIALIZE(THIS)
            %   Initialize the LocalWebcam object.  Initializes the webcam
            %   client object, and enables neural data recording if the
            %   Framework's neural data object is set to Blackrock.
            
            % initialize the video object
            this.hVideo.initialize;
            
            % enable or disable neural data recording
            if isa(this.hFramework.hNeuralSource,'Framework.NeuralSource.Blackrock')
                command(this.hVideo,Video.Webcam.Command.ENABLE_CBMEX);
            else
                command(this.hVideo,Video.Webcam.Command.DISABLE_CBMEX);
            end
        end % END function initialize
        
        function stop(this)
            % STOP Stop recording
            %
            %   STOP(THIS)
            %   Stop recording audio and video from the webcam object.
            
            % stop recording
            this.hVideo.stop;
        end % END function stop
        
        function record(this)
            % RECORD Start recording
            %
            %   RECORD(THIS)
            %   Start recording audio and video from the webcam object.
            
            % start recording
            this.hVideo.record(this.hFramework.runtime.baseFilename);
        end % END function record
        
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
end % END classdef Interface