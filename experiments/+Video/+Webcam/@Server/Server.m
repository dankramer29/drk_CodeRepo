% commented line 157, may need to comment either 146 or 147

classdef Server < handle & Video.Interface & util.Structable & util.StructableHierarchy
    % SERVER Local or network interface for access to local USB webcam
    %
    %   The Server object provides access to a local webcam either through
    %   local methods directly, or via commands received over UDP.  The
    %   Server supports both audio and video streams, and can read
    %   timestamps from a neural data interface to synchronize A/V 
    %   recordings with neural data recordings.
    %
    %   To use locally, simply instantiate the object and operate on it
    %   directly.
    %
    %     Example:
%         av = Video.Webcam.Server;which 
%         record(av,'myFile');
%         ...
%         stop(av);
%         delete(av);
    %
    %   To use remotely, instantiate Server on the local machine (with the
    %   webcam), and instantiate Client on the remote machine.  Verify that
    %   the IP addresses and ports agree with each other on both objects.
    %   Execute all operations on the client.
    %
    %     Example:
    %     % On local (webcam) PC
    %     av = Video.Webcam.Server;
    %     % On remote PC
    %     av = Video.Webcam.Client;
    %     record(av,'myFile');
    %     ...
    %     stop(av);
    %     delete(av);
    %
    %   Setting up the audio and video sampling rates such that the two
    %   media streams record in synchrony without overruns or underruns can
    %   be tricky.  Here is how the audio device buffering works, from the
    %   MATLAB documentation for the simulink "From Audio Device" block:
    %
    %     1. At the start of the simulation, the audio device begins 
    %     writing the input data to a buffer. This data has the data type 
    %     specified by the Device data type parameter.
    %
    %     2. When the buffer is full, the From Audio Device block writes 
    %     the contents of the buffer to the queue. Specify the size of this
    %     queue using the Queue duration (seconds) parameter.
    %
    %     3. As the audio device appends audio data to the bottom of the 
    %     queue, the From Audio Device block pulls data from the top of the
    %     queue to fill the Simulink frame. This data has the data type 
    %     specified by the Output data type parameter.
    %
    %   The GUI reports the instantaneous and average queue overrun
    %   samples.  Again, from the "From Audio Device" documentation:
    %
    %     When the simulation throughput rate is lower than the hardware 
    %     throughput rate, the queue, which is initially empty, fills up. 
    %     If the queue is full, the block drops the incoming data from the
    %     audio device. You can monitor dropped samples using the optional
    %     Overrun output port.
    %
    %   If left to default values, this class will use a very small audio
    %   device buffer to make frequent updates to the queue, a moderately
    %   sized queue to provide some cushion while balancing latency, and
    %   audio frame size matched to the requested video frame rate.  Video
    %   format and frame rate are balanced for decent resolution and stable
    %   performance.
    %
    %   Specifically, the audio sampling rate will be set to 11.025 KHz, 
    %   video frame rate set to 15 frames per second, or about 66.7 msec 
    %   frame duration, and an audio frame set to 11025/15 = 735 samples.
    %   The audio buffer will be set to 128 samples (11.6 msec @ 
    %   11025 KHz).  The audio queue duration will be 0.2 seconds (2205 
    %   samples of audio @ 11025 KHz, or about 3 frames of video at 15
    %   fps).  The audio data type will be 8-bit.  Video resolution will be
    %   1280x720.
    %
    %   These values are sensitive to the underlying hardware and drivers.
    %   Optimization may require different values for different systems.
    %   Performance was evaluated in Windows 8.1 Professional 64-bit using
    %   Windows Direct Sound driver interface to Logitech HD Webcam C510 on
    %   a Intel Core i5-4670 (3.4 GHz) with 16 GB RAM and a 250 GB Samsung
    %   840 series SSD.
    
% Modified by Rinu 
    
    %   Specifically, the audio sampling rate will be set to 11.025 KHz, 
    %   video frame rate set to 15 frames per second, or about 66.7 msec 
    %   frame duration, and an audio frame set to 11025/15 = 735 samples.
    %   The audio buffer will be set to 128 samples (11.6 msec @ 
    %   11025 KHz).  The audio queue duration will be 0.2 seconds (2205 
    %   samples of audio @ 11025 KHz, or about 3 frames of video at 15
    %   fps).  The audio data type will be 8-bit.  Video resolution will be
    %   1280x720.
    %
    
    
    
    
    
    %   These values are sensitive to the underlying hardware and drivers.
    %   Optimization may require different values for different systems.
    %   Performance was evaluated in Windows 10 Enterprise 64-bit using
    %   Windows Direct Sound driver interface to Logitech HD Webcam C920 on
    %   a Intel Core i7-6700 (3.4 GHz) with 16 GB RAM and a 500 GB Samsung
    %   840 series SSD.
    

    
    %
    %   Finally, note that all text fields in the GUI will allow an enter 
    %   keypress to update the value intead of manually clicking the apply
    %   button (but that works too; the apply buttons will become active 
    %   once focus moves away from the edit field).
    %
    %   Also note that clicking the "x" icon to close the GUI window is now
    %   supported and will cleanly close the GUI and release all resources.
    %
    %   See also VIDEO.WEBCAM.CLIENT, VIDEOINPUT, DSP.AUDIORECORDER, 
    %   VISION.VIDEOFILEWRITER, BLACKROCK.INTERFACE, VIDEO.INTERFACE,
    %   util.STRUCTABLE, util.STRUCTABLEHIERARCHY, TIMER, UDP.
    
    properties(SetAccess=private,GetAccess=public) % SetAccess: access from class members only
        hVideoInput % handle to object returned by videoinput
        hVideoFileWriter % handle to object returned by vision.VideoFileWriter
        hAudioRecorder % handle to object returned by dsp.AudioRecorder
        hTimerAV % handle to timer used to trigger a/v frame capture
        hTimerUDP % handle to timer used to send status updates over UDP
        hUDPRcv % handle to UDP object used to receive commands
        hUDPSnd % handle to UDP object used to send status updates
        hCBMEX % handle to CBMEX neural data object (to get timestamps only, no recording)
        hGUI % handle to figure
        guiHandles % handles to GUI elements
        buffers % collection of buffers used to store capture information
        timestamp % matlab tic to mark computer time when recording starts
        computerStartTime % timestamp marking time when recording starts
        errorCountVideo % number of errors which have occurred with video capture
        errorCountAudio % number of errors which have occurred with audio capture
        errorCountVideoFR % number of frames outside the specified framerate
        diaryStatus = false; % whether the diary file is open or not
        isRecording = false; % status of the recording
        stopRequested = false; % flag to request a stop synchronously with the timer execution
        deleteRequested = false; % flag to request a delete from the GUI CloseRequestFcn
