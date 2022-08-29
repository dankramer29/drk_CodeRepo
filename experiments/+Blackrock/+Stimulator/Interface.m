classdef Interface < handle & Utilities.Structable
% INTERFACE Encapsulate UDP communication with the stimulator server.
%
%   To create a Interface object, call the constructor with any necessary
%   network settings:
%
%     >> s = Interface('ip','131.215.27.XX','localp','XX','remotep','XX');
%
%   Then, to send a command to the stim server, use the sendStringCommand
%   function:
%
%     >> cmd = '1,0,0,1;'; % pre-formatted stim command
%     >> s.sendStringCommand(cmd);
%
%   Finally, to clean up the Interface object, use the delete function:
%
%     >> s.delete; % calls finalize internally if the object is still open
%
%   It is important clean up the object since it allocates a network
%   resource.

    properties
        stimDirectory % directory containing the stimulation executable
        stimLocalPort = 5007; % local port for UDP communication with stim executable
        stimRemotePort = 5006; % remote port for UDP communication with stim executable
        serverLocalPort = 5040; % local port for UDP communication with server that manages the executable
        serverRemotePort = 5041; % remote port for UDP communication with server that manages the executable
        ipAddress = '192.168.100.73'; % remote IP address for UDP communication
        stimExeLocation = 'network'; % 'network' or 'local' - how to access stim executable
    end
    
    properties(Access=private)
        isOpen = false; % whether the interface is open
        isLoaded = false; % whether the server executable is loaded
        hStimUDP % handle to UDP object for communicating with actual stim executable
        hServerUDP % handle to UDP object for communicating with server that manages the executable
    end % END properties(Access=private)
    
    methods
        function this = Interface(varargin)
            % INTERFACE Constructor for the Interface class
            %
            %   S = INTERFACE;
            %   Create a Interface object with default parameters.
            %
            %   S = INTERFACE('ipAddress',VALUE)
            %   S = INTERFACE('stimRemotePort',VALUE)
            %   S = INTERFACE('stimLocalPort',VALUE)
            %   Specify custom values for the IP address of the stim
            %   server, the remote port for the stim server, or the local
            %   port for the UDP object. Default values are '127.0.0.1' for
            %   IP address, 5006 for remote port, and 5007 for local port.
            
            % set stim directory
            this.stimDirectory = fullfile(env.get('rphst'),'StimulationServer','Debug');
            
            % check input arguments
            [varargin,this.stimDirectory] = Utilities.argkeyval('stimdirectory',varargin,this.stimDirectory,7);
            [varargin,this.ipAddress] = Utilities.argkeyval('ipaddress',varargin,this.ipAddress,2);
            [varargin,this.stimLocalPort] = Utilities.argkeyval('stimLocalPort',varargin,this.stimLocalPort,7);
            [varargin,this.stimRemotePort] = Utilities.argkeyval('stimRemotePort',varargin,this.stimRemotePort,7);
            [varargin,this.serverLocalPort] = Utilities.argkeyval('serverLocalPort',varargin,this.serverLocalPort,9);
            [varargin,this.serverRemotePort] = Utilities.argkeyval('serverRemotePort',varargin,this.serverRemotePort,9);
            [varargin,this.stimExeLocation] = Utilities.argkeyval('stimExeLocation',varargin,this.stimExeLocation,7);
            Utilities.argempty(varargin);
            
            % create UDP object for stim executable communication
            this.hStimUDP = Utilities.getUDP(this.ipAddress,this.stimRemotePort,this.stimLocalPort,'Name','stimUDP');
            
            % create UDP object for stim server communication
            if strcmpi(this.stimExeLocation,'network')
                this.hServerUDP = Utilities.getUDP(this.ipAddress,this.serverRemotePort,this.serverLocalPort,'Name','serverUDP');
            end
            
            % this.tmpStimIP = pnet('udpsocket', this.stimLocalPort);
            % 
            % % check if connection successful
            % if this.tmpStimIP == -1
            %     error('Unable to open port %d',this.stimLocalPort)
            % end
            % 
            % % connect
            % pnet(this.tmpStimIP, 'udpconnect', this.ipAddress , this.stimRemotePort);
            
            % set open property to TRUE
            this.isOpen = true;
        end % END function Interface
        
        function loadServer(this)
            % LOADSERVER Start the stim server executable
            %
            %   LOADSERVER(THIS)
            %   Start the stim server executable process either on the
            %   local machine or the remote machine depending on the
            %   "stimExeLocation" property.
            assert(this.isOpen,'Interface must be open to load the server');
            if strcmpi(this.stimExeLocation,'network')
                Blackrock.Stimulator.loadServerRemote(this.hServerUDP);
            elseif strcmpi(this.stimExeLocation,'local')
                Blackrock.Stimulator.loadServerLocal(this.stimDirectory);
            end
            this.isLoaded = true;
        end % END function loadServer
        
        function stopServer(this)
            % STOPSERVER Stops the stim server executable
            %
            %   STOPSERVER(THIS)
            %   Stop the stim server executable process either on the
            %   local machine or the remote machine depending on the
            %   "stimExeLocation" property.
            assert(this.isOpen&&this.isLoaded,'Interface must be open and loaded to stop the server');
            this.sendStringCommand('t;',false); % terminate any ongoing stimulation
            if strcmpi(this.stimExeLocation,'network')
                Blackrock.Stimulator.stopServerRemote(this.hServerUDP);
            elseif strcmpi(this.stimExeLocation,'local')
                Blackrock.Stimulator.stopServerLocal(this.stimDirectory);
            end
            this.isLoaded = false;
        end % END function stopServer
        
        function sendStringCommand(this,cmd,varargin)
            % SENDSTRINGCOMMAND Send a preformated string command
            %
            %   SENDSTRINGCOMMAND(THIS,CMD)
            %   Send a preformatted string command to the stim server (not
            %   validated). CMD should be a preformatted command string,
            %   e.g., '1,0,0,1;' (see Blackrock documentation).
            %
            %   SENDSTRINGCOMMAND(...,TRUE/FALSE)
            %   Boolean flag of whether or not to printf the received CMD.
            assert(this.isOpen&&this.isLoaded,'Interface must be open and loaded to send a command');
            fwrite(this.hStimUDP,cmd,'char');
            % send to the server just to keep track of the sent commands
            if strcmpi(this.stimExeLocation,'network'); fwrite(this.hServerUDP,cmd,'char'); end
            [~,flagcmd] = Utilities.ProcVarargin(varargin,@(x)isa(x,'logical'),true);
            if flagcmd; fprintf('%s\n',cmd); end
%             % send command message
%             pnet(this.tmpStimIP, 'write', cmd);
%             pnet(this.tmpStimIP, 'writepacket');
        end % END function sendStringCommand
        
        function st = toStruct(this)
            st = toStruct@Utilities.Structable(this,'hStimUDP','hServerUDP');
        end % END function toStruct
        
        function delete(this)
            if this.isLoaded
                try stopServer(this); catch ME, Utilities.errorMessage(ME); end
            end
            if this.isOpen
%                 pnet(this.tmpStimIP, 'close');
                if strcmpi(this.stimExeLocation,'network')
                    try Utilities.deleteUDP(this.hServerUDP); catch ME, Utilities.errorMessage(ME); end
                end
                try Utilities.deleteUDP(this.hStimUDP); catch ME, Utilities.errorMessage(ME); end
            end
        end % END function delete
    end % methods
end