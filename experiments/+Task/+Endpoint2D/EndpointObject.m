classdef EndpointObject < Experiment2.TaskObjectInterface & util.Structable & util.StructableHierarchy & handle
    
    properties
        type % 'target','effector'
        scale % size of the object (screen normalized [0 1])
        shape % shape of the object
        color % color of the object (RGB, [0 1])
        brightness % brightness of the object (0-255)
        alpha % alpha (transparency) of object (0-100)
        angles % no idea...
        imgfile % path to image file
    end % END properties
    
    properties(SetAccess=private)
        hTimer % track contact durations
        flagStateLocked = false % whether to lock the object state
        flagVisible = false % whether object is visible or not
        numKinematicVars % number of dimensions in the object state
        stateDecimalAccuracy % number of decimal places of accuracy in the object state
        stateIdxHitTest % indices to use in the hit test (i.e. index out position only out of pos/vel dimensions)
        stateMode = 'pro' % 'pro', 'anti', 'zero'
        stateExternal % track external vs. internal state (anti vs. pro e.g.)
        stateInternal % track external vs. internal state (anti vs. pro e.g.)
        durationHold % number of seconds to maintain contact for hit
    end % END properties(SetAccess=private)
    
    methods
        function this = EndpointObject(hTask,id,varargin)
            this = this@Experiment2.TaskObjectInterface(hTask,id);
            
            % require hTask,ID
            this.hTask = hTask;
            assert(isa(this.hTask,'Experiment2.TaskInterface'),'Must provide valid handle to Experiment2.TaskInterface object');
            this.id = id;
            
            % process varargins
            [varargin,this.type,~,found_type] = util.argkeyval('type',varargin,'target'); % 'target','effector'
            assert(found_type&&ischar(this.type)&&any(strcmpi(this.type,{'target','effector'})),'Must provide object type "effector" or "target"');
            [varargin,this.numKinematicVars,~,found_kvars] = util.argkeyval('numKinematicVars',varargin,2);
            [varargin,this.stateIdxHitTest,~,found_hittest] = util.argkeyval('stateIdxHitTest',varargin,[1 2]);
            if found_kvars,assert(found_hittest,'Must provide stateIdxHitTest if numKinematicVars is provided');end
            [varargin,this.stateDecimalAccuracy] = util.argkeyval('stateDecimalAccuracy',varargin,5);
            [varargin,this.stateMode] = util.argkeyval('stateMode',varargin,'pro');
            [varargin,this.durationHold] = util.argkeyval('durationHold',varargin,1);
            [varargin,this.scale] = util.argkeyval('scale',varargin,0.05);
            [varargin,this.shape] = util.argkeyval('shape',varargin,'oval');
            [varargin,this.alpha] = util.argkeyval('alpha',varargin,100);
            [varargin,this.color] = util.argkeyval('color',varargin,[0.5 0.5 0.5]);
            [varargin,this.brightness] = util.argkeyval('brightness',varargin,150);
            [varargin,this.angles] = util.argkeyval('angles',varargin,150);
            [varargin,loc,~,found_loc] = util.argkeyval('state',varargin,nan);
            if found_loc,setState(this,loc);end
            [varargin,this.imgfile,~,found_imagefile] = util.argkeyval('imagefile',varargin,'');
            if found_imagefile,assert(exist(imf,'file')==2,'Must provide full path to existing image file');end
            util.argempty(varargin);
            
            % set up target hit timer
            this.hTimer = timer('Name',sprintf('%s%02d_Timer',this.type,this.id));
            this.hTimer.TimerFcn = @HitTimerFcn;
            
            % inline timer function
            function HitTimerFcn(~,~)
                hTask.registerHit(this.id);
            end % END function ObjectHitTimerFcn
        end % END function EndpointObject
        
        function setMode(this,md)
            this.stateMode = md;
        end % END function setMode
        
        function setState(this,val)
            assert(length(val)==this.numKinematicVars,'Wrong number of state dims: received %d but expected %d',length(val),this.numKinematicVars);
            if this.flagStateLocked, return; end
            val = round(val.*(10^this.stateDecimalAccuracy))/(10^this.stateDecimalAccuracy); % round to requested number of places
            this.stateExternal = val(:)';
            
            switch this.stateMode
                case 'pro'
                    this.stateInternal = this.stateExternal;
                case 'anti'
                    this.stateInternal = -this.stateExternal;
                case 'zero'
                    this.stateInternal = zeros(size(this.stateExternal));
                otherwise
                    error('Unrecognized state mode "%s"',this.stateMode);
            end
        end % END function setState
        
        function val = getState(this,varargin)
            [varargin,which] = util.argkeyword({'internal','external','display'},varargin,'internal',3);
            util.argempty(varargin);
            switch which
                case 'internal'
                    val = this.stateInternal;
                    if isempty(val),val=nan(1,this.numKinematicVars);end
                case 'external'
                    val = this.stateExternal;
                    if isempty(val),val=nan(1,this.numKinematicVars);end
                case 'display'
                    if isempty(this.stateExternal)
                        val = nan(1,length(this.stateIdxHitTest));
                    else
                        val = this.stateExternal(this.stateIdxHitTest);
                    end
                otherwise
                    error('Unrecognized state option "%s"',which);
            end
        end % END function getState
        
        function lockState(this)
            this.flagStateLocked = true;
        end % END function lockState
        
        function unlockState(this)
            this.flagStateLocked = false;
        end % END function unlockState
        
        function setVisible(this)
            this.flagVisible = true;
        end % END function setVisible
        
        function setInvisible(this)
            this.flagVisible = false;
        end % END function setInvisible
        
        function draw(this)
            if ~this.flagVisible,return;end
            shp = this.shape;
            switch lower(shp)
                case 'oval'
                    pos = normPos2Client(this.hTask.hDisplayClient,this.getState('display'));
                    scl = normScale2Client(this.hTask.hDisplayClient,this.scale);
                    clr = this.color * this.brightness;
                    drawOval(this.hTask.hDisplayClient,pos,scl,clr);
                case 'ovalframe'
                    pos = normPos2Client(this.hTask.hDisplayClient,this.getState('display'));
                    scl = normScale2Client(this.hTask.hDisplayClient,this.scale);
                    clr = this.color * this.brightness;
                    drawOvalFrame(this.hTask.hDisplayClient,pos,scl,clr);
                case 'square'
                    pos = normPos2Client(this.hTask.hDisplayClient,this.getState('display'));
                    scl = normScale2Client(this.hTask.hDisplayClient,this.scale);
                    clr = this.color * this.brightness;
                    drawSquare(this.hTask.hDisplayClient,pos,scl,clr);
                case 'triangle'
                    pos = normPos2Client(this.hTask.hDisplayClient,this.getState('display'));
                    scl = normScale2Client(this.hTask.hDisplayClient,this.scale);
                    clr = this.color * this.brightness;
                    drawTriangle(this.hTask.hDisplayClient,pos,scl,clr);
                case 'image'
                    pos = normPos2Client(this.hTask.hDisplayClient,this.getState('display'));
                    scl = normScale2Client(this.hTask.hDisplayClient,this.scale);
                    agl = this.angles;
                    imf = this.imgfile;
                    drawImage(this.hTask.hDisplayClient,imf,pos,scl,agl);
                otherwise
                    warning('Unrecognized shape "%s"',shp);
            end
        end % END function draw
        
        function [hit,info] = testContact(this,targets)
            % called for an EFFECTOR to see whether it has entered any
            % TARGET spaces
            
            % break out of the loop(s) once any event has been triggered
            % (avoid multiple events but only storing most recent state)
            hit = false;
            info = struct;
            if ~iscell(targets),targets={targets}; end
            
            % loop over all targets provided
            for kk=1:length(targets)
                hit = subfcn__contact(targets{kk},this);
                if hit
                    info = struct('effectorID',this.id,'targetID',targets{kk}.id);
                    break;
                end
            end
            
            
            % test whether objects have entered each other's space
            function hit = subfcn__contact(obj1,obj2)
                
                % default no hit
                hit = false;
                
                % retrieve state and scale values
                thisState = obj1.getState('internal');
                thisScale = obj1.scale;
                objState = obj2.getState('internal');
                objScale = obj2.scale;
                
                % pull out just the indices to be used for testing
                thisState = thisState(obj1.stateIdxHitTest);
                objState = objState(obj2.stateIdxHitTest);
                
                % convert positions/scales to pixels
                if obj1.hTask.params.useDisplay
                    thisState = obj1.hTask.hDisplayClient.normPos2Client(thisState);
                    thisScale = obj1.hTask.hDisplayClient.normScale2Client(thisScale);
                    objState = obj1.hTask.hDisplayClient.normPos2Client(objState);
                    objScale = obj1.hTask.hDisplayClient.normScale2Client(objScale);
                end
                
                % calculate distance between them and threshold for hit
                d = sqrt(sum((thisState(:)-objState(:)).^2)); % test straight-line distance
                threshold = (thisScale + objScale)/2;
                
                % act on distance/threshold
                if d <= threshold
                    hit = true;
                elseif d > threshold
                    hit = false;
                end
            end % END function subfcn__contact
        end % END function testContact
        
        function startTimer(this,delay)
            if strcmpi(this.hTimer.Running,'on')
                stop(this.hTimer);
            end
            assert(~isempty(delay)&&isfinite(delay),'Must provide finite delay value');
            this.hTimer.StartDelay = delay;
            start(this.hTimer);
        end % END function startHitTimer
        
        function stopTimer(this)
            stop(this.hTimer);
        end % END function startHitTimer
        
        function update(this)
            draw(this);
        end % END function update
        
        function HitFcn(this,evt,hTask,varargin)
        end % END function HitFcn
        
        function EnterFcn(this,evt,hTask,varargin)
        end % END function EnterFcn
        
        function ExitFcn(this,evt,hTask,varargin)
        end % END function ExitFcn
        
        function skip = structableSkipFields(this)
            skip = {'hTask','hTimer'};
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = struct;
        end % END function structableManualFields
    end % END methods
end % END classdef EndpointObject