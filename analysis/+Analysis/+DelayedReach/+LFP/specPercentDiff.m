function [PercDifferences, TimeStamps, LFreq_mean, RFreq_mean] = specPercentDiff(RightSpectrograms, LeftSpectrograms, TimeBins, FreqBins, varargin)
% [PercDifferences, TimeStamps] = specPercentDiff(RightSpectrograms, LeftSpectrograms, TimeBins, FreqBins, varargin)
    % varargin: 'Window', [TimeWinToAvg StepSize]. Default: [2 1]. If stepsize 
    % is < timewintoavg, there will be overalap. If stepsize == timewintoavg, no
    % overlap. I don't think stepsize > timewintoavg makes sense.
    
    %To-Do: make varargin for freq bins. 2 column input, each row is min
    %and max of freq range. How to input desired names?
    ThetaLogical  = FreqBins > 4  & FreqBins < 8;
    AlphaLogical  = FreqBins > 8  & FreqBins < 12;
    BetaLogical   = FreqBins > 12 & FreqBins < 30;
    LGammaLogical = FreqBins > 30 & FreqBins < 80;
    HGammaLogical = FreqBins > 80 & FreqBins < 200;
    FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
%     Frequencies = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
%         'High Gamma 80-200'};
    
    % -- Process varargin --
%     [varargin, Window, ~, ~] = util.argkeyval('Window', varargin, [2 1]);
%     if length(Window) == 1
%         Window(2) = 1;
%     end
    Window = [2 1];
%     util.argempty(varargin);
    
    numChan       = size(RightSpectrograms, 3);
    numFBins      = size(FreqLog, 1);
    timebinwindow = Window(1);
    stepsize      = Window(2);
    NumTS = floor( (length(TimeBins) - timebinwindow) / stepsize) + 1;
    TSIdx = 1:stepsize:NumTS;
    TimeStamps = TimeBins(TSIdx);

    % -- Preallocation --
    PercDifferences = zeros(numFBins,NumTS,numChan);
    LFreq_mean = zeros(length(TimeBins),numFBins,  numChan);
    RFreq_mean = zeros(length(TimeBins),numFBins,  numChan);


        for fr = 1:numFBins
            FrIdx = FreqLog(fr,:);

            startIdx = 1;
            endIdx = timebinwindow;
            lfrsubarray = mean(LeftSpectrograms(:, FrIdx, :), 2);
            LFreq_mean(:, fr,:) = lfrsubarray;
            rfrsubarray = mean(RightSpectrograms(:, FrIdx, :), 2);
            RFreq_mean(:, fr,:) = rfrsubarray;
            for tw = 1:NumTS

                LWinAvg = mean(lfrsubarray(startIdx:endIdx, :, :), 1);

                RWinAvg = mean(rfrsubarray(startIdx:endIdx, :, :), 1);

                PDiff = (RWinAvg-LWinAvg)./ (RWinAvg + LWinAvg);
                PercDifferences(fr,tw,:) = PDiff;
                startIdx = startIdx + stepsize;
                endIdx = endIdx + stepsize;
            end %endwhileTime

        end %endforFBins
%     end %endforChannels
    
end