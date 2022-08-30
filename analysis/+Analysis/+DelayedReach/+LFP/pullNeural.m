function [NeuralSampleRanges, NeuralStartTimes, NeuralEndTimes] = pullNeural(taskObj, TrialStarts, TrialEnds, PreBuffer, PostBuffer)
    NeuralZero = arrayfun(@(x) taskObj.data.neuralTime(x), TrialStarts);
    %neuralStarts = neuralStarts';
    %NeuralEnds = arrayfun(@(x) taskObj.data.neuralTime(x), TrialEnds); 
    %neuralEnds = neuralEnds';
    NeuralStartTimes = NeuralZero - PreBuffer;
    NeuralEndTimes = NeuralZero + PostBuffer;
    NeuralSampleRanges = [NeuralStartTimes (NeuralEndTimes - NeuralStartTimes)]; 
end