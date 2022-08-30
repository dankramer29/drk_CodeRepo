function val = processLeafNode(node)

val = [];
nodeType = char(node.getAttributes.getNamedItem('Type').getValue);
if node.hasChildNodes
    nodeData = char(node.getFirstChild.getData);
    
    if ~isempty(nodeData)
        switch nodeType
            case 'cstring'
                val = nodeData;
            otherwise
                val = cast(str2double(nodeData),nodeType);
        end
    end
end
