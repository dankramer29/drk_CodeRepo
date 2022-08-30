function validate(this)
% VALIDATE Compare Blackrock.NEV and NPMK outputs

% look for NPMK
if exist('openNEV','file')~=2
    extdir = env.get('external');
    npmkdir = fullfile(extdir,'NPMK');
    if exist(npmkdir,'dir')==7
        addpath(genpath(npmkdir));
    end
end
if exist('openNEV','file')~=2
    log(this,'Cannot validate: could not locate NPMK package','warn');
    return;
end

% read data from Blackrock.NEV
nv1 = read(this,'all');
if ~iscell(nv1.Spike)
    
    % make sure all fields are cell arrays
    fields = fieldnames(nv1);
    for kk=1:length(fields)
        nv1.(fields{kk}) = util.ascell(nv1.(fields{kk}));
    end
end

% read data from NPMK
nv2 = openNEV(fullfile(this.SourceDirectory,sprintf('%s.nev',this.SourceBasename)),'nosave','nomat','read');

% identify recording blocks in the NPMK output
npmkStart = [1 find(diff(double(nv2.Data.Spikes.TimeStamp))<0)+1];
npmkLen = [diff(npmkStart) length(nv2.Data.Spikes.TimeStamp)-npmkStart(end)+1];

% pull out number of spike timestamps in each NEV block
nevLen = arrayfun(@(x)size(nv1.Spike{x}.Timestamps,1),1:length(nv1.Spike));

% validate lengths and sizes
assert(length(nevLen)==length(npmkLen),'Number of recording blocks mismatched (npmk: %d, nev: %d)',length(npmkLen),length(nevLen));
assert(all(nevLen==npmkLen),'Lengths of recording blocks mismatched (npmk: %s, nev: %s)',util.vec2str(npmkLen),util.vec2str(nevLen));

% select a random set of indices to compare
[~,mainPacket] = max(nevLen);
idx = randperm(length(nv1.Spike{mainPacket}.Timestamps),min(max(round(0.1*length(nv1.Spike{mainPacket}.Timestamps)),1e4),length(nv1.Spike{mainPacket}.Timestamps)));
npmkOffset = sum(npmkLen(1:mainPacket-1));
assert(all(nv1.Spike{mainPacket}.Timestamps(idx)==nv2.Data.Spikes.TimeStamp(npmkOffset+idx)'),'Timestamp values do not match');
assert(all(nv1.Spike{mainPacket}.Channels(idx)==nv2.Data.Spikes.Electrode(npmkOffset+idx)'),'Channel values do not match');
assert(all(all(nv1.Spike{mainPacket}.Waveforms(:,idx)==nv2.Data.Spikes.Waveform(:,npmkOffset+idx))),'Waveforms do not match');