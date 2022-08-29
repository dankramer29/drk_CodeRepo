function ns = getNSx(task,params)
Parameters.validate(params,mfilename('fullpath'));

% initialize neural data sources
ns = cell(1,task.numArrays);
for kk=1:task.numArrays
    
    % get a list of available neural data types
    list = task.availableNeuralDataTypes(task.arrayNames{kk});
    switch params.lfp.type
        case 'any'
            if any(strcmpi(list,'ns3'))
                which = 'ns3';
            elseif any(strcmpi(list,'ns6'))
                which = 'ns6';
            else
                error('No applicable neural data files available');
            end
        otherwise
            which = params.lfp.type;
    end
    assert(ismember(which,list),'Could not find LFP type ''%s'' (available files include %s)',which,strjoin(list,', '));
    
    % load in neural data
    ns(kk) = task.getNeuralDataObject(task.arrayNames{kk},which);
end