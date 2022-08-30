function [dataMin] = minVoltForSpike(data, varargin)
%minVoltForSpike take the minimum value of the voltage per ms for the
%purpose of RMS spike sorting


[varargin, fs] = util.argkeyval('fs',varargin, 30000); %sampling rate

%Data should be filtered already with high pass

%%
%make sure data is columns=channels and rows are time
if size(data, 1)<size(data,2)
    data=data';
end

%only look at negative values
%data(data>0)=NaN;

Nstep=fs/1000;
dataMin=zeros(ceil(size(data,1)/Nstep), size(data,2));

idx=1;
%note, last value will be 0, just for timing.
for ii=1:Nstep:size(data,1)-Nstep
    dataMin(idx,:)=nanmin(data(ii:ii+Nstep,:));
    idx=idx+1;
end

end


