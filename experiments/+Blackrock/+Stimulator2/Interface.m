classdef Interface < handle & util.Structable & util.StructableHierarchy
    % INTERFACE Encapsulate communication with the stimulator server.
    %
    %   The Blackrock Interface class serves as the MATLAB interface to
    %   Blackrock Cerebus96 through the Blackrock STIMMEX MATLAB API.  This
    %   class provides basic functionality for delievering stimulation
    %   waveforms and triggering stimulation
    %
    %   The Blackrock STIMMEX MATLAB API must be on the path, or it must
    %   reside in a subfolder 'STIMMEX' of the current MATLAB folder.
    %
    %   EXAMPLE:
    %   >> hStimulator2 = Blackrock.Stimulator2.Interface;
    %   >>
    %   >> cmd = Blackrock.Stimulator2.StimCommand;
    %   >> cmd.configureWaveform(1, 0, 5, 50, 200, 150, 53);
    %   >> cmd.electrode = 1;
    %   >> cmd.duration = 1;
    %   >>
    %   >> hStimulator2.configure(cmd);
    %   >> hStimulator2.start(cmd);
    %   >>
    %   >> //DO SOMETHING
    %   >>
    %   >> hStimulator2.stop();
    %   >> hStimulator2.close();
    %
    %   See also BLACKROCK.STIMULATOR2/STIMCOMMAND.
    
    properties
        verbosity                       % verbosity level
        debug                           % debug object
        dummy = false                   % is connected to physical device
        commentFcn                      % handle to comment function (or cell array with first cell containing function handle)
    end                                 % END properties
    
    properties(Access=private)
        stimulator                      % stimulator object
        isOpen = false;                 % whether the interface is open
        isSequenceLoaded = false;       % whether a sequence is loaded
        %         stimHistory = struct{'endPoint', 0, ... % struct object for delivered stim
        %                              'chargeRate', 0, ...
        %                              'chargeAmount', 0};
        PROTCL_LIMIT_InPhDelay  = 200   % max interphase delay in micro-seconds
        PROTCL_LIMIT_Amp        = 10000   % max ampltiude in micro-amps
        PROTCL_LIMIT_PhWidth    = 660   % max phase width delay in micro-seconds
        PROTCL_LIMIT_ChrgRate   = 720000 % max charge delivery rate nano-coulombs per 10 seconds -- it was 30000nC/10s in the code. Change to 720000 nC/10s using 
        % the max CPP at 1800 nC/phase and 1 s stim at a max frequency of 200 Hz.
        % Should this limit be lowered, a soft limit is calculated as 375000 nC/10s using ratio between values for micro stim and macro stim
        % i.e: (max CPP for macro stim / max CPP for micro stim) * max Charge Rate for micro stim 
        % = ((1800 nC/phase) / (144 nC/phase))* (30000 nC/10 s) = 375000 nC/10 s
        PROTCL_LIMIT_Dur        = 60    % max stimulation sequence duration in seconds
        PROTCL_LIMIT_Freq       = 333.3   % max frequency in hertz
        PROTCL_LIMIT_ChrgDensity = 30; % Max Charge density in micro-Columb/cm2/phase)
        PROTCL_LIMIT_ChrgPerPh  = 1800   % max simultaneously delivered charge/phase in nano-coulombs/phase -- it was 144 nC/phase for code for microelectrode version
        % cpp = 1800 nC/phase is from Shannon's Equation for electrode with surface area 6 mm2
        % Shannon's Equation : 
        % log (charge density in micro-Columb/cm2/phase) = 1.7 - log(charge/phase in micro-Columb/phase)
 
        MAX_VOLTAGE             = 15    % top stimulator rail voltage index  15: 9.5V
        %                                    14: 8.9V
        %                                    13: 8.3V
        %                                    12: 7.7V
        %                                    11: 7.1V
        %                                    10: 6.5V
        %                                     9: 5.9V
        %                                     8: 5.3V
        %                                     7: 4.7V
    end % END properties(Access=private)
    
    properties (GetAccess=public, SetAccess=private)
        STATUS_STOPPED  = 0             % status value, sequence stopped
        STATUS_PAUSED   = 1             % status value, sequence paused
        STATUS_PLAYING  = 2             % status value, sequence playing
        STATUS_WRITING  = 3             % status value, sequence waiting
        STATUS_TRIGGER  = 4             % status value, sequence waiting for trigger
    end % END properties(GetAccess=public, SetAccess=private)
    
    methods
        function this = Interface(varargin)
            % INTERFACE Constructor for the Interface class
            %
            %   S = INTERFACE
            %   Create an object of the Blackrock.Stimulator2/Interface.
            %   Default values for each property are listed below. Any
            %   publically writeable property may be set as a keyword-value
            %   input pair in the arguments of the constructor.  Use the
            %   MATLAB 'properties' function to get a list of all
            %   properties of this class.
            %
            %   STIMINTERFACE(...,'VERBOSE',TRUE)
            %   STIMINTERFACE(...,'VERBOSE',FALSE)
            %   Enable or disable verbosity.
            %
            %   See also BLACKROCK.STIMULATOR2/INTERFACE.
            
            
            % property-style inputs override config, make sure no remaining
            varargin = util.argobjprop(this,varargin);
            if ~this.dummy
                
                % check dependency
                if exist('stimmex','file')~=3
                    % first priority: user input
                    [varargin,stimmexFolder,~,found_stimmexFolder] = util.argkeyval('stimmexFolder',varargin,'',7);
                    if found_stimmexFolder
                        assert(exist(stimmexFolder,'dir')==7,'Invalid directory "%s"',stimmexFolder);
                        addpath(stimmexFolder);
                    else
                        
                        % second priority: HST environment variable
                        stimmexFolder = env.get('stimmexFolder');
                        if exist(stimmexFolder,'dir')==7
                            addpath(stimmexFolder);
                        else
                            
                            % third priority: reconstruct from file path
                            stimmexFolder = mfilename('fullpath');
                            mc = meta.class.fromName(class(this));
                            for mm=1:length(mc.SuperclassList)
                                if isempty(mc.SuperclassList(mm).ContainingPackage),continue;end
                                pkg = mc.SuperclassList(mm).ContainingPackage.Name;
                                pkgdir = regexprep(sprintf('+%s',pkg),'\.','\\+');
                                local_stimmexFolder = stimmexFolder(1:strfind(stimmexFolder,pkgdir)-2);
                                local_stimmexFolder = fullfile(local_stimmexFolder,'stimmex');
                                if exist(local_stimmexFolder,'dir')==7
                                    stimmexFolder = local_stimmexFolder;
                                    addpath(stimmexFolder);
                                    break;
                                end
                            end
                        end
                    end
                end
                assert(exist('stimmex','file')==3,'Cannot find "stimmex" dependency');
                
                % load debug/verbosity HST env vars
                % TODO: CHECK IF FRAMEWORK IS ACTIVE
                [this.debug, this.verbosity] = env.get('debug','verbosity');
                this.commentFcn = {@cmdWindowOutput, this};
                
                % open stimulator connection
                initialize(this);
            end
            util.argempty(varargin);
        end % END function Interface
        
        
        function loadServer(this)
            % LOADSERVER
            %
            % LOADSERVER(~)
            % Legacy function, dummy function
        end % END function loadServer
        
        
        function stopServer(this)
            % STOPSERVER
            %
            % STOPSERVER(~)
            % Legacy function, dummy function
        end % END function stopServer
        
        
        function output = configure(this, cmd)
            % CONFIGURE Update local stimulator object with waveform and
            % sequence information
            %
            %   CONFIGURE(THIS, CMD)
            %   Set values for waveform pattern and set all electrodes to
            %   stimulate that pattern simultaneously for specified
            %   duration. CMD must be a Blackrock.Stimulator2.StimCommand
            %   object.
            
            try
                this.configurePattern(cmd);
                this.configureBasicSequence(cmd.waveformID, cmd.electrode);
                output = true;
                % adding to see if we can get any value when stim happens (
                % true/false for 100 or 500 ms of stimulation
%                 locked = this.stimulator.isLocked
                
            catch ME
                util.errorMessage(ME);
                output = false;
            end
        end % END function configure
        
%{        
        function validate(this,cmd,gMap)
            % VALIDATE Verify parameters are within allowed protocol limits
            %
            %   VALIDATE(THIS,CMD,GMAP)
            %   Checks that parameters initialized on stimulator are
            %   within protocol limits.
            assert(cmd.interphase <= this.PROTCL_LIMIT_InPhDelay, 'Illegal interphase cmd value');
            assert(cmd.amplitude  <= this.PROTCL_LIMIT_Amp,       'Illegal amplitude cmd value');
            assert(cmd.phaseWidth <= this.PROTCL_LIMIT_PhWidth,   'Illegal phase width cmd value');
            assert(cmd.interphase <= this.PROTCL_LIMIT_InPhDelay, 'Illegal interphase cmd value');
            assert(cmd.frequency  <= this.PROTCL_LIMIT_Freq,      'Illegal frequency cmd value');
            assert(cmd.duration   <= this.PROTCL_LIMIT_Dur,       'Illegal duration cmd value');  
            % calcuate charge per phase in nano-coulombs (CPP)
            cmd_cpp = cmd.amplitude * cmd.phaseWidth / 1000;
            % calculate max simultaneously charge per phase delievered
            cmd_cpp_allEl = cmd_cpp * numel(cmd.electrode);
            assert(cmd_cpp_allEl <= this.PROTCL_LIMIT_ChrgPerPh, 'Illegal charge per phase: too many electrodes');
            cmd_chrgDensity = (cmd.amplitude/1000)*(cmd.phaseWidth/1000)/ this.calcSurfaceArea(gMap,cmd.electrode);
            assert(cmd_chrgDensity<=this.PROTCL_LIMIT_ChrgDensity, 'Illegal charge density: too much charge per area');
            % calculate single electrode max injection rate
            % Charge Rate = charge per phase * 2 phases * Freq * 10 sec
            cmd_chrgRate = cmd_cpp * 2 * cmd.frequency * cmd.duration;
            assert(cmd_chrgRate <= this.PROTCL_LIMIT_ChrgRate, 'Illegal charge per phase: too much charge per time');
        end % END function validate
        
%}        
        function enableTrigger(this, edge)
            % ENABLETRIGGER set enable trigger for stimulator
            %
            %   ENABLETRIGGER(THIS, EDGE)
            %   Sends command to stimulator object to enable stimulation on
            %   trigger input. EDGE sets mode (1 - rising (low to high), 2
            %   - falling (high to low), 3 - either rising or falling).
            %   Default value is rising.
            if nargin < 2 || isempty(edge), edge = 1; end
            if edge > 3 || edge < 1
                warning('Inproper stimulation trigger edge mode set, default value enabled');
                edge = 1;
            end
            
            % set trigger mode
            this.stimulator.trigger(edge);
            
            % check to see if trigger mode is set
            status = this.stimulator.getSequenceStatus();
            assert( status == 4, 'Stimulator Set Trigger Mode Failed' );
        end
        
        
        function disableTrigger(this)
            % DISABLETRIGGER disable trigger for stimulator
            %
            %   DISABLETRIGGER(THIS)
            %   Sends command to stimulator object to disation stimulation on
            %   trigger input.
            
            this.stimulator.disableTrigger;
        end
        
        
        function start(this,cmd)
            % START Stop stimulating
            %
            %   START(THIS, CMD, GMAP)
            %   Sends command to stimulator object to begin stimulating.
            %   Runs check to ensure compliance with injected charge limits
            %   and maximum allowable charge per phase / amplitude / etc --
            %   commented validate() after purging out illegal combinations
            %   during param creation.
            %   CMD must be a Blackrock.Stimulator2.StimCommand object.
            
            % check if stimualator is in the middle of sequence
            assert( this.getSequenceStatus() == this.STATUS_STOPPED, 'Stimulator already running');
            
            % check if cmd is safe
            % validate(this,cmd,gMap);
            
            % if sequence isn't laoded, load
            if ~this.isSequenceLoaded, configure(this, cmd); end
            assert(this.isSequenceLoaded, 'Sequence must be loaded to play stimulation');
            
%             % calcuate length of stimulation train
%             sequenceDuration_sec = cmd.numPulses * 1/cmd.frequency;
%             numRepeats           = floor(cmd.duration / sequenceDuration_sec);
            
%             % turn on stimulation
%             this.stimulator.play(numRepeats);
        this.stimulator.play(1);
        end % END function start
        
        
        function stop(this)
            % STOP Stop stimulating
            %
            %   STOP(THIS)
            %   Sends command to stimulator object to stop stimulating
            this.stimulator.stop();
        end % END function stop
        
        
        function close(this)
            % CLOSE Close the STIMMEX interface
            %
            %   CLOSE(THIS)
            %   If recording, stop recording, then close the CBMEX
            %   interface.
            
            % make sure the interface is open
            assert(this.isOpen, 'Interface not open');
            
            % stop recording
            if this.getSequenceStatus() > this.STATUS_STOPPED, stop(this); end
            
            % close
            this.stimulator.disconnect;
            
            this.isOpen = false;
        end % END function close
        
        function skip = structableSkipFields(~)
            skip = {'commentFcn'};
        end % END function structableSkipFields
        
        function st = structableManualFields(~)
            st = struct;
        end % END function structableManualFields
        
        function delete(this)
            % DELETE Delete the object
            %
            %   DELETE(THIS)
            %   If the Interface is open, close it, then delete the object
            %   as normal.
            
            % if open, close
            if this.isOpen, close(this); end
        end % END function delete
        
        function comment(this,msg,vb)
            % COMMENT Display a message on the screen
            %
            %   COMMENT(THIS,MSG,VB)
            %   Display the text in MSG on the screen depending on the
            %   message verbosity level VB.  MSG should not include a
            %   newline at the end, unless an extra newline is desired.  If
            %   VB is not specified, the default value is 1.
            
            % default message verbosity
            if nargin<3,vb=1;end
            
            % execute the comment function
            feval(this.commentFcn{:},msg,vb);
        end % END function comment
        
        
    end % END methods
    
    methods(Access='private')
        function surfaceArea = calcSurfaceArea(this,gridMap,elId)
%             To calculate the surface area of the stimulating electrode
            gridID = gridMap{1}.ChannelInfo.GridID(gridMap{1}.ChannelInfo.RecordingChannel == elId);
            gMapSpecs = gridMap{1}.GridInfo.Custom{gridMap{1}.GridInfo.GridID == gridID};
            surfaceArea = pi*str2double(gMapSpecs.ElectrodeDiameter)/10*str2double(gMapSpecs.ElectrodeWidth)/10;
        end
        function initialize(this)
            % INITIALIZE Initialize the STIMMEX interface
            %
            %   INITIALIZE(THIS)
            %   Lock the current settings and open the requested number of
            %   STIMMEX instances.  Also, configure the CereStim96 to be
            %   enabled.
            
            % make sure the interface is not open
            assert(~this.isOpen, 'WARNING: Interface is already open');
            
            % Create stimulator object
            this.stimulator = cerestim96();
            pause(1);
            
            %             % Scan for devices
            %             deviceList = this.stimulator.scanForDevices();
            %             pause(1);
            % %             usb = this.stimulator.usbAddress;
            %             % Select a device to connect to
            %             if deviceList ~= 0
            %                 this.stimulator.selectDevice(deviceList(1));
            %             else
            %                 comment(this, 'ERROR: Blackrock Stimulator not found. Please press enter after reconnecting.', 1);
            %                 pause;
            %                 deviceList = this.stimulator.scanForDevices();
            %                 clear this.stimulator.selectDevice(deviceList(1));
            %             end
            
            
            % Scan for devices
            deviceList = this.stimulator.scanForDevices();
            pause(1);
            %             usb = this.stimulator.usbAddress;
%             Select a device to connect to
            if  ~isempty(deviceList)
                this.stimulator.selectDevice(deviceList);
            else
                comment(this, 'ERROR: Blackrock Stimulator not found. Please press enter after reconnecting.', 1);
                pause;
                deviceList = this.stimulator.scanForDevices();
                clear this.stimulator.selectDevice(deviceList(1));
            end
            assert(~isempty(deviceList), 'Device List Empty');
            % Connect to stimulator
            this.stimulator.connect;
            if (this.stimulator.isConnected())
                % update status
                this.isOpen = true;
                
                % update user
                comment(this, 'Success! Interface is open', 3);
            else
                % update status
                this.isOpen = false;
                % update user
                comment(this, 'ERROR: Could not open interface', 1);
            end
            
            % Set safety limits
            %             [~] = this.stimulator.stimulusMaxValue(this.MAX_VOLTAGE, ...
            %                                                    this.PROTCL_LIMIT_Amp, ...
            %                                                    this.PROTCL_LIMIT_ChrgPerPh*1000, ...
            %                                                    this.PROTCL_LIMIT_Freq);
            
            %             max_values = this.stimulator.stimulusMaxValue()
            %             hardware_values = this.stimulator.getHardwareValues()
            
            % make sure safetly limits are set
            assert(~this.stimulator.isSafetyDisabled(), 'WARNING: CereStim firmware safetly limits are disabled. Contact Blackrock support.');
            
        end % END function initialize
        
        
        function status = getSequenceStatus(this)
            % GETSTATUS Return status of stimulator
            %
            %   GETSTATUS(THIS)
            %   Returns an index, indicating status
            
            if (this.isSequenceLoaded)
                status = this.stimulator.getSequenceStatus();
            else
                status = 0;
            end
        end % END function getSequenceStatus
        
        
        function configurePattern(this, cmd)
            % CONFIGUREPATTERN update Blackrock CereStim96 waveform
            %
            %   CONFIGUREPATTERN(THIS,CMD)
            %   Update local stimulation object with waveform parameters
            %   and send pattern to stimulator via stimmex (handled by
            %   stimulator object)
            
            assert(this.isOpen, 'Interface must be open to send a command');
            assert(isa(cmd, 'Blackrock.Stimulator2.StimCommand'), 'Must send a Blackrock.Stimulator2.StimCommand object');
            assert(cmd.isValidCommand(), 'Must be a valid command');
            
            % Set and get new waveforms
            this.stimulator.disableStimulus(cmd.waveformID);
            this.stimulator.setStimPattern(...
                'waveform',     cmd.waveformID,...
                'polarity',     cmd.polarity,...
                'pulses',       cmd.numPulses,...
                'amp1',         cmd.amplitude,...
                'amp2',         cmd.amplitude,...
                'width1',       cmd.phaseWidth,...
                'width2',       cmd.phaseWidth,...
                'interphase',   cmd.interphase,...
                'frequency',    cmd.frequency);
            comment(this, 'Waveform configuration set', 7);
            
            waveform = this.stimulator.getStimPattern(cmd.waveformID);
            comment(this, 'Waveform configuration read', 7);
            
            % Check cerebus R96 has been updated
            % Read stimulus max values and modify them
            stimulus_max = this.stimulator.stimulusMaxValue();
            
            temp_voltage         = stimulus_max.voltage;
            temp_amplitude       = stimulus_max.amplitude;
            temp_phaseCharge     = stimulus_max.phaseCharge;
            temp_freq            = stimulus_max.frequency/2;
            
            [~] = this.stimulator.stimulusMaxValue(temp_voltage, temp_amplitude, temp_phaseCharge, temp_freq);
            temp_stim = this.stimulator.stimulusMaxValue();
            [~] = this.stimulator.stimulusMaxValue(temp_voltage, temp_amplitude, temp_phaseCharge, temp_freq*2);
            
            % verify values match
            if (stimulus_max.frequency == temp_stim.frequency*2)
                comment(this, 'Max stimulus parameters successfully updated', 7);
            else
                comment(this, 'Failed to update stimulus parameters', 7);
            end
        end % END function configure
        
        
        function configureBasicSequence(this, wid, el)
            % CONFIGUREBASICSEQUENCE update Blackrock CereStim96 seqeunce
            %
            %   CONFIGUREBASICSEQUENCE(THIS, WID, EL)
            %   Update local stimulation object with the set of electrode
            %   to be stimulated in which order and what duration
            
            try
                [~] = this.stimulator.getStimPattern(wid);
            catch ME
                util.errorMessage(ME);
                this.isSequenceLoaded = false;
                return;
            end
            
            % Configure sequence
            this.stimulator.beginSequence();
            this.stimulator.beginGroup();
            
            % assign each electrode
            for kk = el
                this.stimulator.autoStim(kk, wid);
            end
            
            %End program definition
            this.stimulator.endGroup();
            this.stimulator.endSequence;
            
            % sequence loaded
            this.isSequenceLoaded = true;
            
        end % END function configureBasicSequence
        
        
        %{
function configureSeqeunce()
            
            %             assert(this.isOpen, 'Interface must be open to send a command');
            %             assert(isa(cmd,'Blackrock.Stimulator2.StimSequence'), 'Must send a Blackrock.Stimulator2.StimSequence object');
            %             assert(cmd.isValidSequence(), 'Must be a valid sequence');
            
            % Other commands
            % groupStimulus(BeginSeq, Play, Times, , Electrodes, Patterns)
            % wait(Milliseconds)
            % beginSequence()
            % endSequence()
            % autoStim(Electrode, Waveform ID)
            % manualStim(Electrode, Waveform ID) % single electrode only
            % pause()
           
        end % END function configureSequence
        
         %}
        function cmdWindowOutput(this,msg,vb)
            % CMDWINDOWOUTPUT Internal function for printing messages
            %
            %   CMDWINDOWOUTPUT(THIS,MSG)
            %   Print the string in MSG to the screen with the '[STIMMEX]'
            %   identifier prepended.
            %
            %   CMDWINDOWOUTPUT(...,ARG1,ARG2,...,ARGn)
            %   Provide additional arguments which will be passed directly
            %   to the COMMENT method of this class.
            %
            %   See also BLACKROCK.INTERFACE/COMMENT.
            
            if vb<=this.verbosity, fprintf('[STIMMEX] %s\n', msg); end
        end % END function cmdWindowOutput  
        
    end % END methods
    
end % END classdef Interface