classdef Server < handle & Utilities.Structable
% SERVER Manage the stim executable
%
%   The Server class exists to manage (i.e., start or stop) the stim server
%   executable process. It should be used when the stim server executable
%   runs on a different machine (but one that is network accessible) from
%   the primary matlab process sending stimulation commands. This object
%   should be instantiated on the the PC that will be running the stim
%   server executable, and left running. It will listen for incoming
%   commands to start or stop the executable.
%
%   >> s = Server;
    
    properties
        stimDirectory % directory containing the stimulation server executable
        ipAddress = '192.168.100.75'; % IP address of the machine sending commands to the stim server
        remotePort = 5040; % port on the remote machine to which commands should be sent
        localPort = 5041; % port on the local machine on which to listen for incoming commands
        verbosity = Inf;
    end % END properties
    
    properties(Access=private)
        hUDP % handle to the UDP object for sending/receiving UDP traffic
    end % END properties(Access=private)
    
    methods
        function set.stimDirectory(this,val)
            % SET.STIMDIRECTORY Validate stimulation directories
            assert(exist(val,'dir')==7,'Server:Error. ','Directory ''%s'' does not exist',val);
            this.stimDirectory = val;
        end % END function set.stimDirectory
        
        function this = Server(varargin)
            % SERVER Manage the stim executable
            %
            %   THIS = SERVER;
            %   Instantiate the server with default values.
            %
            %   THIS = SERVER(...,'ipaddress',IP_ADDRESS)
            %   THIS = SERVER(...,'remotePort',REMOTE_PORT)
            %   THIS = SERVER(...,'localPort',LOCAL_PORT)
            %   Optionally override the default values for UDP
            %   communication: IP Address (192.168.100.75), remote port
            %   (5040), and local port (5041).
            
            % set stim directory
            this.stimDirectory = fullfile(env.get('rphst'),'StimulationServer','Debug');
            
            % process remaining user inputs
            varargin = Utilities.ProcVarargin(varargin,this);
            Utilities.ProcVarargin(varargin);
            
            % create receive UDP object
            this.hUDP = Utilities.getUDP(this.ipAddress,this.remotePort,this.localPort,...
                'InputBufferSize',4096,'Name','StimServer','DatagramReceivedFcn',@processDatagram);
            
            % process datagrams received
            function processDatagram(~,~)
                data = fread(this.hUDP,this.hUDP.BytesAvailable,'uint8');
                cmd = data(1);
                % print on screen what was received
                if cmd > 3
                    comment(this,sprintf('Command received ''%s''',char(data)));
                else
                    [~,names] = enumeration('StimServer.Command');
                    comment(this,sprintf('Command received: ''%s''',names{cmd}));
                end
                switch cmd
                    case uint8(StimServer.Command.LOADSERVER)
                        Blackrock.Stimulator.loadServerLocal(this.stimDirectory);
                    case uint8(StimServer.Command.STOPSERVER)
                        Blackrock.Stimulator.stopServerLocal(this.stimDirectory);
                    case uint8(StimServer.Command.SETSERVER)
                        str = data(2:end);
                        str = str(:)';
                        commaIdx = strfind(str,',');
                        name = str(1:commaIdx-1);
                        val = str(commaIdx+1:end);
                        switch lower(name)
                            case 'stimdirectory',   this.stimDirectory = char(val);
                            case 'ipaddress',       this.ipAddress = char(val);
                            case 'remoteport',      this.remotePort = double(val);
                            case 'localport',       this.localPort = double(val);
                            otherwise, warning('Unknown property ''%s''',name);
                        end
                end
            end % END function processDatagram
        end % END function Server
        
        function comment(this,msg,vb)
            if nargin<3,vb=1;end
            if vb<=this.verbosity,fprintf('%s\n',msg);end
        end % END function comment
        
        function delete(this)
            try Utilities.deleteUDP(this.hUDP); catch ME, Utilities.errorMessage(ME); end
        end % END function delete
        
        function st = toStruct(this)
            st = toStruct@Utilities.Structable(this,'hUDP');
        end % END function toStruct
    end % END methods
end % END classdef Server