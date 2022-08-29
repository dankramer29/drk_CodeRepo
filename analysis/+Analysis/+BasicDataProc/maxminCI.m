function [maxminci] = maxminCI(data,varargin)
%maximaCI combines specChange and a boot CI to output a table
%to be used with out put from Analysis.BasicDataProc.specChange 

[varargin, binSize] = util.argkeyval('binSize',varargin, 1); %input the timing to have time of events in ms


%get the overall mean

if size(data,3)>1
    dataMean=nanmean(data, 3)*binSize;
    idx=0;
    for ii=1:size(data,2)
        tempD=squeeze(data(:,ii,:))';
        CI=bootci(1000, {@mean, tempD}, 'type', 'cper');
        maxminci(1+idx,1)=dataMean( 1, ii);
        maxminci(2+idx,1)=CI( 1, 1)*binSize;
        maxminci(3+idx,1)=CI( 2, 1)*binSize;
        maxminci(4+idx,1)=dataMean( 2, ii);
        maxminci(5+idx,1)=CI( 1, 2)*binSize;
        maxminci(6+idx,1)=CI( 2, 2)*binSize;
        maxminci(7+idx,1)=dataMean( 3, ii);
        maxminci(8+idx,1)=CI( 1, 3)*binSize;
        maxminci(9+idx,1)=CI( 2, 3)*binSize;
        maxminci(10+idx,1)=dataMean( 4, ii);
        maxminci(11+idx,1)=CI( 1, 4)*binSize;
        maxminci(12+idx,1)=CI( 2, 4)*binSize;
        idx=idx+12;
    end
else
    dataMean=nanmean(data, 2)*binSize;    
    CI=bootci(1000, {@mean, data'}, 'type', 'cper');
    maxminci(1,1)=dataMean( 1, 1);
    maxminci(2,1)=CI( 1, 1)*binSize;
    maxminci(3,1)=CI( 2, 1)*binSize;
    maxminci(4,1)=dataMean( 2, 1);
    maxminci(5,1)=CI( 1, 2)*binSize;
    maxminci(6,1)=CI( 2, 2)*binSize;
    maxminci(7,1)=dataMean( 3, 1);
    maxminci(8,1)=CI( 1, 3)*binSize;
    maxminci(9,1)=CI( 2, 3)*binSize;
    maxminci(10,1)=dataMean( 4, 1);
    maxminci(11,1)=CI( 1, 4)*binSize;
    maxminci(12,1)=CI( 2, 4)*binSize;
end

end




