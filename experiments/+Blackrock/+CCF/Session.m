function ss = Session(root)

% author and date
a_node = getElementsByTagName(root,'Author');
d_node = getElementsByTagName(root,'Date');
a_data = char(a_node.item(0).getFirstChild.getData);
d_data = char(d_node.item(0).getFirstChild.getData);
ss.Author = a_data;
ss.Date = d_data;

% version data
ss.Version = [];
group_node = getElementsByTagName(root,'Version');
if group_node.getLength>0
    
    p_node = getElementsByTagName(group_node.item(0),'Protocol');
    c_node = getElementsByTagName(group_node.item(0),'Cerebus');
    n_node = getElementsByTagName(group_node.item(0),'NSP');
    i_node = getElementsByTagName(group_node.item(0),'ID');
    o_node = getElementsByTagName(group_node.item(0),'Original');
    
    p_data = char(p_node.item(0).getFirstChild.getData);
    c_data = char(c_node.item(0).getFirstChild.getData);
    n_data = char(n_node.item(0).getFirstChild.getData);
    i_data = char(i_node.item(0).getFirstChild.getData);
    o_data = char(o_node.item(0).getFirstChild.getData);
    
    ss.Version.Protocol = str2double(p_data);
    ss.Version.Cerebus = c_data;
    ss.Version.NSP = n_data;
    ss.Version.ID = i_data;
    ss.Version.Original = o_data;
    
end