function unitId = date2unitId(dates)
%UNITID2DATE Returns the date (yyyymmdd) corresponding to each unit ID.
%   Requires the elapsed time in the id (i.e. the 4th element from UnitIDs)

refDate = [2013 01 01 0 0 0];

NUnits = size(dates,1);
dt = datetime(dates,'InputFormat','yyyyMMdd');
% repmat(refDate,NUnits,1) + [zeros(NUnits,5) UnitID(:,4)*60*60*24]);
unitId = etime(datevec(dt),refDate)/60/60/24;
% dates = cellstr(datestr(dt,'yyyyMMdd'));

% Inverse problem donw in Blackrock.NEV2SpikeData
% tmp=NEV.MetaTags.DateTimeRaw;
% SpikeData{indx,7} = etime([tmp([1 2 4]) 0 0 0],refDate)/60/60/24;
                

end

