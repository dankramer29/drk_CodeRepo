classdef Client < handle & util.Structable & util.StructableHierarchy
    
    properties
        ipAddress = '192.168.100.73';
        hSend
        hReceive
        rcvRemotePort = 4031+8;
        rcvLocalPort = 4030+8;
        sndRemotePort = 4033+8;
        sndLocalPort = 4032+8;
        
        sounds
    end
    
    methods
        function this = Client(varargin)
            
            % process inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % create receive UDP object
            try
                ff = instrfind('Name','SoundClient-rcv');
                if ~isempty(ff), delete(ff); end
                this.hReceive = udp(this.ipAddress,this.rcvRemotePort,'LocalPort',this.rcvLocalPort,...
                    'InputBufferSize',4096,...
                    'Name','SoundClient-rcv',...
                    'DatagramReceivedFcn',{@Sound.Server.processDatagram,this});
                fopen(this.hReceive);
            catch ME
                util.errorMessage(ME);
            end
            
            % create send UDP object
            try
                ff = instrfind('Name','SoundClient-snd');
                if ~isempty(ff), delete(ff); end
                this.hSend = udp(this.ipAddress,this.sndRemotePort,'LocalPort',this.sndLocalPort,...
                    'OutputBufferSize',4096,...
                    'Name','SoundClient-snd');
                fopen(this.hSend);
            catch ME
                util.errorMessage(ME);
            end
        end % END function Sound
        
        function register(this,name,file)
            fwrite(this.hSend,[uint8(Sound.Command.REGISTER) name ',' file],'uint8');
            
            % create full path to file
            s.name = name;
            
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
        end % END function register
        
        function play(this,name)
            fwrite(this.hSend,[uint8(Sound.Command.PLAY) name],'uint8');
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
        
        function close(this)
            delete(this);
        end % END function close
        
        function delete(this)
            
            % % send stop command to server
            % try
            %     fwrite(this.hSend,uint8(Sound.Command.STOP),'uint8')
            % catch ME
            %     util.errorMessage(ME);
            % end
            
            % clean up UDP objects
            try util.deleteUDP(this.hReceive); catch ME, util.errorMessage(ME); end
            try util.deleteUDP(this.hSend);    catch ME, util.errorMessage(ME); end
        end % END function delete
        
        function list = structableSkipFields(this)
            list = {'pahandle','hSend','hReceive'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = [];
        end % END function structableManualFields
    end
    
end