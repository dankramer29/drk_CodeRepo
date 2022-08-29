classdef Client < handle & util.Structable & util.StructableHierarchy
    % CLIENT NI client interfacing with the server/interface
    
    properties(SetAccess=private,GetAccess=public)
        hUDP % UDP object for sending commands to server
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties
        udpIPAddress = '127.0.0.1' % IP address of server
        udpRemotePort = 7006 % the server's receive port
        udpLocalPort = 7007 % the local send port
    end % END properties
    
    methods
        function this = Client(varargin)
            % CLIENT Constructor for the NI client
            
            % process inputs
            [varargin,this.udpIPAddress] = util.argkeyval('ipAddress',varargin,this.udpIPAddress);
            [varargin,this.udpRemotePort] = util.argkeyval('sndRemotePort',varargin,this.udpRemotePort);
            [varargin,this.udpLocalPort] = util.argkeyval('sndLocalPort',varargin,this.udpLocalPort);
            util.argempty(varargin);
        end % END function Interface
        
        function initialize(this)
            % INITIALIZE start the UDP to the NI server/interface
            %
            %   INITIALIZE(THIS)
            %   Create the UDP send and receive objects and open them.
            
            % create send UDP object
            this.hUDP = util.getUDP(this.udpIPAddress,this.udpRemotePort,this.udpLocalPort);
            
            % initialize the Server
            command(this,NI.Command.INITIALIZE);
        end % END function initialize
        
        function start(this,varargin)
            % START Begin recording from the NI modules
            %
            %   START(THIS)
            %   Start recording Stimulator output and optical pulse saved
            %   with default ID string (YYYYMMDD-HHMMSS, plus the file 
            %   index).
            %
            %   START(...,BASEFILENAME)
            %   Record to the file specified by BASEFILENAME (plus the file
            %   index).
            
            % set the ID string if provided
            if nargin>1, setIDString(this,varargin{1}); end
            
            % start recording
            command(this,NI.Command.START);
        end % END function record
        
        function setIDString(this,str)
            % SETIDSTRING Set the ID string of the recorded files
            %
            %   SETIDSTRING(THIS,STR)
            %   Send a command to the server to set the ID string of
            %   recorded files to the string in STR.
            
            command(this,NI.Command.SET_ID_STRING,str);
        end % END function setIDString
        
        function setSubject(this,str)
            % SETSUBJECT Set the subject HST environment variable
            %
            %   SETSUBJECT(THIS,STR)
            %   Send a command to the server to set the subject HST env var
            %   to the string in STR.
            
            command(this,NI.Command.SET_SUBJECT,str);
        end % END function setSubject
        
        function stop(this)
            % STOP Stop recording from the NI modules
            %
            %   STOP(THIS)
            %   Stop recording output from Stimulator and optical pulse
            
            command(this,NI.Command.STOP);
        end % END function stop
        
        function setNeuralSync(this,state)
            % SETNEURALSYNC Enable or disable neural data synchronization
            %
            %   SETNEURALSYNC(THIS,STATE)
            %   Send the command to the server to enable or disable neural 
            %   data synchronization based on the logical value of STATE
            %   (TRUE = enable, FALSE = disable).
            
            if state
                command(this,NI.Command.ENABLE_CBMEX);
            else
                command(this,NI.Command.DISABLE_CBMEX);
            end
        end % END function setNeuralSync
        
        function delete(this)
            % DELETE Delete the NI server/modules
            %
            %   DELETE(THIS)
            %   Send the exit command to the server, and delete the send
            %   and receive UDP objects.
            command(this,NI.Command.STOP);
            command(this,NI.Command.EXIT);
            try util.deleteUDP(this.hUDP); catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function skip = structableSkipFields(this)
            skip = {'hUDP'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
        end % END function structableManualFields
        
    end % END methods
    
    methods(Access=private)
        
        function command(this,cmdId,varargin)
            % COMMAND Send commands to the webcam server
            %
            %   COMMAND(THIS,CMDID)
            %   Send the command specified by CMDID to the NI server/interface.
            %   CMDID must be an object of the enumeration class
            %   NI.Command.
            %
            %   COMMAND(...,ARG)
            %   Pass ARG along with the command to the NI server.  This
            %   interface option is only available for the SET_ID_STRING
            %   command and is used to specify the ID string.
            
            % verify that the UDP object is connected
            assert(isa(this.hUDP,'udp')&&strcmpi(this.hUDP.Status,'open'),'Invalid or closed UDP connection');
            
            % verify a valid command ID
            assert(isa(cmdId,'NI.Command'),'Invalid command ID');
            
            % process the command based on the command ID
            switch cmdId
                case NI.Command.EXIT
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId)];
                case NI.Command.INITIALIZE
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId)];
                case NI.Command.START
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId)];
                case NI.Command.STOP
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId)];
                case NI.Command.SET_ID_STRING
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId) uint8(varargin{1})];
                case NI.Command.SET_SUBJECT
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId) uint8(varargin{1})];
                case NI.Command.ENABLE_CBMEX
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId)];
                case NI.Command.DISABLE_CBMEX
                    data = [uint8(NI.MessageType.COMMAND) uint8(cmdId)];
                case NI.Command.REQUEST
                    warning('not implemented yet');
                otherwise
                    error('Unknown command id ''%d''',uint8(cmdId));
            end
            
            % send the command bytes
            fwrite(this.hUDP,data,'uint8');
        end % END function command
    end % END methods(Access=private)
end % END classdef Client