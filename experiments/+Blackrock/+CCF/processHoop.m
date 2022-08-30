function [tm,mn,mx] = processHoop(node)
item_nodes = getElementsByTagName(node,'hoop_item');

tm = [];
mn = [];
mx = [];
for nn = 0:item_nodes.getLength-1
    v_node = getElementsByTagName(item_nodes.item(nn),'valid');
    if v_node.getLength>0
        v = Blackrock.CCF.processLeafNode(v_node.item(0));
        if v>0
            tm_node = getElementsByTagName(item_nodes.item(nn),'time');
            mn_node = getElementsByTagName(item_nodes.item(nn),'min');
            mx_node = getElementsByTagName(item_nodes.item(nn),'max');
            tm = [tm Blackrock.CCF.processLeafNode(tm_node.item(0))];
            mn = [mn Blackrock.CCF.processLeafNode(mn_node.item(0))];
            mx = [mx Blackrock.CCF.processLeafNode(mx_node.item(0))];
        end
    end
end