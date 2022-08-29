classdef cbFILTDESC < util.Structable
    
    properties
        label
        hpfreq
        hporder
        hptype
        lpfreq
        lporder
        lptype
    end % END properties
    
    methods
        function this = cbFILTDESC(root)
            basic_nodes = properties(this);
            for nn = 1:length(basic_nodes)
                nodeList = getElementsByTagName(root,basic_nodes{nn});
                if nodeList.getLength > 0
                    this.(basic_nodes{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
        end % END function cbFILTDESC
    end % END methods
    
end % END classdef cbFILTDESC