function [electrodes,impFlag,idx] = checkValidElectrodes(electrodes,idString,arrayName)
if nargin<3||isempty(arrayName),arrayName='s1x';end
stimarrays = util.ascell(env.get('stimarrays'));
assert(ischar(arrayName)&&ismember(lower(arrayName),cellfun(@lower,stimarrays,'UniformOutput',false)),'Could not find array ''%s'' in list of stim arrays %s',arrayName,strjoin(stimarrays,', '));

if nargin == 1; idString = datestr(now,'yyyymmdd-HHMMSS'); end

% get electrode array map
map = Blackrock.ArrayMap(hst.getMapFiles(env.get('subject'),arrayName));
threshold = 2000;
flagThres = 150;
impFlag = false(size(electrodes));

% get impedance file
%datapath = env.get('data');
datapath = env.get('output');
datapath = repmat({datapath},1,3);
fid = fopen(fullfile(datapath{3},env.get('subject'),datestr(now,'yyyymmdd'),'Impedance','s1x.txt'));
if fid > 0
    filecell = textscan(fid,'%s %f %s','HeaderLines',9);
    fclose(fid);
    channels = filecell{1};
    impedance = filecell{2};
    
    % separate prefix and channel number
    if any(cellfun(@(x)ismember('-',x),channels))
        labels = regexp(channels,'(?<prefix>[^\d]+\d)-(?<num>\d+)','names');
    elseif ~any(cellfun(@(x)ismember('-',x),channels))
        labels = regexp(channels,'(?<prefix>[^\d]+)(?<num>\d+)','names');
    end
    impedance(cellfun(@isempty,labels)) = [];
    labels = cat(2,labels{:});
    chanNum = cellfun(@str2double,{labels.num});
    idx = chanNum >= 1 & chanNum <= 96;
    
    % check if impedances are valid
    validChans = idx(:) & impedance <= threshold;
    warnChans = idx(:) & impedance >= flagThres & impedance <= threshold;
    
    if all(strcmpi('chan',{labels.prefix}))
        [~,loc1] = ismember(map.ChanNum,chanNum(validChans));
        [~,loc2] = ismember(map.ChanNum,chanNum(warnChans));
    else
        [~,loc1] = ismember(map.ElecNum,chanNum(validChans));
        [~,loc2] = ismember(map.ElecNum,chanNum(warnChans));
    end
    invalidElecs = map.ElecNum(loc1 == 0);
    idx = ismember(electrodes,invalidElecs);
    fid = fopen(fullfile(datapath{3},env.get('subject'),datestr(now,'yyyymmdd'),[idString,'-',datestr(now,'HHMMSS'),'_invalidElectrodes.txt']),'w');
    fprintf(fid,'Elec.\tChan.\r\n');
    fprintf(fid,'%d\t%d\r\n',electrodes(idx)',map.ChanNum(ismember(map.ElecNum,electrodes(idx))));
    electrodes(idx) = []; % clear out the invalid electrodes
    warnElecs = map.ElecNum(loc2 > 0);
    impFlag(ismember(electrodes,warnElecs)) = true;
    %display(['Invalid electrodes: ',num2str(invalidElecs(:)')]);
    fclose(fid);
else
    warning('No impedance file found for %s arrays',arrayName);
    idx = false(size(electrodes));
end

end % END of CHECKVALIDELECTRODES function