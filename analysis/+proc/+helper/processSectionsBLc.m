function [sections,time_from_source,idx_in_output,idx_ok,num_samples_in_output] = processSectionsBLc(ns,fs,procwin,sections,num_arrays,num_wins,FlagUnifiedTiming,logfcn)
FlagUpdateSections = false;
if iscell(sections)
    
    % first, make sure one packet per array
    if length(sections)==1
        sections = arrayfun(@(x)sections{1}(:),1:num_arrays,'UniformOutput',false);
    else
        assert(length(sections)==num_arrays,'If packets is a cell with more than one cell, it must have %d cells',num_arrays);
    end
    
    % next make sure correct dimensions
    for nn=1:num_arrays
        if length(sections{nn})==1
            sections{nn} = arrayfun(@(x)sections{nn},1:num_wins,'UniformOutput',false);
        end
        assert(length(sections{nn})==num_wins,'Each cell of packets must be length %d',num_wins);
    end
elseif isnan(sections) || isempty(sections)
    
    % get early estimate of recording packets
    sections = proc.helper.getProcwinNSxPackets(ns,procwin,'col2mode','length','units','seconds');
    FlagUpdateSections = true;
else
    if isnumeric(sections)
        if isscalar(sections)
            sections = arrayfun(@(y)arrayfun(@(x)sections,(1:num_wins)','UniformOutput',false),1:num_arrays,'UniformOutput',false);
        else
            if length(sections)==num_wins
                sections = arrayfun(@(x)arrayfun(@(y)sections(y),(1:num_wins)','UniformOutput',false),1:num_arrays,'UniformOutput',false);
            elseif length(sections)==num_arrays
                sections = arrayfun(@(x)arrayfun(@(y)x,(1:num_wins)','UniformOutput',false),sections,'UniformOutput',false);
            elseif size(sections,1)==num_wins && size(sections,2)==num_arrays
                sections = mat2cell(sections,num_wins,num_arrays);
            else
                error('Unknown configuration for packets input');
            end
        end
    end
end
assert(length(sections)==num_arrays && all(cellfun(@(x)length(x)==num_wins,sections)==1),'If packets is a cell array, it must be length %d, each cell length %d',num_arrays,num_wins);

% identify file read timing and raw data sample placement
time_from_source = arrayfun(@(x)cell(num_wins,1),1:num_arrays,'UniformOutput',false);
idx_in_output = arrayfun(@(x)cell(num_wins,1),1:num_arrays,'UniformOutput',false);
idx_ok = arrayfun(@(x)true(num_wins,1),1:num_arrays,'UniformOutput',false);
for kk=1:num_wins
    for nn=1:num_arrays
        idx_packet = sections{nn}{kk};
        idx_packet = unique(idx_packet(~isnan(idx_packet)));
        assert(~isempty(idx_packet),'Could not identify recording packet for procwin %d/%d, array %d/%d: requested [%.2f +%.2f] sec',kk,num_wins,nn,num_arrays,procwin{nn}(kk,1),procwin{nn}(kk,2));
        [~,idx_which] = max(ns{nn}.PointsPerDataPacket(idx_packet));
        idx_packet = idx_packet(idx_which);
        local_min_time = ns{nn}.Timestamps(idx_packet)/ns{nn}.TimestampTimeResolution;
        local_max_time = ns{nn}.Timestamps(idx_packet)/ns{nn}.TimestampTimeResolution + ns{nn}.PointsPerDataPacket(idx_packet)/fs;
        local_procwin = procwin{nn}(kk,:);
        
        % determine requested time range
        time_from_source{nn}{kk}(1) = max(local_min_time,local_procwin(1));
        time_from_source{nn}{kk}(2) = min(local_max_time,local_procwin(1)+local_procwin(2));
        if time_from_source{nn}{kk}(1)>local_procwin(1)
            proc.helper.log(logfcn,sprintf('Array %d/%d, procwin %d/%d start time clamped from %.3f to %.3f',nn,num_arrays,kk,num_wins,local_procwin(1),time_from_source{nn}{kk}(1)),'warn');
        end
        if time_from_source{nn}{kk}(2)<=time_from_source{nn}{kk}(1)
            proc.helper.log(logfcn,sprintf('Insufficient data for array %d/%d, procwin %d/%d',nn,num_arrays,kk,num_wins),'warn');
            idx_ok{nn}(kk) = false;
            time_from_source{nn}{kk} = [nan nan];
            continue;
        end
        if time_from_source{nn}{kk}(2)<(local_procwin(1)+local_procwin(2))
            proc.helper.log(logfcn,sprintf('Array %d/%d, procwin %d/%d end time clamped from %.3f to %.3f',nn,num_arrays,kk,num_wins,local_procwin(1)+local_procwin(2),time_from_source{nn}{kk}(2)),'warn');
        end
        
        % identify sample correspondents to time start/end
        idx_start = round( (time_from_source{nn}{kk}(1) - local_procwin(1))*fs ) + 1;
        idx_end = idx_start + round( diff(time_from_source{nn}{kk})*fs ) - 1;
        idx_in_output{nn}{kk} = [idx_start idx_end];
    end
end

% compute the number of samples expected for each processing window
num_samples_in_output = cellfun(@(x)cellfun(@(y)y(2),x),idx_in_output,'UniformOutput',false);

% if user requests unified timing, find the joint timing superset for each
% procwin, then calculate the indices in that joint space in which to place
% the neural data for each array
% this is not always relevant when asking for trials as procwins since the
% time for each trial is the same across arrays. it's more relevant when
% asking for all the data in a file, for example, where the two files might
% be off slightly in the amount of time recorded.
if FlagUnifiedTiming
    
    % loop over processing windows
    for kk=1:num_wins
        
        % grab start/end times for this window for each array
        start_times = arrayfun(@(y)time_from_source{y}{kk}(1),1:num_arrays);
        end_times = arrayfun(@(y)time_from_source{y}{kk}(2),1:num_arrays);
        if nnz(unique(start_times))==1 && nnz(unique(end_times))==1
            
            % all start/end at the same time -- no need to modify anything
            continue;
        end
        
        % differences in start and/or end times -- need to tack on
        % extra buffer to beginning/end of sample indices to account
        min_start = min(start_times);
        max_end = max(end_times);
        
        % loop over arrays
        for nn=1:num_arrays
            if start_times(nn)>min_start
                
                % add offset samples (will result in NaNs prepended)
                num_extra_samples = round( (start_times(nn) - min_start)*fs ) - 1;
                idx_in_output{nn}{kk} = idx_in_output{nn}{kk} + num_extra_samples;
            end
            num_samples_in_output{nn}(kk) = round((max_end-min_start)*fs);
        end
    end
end

% remove processing windows not supported by data
for nn=1:num_arrays
    time_from_source{nn}(~idx_ok{nn}) = [];
    idx_in_output{nn}(~idx_ok{nn}) = [];
end
idx_ok = cellfun(@(x)find(x),idx_ok,'UniformOutput',false);

% identify recording packets associated with each file timing
if FlagUpdateSections
    sections = proc.helper.getProcwinNSxPackets(ns,time_from_source,'col2mode','endtime','units','seconds');
end