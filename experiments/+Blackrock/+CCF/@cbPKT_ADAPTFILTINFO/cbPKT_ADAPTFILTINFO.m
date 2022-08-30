classdef cbPKT_ADAPTFILTINFO < util.Structable
    
    properties
        chid
        type
        dlen
        chan
        mode
        LearningRate
        RefChan
    end % END properties
    
    methods
        function this = cbPKT_ADAPTFILTINFO(root)
            basic_nodes = {'chid','type','dlen','chan','mode','LearningRate'};
            for nn = 1:length(basic_nodes)
                nodeList = getElementsByTagName(root,basic_nodes{nn});
                if nodeList.getLength > 0
                    this.(basic_nodes{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            rc_node = getElementsByTagName(root,'RefChan');
            if rc_node.getLength>0
                RefChan_items = getElementsByTagName(rc_node.item(0),'RefChan_item');
                numItems = RefChan_items.getLength;
                rc = Blackrock.CCF.processLeafNode(RefChan_items.item(0));
                rc(numItems) = rc;
                for nn=0:numItems-1
                    rc(nn+1) = Blackrock.CCF.processLeafNode(RefChan_items.item(nn));
                end
                this.RefChan = rc;
            end
        end % END function cbPKT_ADAPTFILTINFO
    end % END methods
    
end % END classdef cbPKT_ADAPTFILTINFO