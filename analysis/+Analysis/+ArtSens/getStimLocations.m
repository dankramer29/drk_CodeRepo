function [unique_locations,elec_counts] = getStimLocations(subject)


% %Inputs:
%     subject=        name of subject, like this 'LName, FName', see in the folder research for the names
% for saving the data
dirpath = fullfile(env.get('results'),'ECoG',mfilename);
if ~isdir(dirpath); mkdir(dirpath); end

if strcmpi(subject,'MEA')
    filename = fullfile(env.get('results'),'ECoG','Raw',subject,'Pittremake_lateralarray1.xlsx');
    [~,~,lat_raw] = xlsread(filename);
    filename = fullfile(env.get('results'),'ECoG','Raw',subject,'Pittremake_medialarray1.xlsx');
    [~,~,med_raw] = xlsread(filename);
    
    elec_lat = cell2mat(lat_raw(2:end,1));
    lat_locations = lat_raw(2:end,2);
    
    elec_med = cell2mat(med_raw(2:end,1));
    med_locations = med_raw(2:end,2);
    
    unique_locations = unique([lat_locations;med_locations],'stable');
    % Loop to check when a new "finger" is added
    keep = checkUniqueLocs(unique_locations);
    unique_locations(keep);
    
    lat_tmp = cellfun(@(x)strcmpi(x,lat_locations),unique_locations,'UniformOutput',false);
    med_tmp = cellfun(@(x)strcmpi(x,med_locations),unique_locations,'UniformOutput',false);
    elecs = cellfun(@(x,y)unique([elec_lat(x);elec_med(y)]),lat_tmp,med_tmp,'UniformOutput',false);
    elec_counts = cellfun(@(x)size(x,1),elecs);
    
    % save new excel file
    filename = fullfile(dirpath,[lower(subject),'_locations']);
    xlswrite(filename,[{'Locations','NumElecs','Electrodes'};unique_locations,num2cell(elec_counts),cellfun(@(x)Utilities.vec2str(x),elecs,'UniformOutput',false)]);
    
    gridlocs = {}; grid_counts = []; c = 1;
    for jj = 1:length(unique_locations)
        str = strsplit(unique_locations{jj},';');
        for ii = 1:length(str)
            if isempty(gridlocs) || ~ismember(str{ii},gridlocs)
                gridlocs{c} = str{ii};
                grid_counts(c) = elec_counts(jj);
                c = c + 1;
            else
                idx = find(strcmpi(str{ii},gridlocs));
                grid_counts(idx) = grid_counts(idx) + elec_counts(jj);
            end
        end
    end
    
    filename = fullfile(dirpath,[lower(subject),'_fullLocations']);
    xlswrite(filename,[{'Grid_Locations','NumElecs'};gridlocs(:),num2cell(grid_counts(:))]);
    
else
    % filename to load
    filename = fullfile(env.get('results'),'ECoG','Raw',subject,'mapping.xlsx');
    
    [~,~,raw] = xlsread(filename);
    
    % get sensation-type indices
    sen_idx = cellfun(@(x)strcmpi('sensation',x),raw(:,5));
    locations = raw(sen_idx,3);
    elecs1 = cell2mat(raw(sen_idx,1));
    elecs2 = cell2mat(raw(sen_idx,2));
    
    % get unique locations
    unique_locations = unique(locations,'stable');
    
    % Loop to check when a new "finger" is added
    keep = checkUniqueLocs(unique_locations);
    
    unique_locations = unique_locations(keep);
    
    tmp = cellfun(@(x)strcmpi(x,locations),unique_locations,'UniformOutput',false);
    elecs = cellfun(@(x)[unique(elecs1(x)) unique(elecs2(x))],tmp,'UniformOutput',false);
    elec_counts = cellfun(@(x)size(x,1),elecs);
    
    % save a new excel file
    filename = fullfile(dirpath,[lower(subject),'_locations']);
    xlswrite(filename,[{'Locations','NumElecs','Electrodes'};unique_locations,num2cell(elec_counts),cellfun(@(x)Utilities.vec2str(x),elecs,'UniformOutput',false)]);
    
    gridlocs = {}; grid_counts = []; c = 1;
    for jj = 1:length(unique_locations)
        str = strsplit(unique_locations{jj},';');
        for ii = 1:length(str)
            if isempty(gridlocs) || ~ismember(str{ii},gridlocs)
                gridlocs{c} = str{ii};
                grid_counts(c) = elec_counts(jj);
                c = c + 1;
            else
                idx = find(strcmpi(str{ii},gridlocs));
                grid_counts(idx) = grid_counts(idx) + elec_counts(jj);
            end
        end
    end
    
    filename = fullfile(dirpath,[lower(subject),'_fullLocations']);
    xlswrite(filename,[{'Grid_Locations','NumElecs'};gridlocs(:),num2cell(grid_counts(:))]);
end

    function keep = checkUniqueLocs(locs)
        keep = true(size(locs));
    for nn = 1:length(locs)
        str1 = strsplit(locs{nn},';');
        for kk = nn+1:length(locs)
            str2 = strsplit(locs{kk},';');
            if length(unique(cellfun(@(x)x(1:2),str1,'UniformOutput',false)))  == length(unique(cellfun(@(x)x(1:2),str2,'UniformOutput',false)))
                if all(ismember(unique(cellfun(@(x)x(1:2),str1,'UniformOutput',false)),unique(cellfun(@(x)x(1:2),str2,'UniformOutput',false)))) && (length(str1) == length(str2))
                    if length(str1) ~= 1
                        keep(nn) = false;
                    end
                end
            end
        end
    end
    end

end % END of GETSTIMLOCATIONS