function valid = detectSyncPackets(ns)
% DETECTSYNCPACKETS Determine which data packets in NSx files precede syncs
%
%   VALID = DETECTSYNCPACKETS(NS)
%   For the BLACKROCK.NSX objects in the cell array NS, identify data
%   packets which precede NSP sync and return the indices of subsequent
%   data packets in VALID. See algorithm description in the notes below.
%
%   NOTES
%   When two NSPs synchronize, the clocks reset (see the articles
%   referenced below for more information). After the sync, a new data
%   packet begins with synchronized data (see file spec referenced below).
%   Since the clock was running up to some value before resetting to zero,
%   the number of samples in the pre-sync data packet will be longer than
%   would seem possible based on the starting timestamp of the subsequent
%   data packet. In this way we can detect pre-sync packets. Please note
%   that this code is experimental and all results should be manually
%   verified!
%
%   See Blackrock Support articles:
%   http://support.blackrockmicro.com/KB/View/166114-how-to-sync--nsps
%   http://support.blackrockmicro.com/KB/View/166828-synchronization-specifics
%
%   See Blackrock NEV/NSx file specification:
%   http://support.blackrockmicro.com/KB/View/166838-file-specifications-packet-details-headers-etc

% validate inputs
ns = util.ascell(ns); % enforce cell array
assert(all(cellfun(@(x)isa(x,'Blackrock.NSx'),ns)),'Inputs must be BLACKROCK.NSX objects');

% loop over BLACKROCK.NSX objects
valid = cell(1,length(ns));
for nn=1:length(ns)
    
    % loop over data packets for this BLACKROCK.NSX object
    valid{nn} = false(1,ns{nn}.NumDataPackets);
    valid{nn}(end) = true; % last one cannot precede a reset
    runningDataLength = 0;
    for pp=1:ns{nn}.NumDataPackets-1
        
        % find the end of the current packet, and the start of the next
        thisPacketEndTime = runningDataLength + ns{nn}.PointsPerDataPacket(pp)/ns{nn}.Fs;
        nextPacketStartTime = ns{nn}.Timestamps(pp+1)/ns{nn}.TimestampTimeResolution;
        
        % data packet is valid (post-sync) if it ends before next begins
        valid{nn}(pp) = thisPacketEndTime < nextPacketStartTime;
        
        % update the last relevant packet's end time if relevant
        if valid{nn}(pp)
            runningDataLength = thisPacketEndTime;
        end
    end
    
    % check for syncs that occur after the first packet
    if any(~valid{nn}(2:end))
        warning('Sync detected in NSP %d after the first data packet - results cannot be guaranteed. Proceed with caution!',nn);
    end
    
    % convert from logical to numerical indexing
    valid{nn} = find(valid{nn});
end