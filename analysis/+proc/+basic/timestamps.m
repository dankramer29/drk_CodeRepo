function ts = timestamps(allts,allch,allun,featdef)
% TIMESTAMPS Extract timestamps
%
%    TIMESTAMPS = TS(ALLTS,ALLCH,ALLUN,FEATDEF)
%    For each unique feature defined in FEATDEF, extract the timestamps
%    from ALLTS into a cell of the cell array TIMESTAMPS.

% loop over procwins
num_features = size(featdef,1);

% loop over features
ts = cell(1,num_features);
for ff=1:num_features
    
    % identify dataset channel, unit for this feature
    ch = featdef.dataset_channel(ff);
    un = featdef.unit(ff);
    
    % pull out matching timestamps
    ts{ff} = allts( allch==ch & allun==un );
end