function emptyBuffers(obj)

% empty all the buffers.
fN=fieldnames(obj.DataBuffers);
fN=fN(~strncmp(fN,'Recent',6));

for i=1:length(fN)
    obj.DataBuffers.(fN{i}).empty;
end

