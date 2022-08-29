classdef cbPKT_SS_STATUS < util.Structable
    
    properties
        chid
        type
        dlen
        cntlUnitStats
        cntlNumUnits
    end % END properties
    
    methods
        function this = cbPKT_SS_STATUS(root)
            basic_nodes = {'chid','type','dlen'};
            for nn = 1:length(basic_nodes)
                nodeList = getElementsByTagName(root,basic_nodes{nn});
                if nodeList.getLength > 0
                    this.(basic_nodes{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            this.cntlUnitStats = Blackrock.CCF.processGroupNode(root,'cntlUnitStats',{'mode','TimeOutMinutes','ElapsedMinutes'});
            this.cntlNumUnits = Blackrock.CCF.processGroupNode(root,'cntlNumUnits',{'mode','TimeOutMinutes','ElapsedMinutes'});
        end % END function cbPKT_SS_STATUS
    end % END methods
    
end % END classdef cbPKT_SS_STATUS