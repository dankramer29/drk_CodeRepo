function [closestIndex, closestValue] = timeStampConversion(behavioralTimeStamps,macromicroTimeStamps)
%timeStampConversion get a vector that has the correct indices for the time
%stamps
%   Inputs
%       behavioralTimeStamps = the ones that are on the output from the mat
%       file from psychtoolbox (beh_timestamps) 
%       macromicroTimeStamps = the ones that are on the neural clock
%       (ma_timestampsDS). NOTE: the ma_timeStamps (i.e. ma_timeStampsDS)
%       should be downsampled to equal the number of samples in the macro
%       or micro data (i.e. length(macromicroTimeStamps) =
%       length(macrowires)

%   Outputs
%       cosestIndex = vector that has the indices of the closest thing to
%       the timestamps
%       closestValue = the actual value at each index, which probably isn't
%       needed

[row col] = size(macromicroTimeStamps);
if col > row
    macromicroTimeStamps=macromicroTimeStamps';
end

[row col] = size(behavioralTimeStamps);
if col > row
    behavioralTimeStamps=behavioralTimeStamps';
end


A = repmat(macromicroTimeStamps,[1 length(behavioralTimeStamps)]);
[minValue,closestIndex] = min(abs(A-behavioralTimeStamps'));
closestValue = macromicroTimeStamps(closestIndex); 


end