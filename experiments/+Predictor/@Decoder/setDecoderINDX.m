function setDecoderINDX(obj,INDX)

if isempty(obj.decoders)
    obj.msgName('No trained decoders.  Cannot set decdoder index')
    return
end


oldDecoderINDX=obj.currentDecoderINDX;

if nargin==1;
    obj.currentDecoderINDX=length(obj.decoders);
else
    if INDX<=length(obj.decoders);
        obj.currentDecoderINDX=INDX;
    else
        obj.currentDecoderINDX=length(obj.decoders);
    end
end



if obj.currentDecoderINDX==oldDecoderINDX
    obj.msgName(sprintf('Continuing to use Decoder "%s" (INDX %d/%d)', obj.decoders(obj.currentDecoderINDX).name  ,obj.currentDecoderINDX,length(obj.decoders)),[1 1])
else
    obj.msgName(sprintf('Updating to Decoder "%s" (INDX %d/%d)', obj.decoders(obj.currentDecoderINDX).name  ,obj.currentDecoderINDX,length(obj.decoders)),[1 1])
end

if obj.guiParams.enableGUI
    handles = guihandles(obj.guiProps.handle);
    set(handles.editDecoderCurrent,'String',obj.decoders(obj.currentDecoderINDX).name);
    assistStr = sprintf('%1.2f ',obj.runtimeParams.assistLevel);
    set(handles.editAssist,'String',sprintf('[%s]',assistStr(1:end-1)));
end

% if obj.decoders(obj.currentDecoderINDX).nFeatures~=obj.decoders(obj.oldDecoderINDX).nFeatures
% warning('Number of features mismatch - resetting local buffers.')
% 
% end