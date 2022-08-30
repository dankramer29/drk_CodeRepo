function packets = getProcwinBLcSections(blc,procwin,varargin)
% GETPROCWINBLCSECTIONS Identify data sections associated with procwins
%
% SUMMARY:
% bad trials are those for which the start time matches multiple recording
% packets due to a clock reset. here we make an assumption that bad trials
% will be clustered at the beginning and/or the end of the trials:
%
%   (*) if a clock reset occurs after the trials have finished but before
%       data stopped recording, then early trials' near-0 start times will
%       match multiple recording packets
%
%   (*) if a clock reset occurs during the trial run, then early and late
%       trials will have conflicting start times and both will match
%       multiple recording packets
%
% so long as there is a contiguous block of single-packet start times in
% the middle of the trials, we can use that information to infer which
% packet should be used for the early and late trials matching multiple
% packets.
warning('need to look through code and possibly change units and ref');

% interpret column 2 of procwin as either length or end time
[varargin,col2mode] = util.argkeyval('col2mode',varargin,'length');
[varargin,units] = util.argkeyval('units',varargin,'time');
[varargin,ref] = util.argkeyval('ref',varargin,'timestamp');
util.argempty(varargin);

% process blc,procwin
numArrays = length(blc);
if iscell(procwin)
    assert(length(procwin)==length(blc),'Must provide same number of procwin cells as ns cells');
else
    procwin = arrayfun(@(x)procwin,1:numArrays,'UniformOutput',false);
end

% check whether procwin cells contain matrices or cell arrays
if all(cellfun(@(x)iscell(x),procwin))
    procwin = cellfun(@(x)cat(1,x{:}),procwin,'UniformOutput',false);
end

% choose packet id fcn based on units
assert(ischar(units),'must provide units as char, not ''%s''',class(units));
if any(strcmpi(units,{'time','times','second','seconds','sec'}))
    fn = @getPacketsContainingTimeWindow;
    if strcmpi(col2mode,'endtime')
        procwin = cellfun(@(x)[x(:,1) x(:,2)-x(:,1)],procwin,'UniformOutput',false);
    end
elseif any(strcmpi(units,{'sample','samples'}))
    fn = @getPacketsContainingSampleWindow;
    if strcmpi(col2mode,'endtime')
        procwin = cellfun(@(x)[x(:,1) x(:,2)-x(:,1)+1],procwin,'UniformOutput',false);
    end
elseif any(strcmpi(units,{'timestamp','timestamps'}))
    fn = @getPacketsContainingTimestampWindow;
    if strcmpi(col2mode,'endtime')
        procwin = cellfun(@(x)[x(:,1) x(:,2)-x(:,1)+1],procwin,'UniformOutput',false);
    end
else
    error('unknown units ''%s''',units);
end

% check whether we can localize each trial to a single recording packet
packets = cell(1,numArrays);
for kk=1:numArrays
    numTrials = size(procwin{kk},1);
    
    st = procwin{kk}(:,1);
    len = procwin{kk}(:,2);
    [~,startPackets,~,endPackets] = arrayfun(@(x)fn(blc{kk},st(x),len(x),ref),1:numTrials,'UniformOutput',false);
    startNum = cellfun(@(y)length(y(~isnan(y))),startPackets);
    
    % identify packets of the good trials
    if all(startNum==0)
        endNum = cellfun(@(y)length(y(~isnan(y))),endPackets);
        if any(endNum~=0)
            
            % in a last ditch effort, make an assumption that the end
            % packet might have the data we need
            startPackets = {nan}; %endPackets;
        else
            
            % out of luck, set to nan and continue
            packets{kk} = nan;
            continue;
        end
    end
    
    % process start packets/nums
    startPackets = procPacketNum(startPackets,startNum);
    assert(all(cellfun(@length,startPackets)==1),'start packets still contain multiple entries');
    
    % if no end packets, just use start packets and return
    if isempty(endPackets)
        packets{kk} = startPackets;
    else
        
        % process end packets/nums
        endNum = cellfun(@(y)length(y(~isnan(y))),endPackets);
        endPackets = procPacketNum(endPackets,endNum);
        assert(all(cellfun(@length,endPackets)==1),'end packets still contain multiple entries');
        
        % combine start/end packets into single list of packets per procwin
        packets{kk} = cell(1,numTrials);
        for bb=1:numTrials
            if isnan(startPackets{bb}) && isnan(endPackets{bb})
                packets{kk}{bb} = nan;
            elseif isnan(startPackets{bb})
                packets{kk}{bb} = [nan endPackets{bb}];
            elseif isnan(endPackets{bb})
                packets{kk}{bb} = [startPackets{bb} nan];
            else
                packets{kk}{bb} = startPackets{bb}:endPackets{bb};
            end
        end
    end
end



function packets = procPacketNum(packets,num)
numTrials = length(packets);

% use information about future or past trials to infer the correct packet
% for the current trial, if multiple packets match
for bb=1:numTrials
    
    % if only one packet already, nothing needs to be changed
    if isscalar(packets{bb})&&~isnan(packets{bb}),continue;end
    
    % check whether there are valid (i.e., single) packets before/after
    if any(num(bb+1:end)==1)
        packetNextValid = packets{bb+find(num(bb+1:end)==1,1,'first')};
    else
        packetNextValid = nan;
    end
    if any(num(1:bb-1)==1)
        packetPrevValid = packets{find(num(1:bb-1)==1,1,'last')};
    else
        packetPrevValid = nan;
    end
    
    % replace the multiple packets with single packet depending on
    % configuration of preceding/following packets
    if isnan(packetPrevValid) && isnan(packetNextValid)
        
        % no prior or following single packets, so nothing we can do!
        packets{bb} = nan; % DONT KNOW
    elseif isnan(packetPrevValid)
        
        % there is no preceding, but there is a following; replace if it is
        % one of the already matching packets, otherwise nothing we can do
        if isempty(packets{bb}) || ismember(packetNextValid,packets{bb}) || isnan(packets{bb})
            packets{bb} = packetNextValid;
        else
            packets{bb} = nan; % DONT KNOW
        end
    elseif isnan(packetNextValid)
        
        % there is no following, but there is a preceding; replace if it is
        % one of the already matching packets, otherwise nothing we can do
        if isempty(packets{bb}) || ismember(packetPrevValid,packets{bb}) || isnan(packets{bb})
            packets{bb} = packetPrevValid;
        else
            packets{bb} = nan; % DONT KNOW
        end
    else
        
        % both preceding and following trials have single matching packets
        if isempty(packets{bb}) || (ismember(packetPrevValid,packets{bb}) && ismember(packetNextValid,packets{bb})) || all(isnan(packets{bb}))
            
            % if they are the same packet, all good and replace; otherwise
            % don't know what to do
            if packetPrevValid==packetNextValid
                packets{bb} = packetPrevValid;
            else
                packets{bb} = nan; % DONT KNOW
            end
        elseif ismember(packetPrevValid,packets{bb})
            
            % only the previous single packet matches
            packets{bb} = packetPrevValid;
        elseif ismember(packetNextValid,packets{bb})
            
            % only the following single packet matches
            packets{bb} = packetNextValid;
        else
            
            % neither the previous nor the following single packet matches
            packets{bb} = nan; % DONT KNOW
        end
    end
end