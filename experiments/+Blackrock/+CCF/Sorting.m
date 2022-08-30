function srt = Sorting(root)

stat_node = getElementsByTagName(root,'Statistics');
if stat_node.getLength>0
    srt.Statistics = toStruct(Blackrock.CCF.cbPKT_SS_STATISTICS(stat_node.item(0)));
end

nb_items = getElementsByTagName(root,'NoiseBoundary_item');
numNB = nb_items.getLength;
nb = toStruct(Blackrock.CCF.cbPKT_SS_NOISE_BOUNDARY(nb_items.item(0)));
nb(numNB) = nb;
for nn=0:numNB-1
    nb(nn+1) = toStruct(Blackrock.CCF.cbPKT_SS_NOISE_BOUNDARY(nb_items.item(nn)));
end
srt.NoiseBoundary = nb;

srt.Detect = Blackrock.CCF.processGroupNode(root,'Detect',{'chid','type','dlen','Threshold','Multiplier'});
srt.ArtifactReject = Blackrock.CCF.processGroupNode(root,'ArtifactReject',{'chid','type','dlen','MaxSimulChans','RefractoryCount'});

stat_node = getElementsByTagName(root,'Status');
if stat_node.getLength>0
    srt.Sorting = toStruct(Blackrock.CCF.cbPKT_SS_STATUS(stat_node.item(0)));
end