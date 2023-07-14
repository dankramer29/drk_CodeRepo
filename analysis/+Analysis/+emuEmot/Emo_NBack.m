% Emotional faces N-Back task.
%
% Can be run in emotion-match mode or identity-match mode
%
% Rex Tien March 14 2021
% 
% Updated April 1 2021 to add image selection based on validity and
% reliability scores, added choice time-out - RT
%
% Updated August 23 2022 to add audio and video recording, 

%----------------------------------------------------------------------
%                              Setup
%----------------------------------------------------------------------

% Clear the workspace
close all;
clearvars;
sca;

%%
%----------------------------------------------------------------------
%                       Task Parameter Setup
%----------------------------------------------------------------------

% Do Cedrus?
Settings.Do_Cedrus = true;
% Settings.Do_Cedrus = false;

% Do Audio?
Settings.Do_Audio = true;

% Do Video?
Settings.Do_Video = true;

% Define hex event codes
Events.Codes.Task_Start = 619;
Events.Codes.Image_Shown = 629;
Events.Codes.Fixation_Shown = 639;
Events.Codes.Response_Made = 649;
if Settings.Do_Audio
    Events.Codes.Audio_Start = 669;
    Events.Codes.Audio_Stop = 679;
end
if Settings.Do_Video
    Events.Codes.First_Video_Frame = 689;
    Events.Codes.Thousandth_Video_Frame = 699;
    frameflag = true;
end

% Initialize Cedrus device for hex TTL
if Settings.Do_Cedrus
    [~, device] = Cedrus_TTL();
end

% Get the image directory (RADIATE_SELECT)
% fprintf('Select directory where face images are stored.\n');
% faceDir = uigetdir();
% faceDir = 'C:\Users\Rex\Dropbox\Anschutz\Data\RADIATE_SELECT';
faceDir = 'C:\Users\jatne\OneDrive\Documents\EmotionTasks_Cedrus\RADIATE_SELECT';

% Get the save directory. Create it if it doesn't exist.
% fprintf('Select directory to save results.\n');
% saveDir = uigetdir();
% saveDir = 'C:\Users\Rex\Dropbox\Anschutz\Data\EmotionResults';
dstr = datestr(now,'mm-dd-yy');
saveDir = ['C:\Users\jatne\OneDrive\Documents\EmotionTasks_Cedrus\EmotionTasks_Results_' dstr];
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

if Settings.Do_Audio
    % Set up audio recording
    reco = audiorecorder(44100, 16, 1, 1);
    record(reco);
    if Settings.Do_Cedrus
        write(device,sprintf("mh%c%c",Events.Codes.Audio_Start, 0), "char");
    end
    Events.Times.Audio_Start = now;
end

if Settings.Do_Video
    % Set up video recording - this setup is for low HD monochrome
    cam = webcam('HD Pro Webcam C920');
    framerate = 30;
    frametime = 1/framerate;
    vidbufft = 900;
    nbuffframes = framerate*vidbufft;
    cam.Resolution = '640x480';
    vidbuffer = zeros(480, 640, 1, nbuffframes, 'uint8');
    Events.Times.Video_Frame = nan(nbuffframes,1);
    vidi = 1;
end

% Is it a practice session or real?
defaultIsPractice = 0;
ispractice = input(['Is this practice? 1 = practice or 0 = real, default is (' num2str(defaultIsPractice) ')\n']);
if isempty(ispractice)
    ispractice = defaultIsPractice;
elseif ispractice > 1 || floor(ispractice) ~= ispractice || ispractice < 0
    ispractice = defaultIsPractice;
end
if ispractice == 0
    fprintf('True session - will save.\n\n');
else
    fprintf('Practice Session - won''t save.\n\n');
end

