classdef cbPKT_SS_NOISE_BOUNDARY < util.Structable
    
    properties
        chid
        type
        dlen
        chan
        center
        axes
    end % END properties
    
    methods
        function this = cbPKT_SS_NOISE_BOUNDARY(root)
            basic_nodes = {'chid','type','dlen','chan'};
            for nn = 1:length(basic_nodes)
                nodeList = getElementsByTagName(root,basic_nodes{nn});
                if nodeList.getLength > 0
                    this.(basic_nodes{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            center_items = getElementsByTagName(root,'center_item');
            for nn=0:center_items.getLength-1
                this.center(nn+1) = Blackrock.CCF.processLeafNode(center_items.item(nn));
            end
            
            axises = getElementsByTagName(root,'axis');
            for nn=0:axises.getLength-1
                axis_items = getElementsByTagName(axises.item(0),'axis_item');
                for mm=0:axis_items.getLength-1
                    this.axes(:,mm+1) = Blackrock.CCF.processLeafNode(axis_items.item(mm));
                end
            end
            
        end % END function cbPKT_SS_NOISE_BOUNDARY
    end % END methods
    
end % END classdef cbPKT_SS_NOISE_BOUNDARY