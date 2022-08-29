classdef Client < handle & Video.Interface & util.Structable & util.StructableHierarchy
    % CLIENT Webcam client interfacing with the webcam server
    
    properties(SetAccess=private,GetAccess=public)
        hUDPSnd % UDP object for sending commands to server
        hUDPRcv % UDP object for receiving data from server
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties
        ipAddress % IP address of server
        sndRemotePort % the server's receive port
        sndLocalPort % the local send port
        rcvRemotePort % the server's send port
        rcvLocalPort % the local receive port
    end % END properties
    
    methods
        function this = Client(varargin)
            % CLIENT Constructor for the webcam client object
            %
            %   V = CLIENT
            %   Create a webcam client object.  The default IP address is
            %   192.168.100.74 (appropriate for Rancho only); the default 
            %   local and remote ports for the UDP send object are 10023 
            %   and 10022 respectively; the default local and remote ports
            %   for the UDP receive object are 10025 and 10024 
            %   respectively.
            %
            %   V = CLIENT(...,'IPADDRESS',IPADDR)
            %   V = CLIENT(...,'SNDREMOTEPORT',PORT)
            %   V = CLIENT(...,'SNDLOCALPORT',PORT)
            %   V = CLIENT(...,'RCVREMOTEPORT',PORT)
            %   V = CLIENT(...,'RCVLOCALPORT',PORT)
            %   Override default values for these properties.
            
            % process inputs
            [varargin,this.ipAddress] = util.argkeyval('ipAddress',varargin,'127.0.0.1');
            [varargin,this.sndRemotePort] = util.argkeyval('sndRemotePort',varargin,10022);
            [varargin,this.sndLocalPort] = util.argkeyval('sndLocalPort',varargin,10023);
            [varargin,this.rcvRemotePort] = util.argkeyval('rcvRemotePort',varargin,10024);
            [varargin,this.rcvLocalPort] = util.argkeyval('rcvLocalPort',varargin,10025);
            util.argempty(varargin);
            
            % initialize recording status to OFF
            this.setStatus(Video.Status.OFF);
        end % END function Interface
        
        function initialize(this)
            % INITIALIZE start the UDP to the webcame server
            %
            %   INITIALIZE(THIS)
            %   Create the UDP send and receive objects and open them.
            
            % create receive UDP object
            this.hUDPRcv = util.getUDP(this.ipAddress,this.rcvRemotePort,this.rcvLocalPort,...
                'Name','WebcamClient-rcv',...
                'DatagramReceivedFcn',@processDatagram);
            
            % create send UDP object
            this.hUDPSnd = util.getUDP(this.ipAddress,this.sndRemotePort,this.sndLocalPort,...
                'Name','WebcamClient-snd');
            
            % initialize the Server
            command(this,Video.Webcam.Command.INITIALIZE);
            
            function processDatagram(u,~)
                % PROCESSDATAGRAM process received bytes
                %
                %   PROCESSDATAGRAM(UDPOBJ,EVT)
                %   Read any data available on UDPOBJ and process the
                %   message.
                
                % keep processing until nothing left
                while u.BytesAvailable>0
                    
                    % read the datagram
                    data = fread(u,u.BytesAvailable,'uint8');
                    messageType = data(1);
                    
                    % process based on message type (status or error)
                    switch messageType
                        case Video.Webcam.MessageType.STATUS % STATUS
                            this.setStatus(Video.Status(data(2)));
                        case Video.Webcam.MessageType.ERROR_ID % ERROR ID
                            this.setStatus(Video.Status.ERROR);
                            this.setErrorId(data(2));
                        case Video.Webcam.MessageType.RESPONSE % RESPONSE
                            this.setResponse(data(2));
                        otherwise
                            warning('Invalid message type ''%d''',messageType);
                    end
                end
            end % END function processDatagram
        end % END function initialize
        
        function record(this,varargin)
            % RECORD Begin recording from the webcam
            %
            %   RECORD(THIS)
            %   Start recording audio and video from the webcam to the file
            %   with default ID string (YYYYMMDD-HHMMSS, plus the file 
            %   index).
            %
            %   RECORD(...,BASEFILENAME)
            %   Record to the file specified by BASEFILENAME (plus the file
            %   index).
            
            % set the ID string if provided
            if nargin>1, setIDString(this,varargin{1}); end
            
            % start recording
            command(this,Video.Webcam.Command.RECORD);
            this.setStatus(Video.Status.RECORDING);
        end % END function record
        function startRecording(this,basefilename)
            warning('This function will be deprecated in a future release (use ''record'' instead).');
            record(this,basefilename);
        end % END function startRecording
        
        function setIDString(this,str)
            % SETIDSTRING Set the ID string of the recorded files
            %
            %   SETIDSTRING(THIS,STR)
            %   Send a command to the server to set the ID string of
            %   recorded files to the string in STR.
            
            command(this,Video.Webcam.Command.SET_ID_STRING,str);
        end % END function setIDString
        
        function setSubject(this,str)
            % SETSUBJECT Set the subject HST environment variable
            %
            %   SETSUBJECT(THIS,STR)
            %   Send a command to the server to set the subject HST env var
            %   to the string in STR.
            
            command(this,Video.Webcam.Command.SET_SUBJECT,str);
        end % END function setSubject
        
        function stop(this)
            % STOP Stop recording from the webcam
            %
            %   STOP(THIS)
            %   Stop recording audio and video from the webcam.
            
            command(this,Video.Webcam.Command.STOP);
            this.setStatus(Video.Status.OFF);
        end % END function stop
        
        function setNeuralSync(this,state)
            % SETNEURALSYNC Enable or disable neural data synchronization
            %
            %   SETNEURALSYNC(THIS,STATE)
            %   Send the command to the server to enable or disable neural 
            %   data synchronization based on the logical value of STATE
            %   (TRUE = enable, FALSE = disable).
            
            if state
                command(this,Video.Webcam.Command.ENABLE_CBMEX);
            else
                command(this,Video.Webcam.Command.DISABLE_CBMEX);
            end
        end % END function setNeuralSync
        
        function delete(this)
            % DELETE Delete the webcam client object
            %
            %   DELETE(THIS)
            %   Send the exit command to the server, and delete the send
            %   and receive UDP objects.
            
            command(this,Video.Webcam.Command.EXIT);
            try util.deleteUDP(this.hUDPRcv); catch ME, util.errorMessage(ME); end
            try util.deleteUDP(this.hUDPSnd); catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function skip = structableSkipFields(this)
            skip = {'hUDPSnd','hUDPRcv'};
            skip1 = structableSkipFields@Video.Interface(this);
            skip = [skip skip1];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
            st1 = structableManualFields@Video.Interface(this);
            st = util.catstruct(st,st1);
        end % END function structableManualFields
        
    end % END methods
    
    methods(Access=private)
        
        function command(this,cmdId,varargin)
            % COMMAND Send commands to the webcam server
            %
            %   COMMAND(THIS,CMDID)
            %   Send the command specified by CMDID to the webcam server.
            %   CMDID must be an object of the enumeration class
            %   Video.Webcam.Command.
            %
            %   COMMAND(...,ARG)
            %   Pass ARG along with the command to the webcam server.  This
            %   interface option is only available for the SET_ID_STRING
            %   command and is used to specify the ID string.
            
            % verify that the UDP object is connected
            assert(isa(this.hUDPSnd,'udp')&&strcmpi(this.hUDPSnd.Status,'open'),'Invalid or closed UDP connection');
            
            % verify a valid command ID
            assert(isa(cmdId,'Video.Webcam.Command'),'Invalid command ID');
            
            % process the command based on the command ID
            switch cmdId
                case Video.Webcam.Command.EXIT
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId)];
                case Video.Webcam.Command.INITIALIZE
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId)];
                case Video.Webcam.Command.RECORD
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId)];
                case Video.Webcam.Command.STOP
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId)];
                case Video.Webcam.Command.SET_ID_STRING
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId) uint8(varargin{1})];
                case Video.Webcam.Command.SET_SUBJECT
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId) uint8(varargin{1})];
                case Video.Webcam.Command.ENABLE_CBMEX
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId)];
                case Video.Webcam.Command.DISABLE_CBMEX
                    data = [uint8(Video.Webcam.MessageType.COMMAND) uint8(cmdId)];
                case Video.Webcam.Command.REQUEST
                    warning('not implemented yet');
                otherwise
                    error('Unknown command id ''%d''',uint8(cmdId));
            end
            
            % send the command bytes
            fwrite(this.hUDPSnd,data,'uint8');
        end % END function command
    end % END methods(Access=private)
end % END classdef Client