function [channels, channel_key] = get_channels_for_location(GridMapObj, LocationNames, HemisphereNames)
    GridInfoTable = GridMapObj.GridInfo;
    channels = [];
    channel_key = [];
    for l = 1:length(LocationNames)
        location_index = strcmp([GridInfoTable.Location], LocationNames{l});
        loc_name = LocationNames{l};
        for h = 1:length(HemisphereNames)
            hemisphere_index = strcmp([GridInfoTable.Hemisphere], HemisphereNames{h});
            hem_name = HemisphereNames{h};
            index_intersect = location_index & hemisphere_index;
            all_channels = [GridInfoTable.Channels];
            h_chan = cell2mat(all_channels(index_intersect));
%             start = length(channels)+1;
%             stop = length(channels) + length(h_chan);
%             channel_key{start:stop, 1} = (length(channels)+1:length(channels)+length(h_chan))';
            full_name = sprintf('%s %s', hem_name, loc_name);
            chan_loc_names = string(repmat(full_name, [length(h_chan), 1]));
%             channel_key{start:stop, 2} = repmat(full_name, [length(h_chan), 1]);
            channel_key = [channel_key; chan_loc_names];
            channels = [channels; h_chan];
        end
    end
end %end func get_channels_for_location