%         queueOverrun = true; % whether to track queue overrun
        queueOverrunInst = 0; % current queue overrun
        queueOverrunAvg = 0; % average queue overrun
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties
        ii=[]
        hDebug % debug object
        savePath = 'C:\Share'; % directory where a/v files will be saved
        idString % string used in filename to identify group of files
        fileIdx = 0; % incremental counter to create unique filenames
        singleFileSamples = 2e3; % start a new a/v file after this many frames
        ignoreExitCommand = true; % whether to adhere to incoming EXIT commands
        
        guiName = 'WebcamServerGUI'; % name of the GUI
        ipAddress = '127.0.0.1'; % ip address of the client machine
        sndRemotePort = 10025; % client machine's receive port
        sndLocalPort = 10024; % local machine's send port
        rcvRemotePort = 10023; % client machine's send port
        rcvLocalPort = 10022; % local machine's receive port
        
        audioSampleRate = 11025; % sample rate for audio recording
        audioBufferSize = 512; % if empty, automatically set the buffer size; otherwise manually set the buffer size
        audioQueueDuration = 0.3; % size of the audio queue in seconds
        audioNumChannels = 1; % number of channels used for audio recording
        audioOutputDataType = 'unit8'; % output data type of audio recording
%         audioDeviceName = 'Primary Sound Capture Driver'; % name of the audio device to use for recording sound
       audioDeviceDriverName = 'DirectSound';
       audioDeviceName = 'Microphone (HD Pro Webcam C920)'; % for Logitech C920
       audioDeviceDataType = '8-bit integer'; % data type of audio device
        
        videoFrameRate = 24; % frames-per-second for video recording
        videoFocusMode = 'manual'; % focus mode of the video device
        videoFocusValue = 0; % focus value of the video device (for manual focus)
        videoExposureMode = 'auto'; % exposure mode of the video device
        videoExposureValue = -1; % exposure value of the video device (for manual exposure)
        videoWhiteBalanceMode = 'auto'; % white balance mode of the video device
        videoWhiteBalanceValue = 5000; % white balance value of the video device (for manual white balance)
        videoAdaptorName = 'winvideo'; % name of the video adaptor
        videoDeviceID = 1; % id of a device available through the video adaptor
