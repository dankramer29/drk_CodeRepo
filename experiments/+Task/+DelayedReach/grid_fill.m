sca;
close all;
clearvars;

PsychDefaultSetup(2);

trials = 5;
z = 3;
grid_end  = z^2;
%incr = 1/(z+1);
%incr_array = incr:incr:1-incr;
incr_array = [0.2 0.5 0.8];

pos_grid = ones(z,z,2);
pos_grid(:,:,1) = pos_grid(:,:,1) .* incr_array;
pos_grid(:,:,2) = pos_grid(:,:,2) .* incr_array;

if rem(z,2) ~= 0
    middle = round(grid_end/2);
else
    middle = 0;
end

% set up screens and get screen coordinates
screens = Screen('Screens');
screenNumber = max(screens);

white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);

ifi = Screen('GetFlipInterval', window);


%center fixation cross parameters
cross_dim = 50;
cross_lwidth = 4;
xCoords = [-cross_dim cross_dim 0 0];
yCoords = [0 0 -cross_dim cross_dim];
allCoords = [xCoords; yCoords];

%rectangle parameters
baseRect = [0 0 200 200];
frameWidth = 4;

% draw fixation cross outside rectangle display loop
Screen('DrawLines', window, allCoords, cross_lwidth, white,...
    [xCenter, yCenter], 0);
Screen('Flip', window);

KbStrokeWait;
%sca;



while trials > 0
    position = randi(grid_end, 1);
    if position ~= middle
        x = screenXpixels * pos_grid(position);
        y = screenYpixels * pos_grid(2*position);
        trials = trials - 1;
        centeredRect = CenterRectOnPointd(baseRect, x, y);
        Screen('FrameRect', window, black, centeredRect, frameWidth);
        Screen('DrawLines', window, allCoords, cross_lwidth, white,...
    [xCenter, yCenter], 0);
        Screen('Flip', window);
        KbStrokeWait;
        Screen('DrawLines', window, allCoords, cross_lwidth, white,...
    [xCenter, yCenter], 0);
        Screen('Flip', window);
        KbStrokeWait;
    else
        continue
    end
    
    
end

sca;

% make PTB draw rectangle at x y coords
% set rect base shape and color
% generate the rect and flip it wait for keypress for next shape