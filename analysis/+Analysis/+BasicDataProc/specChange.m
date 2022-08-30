function [ peakStartIdx ] = specChange(data, varargin )
%specChange- finds the timing of changes in continuous data, the start of the maxima and minima  

% This is meant to be done for each trial, so timing changes don't get averaged out.
% Find the max change in the data. Find when it rises above the 10% of that mark and sustains.


% Inputs:
%     data= any continuous data, assumes that third dimension is the one to
%     average across (i.e. trials)

% Outputs
%     peakStartIdx:    gives the indices of the max (row 1) and min (row 3)
%     starts for the maxima/minima and the actual max (row 2) and min (row
%     4)
% Example:
%     [ peakStartIdx]=Analysis.BasicDataProc.specChange(data);

peakStartIdx=[];

%rows data, columns channels/bands/etc
if size(data, 1)<size(data,2)
    data=data';
end


for jj=1:size(data,3)
    for ii=1:size(data,2)
        [pk, pki]=findpeaks(data(:,ii,jj));
        if isempty(pk)
            [pk, pki]=max(data(:,ii));
        end
        [val, vali]=findpeaks(-data(:,ii,jj));
        if isempty(val)
            [val, vali]=max(-data(:,ii,jj));
        end
        [mx, mxiT]=max(pk);
        mxi=pki(mxiT);
        [mn, mniT]=max(val);
        mni=vali(mniT);
        
        valPre=vali(vali<mxi);
        if isempty(valPre)
            peakStartIdx(1,ii,jj)=1;
        else
            peakStartIdx(1,ii,jj)=valPre(end);
        end
        peakStartIdx(2,ii,jj)=mxi;
        
        peakPre=pki(pki<mni);
        if isempty(peakPre)
            peakStartIdx(3,ii,jj)=1;
        else
            peakStartIdx(3,ii,jj)=peakPre(end);
        end
        peakStartIdx(4,ii,jj)=mni;
    end
end


    

end