% Get the number of images to display
defaultSettings.N_Images = 54;
if ispractice
    Settings.N_Images = input(['Enter the number of images to display.\nJust press Enter for default (' num2str(defaultSettings.N_Images) ')\n']);
    if isempty(Settings.N_Images)
        fprintf('Using default number of images: %i\n\n', defaultSettings.N_Images);
        Settings.N_Images = defaultSettings.N_Images;
    elseif Settings.N_Images < 1 || floor(Settings.N_Images) ~= Settings.N_Images
        fprintf('Bad number of images entered - using default number of images: %i\n\n', defaultSettings.N_Images);
        Settings.N_Images = defaultSettings.N_Images;
    end
else
    Settings.N_Images = defaultSettings.N_Images;
end
fprintf('Will display %i images\n\n', Settings.N_Images);

% Select the matching paradigm (emotion or identity)
defaultMatchType = 1;
Match_Type = input('Enter the type of matching to be performed.\nEnter ''1'' for Emotion matching or ''2'' for Identity matching.\nJust press Enter for default (Emotion)\n');
if isempty(Match_Type)
%     fprintf('Using default matching paradigm: Emotion\n\n');
    Match_Type = defaultMatchType;
elseif Match_Type ~= 1 && Match_Type ~= 2
%     fprintf('Unknown value entered. Using default paradigm: Emotion\n\n');
    Match_Type = defaultMatchType;
end

if Match_Type == 1
    fprintf('Matching Emotion\n\n');
elseif Match_Type == 2
    fprintf('Matching Identity\n\n');
end

% Select degree of N-back
defaultSettings.N_Back = 1;
% Settings.N_Back = input(['Enter the degree of N-back.\nJust press enter for default (' num2str(defaultSettings.N_Back) ')\n']);
% if isempty(Settings.N_Back)
% %     fprintf('Using default N-back of degree %i\n\n', defaultSettings.N_Back);
%     Settings.N_Back = 1;
% elseif floor(Settings.N_Back) ~= Settings.N_Back || Settings.N_Back < 1
% %     fprintf('Using defualt N-back of degree %i\n\n', defaultSettings.N_Back);
%     Settings.N_Back = 1;
% end
Settings.N_Back = defaultSettings.N_Back;
fprintf('Doing %i-back\n\n', Settings.N_Back);

% Select how many emotions/identities to show
defaultSettings.N_Emotions_Identities = 3;
% Settings.N_Emotions_Identities = input(['Enter the number of emotions/identities to display\nMust be 1 < x < 8\nJust press enter for default (' num2str(defaultSettings.N_Emotions_Identities) ')\n']);
% if isempty(Settings.N_Emotions_Identities)
%     Settings.N_Emotions_Identities = defaultSettings.N_Emotions_Identities;
% elseif floor(Settings.N_Emotions_Identities) ~= Settings.N_Emotions_Identities || Settings.N_Emotions_Identities < 2 || Settings.N_Emotions_Identities > 7
%     Settings.N_Emotions_Identities = defaultSettings.N_Emotions_Identities;
% end
Settings.N_Emotions_Identities = defaultSettings.N_Emotions_Identities;
% Order of emotions to display. Happy, angry, sad, disgust, calm,
% fearful, surprised
emorder = {'HO', 'AO', 'SC', 'DO', 'CC', 'FC', 'SUR'};
emoFullNames = {'Happy', 'Angry' , 'Sad', 'Digusted', 'Calm', 'Afraid', 'Surprised'};
Settings.Emotions = emorder(1:Settings.N_Emotions_Identities);
Settings.Emotion_Full_Names = emoFullNames(1:Settings.N_Emotions_Identities);
disp(['Displaying ' num2str(Settings.N_Emotions_Identities) ' emotions: ' cell2mat(Settings.Emotion_Full_Names)]);
fprintf('\n');

% % Select which demographics to show. For now we are set up for only a
% % single demographic.
% defaultdemo = 'WM';
% % A: Asian, B: Black, H: Hispanic, W: White, F: Female, M: Male
% demo = input(['Enter which demographics to show.\nDefault is ' defaultdemo '.\nOptions are AF, AM, BF, BM, HF, HM, WF, WM, A, B, H, W or ALL.\nEnter with ''single quotes'' and CAPITALS\n']);
% if isempty(demo)
%     demo = defaultdemo;
% elseif ~any(strcmp(demo,{'AF', 'AM', 'BF', 'BM', 'HF', 'HM', 'WF', 'WM'}))
%     demo = defaultdemo;
%     fprintf('Bad demo entered, using default (%s)\n\n', defaultdemo);
% end
demo = 'WM';

