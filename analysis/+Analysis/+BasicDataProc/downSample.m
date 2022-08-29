function [dsData] = downSample(data, oldrate, newrate)
%downSample takes data and downsamples it with a lowpass filter.
%   Inputs:
%         data- data you want to downsample
%         oldrate- old sampling rate in samples/sec
%         newrate- the new rate you want in samples/sec

dsRate=floor(oldrate/newrate);
lwPass=floor(oldrate*.4); %get the new downsample rate and lowpass to 80% of that for safe nyquist line

%preallocate
dsData=zeros(size(data,1),floor(size(data,2)/dsRate));


% Lowpass for nyquist
bsFilt1 = designfilt('lowpassiir','FilterOrder',8, ...
    'HalfPowerFrequency', lwPass, ...
    'SampleRate', oldrate, 'DesignMethod','butter');

%convert to double
if ~isa(data, 'double')
    data=double(data);
end

%filtfilt needs the data to go down (apparently)
if size(data,1)<size(data,2)
    data=data';
    dsData=dsData';
end


%lowpass for nyquist
data=filtfilt(bsFilt1, data);

%downsample through subsampling
dsData=data(1:dsRate:end, :);


end

