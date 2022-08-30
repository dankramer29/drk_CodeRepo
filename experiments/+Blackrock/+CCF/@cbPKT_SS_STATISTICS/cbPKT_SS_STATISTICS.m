classdef cbPKT_SS_STATISTICS < util.Structable
    
    properties
        chid
        type
        dlen
        UpdateSpikes
        Autoalg
        mode
        Cluster
        WaveBasisSize
        WaveSampleSize
    end % END properties
    
    methods
        function this = cbPKT_SS_STATISTICS(root)
            basic_nodes = {'chid','type','dlen','UpdateSpikes','Autoalg','mode','WaveBasisSize','WaveSampleSize'};
            for nn = 1:length(basic_nodes)
                nodeList = getElementsByTagName(root,basic_nodes{nn});
                if nodeList.getLength > 0
                    this.(basic_nodes{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
                end
            end
            
            this.Cluster = Blackrock.CCF.processGroupNode(root,'Cluster',{...
                'MinClusterPairSpreadFactor',...
                'MaxSubclusterSpreadfactor',...
                'MinClusterHistCorrMajMeasure',...
                'MaxClusterPairHistCorrMajMeasure',...
                'ClusterHistValleyPercentage',...
                'ClusterHistClosePeakPercentage',...
                'ClusterHistMinPeakPercentage'});
            
        end % END function cbPKT_SS_STATISTICS
    end % END methods
    
end % END classdef cbPKT_SS_STATISTICS