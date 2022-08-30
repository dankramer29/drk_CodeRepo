function nv = getNEV(task,params)
Parameters.validate(params,mfilename('fullpath'));

% initialize neural data sources
nv = cell(1,task.numNSPs);
for kk=1:task.numNSPs
    
    % get a list of available neural data types
    list = task.availableNeuralDataTypes(task.nspNames{kk});
    switch params.spk.type
        case 'any'
            if any(strcmpi(list,'sorted'))
                which = 'sorted';
            elseif any(strcmpi(list,'npmk'))
                which = 'npmk';
            elseif any(strcmpi(list,'nev'))
                which = 'nev';
            else
                error('No applicable neural data files available');
            end
        otherwise
            which = params.spk.type;
    end
    list = util.ascell(list);
    assert(ismember(which,list),'Could not find Spike type ''%s'' (available files include %s)',which,strjoin(list,', '));
    
    % load in neural data
    nv(kk) = task.getNeuralDataObject(task.nspNames{kk},which);

end