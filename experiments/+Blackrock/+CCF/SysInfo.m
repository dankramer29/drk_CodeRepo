function si = SysInfo(root)

basic_names = {'chid','type','dlen','sysfreq','resetque','runlevel','runflags'};
for nn = 1:length(basic_names)
    nodeList = getElementsByTagName(root,basic_names{nn});
    if nodeList.getLength > 0
        si.(basic_names{nn}) = Blackrock.CCF.processLeafNode(nodeList.item(0));
    end
end

si.spike = Blackrock.CCF.processGroupNode(root,'spike',{'length','pretrigger'});