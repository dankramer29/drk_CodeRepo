function ccf = read(file,varargin)

VerboseFlag = true;
AvailableContainers = {'FilterInfo','ChanInfo','Sorting','SysInfo','LNC','AnalogOutput','NTrodeInfo','AdaptInfo','Session'};
RequestedContainers = {};

% check file existence
if exist(file,'file')~=2
    error('File ''%s'' does not exist',file);
end

% user input
if any(strncmpi(varargin,'quiet',1))
    VerboseFlag = false;
end
if any(strcmpi(varargin,'all'))
    RequestedContainers = AvailableContainers;
else
    for cc = 1:length(AvailableContainers)
        if any(strncmpi(varargin,AvailableContainers{cc},3))
            RequestedContainers{end+1} = AvailableContainers{cc};
        end
    end
end

% default to ChanInfo if nothing else requested
if isempty(RequestedContainers)
    if VerboseFlag
        warning('Default container ChanInfo selected');
    end
    RequestedContainers = {'ChanInfo'};
end

% read XML file
root = xmlread(file);

% read the data
for cc = 1:length(RequestedContainers)
    ContainerNode = getElementsByTagName(root,RequestedContainers{cc});
    try
        if ContainerNode.getLength>0
            ccf.(RequestedContainers{cc}) = Blackrock.CCF.(RequestedContainers{cc})(ContainerNode.item(0));
        end
    catch ME
        util.errorMessage(ME);
        keyboard
    end
end

% collapse to single struct if single requested container
if length(RequestedContainers)==1
    ccf = ccf.(RequestedContainers{1});
end