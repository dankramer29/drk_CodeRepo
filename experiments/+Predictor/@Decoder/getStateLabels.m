function stateLabel=getStateLabels(obj)

indx=1;
for i=1:length(obj); 
    stateLabel{indx}=obj.dofLabels{i};
    stateLabel{indx+1}=[d obj.dofLabels{i}];
    indx=indx+2;
end
    
