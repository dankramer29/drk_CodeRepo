function hoops = getHoops(file,varargin)

% defaults
hoops = [];
hArrayMap = [];
UserRequestedElectrode = [];
UserRequestedChannel = [];

% check file exist and read XML
if exist(file,'file')~=2
    error('File %s does not exist.',file);
end
root = xmlread(file);
ChanInfo_items = getElementsByTagName(root,'ChanInfo_item');
numChans = ChanInfo_items.getLength;

% read user inputs
if any(strncmpi(varargin,'mapfile',2))
    idx = find(strncmpi(varargin,'mapfile',2),1,'first');
    mapfile = varargin{idx+1};
    hArrayMap = Blackrock.ArrayMap(mapfile);
end
if any(strncmpi(varargin,'electrode',2))
    idx = find(strncmpi(varargin,'electrode',2),1,'first');
    UserRequestedElectrode = sort(unique(varargin{idx+1}),'ascend');
    if ~isempty(hArrayMap)
        UserRequestedChannel = hArrayMap.el2ch(UserRequestedElectrodes);
    end
end
if any(strncmpi(varargin,'channel',2))
    idx = find(strncmpi(varargin,'channel',2),1,'first');
    UserRequestedChannel = sort(unique(varargin{idx+1}),'ascend');
    if ~isempty(hArrayMap)
        UserRequestedElectrode = hArrayhArrayMap.ch2el(UserRequestedChannel);
    end
end

% check channels
if ~isempty(UserRequestedElectrode) && isempty(UserRequestedChannel)
    error('Must provide mapfile when using electrode numbers instead of channels.');
end
if isempty(UserRequestedChannel)
    UserRequestedChannel = 1:96;
    if ~isempty(hArrayMap)
        UserRequestedElectrode = hArrayMap.ch2el(UserRequestedChannel);
    end
end

% match up available channels with requested channels
MatchChannel = nan(size(UserRequestedChannel));
for nn=0:numChans-1
    chLabel = char(ChanInfo_items.item(nn).getAttribute('label'));
    switch lower(chLabel(1:4))
        case 'chan'
            idx = find(UserRequestedChannel==str2double(chLabel(5:end)),1,'first');
        case 'elec'
            idx = find(UserRequestedElectrode==str2double(chLabel(5:end)),1,'first');
        otherwise
            idx = [];
    end
    if ~isempty(idx)
        MatchChannel(idx) = nn;
    end
end
if any(isnan(MatchChannel))
    warning('Could not match some requested channels: %s',sprintf('%d ',UserRequestedChannel(isnan(MatchChannel))));
end
UserRequestedChannel(isnan(MatchChannel))=[];
if ~isempty(UserRequestedElectrode)
    UserRequestedElectrode(isnan(MatchChannel))=[];
end
MatchChannel(isnan(MatchChannel))=[];
if isempty(MatchChannel)
    warning('Could not find any of the requested channels');
    return;
end

% process hoops nodes
hoopsIdx = 1;
for nn=1:length(MatchChannel)
    nodeIdx = MatchChannel(nn);
    hoops_node = getElementsByTagName(ChanInfo_items.item(nodeIdx),'hoops');
    if hoops_node.getLength>0
        hoop_nodes = getElementsByTagName(hoops_node.item(0),'hoop');
        for mm=0:hoop_nodes.getLength-1 % loop over units
            [tm,mn,mx] = Blackrock.CCF.processHoop(hoop_nodes.item(mm));
            if ~isempty(tm)
                hoops(hoopsIdx).channel = UserRequestedChannel(nn);
                if ~isempty(UserRequestedElectrode)
                    hoops(hoopsIdx).electrode = UserRequestedElectrode(nn);
                end
                hoops(hoopsIdx).unit = mm+1;
                hoops(hoopsIdx).time = tm;
                hoops(hoopsIdx).min = mn;
                hoops(hoopsIdx).max = mx;
                hoopsIdx = hoopsIdx + 1;
            end
        end
    end
end
