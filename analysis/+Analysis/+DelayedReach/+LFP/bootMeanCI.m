function [MeanOutput, CIOutput] = bootMeanCI(array, resamples)

% Variables from inputs for repeat use
NumColumns = size(array, 2);
NumRows    = size(array, 1);
NumResamples = resamples;
LowThresh    = floor(0.05 * resamples); % 5% cutoff
HighThresh   = floor(0.95 * resamples); % 95% cutoff

%Pre-allocation
ResampledMeans = zeros(NumResamples, NumColumns);
CIOutput       = zeros(2, NumColumns);

% resampling loop. Way to arrayfun or vectorize?
for sample = 1: NumResamples
    NewArray = zeros(NumRows, NumColumns);
    rIndex = randi(NumRows,[NumRows, NumColumns]);
    for col = 1: NumColumns
        column = array(:, col);
        NewArray(:, col) = column(rIndex(:, col));
    end
    ResampledMeans(sample, :) = mean(NewArray);
end
    

% for c = 1:10
% subplot(2,5,c)
% histogram(ResampledMeans(:,c))
% hold on
% m = mean(ResampledMeans(:,c));
% plot([m m], [0 800])
% title(string(m))
% hold off
% end



SortedMeans = sort(ResampledMeans);
CILows = SortedMeans(LowThresh, :); % SortedMeans(500, :) 500/10000 = 5%
CIHighs = SortedMeans(HighThresh, :); % SortedMeans(9500, :) 9500/10000 = 95%

MeanOutput = mean(ResampledMeans);
CIOutput(1, :) = CILows;
CIOutput(2, :) = CIHighs;

end