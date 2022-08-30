classdef PsychToolbox < handle & DisplayClient.Interface & util.StructableHierarchy & util.Structable
    
    properties(Access=private)
        hSend % udp object for sending data
        hReceive % udp object for receiving data
    end % END properties(Access=private)
    
    properties(SetAccess=private,GetAccess=public)
        win % psychtoolbox object
        screenCenter = [960 540]; % center of the screen in pixels
        rect
    end % END properties(SetAccess=private,GetAccess=public)
    
    properties
        screenid = 0; % psychtoolbox screen id
        monitorSize = [107 59]; % in cm
        displayResolution = [1920 1080]; % display resolution in pixels
        target = 'local'; %'local'; %'udp'
        ipAddress = '127.0.0.1'; % IP address of the remote machine
        rcvLocalPort = 4022; % local port for the receive UDP object
        rcvRemotePort = 4023; % remote port for the receive UDP object
        sndLocalPort = 4021; % local port for the send UDP object
        sndRemotePort = 4020; % remote port for the receive UDP object
        fudgeScalingFactor = 1; % multiplier for normalized values
        uniqueImageID % unique identifier in case of nonunique files in sep. dirs.
        ImageNames % used to identify images already loaded
        ImageAliases % allow multiple names for same texture
        ImageDirectory % where to find images
        ImagePaths % where to find images
        ImageTextures % image textures
        ImageDimensions % image dimensions
        skipSyncTests = true; % indicate skip psychtoolbox sync tests
        openGL = true; % enable for remote desktop
        debug % debug mode
        verbosity % verbosity level
        ptbOldVerbosityLevel % save the original PTB debug level
        ptbopacity % opacity level
        ptbhid % opaque to human interface input (mouse click etc.)
    end % END properties
    
    methods
        function this = PsychToolbox(varargin)
            this = this@DisplayClient.Interface;
            
            % set defaults based on environment variables
            this.ImageDirectory = fullfile(env.get('media'),'img');
            [si,dr,ss] = env.get('screenid','displayresolution','screensize');
            if ~isempty(si), this.screenid = si; end
            if ~isempty(dr), this.displayResolution = dr; end
            if ~isempty(ss), this.screensize = ss; end
            
            % reset debug
            clear('Screen');
            
            % read debug/verbosity
            [this.debug,this.verbosity,this.screenid,this.ptbopacity,this.ptbhid] = env.get('debug','verbosity','screenid','ptbopacity','ptbhid');
            if isa(this.verbosity,'Debug.PriorityLevel')
                this.verbosity = double(this.verbosity);
            end
            if isa(this.debug,'Debug.Mode')
                this.debug = double(this.debug);
            end
            
            % process user inputs
            varargin = util.argobjprop(this,varargin);
            util.argempty(varargin);
            
            % make sure valid comment function
            this.commentFcn = util.ascell(this.commentFcn);
            assert(isa(this.commentFcn{1},'function_handle'),'Must provide function handle for commentFcn');
            
            % local or remote operation
            switch lower(this.target)
                case 'local'
                    initPsychToolbox(this);
                case 'udp'
                    initUDP(this);
            end
        end % END function PsychToolbox
        
        function initUDP(this)
            
            % create receive UDP object
            this.hReceive = util.getUDP(this.ipAddress,this.rcvRemotePort,this.rcvLocalPort,...
                'InputBufferSize',8192,'Name','PsychToolbox-rcv',...
                'DatagramReceivedFcn',{@DisplayClient.PsychToolboxRemote.IncomingCommandProcessor,this});
            
            % create send UDP object
            this.hSend = util.getUDP(this.ipAddress,this.sndRemotePort,this.sndLocalPort,...
                'Name','PsychToolbox-snd');
        end % END function initUDP
        
        function [ifi,vbl] = initPsychToolbox(this)
            
            % set verbosity level
            this.ptbOldVerbosityLevel = Screen('Preference','Verbosity',this.verbosity);
            
            % make sure no empty screen id
            availableScreens = Screen('Screens');
            assert(ismember(this.screenid,availableScreens),'Screen %d is not in the list of available screens %s',this.screenid,util.vec2str(availableScreens,'%g'));
            
            % if needed to avoid startup failures
            if this.skipSyncTests
                comment(this,'Skipping sync tests',2);
                Screen('Preference', 'SkipSyncTests', 1);
            else
                Screen('Preference', 'SkipSyncTests', 0);
            end
            
            % run debug mode or not
            if this.debug>0
                comment(this,'Debug mode enabled',2);
            end
            
            % set opacity
            if this.ptbopacity<1.0 || this.ptbhid==0
                PsychDebugWindowConfiguration(this.ptbhid,this.ptbopacity);
                type = env.get('type');
                if ischar(type) && strcmpi(type,'production')
                    warning('PsychToolbox performance is reduced when using debug window configuration (ptbopacity %.1f, ptbhid %d)',this.ptbopacity,this.ptbhid);
                end
            end
            
            % open GL mode (for remote desktop)
            if this.openGL
                comment(this,'OpenGL mode enabled',2);
                Screen('Preference', 'ConserveVRAM', 64);
            end
            
            % Open a fullscreen onscreen window
            [this.win,this.rect] = Screen('OpenWindow', this.screenid, [0 0 0], [], 32, 2, [], 0);
            assert(ismember(this.win,Screen('Windows')),'OpenWindow command returned invalid results');
            this.displayResolution = this.rect(3:4);
            [this.screenCenter(1),this.screenCenter(2)] = RectCenter(this.rect);
            
            % enable transparency
            Screen('BlendFunction',this.win,GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
            
            % Retrieve monitor refresh duration:
            ifi = Screen('GetFlipInterval', this.win);
            
            % Perform initial flip to gray background and sync us to the retrace:
            vbl = Screen('Flip', this.win);
            Screen('TextSize',this.win,40);
        end % END function initPsychToolbox
        
        function flipTime = refresh(this)
            flipTime = nan;
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    flipTime = Screen('Flip', this.win);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''Flip'', %%d);'));
            end
        end % END function refresh
        
        function textureId = loadImage(this,imageData,imageName)
            % LOADIMAGE Load an image into a texture
            %
            %   TEXTUREID = LOADIMAGE(THIS,IMAGEFILE,IMAGENAME)
            %   Load the image located at the path and filename IMAGEFILE
            %   into a texture, with the associated string IMAGENAME.
            %   Return the index of the new texture as TEXTUREID.  If
            %   IMAGENAME is empty or not provided, the basename of
            %   IMAGEFILE will be used as the image name.
            
            % validate window
            assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
            
            % interpret inputs
            if isnumeric(imageData)
                
                % data provided is the image matrix
                imageMatrix = imageData;
                
                % process image name
                if nargin<3||isempty(imageName)
                    imageName = sprintf('Texture%d',length(this.ImageNames)+1);
                end
                uid = imageName;
            elseif ischar(imageData)
                
                % construct path to image file
                if exist(imageData,'file')~=2
                    imageData = fullfile(this.ImageDirectory,imageData);
                end
                uid = imageData;
                % get image name
                if nargin<3 || isempty(imageName)
                    [~,imageName] = fileparts(imageData);
                end
                
                % validate input
                assert(exist(imageData,'file')==2,'Cannot locate file ''%s''',imageData);
                
                % read image
                try
                    [imageMatrix,~,alpha] = imread(imageData);
                catch ME
                    fprintf('Could not read ''%s''\n',imageData);
                    util.errorMessage(ME);
                end
                if size(imageMatrix,3)==3 && ~isempty(alpha)
                    imageMatrix(:,:,4) = alpha;
                end
                
                % make sure transparency enabled (should be since in init)
                if size(imageMatrix,3)==4
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    [currentSourceFactor,currentDestinationFactor] = Screen('BlendFunction',this.win);
                    if ~strcmpi(currentSourceFactor,GL_SRC_ALPHA) || ~strcmpi(currentDestinationFactor,GL_ONE_MINUS_SRC_ALPHA)
                        Screen('BlendFunction', this.win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                    end
                end
            else
                error('imageData must be numeric or char');
            end
            
            % identify the texture index
            try
                textureId = find(strcmpi(this.uniqueImageID,uid),1,'first');
                if isempty(textureId)
                    
                    % add to textures
                    textureId = length(this.ImageNames)+1;
                    this.ImageNames{textureId} = imageName;
                    this.uniqueImageID{textureId} = uid;
                    this.ImageTextures{textureId} = Screen('MakeTexture',this.win,double(imageMatrix));
                    this.ImageDimensions{textureId} = [size(imageMatrix,2) size(imageMatrix,1)]; % width x height
                else
                    
                    % add alias
                    if isempty(this.ImageAliases)
                        this.ImageAliases = {uid,imageName};
                    else
                        this.ImageAliases = [this.ImageAliases; {uid,imageName}];
                    end
                end
            catch ME
                util.errorMessage(ME);
                keyboard;
            end
        end % END function loadImage
        
        function dims = getImageDimensions(this,imagename)
            % GETIMAGEDIMENSIONS Get dimensions of a loaded image
            %
            %   DIMS = GETIMAGEDIMENSIONS(THIS,IMAGENAME)
            %   Return in DIMS the width and height of the image that has
            %   already been loaded under the name IMAGENAME.
            
            % determine whether this image has already been loaded
            id = find(strcmpi(this.ImageNames,imagename));
            if isempty(id)
                
                % look for alias
                if isempty(this.ImageAliases)
                    which = false;
                else
                    which = strcmpi(this.ImageAliases(:,2),imagename);
                end
                if any(which)
                    id = find(strcmpi(this.uniqueImageID,this.ImageAliases{which,1}));
                else
                    id = loadImage(this,imagename);
                end
            end
            assert(~isempty(id),'Could not find image ''%s''',imagename);
            
            % read out image dimensions
            dims = this.ImageDimensions{id};
        end % END function getImageDimensions
        
        function initLoadImages(this)
            % INITLOADIMAGES Load all images
            
            % return if nothing to load
            if isempty(this.ImagePaths),return;end
            
            % Create image textures
            for kk = 1:length(this.ImagePaths)
                loadImage(this,this.ImagePaths{kk});
            end
        end % END function initLoadImages
        
        function remoteCommand(this,cmd)
            fprintf(this.hSend, '%s', cmd);
        end % END function remoteCommand
        
        function displayMessage(this,msg,varargin)
            % DISPLAYMESSAGE Display a message on the screen
            %
            %   DISPLAYMESSAGE(THIS,MSG)
            %   Print a message on the screen.  Default values will place
            %   the message in the upper left corner of the screen.
            %
            %   See also DRAWTEXT.
            
            sx = 10;
            sy = 10;
            color = [0 150 150];
            wrapat = 40;
            if nargin>2, sx = varargin{1}; end
            if nargin>3, sy = varargin{2}; end
            if nargin>4, color = varargin{3}; end
            if nargin>5, wrapat = varargin{4}; end
            
            % draw the text
            if isempty(msg); msg=' '; end
            drawText(this,msg,sx,sy,color,wrapat);
        end % END function displayMessage
        
        function oldval = pref(this,nm,val)
            % PREF Get or set psychtoolbox preference
            %
            %   OLDVAL = PREF(THIS,NM)
            %   Retrieve the value of the preference named NM in OLDVAL.
            %
            %   OLDVAL = PREF(THIS,NM,VAL)
            %   Set the value of the preference named NM to VAL, returning
            %   the original value in OLDVAL.
            
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    if nargin<3
                        
                        % just get the value
                        oldval = Screen('Preference',nm);
                    else
                        
                        % set and get the value
                        oldval = Screen('Preference',nm,val);
                    end
                case 'udp'
                    error('setPreference not supported for remote PTB');
            end
        end % END function setPreference
        
        function sz = getTextSize(this)
            % GETTEXTSIZE get the font size
            %
            %   SZ = GETTEXTSIZE(THIS)
            %   Get the font size in SZ.
            
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    sz = Screen('TextSize',this.win);
                case 'udp'
                    error('getTextSize not supported for remote PTB');
            end
        end % END function getTextSize
        
        function setTextSize(this,size,varargin)
            % SETTEXTSIZE set the font size
            %
            %   SETTEXTSIZE(THIS,SIZE)
            %   Set the font size to the value in SIZE.
            
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('TextSize',this.win,size);
                case 'udp'
                    
                    % command for remote system
                    remoteCommand(this,sprintf('Screen(''TextSize'',%%d,%d);',size));
            end
        end % END function setTextSize
        
        function ft = getTextFont(this)
            % GETTEXTFONT get the font family
            %
            %   FT = GETTEXTFONT(THIS)
            %   Get the font family in FT.
            
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    ft = Screen('TextFont',this.win);
                case 'udp'
                    error('getTextFont not supported for remote PTB');
            end
        end % END function setTextFont
        
        function setTextFont(this,font)
            % SETTEXTFONT set the font family
            %
            %   SETTEXTFONT(THIS,FONT)
            %   Set the font to the font family specified by FONT.
            
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('TextFont',this.win,font);
                case 'udp'
                    
                    % command for remote system
                    remoteCommand(this,sprintf('Screen(''TextFont'',%%d,%d);',font));
            end
        end % END function setTextFont
        
        function setTextStyle(this,style)
            % SETTEXTSTYLE set the font family
            %
            %   SETTEXTSTYLE(THIS,STYLE)
            %   Set the font style to the style indicated in STYLE
            
            if ischar(style)
                switch lower(style)
                    case 'normal',style=0;
                    case 'bold',style=1;
                    case 'italic',style=2;
                    case 'underline',style=4;
                    case 'outline',style=8;
                    case 'condense',style=32;
                    case 'extend',style=64;
                    otherwise
                        error('Unknown style ''%s''',style);
                end
            end
            
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('TextStyle',this.win,style);
                case 'udp'
                    
                    % command for remote system
                    remoteCommand(this,sprintf('Screen(''TextFont'',%%d,%d);',font));
            end
        end % END function setTextFont
        
        function [nx,ny,textbound] = drawText(this,tstring,x,y,color,varargin)
            % DRAWTEXT print text to the screen
            %
            %   DRAWTEXT(THIS,TSTRING,X,Y,COLOR)
            %   Print the text in TSTRING to the screen at the location
            %   specified by X and Y, in the color specified by COLOR.
            %
            %   DRAWTEXT(...,WRAPAT,FLIPH,FLIPV,VSPAC,R2L,WINRECT)
            %   Modify how text will be printed to screen.
            %
            %   See also DRAWFORMATTEDTEXT.
            
            % empty defaults
            if nargin<5,color=[];end
            if nargin<4,y=[];end
            if nargin<3,x=[];end
            
            % execute
            switch lower(this.target)
                case 'local'
                    
                    % command for local system
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    if isempty(tstring); tstring=''; end
                    [nx,ny,textbound] = DrawFormattedText(this.win,tstring,x,y,color,varargin{:});
                case 'udp'
                    nx=nan;
                    ny=nan;
                    textbound=nan;
                    
                    % basic command, will be passed through sprintf
                    xstr = '%g';
                    if ischar(x), xstr='%s'; end
                    if isempty(x), xstr='[]'; end
                    ystr = '%g';
                    if ischar(y), ystr='%s'; end
                    if isempty(y), ystr='[]'; end
                    formatString = ['DrawFormattedText(%%d,''%s'',' xstr ',' ystr ',%s'];
                    formatArg = {msg,x,y,util.vec2str(color,'%d')};
                    
                    % wrapat
                    if nargin>4
                        formatString = [formatString ',%g'];
                        formatArg = [formatArg varargin(1)];
                    end
                    
                    % flipHorizontal
                    if nargin>5
                        formatString = [formatString ',%d'];
                        formatArg = [formatArg varargin(2)];
                    end
                    
                    % flipVertical
                    if nargin>6
                        formatString = [formatString ',%d'];
                        formatArg = [formatArg varargin(3)];
                    end
                    
                    % vSpacing
                    if nargin>7
                        formatString = [formatString ',%g'];
                        formatArg = [formatArg varargin(4)];
                    end
                    
                    % righttoleft
                    if nargin>8
                        formatString = [formatString ',%g'];
                        formatArg = [formatArg varargin(5)];
                    end
                    
                    % winRect
                    if nargin>9
                        formatString = [formatString ',%s'];
                        formatArg = [formatArg util.vec2str(varargin(6))];
                    end
                    
                    % end the string
                    formatString = [formatString ');'];
                    
                    % send the command
                    remoteCommand(this,sprintf(formatString,formatArg{:}));
            end
        end % END function drawText
        
        function drawLines(this,st,lt,lw,clr,orig,sm)
            % DRAWLINES Draw single or multiple lines
            %
            %   DRAWLINES(THIS,ST,LT)
            %   Draw one or more lines, with starting X/Y coordinates in ST
            %   and ending X/Y coordinates in LT.  The length of ST and LT
            %   must be identical, and defines the number of lines that
            %   will be drawn.
            %
            %   DRAWLINES(THIS,ST,LT,LW,CLR,ORIG,SM)
            %   Additionally specify the line width LW, the color CLR
            %   (default white), the origin ORIG (default origin [0,0]),
            %   and the smoothing flag SM indicating whether lines should
            %   be smoothed (0 none, 1 anti-aliasing, 2 high-quality).  Any
            %   or all of these can be supplied as empty (i.e. []) to use
            %   defaults.
            
            % defaults
            if nargin<4||isempty(lw),lw=[];end
            if nargin<5||isempty(clr),clr=[];end
            if nargin<6||isempty(orig),orig=[];end
            if nargin<7||isempty(sm),sm=[];end
            
            % process inputs
            if size(st,1)~=2,st=st';end
            assert(size(st,1)==2,'Must provide a 2xN matrix of starting X/Y coordinates (one for each line)');
            nline = size(st,2);
            if size(lt,1)~=2,lt=lt';end
            assert(size(lt,1)==2,'Must provide a 2xN matrix of ending X/Y coordinates (one for each line)');
            assert(size(lt,2)==nline,'Lengths of ST and LT must match');
            if length(lw)==1,lw=repmat(lw,1,nline);end
            assert(isempty(lw)|length(lw)==nline,'Must provide line width for each line');
            if min(size(clr))==1,clr=repmat(clr(:),1,nline);end % single color applied to all lines
            assert(isempty(clr)|size(clr,2)==nline,'Must provide either a single R, G, B triplet or R, G, B, A quadruplet, or one per position'); % validate
            
            % transform start and end points into PTB configuration
            % (consecutive pairs of start/end points as columns in a
            % two-row matrix).
            xy = nan(2,2*nline);
            xy(1:2:end,:) = st;
            xy(2:2:end,:) = lt;
            
            % construct further arguments
            args = {};
            if ~isempty(lw)
                args = [args {lw}];
                if ~isempty(clr)
                    args = [args {clr}];
                    if ~isempty(orig)
                        args = [args {orig}];
                        if ~isempty(sm)
                            args = [args {sm}];
                        end
                    end
                end
            end
            
            % draw the lines
            Screen('DrawLines',this.win,xy,args{:});
        end % END function drawLines
        
        function drawShapes(this,pos,sz,clr,shp,varargin)
            % DRAWSHAPES Single interface to draw multiple shapes
            %
            %   DRAWSHAPES(THIS,POS,SZ,CLR,SHP)
            %   Draw one or more shapes at positions in POS, with sizes in
            %   SZ, colors in CLR, shape identifiers in SHP, and any 
            %   additional required arguments in ARGS.  POS should have
            %   [X,Y] pairs in columns.  SZ should have [W,H] pairs in
            %   columns.  CLR should have [R,G,B] triplets or [R,G,B,A]
            %   quadruplets in columns.
            %
            %   If the number of shapes to be drawn, NPOS, is different
            %   from 2, some logic will be applied to re-orient POS if
            %   necessary.  (For NPOS==2, POS will be 2x2 so it must
            %   be provided in the correct orientation -- [X,Y] pairs as
            %   columns.)
            %
            %   If SZ is a scalar, it will be the (symmetric) size for all
            %   NPOS shapes.  If SZ is a length-NPOS vector, the elements
            %   of SZ will be the (symmetric) size values for each shape.
            %   If NPOS~=2 and SZ is a length-2 vector, it will be the
            %   common width and height for all NPOS shapes. Otherwise, SZ
            %   must be a 2xNPOS or NPOSx2 matrix.
            %
            %   If CLR is a length-3 or length-4 vector, it will be
            %   interpreted as the common color for all NPOS shapes.
            %   Otherwise, CLR must have NPOS rows or columns, each a
            %   triplet or quadruplet color specification.
            %
            %   SHP must be a cell array of strings with one cell per 
            %   shape.  Valid shape strings include 'oval', 'ovalframe',
            %   'rect', 'rectframe', 'square', and 'triangle'.  For 
            %   'triangle', the first row of SZ will be interpreted as the
            %   altitude of the isosceles triangle (base-tip height) and
            %   the second row ignored.
            %
            %   See also DRAWOVAL, DRAWOVALFRAME, DRAWRECT, DRAWRECTFRAME,
            %   DRAWSQUARE, DRAWTRIANGLE, DRAWPOLY, and DRAWPOLYFRAME.
            
            % process any overriding inputs
            [varargin,voffset] = util.argkeyval('voffset',varargin,0);
            [varargin,hoffset] = util.argkeyval('hoffset',varargin,0);
            
            % handle multiple shapes
            if size(pos,1)~=2,pos=pos';end
            if size(pos,1)~=2,pos=this.screenCenter(:);end
            npos = size(pos,2);
            if isscalar(sz),sz=repmat(sz,size(pos));end % scalar size replicated as width/height of all positions
            if min(size(sz))==1&&max(size(sz))==npos,sz=repmat(sz(:)',2,1);end % one value per shape, replicated to symmetric width/height
            if min(size(sz))==1&&max(size(sz))==2,sz=repmat(sz(:),1,npos);end % width/height replicated for all positions
            if size(sz,1)~=2,sz=sz';end % re-orient if needed
            assert(size(sz,2)==npos,'Must provide width and height as a 2xN or Nx2 matrix'); % validate
            if min(size(clr))==1,clr=repmat(clr(:),1,npos);end % single color applied to all positions
            assert(size(clr,2)==npos,'Must provide either a single R, G, B triplet or R, G, B, A quadruplet, or one per position'); % validate
            if ischar(shp),shp=arrayfun(@(x)shp,1:npos,'UniformOutput',false);end % if char, replicate one per npos
            shp = util.ascell(shp); % ensure SHP is a cell array
            assert(length(shp)==npos,'SHP must be a 1xNPOS cell array'); % validate length of SHP
            if length(voffset)==1,voffset=voffset*ones(1,npos);end % voffset vector of length NPOS
            if size(voffset,2)~=npos,voffset=voffset';end % voffset orientation
            assert(length(voffset)==npos,'VOFFSET must contain one value per shape'); % validate voffset length
            if length(hoffset)==1,hoffset=hoffset*ones(1,npos);end % hoffset vector of length NPOS
            if size(hoffset,2)~=npos,hoffset=hoffset';end % hoffset orientation
            assert(length(hoffset)==npos,'HOFFSET must contain one value per shape'); % validate hoffset length
            
            % add offsets to location
            pos = pos + [hoffset; voffset;];
            
            % draw like shapes simultaneously
            [shape_values,~,shape_indices] = unique(shp);
            for vv=1:length(shape_values)
                idx = find(shape_indices==vv);
                
                % determine the appropriate function
                switch lower(shape_values{vv})
                    case 'square' % drawSquare(this,pos,sz,clr)
                        fn = @drawSquare;
                        args{1} = {pos(:,idx),sz(:,idx),clr(:,idx)};
                        for nn=1:length(varargin)
                            args{1} = [args{1} {varargin{nn}(:,idx)}];
                        end
                    case 'oval' % drawOval(this,pos,sz,clr)
                        fn = @drawOval;
                        args{1} = {pos(:,idx),sz(:,idx),clr(:,idx)};
                        for nn=1:length(varargin)
                            args{1} = [args{1} {varargin{nn}(:,idx)}];
                        end
                    case 'ovalframe' % drawOvalFrame(this,pos,sz,clr,pnw)
                        fn = @drawOvalFrame;
                        args{1} = {pos(:,idx),sz(:,idx),clr(:,idx)};
                        for nn=1:length(varargin)
                            args{1} = [args{1} {varargin{nn}(:,idx)}];
                        end
                    case 'rect' % drawRect(this,pos,sz,clr)
                        fn = @drawRect;
                        args{1} = {pos(:,idx),sz(:,idx),clr(:,idx)};
                        for nn=1:length(varargin)
                            args{1} = [args{1} {varargin{nn}(:,idx)}];
                        end
                    case 'rectframe' % drawRectFrame(this,pos,sz,clr,pnw)
                        fn = @drawRectFrame;
                        args{1} = {pos(:,idx),sz(:,idx),clr(:,idx)};
                        for nn=1:length(varargin)
                            args{1} = [args{1} {varargin{nn}(:,idx)}];
                        end
                    case 'triangle' % drawTriangle(this,pos,alt,clr)
                        fn = @drawTriangle;
                        args = cell(1,length(idx));
                        for kk=1:length(idx)
                            args{kk} = {pos(:,idx(kk)),sz(1,idx(kk)),clr(:,idx(kk))'};
                            for nn=1:length(varargin)
                                args{kk} = [args{kk} {varargin{nn}(:,idx(kk))}];
                            end
                        end
                    case 'poly' % drawPoly(this,vert,clr,isConvex)
                        fn = @drawPoly;
                        args = cell(1,length(idx));
                        for kk=1:length(idx)
                            args{kk} = {pos(:,idx(kk)),clr(:,idx(kk))',true};
                            for nn=1:length(varargin)
                                args{kk} = [args{kk} {varargin{nn}(:,idx(kk))}];
                            end
                        end
                    case 'polyframe' % drawPolyFrame(this,vert,clr,pnw)
                        fn = @drawPolyFrame;
                        args = cell(1,length(idx));
                        for kk=1:length(idx)
                            args{kk} = {pos(:,idx(kk)),clr(:,idx(kk))'};
                            for nn=1:length(varargin)
                                args{kk} = [args{kk} {varargin{nn}(:,idx(kk))}];
                            end
                        end
                    otherwise
                        error('Unknown target shape ''%s''',shape_values{vv});
                end
                
                % execute the function
                for kk=1:length(args)
                    feval(fn,this,args{kk}{:});
                end
            end
        end % END function drawShapes
        
        function drawOval(this,pos,sz,clr)
            % DRAWOVAL Draw an oval
            %
            %   DRAWOVAL(THIS,POS,SZ,CLR)
            %   Draw one or more filled ovals at positions in POS, with
            %   sizes in SZ, and colors in CLR.  Positions should be
            %   provided as [X,Y] pairs in columns of POS.  Sizes should be
            %   provided as [W,H] pairs in columns of SZ.  Colors should be
            %   provided as [R,G,B] triplets or [R,G,B,A] quadruplets in
            %   columns of CLR.
            %
            %   If the number of shapes to be drawn, NPOS, is different
            %   from 2, some logic will be applied to re-orient POS if
            %   necessary.  (For NPOS==2, POS will be 2x2 so it must
            %   be provided in the correct orientation -- [X,Y] pairs as
            %   columns.)
            %
            %   If SZ is a scalar, it will be the (symmetric) size for all
            %   NPOS shapes.  If SZ is a length-NPOS vector, the elements
            %   of SZ will be the (symmetric) size values for each shape.
            %   If NPOS~=2 and SZ is a length-2 vector, it will be the
            %   common width and height for all NPOS shapes. Otherwise, SZ
            %   must be a 2xNPOS or NPOSx2 matrix.
            %
            %   If CLR is a length-3 or length-4 vector, it will be
            %   interpreted as the common color for all NPOS shapes.
            %   Otherwise, CLR must have NPOS rows or columns, each a
            %   triplet or quadruplet color specification.
            
            % handle multiple positions
            if size(pos,1)~=2,pos=pos';end
            assert(size(pos,1)==2,'Position must be Nx2 or 2xN');
            npos = size(pos,2);
            if isscalar(sz),sz=repmat(sz,size(pos));end % scalar size replicated as width/height of all positions
            if min(size(sz))==1&&max(size(sz))==npos,sz=repmat(sz(:)',2,1);end % one value per shape, replicated to symmetric width/height
            if min(size(sz))==1&&max(size(sz))==2,sz=repmat(sz(:),1,npos);end % width/height replicated for all positions
            if size(sz,1)~=2,sz=sz';end % re-orient if needed
            assert(size(sz,2)==npos,'Must provide width and height as a 2xN or Nx2 matrix'); % validate
            if min(size(clr))==1,clr=repmat(clr(:),1,npos);end % single color applied to all positions
            assert(size(clr,2)==npos,'Must provide either a single R, G, B triplet or R, G, B, A quadruplet, or one per position'); % validate
            
            % generate bounding boxes
            box = DisplayClient.PsychToolbox.convertToBox(pos,sz);
            
            % local or remote target
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('FillOval',this.win,clr,box);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''FillOval'',%%d,%s,%s);',...
                        util.vec2str(clr,'[%g]'),util.vec2str(box,'[%g]')));
                otherwise
                    error('unknown target');
            end
        end % END function drawOval
        
        function drawOvalFrame(this,pos,sz,clr,pnw)
            % DRAWOVALFRAME Draw an unfilled rectangle
            %
            %   DRAWOVALFRAME(THIS,POS,SZ,CLR,PNW)
            %   Draw one or more unfilled ovals at positions in POS, with
            %   sizes in SZ, colors in CLR, and pen widths in PNW.
            %   Positions should be provided as [X,Y] pairs in columns of
            %   POS.  Sizes should be provided as [W,H] pairs in columns of
            %   SZ.  Colors should be provided as [R,G,B] triplets or
            %   [R,G,B,A] quadruplets in columns of CLR.  Pen widths should
            %   be provided as a vector.
            %
            %   If the number of shapes to be drawn, NPOS, is different
            %   from 2, some logic will be applied to re-orient POS if
            %   necessary.  (For NPOS==2, POS will be 2x2 so it must
            %   be provided in the correct orientation -- [X,Y] pairs as
            %   columns.)
            %
            %   If SZ is a scalar, it will be the (symmetric) size for all
            %   NPOS shapes.  If SZ is a length-NPOS vector, the elements
            %   of SZ will be the (symmetric) size values for each shape.
            %   If NPOS~=2 and SZ is a length-2 vector, it will be the
            %   common width and height for all NPOS shapes. Otherwise, SZ
            %   must be a 2xNPOS or NPOSx2 matrix.
            %
            %   If CLR is a length-3 or length-4 vector, it will be
            %   interpreted as the common color for all NPOS shapes.
            %   Otherwise, CLR must have NPOS rows or columns, each a
            %   triplet or quadruplet color specification.
            %
            %   If PNW is omitted, the default value of 1.0 will be used.
            %   If PNW is a scalar, it will be replicated as the common pen
            %   width for all NPOS shapes.  Otherwise, it must be a
            %   length-NPOS vector.
            
            % handle multiple positions
            if size(pos,1)~=2,pos=pos';end
            assert(size(pos,1)==2,'Position must be Nx2 or 2xN');
            npos = size(pos,2);
            if isscalar(sz),sz=repmat(sz,size(pos));end % scalar size replicated as width/height of all positions
            if min(size(sz))==1&&max(size(sz))==npos,sz=repmat(sz(:)',2,1);end % one value per shape, replicated to symmetric width/height
            if min(size(sz))==1&&max(size(sz))==2,sz=repmat(sz(:),1,npos);end % width/height replicated for all positions
            if size(sz,1)~=2,sz=sz';end % re-orient if needed
            assert(size(sz,2)==npos,'Must provide width and height as a 2xN or Nx2 matrix'); % validate
            if min(size(clr))==1,clr=repmat(clr(:),1,npos);end % single color applied to all positions
            assert(size(clr,2)==npos,'Must provide either a single R, G, B triplet or R, G, B, A quadruplet, or one per position'); % validate
            if nargin<5,pnw=1;end
            if isscalar(pnw),pnw=pnw*ones(1,npos);end
            assert(length(pnw)==npos,'If provided, PNW must be either a scalar or a vector with one element per position');
            
            % generate bounding box
            box = DisplayClient.PsychToolbox.convertToBox(pos,sz);
            
            % local or remote target
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('FrameOval',this.win,clr,box,pnw);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''FrameOval'',%%d,%s,%s,%s);',...
                        util.vec2str(clr,'[%g]'),util.vec2str(box,'[%g]'),util.vec2str(pnw,'[%g]')));
                otherwise
                    error('unknown target');
            end
        end % END function drawOvalFrame
        
        function drawRect(this,pos,sz,clr)
            % DRAWRECT Draw a rectangle
            %
            %   DRAWRECT(THIS,POS,SZ,CLR)
            %   Draw one or more filled rectangles at positions in POS,
            %   with sizes in SZ, and colors in CLR.  Positions should be
            %   provided as [X,Y] pairs in columns of POS.  Sizes should be
            %   provided as [W,H] pairs in columns of SZ.  Colors should be
            %   provided as [R,G,B] triplets or [R,G,B,A] quadruplets in
            %   columns of CLR.
            %
            %   If the number of shapes to be drawn, NPOS, is different
            %   from 2, some logic will be applied to re-orient POS if
            %   necessary.  (For NPOS==2, POS will be 2x2 so it must
            %   be provided in the correct orientation -- [X,Y] pairs as
            %   columns.)
            %
            %   If SZ is a scalar, it will be the (symmetric) size for all
            %   NPOS shapes.  If SZ is a length-NPOS vector, the elements
            %   of SZ will be the (symmetric) size values for each shape.
            %   If NPOS~=2 and SZ is a length-2 vector, it will be the
            %   common width and height for all NPOS shapes. Otherwise, SZ
            %   must be a 2xNPOS or NPOSx2 matrix.
            %
            %   If CLR is a length-3 or length-4 vector, it will be
            %   interpreted as the common color for all NPOS shapes.
            %   Otherwise, CLR must have NPOS rows or columns, each a
            %   triplet or quadruplet color specification.
            
            % handle multiple positions
            if size(pos,1)~=2,pos=pos';end
            assert(size(pos,1)==2,'Position must be Nx2 or 2xN');
            npos = size(pos,2);
            if isscalar(sz),sz=repmat(sz,size(pos));end % scalar size replicated as width/height of all positions
            if min(size(sz))==1&&max(size(sz))==npos,sz=repmat(sz(:)',2,1);end % one value per shape, replicated to symmetric width/height
            if min(size(sz))==1&&max(size(sz))==2,sz=repmat(sz(:),1,npos);end % width/height replicated for all positions
            if size(sz,1)~=2,sz=sz';end % re-orient if needed
            assert(size(sz,2)==npos,'Must provide width and height as a 2xN or Nx2 matrix'); % validate
            if min(size(clr))==1,clr=repmat(clr(:),1,npos);end % single color applied to all positions
            assert(size(clr,2)==npos,'Must provide either a single R, G, B triplet or R, G, B, A quadruplet, or one per position'); % validate
            
            % generate bounding boxes
            box = DisplayClient.PsychToolbox.convertToBox(pos,sz);
            
            % local or remote target
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('FillRect',this.win,clr,box);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''FillRect'',%%d,%s,%s);',...
                        util.vec2str(clr,'[%g]'),util.vec2str(box,'[%g]')));
                otherwise
                    error('unknown target');
            end
        end % END function drawRect
        
        function drawRectFrame(this,pos,sz,clr,pnw)
            % DRAWRECTFRAME Draw an unfilled rectangle
            %
            %   DRAWRECTFRAME(THIS,POS,SZ,CLR,PNW)
            %   Draw one or more unfilled rectangles at positions in POS,
            %   with sizes in SZ, colors in CLR, and pen widths in PNW.
            %   Positions should be provided as [X,Y] pairs in columns of
            %   POS.  Sizes should be provided as [W,H] pairs in columns of
            %   SZ.  Colors should be provided as [R,G,B] triplets or
            %   [R,G,B,A] quadruplets in columns of CLR.  Pen widths should
            %   be provided as a vector.
            %
            %   If the number of shapes to be drawn, NPOS, is different
            %   from 2, some logic will be applied to re-orient POS if
            %   necessary.  (For NPOS==2, POS will be 2x2 so it must
            %   be provided in the correct orientation -- [X,Y] pairs as
            %   columns.)
            %
            %   If SZ is a scalar, it will be the (symmetric) size for all
            %   NPOS shapes.  If SZ is a length-NPOS vector, the elements
            %   of SZ will be the (symmetric) size values for each shape.
            %   If NPOS~=2 and SZ is a length-2 vector, it will be the
            %   common width and height for all NPOS shapes. Otherwise, SZ
            %   must be a 2xNPOS or NPOSx2 matrix.
            %
            %   If CLR is a length-3 or length-4 vector, it will be
            %   interpreted as the common color for all NPOS shapes.
            %   Otherwise, CLR must have NPOS rows or columns, each a
            %   triplet or quadruplet color specification.
            %
            %   If PNW is omitted, the default value of 1.0 will be used.
            %   If PNW is a scalar, it will be replicated as the common pen
            %   width for all NPOS shapes.  Otherwise, it must be a
            %   length-NPOS vector.
            
            % handle multiple positions
            if size(pos,1)~=2,pos=pos';end
            assert(size(pos,1)==2,'Position must be Nx2 or 2xN');
            npos = size(pos,2);
            if isscalar(sz),sz=repmat(sz,size(pos));end % scalar size replicated as width/height of all positions
            if min(size(sz))==1&&max(size(sz))==npos,sz=repmat(sz(:)',2,1);end % one value per shape, replicated to symmetric width/height
            if min(size(sz))==1&&max(size(sz))==2,sz=repmat(sz(:),1,npos);end % width/height replicated for all positions
            if size(sz,1)~=2,sz=sz';end % re-orient if needed
            assert(size(sz,2)==npos,'Must provide width and height as a 2xN or Nx2 matrix'); % validate
            if min(size(clr))==1,clr=repmat(clr(:),1,npos);end % single color applied to all positions
            assert(size(clr,2)==npos,'Must provide either a single R, G, B triplet or R, G, B, A quadruplet, or one per position'); % validate
            if nargin<5,pnw=1;end
            if isscalar(pnw),pnw=pnw*ones(1,npos);end
            assert(length(pnw)==npos,'If provided, PNW must be either a scalar or a vector with one element per position');
            
            % generate bounding box
            box = DisplayClient.PsychToolbox.convertToBox(pos,sz);
            
            % local or remote target
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('FrameRect',this.win,clr,box,pnw);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''FrameRect'',%%d,%s,%s,%s);',...
                        util.vec2str(clr,'[%g]'),util.vec2str(box,'[%g]'),util.vec2str(pnw,'[%g]')));
                otherwise
                    error('unknown target');
            end
        end % END function drawRectFrame
        
        function drawPoly(this,vert,clr,isConvex)
            % DRAWPOLY Draw a rectangle
            %
            %   DRAWPOLY(THIS,VERT,CLR,ISCONVEX)
            %   Draw a filled polygon with vertices in VERT and colors in
            %   CLR.  Vertices should be provided as [X,Y] pairs in rows of
            %   VERT.  Colors should be provided as an [R,G,B] triplet or 
            %   [R,G,B,A] quadruplet in CLR.  ISCONVEX defaults to true,
            %   which results in considerable speedup if accurate.
            %
            %   See also SCREEN.
            
            % validate inputs
            if size(vert,2)~=2,vert=vert';end
            assert(size(vert,2)==2,'VERT must be Nx2 or 2xN');
            assert(any(ismember(length(clr),[3 4])),'CLR must be either a [R,G,B] triplet or [R,G,B,A] quadruplet'); % validate
            if nargin<4,isConvex=1;end
            
            % local or remote target
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('FillPoly',this.win,clr,vert,isConvex);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''FillPoly'',%%d,%s,%s,%d);',util.vec2str(clr,'[%g]'),util.vec2str(vert,'[%g]'),isConvex));
                otherwise
                    error('unknown target');
            end
        end % END function drawPoly
        
        function drawPolyFrame(this,vert,clr,pnw)
            % DRAWPOLYFRAME Draw a rectangle
            %
            %   DRAWPOLYFRAME(THIS,VERT,CLR,PNW)
            %   Draw an unfilled polygon with vertices in VERT and colors
            %   in CLR.  Vertices should be provided as [X,Y] pairs in rows
            %   of VERT.  Colors should be provided as an [R,G,B] triplet
            %   or [R,G,B,A] quadruplet in CLR.  If PNW is omitted, the
            %   default value of 1.0 will be used.
            %
            %   See also SCREEN.
            
            % validate inputs
            if size(vert,2)~=2,vert=vert';end
            assert(size(vert,2)==2,'VERT must be Nx2 or 2xN');
            assert(any(ismember(length(clr),[3 4])),'CLR must be either a [R,G,B] triplet or [R,G,B,A] quadruplet'); % validate
            if nargin<4,pnw=1.0;end
            
            % local or remote target
            switch lower(this.target)
                case 'local'
                    assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
                    Screen('FramePoly',this.win,clr,vert,pnw);
                case 'udp'
                    remoteCommand(this,sprintf('Screen(''FillPoly'',%%d,%s,%s,%d);',util.vec2str(clr,'[%g]'),util.vec2str(vert,'[%g]'),pnw));
                otherwise
                    error('unknown target');
            end
        end % END function drawPolyFrame
        
        function drawSquare(this,pos,sz,clr)
            % DRAWSQUARE Draw a square
            %
            %   See also DRAWRECT.
            
            % call drawRect
            drawRect(this,pos,sz,clr);
        end % END function drawSquare
        
        function drawTriangle(this,pos,alt,clr)
            % DRAWTRIANGLE Draw a triangle
            %
            %   See also DRAWPOLY.
            
            % get polygon vertices
            verts = DisplayClient.PsychToolbox.getTriangleVertices(pos,alt);
            
            % draw the polygon
            drawPoly(this,verts,clr);
        end % END function drawTriangle
        
        function drawImage(this,imagename,pos,sz,angl)
            % DRAWIMAGE Draw an image to the screen
            %
            %   DRAWIMAGE(THIS,IMAGENAME,POS,SZ,ANGL)
            %   Draw the image in IMAGENAME to the screen, centered at the
            %   X,Y pair in POS, sized to the width and height specified
            %   in SZ, and with rotation angle ANGL.  If POS is empty or 
            %   not provided, the screen center will be used.  If SZ is a
            %   single value, it will be interpreted as the width and the
            %   height will be scaled to maintain the original aspect
            %   ratio.  If SZ is empty, the image dimensions will be used.
            %   If ANGL is empty or not provided, a rotation of 0 will be
            %   used.
            %
            %   See also SCREEN, DRAWIMAGES, DRAWIMAGEDIRECT.
            
            % validate the window
            assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
            
            % default to center of screen
            if nargin<3||isempty(pos)
                pos = this.screenCenter;
            end
            
            % default to no rotation
            if nargin<5||isempty(angl)
                angl = 0;
            end
            
            % determine whether this image has already been loaded
            id = find(strcmpi(this.ImageNames,imagename));
            if isempty(id)
                
                % look for alias
                which = false;
                try
                    which = strcmpi(this.ImageAliases(:,2),imagename);
                catch er
                    er.message;
                end
                if any(which) && sum(which) == 1
                    id = find(strcmpi(this.uniqueImageID,this.ImageAliases{which,1}));
                elseif any(which)
                    id = find(strcmpi(this.uniqueImageID,this.ImageAliases{find(which,1,'last'),1}));
                else
                    id = loadImage(this,imagename);
                end
            end
            assert(~isempty(id),'Could not identify image ''%s''',imagename);
            
            % read out image dimensions
            dims = this.ImageDimensions{id};
            src = [0 0 dims(1) dims(2)]; % full image
            
            % calculate destination box
            if nargin<4||isempty(sz)
                sz = dims;
            elseif length(sz)==1
                sz(2) = sz(1)*dims(2)/dims(1);
            end
            dest = DisplayClient.PsychToolbox.convertToBox(pos,sz);
            
            % draw the texture
            Screen('DrawTexture',this.win,this.ImageTextures{id},src,dest,angl);
        end % END function drawImage
        
        function drawImages(this,imagenames,pos,sz,angl)
            % DRAWIMAGES Draw multiple images to the screen
            %
            %   DRAWIMAGES(THIS,IMAGENAMES,POS,SZ,ANGL)
            %   Draw the images in IMAGENAMES to the screen centered at the
            %   X,Y pairs in POS, sized to the widths and heights specified
            %   in SZ, and with rotation angle ANGL.  If POS is empty or 
            %   not provided, the screen center will be used.  If SZ is a
            %   single value, it will be interpreted as the width and the
            %   height will be scaled to maintain the original aspect
            %   ratio.  If SZ is empty, the image dimensions will be used.
            %   If ANGL is empty or not provided, a rotation of 0 will be
            %   used.
            %
            %   See also SCREEN, DRAWIMAGE, DRAWIMAGEDIRECT.
            
            % validate the window
            assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
            imagenames = util.ascell(imagenames);
            
            % try to determine how many textures will be drawn
            n=zeros(1,4);
            if nargin>=2,n(1)=length(imagenames);end
            if nargin>=3,n(2)=length(pos(:))/2;end
            if nargin>=4
                if isscalar(sz)
                    n(3)=1;
                elseif min(size(sz))==1
                    n(3)=length(sz);
                else
                    n(3)=length(sz(:))/2;
                end
            end
            if nargin>=5,n(4)=length(angl);end
            nimg = max(n);
            
            % replicate imagenames if needed
            if length(imagenames)==1
                imagenames = repmat(imagenames,1,nimg);
            end
            assert(length(imagenames)==nimg,'Imagenames must be 1x%d cell array',nimg);
            
            % default to center of screen
            if nargin<3||isempty(pos)
                pos = repmat(this.screenCenter(:),1,nimg);
            elseif length(pos(:))==2
                pos = repmat(pos(:),1,nimg);
            elseif length(pos(:))>2 && size(pos,1)~=2
                pos = pos';
            end
            assert(size(pos,1)==2&&size(pos,2)==nimg,'Position must be 2x%d with x and y as rows 1/2 respectively',nimg);
            
            % placeholder for sizing
            if nargin<4||isempty(sz) % ADDED THE ISEMPTY CONDITION 8/30/2015
                sz = nan(2,nimg);
            elseif isscalar(sz)
                sz = [repmat(sz,1,nimg); nan(1,nimg)]; % provided width
            elseif length(sz(:))==2
                sz = repmat(sz(:),1,nimg);
            elseif length(sz(:))>2 && size(sz,1)~=2
                sz = sz';
            end
            assert(size(sz,1)==2&&size(sz,2)==nimg,'Sizing must be 2x%d with width and height as rows 1/2 respectively',nimg);
            
            % default to no rotation
            if nargin<5||isempty(angl)
                angl = zeros(1,nimg);
            elseif length(angl)==1
                angl = repmat(angl,1,nimg);
            end
            assert(length(angl)==nimg,'Angles must be a 1x%d vector',nimg);
            
            % determine whether each image has already been loaded
            id = nan(1,nimg);
            src = nan(4,nimg);
            dst = nan(4,nimg);
            for kk=1:nimg
                
                % determine whether this image already loaded
                tmpid = find(strcmpi(this.ImageNames,imagenames{kk}));
                if ~isempty(tmpid) && ~isnan(tmpid)
                    
                    % already loaded
                    id(kk) = tmpid;
                else
                    
                    % look for alias
                    which = strcmpi(this.ImageAliases(:,2),imagenames{kk});
                    if any(which)
                        id(kk) = find(strcmpi(this.uniqueImageID,this.ImageAliases{which,1}));
                    else
                        id(kk) = loadImage(this,imagenames{kk});
                    end
                end
                
                % determine texture sizing
                dims = this.ImageDimensions{id(kk)};
                if all(isnan(sz(:,kk))) % not provided, use img dims
                    sz(:,kk) = dims;
                elseif isnan(sz(1,kk)) % height provided, scale width
                    sz(1,kk) = sz(2,kk)*dims(1)/dims(2);
                elseif isnan(sz(2,kk)) % width provided, scale height
                    sz(2,kk) = sz(1,kk)*dims(2)/dims(1);
                end
                
                % calculate source box (full image)
                src(:,kk) = [0 0 dims(1) dims(2)];
                
                % calculate destination box
                dst(:,kk) = DisplayClient.PsychToolbox.convertToBox(pos(:,kk),sz(:,kk));
            end
            
            % draw the texture
            Screen('DrawTextures',this.win,[this.ImageTextures{id}],src,dst,angl);
        end % END function drawImages
        
        function drawImageDirect(this,pos,sz,texture,rotAngle)
            assert(ismember(this.win,Screen('Windows')),'Invalid window pointer');
            if nargin<5; rotAngle=[]; end
            
            pos = normPos2Client(this,pos);
            if ~isempty(sz)
                sz = normScale2Client(this,sz);
                dest = DisplayClient.PsychToolbox.convertToBox(pos,sz);
            else
                dest = [];
            end
            Screen('DrawTexture',this.win,texture,[],dest,rotAngle);
        end % END function drawImageDirect
        
        function position = normPos2Client(this,normpos)
            % REQUIRE that normpos be in horiz/vert or horiz/vert/depth
            tmppos = this.fudgeScalingFactor*100*normpos;
            if length(tmppos)>1
                tmppos(2) = -tmppos(2); % reverse y direction
            end
            tmppos = tmppos./(this.monitorSize/2); % normalize to screen width
            position = tmppos .* (this.displayResolution/2) + this.screenCenter; % convert from normalized [-1,1] to pixels [0,pixelsWidth]
        end % END function normPos2Client
        
        function scale = normScale2Client(this,normscale)
            % REQUIRE that normscale be in horiz/vert or horiz/vert/depth
            if length(normscale)>1
                %warning('broken!!');
                scale(1:2) = normscale(1:2) .* this.displayResolution; % convert from normalized [0,1] to pixels [0,pixelsWidth]
                if length(scale) > 2
                    scale(3:end) = normscale(3:end) * this.displayResolution(1); % use width for scaling any other dimensions
                end
            else
                normscale = this.fudgeScalingFactor*100*normscale/(this.monitorSize(1)/2); % use width for normalizing scale
                scale = normscale * (this.displayResolution(1)/2); % use width for scaling any other dimensions
            end
        end % END function normScale2Client
        
        function updateObject(this,obj,varargin)
            assert(isa(obj,'DisplayClient.PsychToolboxObjectInterface'),'Objects must inherit DisplayClient.PsychToolboxObjectInterface');
            position = normPos2Client(this,obj.getDisplayPosition);
            scale = normScale2Client(this,obj.scale);
            color = obj.color * obj.brightness;
            shape = obj.shape;
            if any(isinf(position)) || any(isinf(scale)) || any(isnan(position)) || any(isnan(scale))
                warning('Inf or NaN encountered in position or scale data\n');
                if this.debug==1, keyboard; end
                return;
            end
            switch lower(shape)
                case 'oval'
                    drawOval(this,position,scale,color,varargin{:});
                case 'ovalframe'
                    drawOvalFrame(this,position,scale,color,varargin{:});
                case 'square'
                    drawSquare(this,position,scale,color,varargin{:});
                case 'triangle'
                    drawTriangle(this,position,scale,color,varargin{:});
                case 'image'
                    drawImage(this,obj.imagefile,position,scale,obj.angles,varargin{:});
                    %drawImage(this,position,scale,obj.imagefile);
                otherwise
                    warning('Unrecognized shape ''%s''',shape);
            end
        end % END function updateObject
        
        function createObject(this,obj)
            % CREATEOBJECT Unused, but will check proper inheritance
            
            % check inheritance
            assert(isa(obj,'DisplayClient.PsychToolboxObjectInterface'),'Objects must inherit DisplayClient.PsychToolboxObjectInterface');
        end % END function createObject
        
        function r = getResource(~,~)
            r = '';
        end % END function getResource
        
        function returnResource(~,~)
        end % END function returnResource
        
        function screenshot(this,outpath)
            
            % pull the image data from the buffer (default front buffer)
            imarray = Screen('GetImage',this.win);
            
            % set up default path
            if nargin<2||isempty(outpath)
                outpath = fullfile('.',sprintf('ptb_screenshot_%s.png',datestr(now,'yyyymmdd-HHMMSS-FFF')));
            end
            
            % write the image file
            try
                imwrite(imarray,outpath);
            catch ME
                util.errorMessage(ME);
            end
        end % END function screenshot
        
        function skip = structableSkipFields(this)
            skip1 = structableSkipFields@DisplayClient.Interface(this);
            skip = [skip1 {'hSend','hReceive','win'}];
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st1 = structableManualFields@DisplayClient.Interface(this);
            st2 = [];
            st = util.catstruct(st1,st2);
        end % END function structableManualFields
        
        function delete(this)
            
            % restore PTB verbosity
            if ~isempty(this.ptbOldVerbosityLevel)
                Screen('Preference','Verbosity',this.ptbOldVerbosityLevel);
            end
            
            % Close window, release all ressources
            if ismember(this.win,Screen('Windows'))
                Screen('Flip',this.win);
            end
            Screen('CloseAll');
            WaitSecs(1);
            
            % udp objects
            try util.deleteUDP(this.hSend); catch ME, util.errorMessage(ME); end
            try util.deleteUDP(this.hReceive); catch ME, util.errorMessage(ME); end
        end % END function delete
    end % END methods
    
    methods(Static)
        % function p = toClientWorkspace(client,position)
        %     p = position.*client.calibrationPositionGain + client.calibrationOrigin;
        %     p(2) = -p(2); % flip y
        % end % END function toClientWorkspace
        %
        % function p = fromClientWorkspace(client,position)
        %     p = (position-client.calibrationOrigin)./client.calibrationPositionGain;
        %     p(2) = -p(2); % flip y
        % end % END function fromClientWorkspace
        
        function [h,w] = norm2client(h,w,varargin)
            type = 'pixel';
            if nargin>2, type=varargin{1}; end
            
            switch lower(type)
                case {'px','pixel','pixels'}
                    w = w*client.displayResolution(1);
                    h = h*client.displayResolution(2);
                case {'cm','centimeter'}
                    h = h*client.monitorSize;
                otherwise
                    error('DisplayClient:PsychToolbox:UnknownType','Unknown type ''%s''',type);
            end
            
        end % END function norm2client
        
        function box = convertToBox(pos,sz)
            % CONVERTTOBOX Create box vector for psychtoolbox
            %
            %   BOX = CONVERTTOBOX(POS,SZ)
            %   Create a box with elements [LEFT TOP RIGHT BOTTOM] centered
            %   at POS with width and height SZ.  If SZ is scalar, the box
            %   will be symmetric (all side same length).  If SZ has both
            %   width and height, the box will be sized accordingly.
            %
            %   To generate multiple boxes, provide N positions in POS as a
            %   2xN matrix.  If SZ is scalar, it will be interpreted as the
            %   (symmetric) size parameter for each of the N boxes.  If SZ
            %   is a length-N vector, it will be interpreted as a list of
            %   (symmetric) size parameters for each of the N boxes.  If
            %   N~=2 and SZ is a length-2 vector, it will be replicated as
            %   the width and height for all N boxes.  Otherwise, SZ should
            %   be a 2xN or Nx2 matrix containing width and height for each
            %   of the N boxes.
            %
            %   If N~=2 (i.e., POS is not 2x2), some logic will be applied
            %   to re-orient inputs as needed (when N==2, POS will be 2x2
            %   and so must be provided as expected, i.e., with [X,Y] pairs
            %   in columns).
            %
            %   Note that Psychtoolbox uses Apple/Mac convention (origin is
            %   top-left) vs. MATLAB convention (origin is bottom-left), so
            %   vertical dimension should be flipped.
            
            % handle multiple positions
            if size(pos,1)~=2,pos=pos';end % re-orient to 2xN if needed
            assert(size(pos,1)==2,'Position must be Nx2 or 2xN'); % validate
            npos = size(pos,2);
            if isscalar(sz),sz=repmat(sz,size(pos));end % scalar size replicated as width/height of all positions
            if min(size(sz))==1&&max(size(sz))==npos,sz=repmat(sz(:)',2,1);end % one value per box, replicated to symmetric width/height
            if min(size(sz))==1&&max(size(sz))==2,sz=repmat(sz(:),1,npos);end % width/height replicated for all positions
            if size(sz,1)~=2,sz=sz';end % re-orient if needed
            assert(size(sz,2)==npos,'Must provide width and height as a 2xN or Nx2 matrix'); % validate
            
            % create box
            w = sz(1,:);
            h = sz(2,:);
            box = round([
                pos(1,:)-w/2 % left
                pos(2,:)-h/2 % top
                pos(1,:)+w/2 % right
                pos(2,:)+h/2]); % bottom
        end % END function convertToBox
        
        function vert = getTriangleVertices(pos,alt)
            % GETTRIANGLEVERTICES Get vertices of a triangle
            %
            %   VERT = GETTRIANGLEVERTICES(POS,ALT)
            %   Generate the vertices of an isosceles triangle with base
            %   equal to height (base angles 45 degrees), centered at POS
            %   with altitude ALT.
            
            % calculate the half-height
            halfa = 0.5*alt;
            
            % construct the vertices
            vert = [...
                pos(1),          pos(2)-halfa; % top vertex
                pos(1)+halfa,    pos(2)+halfa; % bottom-right vertex
                pos(1)-halfa,    pos(2)+halfa; % bottom-left vertex
                ];
        end % END function getTriangleVertices
        
        function scalingFactor = units2Pixels(units,widthPixels,widthUnits,distanceUnits)
            
            switch lower(units)
                case {'cm','centimeters','in','inches'}
                    scalingFactor = widthPixels/widthUnits;
                case {'ppd', 'pixelsperdegree'}
                    scalingFactor = pi * (widthPixels) / atan(widthUnits/distanceUnits/2) / 360;
            end
        end % END function units2Pixels
    end % END methods(Static)
    
end % END classdef PsychToolbox