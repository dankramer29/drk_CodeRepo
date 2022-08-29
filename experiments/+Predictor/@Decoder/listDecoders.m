function varargout = listDecoders(obj)

if nargout==0
    
    if isempty(obj.decoders)
        obj.msgName('No trained decoders')
    end
    
    for k=1:length(obj.decoders)
        obj.msgName(sprintf('%d. %s',k,obj.decoders(k).name));
    end
    
else
    
    out = cell(1,length(obj.decoders));
    for k=1:length(obj.decoders)
        out{k} = obj.decoders(k).name;
    end
    varargout{1} = out;
    
end