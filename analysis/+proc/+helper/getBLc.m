function blc = getBLc(task,params,debug)
Parameters.validate(params,mfilename('fullpath'));

% initialize neural data sources
blc = cell(1,task.numNSPs);
for kk=1:task.numNSPs
    
    % get a list of available neural data types
    [type,~,fs] = task.availableNeuralDataTypes(task.nspNames{kk});
    switch lower(params.lfp.type)
        case 'blc'
            assert(ismember('blc',type),'Could not find BLc in available data types "%s"',strjoin(type,', '));
            if params.lfp.fs>=1000
                fsstr = sprintf('fs%dk',round(params.lfp.fs/1e3));
            else
                fsstr = sprintf('fs%d',params.lfp.fs);
            end
            assert(ismember(fsstr,fs),'Could not find requested sampling rate "%s" in list of available sampling rates "%s"',fsstr,strjoin(fs,', '));
        otherwise
            error('Could not find requested LFP type "%s"',params.lfp.type);
    end
    
    % load in neural data
    blc(kk) = task.getNeuralDataObject(task.nspNames{kk},fsstr);
end