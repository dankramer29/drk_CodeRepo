classdef Interface < handle & util.Structable
% INTERFACE Class to abstract interacting with NI cDAQ hardware
%
% This class provides an abstraction for controlling data acquisition
% with a National Instruments module. There are options to start and stop
% recording, plot data as it comes in, save data to disk, and configure
% aspects of data capture.
%
% To create an Interface object:
%
% >> t = Interface;
%
% Without any arguments, all default properties will be used - essentially
% configuring the object to record from the Blackrock stimulator monitor
% outputs. To plot, save, and use random data:
%
% >> t = Interface('plot','save','random');
    
    properties(SetAccess=private,GetAccess=public)
        hSession % handle to daq session object
        
        hUDP % handle to UDP object for receiving commands
        udpIPAddress = '192.168.100.73'; % IP address of server
        udpRemotePort = 7007 % the server's receive port
        udpLocalPort = 7006 % the local send port
        
        hAnalogInputDevice % handle to analog input daq device(s)
        hAnalogOutputDevice % handle to analog input daq device(s)
        hDigitalIODevice % handle to digital IO daq device(s)
        
        hAnalogInputChannel % handle to analog input channel object(s)
        hAnalogOutputChannel % handle to analog output channel object(s)
        hDigitalChannel % handle to digital channel object(s)
        
        SamplingRate = 100000; % default sampling rate
        AcquisitionPeriod = 0.1; % length of single acquisition (in seconds)
        OutputQueueLength = 2.5; % length of output queue (in seconds)
        
        AnalogInputDeviceName = 'cDAQ9184-1BFBCE7Mod1'; % name of the NI device for analog input
        AnalogInputMeasurementType = 'Voltage'; % default measurement type ('voltage')
        AnalogInputTerminalConfig = 'SingleEnded'; % default recording configuration (differential, single-ended, etc.)
        AnalogInputRange = [-10 10]; % range (in volts) of the input measurement
        AnalogInputChannels = {'ai0'}; % default list of channels to record
        AnalogInputChannelNames = {'Stim Monitor Input'}; % default names of the channels
        
        AnalogOutputDeviceName = 'cDAQ9184-1BFBCE7Mod3'; % name of the NI device for analog output
        AnalogOutputMeasurementType = 'Voltage'; % default measurement type ('voltage')
        AnalogOutputTerminalConfig = 'SingleEnded'; % default recording configuration (differential, single-ended, etc.)
        AnalogOutputRangeHardware = [-10 10]; % technical range (in volts) of the output signal
        AnalogOutputRangeActual = [-5 5]; % effective range (in volts) of the output signal (via normalization)
        AnalogOutputChannels = {'ao0','ao1'}; % default list of channels to output
        AnalogOutputChannelNames = {'Stim Monitor Output','Stim Sync Output'}; % default names of the channels
        
        DigitalIODeviceName = 'cDAQ9184-1BFBCE7Mod2'; % name of the NI device for digital I/O
        DigitalIOMeasurementType = 'InputOnly'; % default measurement type ('Bidirectional','OutputOnly','InputOnly')
        DigitalIOChannels = {'port0/line0'}; % default list of channels to output
        DigitalIOChannelNames = {'Stim Sync Input'}; % default names of the channels
        
        numAnalogInputChannels = 0 % number of analog input channels in the system
        numAnalogOutputChannels = 0 % number of analog output channels in the system
        numDigitalInputChannels = 0 % number of digital input channels in the system
        numDigitalOutputChannels = 0 % number of digital output channels in the system
        numDigitalBidirectionalChannels = 0 % number of bidirectional channels in the system
        
        SaveDirectory = '.' % directory for the output file
        SaveBasename = 'ni' % basename of the output file
        SessionID % session identifier to append to basename
        RunID % run identifier to append after session ID
        SaveExtension = '.bin' % file extension of the output file
        idString % ID identifier for recording files with same task idString
        moveDirectory % directory to transfer the output file, when delete is called
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties(Access=private)
        flagAnalogInputRandom = false; % flag to generate random data for analog input
        flagAnalogOutputRandom = false; % flag to use random data for analog output
        flagCapture = false; % flag to capture data in the next snapshot
        flagPlot = false; % flag to plot the data as it comes in
        flagSave = false; % flag to save the data to disk
        flagAnalogInput = true; % flag to enable/disable analog input
        flagAnalogOutput = false; % flag to enable/disable analog output
        flagDigitalIO = false; % flag to enable/disable digital IO
        flagMoveFile = false; % flag to enable/disable moving file after save
        
        DataClass = 'single'; % class of the saved data
        
        openPlot = false; % whether the plot is open
        openFile = false; % whether the output file is open
        openSession = false; % whether the session is open
        movedFile = false; % whether we have changed the file location
        
        sessionChannelOrder % store the order in which channels are added
        data % buffers with captured data
        outfile % full path to output file
        fid % file ID if writing to disk
        gui % handles to GUI elements
        lhEvents % listener handles
        
        hTimer % timer handle for generating fake random data
        currRandTimestamp = 0; % track the current timestamp
        samplesPerInterrupt = 1000; % number of samples each time timer fires
        stats % track some stats about performance
        
        ignoreExitCommand = true;
        
    end % END properties(Access=private)
    
    methods
        function this = Interface(varargin)
            
            % analog input
            [varargin,this.AnalogInputDeviceName]       = util.argkeyval('aiDeviceName',varargin,this.AnalogInputDeviceName);
            [varargin,this.AnalogInputMeasurementType]  = util.argkeyval('aiMeasurementType',varargin,this.AnalogInputMeasurementType);
            [varargin,this.AnalogInputTerminalConfig]   = util.argkeyval('aiTerminalConfig',varargin,this.AnalogInputTerminalConfig);
            [varargin,this.AnalogInputRange]            = util.argkeyval('aiInputRange',varargin,this.AnalogInputRange);
            [varargin,this.AnalogInputChannels]         = util.argkeyval('aiChannels',varargin,this.AnalogInputChannels);
            [varargin,this.AnalogInputChannelNames]     = util.argkeyval('aiNames',varargin,this.AnalogInputChannelNames);
            this.AnalogInputChannels = util.ascell(this.AnalogInputChannels);
            
            % analog output
            [varargin,this.AnalogOutputDeviceName]      = util.argkeyval('aoDeviceName',varargin,this.AnalogOutputDeviceName);
            [varargin,this.AnalogOutputMeasurementType] = util.argkeyval('aoMeasurementType',varargin,this.AnalogOutputMeasurementType);
            [varargin,this.AnalogOutputTerminalConfig]  = util.argkeyval('aoTerminalConfig',varargin,this.AnalogOutputTerminalConfig);
            [varargin,this.AnalogOutputRangeHardware]   = util.argkeyval('aoOutputRangeHardware',varargin,this.AnalogOutputRangeHardware);
            [varargin,this.AnalogOutputRangeActual]     = util.argkeyval('aoOutputRangeActual',varargin,this.AnalogOutputRangeActual);
            [varargin,this.AnalogOutputChannels]        = util.argkeyval('aoChannels',varargin,this.AnalogOutputChannels);
            [varargin,this.AnalogOutputChannelNames]    = util.argkeyval('aoNames',varargin,this.AnalogOutputChannelNames);
            this.AnalogOutputChannels = util.ascell(this.AnalogOutputChannels);
            
            % digital I/O
            [varargin,this.DigitalIODeviceName]         = util.argkeyval('dioDeviceName',varargin,this.DigitalIODeviceName);
            [varargin,this.DigitalIOMeasurementType]    = util.argkeyval('dioMeasurementType',varargin,this.DigitalIOMeasurementType);
            [varargin,this.DigitalIOChannels]           = util.argkeyval('dioChannels',varargin,this.DigitalIOChannels);
            [varargin,this.DigitalIOChannelNames]       = util.argkeyval('dioNames',varargin,this.DigitalIOChannelNames);
            this.DigitalIOChannels = util.ascell(this.DigitalIOChannels);
            
            % miscellaneous
            [varargin,this.SamplingRate]                = util.argkeyval('SamplingRate',varargin,this.SamplingRate);
            [varargin,this.AcquisitionPeriod]           = util.argkeyval('AcquisitionPeriod',varargin,this.AcquisitionPeriod);
            [varargin,this.OutputQueueLength]           = util.argkeyval('OutputQueueLength',varargin,this.OutputQueueLength);
            [varargin,this.SaveDirectory]               = util.argkeyval('savedirectory',varargin,this.SaveDirectory,7);
            [varargin,this.SaveBasename]                = util.argkeyval('savebasename',varargin,this.SaveBasename,8);
            [varargin,this.SessionID]                   = util.argkeyval('sessionid',varargin,datestr(now,'yyyymmdd_HHMMSS'),9);
            [varargin,this.SaveExtension]               = util.argkeyval('saveextension',varargin,this.SaveExtension,7);
            [varargin,this.flagSave]                    = util.argflag('save',varargin,this.flagSave,4);
            [varargin,this.flagPlot]                    = util.argflag('plot',varargin,this.flagPlot,4);
            [varargin,this.flagAnalogInput]             = util.argflag('analoginput',varargin,this.flagAnalogInput);
            [varargin,this.flagAnalogInputRandom]       = util.argflag('random',varargin,this.flagAnalogInputRandom);
            [varargin,this.flagAnalogOutput]            = util.argflag('analogoutput',varargin,this.flagAnalogOutput);
            [varargin,this.flagAnalogOutputRandom]      = util.argflag('random',varargin,this.flagAnalogOutputRandom);
            [varargin,this.flagDigitalIO]               = util.argflag('digitalio',varargin,this.flagDigitalIO);
            [varargin,this.flagMoveFile]                = util.argflag('movefile',varargin,this.flagMoveFile);
            [varargin,this.moveDirectory]               = util.argkeyval('movedirectory',varargin,env.get('output'),7);
            [varargin,this.idString]                    = util.argkeyval('idstring',varargin,'',5);
            
            % make sure no unused inputs
            util.argempty(varargin);
            
            % set up the UDP object
            fcn = @(src,evt)process_udp_data;
            this.hUDP = util.getUDP(this.udpIPAddress,this.udpRemotePort,this.udpLocalPort,'DatagramReceivedFcn',fcn);
            
            % make sure there is a subject set up
            sessiontype = env.get('type');
            switch sessiontype
                case 'PRODUCTION'
                    assert(~isempty(env.get('subject')),'Must set the SUBJECT environment variable');
            end
            
            
            function process_udp_data
                % PROCESSDATAGRAM Process received datagrams
                %
                %   PROCESSDATAGRAM(U,EVT)
                %   Process incoming command messages on the receive
                %   (command) UDP object.
                
                % as long as bytes available, keep processing
                while this.hUDP.BytesAvailable>0
                    
                    % read data from the input buffer
                    data = fread(this.hUDP,this.hUDP.BytesAvailable,'uint8');
                    %assert(mod(length(data),2)==0,'Incompatible received packet length ''%d''',length(data));
                    
                    % process data
                    type = data(1);
                    fprintf('Received UDP data');
                    switch type
                        case NI.MessageType.COMMAND
                            cmd = data(2);
                            payload = data(3:end);
                            switch cmd
                                case NI.Command.INITIALIZE
                                    fprintf('[NI] Received INITIALIZE command\n');
                                    initialize(this);
                                case NI.Command.START
                                    fprintf('[NI] Received START command\n');
                                    start(this);
                                case NI.Command.STOP
                                    fprintf('[NI] Received STOP command\n');
                                    stop(this);
                                case NI.Command.ENABLE_CBMEX
                                    this.enableCBMEX = true;
                                    fprintf('[NI] Received ENABLE_CBMEX command\n');
                                    setNeuralSync(this,true);
                                case NI.Command.DISABLE_CBMEX
                                    this.enableCBMEX = false;
                                    setNeuralSync(this,false);
                                    fprintf('[NI] Received DISABLE_CBMEX command\n');
                                case NI.Command.SET_ID_STRING
                                    str = char(payload);
                                    setIDString(this,str(:)');
                                    fprintf('[NI] Received SET_ID_STRING = ''%s'' command\n',str(:)');
                                case NI.Command.SET_SUBJECT
                                    str = char(payload);
                                    setSubject(this,str(:)');
                                    fprintf('[NI] Received SET_SUBJECT = ''%s'' command\n',str(:)');
                                case NI.Command.EXIT
                                    fprintf('[NI] Received EXIT command\n');
                                    if this.ignoreExitCommand
                                        fprintf('[NI] Ignoring EXIT command\n');
                                    else
                                        t = timer;
                                        t.Name = 'deleteSoundTimer';
                                        t.ExecutionMode = 'singleShot';
                                        t.Period = 1;
                                        %t.TimerFcn = @timerFcn;
                                        t.StopFcn = @stopFcn;
                                        start(t);
                                    end
                                case NI.Command.REQUEST
                                    warning('not implemented yet');
                            end
                        otherwise
                            warning('Invalid MessageType ''%d''',type);
                    end
                end
                %function timerFcn(~,~),delete(this);end % END function timerFcn
                function stopFcn(tmr,~),delete(tmr);end % END function stopFcn
            end % END function processDatagram
            
            % create DAQ session
            if this.flagAnalogInput || this.flagAnalogOutput || this.flagDigitalIO
                this.hSession = daq.createSession('ni');
                this.hSession.IsContinuous = true;
                this.hSession.Rate = this.SamplingRate;
                this.hSession.NotifyWhenDataAvailableExceeds = round(this.AcquisitionPeriod*this.SamplingRate);
                this.hSession.NotifyWhenScansQueuedBelow = round(this.OutputQueueLength*this.SamplingRate);
                
                % set up the event listener
                this.lhEvents.ErrorOccurred = addlistener(this.hSession,'ErrorOccurred',@proc_err);
            end
            
            % set up the analog input
            this.sessionChannelOrder = {};
            if this.flagAnalogInput
                if this.flagAnalogInputRandom
                    
                    % create timer
                    this.hTimer = util.getTimer('fakeDAQTimer',...
                        'Period',       0.05,...
                        'ExecutionMode','fixedDelay',...
                        'BusyMode',     'drop',...
                        'TimerFcn',     @rcv_data);
                else
                    
                    % get the DAQ device
                    [this.hAnalogInputDevice,this.AnalogInputDeviceName] = get_daq_device(this,this.AnalogInputDeviceName);
                    
                    % set up analog input channels
                    this.hAnalogInputChannel = cell(1,length(this.AnalogInputChannels));
                    for kk=1:length(this.AnalogInputChannels)
                        this.hAnalogInputChannel{kk} = addAnalogInputChannel(this.hSession,this.AnalogInputDeviceName,this.AnalogInputChannels{kk},this.AnalogInputMeasurementType);
                        this.hAnalogInputChannel{kk}.TerminalConfig = this.AnalogInputTerminalConfig;
                        this.hAnalogInputChannel{kk}.Range = this.AnalogInputRange;
                        this.sessionChannelOrder = [this.sessionChannelOrder {'AnalogInput'}];
                    end
                    this.numAnalogInputChannels = this.numAnalogInputChannels + length(this.AnalogInputChannels);
                    
                    % set up the event listener
                    this.lhEvents.DataAvailable = addlistener(this.hSession,'DataAvailable',@rcv_data);
                end
            end
            
            % set up the analog output DAQ device
            if this.flagAnalogOutput
                
                % get the DAQ device
                [this.hAnalogOutputDevice,this.AnalogOutputDeviceName] = get_daq_device(this,this.AnalogOutputDeviceName);
                
                % set up analog output channels
                this.hAnalogOutputChannel = cell(1,length(this.AnalogOutputChannels));
                for kk=1:length(this.AnalogOutputChannels)
                    this.hAnalogOutputChannel{kk} = addAnalogOutputChannel(this.hSession,this.AnalogOutputDeviceName,this.AnalogOutputChannels{kk},this.AnalogOutputMeasurementType);
                    this.hAnalogOutputChannel{kk}.TerminalConfig = this.AnalogOutputTerminalConfig;
                    this.hAnalogOutputChannel{kk}.Range = this.AnalogOutputRangeHardware;
                    this.sessionChannelOrder = [this.sessionChannelOrder {'AnalogOutput'}];
                end
                this.numAnalogOutputChannels = this.numAnalogOutputChannels + length(this.AnalogOutputChannels);
                
                % set up the event listener
                this.lhEvents.DataRequired = addlistener(this.hSession,'DataRequired',@queue_data);
            end
            
            % set up the digital IO DAQ device
            if this.flagDigitalIO
                [this.hDigitalIODevice,this.DigitalIODeviceName] = get_daq_device(this,this.DigitalIODeviceName); % get dio device
                
                % set up digital IO channels
                this.hDigitalChannel = cell(1,length(this.DigitalIOChannels));
                for kk=1:length(this.DigitalIOChannels)
                    this.hDigitalChannel{kk} = addDigitalChannel(this.hSession,this.DigitalIODeviceName,this.DigitalIOChannels{kk},this.DigitalIOMeasurementType);
                    if strcmpi(this.DigitalIOMeasurementType,'InputOnly')
                        this.numDigitalInputChannels = this.numDigitalInputChannels + 1;
                        this.sessionChannelOrder = [this.sessionChannelOrder {'DigitalInput'}];
                    elseif strcmpi(this.DigitalIOMeasurementType,'OutputOnly')
                        this.numDigitalOutputChannels = this.numDigitalOutputChannels + 1;
                        this.sessionChannelOrder = [this.sessionChannelOrder {'DigitalOutput'}];
                    elseif strcmpi(this.DigitalIOMeasurementTYpe,'Bidirectional')
                        this.numDigitalBidirectionalChannels = this.numDigitalBidirectionalChannels + 1;
                        this.sessionChannelOrder = [this.sessionChannelOrder {'DigitalBidirectional'}];
                    else
                        error('Unknown digital IO measurement type ''%s''',this.DigitalIOMeasurementType);
                    end
                end
            end
            
            % sub functions to process, save, plot the data
            function rcv_data(~,event)
                [~,m] = this.data.DataBuffer.size;
                stats = [toc(this.stats.tmr) size(event.Data,1) double(this.hSession.ScansQueued) m];
                this.stats.rcv.add(stats);
                fprintf('rcv -- %5.2f -- %5d avail -- %5d queued -- %5d buffer\n',stats(1),stats(2),stats(3),stats(4));
                
                % generate random data if requested
                if this.flagAnalogInputRandom
                    event.TimeStamps = this.currRandTimestamp + (0:(1/this.SamplingRate):(this.samplesPerInterrupt/this.SamplingRate-1/this.SamplingRate));
                    event.Data = nan(this.samplesPerInterrupt,length(this.AnalogInputChannels));
                    for nn=1:size(event.Data,2)
                        event.Data(:,nn) = nn*sin(nn*event.TimeStamps+nn);
                    end
                    this.currRandTimestamp = event.TimeStamps(end)+1/this.SamplingRate;
                end
                
                % buffer the data for later queueing into output scans
                dt = event_to_buffer(this,event);
                this.data.DataBuffer.add(dt);
                
                % the data required event only runs once when the queue
                % falls below the threshold, and if data are not added that
                % one time it will never run again -- meaning there will
                % eventually be a buffer underrun error. here, we test for
                % the size of the output queue and if it's less than the
                % number of samples in the buffer, we'll call the
                % queue_data function
                if this.flagAnalogOutput && this.hSession.ScansQueued<0.8*size(this.data.DataBuffer,2)
                    fprintf('calling queue_data\n');
                    queue_data(1,1);
                end
                
                % plot the data if requested
                if this.flagPlot
                    try plot_data(event); catch ME, util.errorMessage(ME); end
                end
                
                % write to disk if requested
                if this.flagSave
                    try save_data(event); catch ME, util.errorMessage(ME); end
                end
            end % END function rcv_data
            
            function queue_data(~,~)
                [~,m] = this.data.DataBuffer.size;
                stats = [toc(this.stats.tmr) 0 double(this.hSession.ScansQueued) m];
                this.stats.queue.add(stats);
                fprintf('que -- -- %5.2f -- %5d avail -- %5d queued -- %5d buffer\n',stats(1),stats(2),stats(3),stats(4));
                
                % get source data
                if this.flagAnalogOutputRandom
                    
                    % generate random data
                    src_data = randn(round(this.AcquisitionPeriod*this.SamplingRate),this.numAnalogOutputChannels);
                else
                    
                    % grab data from the incoming buffer
                    src_data = this.data.DataBuffer.get;
                end
                if isempty(src_data)
                    warning('No data available to queue for output');
                    return;
                end
                
                % transpose, scale, etc.
                num_channels = this.numAnalogInputChannels+this.numDigitalInputChannels+this.numDigitalBidirectionalChannels;
                dt = prepare_data_for_queue(this,src_data,num_channels,this.AnalogInputRange,this.AnalogOutputRangeActual);
                
                % queue the data
                try queueOutputData(this.hSession,dt); catch ME, util.errorMessage(ME); end
            end % END function queue_data
            
            function proc_err(src,event)
                util.errorMessage(event.Error);
            end % END function proc_err
            
            function save_data(event)
                numSamples = size(event.Data,1);
                
                % SECTION DEFINITION
                % bytes     contents        class
                % 1-4       num samples     uint32
                % 5-8       timestamp       single
                % 9-?       data            (custom)
                len = typecast(cast(numSamples,'uint32'),'uint8');
                t = typecast(cast(event.TimeStamps(1),'single'),'uint8');
                x = event.Data;
                n = this.numAnalogInputChannels+this.numDigitalInputChannels+this.numDigitalBidirectionalChannels;
                if size(x,1)~=n,x=x';end
                assert(size(x,1)==n,'Incorrect number of channels: found %d, but expected %d',size(x,1),n);
                x = x(:)'; % [channels x samples] --> [ch1s1 ch2s1 ... ch1s2 ch2s2 ... etc.]
                x = typecast(cast(x,this.DataClass),'uint8');
                data_bytes = [len t x];
                fwrite(this.fid,data_bytes);
            end % END function save_data
            
            function plot_data(event)
                
                % plot new data
                if isfield(this.gui,'hLine')
                    
                    % if plot exists, update xdata/ydata (faster)
                    for nn=1:length(this.gui.hLine)
                        set(this.gui.hLine(nn),'XData',event.TimeStamps/this.SamplingRate,'YData',event.Data(:,nn));
                    end
                else
                    
                    % create new plot
                    this.gui.hLine = plot(this.gui.hAxes,event.TimeStamps/this.SamplingRate,event.Data);
                    set(this.gui.hAxes,'YLim',[-10 10]);
                    xlabel('Time (sec)');
                    ylabel('Amplitude (V)');
                    legend(this.AnalogInputChannelNames);
                end
            end % END function plot_data
        end % END function Interface
        
        function initialize(~)
            % INITIALIZE Initialize the Server object
            %
            %   INITIALIZE(THIS)
            %   This function serves no purpose in the Server class.
            
        end % END function initialize
        
        function dt = event_to_buffer(this,event)
            idx_inputs = ismember(this.sessionChannelOrder,{'AnalogInput','DigitalInput','DigitalBidirectional'});
            idx_ai = strcmpi(this.sessionChannelOrder(idx_inputs),'AnalogInput');
            idx_di = strcmpi(this.sessionChannelOrder(idx_inputs),'DigitalInput');
            dt = event.Data(:,idx_ai|idx_di)';
        end % END function event_to_buffer
        
        function dt = prepare_data_for_queue(this,dt,n,range_input,range_output)
            if nargin<3||isempty(n),n=this.numAnalogOutputChannels;end
            if nargin<4||isempty(range_input),range_input=this.AnalogInputRange;end
            if nargin<5||isempty(range_output),range_output=this.AnalogOutputRangeActual;end
            
            % handle the corner case of empty incoming data
            if isempty(dt),return;end
            
            % transpose if necessary to get data in correct orientation
            if size(dt,2)~=n,dt=dt';end
            assert(size(dt,2)==n,'Incorrect number of channels: found %d, but expected %d',size(dt,2),n);
            
            % scale the data to the effective output range
            dt = (dt - range_input(1))/diff(range_input); % normalize to approx [0,1]
            dt = dt*diff(range_output) + range_output(1); % expand back to output range
            
            % rail the data to the outputput max/min
            dt = nanmax(range_output(1),dt);
            dt = nanmin(range_output(2),dt);
        end % END function prepare_data_for_queue
        
        function [dev,devname] = get_daq_device(this,devname)
            
            % get the DAQ device
            dev = daq.getDevices;
            if all(isprop(dev,'ID'))
                idprop = 'ID';
            elseif all(isprop(dev,'DeviceID'))
                idprop = 'DeviceID';
            else
                error('Could not identify property to use for matching against requested device ID string (no ''ID'' or ''DeviceID'' properties)');
            end
            idx_found = false(size(dev));
            for dd=1:length(dev)
                idx = regexpi(dev(dd).(idprop),devname);
                idx_found(dd) = ~isempty(idx);
            end
            assert(any(idx_found),'Could not find requested device ''%s''',devname);
            assert(nnz(idx_found)==1,'Fou nd %d devices matching the device name ''%s''',nnz(idx_found),this.AnalogInputDeviceName);
            
            % update outputs
            dev = dev(idx_found);
            devname = dev.(idprop);
        end % END function get_daq_device
        
        function start(this,varargin)
            [varargin,this.RunID] = util.argkeyval('runid',varargin,datestr(now,'HHMMSS'),5);
            util.argempty(varargin);
            
            % performance stats
            this.stats.tmr = tic;
            this.stats.rcv = Buffer.Dynamic('r');
            this.stats.queue = Buffer.Dynamic('r');
            
            % validate file settings
            if this.flagSave
                if ~isempty(this.idString)
                    this.outfile = fullfile(this.SaveDirectory,sprintf('%s_%s_%s%s',this.SaveBasename,this.SessionID,this.RunID,this.SaveExtension));
                else
                    if ~isdir(fullfile(this.SaveDirectory,upper(env.get('subject')),this.SessionID)); mkdir(fullfile(this.SaveDirectory,upper(env.get('subject')),this.SessionID)); end
                    this.outfile = fullfile(this.SaveDirectory,upper(env.get('subject')),this.SessionID,sprintf('%s%s',this.idString,this.SaveExtension));
                end
                assert(exist(this.outfile,'file')~=2,'Output file ''%s'' already exists',this.outfile);
                
                % flat that there will be a new file to move
                this.movedFile = false;
                
                % open file for writing
                if ~this.openFile
                    open_file(this);
                end
            end
            
            % create the figure
            if this.flagPlot && ~this.openPlot
                open_gui(this);
            end
            
            % remove old buffers if they exist
            if isfield(this.data,'Samples')
                try delete(this.data.DataBuffer); catch ME, util.errorMessage(ME); end
            end
            
            % create buffers to queue data between read/write
            this.data.DataBuffer = Buffer.FIFO(5*this.SamplingRate);
            
            % queue up initial output data
            if this.flagAnalogOutput
                this.hSession.queueOutputData(zeros(round(2*this.OutputQueueLength*this.SamplingRate),this.numAnalogOutputChannels));
            end
            
            % start the session
            if this.flagAnalogInputRandom
                start(this.hTimer);
            else
                this.hSession.startBackground;
            end
            this.openSession = true;
        end % END function start
        
        function stop(this)
            
            % stop the session
            if this.openSession
                if this.flagAnalogInputRandom
                    stop(this.hTimer)
                else
                    this.hSession.stop;
                end
                this.openSession = false;
            end
            
            % collect performance statistics
            if ~isempty(this.stats)
                this.stats.toc = [];
                if isa(this.stats.rcv,'Buffer.Dynamic')
                    this.stats.rcv = this.stats.rcv.get;
                end
                if isa(this.stats.queue,'Buffer.Dynamic')
                    this.stats.queue = this.stats.queue.get;
                end
            end
            
            % close the GUI
            if this.flagPlot && this.openPlot
                try close_gui(this); catch ME, util.errorMessage(ME); end
            end
            
            % close output file
            if this.flagSave && this.openFile
                try close_file(this); catch ME, util.errorMessage(ME); end
            end
            
            % move the file from SAVEDIRECTORY to MOVEDIRECTORY
            if this.flagMoveFile
                trymax = 5; cc = 1;
                if ~this.movedFile
                    if ~isdir(fullfile(this.moveDirectory,upper(env.get('subject')),this.SessionID)); mkdir(fullfile(this.moveDirectory,upper(env.get('subject')),this.SessionID)); end
                    mvfile = fullfile(this.moveDirectory,upper(env.get('subject')),this.SessionID,'Task',sprintf('%s%s',this.idString,this.SaveExtension));
                    [status,msg] = movefile(this.outfile,mvfile);
                    while ~status && cc <= trymax
                        [status,msg] = movefile(this.outfile,mvfile);
                        cc = cc + 1;
                        pause(0.5);
                    end
                    if ~status; warning('Error when moving %s file to %s, due to %s',this.outfile,mvfile,msg); end
                    this.movedFile = true;
                end
            end
        end % END function stop
        
        function open_gui(this)
            
            % open the figure, create axes
            this.gui.hFigure = figure;
            this.gui.hAxes = axes('Parent',this.gui.hFigure);
            this.openPlot = true;
        end % END function open_gui
        
        function close_gui(this)
            
            % close the figure
            close(this.gui.hFigure);
            this.gui = [];
            this.openPlot = false;
        end % END function close_gui
        
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
        
        function open_file(this,flagOverwrite)
            numChannels = this.numAnalogInputChannels+this.numDigitalInputChannels+this.numDigitalBidirectionalChannels;
            if nargin<2||isempty(flagOverwrite),flagOverwrite=false;end
            
            % check whether exists already
            assert(~flagOverwrite||exist(this.outfile,'file')~=2,'File ''%s'' already exists',this.outfile);
            
            % open the file for writing
            [this.fid,errmsg] = fopen(this.outfile,'w');
            assert(this.fid>0,'Could not open output file ''%s'' for writing: %s',this.outfile,errmsg);
            this.openFile = true;
            
            % write header information into the file
            % HEADER DEFINITION
            % bytes     contents            class
            % 1-4       sampling rate       uint32
            % 5-6       num channels        uint16
            % 7         bytes per sample    uint8
            % 8         is floating point?  uint8
            % 9         is signed?          uint8
            fs = typecast(cast(this.SamplingRate,'uint32'),'uint8');
            nc = typecast(cast(numChannels,'uint16'),'uint8');
            switch lower(this.DataClass)
                case 'single',bps = cast(4,'uint8');
                case 'double',bps = cast(8,'uint8');
                otherwise
                    error('Unknown data class ''%s''',this.DataClass);
            end
            if any(strcmpi(this.DataClass,{'single','double'}))
                isfp = true;
                issigned = true;
            else
                isfp = false;
                if this.DataClass(1)=='u'
                    issigned = false;
                else
                    issigned = true;
                end
            end
            isfp = cast(isfp,'uint8');
            issigned = cast(issigned,'uint8');
            header_bytes = typecast([fs(:); nc(:); bps; isfp; issigned],'uint8');
            fwrite(this.fid,header_bytes);
        end % END function open_file
        
        function close_file(this)
            
            % close the file
            fclose(this.fid);
            this.openFile = false;
        end % END function close_file
        
        function st = toStruct(this,varargin)
            skip = {'hSession','hAnalogInputDevice','hAnalogOutputDevice','hDigitalIODevice',...
                'hAnalogInputChannel','hAnalogOutputChannel','hDigitalChannel'};
            st = toStruct@util.Structable(this,skip{:});
            st.stats.rcv = this.stats.rcv;
            st.stats.queue = this.stats.queue;
        end % END function toStruct
        
        function delete(this)
            stop(this);
            
            % delete the session
            if this.openSession
                if this.flagAnalogInputRandom
                    try delete(this.hTimer); catch ME, util.errorMessage(ME); end
                else
                    try delete(this.hSession); catch ME, util.errorMessage(ME); end
                end
            end
            
            % close the GUI
            if this.flagPlot && this.openPlot
                try close_gui(this); catch ME, util.errorMessage(ME); end
            end
            
            % close the file
            if this.flagSave && this.openFile
                try close_file(this); catch ME, util.errorMessage(ME); end
            end
            
            % delete event listener handles
            if ~this.flagAnalogInputRandom
                listenerNames = fieldnames(this.lhEvents);
                for kk=1:length(listenerNames)
                    try delete(this.lhEvents.(listenerNames{kk})); catch ME, util.errorMessage(ME); end
                end
            end
            
            % close the UDP communication 
             try util.deleteUDP(this.hUDP); catch ME, util.errorMessage(ME); end
        end % END function delete
    end % END methods
    
    methods(Static)
        function reportSessionInfo(s)
            fprintf('\n\n');
            fprintf('Running? %d\n',s.IsRunning);
            fprintf('Done? %d\n',s.IsDone);
            fprintf('Data Available Notified:   %d\n',s.NotifyWhenDataAvailableExceeds);
            fprintf('Scans Queued Below:        %d\n',s.NotifyWhenScansQueuedBelow);
            fprintf('Scans Queued:              %d\n',s.ScansQueued);
            fprintf('Scans Output By Hardware:  %d\n',s.ScansOutputByHardware);
            fprintf('Scans Acquired:            %d\n',s.ScansAcquired);
        end % END function reportSessionInfo
        
        function listDevices
            d = daq.getDevices;
            if isempty(d),return;end
            fprintf('\n');
            for kk=1:length(d)
                fprintf('Device %d. %s (%s)\n',kk,d(kk).Description,d(kk).ID);
                for nn=1:length(d(kk).Subsystems)
                    fprintf('\tSubsystem %d. %s\n',nn,d(kk).Subsystems(nn).SubsystemType);
                    for mm=1:length(d(kk).Subsystems(nn).ChannelNames)
                        fprintf('\t\tChannel %d. %s\n',mm,d(kk).Subsystems(nn).ChannelNames{mm});
                    end
                end
            end
            fprintf('\n');
            fprintf(...
                ['Use the device ID (in parentheses above) as an input when constructing\n'...
                 'the NI.Interface object:\n'...
                 '\n'...
                 '    NI.Interface(''aiDeviceName'',AI_ID_STRING,...\n'...
                 '                 ''aoDeviceName'',AO_ID_STRING,...\n'...
                 '                 ''dioDeviceName'',DIO_ID_STRING);\n'...
                 '\n'...
                 'Specify the channels using the channel names above:\n'...
                 '\n'...
                 '    NI.Interface(''aiChannels'',{CH1_STRING,CH2_STRING,...},...\n'...
                 '                 ''aoChannels'',{CH1_STRING,CH2_STRING,...},...\n'...
                 '                 ''dioChannels'',{CH1_STRING,CH2_STRING,...});\n'...
                 '\n']);
        end % END function listDevices
    end % END methods(Static)
end % END classdef Interface