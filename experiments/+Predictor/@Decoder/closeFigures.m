function closeFigures(obj)

%%
fN=fieldnames(obj.figureHandles);

for i=1:length(fN)
    tmp=obj.figureHandles.(fN{i});
    if ishandle(tmp)
       close(tmp) 
    end
end
