function st = processGroupNode(root,group_name,leaf_names)
st = [];
group_node = getElementsByTagName(root,group_name);
if group_node.getLength>0
    for nn=1:length(leaf_names)
        g_node = getElementsByTagName(group_node.item(0),leaf_names{nn});
        if g_node.getLength>0
            st.(leaf_names{nn}) = Blackrock.CCF.processLeafNode(g_node.item(0));
        end
    end
end