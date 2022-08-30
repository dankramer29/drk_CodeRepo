classdef Server < handle & util.Structable & util.StructableHierarchy
    
    properties
        sounds
        pahandle
        soundBuffer
        soundDirectory
        
        audioDevice     = [];
        freq            = 44100;
        nchannels       = 2;
        runMode         = 1;
        
        % default UDP parameters
        ipAddress = '192.168.100.75';
        hSend
        hReceive
        sndRemotePort = 4030+8;
        sndLocalPort = 4031+8;
        rcvRemotePort = 4032+8;
        rcvLocalPort = 4033+8;
        
        debug
        verbosity
    end
    
    methods
        function set.soundDirectory(this,val)
            assert(exist(val,'dir')==7,'Sound:Error','Directory ''%s'' does not exist',val);
            this.soundDirectory=val;
        end % END function set.soundDirectory
        
        function this = Server(varargin)
            
            % set sound directory
            this.soundDirectory = fullfile(env.get('media'),'sound');
            
            % load debug/verbosity HST env vars
            [this.debug,this.verbosity] = env.get('debug','verbosity');
            
            % process remaining user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % Perform basic initialization of the sound driver:
            InitializePsychSound;
            
            % Open the audio device
            if isempty(this.audioDevice)
                % Open the default audio device [], with default mode [] (==Only playback),
                % and a required latencyclass of 1 == standard low-latency mode, as well as
                % a playback frequency of 'freq' and 'nrchannels' sound output channels.
                % This returns a handle 'pahandle' to the audio device:
                this.pahandle = PsychPortAudio('Open', [], [], 1, this.freq, this.nchannels);
            else
                this.pahandle = PsychPortAudio('Open', this.audioDevice, [], 1, this.freq, this.nchannels);
            end
            
            % runMode 1 will slightly increase the cpu load and general system load,
            % but provide better timing and even lower sound onset latencies under
            % certain conditions. Type PsychPortAudio RunMode? for more details...
            PsychPortAudio('RunMode', this.pahandle, this.runMode);
            
            % Enable use of sound schedules: default size 128 slots by default. From
            % now on, the driver will not play back the sounds stored via
            % PsychPortAudio('FillBuffer') anymore. Instead define a "playlist" or
            % schedule via subsequent calls to PsychPortAudio('AddToSchedule'). Then
            % the driver will process that schedule by playing all defined sounds in
            % the schedule, one after each other, until the end of the schedule is
            % reached. You can add new items to the schedule while the schedule is
            % already playing.
            PsychPortAudio('UseSchedule', this.pahandle, 1);
            
            % create receive UDP object
            this.hReceive = util.getUDP(this.ipAddress,this.rcvRemotePort,this.rcvLocalPort,...
                'InputBufferSize',4096,'Name','SoundServer-rcv',...
                'DatagramReceivedFcn',{@Sound.Server.processDatagram,this});
            
            % create send UDP object
            this.hSend = util.getUDP(this.ipAddress,this.sndRemotePort,this.sndLocalPort,...
                'OutputBufferSize',4096,'Name','SoundServer-snd');
        end
        
        function register(this,name,file)
            comment(this,sprintf('Register ''%s'' / ''%s''',name,file),2);
            
            % create full path to file
            s.name = name;
            [locDir,locBase,locExt] = fileparts(file);
            s.fullfile = fullfile(this.soundDirectory,locDir,[locBase locExt]);
            assert(exist(s.fullfile,'file')==2,'Cannot find file ''%s''',s.fullfile);
            
            % read the file
            try
                [audiodata, infreq] = audioread(s.fullfile);
            catch ME
                util.errorMessage(ME);
                return;
            end
            
            % resample
            if infreq ~= this.freq
                audiodata = resample(audiodata, this.freq, infreq);
            end
            [~, ninchannels] = size(audiodata);
            audiodata = repmat(transpose(audiodata), this.nchannels / ninchannels, 1);
            
            % same file can be referenced by different names, but new
            % registration with same name as existing entry will overwrite
            % existing entry
            idx = length(this.sounds)+1;
            for k=1:length(this.sounds)
                if strcmpi(this.sounds(k).name,s.name)
                    idx = k;
                end
            end
            
            % save
            if isempty(this.sounds)
                this.sounds = s;
            else
                this.sounds(idx) = s;
            end
            this.soundBuffer(idx) = PsychPortAudio('CreateBuffer', [], audiodata);
        end % END function register
        
        function Play(this,soundName)
            play(this,soundName);
        end % END function Play
        
        function play(this,soundName)
            comment(this,sprintf('play ''%s''',soundName),2);
            
            % get the sound index
            [registered,soundIdx] = isRegistered(this,soundName);
            if ~registered
                warning('Invalid sound ''%s''',soundName);
                return;
            end
            
            % get the audio status
            s = PsychPortAudio('GetStatus', this.pahandle);
            
            % Engine still running on a schedule?
            if s.Active == 0
                
                % Schedule finished, engine stopped. Before adding new
                % slots we first must delete the old ones, ie., reset the
                % schedule:
                PsychPortAudio('UseSchedule', this.pahandle, 2);
            end
            PsychPortAudio('AddToSchedule', this.pahandle, this.soundBuffer(soundIdx), 1, 0, [], 1);
            
            % If engine has stopped, we need to restart:
            if s.Active == 0
                PsychPortAudio('Start', this.pahandle, [], 0, 1);
            end
        end % END function play
        
        function [registered,soundIdx] = isRegistered(this,soundName)
            
            % check for numerical indices
            if isnumeric(soundName)
                idx = soundName;
                assert(length(idx)==1,'Multiple sounds not supported');
                assert(idx<=length(this.sounds),'Invalid index %d (valid range 1-%d)',idx,length(this.sounds));
                soundName = this.sounds(idx).name;
            end
            
            % make sure valid sound
            soundIdx = ismember({this.sounds.name},soundName);
            registered = any(soundIdx);
        end % END function isRegistered
        
        function comment(this,msg,vb)
            if nargin<3,vb=1;end
            if vb<=this.verbosity,fprintf('%s\n',msg);end
        end % END function comment
        
        % clean up UDP objects
        function delete(this)
            
            % clean up the UDP objects
            try util.deleteUDP(this.hReceive); catch ME, util.errorMessage(ME); end
            try util.deleteUDP(this.hSend);    catch ME, util.errorMessage(ME); end
            
            % clean up psych audio resources
            try
                %PsychPortAudio('UseSchedule', this.pahandle, 0);
                PsychPortAudio('Stop', this.pahandle, 1);
                PsychPortAudio('DeleteBuffer');
                PsychPortAudio('Close');
            catch ME
                util.errorMessage(ME);
            end
        end % END function delete
        
        function list = structableSkipFields(this)
            list = {'hSend','hReceive','pahandle','soundBuffer'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
        end % END function structableManualFields
        
    end % END methods
    
    methods(Static)
        function listAudioDevices
            InitializePsychSound;
            devices = PsychPortAudio('GetDevices');
            for kk=1:length(devices)
                fprintf('%s\n\t* Device %d\n\t* API %s\n',devices(kk).DeviceName,devices(kk).DeviceIndex,devices(kk).HostAudioAPIName);
            end
        end % END function listDevices
        
        % process datagrams received
        function processDatagram(~,~,s)
            while s.hReceive.BytesAvailable>0
                data = fread(s.hReceive,s.hReceive.BytesAvailable,'uint8');
                cmd = data(1);
                switch cmd
                    case uint8(Sound.Command.PLAY)
                        name = data(2:end);
                        name = char(name(:)');
                        try play(s,name); catch ME, util.errorMessage(ME); end
                    case uint8(Sound.Command.REGISTER)
                        str = data(2:end);
                        str = char(str(:)');
                        commaIdx = strfind(str,',');
                        name = str(1:commaIdx-1);
                        filepath = str(commaIdx+1:end);
                        try register(s,name,filepath); catch ME, util.errorMessage(ME); end
                    case uint8(Sound.Command.GET)
                        str = data(2:end);
                        str = char(str(:)');
                        proplist = properties(s);
                        idx = find(strcmpi(proplist,str),1);
                        if isempty(idx)
                            warning('Cannot find property ''%s''',str);
                        else
                            fwrite(s.hSend,uint8(s.(str)),'uint8');
                        end
                    case uint8(Sound.Command.SET)
                        str = data(2:end);
                        str = str(:)';
                        commaIdx = strfind(str,',');
                        name = str(1:commaIdx-1);
                        val = str(commaIdx+1:end);
                        if ~isprop(this,name)
                            warning('Cannot find property ''%s''',name);
                        else
                            switch lower(name)
                                case {'sounddirectory','ipaddress'}
                                    this.(name) = char(val);
                                case {'freq','nchannels','sndremoteport','sndlocalport','rcvremoteport','rcvlocalport'}
                                    this.(name) = double(val);
                            end
                        end
                    case uint8(Sound.Command.STOP)
                        t = timer;
                        t.Name = 'deleteSoundTimer';
                        t.ExecutionMode = 'singleShot';
                        t.Period = 1;
                        t.TimerFcn = @(t,evt)delete(s);
                        t.StopFcn = @(t,evt)delete(t);
                        start(t);
                end
            end
        end % END function processDatagram
    end % END methods(Static)
end % END classdef Server