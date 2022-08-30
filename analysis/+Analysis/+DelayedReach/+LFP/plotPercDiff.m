function plotPercDiff(FigTitle, Channels, PercentDifferences, TimeStamps, varargin)
%plotPercDiff plot percent difference values over time. 
%   plotPercDiff(FigTitle, Channels, PercentDifferences, TimeStamps,
%   varargin) plots the stuff you give it.
%   
%   FigTitle: string to title figure; Adds this string to the figure
%   title. The title of the figure will be this string.
%   
%   Channels: Channels to be plotted, one subplot for each channel; An
%   index into the 3rd dimension of PercentDifferences matrix.
%   
%   PercentDifferences: FreqBands x TimeBins x Channels matrix of power
%   differences to be used; Y x X x Z matrix. Each Z indexed by Channels
%   input on separate subplot, plotting each row Y as a different line over
%   range of X
%   
%   TimeStamps: time for each value in PercentDifferences; become x-axis tick
%   labels.
%   
%   
%   *Optional Inputs*:
%   
%   'VertLineCoords': Row vector of x-values to plot vertical lines (dashed);
%   Should be in the range of TimeStamps. Used for showing important time
%   events. Will show on every subplot. Default is none.
%   
%   'VertLineLabels': string or char array of labels to to add to the
%   VerLineCoords; Must match the number of x-values in VertLineCoords.
%   Will show on first subplot only. If input incorrectly, line labels will
%   be numbered. Default is none.
%   
%   'TitleMod': string to append to 'Channel #' subplot title; Default is
%   none.
%   
%   'FixYRange': Boolean to make all subplots have the same Y-limits;
%   true/false or 0/1. Default is false.
%   
%   
%   *To-Do*:
%   Add option to input labels for legend for rows of PercDiff.
%   Change PercentDiff input to be Time x Freq like chronux output? (Mod to
%   specPercentDiff too). 
%   This is really a plotting function that could be used for raw voltages
%   too, keeping the varargins to make it work for many cog-sci exps?
    

    
    NumChannels = length(Channels);
    spC = 1;
    spR = NumChannels;
    
    [varargin, VertLineCoords, ~, ~] = util.argkeyval('VertLineCoords', varargin, 0);
    [varargin, VertLineLabels, ~, VLLabelFound] = util.argkeyval('VertLineLabels', varargin, {''});
    [varargin, TitleMod, ~, TMFound] = util.argkeyval('TitleMod', varargin, '');
    [varargin, FixYRange, ~, ~]      = util.argkeyval('FixYRange', varargin, false);
    util.argempty(varargin);
    
    if VLLabelFound %make sure the user(your distracted self) inputs useable labels
        if ~(length(VertLineLabels) == length(VertLineCoords))
            defaultL = char(string(0:length(VertLineCoords)));
            vlrange = sprintf('0:%d', length(VertLineCoords));
            VertLineLabels = defaultL;
            fprintf('Number of labels provided does not = number of vertical lines.\n')
            fprintf('Labels set to default: %s\n', vlrange)
        end
        if ~(iscell(VertLineLabels) && iscell(VertLineLabels(1)))
            defaultL = char(string(0:length(VertLineCoords)));
            vlrange = sprintf('0:%d', length(VertLineCoords));            
            VertLineLabels = defaultL;
            fprintf('Labels must be cell array Ex: {''1'',''2'',...}\n')
            fprintf('Labels set to default: %s\n', vlrange)
        end
    end
        
    
    if FixYRange
        subData  = PercentDifferences(:,:,Channels);
        sortData = sort(subData(:)); % unroll and sort low to high
        YLow     = sortData(1);
        YUpp     = sortData(end);
    end
        
    
    figure('Name', FigTitle, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [0.2 0 0.6 1], 'PaperPositionMode', 'auto');

    for row = 1:NumChannels
        chNum = Channels(row);
        subplot_tight(spR, spC, row, [0.035 0.045])
        plot(TimeStamps, PercentDifferences(:, :, chNum))
        TitleStr = (sprintf('Channel %d', chNum));
        if TMFound
            TitleStr = sprintf('%s - %s',TitleStr, TitleMod);
        end
        title(TitleStr)
        ax = gca;
        ax.XAxisLocation = 'origin';
        YCoords = ax.YLim; % plotting at YLim readjusts YLim
        if FixYRange
            YCoords = [YLow YUpp];
        end
        Vx = [VertLineCoords; VertLineCoords];
        Vy = YCoords' .* ones(2, length(VertLineCoords));
        hold on
        plot(Vx, Vy, 'k--')
        hold off
        ax.YLim = YCoords; % set YLim back to original place
        ax.XLim = [TimeStamps(1) TimeStamps(end)];
        ax.YMinorTick = 'on';
        if row == 1
            legend('Theta', 'Alpha', 'Beta', 'Low Gamma', 'High Gamma',...
                'Location', 'best')
            if VLLabelFound
                for p = 1:length(VertLineCoords)
                    text(VertLineCoords(p)+0.05, YCoords(1)*0.7, VertLineLabels(p))
                end
            end
        end %endifLegend

    end %endforPlot
    clear ax
end %endfunction