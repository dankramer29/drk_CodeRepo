classdef cbPKT_NTRODEINFO < util.Structable
    
    properties
        label
        
        chid
        type
        dlen
        ntrode
        site
        featurespace
        
        ellipses
        chan
        
    end % END properties
    
    methods
        function this = cbPKT_NTRODEINFO(root)
            lbl = char(root.getAttributes.getNamedItem('label').getValue);
            this.label = lbl;
            
            basic_names = {'chid','type','dlen','ntrode','site','featurespace'};
            for nn = 1:length(basic_names)
                nodeList = getElementsByTagName(root,basic_names{nn});
                if nodeList.getLength > 0
                    this.(basic_names{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            ellipses_node = getElementsByTagName(root,'ellipses');
            if ellipses_node.getLength>0
                ellipse_nodes = getElementsByTagName(ellipses_node.item(0),'ellipse');
                numEllipse = ellipse_nodes.getLength;
                this.ellipses = cell(1,numEllipse);
                for ee = 0:numEllipse-1
                    item_nodes = getElementsByTagName(ellipse_nodes.item(ee),'ellipse_item');
                    for nn=0:item_nodes.getLength-1
                        if isempty(this.ellipses{ee+1})
                            this.ellipses{ee+1} = toStruct(Blackrock.CCF.cbMANUALUNITMAPPING(item_nodes.item(nn)));
                        else
                            this.ellipses{ee+1}(nn+1) = toStruct(Blackrock.CCF.cbMANUALUNITMAPPING(item_nodes.item(nn)));
                        end
                    end
                end
            end
        end % END function cbPKT_NTRODEINFO
    end % END methods
    
end % END classdef cbPKT_NTRODEINFO