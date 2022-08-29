function lnc = LNC(root)

basic_names = {'chid','type','dlen','frequency','GlobalMode'};
for nn = 1:length(basic_names)
    nodeList = getElementsByTagName(root,basic_names{nn});
    if nodeList.getLength > 0
        lnc.(basic_names{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
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
    lnc.RefChan = rc;
end