samplingRate = 100000;
%MinPeakDistance = 50000/frequency
%MinPeakHeight = Current / 2
resistor = .220;

%% Natus
natusFiles = dir('C:\Data\StimTask\Natus\*.bin');
b = arrayfun(@(x)NI.BinFile(fullfile(x.folder, x.name)), natusFiles, 'uniformoutput', false);
[X,T] = cellfun(@read, b, 'uniformoutput', false);
mANatus = cellfun(@(x)x/resistor, X, 'uniformoutput', false);
numParams = size(mANatus,1); 
meanSDNatus = zeros(numParams,6);
%  positivePeaks = [];
%  negativePeaks = [];
for i = 1:numParams
    Frequency = TableNatus.PulseRate(i);
    MinPeakDistance = 50000/Frequency;
    Current = TableNatus.Current(i);
    MinPeakHeight = Current/2;
     positivePeaks = findpeaks(double(mANatus{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight);
     negativePeaks = findpeaks(double(-mANatus{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight);
%      positivePeaks = cat(1,positivePeaks,findpeaks(double(mANatus{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight));
%      negativePeaks = cat(1,negativePeaks, findpeaks(double(-mANatus{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight));
    meanSDNatus(i,1) = mean(positivePeaks);
    meanSDNatus(i,2) = std(positivePeaks);
    meanSDNatus(i,3) = -mean(negativePeaks);
    meanSDNatus(i,4) = std(negativePeaks);
    meanSDNatus(i,5) = size(positivePeaks,1);
    meanSDNatus(i,6) = size(negativePeaks,1);
end



%% Grass

grassFiles = dir('C:\Data\StimTask\grass\*.bin');
b = arrayfun(@(x)NI.BinFile(fullfile(x.folder, x.name)), grassFiles, 'uniformoutput', false);
[X,T] = cellfun(@read, b, 'uniformoutput', false);
mAGrass = cellfun(@(x)x/resistor, X, 'uniformoutput', false);
numParams = size(mAGrass,1); 
meanSDGrass = zeros(numParams,6);
% 
% positivePeaks = [];
% negativePeaks = [];

for i = 1:numParams
    Frequency = TableGrass.PulseRate(i);
    MinPeakDistance = 50000/Frequency;
    Current = TableGrass.Current(i);
    MinPeakHeight = Current/2;
    positivePeaks = findpeaks(double(mAGrass{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight);
    negativePeaks = findpeaks(double(-mAGrass{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight);
%     positivePeaks = cat(1,positivePeaks, findpeaks(double(mAGrass{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight));
%     negativePeaks = cat(1,negativePeaks, findpeaks(double(-mAGrass{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight));
    meanSDGrass(i,1) = mean(positivePeaks);
    meanSDGrass(i,2) = std(positivePeaks);
    meanSDGrass(i,3) = -mean(negativePeaks);
    meanSDGrass(i,4) = std(negativePeaks);
    meanSDGrass(i,5) = size(positivePeaks,1);
    meanSDGrass(i,6) = size(negativePeaks,1);
end



%% Ojemann
% files were out of order due to ni_######_param format. Removed #s so now
% the format is ni_param##_###.bin

ojemannFiles = dir('C:\Data\StimTask\ojemann\*.bin');
b = arrayfun(@(x)NI.BinFile(fullfile(x.folder, x.name)), ojemannFiles, 'uniformoutput', false);
[X,T] = cellfun(@read, b, 'uniformoutput', false);
mAOjemann = cellfun(@(x)x/resistor, X, 'uniformoutput', false);
numParams = size(mAOjemann,1); 
meanSDOjemann = zeros(numParams,6);

positivePeaks = [];
negativePeaks = [];

for i = 28:36
    Frequency = TableOjemann.PulseRate(i);
    MinPeakDistance = 50000/Frequency;
    Current = TableOjemann.Current(i);
    MinPeakHeight = Current/2;
%     positivePeaks = findpeaks(double(mAOjemann{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight);
%     negativePeaks = findpeaks(double(-mAOjemann{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight);
    positivePeaks = cat(1,positivePeaks,findpeaks(double(mAOjemann{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight));
    negativePeaks = cat(1,negativePeaks,findpeaks(double(-mAOjemann{i}), 'MinPeakDistance', MinPeakDistance, 'MinPeakHeight', MinPeakHeight));
    meanSDOjemann(i,1) = mean(positivePeaks);
    meanSDOjemann(i,2) = std(positivePeaks);
    meanSDOjemann(i,3) = -mean(negativePeaks);
    meanSDOjemann(i,4) = std(negativePeaks);
    meanSDOjemann(i,5) = size(positivePeaks,1);
    meanSDOjemann(i,6) = size(negativePeaks,1);
end
