classdef Unity < handle & DisplayClient.Interface & util.Structable
    
    properties
        hStream % stream UDP object
        hResponse % response UDP object
        ip = '127.0.0.1';%'192.168.100.73';
        streamPort = 26001;  % for streaming msgs
        responsePort = 26002;  % for response msgs
        unityIO
        UnitySubscribe % cell array of names of objects so subscribe to
        sentSubscribeCommands = false;
        buffers % for buffering data received by Unity
        initialBodyPosture
        useVMPL = true;
        scale = 100;
        offset = [0 0 20];
        debug
        verbosity
    end % END properties
    
    methods
        function this = Unity(cfg,varargin)
            this = this@DisplayClient.Interface;
            
            % read debug/verbosity
            [this.debug,this.verbosity] = env.get('debug','verbosity');
            
            % user config function overrides defaults
            if isa(cfg,'function_handle')
                feval(cfg,this);
            elseif ishandle(cfg) % preserve old functionality
                this.hParent = cfg;
            end
            
            % process user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % setup receiving messages from unity
            this.hStream = udp(this.ip, 'LocalPort',this.streamPort,'DatagramTerminateMode','off','InputBufferSize',2^20);
            fopen(this.hStream);
            
            this.hResponse = pnet('udpsocket', this.responsePort);
            pnet(this.hResponse,'setreadtimeout',0);
            
            % setup buffers for incoming Unity data
            for i = 1:length(this.UnitySubscribe)
                this.buffers{i} = Buffer.Dynamic('r');
            end
            
            % make port non-blocking
            %pnet(this.pSend,'setreadtimeout',0);
            %pnet(this.pReceive,'setreadtimeout',0);
            
            % create Unity interface
            this.unityIO = UnityInterface.WifCommandEncoder(this.ip);

            if this.useVMPL
                this.unityIO.setArmTransparency({'wholeArm'},0);
            else
                this.unityIO.setArmTransparency({'wholeArm'},100);
            end
            
            % make sure valid comment function
            this.commentFcn = util.ascell(this.commentFcn);
            assert(isa(this.commentFcn{1},'function_handle'),'Must provide function handle for commentFcn');
        end % END function Unity
        
        function r = getResource(this,type)
            available = cellfun(@(x)x==true,this.resourceList(:,strcmpi(this.resourceListLabels,'available')));
            sameType  = cellfun(@(x)x==type,this.resourceList(:,strcmpi(this.resourceListLabels,'type')));
            pick = find(available & sameType,1,'first');
            if isempty(pick)
                error('Experiment:Client:NoMoreResources','There are no more resources of type ''%s'' available',char(type));
            end
            r = this.resourceList{pick,strcmpi(this.resourceListLabels,'name')};
            this.resourceList{pick,strcmpi(this.resourceListLabels,'available')} = false;
        end % END function getResource
        
        function returnResource(this,name)
            idx = cellfun(@(x)strcmpi(x,name),this.resourceList(:,strcmpi(this.resourceListLabels,'name')));
            this.resourceList{idx,strcmpi(this.resourceListLabels,'available')} = true;
        end % END function returnResource
        
        function delete(this)
            try
                if ~isempty(this.hResponse), pnet(this.hResponse,'close'); end
            catch ME
                util.errorMessage(ME);
            end
            try
                if ~isempty(this.unityIO), finalize(this.unityIO); end
            catch ME
                util.errorMessage(ME);
            end
            util.deleteUDP(this.hStream);
        end % END function delete
        function st = toClientWorkspace(client,obj)
            st = obj.toStruct;
            if length(st.position)<3
                error('Experiment:Client:Unity:WorkspaceDimensions','Must provide positions with three dimensions');
            end
            st.scale = client.scale * st.scale;
            st.position = client.scale * st.position([3 2 1]);
            st.position = st.position + client.offset;
            st.alpha = 100 - st.alpha;
        end % END toClientWorkspace
        
        function createObject(this,obj)
            workspaceObj = this.toClientWorkspace(obj);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.COLLIDEABLE,true);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.PHYSICS,false);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.SUBSCRIBE_COLLISION_BEGIN,true);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.SUBSCRIBE_COLLISION_END,true);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.SCALE,workspaceObj.scale);
        end % END function createObject
        
        function updateObject(this,obj)
            % fprintf('Updating object: ''%s'', position=[%d %d %d], color=[%d %d %d], alpha=''%s'', scale=[%d %d %d]\n',...
            %     obj.name,obj.position(1),obj.position(2),obj.position(3),obj.color(1),obj.color(2),obj.color(3),char(obj.alpha),...
            %     obj.size,obj.size,obj.size);
            workspaceObj = this.toClientWorkspace(obj);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.POSITION,workspaceObj.position);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.COLOR,obj.color);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.TRANSPARENCY,workspaceObj.alpha);
        end % END function updateObject
        
        function updateBone(this,obj)
            % fprintf('Updating object: ''%s'', position=[%d %d %d], color=[%d %d %d], alpha=''%s'', scale=[%d %d %d]\n',...
            %     obj.name,obj.position(1),obj.position(2),obj.position(3),obj.color(1),obj.color(2),obj.color(3),char(obj.alpha),...
            %     obj.size,obj.size,obj.size);
            workspaceObj = this.toClientWorkspace(obj);
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.BONE,workspaceObj.position);
        end % END function updateObject
        
        function updateProperty(this,obj,val)
            this.unityIO.sendSingleCommand(obj.name,this.unityIO.PROPERTY1,val);
        end
        
        function setObjectVisibility(this,objectName,visible)
        	 this.unityIO.sendSingleCommand(objectName,this.unityIO.VISIBILITY,visible);
        end

        
        function refresh(this)
            if(~this.sentSubscribeCommands)
                this.sendSubscribeCommands();
            end
            
            junk = this.hStream.BytesAvailable;
            if(junk)
                data = uint8(fread(this.hStream,junk,'uint8'));
                msgs = UnityInterface.decodeWorldStateMessage(data);
                msgs = [msgs{:}];
            else
                data = [];
                msgs.id = [];
            end
            
            
            
            
            for i = 1:length(this.UnitySubscribe)
                lastMessage = find(strcmp({msgs.id},this.UnitySubscribe(i)),1,'last');
                if(isempty(lastMessage))
                    if(this.buffers{i}.isempty)
                        this.buffers{i}.add(nan(1,6));
                    else
                        this.buffers{i}.add(this.buffers{i}.get(1));
                    end
                else
                    this.buffers{i}.add([msgs(lastMessage).position' msgs(lastMessage).rotation']);
                    % this.buffers{i}.get(1)
                end
            end
            
            % this.unityIO.sendSingleCommand('SyncDisplayTime',this.unityIO.PROPERTY1,num2str(this.hFramework.frameId));
        end
        
        function drawOval(this,pos,diam,color)
            
        end
        
        function s = normScale2Client(this,normscale)
            s = normscale;
        end
        function p = normPos2Client(this, normpos)
            p = normpos;
        end
        
        function displayMessage(this,text,objectName)
            if nargin < 3
                objectName = 'MonitorText';
            end
            this.unityIO.sendSingleCommand(objectName,this.unityIO.PROPERTY1,text);
        end % END function displayMessage
        
        function setBodyPosture(this)
            %this.unityIO.sendSingleCommand('bone_leg_right',this.unityIO.BONE,[275 0 0])
            %this.unityIO.sendSingleCommand('bone_knee_right',this.unityIO.BONE,[80 0 0])
            
            %this.unityIO.sendSingleCommand('bone_leg_left',this.unityIO.BONE,[275 0 0])
            %this.unityIO.sendSingleCommand('bone_knee_right',this.unityIO.BONE,[80 0 0])
            
            % this.unityIO.sendSingleCommand('bone_shoulder_left',this.unityIO.BONE,[362 0 70])
            disp('[UNITY]            Setting Initial Body Posture');
            for i = 1:size(this.initialBodyPosture,1)
                this.unityIO.sendSingleCommand(this.initialBodyPosture{i,1},this.unityIO.BONE,this.initialBodyPosture{i,2})
            end
        end % END function setBodyPosture
        
        function setSyncDisplayTime(this,str)
            this.unityIO.sendSingleCommand('SyncDisplayTime',this.unityIO.PROPERTY1,num2str(str))
        end % END function setSyncDisplayTime
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@DisplayClient.Interface(this);
            skip = [skip1 {'buffers', 'hStream','hResponse','unityIO'}];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@DisplayClient.Interface(this);
            st = [];
            for i = 1:length(this.buffers)
                st.buffers{i} = this.buffers{i}.get;
            end
            st = util.catstruct(st,st1);
        end % END function structableManualFields
        
        function sendSubscribeCommands(this)
            for i = 1:length(this.UnitySubscribe)
                disp(['[UNITY]            Sending subscribe commands to Unity for: ' this.UnitySubscribe{i}]);
                this.unityIO.sendSingleCommand(this.UnitySubscribe{i}, this.unityIO.SUBSCRIBE,1);
            end
            this.sentSubscribeCommands = true;
        end % END function sendSubscribeCommands
    end % END methods
end % END classdef Unity