%         videoFormat = 'RGB24_1280x720'; % video format string %% commented 
        videoFormat = 'MJPG_1280x720'; % video format string
        videoLiveUpdate = true; % whether to update the GUI with video frame captures while recording
        
        fileBasename % basename of the recorded file
        fileFormat = 'AVI'; % format of the output file
        fileExtension = '.avi'; % file-extension of the output file
        fileAudioCompressor = 'None (uncompressed)'; % compression scheme used for audio (see VideoFileWriter)
        fileVideoCompressor = 'DV Video Encoder'; % compression scheme used for video (see VideoFileWriter)
        fileColorSpace = 'RGB'; % colorspace of the output video file
        
        cbmexArrayStrings = {'NSP1'}; % labels applied to files recorded from connected NSP (for future file recording support)
        cbmexOpenArgs = {{'central-addr','127.0.0.1'}}; % arguments supplied to Blackrock Interface for opening CBMEX
        cbmexInterface = 2; % interface type to open for CBMEX (0 - Default, 1 - Central, 2 - UDP)
        
        errorThresholdVideo = 5; % threshold on video error count before restarting recording
        errorThresholdAudio = 10; % threshold on audio error count before restarting recording
        errorThresholdVideoFR = 25; % threshold on framerate error count before restarting recording
        
        enableUDP = true; % enable or disable the UDP objects
        enableDiary = true; % enable or disable the diary file
        enableAudio = true; % enable or disable audio recording
        enableCBMEX = true; % enable or disable neural data synchronization
    end % END properties
    
    methods
        function this = Server(varargin)
            % SERVER Create Server object for recording webcam audio/video
            %
            %   AV = SERVER
            %   Creates a timer object with callback functions for
            %   capturing audio and video at constant framerate.
            %
            %   SERVER(...,PROP,VAL)
            %   Override default value of PROP with VAL.  PROP can be any
            %   property of the Server object.
            
            % environment-specific options
            [this.hDebug,varargin,found_dbg] = util.argisa('Debug.Debugger',varargin,nan);
            if ~found_dbg,this.hDebug=Debug.Debugger('video_webcam','screen');end
            
            type = env.get('type');
            subject = env.get('subject');
            switch type
                case 'DEVELOPMENT'
                    this.hDebug.log('Development environment detected','info');
                    this.hDebug.log('Disabling CBMEX','debug');
                    this.enableCBMEX = true;
                    %       this.enableCBMEX = false --remember it!!!;
                case 'PRODUCTION'
                    this.hDebug.log('Production environment detected','info');
                    this.hDebug.log('Enabling CBMEX','debug');
                    assert(~isempty(subject),'Must set the SUBJECT environment variable');
                    this.enableCBMEX = true;
                otherwise
                    error('Invalid environment type "%s"',type);
            end
            if isempty(subject)
                this.hDebug.log('No subject ID provided','info');
            else
                this.guiName = sprintf('%s - Subject %s',this.guiName,subject);
                this.hDebug.log(sprintf('Subject set to "%s"',subject),'info');
            end
            
            % set the default ID string
            this.idString = datestr(now,'yyyymmdd-HHMMSS');
            
            % user inputs override defaults
            [~,varargin] = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % initialize status to OFF
            this.setStatus(Video.Status.OFF);
            
            % create buffer collection
            this.buffers = Buffer.DynamicCollection;
            register(this.buffers,'videoTime','r');
            register(this.buffers,'cbmexTime','r');
            register(this.buffers,'computerTime','r');
            register(this.buffers,'videoFrameDelay','r');
            register(this.buffers,'timerPeriod','r');
            register(this.buffers,'audioQueueOverrun','r');
            register(this.buffers,'numFramesProcessed','r');
            register(this.buffers,'frameTicToc','r');
            if this.enableAudio, register(this.buffers,'audioFrameDelay','r'); end
            
            % construct final save path and make sure it exists
            this.savePath = fullfile(this.savePath,upper(subject),datestr(now,'yyyymmdd'),'Video');
            if exist(this.savePath,'dir')~=7, mkdir(this.savePath); end
            
            % create file basename
            this.fileBasename = sprintf('%s-%03d',this.idString,this.fileIdx);
            
            % construct timer for audio/video frame capture
            try
                initializeTimerAV(this);
                if this.enableUDP
                    initializeTimerUDP(this);
                    initializeUDP(this);
                end
                setNeuralSync(this,this.enableCBMEX);
            catch ME
                util.errorMessage(ME);
                delete(this);
                return;
            end
            
            % create GUI
            try
                gui(this);
            catch ME
                util.errorMessage(ME);
                delete(this);
                return;
            end
            if this.enableAudio
                set(this.guiHandles.editAudioSampleRate,'String',num2str(this.audioSampleRate))
            else
                set(this.guiHandles.editAudioSampleRate,'String','[Audio Disabled]')
                set(this.guiHandles.editAudioSampleRate,'Enable','off')
            end
            set(this.guiHandles.editVideoFrameRate,'String',num2str(this.videoFrameRate));
            set(this.guiHandles.editFile,'String',sprintf('%s%s',this.fileBasename,this.fileExtension));
            set(this.guiHandles.toggleRecord,'enable','on');
        end % END function Server
        
        function setNeuralSync(this,state)
            % SETNEURALSYNC Enable or disable neural data synchronization
            %
            %   SETNEURALSYNC(THIS,STATE)
            %   Enable (STATE=TRUE) or disable (STATE=FALSE) neural data
            %   synchronization.
            
            % enable or disable neural synchronization
            if state
                
                % disable first to ensure clean start
                setNeuralSync(this,false);
                
                % initialize CBMEX
                initializeCBMEX(this);
            else
                
                % if the object has been initialized, clean it up
                if isa(this.hCBMEX,'Blackrock.Interface')
                    close(this.hCBMEX);
                    delete(this.hCBMEX);
                end
                this.hCBMEX = [];
            end
        end % END function setNeuralSync
        
        function setIDString(this,str)
            % SETIDSTRING Set the ID string of recorded files
            %
            %   SETIDSTRING(THIS,STR)
            %   Set the ID string of recorded files to the string in STR.
            
            % make sure it's a string a set it
            assert(ischar(str),'ID string must be char');
            this.idString = str;
        end % END function setIDString
        
        function setSubject(this,str)
            % SETSUBJECT Set the subject HST environment variable
            %
            %   SETIDSTRING(THIS,STR)
            %   Set the HST env var SUBJECT to the string in STR.
            
            % make sure it's a string a set it
            assert(ischar(str),'Subject must be char');
            env.set('subject',str);
        end % END function setIDString
        
        function initialize(~)
            % INITIALIZE Initialize the Server object
            %
            %   INITIALIZE(THIS)
            %   This function serves no purpose in the Server class.
            
        end % END function initialize
        
        function record(this,varargin)
            % RECORD Start recording
            %
            %   RECORD(THIS)
            %   Start recording audio and video to a file
            %
            %   RECORD(THIS,IDSTRING)
            %   Customize the basename of the generated files.
            
            % verify status
            if this.isRecording, return; end
            this.isRecording = true;
            
            % will overwrite previous value if provided
            if ~isempty(varargin), setIDString(this,varargin{1}); end
            
            % start the diary if not already started
            if this.enableDiary && ~this.diaryStatus
                diaryFile = fullfile(this.savePath,[this.idString '_diary.txt']);
                diary(diaryFile);
                this.diaryStatus = true;
            end
            
            % initialize error counts to 0
            this.errorCountVideo = 0;
            this.errorCountAudio = 0;
            this.errorCountVideoFR = 0;
            this.queueOverrunInst = 0;
            this.queueOverrunAvg = 0;
            
            % create file basename
            this.fileBasename = [this.idString '-' sprintf('%03d',this.fileIdx)];
            
            % stop if anything wrong
            try
                
                % update GUI width for width of frame grab
                dims = regexp(this.videoFormat,'(\d+)x(\d+)','tokens');
                aspectRatio = 1.5;
                if ~isempty(dims) && iscell(dims) && length(dims{1})==2
                    frw = str2double(dims{1}{1});
                    frh = str2double(dims{1}{2});
                    aspectRatio = frw/frh;
                end
                axpos = get(this.guiHandles.axisPicture,'position');
                axpos(3) = aspectRatio*axpos(4);
                set(this.guiHandles.axisPicture,'position',axpos);
                figpos = get(this.guiHandles.fh,'position');
                figpos(3) = axpos(1) + axpos(3) + 15;
                set(this.guiHandles.fh,'position',figpos);
                
                % initialize devices
                initializeVideo(this);
                if this.enableAudio, initializeAudio(this); end
                initializeFileWriter(this);
                
                % update the GUI frame grab each time a new file starts
                vframe = getsnapshot(this.hVideoInput);
                this.plotImage(this.guiHandles.axisPicture,vframe)
                axis(this.guiHandles.axisPicture,'tight','equal');
                
                % mark computer time when timer started
                this.computerStartTime = now;
                this.timestamp = tic;
                
                % start the framerate timer
                startTimerAV(this);
            catch ME
                util.errorMessage(ME);
                stop(this);
            end
            
            % update current filename
            set(this.guiHandles.editFile,'String',sprintf('%s%s',this.fileBasename,this.fileExtension));
            
            % disable fields for changing adaptor, device, or format
            set(this.guiHandles.popupVideoAdaptor,'enable','off');
            set(this.guiHandles.popupVideoDeviceID,'enable','off');
            set(this.guiHandles.popupVideoFormat,'enable','off');
            set(this.guiHandles.editVideoFrameRate,'enable','off');
            set(this.guiHandles.editAudioSampleRate,'enable','off');
            set(this.guiHandles.popupAudioDevice,'enable','off');
            
            % update the status
            this.setStatus(Video.Status.RECORDING);
            
        end % END function record
        
        function stop(this)
            % STOP Stop recording
            %
            %   STOP(THIS)
            %   Stop recording audio and video
            
            if ~this.isRecording, return; end
            this.isRecording = false;
            
            % individual catch statements so nothing blocks
            try stopTimerAV(this);      catch ME, util.errorMessage(ME); end
            try cleanupFileWriter(this);catch ME, util.errorMessage(ME); end
            try cleanupAudio(this);     catch ME, util.errorMessage(ME); end
            try cleanupVideo(this);     catch ME, util.errorMessage(ME); end
            try save(this);             catch ME, util.errorMessage(ME); end
            
            % update the status
            this.setStatus(Video.Status.OFF);
            
            % increment file index
            this.fileIdx = this.fileIdx + 1;
            
            % enable fields for changing adaptor, device, or format
            set(this.guiHandles.popupVideoAdaptor,'enable','on');
            set(this.guiHandles.popupVideoDeviceID,'enable','on');
            set(this.guiHandles.popupVideoFormat,'enable','on');
            set(this.guiHandles.editVideoFrameRate,'enable','on');
            set(this.guiHandles.editAudioSampleRate,'enable','on');
            set(this.guiHandles.popupAudioDevice,'enable','on');
            
        end % END function stop
        
        function restart(this)
            % RESTART restart video recording to a new file
            %
            %   RESTART(THIS)
            %   Stop recording the current file and start recording audio
            %   and video to a new file.
            
            stop(this);
            pause(0.1);
            record(this);
        end % END function restart
        
        function save(this)
            % SAVE Save all collected information to disk
            %
            %   SAVE(THIS)
            %   Save the timing information, object properties, and
            %   buffered data into a MAT file.
            
            % if empty buffers, nothing to save
            if isempty(this.buffers,'timerPeriod'), return; end
            
            % get object properties in a struct
            Object.Properties = toStruct(this);
            
            % grab data out of the buffers
            [d,names] = all(this.buffers);
            for kk=1:length(names)
                Object.Data.(names{kk}) = d{kk};
            end
            Object.Data.computerStartTime = this.computerStartTime;
            
            % save to file
            timingFile = fullfile(this.savePath,[this.idString '-' sprintf('%03d',this.fileIdx) '.mat']);
            try
                save(timingFile,'-struct','Object');
            catch ME
                util.errorMessage(ME);
                fprintf('\n');
                fprintf('*********************************************************************\n');
                fprintf('* Could not write results.  Save manually, then hit F5 to continue. *\n');
                fprintf('*********************************************************************\n');
                fprintf('\n');
                keyboard
            end
            
            % update user
            this.hDebug.log(sprintf('Saved output to "%s"',fullfile(this.savePath,[this.idString '-' sprintf('%03d',this.fileIdx) '.mat'])),'critical');
            
            % clear buffers to prevent saving again
            reset(this.buffers);
        end % END function save
        
        function delete(this)
            % DELETE Delete the Server object
            %
            %   DELETE(THIS)
            %   Delete the Server object including all of its timers, UDP
            %   objects, and neural data interfaces.
            
            % no longer initialized
            if this.isRecording, stop(this); end
            if this.enableDiary, diary off; end
            
            % delete timer object
            try util.deleteTimer(this.hTimerAV); catch ME, util.errorMessage(ME); end
            try util.deleteTimer(this.hTimerUDP); catch ME, util.errorMessage(ME); end
            
            % delete udp objects
            if this.enableUDP
                try util.deleteUDP(this.hUDPSnd); catch ME, util.errorMessage(ME); end
                try util.deleteUDP(this.hUDPRcv); catch ME, util.errorMessage(ME); end
            end
            
            % close CBMEX
            try setNeuralSync(this,false); catch ME, util.errorMessage(ME); end
            
            % close the GUI
            try if ~isempty(this.hGUI), delete(this.hGUI); end
            catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function updateGUI(this,vframe)
            % UPDATEGUI Update information in the GUI
            %
            %   UPDATEGUI(THIS,VFRAME)
            %   Update the GUI with the video frame information
            
            if ~isempty(this.hGUI) && ishandle(this.hGUI)
                
                % number of frames processed so far
                numFrames = this.hTimerAV.TasksExecuted;
                instFps = 1/this.hTimerAV.InstantPeriod;
                set(this.guiHandles.editStatus,'String',sprintf('%4d frames @ %2.2ffps ',numFrames,instFps));
                
                % queue overrun
                set(this.guiHandles.editQueueOverrun,'String',sprintf('%4.0f (inst) %4.0f (avg)',this.queueOverrunInst,this.queueOverrunAvg));
                
                % update live video frame grab
                if this.videoLiveUpdate && nargin>1, this.plotImage(this.guiHandles.axisPicture,vframe); end
            else
                
                % re-open the GUI
                gui(this);
            end
        end % END function updateGUI
        
        function plotImage(~,ax,vframe)
            % PLOTIMAGE Plot an image to the GUI
            %
            %   PLOTIMAGE(THIS,AX,VFRAME)
            %   Plot the image in VFRAME into the axes in AX.
            
            hold(ax,'on'); % without this, axis gets replaced and tag disappears so handle missing from guihandles output
            cla(ax);
            image(flip(vframe,1),'Parent',ax);
            hold(ax,'off');
        end % END function plotImage
        
        function skip = structableSkipFields(this)
            skip1 = {'hVideoInput','hVideoFileWriter','hAudioRecorder','hTimerAV','hTimerUDP','hUDPSnd','hUDPRcv','hGUI','guiHandles','buffers','timestamp'};
            skip2 = structableSkipFields@Video.Interface(this);
            skip = [skip1 skip2];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Video.Interface(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
    
    methods(Access=private)
        function initializeTimerAV(this)
            
            % INITIALIZETIMERAV Initialize the A/V timer
            %
            %   INITIALIZETIMERAV(THIS)
            %   Create the a/v timer, which processes video frames and
            %   audio samples at a constant rate.
            
            this.hTimerAV = util.getTimer('WebcamServerAVTimer',...
                'Period',round((1/this.videoFrameRate)*1000)/1000,...
                'StartDelay',0.5,...
                'ExecutionMode','fixedDelay',...
                'BusyMode','queue',...
                'ErrorFcn',@avErrorFcn,...
                'TimerFcn',@avTimerFcn);
            
            function avErrorFcn(~,evt)
                if isfield(evt,'Data') && isfield(evt.Data,'messageID') && strcmpi(evt.Data.messageID,'MATLAB:timer:timerfcnoverlap')
                    warning('Timer function delay');
                else
                    warning('Unknown error: stopping');
                    stop(this)
                    delete(this)
                end
            end % END function avErrorFcn
            
            function avTimerFcn(t,~)
                % handle stop request
                if this.stopRequested
                    this.stopRequested = false;
                    this.stop;
                    if this.deleteRequested
                        this.deleteRequested = false;
                        delete(this);
                    end
                    return;
                end
                
                % track timing
                localTic = tic;
                
                % warn if lagging framerate
                if ~isnan(t.InstantPeriod) && t.InstantPeriod > 2*t.Period
                    this.hDebug.log(sprintf('Warning - video capture taking too long (instantaneous frame rate was %.1f and target is %.1f)',1/t.InstantPeriod,1/t.Period),'info');
                end
                
                % get computer, cbmex times
                cptime = round(toc(this.timestamp)*10000)/10000;
                if this.enableCBMEX, cbtime = this.hCBMEX.time; end
     
                 % read audio data
                writeArgs = {};
                if this.enableAudio
                    adelay = toc(localTic); % delay from timer cb entrance to recording audio frame
                    try
%                         if this.queueOverrun
                            [writeArgs{end+1},qOverrun] = this.hAudioRecorder();
                            this.queueOverrunInst = double(qOverrun);
                            this.queueOverrunAvg = 0.01*double(this.queueOverrunInst) + 0.99*double(this.queueOverrunAvg);
%                         else
%                             disp(writeArgs{1});
                           
%                             writeArgs{end+1} = step(this.hAudioRecorder);
%                             this.queueOverrunInst = nan;
%                             this.queueOverrunAvg = nan;
%                         end
                    catch ME
                        localErrorFcn(ME);
                        addCheckThreshold('errorCountAudio','errorThresholdAudio');
                    end
                end
%                 disp(writeArgs{1});
                 % read video data
                vdelay = toc(localTic); % delay from timer cb entrance to recording video frame
                try
                    vframe = getsnapshot(this.hVideoInput);
%                     BaseName2='Speaker_test_';
%                     FileName2=[BaseName2,num2str(ii),'.wav'];
%                     fileWriter = dsp.AudioFileWriter(FileName2,'FileFormat','WAV');
%                     fileWriter(writeArgs{1});
                    writeArgs = [vframe writeArgs];
%                     disp("arg{2}")
%                     disp(writeArgs{2});
                catch ME
                    localErrorFcn(ME);
                    addCheckThreshold('errorCountVideo','errorThresholdVideo');
                end
               
                 % write media to disk
                try this.hVideoFileWriter(writeArgs{:}); catch ME, localErrorFcn(ME); end
                
                % add timing information to buffers
                add(this.buffers,'audioQueueOverrun',this.queueOverrunInst);
                add(this.buffers,'videoFrameDelay',vdelay);
                add(this.buffers,'videoTime',round(this.hTimerAV.TasksExecuted/this.hVideoFileWriter.FrameRate*10000)/10000);
                add(this.buffers,'computerTime',cptime);
                add(this.buffers,'timerPeriod',this.hTimerAV.InstantPeriod);
                add(this.buffers,'numFramesProcessed',this.hTimerAV.TasksExecuted);
                if this.enableCBMEX, add(this.buffers,'cbmexTime',cbtime); end
                if this.enableAudio, add(this.buffers,'audioFrameDelay',adelay); end
                
                % write out the file every so often and start a new file
                if mod(this.hTimerAV.TasksExecuted,this.singleFileSamples)==0, this.restart; end
                
                % check framerate
                instantFrameRate = 1/this.hTimerAV.InstantPeriod;
                if 2*instantFrameRate < this.videoFrameRate, addCheckThreshold('errorCountVideoFR','errorThresholdVideoFR'); end
                
                % update GUI
                this.updateGUI(writeArgs{1});
                
                % force event handling
                drawnow;
                
                % record self time
                add(this.buffers,'frameTicToc',toc(localTic));
                
                % generate test audio file
                % this.ii=[this.ii;writeArgs{2}];
                % disp(this.ii);
                % fileWriter = dsp.AudioFileWriter(...
                %     'mySpeech.wav',...
                %     'FileFormat','WAV');
                % fileWriter(this.ii);
                
                function addCheckThreshold(count,thresh)
                    % ADDCHECKTHRESHOLD Update error counts
                    %
                    %   ADDCHECKTHRESHOLD(COUNT,THRESH)
                    %   Adds one to the error counter named COUNT, and
                    %   checks it agains the threshold named THRESH.  COUNT
                    %   and THRESH must be properties of the Server object.
                    %   If the error count exceeds the threshold, the
                    %   Server will be restarted.
                    
                    this.(count) = this.(count)+1;
                    if this.(count) > this.(thresh)
                        this.hDebug.log(sprintf('%s (%d) exceeded threshold (%d) -- restarting',count,this.(count),this.(thresh)),'info');
                        this.restart;
                    end
                end % END function checkThreshold

                function localErrorFcn(ME)
                    % LOCALERRORFCN Convenience function to process errors
                    %
                    %   LOCALERRORFCN(ME)
                    %   Prints the error contained in ME to the screen and
                    %   sets the Server status to ERROR.
                    
                    util.errorMessage(ME);
                    this.setStatus(Video.Status.ERROR);
                end % END function localErrorFcn
            end % END function avTimerFcn
 
        end % END function initializeTimerAV
   
        function startTimerAV(this)
            % STARTTIMERAV Start the A/V timer
            %
            %   STARTTIMERAV(THIS)
            %   Start the A/V timer.
            
            if isa(this.hTimerAV,'timer') && strcmpi(this.hTimerAV.Running,'off')
                start(this.hTimerAV);
            end
        end % END function startTimerAV
        
        function stopTimerAV(this)
            % STOPTIMERAV Stop the A/V timer
            %
            %   STOPTIMERAV(THIS)
            %   Stop the A/V timer.
            
            if isa(this.hTimerAV,'timer') && strcmpi(this.hTimerAV.Running,'on')
                stop(this.hTimerAV);
            end
        end % END function stopTimerAV
        
        function initializeTimerUDP(this)
            % INITIALIZETIMERUDP Initialize the UDP timer
            %
            %   INITIALIZETIMERUDP(THIS)
            %   Create the UDP timer, which processes status messages
            
            this.hTimerUDP = util.getTimer('WebcamServerUDPSndTimer',...
                'Period',0.05,...
                'StartDelay',0.5,...
                'ExecutionMode','fixedRate',...
                'BusyMode','drop',...
                'TimerFcn',@timerUDPFcn);
            start(this.hTimerUDP);
            
            function timerUDPFcn(~,~)
                % TIMERUDPFCN Timer function for the UDP timer
                %
                %   TIMERUDPFCN(T,EVT)
                %   Creates and sends a status update message over UDP.
                
                % Sometimes the video file writer changes the MATLAB 
                % directory, which means the repository code is no longer
                % on the path.  To avoid generating errors, just skip
                % sending status updates if the Video Webcam MessageType
                % class is not available (with a warning under debug mode).
                if exist('Video.Webcam.MessageType','class')~=8
                    st = dbstack;
                    FlagTempdir = false;
                    for kk=1:length(st)
                        if strcmpi(st(kk).file,'tempdir')
                            FlagTempdir = true;
                            break;
                        end
                    end
                    if FlagTempdir
                        this.hDebug.log('Path was changed in tempdir; this message is for information only','info');
                    else
                        this.hDebug.log('Video.Webcam.MessageType is unavailable.  If this warning continues to occur, make sure the path is correct and that Video.Webcam.MessageType exists.','warn');
                    end
                    return;
                end
                
                % construct and send the message
                data = [uint8(Video.Webcam.MessageType.STATUS) uint8(this.status)];
                fwrite(this.hUDPSnd,data,'uint8');
            end % END fucntion timerUDPFcn
        end % END function initializeTimerUDP
        
        function initializeUDP(this)
            % INITIALIZEUDP Initialize the UDP objects
            %
            %   INITIALIZEUDP(THIS)
            %   Create and open the send (status updates) and receive
            %   (commands) UDP objects.
            
            this.hUDPSnd = util.getUDP(this.ipAddress,this.sndRemotePort,this.sndLocalPort,...
                'Name','WebcamServerUDPSnd');
            this.hUDPRcv = util.getUDP(this.ipAddress,this.rcvRemotePort,this.rcvLocalPort,...
                'Name','WebcamServerUDPRcv',...
                'DatagramReceivedFcn',@processDatagram);
            
            function processDatagram(~,~)
                % PROCESSDATAGRAM Process received datagrams
                %
                %   PROCESSDATAGRAM(U,EVT)
                %   Process incoming command messages on the receive
                %   (command) UDP object.
                
                % as long as bytes available, keep processing
                while this.hUDPRcv.BytesAvailable>0
                    
                    % read data from the input buffer
                    data = fread(this.hUDPRcv,this.hUDPRcv.BytesAvailable,'uint8');
                    if mod(data,2)~=0
                        error('Incompatible received packet length ''%d''',length(data));
                    end
                    
                    % process data
                    type = data(1);
                    switch type
                        case Video.Webcam.MessageType.COMMAND
                            cmd = data(2);
                            payload = data(3:end);
                            switch cmd
                                case Video.Webcam.Command.INITIALIZE
                                    this.hDebug.log('Received INITIALIZE command','info');
                                    initialize(this);
                                case Video.Webcam.Command.RECORD
                                    this.hDebug.log('Received RECORD command','info');
                                    record(this);
                                case Video.Webcam.Command.STOP
                                    this.hDebug.log('Received STOP command','info');
                                    stop(this);
                                case Video.Webcam.Command.ENABLE_CBMEX
                                    this.enableCBMEX = true;
                                    this.hDebug.log('Received ENABLE_CBMEX command','info');
                                    setNeuralSync(this,true);
                                case Video.Webcam.Command.DISABLE_CBMEX
                                    this.enableCBMEX = false;
                                    setNeuralSync(this,false);
                                    this.hDebug.log('Received DISABLE_CBMEX command','info');
                                case Video.Webcam.Command.SET_ID_STRING
                                    str = char(payload);
                                    setIDString(this,str(:)');
                                    this.hDebug.log(sprintf('Received SET_ID_STRING = "%s" command',str(:)'),'info');
                                case Video.Webcam.Command.SET_SUBJECT
                                    str = char(payload);
                                    setSubject(this,str(:)');
                                    this.hDebug.log(sprintf('Received SET_SUBJECT = "%s" command',str(:)'),'info');
                                case Video.Webcam.Command.EXIT
                                    this.hDebug.log('Received EXIT command','info');
                                    if this.ignoreExitCommand
                                        this.hDebug.log('Ignoring EXIT command!','info');
                                    else
                                        t = timer;
                                        t.Name = 'deleteSoundTimer';
                                        t.ExecutionMode = 'singleShot';
                                        t.Period = 1;
                                        t.TimerFcn = @timerFcn;
                                        t.StopFcn = @stopFcn;
                                        start(t);
                                    end
                                case Video.Webcam.Command.REQUEST
                                    this.hDebug.log('not implemented yet','warn');
                            end
                        otherwise
                            this.hDebug.log(sprintf('Invalid MessageType "%d"',type),'warn');
                    end
                end
                
                function timerFcn(~,~)
                    % TIMERFCN Delete the Server object on a delay
                    %
                    %   TIMERFCN(T,EVT)
                    %   Calls delete on the Server object
                    
                    delete(this);
                end % END function timerFcn
                function stopFcn(tmr,~)
                    % STOPFCN Clean up the timer
                    %
                    %   STOPFCN(T,EVT)
                    %   Delete the timer after deleting the Server object.
                    
                    delete(tmr);
                end % END function stopFcn
                
            end % END function processDatagram
        end % END function initializeUDP
        
        function initializeCBMEX(this)
            % INITIALIZECBMEX Initialize the neural data interface
            %
            %   INITIALIZECBMEX(THIS)
            %   Start and initialize the Blackrock interface.
            
            this.hCBMEX = Blackrock.Interface(...
                'nspString',this.cbmexArrayStrings,...
                'cbmexOpenArgs',this.cbmexOpenArgs,...
                'cbmexInterface',this.cbmexInterface);
            initialize(this.hCBMEX);
        end % END function initializeCBMEX
        
        function initializeFileWriter(this)
            % INITIALIZEFILEWRITER Initialize object for saving A/V data.
            %
            %   INITIALIZEFILEWRITER(THIS)
            %   Create the object used to save audio and video data to
            %   disk.
            
            % Create the VideoFileWriter object and set its properties
            this.hVideoFileWriter = vision.VideoFileWriter;
            this.hVideoFileWriter.Filename          = fullfile(this.savePath,[this.fileBasename this.fileExtension]);
            this.hVideoFileWriter.FileFormat        = this.fileFormat;
            this.hVideoFileWriter.AudioInputPort    = this.enableAudio;
            if strcmpi(this.fileFormat,'AVI')
                if this.enableAudio
                    this.hVideoFileWriter.AudioCompressor = this.fileAudioCompressor;
                end
                this.hVideoFileWriter.VideoCompressor   = this.fileVideoCompressor;
            end
            this.hVideoFileWriter.FrameRate         = this.videoFrameRate;
            this.hVideoFileWriter.FileColorSpace    = this.fileColorSpace;
        end % END function initializeFileWriter
        
        function cleanupFileWriter(this)
            % CLEANUPFILEWRITER Clean up the object for saving A/V data.
            %
            %   CLEANUPFILEWRITER(THIS)
            %   Release the video file writer object.
            
            if isa(this.hVideoFileWriter,'vision.VideoFileWriter')
                release(this.hVideoFileWriter);
            end
        end % END function cleanupFileWriter
        
        function initializeAudio(this)
            % INITIALIZEAUDIO Initialize the audio recording object
            %
            %   INITIALIZEAUDIO(THIS)
            %   Create and initialize the audio recording object.
            %
            %   Notes: sound card fills a buffer (audioBufferSize samples).
            %   When buffer is full, it's emptied into the bottom of a 
            %   queue (audioQueueDuration seconds).  The 'step' function 
            %   reads samples from the top of the queue each time it is 
            %   called (property of dsp.AudioRecorder sets how many; for
            %   this application, calculated as exactly the number of
            %   samples corresponding to the vide frame duration).
            
            % audio device buffer is either 'auto' (in which case it will
            % default to 4096 samples) or 'property' (in which case user
            % must provide the buffer size -- recommend in powers of 2).
            % Buffer fills and transfers to queue asynchronously as far as
            % I can tell.
            if isempty(this.audioBufferSize) || (ischar(this.audioBufferSize) && strcmpi(this.audioBufferSize,'auto'))
                audioBufferSizeSource = 'Auto';
                this.audioBufferSize = 'Auto';
            else
                audioBufferSizeSource = 'Property';
            end
            
            % queue duration: middle man between audio buffer and software
            % processing frames
            if isempty(this.audioQueueDuration)
                this.audioQueueDuration = 0.2; % default queue size (0.4 sec or 3 frames @ 11025 Fs)
                this.hDebug.log(sprintf('Set audio queue duration to %.4f sec (~%d samples)',this.audioQueueDuration,round(this.audioQueueDuration*this.audioSampleRate)),'info');
            end
            
            % default samples per frame is exactly the number of samples
            % equal to the frame duration
            audioSamplesPerFrame = ceil(1*this.audioSampleRate/this.videoFrameRate);
            this.hDebug.log(sprintf('%d audio samples per frame',audioSamplesPerFrame),'info');
            
            % create the AudioRecorder object and set its properties
%             this.hAudioRecorder = dsp.audiorecorder;
            this.hAudioRecorder = audioDeviceReader();
            %%%%%%
            this.hAudioRecorder.Device              = this.audioDeviceName;
            this.hAudioRecorder.Driver              = this.audioDeviceDriverName; 
%             this.hAudioRecorder.DeviceName          = this.audioDeviceName;
            this.hAudioRecorder.SampleRate          = this.audioSampleRate;
            this.hAudioRecorder.SamplesPerFrame     = audioSamplesPerFrame;
%             this.hAudioRecorder.BitDepth            = this.audioDeviceDataType;
%             this.hAudioRecorder.DeviceDataType      = this.audioDeviceDataType;
%             this.hAudioRecorder.OutputDataType      = this.audioOutputDataType;
            this.hAudioRecorder.NumChannels         = this.audioNumChannels;
            this.hAudioRecorder.ChannelMappingSource= audioBufferSizeSource;
%             this.hAudioRecorder.BufferSizeSource    = audioBufferSizeSource;
%             if ~isempty(this.audioQueueDuration)
%                 this.hAudioRecorder.QueueDuration = this.audioQueueDuration;
%             end
            if strcmpi(audioBufferSizeSource,'Property')
                this.hAudioRecorder.SamplesPerFrame = this.audioBufferSize;
            end
%             if isprop(this.hAudioRecorder,'OutputNumOverrunSamples')
%                 if this.queueOverrun
%                     this.hAudioRecorder.OutputNumOverrunSamples = true;
%                 end
%             else
%               this.queueOverrun = false;
%             end
            
            % report buffer size (last in order to read if auto)
            this.audioBufferSize = this.hAudioRecorder.SamplesPerFrame;
            this.hDebug.log(sprintf('Set audio buffer size to %d (source is "%s")',this.audioBufferSize,audioBufferSizeSource),'info');
        end % END function initializeAudio
        
        function cleanupAudio(this)
            % CLEANUPAUDIO Clean up the audio recording object
            %
            %   CLEANUPAUDIO(THIS)
            %   Release the audio recording object.
            
            if this.enableAudio && isa(this.hAudioRecorder,'audioDeviceReader')
                release(this.hAudioRecorder);
            end
        end % END function cleanupAudio
        
        function initializeVideo(this)
            % INITIALIZEVIDEO Initialize the video recording object
            %
            %   INITIALIZEVIDEO(THIS)
            %   Create and initialize the video recording object.
            
            % create videoinput object and set trigger to manual
            this.hVideoInput = videoinput(this.videoAdaptorName,this.videoDeviceID,this.videoFormat);
            triggerconfig(this.hVideoInput, 'manual');
            
            % set exposure/white balance (possible speed improvements)
            src = getselectedsource(this.hVideoInput);
            srcWritableProps = fieldnames(set(src));
            
            % set exposure mode and value
            if any(strcmpi(srcWritableProps,'ExposureMode'))
                set(src,'ExposureMode',this.videoExposureMode);
            end
            if any(strcmpi(srcWritableProps,'Exposure'))
                if strcmpi(this.videoExposureMode,'manual')
                    set(src,'Exposure',this.videoExposureValue);
                end
            end
            
            % set focus mode and value
            if any(strcmpi(srcWritableProps,'FocusMode'))
                set(src,'FocusMode',this.videoFocusMode);
            end
            if any(strcmpi(srcWritableProps,'Focus'))
                if strcmpi(this.videoFocusMode,'manual')
                    set(src,'Focus',this.videoFocusValue);
                end
            end
            
            % set white balance mode and value
            if any(strcmpi(srcWritableProps,'WhiteBalanceMode'))
                set(src,'WhiteBalanceMode',this.videoWhiteBalanceMode);
            end
            if any(strcmpi(srcWritableProps,'WhiteBalance'))
                if strcmpi(this.videoWhiteBalanceMode,'manual')
                    set(src,'WhiteBalance',this.videoWhiteBalanceValue);
                end
            end
            
            % start the video device
            start(this.hVideoInput);
        end % END function initializeVideo
        
        function cleanupVideo(this)
            % CLEANUPVIDEO Clean up the video recording object
            %
            %   CLEANUPVIDEO(THIS)
            %   Release the video recording object.
            
            if isa(this.hVideoInput,'videoinput')
                if strcmpi(this.hVideoInput.Running,'on')
                    stop(this.hVideoInput);
                end
                delete(this.hVideoInput);
            end
        end % END function cleanupVideo
    end % END methods
    
    methods(Static)
        function listAudioDevices(varargin)
            % LISTAUDIODEVICES Display audio hardware information
            %
            %   LISTAUDIODEVICES
            %   Displays a list of devices for recording audio.
            %
            %   LISTAUDIODEVICES('all')
            %   LISTAUDIODEVICES('in[put]')
            %   LISTAUDIODEVICES('out[put]')
            %   List all audio devices (default), only devices with input, 
            %   or only devices with output.
            
            % process user input
            [varargin,which] = util.argkeyword({'input','output','all'},varargin,'all',2);
            util.argempty(varargin);
            
            % subselect devices
            deviceList = dspAudioDeviceInfo;
            switch lower(which)
                case 'input',  deviceList([deviceList.maxInputs]==0)=[];
                case 'output', deviceList([deviceList.maxOutputs]==0)=[];
                case 'all'
                otherwise
                    error('Unknown device selection ''%s''',which);
            end
            
            % display information
            for kk=1:length(deviceList)
                this.hDebug.log(sprintf('Device %2d: "%s"',kk,deviceList(kk).name),'info');
                this.hDebug.log(sprintf('%15s: %d','Max Inputs',deviceList(kk).maxInputs),'info');
                this.hDebug.log(sprintf('%15s: %d','Max Outputs',deviceList(kk).maxOutputs),'info');
            end
        end % END function listAudioDevices
        
        function listVideoDevices
            % LISTVIDEODEVICES Display video hardware information
            %
            %   LISTVIDEODEVICES
            %   Displays a list of adaptors, devices, and supported formats
            %   available on the local system.
            
            adaptorInfo = imaqhwinfo;
            for a = 1:length(adaptorInfo.InstalledAdaptors)
                this.hDebug.log(sprintf('Adaptor: "%s"',adaptorInfo.InstalledAdaptors{a}),'info');
                deviceInfo = imaqhwinfo(adaptorInfo.InstalledAdaptors{a});
                for d = 1:length(deviceInfo.DeviceIDs)
                    dev = deviceInfo.DeviceInfo(d);
                    this.hDebug.log(sprintf('Device Name: "%s"',dev.DeviceName),'info');
                    this.hDebug.log(sprintf('Device ID: "%d"',dev.DeviceID),'info');
                    this.hDebug.log('Supported Formats:','info');
                    for f = 1:length(dev.SupportedFormats)
                        this.hDebug.log(sprintf('%s',dev.SupportedFormats{f}),'info');
                    end
                end
            end
        end % END function displayHardwareInfo
    end % END methods(Static)
end % END classdef Server