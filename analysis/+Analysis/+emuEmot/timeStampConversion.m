function [closestIndex, closestValue] = timeStampConversion(behavioralTimeStamps,macromicroTimeStamps)
%timeStampConversion get a vector that has the correct indices for the time
%stamps
%   Inputs
%       neuralTimeStamps = the ones that are on the neural clock
%       (beh_timestamps)
%       psychToolTimeStamps = the ones that are on the output from the mat
%       file from psychtoolbox (ma_timeStamps) NOTE: the ma_timeStamps
%       should be downsampled to equal the number of samples in the macro
%       or micro data (i.e. length(macromicroTimeStamps) =
%       length(macrowires)

%   Outputs
%       cosestIndex = vector that has the indices of the closest thing to
%       the timestamps
%       closestValue = the actual value at each index, which probably isn't
%       needed


A = repmat(macromicroTimeStamps,[1 length(behavioralTimeStamps)]);
[minValue,closestIndex] = min(abs(A-behavioralTimeStamps'));
closestValue = macromicroTimeStamps(closestIndex); 


end