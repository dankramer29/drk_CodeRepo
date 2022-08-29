function [ data ] = remove_trials( data, trials )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


dim=length(size(data));
if dim==3
    
    for ii=1:length(trials)
        data(:,:,trials(ii))=[];
    end
elseif dim==2
    for ii=1:length(trials)
        data(trials(ii),:)=[];
    end
    
end

end

