function [clickLabels, binsToChop, onTarget] = findMultiClickTimes(D, options)
% label click periods using D and options. This seems fully uneccessary to SNF
% SNF making this multiclick specific, but should work when only 1 click is
% desired. No RTI.
% Called in multiple places during click decoder build (e.g. buildHMMOpenLoop,
% buildHMMDialog). Allows excludeAmbiguousData, etc. to apply during all parts
% of build (including finding best channels, etc.).

% SNF sees issues. Like, D.clickState previously ranged from 0 to binSize
% (usually 15), but the clickStateThreshold is 0.5. Is this supposed to
% catch anything that isn't 0 or were the clickStates supposed to be
% divided by the binSize in earlier steps (onlineDfromR)?


% pick the the field in the D-struct that matches the click source

%hoverTargetState is always filled in. 
% you're on the target *and* a click or dwell is indicated 
onTarget  =     [D.overTargetState]>options.clickStateThreshold | ... 
                [D.dwellState]>options.clickStateThreshold;      
% you're on the target and a *click*  is indicated, because clickState is always 0 for dwell targets            
aboveThresh =   [D.clickState]>options.clickStateThreshold; %SNF: clickState is # click ms * clickTarget.  For dwell targets, this means all 0s

% onTarget and aboveThresh are logicals
isAmbiguous = false(size([D.clickState]));
beyondMaxLength = false(size([D.clickState]));

switch options.clickSource
    case DiscreteStates.STATE_SOURCE_CLICK
       % clickLabels = aboveThresh; %[D.clickState]>options.clickStateThreshold;
       clickLabels = [D.clickTarget]; %SNF: this works for OL... and CL if we assume he's trying to click
        %this way, the clickLabels are now 0-N for dwell + N clicks 
    case DiscreteStates.STATE_SOURCE_DWELL
        %clickLabels = onTarget; % [D.dwellState]>options.clickStateThreshold;
        tmp = [D.clickTarget];
        clickLabels = tmp(onTarget); %find click target ID for all times when the cursor is on the target
        clear tmp;
        %SNF: clickSource is dwell for open loop training. clickLabels need
        %to be target-based.
    case DiscreteStates.STATE_SOURCE_CLICKOVERTARGET %SNF: this state is not multiclick-friendly.
        clickLabels_temp = (onTarget + aboveThresh)/2;
        % ambiguous bins are at .5; unambiguous non-click bins are 0;
        % and unambiguous click bins are 1
        isAmbiguous = clickLabels_temp == 0.5;
        % now that ambiguous bins have been identified, make clickLabels
        % the usual logical (1s for click, 0s for both non-click and
        % ambiguous bins - the latter is default behavior, but if
        % excludeAmbiguousData is on, ambiguous bins will be chopped downstream):
        clickLabels = logical(floor(clickLabels_temp));
end
% irrespective of clickSource, identify any click data points beyond max click length:
if options.maxClickLength
    % maximum number of continguous bins a click can occur for
    maxClickBins = ceil(options.maxClickLength / options.binSize);
    
    % clickStateChanges = diff([0;clickLabels(:);0]); %original
    clickStateChanges = diff([0;logical(clickLabels(:));0]); %SNF modifying for multiclick
    %this is fine to be logical because we're just interested in click/non
    %click transitions, not click-type-specific wonkyness
    clickStarts = find(clickStateChanges==1);   %in 15 ms bins (not ms)
    clickEnds = find(clickStateChanges==-1) - 1;  %note from BJ: clickEnds was previously the bin at the beginning of next non-click period; -1 makes it the actual last bin of each click period
    
    longClicks = find(clickEnds-clickStarts>maxClickBins); %converting to indices so we can loop through only long clicks below.
    
    if ~isempty(longClicks)
        clickEnds_prev = clickEnds;  %previous click ends (some of which are long)
        clickEnds(longClicks) = clickStarts(longClicks)+maxClickBins; %new click ends (long clicks will now end maxClickBins after start of each click)
        
        for lc = longClicks',
            indsBeyondMaxLength_c{lc} = clickEnds(lc,1):clickEnds_prev(lc,1);
        end
        indsBeyondMaxLength = cell2mat(indsBeyondMaxLength_c);
        beyondMaxLength = false(size(clickLabels));
        beyondMaxLength(indsBeyondMaxLength) = true;  %now logical array
        %SNF verifies that it's okay to have doubles and falses in the same
        %clickLabels vector.
        clickLabels(beyondMaxLength) = false; %by default, turn bins after
        % maxLength to non-click. If options.excludeAmbiguousData is true,
        % these bins will get chopped downstream.
    end
end
binsToChop = isAmbiguous | beyondMaxLength;