% Get number of actors available in that demographic
indemo = dir([faceDir '\' demo '\*.jpg']);
indemo = {indemo.name};
modelsindemo = unique(cellfun(@(x) x(1:4), indemo, 'UniformOutput', false));
nindemo = length(modelsindemo);

% Select which actors to pick - the first few, or the next few
defaultActorPick = 'front';
% ActorPick = input(['Enter which actors to pick.\nOptions are ''' defaultActorPick ''' (default) or ''next''\nEnter using ''single quotes'', lowercase\n']);
% if isempty(ActorPick)
%     ActorPick = defaultActorPick;
% elseif ~strcmp(ActorPick, 'front') && ~strcmp(ActorPick, 'next')
%     ActorPick = defaultActorPick;
% end
ActorPick = defaultActorPick;
fprintf('Picking actors from %s.\n\n', ActorPick);

% Get a randomization seed
defaultRandSeed = 2;
% Settings.Random_Seed = input(['Enter the randomization seed.\nJust press Enter for default (' num2str(defaultRandSeed) ')\n']);
% if isempty(Settings.Random_Seed)
%     Settings.Random_Seed = defaultRandSeed;
% elseif Settings.Random_Seed < 1 || floor(Settings.Random_Seed) ~= Settings.Random_Seed
%     Settings.Random_Seed = defaultRandSeed;
% end
Settings.Random_Seed = defaultRandSeed;
fprintf('Using randomization seed: %i\n\n', Settings.Random_Seed);
rng(Settings.Random_Seed);

%%
%----------------------------------------------------------------------
%                   Generate the Image Sequence
%----------------------------------------------------------------------

% Case of a single demographic

% Load validity, kappa, reliability data
VKR = load([faceDir '\' demo '\Validity_Kappa_Reliability.mat']);
[~, vkrmask] = intersect(VKR.emo7,emorder(1:Settings.N_Emotions_Identities));

% Determine the Settings.N_Emotions_Identities models with the highest average validity rating for
% the selected emotions
[~, topmodelidx] = sort(mean(VKR.Vscores(:,vkrmask),2), 'descend');
if strcmp(ActorPick, 'front')
    models2use = modelsindemo(topmodelidx(1:Settings.N_Emotions_Identities));
elseif strcmp(ActorPick, 'next')
    models2use = modelsindemo(topmodelidx(Settings.N_Emotions_Identities+1:Settings.N_Emotions_Identities+Settings.N_Emotions_Identities));
%     models2use = modelsindemo(topmodelidx([4 6 8]));
end

% Get the files which feature those actors and the right emotions
fiList = indemo(cellfun(@(x) any(strcmp(x(1:4),models2use)), indemo) & cellfun(@(x) any(strcmp(extractBetween(x,'_','.'),emorder(1:Settings.N_Emotions_Identities))), indemo));

nfi = length(fiList);

imivec = repmat((1:nfi)',[floor(Settings.N_Images/nfi),1]);
if mod(Settings.N_Images,nfi) > 0
    for emi = 1:Settings.N_Emotions_Identities
        imivec = [imivec; randperm(nfi/Settings.N_Emotions_Identities,floor(mod(Settings.N_Images,nfi)/Settings.N_Emotions_Identities))'+(nfi/Settings.N_Emotions_Identities)*(emi-1)];
    end
end

leftovers = setdiff(1:nfi,imivec);
if ~isempty(leftovers)
    randleft = leftovers(randperm(length(leftovers)));
    imivec = [imivec; randleft(1:(Settings.N_Images-length(imivec)))'];
else
    imivec = [imivec; randperm(nfi,Settings.N_Images-length(imivec))'];
end

imivec = imivec(randperm(length(imivec)));

% Store emotions and identities in the order presented
Stimuli.Presented_Emotions = extractBetween(fiList(imivec),'_','.');
Stimuli.Presented_Identities = cellfun(@(x) x(1:4), fiList(imivec), 'UniformOutput', false);
Settings.Identity_List = unique(Stimuli.Presented_Identities);

Stimuli.Presented_EmotionsIdx = nan(Settings.N_Images,1);
Stimuli.Presented_IdentitiesIdx = nan(Settings.N_Images,1);
for presi = 1:Settings.N_Images
    Stimuli.Presented_EmotionsIdx(presi) = find(strcmp(Stimuli.Presented_Emotions{presi},Settings.Emotions));
    Stimuli.Presented_IdentitiesIdx(presi) = find(strcmp(Stimuli.Presented_Identities{presi},Settings.Identity_List));
end

% Create vector for user responses
Stimuli.Subject_Responses = nan(Settings.N_Images,1);

% Create timestamp vectors
Events.Times.Image_Shown = nan(Settings.N_Images,1);
Events.Times.Fixation_Shown = nan(Settings.N_Images,1);
Events.Times.Response_Made = nan(Settings.N_Images,1);

% Store correct responses
if Match_Type == 1
    Stimuli.Correct_Responses = Stimuli.Presented_EmotionsIdx(Settings.N_Back+1:end) == Stimuli.Presented_EmotionsIdx(1:end-Settings.N_Back);
    Settings.Match_Paradigm = 'EMOTION';
elseif Match_Type == 2
    Stimuli.Correct_Responses = Stimuli.Presented_IdentitiesIdx(Settings.N_Back+1:end) == Stimuli.Presented_IdentitiesIdx(1:end-Settings.N_Back);
    Settings.Match_Paradigm = 'IDENTITY';
end

%%
%----------------------------------------------------------------------
%                           PTB Setup
%----------------------------------------------------------------------

% Setup PTB with some default values
PsychDefaultSetup(2);

% Disable screen sync checks
Screen('Preference', 'VBLTimestampingMode', -1);
Screen('Preference', 'SkipSyncTests', 2);

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
gray = white/2;

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black, [], 32, 2);

% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set the text size
Screen('TextSize', window, 60);

% Query the maximum priority level
topPriorityLevel = MaxPriority(window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%%
%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Time to show face image, in seconds
Settings.Durations.Image = 2;
faceTimeFrames = round(Settings.Durations.Image/ifi);

% Time after response, in seconds
Settings.Durations.After_Response = 2;
respondTimeFrames = round(Settings.Durations.After_Response/ifi);

% Number of frames to wait before re-drawing
waitFrames = 1;

%%
%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Define the keyboard keys that are listened for.
escapeKey = KbName('ESCAPE');
matchKey = KbName('m');
nomatchKey = KbName('x');

%%
%----------------------------------------------------------------------
%                    Fixation Cross Setup
%----------------------------------------------------------------------

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 40;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

%%
%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------

% Show instruction text
DrawFormattedText(window, ['Doing ' Settings.Match_Paradigm ' matching, ' num2str(Settings.N_Back) '-back\nPress M for Match\nPress X for No Match\nIf unsure, you must guess.\nPress any key to begin.'], 'center', 'center', white, [],[],[],1.5);
HideCursor;
Screen('Flip', window);
KbStrokeWait;
if Settings.Do_Cedrus
    write(device,sprintf("mh%c%c",Events.Codes.Task_Start, 0), "char");
end
Events.Time.Task_Start = now;

% Show an initial fixation cross
Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
vbl = Screen('Flip', window);
for fri = 1:respondTimeFrames-1
    % Get video frame
    if mod(ifi*(fri-1),frametime) == 0 && Settings.Do_Video
        vidbuffer(:,:,1,vidi) = rgb2gray(snapshot(cam));
        if Settings.Do_Cedrus && frameflag
            if vidi == 1000
                write(device,sprintf("mh%c%c",Events.Codes.Thousandth_Video_Frame, 0), "char");
            else
                write(device,sprintf("mh%c%c",Events.Codes.First_Video_Frame, 0), "char");
            end
            frameflag = false;
        end
        Events.Times.Video_Frame(vidi) = now;
        vidi = vidi+1;
        if vidi == 1000
            frameflag = true;
        end
    end
    Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
    vbl = Screen('Flip', window, vbl + (waitFrames - 0.5) * ifi);
end

% Flag for keypress response
responseMade = false;
crosscolor = white;

% Get screen size so we can scale image
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
% Set image scale to 0.5 of screen height
imagescale = 0.5;

% Now go into the presentation loop:
for trii = 1:Settings.N_Images
    % Show a scaled face image
    thisImg = imread([faceDir '\' demo '\' fiList{imivec(trii)}]);
    imageTexture = Screen('MakeTexture', window, thisImg);
    [s1, s2, s3] = size(thisImg);
    aspectRatio = s2 / s1;
    imageHeight = screenYpixels * imagescale;
    imageWidth = imageHeight * aspectRatio;
    dstRect = CenterRectOnPointd([0 0 imageWidth imageHeight], screenXpixels / 2, screenYpixels / 2);
    Screen('DrawTexture', window, imageTexture, [], dstRect);
    vbl = Screen('Flip', window);
    if Settings.Do_Cedrus
        write(device,sprintf("mh%c%c",Events.Codes.Image_Shown, 0), "char");
    end
    Events.Times.Image_Shown(trii) = now;
    % TTL HERE
%     Datapixx('Open')
%     DatapixxAOttl() %FOR TTL
%     TTLTimes(trii) = now;
    for fri = 1:faceTimeFrames-1
        % Get video frame
        if mod(ifi*(fri-1),frametime) == 0 && Settings.Do_Video
            vidbuffer(:,:,1,vidi) = rgb2gray(snapshot(cam));
            if Settings.Do_Cedrus && frameflag
                if vidi == 1000
                    write(device,sprintf("mh%c%c",Events.Codes.Thousandth_Video_Frame, 0), "char");
                else
                    write(device,sprintf("mh%c%c",Events.Codes.First_Video_Frame, 0), "char");
                end
                frameflag = false;
            end
            Events.Times.Video_Frame(vidi) = now;
            vidi = vidi+1;
            if vidi == 1000
                frameflag = true;
            end
        end
        Screen('DrawTexture', window, imageTexture, [], dstRect);
        vbl = Screen('Flip', window, vbl + (waitFrames -0.5) * ifi);
        
        % Allow response while the image is on
        if trii > Settings.N_Back
            if ~responseMade
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(escapeKey)
                    ShowCursor;
                    sca;
                    return
                elseif keyCode(matchKey)
                    if Settings.Do_Cedrus
                        write(device,sprintf("mh%c%c",Events.Codes.Response_Made, 0), "char");
                    end
                    Events.Times.Response_Made(trii) = now;
                    Stimuli.Subject_Responses(trii) = 1;
                    responseMade = true;
                    crosscolor = [0 0 1];
                elseif keyCode(nomatchKey)
                    if Settings.Do_Cedrus
                        write(device,sprintf("mh%c%c",Events.Codes.Response_Made, 0), "char");
                    end
                    Events.Times.Response_Made(trii) = now;
                    Stimuli.Subject_Responses(trii) = 0;
                    responseMade = true;
                    crosscolor = [0 0 1];
                end
            end
        else
            crosscolor = [0 0 1];
        end
    end
    
    % Show a fixation cross, and look for user input
    Screen('DrawLines', window, allCoords, lineWidthPix, crosscolor, [xCenter yCenter], 2);
    vbl = Screen('Flip', window);
    if Settings.Do_Cedrus
        write(device,sprintf("mh%c%c",Events.Codes.Fixation_Shown, 0), "char");
    end
    Events.Times.Fixation_Shown(trii) = now;   
    
    for fxi = 1:respondTimeFrames
        % Get video frame
        if mod(ifi*(fri-1),frametime) == 0 && Settings.Do_Video
            vidbuffer(:,:,1,vidi) = rgb2gray(snapshot(cam));
            if Settings.Do_Cedrus && frameflag
                if vidi == 1000
                    write(device,sprintf("mh%c%c",Events.Codes.Thousandth_Video_Frame, 0), "char");
                else
                    write(device,sprintf("mh%c%c",Events.Codes.First_Video_Frame, 0), "char");
                end
                frameflag = false;
            end
            Events.Times.Video_Frame(vidi) = now;
            vidi = vidi+1;
            if vidi == 1000
                frameflag = true;
            end
        end
        Screen('DrawLines', window, allCoords, lineWidthPix, crosscolor, [xCenter yCenter], 2);
        vbl = Screen('Flip', window);
        
        if trii > Settings.N_Back
            if ~responseMade
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyCode(escapeKey)
                    ShowCursor;
                    sca;
                    return
                elseif keyCode(matchKey)
                    if Settings.Do_Cedrus
                        write(device,sprintf("mh%c%c",Events.Codes.Response_Made, 0), "char");
                    end
                    Events.Times.Response_Made(trii) = now;
                    Stimuli.Subject_Responses(trii) = 1;
                    responseMade = true;
                    crosscolor = [0 0 1];
                elseif keyCode(nomatchKey)
                    if Settings.Do_Cedrus
                        write(device,sprintf("mh%c%c",Events.Codes.Response_Made, 0), "char");
                    end
                    Events.Times.Response_Made(trii) = now;
                    Stimuli.Subject_Responses(trii) = 0;
                    responseMade = true;
                    crosscolor = [0 0 1];
                end
            end
        else
            % Cross turns blue once response is made
            crosscolor = [0 0 1];
        end
    end
    
    responseMade = false;
    crosscolor = white;
end

% Calculate score
score = sum(Stimuli.Subject_Responses(Settings.N_Back+1:end)==Stimuli.Correct_Responses);
if ispractice
    DrawFormattedText(window, ['Done!\nScore: ' num2str(score) ' out of ' num2str(Settings.N_Images-Settings.N_Back)], 'center', 'center', white);
else
    DrawFormattedText(window, 'Done!', 'center', 'center', white);
end
Screen('Flip', window);
KbStrokeWait;
sca;

% Save it
if ~ispractice
    
    currentTime = datestr(now,'yyyy_mm_dd.HH_MM_SS');
    
    if Settings.Do_Audio
        % Save audio
        wavfi = [saveDir '\NBack_' Settings.Match_Paradigm '_' currentTime '.wav'];
        % [audiodata absrecposition overflow Events.Times.Audio_Start2]  = PsychPortAudio('GetAudioData', pahandle);
        stop(reco);
        if Settings.Do_Cedrus
            write(device,sprintf("mh%c%c",Events.Codes.Audio_Stop, 0), "char");
        end
        Events.Times.Audio_Stop = now;
        % psychwavwrite(transpose(audiodata), Settings.AudioFreq, 16, wavfi);
        Settings.AudioFreq = reco.SampleRate;
        audiodata = getaudiodata(reco);
        audiowrite(wavfi, audiodata, Settings.AudioFreq);
    end
    
    if Settings.Do_Video
        % Trim and save video
        vidbuffer = vidbuffer(:,:,1,1:vidi-1);
        Events.Times.Video_Frame = Events.Times.Video_Frame(1:vidi-1);
        vidfi = [saveDir '\NBack_' Settings.Match_Paradigm '_' currentTime '.mp4'];
        v = VideoWriter(vidfi);
        open(v);
        writeVideo(v,vidbuffer)
        close(v);
        clear cam
    end
    
    
    save([saveDir '\NBack_' Settings.Match_Paradigm '_' currentTime '.mat'], ...
        'Stimuli', 'Events', 'Settings');
end