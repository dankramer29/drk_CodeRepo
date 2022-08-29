classdef cbSCALING < util.Structable
    
    properties
        digmin
        digmax
        anamin
        anamax
        anagain
        anaunit
    end % END properties
    
    methods
        function this = cbSCALING(root)
            basic_nodes = properties(this);
            for nn = 1:length(basic_nodes)
                nodeList = getElementsByTagName(root,basic_nodes{nn});
                if nodeList.getLength > 0
                    this.(basic_nodes{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
        end % END function cbSCALING
    end % END methods
    
end % END classdef cbSCALING