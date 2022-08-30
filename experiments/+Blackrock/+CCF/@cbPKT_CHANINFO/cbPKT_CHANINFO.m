classdef cbPKT_CHANINFO < util.Structable
    
    properties
        label
        
        chid
        type
        dlen
        chan
        proc
        bank
        term
        userflags
        eopchar
        refelecchan
        
        scale
        filterdesc
        position
        options
        monitor
        lnc
        sample
        
        spike
        unitmapping
        
    end % END properties
    
    methods
        function this = cbPKT_CHANINFO(root)
            lbl = char(root.getAttributes.getNamedItem('label').getValue);
            this.label = lbl;
            
            basic_names = {'chid','type','dlen','chan','proc','bank','term','userflags','eopchar','refelecchan'};
            for nn = 1:length(basic_names)
                nodeList = getElementsByTagName(root,basic_names{nn});
                if nodeList.getLength > 0
                    this.(basic_names{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            scale_names = {'physcalin','physcalout','scalin','scalout'};
            for nn = 1:length(scale_names)
                nodeList = getElementsByTagName(root,scale_names{nn});
                if nodeList.getLength > 0
                    this.scale.(scale_names{nn}) = toStruct(Blackrock.CCF.cbSCALING(nodeList.item(0)));
                end
            end
            
            filterdesc_names = {'phyfiltin','phyfiltout'};
            for nn = 1:length(filterdesc_names)
                nodeList = getElementsByTagName(root,filterdesc_names{nn});
                if nodeList.getLength > 0
                    this.filterdesc.(filterdesc_names{nn}) = toStruct(Blackrock.CCF.cbFILTDESC(nodeList.item(0)));
                end
            end
            
            position_items = getElementsByTagName(root,'position_item');
            for nn=0:position_items.getLength-1
                this.position(nn+1) = Blackrock.CCF.processLeafNode(position_items.item(nn));
            end
            
            spike_node = getElementsByTagName(root,'spike');
            if spike_node.getLength>0
                this.spike = toStruct(Blackrock.CCF.spike(spike_node.item(0)));
            end
            
            unitmapping_items = getElementsByTagName(root,'unitmapping_item');
            for nn=0:unitmapping_items.getLength-1
                if isempty(this.unitmapping)
                    this.unitmapping = toStruct(Blackrock.CCF.cbMANUALUNITMAPPING(unitmapping_items.item(nn)));
                else
                    this.unitmapping(nn) = toStruct(Blackrock.CCF.cbMANUALUNITMAPPING(unitmapping_items.item(nn)));
                end
            end
            
            this.options = Blackrock.CCF.processGroupNode(root,'options',{'doutopts','dinpopts','aoutopts','ainpopts','spkopts'});
            this.monitor = Blackrock.CCF.processGroupNode(root,'monitor',{'lowsamples','highsamples','offset'});
            this.lnc = Blackrock.CCF.processGroupNode(root,'lnc',{'rate','dispmax'});
            this.sample = Blackrock.CCF.processGroupNode(root,'sample',{'filter','group','dispmin','dispmax'});
        end % END function cbPKT_CHANINFO
    end % END methods
    
end % END classdef cbPKT_CHANINFO