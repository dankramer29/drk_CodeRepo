function [rawVt] = parse_RawData(this, data, blc, varargin)
% parse the raw data up into the different chunks based on the events


%check which day the recording happened on
[varargin,recordingday] = util.argkeyval('recordingday',varargin,1);
[varargin,dt] = util.argkeyval('dt', varargin, blc.OriginTime);


% First divide per event/trial type
vtTimeStamps = cell(1,length(this.evtNames));
vtFrames = cell(1,length(this.evtNames));
rawVt = cell(1,length(this.evtNames));

%set up the start times

sf=blc.SamplingRate;
for nn = 1:length(this.evtData) %run through each type of touch
    % Get range of marked events (XX = start touch, ZZ = end
    % touch)
    idx1 = find(strcmp(this.evtData{nn},'XX'),1,'first');
    idx2 = find(strcmp(this.evtData{nn},'ZZ'),1,'last');
    iniTs = this.evtTimeStamp{nn}{idx1}(1:end-2); %this pulls the FIRST time stamp (if you haven't adjusted the time stamps by the ms, this will only go on integer seconds
    endTs = this.evtTimeStamp{nn}{idx2}(1:end-2); %the end-2 pulls off the last characters which are spaces, these time stamps make up the whole trial
    
    tempts = []; tempfr = []; tempvt = [];
    idxTs1 = []; idxTs2 = [];
    while isempty(rawVt{nn}) % Loop through dataset until we find first and last trial times
       
        if isempty(idxTs1)
            %find the index of the start time of the trial 
            [idxTs1]=Analysis.ArtSens.dt_diff(iniTs, dt, sf, 'recordingday', recordingday);             
        end
        if isempty(idxTs2)
            [idxTs2]=Analysis.ArtSens.dt_diff(endTs, dt, sf, 'recordingday', recordingday); 
            %idxTs2 = find(strcmp(data.time,endTs),1,'last'); %this is what
            %it used to look like, in case that 'last' matters
        end
        if ~isempty(idxTs1) && isempty(idxTs2) %in the event there is not end time
            %tempts = [tempts;data.time(idxTs1:end)]; %concat the times, may not need this
            %tempfr = [tempfr;data.byte(idxTs1:end)];
            %tempvt = [tempvt;getChanVoltages(this,data,[idxTs1 length(data.time)])];
            
            %includes all channels CHANGE HERE IF YOU WANT LESS CHANNELS
            tempvt=[tempvt; data(idxTs1:end,:)];
            
            idxTs1 = 1;
        elseif ~isempty(idxTs1) && ~isempty(idxTs2) %with an end time and start time
            %tempts = [tempts;data.time(1:idxTs2)];
            %tempfr = [tempfr;data.byte(1:idxTs2)];
            %tempvt = [tempvt;getChanVoltages(this,data,[1 idxTs2])];
            
            %includes all channels        
            %this is taking the data from the beginning to the end of the
            %trial, which in the case of the first one is point 1, probably
            %could be cleaned up, but currently everything is expecting it
            %to be data point 1 
            tempvt=[tempvt; data(1:idxTs2, :)];%should concat the data from the beginning to the end.  
            
            
            %vtTimeStamps{nn} = tempts; %this is the time stamps and will exist as a conversion from the datetime
            %vtFrames{nn} = tempfr; %frames, meaning the bytes, this is now recorded as just the row
            rawVt{nn} = tempvt; %this is the actual data and includes the start to the end of the trial
        end
    end
end
end % END of parseRawData function

