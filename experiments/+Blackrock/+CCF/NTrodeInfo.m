function nt = NTrodeInfo(root)

NTrodeInfo_items = getElementsByTagName(root,'NTrodeInfo_item');
numNTrodes = NTrodeInfo_items.getLength;
nt = toStruct(Blackrock.CCF.cbPKT_NTRODEINFO(NTrodeInfo_items.item(0)));
nt(numNTrodes) = nt;
for nn=0:numNTrodes-1
    nt(nn+1) = toStruct(Blackrock.CCF.cbPKT_NTRODEINFO(NTrodeInfo_items.item(nn)));
end