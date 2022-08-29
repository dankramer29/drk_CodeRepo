classdef spike < util.Structable
    
    properties
        filter
        dispmax
        group
        
        threshold
        amplitudereject
        hoops
    end % END properties
    
    methods
        
        function this = spike(root)
            basic_names = {'filter','dispmax','group'};
            for nn = 1:length(basic_names)
                nodeList = getElementsByTagName(root,basic_names{nn});
                if nodeList.getLength > 0
                    this.(basic_names{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            this.threshold = Blackrock.CCF.processGroupNode(root,'threshold',{'level','limit'});
            this.amplitudereject = Blackrock.CCF.processGroupNode(root,'amplitudereject',{'positive','negative'});
            
            hoops_node = getElementsByTagName(root,'hoops');
            if hoops_node.getLength>0
                hoop_nodes = getElementsByTagName(hoops_node.item(0),'hoop');
                for nn=0:hoop_nodes.getLength-1 % loop over units
                    [tm,mn,mx] = Blackrock.CCF.processHoop(hoop_nodes.item(nn));
                    this.hoops{nn+1}.time = tm;
                    this.hoops{nn+1}.min = mn;
                    this.hoops{nn+1}.max = mx;
                end
            end
        end % END function spike
        
    end % END methods
    
end % END classdef spike