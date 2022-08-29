classdef PupilNetwork < handle & Framework.EyeTracker.Interface & util.Structable & util.StructableHierarchy
    
    properties
        hUDP % handle to Pupil Network UDP
    end % END properties
    
    properties(SetAccess='private')
        isConnected = false
        isRecording = false
        isOpen = false
        
        isRemoteConnected = false
        
        % python libraries added to MATLAB
        zmq
        zmqM
        socket
        
    end % END properties(SetAccess='private')
    
    properties
        remoteIP = ''
        remotePort = '50020'
    end
    
    properties(Constant)
        isSimulated = false;
    end % END properties(Constant)
    
    methods
        function this = PupilNetwork(fw,cfg,varargin)
            this = this@Framework.EyeTracker.Interface(fw);
            
            % configure
            feval(cfg{1},this,cfg{2:end});
            
            % construct the pupil UDP
            this.hUDP = udp('127.0.0.1','LocalPort',8821,'Timeout',0.5);
            % this.hUDP = udp('192.168.100.74','LocalPort',8821);
        end % END function Pupil
        
        function initialize(this)
            fopen(this.hUDP);
            this.isOpen = true;
            
            tic; tst = fread(this.hUDP); elapsed=toc;
            if elapsed>=(this.hFramework.options.timerPeriod+1)
                fprintf('entered elapsed if statement\n');
                comment(this,sprintf('Timeout for PupilNetwork UDP (%.2f sec): disabling EyeTracker',elapsed),3);
                fclose(this.hUDP);
                this.isOpen = false;
            else
                if isempty(tst)
                    this.isConnected = false;
                    fprintf('UDP received and empty SETTING TO FALSE\n\n\n')
                else                
                this.isConnected = true;
                fprintf('UDP received no timeout pythonUDP connected\n')
                end
            end
            
            if this.isConnected
                % import python packages
                this.zmq = py.importlib.import_module('zmq');
                this.zmqM = py.importlib.import_module('zmq.utils.monitor');
                %             this.msgpack = py.importlib.import_module('msgpack');
                
                % this must be run before running Requester
                context = this.zmq.Context();
                remAddress = sprintf('tcp://%s:%s', this.remoteIP, this.remotePort);
                
                % Requester Initialize
                this.socket = this.zmq.Socket(context, this.zmq.REQ);
                
                % connect and block node
                
                block_until_connected = 1;
                if block_until_connected == 1
                    monitor = this.socket.get_monitor_socket();
                    this.socket.connect(remAddress)
                    for attempt = 1:5
                        status = this.zmqM.recv_monitor_message(monitor);
                        if double(status{'event'}) == this.zmq.EVENT_CONNECTED
                            comment(this,sprintf('Pupil Remote: Event Connected\n'),3)
                            break
                        elseif double(status{'event'}) == this.zmq.EVENT_CONNECT_DELAYED
                            comment(this,sprintf('Trying to connect to Pupil Remote again: Attempt %d\n', attempt),3)
                        else
                            comment(this,sprintf('ZMQ Connection Failed: Attempt %d\n', attempt),3)
                        end
                    end
                    this.socket.disable_monitor();
                    this.isRemoteConnected = true;
                else
                    this.socket.connect(remAddress);
                    comment(this,sprintf('Pupil Remote connection NOT tested...check ip and port\nIP: %s\nPort: %s\n',this.remoteIP,this.remotePort))
                end
            else
                comment(this,...
                    sprintf('PupilRemote NOT initialized: UDP messesages from external python NOT received'),0);
            end
            
        end % END function initialize
        
        function startRecording(this,varargin)
            if ~this.isRemoteConnected,return;end
            
            % set timebase of pupil to 0
            cmd = 'T 0.0';
            this.socket.send_string(cmd);
            zMsgRecv = char(this.socket.recv_string());
            comment(this,sprintf('Sent command %s and received %s\n',cmd, zMsgRecv),3);
            
            % uncomment this line for Rancho
            % filePathName = ['/media/test/' this.hFramework.runtime.baseFilename];
            filePathName = this.hFramework.runtime.baseFilename;
            cmd = ['R', ' ', filePathName]; % edit this so file name matches what Framework defines tasks as
            this.socket.send_string(cmd)
            zMsgRecv = char(this.socket.recv_string());
            comment(this,sprintf('Sent command %s and received %s\n',cmd, zMsgRecv),3);
            
            % set isRecording property to true
            this.isRecording = true;
        end % END function startRecording
        
        function stopRecording(this)
            if ~this.isRemoteConnected,return;end
            
            cmd = 'r';
            this.socket.send_string(cmd)
            zMsgRecv = char(this.socket.recv_string());
            comment(this,sprintf('Sent command %s and received %s\n',cmd, zMsgRecv),3);
            
            % set isRecording property to false
            this.isRecording = false;
        end % END function stopRecording
        
        function setTime(this,varargin)
        end % END function setTime
        
        function t = getTime(this,varargin)
            t = nan;
        end % END function getTime
        
        function [pupil_vals] = read(this)
            
            %process the packet from SURFACE Subscribe for Timeout
            pupil_vals.gazePosition = NaN([1,2],'single');
            pupil_vals.gazeConfidence = NaN(1,'single');
            pupil_vals.gazeTime = NaN(1,'single');
            pupil_vals.gazeOnSurface = NaN(1,'single');
            pupil_vals.pupilDiam = NaN(1,'single');
            pupil_vals.pupilDiamTime = NaN(1,'single');
            
            % return early if not connected
            if ~this.isConnected,return;end
            
            % get data
            pkt = nan;
            num_iter = 0;
            max_iter = 20;
            while all(isnan(pkt)) && num_iter<max_iter
                tic; data = cast(fread(this.hUDP), 'uint8'); elapsed=toc;
                if elapsed>=this.hFramework.options.timerPeriod
                    warning('Elapsed time was %.2f',elapsed);
                    break;
                end
                num_iter = num_iter + 1;
                
                % split the data up into packets
                pktbyte = 0;
                while pktbyte < length(data)
                    % read out the number of bytes in the packet:
                    % 2 accounts for:
                    % 1st byte payload length
                    % and last byte checksum
                    pktlen = cast(data(1),'single');
                    
                    % make sure we read sufficient data for the packet
                    if pktbyte+pktlen > length(data)
                        comment(this,sprintf('Bad packet: expected %d bytes but found %d',pktlen,length(data)),0);
                        break;
                    end
                    
                    % pull out bytes for this packet
                    pkt = data(pktbyte+(1:pktlen));
                    
                    pktID = pkt(2);
                    pkt(2) = [];
                    % validate the checksum calculated just based off payload
                    if pkt(end) ~= mod(sum(double(pkt(2:end-1))),256)
                        
                        % invalid checksum, kill this packet
                        comment(this,'Invalid checksum!',0);
                        pkt = nan;
                    end
                    
                    % increment byte counter
                    pktbyte = pktbyte + pktlen + 1;
                end
            end
            
            % remove unused pkt entries and check for remaining
            if isnan(pkt)
                comment(this,'No valid packets received',0);
                pktID = 3;
                % return;
            end
            
            switch pktID
                case 0
                    % process the packet from gaze Subscribe
                    pupil_vals.gazePosition = typecast(pkt(2:9),'single');
                    pupil_vals.gazeConfidence = typecast(pkt(10:13),'single');
                    pupil_vals.gazeTime = typecast(pkt(14:17),'single');
                case 1
                    % process the packet from SURFACE Subscribe
                    pupil_vals.gazePosition = (typecast(pkt(2:9),'single'))';
                    pupil_vals.gazeConfidence = typecast(pkt(10:13),'single');
                    pupil_vals.gazeTime = typecast(pkt(14:17),'single');
                    pupil_vals.gazeOnSurface = typecast(pkt(18:21),'single');
                    pupil_vals.pupilDiam = typecast(pkt(22:25),'single');
                    pupil_vals.pupilDiamTime = typecast(pkt(26:29),'single');
                    comment(this,sprintf('Surface Received'),0)
                case 3
                    % default value: all NaNs
                otherwise
                    comment(this,sprintf('ERROR NO PACKETID RECEIVED\n'),0)
            end % END of switch pktID
            %             fprintf('test.\n')
            comment(this,sprintf('Eye tracking data: [%.2f, %.2f], %.2f',pupil_vals.gazePosition(1),...
                pupil_vals.gazePosition(2),pupil_vals.gazeConfidence),0);
            
            %             sprintf('size');
            [r,c] = size(pupil_vals.gazePosition);
            if r == 2 && c == 1
                pupil_vals.gazePosition = pupil_vals.gazePosition';
                %                 warning('had to invert');
                %                 sprintf('%d x %d',r,c);
            end
            %             size(pupil_vals.gazeConfidence)
            
            fclose(this.hUDP);
            fopen(this.hUDP);
        end % END function read
        
        function close(this)
            try util.deleteUDP(this.hUDP); catch ME, util.errorMessage(ME); end
            
            if this.isRemoteConnected == true
                this.socket.close(0);
                
                this.isOpen = false;
                this.isConnected = false;
            end
        end % END function close
        
        function skip = structableSkipFields(this)
            skip = {'hUDP','zmq','zmqM','socket'};
            skip1 = structableSkipFields@Framework.EyeTracker.Interface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Framework.EyeTracker.Interface(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
    end % END methods
end % END classdef Pupil