function plotSpecgram(SpectrogramArray, FreqBins, TimeBins,  TargetList,  PlotChannel, PlotTarget)

    % determine subplot dimensions
    NumPlots = length(find(TargetList == PlotTarget));
    PRows = ceil(NumPlots / 2);
    PCols = 2;


    FigName = sprintf('Spectrograms Channel %d Target %d', PlotChannel, PlotTarget);
    figure('Name', FigName, 'NumberTitle', 'off', 'position', [1 50 958 930]);
    Position = 0;
    for Trial = 1:length(TargetList)
        Target = TargetList(Trial);
        if Target == PlotTarget
            Position = Position + 1; 
            subplot_tight(PRows, PCols, Position, [0.045 0.04])
            imagesc(TimeBins, FreqBins, 10*log10(SpectrogramArray(:,:,PlotChannel,Trial))', [-10 20]);
            axis xy;
            TStr = sprintf('Trial %d Target %d', Trial, Target);
            title(TStr);
            colorbar
        end

    end
end