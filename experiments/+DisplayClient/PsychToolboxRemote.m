classdef PsychToolboxRemote < handle
    
    properties
        hReceive
        hSend
        
        screenid
        win
        monitorResolution
        skipSyncTests = true;
        
        ipAddress = '127.0.0.1';
        rcvRemotePort = 4021;
        rcvLocalPort = 4020;
        sndRemotePort = 4022;
        sndLocalPort = 4023;
    end % END properties
    
    methods
        
        function this = PsychToolboxRemote(varargin)
            
            initPsychToolbox(this);
            initUDP(this);
            
        end % END function PsychToolboxRemote
        
        function initUDP(this)
            % open UDP send connection
            ff = instrfind('RemoteHost',this.ipAddress,'RemotePort',this.sndRemotePort,'LocalPort',this.sndLocalPort);
            if ~isempty(ff), delete(ff); end
            this.hSend = udp(this.ipAddress,this.sndRemotePort,'LocalPort',this.sndLocalPort);
            fopen(this.hSend);
            
            % open UDP receive connection
            ff = instrfind('RemoteHost',this.ipAddress,'RemotePort',this.rcvRemotePort,'LocalPort',this.rcvLocalPort,'InputBufferSize',8192);
            if ~isempty(ff), delete(ff); end
            this.hReceive = udp(this.ipAddress,this.rcvRemotePort,'LocalPort',this.rcvLocalPort,'InputBufferSize',8192);
            this.hReceive.DatagramReceivedFcn = {@DisplayClient.PsychToolboxRemote.IncomingCommandProcessor,this};
            fopen(this.hReceive);
        end % END function initUDP
        
        function initPsychToolbox(this)
            
            % if needed to avoid startup failures
            if this.skipSyncTests
                Screen('Preference', 'SkipSyncTests', 1);
            end
            
            % Choose screen with maximum id - the secondary display:
            %this.screenid = max(Screen('Screens'));
            %if this.screenid~=0
               this.screenid = 2;
            %end
            
            % Open a fullscreen onscreen window
            this.win = Screen('OpenWindow', this.screenid, 0);
            
            % Retrieve monitor refresh durations:
            ifi = Screen('GetFlipInterval', this.win);
            
            % Perform initial flip to gray background and sync us to the retrace:
            vbl = Screen('Flip', this.win);
            Screen('TextSize',this.win, 40);
        end
        
        function delete(this)
            try util.deleteUDP(this.hSend); catch ME, util.errorMessage(ME); end
            try util.deleteUDP(this.hReceive); catch ME, util.errorMessage(ME); end
            
            % Close window, release all ressources
            Screen('CloseAll');
        end % END function delete
    end % END methods
    
    methods(Static)
        function IncomingCommandProcessor(u,~,ptbr)
            while u.BytesAvailable>0
                cmd = fscanf(u);
                try
                    if any(strcmpi(cmd(1:6),{'Screen','DrawFo'}))
                        eval(sprintf(cmd(:)',ptbr.win));
                    end
                catch ME
                    util.errorMessage(ME);
                end
            end
        end % END function IncomingCommandProcessor
    end % END methods(Static)
    
end % END classdef PsychToolboxRemote