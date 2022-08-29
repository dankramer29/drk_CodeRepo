NumSamples = size(TestData,1);
NumChannels = size(TestData, 2);
NumTrials = size(TestData, 3);
TestDataConcat = zeros(NumSamples*NumTrials, NumChannels);

for Ch = 1:NumChannels
    %fprintf('Channel #%d\n***************\n',Ch)
    startSample = 1;
    endSample = NumSamples;
    for Tr = 1:NumTrials
        %fprintf('Trial #%d, Start: %d | End: %d\n',Tr, startSample, endSample)
        TestDataConcat(startSample:endSample,Ch) = TestData(:,Ch,Tr);
        startSample = startSample + NumSamples;
        endSample = endSample + NumSamples;
    end
end

TestDataConcatTime = 0:1/2000:(6*40);
TestDataConcat = TestDataConcat(1:size(TestDataConcatTime,2),:);