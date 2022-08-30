function ch = ChanInfo(root)

ChanInfo_items = root.getElementsByTagName('ChanInfo_item');
numChans = ChanInfo_items.getLength;
ch = toStruct(Blackrock.CCF.cbPKT_CHANINFO(ChanInfo_items.item(0)));
ch(numChans) = ch;
for nn=1:numChans-1
    ch(nn+1) = toStruct(Blackrock.CCF.cbPKT_CHANINFO(ChanInfo_items.item(nn)));
end