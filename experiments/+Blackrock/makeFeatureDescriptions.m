function FeatureList=makeFeatureDescriptions(ElectrodeInfo, Type, Pedestal,unit)

% this function turns the cell representation of FeatureList in the stream
% framework into a struct form (which I prefer to work with.)


Pedestal_name={'A','B'};

if strcmp(Type,'continuous')
    
    FeatureList.type='continuous';
    
    FeatureList.unit=-1;
    FeatureList.bandpass=[];
    
    
    FeatureList.ElectrodeID=ElectrodeInfo.ElectrodeID;
    FeatureList.Pedestal=Pedestal;
    
    PedName=Pedestal_name{Pedestal};
    FeatureList.name=sprintf('c%d%s%s', FeatureList.ElectrodeID,PedName ,sprintf('_%d',round(FeatureList.bandpass)));
    %     FeatureList.name=
else
    
    FeatureList.type='event';
    FeatureList.ElectrodeID=ElectrodeInfo.ElectrodeID;
    FeatureList.unit=unit;
    FeatureList.bandpass=-1;
    
    FeatureList.ElectrodeID=ElectrodeInfo.ElectrodeID;
    FeatureList.Pedestal=Pedestal;
    
    PedName=Pedestal_name{Pedestal};
    
    if FeatureList.unit~=0; 
        UnitName=sprintf('_%d',FeatureList.unit); 
    else, UnitName=[]; end
    FeatureList.name=sprintf('e%d%s%s', FeatureList.ElectrodeID,PedName,UnitName);
end
