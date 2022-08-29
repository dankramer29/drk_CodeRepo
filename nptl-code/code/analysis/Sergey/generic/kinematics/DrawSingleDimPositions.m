% DrawSinglePosVelocities.m
%
% Draws cursor positions for each dimension. Plot is thicker when over the
% target. Similar to DrawSingleDimVelocities.m, but for cursor position.
%
% USAGE: [ figh, axh ] = DrawSingleDimPositions( R, varargin )
%
% EXAMPLE:
%
% INPUTS:
%     R                         R struct of trials one wants plotted.
%                               Probably shoudl be contiguous for this type
%                               of plot, but that's not strictly necessary.
%                               By default will throw away 
%   OPTIONAL ARGUMENT-VALUE PAIRS: 
%                               
%
% OUTPUTS:
%     figh                      figure handle
%     axh                       vector of axis handles (top to bottom)
%
% Created by Sergey Stavisky on 20 October 2017 using MATLAB version 9.0.0.341360 (R2016a)

 function [ figh, axh ] = DrawSingleDimPositions( R, varargin )
    def.axh = [];
    def.smoothKernel = 'none'; % Generally not needed for cursor position
    def.smoothSigma = 5;  % gaussian kernel has this STD, in samples (ms)
    def.clipTrialsEachEnd = 1; % by default, throw out 1 trial on each end of the R structs. 
                               % Allows for velocity smoothing
    def.YLIM = [];             % Can hard-code y axis limits               
    def.numDims = [];      % by default it infers from the task.
    def.overTargetStates = double( [CursorStates.STATE_HOVER, CursorStates.STATE_ACQUIRE] );
    
    assignargs( def, varargin );

    
    %% Generate smoothing kernel
    switch smoothKernel
        case 'gaussian'
            kern = normpdf(-4*smoothSigma:smoothSigma*4,0, smoothSigma );
            kern = kern ./ sum( kern );
            
        case 'none'
            % do nothing
        otherwise
            error('Smoothing method %s not defined yet', smoothKernel')
    end
    
    %% Smooth Position
    X = double( [R.cursorPosition] ); 
    if isempty( numDims )
        numDims = size( X, 1 );
    end
    P = X .* 100; % units are m. Conver to cm.
   
    % smooth it
    if strcmp( smoothKernel, 'none')
        Psmooth = P';
    else
        Psmooth = nan( size( P ) )';
        for iDim = 1 : numDims
            Psmooth(:,iDim) = conv( P(iDim,:), kern, 'same' );
        end
    end
    
    %% clip the trials (after smoothing
    msEachTrial = arrayfun( @(x) numel( x.state ), R );
    % clip start
    Psmooth(1:sum( msEachTrial(1:clipTrialsEachEnd) )-1,:) = []; % accounts for diff earlier
    msEachTrial(1:clipTrialsEachEnd) = [];
    Psmooth(end- sum(msEachTrial(end-clipTrialsEachEnd+1:end))+1:end,:) = [];
    msEachTrial(end-clipTrialsEachEnd+1:end) = [];
    trialEndsMS = cumsum( msEachTrial );
    trialEndsMS(end) = []; % don't need separator after last trial;
    
    % and even clip the trials from R struct so they're not hanging around
    R(1:clipTrialsEachEnd) = [];
    R(end-clipTrialsEachEnd+1:end)=[];
    
    
    % For limits, what's the largest value across all the dimensions?
    maxSingleDimSpeed = max(  max( abs( Psmooth ) ) );
    if isempty( YLIM )
        YLIM = [-ceil(maxSingleDimSpeed) ceil(maxSingleDimSpeed)];
    end
    t = 0 : sum(msEachTrial);
    
    % Get events of interest from these trials
    offset = 0;
    allClickTimes = [];
    for iTrial = 1 : numel( R )
        % Are there clicks, and if so, when did they happen?        
        allClickTimes = [allClickTimes, [R(iTrial).clickTimes]+offset ];
        offset = offset + numel( R(iTrial).state ); % where I am in across-trials matrix;
    end
    
    % When was the cursor within a target?
    allState = [R.state];
    inTargetMS = ismember( allState, overTargetStates );

        
    
    %%
    figh = figure;
    for iDim = 1 : numDims
        % Basically tight packed subplot from top
        axhMe = axes('OuterPosition', [0, 1-iDim*(1/numDims), 1, 1/numDims] );
        axh(iDim) = axhMe;
        ylim( YLIM );
        axhMe.TickDir = 'out';
        axhMe.YTick = YLIM;
        xlim([0 sum(msEachTrial)+1]);
        hold on
        
        
        % Write target coordinate       
        for iTrial = 1 : numel( R )
            % where do I write this?
            labelt = sum( msEachTrial(1:iTrial-1) ) + msEachTrial(iTrial)/2;
            str = mat2str( 100.*R(iTrial).posTarget(iDim), 3 ); % converted to cm
            th = text( labelt, YLIM(2), str, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top' );
        end
      
        
        % Plot trial boundaries
        for i = 1 : numel( trialEndsMS );
            triallineh(i) = line([trialEndsMS(i) trialEndsMS(i)], YLIM, 'LineWidth', 1, 'Color', 'k');
        end
        % plot zero velocity
        line( [1 sum(msEachTrial)], [0 0], 'LineWidth', 0.5, 'Color', [.5 .5 .5]);
        
        % plot velocity
        % not over target - thinner
        plotv = Psmooth(:,iDim);
        plotv(~inTargetMS) = nan;
        vhInTarget(iDim) = plot( t, plotv, 'LineWidth', 3, 'Color', 'b');
        plotv = Psmooth(:,iDim);
        plotv(inTargetMS) = nan;
        vh(iDim) = plot( t, plotv, 'LineWidth', 1, 'Color', 'b');

        % Plot clicks
        if ~isempty( allClickTimes )
            clickV = Psmooth(allClickTimes,iDim);
            scath = scatter( allClickTimes, clickV, 5^2, [1 0 1], 'Marker', 'o', 'LineWidth', 1.5);
           
        end
        
    end
    

    if isempty( axh );
        axh = axes; hold on;
    end


end