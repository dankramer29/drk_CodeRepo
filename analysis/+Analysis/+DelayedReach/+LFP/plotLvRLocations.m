function plotLvRLocations(LocName, Channels, LeftAverages, RightAverages,...
    Comparisons, SubTimeBins, SubFreqBins, varargin)
%plotLvRLocations
%   plotting helper function to plot left(L) and right(R) trial averaged
%   spectrograms per channel, with an plot in the middle displaying the
%   comparison array
% 
%    plotLvRLocations(LocName)
%     LocName is a string used for the title of the figure
%     
%    plotLvRLocations(..., Channels)
%     Channels is a row vector of the channels desired to plot. Assumes input
%     arrays' 3rd dimension is for channels
%     
%    plotLvRLocations(..., LeftAverages, RightAverages, Comparisons)
%     Arrays with dimensions Time x Freq x Channels. Can be z-scored arrays or
%     spectrograms. Left arrays will be plotted far left, comparison arrays in
%     the middle, and right arrays in the 3rd, right column.
%     
%    plotLvRLocations(..., SubTimebins, SubFreqBins)
%     Vectors of time and frequency stamps, matching 1st and 2nd dimensions of
%     3 input arrays described above. These are usually returned when generating
%     the spectrograms in chronux. 
%     
%    plotLvRLocations(..., 'Normalize', true/false) default = true
%     Optional boolean input to specify whether to fix the colormap range based 
%     on max and min values of the channel
%     
%    plotLvRLocations(..., 'PlotColorBar', true/false) default = false
%     Optional boolean input to plot colorbars next to each subplot for reference
%     
%    plotLvRLocations(..., 'AllZs', true/false) default = false
%     Optional boolean input. True if left and right input arrays are z-scored.
%     Changes colormap range to be the same for all 3 subplot for a channel.
%     
%    plotLvRLocations(..., 'VertLineCoords', X-AxisCoordinates)
%     Optional row vector of x-coordinates to plot vertical lines. Useful for
%     indicating trial phase transitions. Will be plotted as red dashed lines. 
%     Must be values within the timebin domain. 

    
    [varargin, Normalize, ~, ~] = util.argkeyval('Normalize', varargin, 'Row');
    [varargin, PltClrBar, ~, ~] = util.argkeyval('PlotColorBar', varargin, 0);
    [varargin, AllZs, ~, ~] = util.argkeyval('AllZs', varargin, 0);
    [varargin, VertLineCoords, ~, VertFound] = util.argkeyval('VertLineCoords', varargin, 0);
    
    util.argempty(varargin);
    
    spR = length(Channels);
    spC = 3;
    
    % If we try to log10 negative values (z-scores) we get invalid data for
    % imagesc
    if AllZs
        LeftData = LeftAverages;
        RightData = RightAverages;
        TitleMod = "Z-Score";
    elseif ~AllZs
        LeftData = 10*log10(LeftAverages);
        RightData = 10*log10(RightAverages);
        TitleMod = "SpecAvg";
    end
    
    switch Normalize
        case 'Row'
            TitleMod = TitleMod + "-Normd";
            LeftData = 10*log10(LeftAverages);
            LeftData = LeftData - repmat(min(LeftData,[],1),[size(LeftData,1),1,1]);
            %takes min across time dimension (x) and expands it to dimensions in second
            %[] argument. 
            LeftData = LeftData./repmat(max(LeftData,[],1),[size(LeftData,1),1,1]);
            
            RightData = 10*log10(RightAverages);
            RightData = RightData - repmat(min(RightData,[],1),[size(RightData,1),1,1]);
            RightData = RightData./repmat(max(RightData,[],1),[size(RightData,1),1,1]);

            Comparisons = Comparisons - repmat(min(Comparisons, [], 1), [size(Comparisons,1),1,1]);
            Comparisons = Comparisons./repmat(max(Comparisons,[], 1), [size(Comparisons,1),1,1]);
            NormClrBar = 0;
        case 'Channel'
            NormClrBar = 1;
            TitleMod = TitleMod + "-ClrRangeLim";
            % Find min and max for entire array being plotted for colormap
%             MinSpecVal = min( min(min(min(LeftData(:,:,Channels)))),...
%                 min(min(min(RightData(:,:,Channels)))));
%             MaxSpecVal = max( max(max(max(LeftData(:,:,Channels)))),...
%                 max(max(max(RightData(:,:,Channels)))));

            % Find min value for each channel for colormap
            LChanSpecMin = squeeze(min(min(LeftData)));
            RChanSpecMin = squeeze(min(min(RightData)));
            ChanSpecMin = min([LChanSpecMin RChanSpecMin], [], 2);

            % Find max value for each channel for colormap
            LChanSpecMax = squeeze(max(max(LeftData)));
            RChanSpecMax = squeeze(max(max(RightData)));
            ChanSpecMax = max([LChanSpecMax RChanSpecMax], [], 2);

%             MinZScore = min(min(min(Comparisons(:,:,Channels))));
            ChanMinZScore = squeeze(min(min(Comparisons)));

%             MaxZScore = max(max(max(Comparisons(:,:,Channels))));
            ChanMaxZScore = squeeze(max(max(Comparisons)));
    end

    if VertFound
        Vx = [VertLineCoords; VertLineCoords];
        Vy = [min(SubFreqBins) max(SubFreqBins)]'...
            .* ones(2, length(VertLineCoords));
    end
    
% ---- Plot ------
    FString = sprintf('LvR-%s', LocName);
    figure('Name', FString, 'NumberTitle', 'off', 'units', 'normalized',...
        'outerposition', [0.2 0 0.8 1], 'PaperPositionMode', 'auto');
    for c = 1:spR
        rowIdx = (c-1)*spC;
        chNum = Channels(c);
        
        % Left SubPlot
        subplot_tight(spR, spC, rowIdx+1, [0.035 0.045])
        imagesc(SubTimeBins, SubFreqBins, LeftData(:,:,chNum)'); axis xy;
        if VertFound
            hold on
            plot(Vx, Vy, 'r--')
            hold off
        end
        if NormClrBar
%             caxis([MinSpecVal MaxSpecVal])
            caxis([ChanSpecMin(chNum) ChanSpecMax(chNum)])
        end
        if PltClrBar
            colorbar
        end
        ts = sprintf('Channel %d L Target Trials %s', chNum, TitleMod);
        title(ts)
        
        % Middle SubPlot
        subplot_tight(spR, spC, rowIdx+2, [0.035 0.045])
        imagesc(SubTimeBins, SubFreqBins, Comparisons(:,:,chNum)'); axis xy;
        ts = sprintf('Channel %d (L z) - (R z)', chNum);
        if VertFound
            hold on
            plot(Vx, Vy, 'r--')
            hold off
        end
        if NormClrBar
%             caxis([MinZScore MaxZScore])
            caxis([ChanMinZScore(chNum) ChanMaxZScore(chNum)])
        end
        if PltClrBar
            colorbar
        end
        title(ts)
        
        % Right Subplot
        subplot_tight(spR, spC, rowIdx+3, [0.035 0.045])
        imagesc(SubTimeBins, SubFreqBins, RightData(:,:,chNum)'); axis xy;
        if VertFound
            hold on
            plot(Vx, Vy, 'r--')
            hold off
        end
        if NormClrBar
%             caxis([MinSpecVal MaxSpecVal])
            caxis([ChanSpecMin(chNum) ChanSpecMax(chNum)])
        end
        if PltClrBar
            colorbar
        end
        ts = sprintf('Channel %d R Target Trials %s', chNum, TitleMod);
        title(ts)
    end
        
end

