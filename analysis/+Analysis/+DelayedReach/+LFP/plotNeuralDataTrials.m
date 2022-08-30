function plotNeuralDataTrials(NeuralData, TargetVector, RelativeTimes, TaskString, varargin)
%   Adjust vertical lines for phase timing
%    To-Do: varargin to fix y limit to specific amount
    [varargin, VertLineCoords, ~, VLCFound] = util.argkeyval('VertLineCoords', varargin, 0);
    %[varargin, VertLineLabels, ~, VLLabelFound] = util.argkeyval('VertLineLabels', varargin, {''});
    util.argempty(varargin);
    
    for ch = 1:size(NeuralData, 2)
    FString = sprintf('%s-Channel-%d All-Targets All-Trials', TaskString, ch);
    figure('Name', FString, 'NumberTitle', 'off', 'Units', 'normalized',...
        'OuterPosition', [0 0.025 0.5 0.97]); %just about half a screen
        for t = 1:8
            TargetLogical = TargetVector == t;
            TargetND = squeeze(NeuralData(:,ch,TargetLogical));
            NumTrials = size(TargetND, 2);
            TargetMean = mean(TargetND,2);
            subplot_tight(8,1,t, [0.035 0.045]);
            hold on
            for tr = 1:NumTrials
                plot(RelativeTimes,TargetND(:,tr), 'Color', [0.7 0.87 0.54],...
                'LineWidth', 0.2)
            end
            set(gca, 'YLim', [-500 500], 'xticklabels', '')
            ylabel('\muV', 'Interpreter','tex')
            TString = sprintf('Target Location %d, %d Trials', t, NumTrials);
            title(TString)
            if VLCFound
                YCoords = [-500 500]; % plotting at YLim readjusts YLim
                Vx = [VertLineCoords; VertLineCoords];
                Vy = YCoords' .* ones(2, length(VertLineCoords));
                plot(Vx, Vy, 'k--')
                set(gca, 'YLim', [-500 500], 'xticklabels', '')
            end

            plot(RelativeTimes, TargetMean, 'Color', [0.2 0.63 0.17],...
            'LineWidth', 0.5)

            if t == 8
                xlabel('Time (s)')
                set(gca, 'xticklabelmode', 'auto')
            end
            
            hold off

        end % End target loop
    end % End channel plotting loop
end % End Function