function plotCursor(obj,x,idealX,goal,curZ)

if obj.decoderParams.nDOF==2;
    if ~isfield(obj.figureHandles,'CursorPlot') || ~ishandle(obj.figureHandles.CursorPlot) || ~ishandle(obj.figureHandles.CursorPlotHandles(1))
        obj.figureHandles.CursorPlot=figure; hold on
        obj.figureHandles.CursorAxes=gca;
        sP=obj.decoderParams.samplePeriod;
        obj.figureHandles.CursorPlotHandles(1) = plot(x(1),x(3),'ko','markersize',20);
        obj.figureHandles.CursorPlotHandles(2) = plot([x(1) x(1)+x(2)*sP],[x(3) x(3)+x(4)*sP],'k','linewidth',10);
        obj.figureHandles.CursorPlotHandles(3) = plot([idealX(1) idealX(1)+idealX(2)*sP],[idealX(3) idealX(3)+idealX(4)*sP],'r','linewidth',5);
        obj.figureHandles.CursorPlotHandles(4) = plot(goal(1),goal(2),'go','markersize',20);
        
        perc=.6;
        xlims=[obj.runtimeParams.outputMin(1) obj.runtimeParams.outputMax(1)];
        xlims(1)=xlims(1)+perc*xlims(1);xlims(2)=xlims(2)+perc*xlims(2);
        ylims=[obj.runtimeParams.outputMin(2) obj.runtimeParams.outputMax(2)];
        ylims(1)=ylims(1)+perc*ylims(1);ylims(2)=ylims(2)+perc*ylims(2);
%       axis image
        xlim( xlims)
        ylim( ylims)
        
           xlims=[obj.runtimeParams.outputMin(1) obj.runtimeParams.outputMax(1)];
        ylims=[obj.runtimeParams.outputMin(2) obj.runtimeParams.outputMax(2)];
        rectangle('Position',[xlims(1),ylims(1),xlims(2)-xlims(1),ylims(2)-ylims(1)],...
            'EdgeColor',[.5 .5 .5],'LineStyle','--');
        
    else
        sP=obj.decoderParams.samplePeriod;
        set(obj.figureHandles.CursorPlotHandles(1),'XData',x(1),'YData',x(3));
        set(obj.figureHandles.CursorPlotHandles(2),'XData',[x(1) x(1)+x(2)*sP*2],'YData',[x(3) x(3)+x(4)*sP*2]);
        set(obj.figureHandles.CursorPlotHandles(3),'XData',[idealX(1) idealX(1)+idealX(2)*sP*2],'YData',[idealX(3) idealX(3)+idealX(4)*sP*2]);
        set(obj.figureHandles.CursorPlotHandles(4),'XData',goal(1),'YData',goal(2));
    end
    
    if obj.runtimeParams.showPopResponse && obj.isTrained
        if ~isfield(obj.figureHandles,'ForceVectorHandles')  || length(obj.figureHandles.ForceVectorHandles)~=length(curZ) || ~ishandle(obj.figureHandles.ForceVectorHandles(1))
            [fX,fY]=getForceVectors(obj,curZ);
            obj.figureHandles.ForceVectorHandles= plot(obj.figureHandles.CursorAxes,[x(1)+fX],[x(3)+fY],'k');
        else
            %%
%             Note, addind color does not take much extra time
            [fX,fY]=getForceVectors(obj,curZ);
            fX=fX*obj.runtimeParams.outputGain(1);
            fY=fY*obj.runtimeParams.outputGain(2);
            
            for i=1:length(curZ);
                set(obj.figureHandles.ForceVectorHandles(i),'XData',[x(1) x(1)+fX(i)],'YData',[x(3),x(3)+fY(i)]);
            end
        end
    end
    
    
end

function [x1,x2]=getForceVectors(obj,curZ)

cDecINDX=obj.currentDecoderINDX;
Bc=obj.decoders(cDecINDX).decoderProps.Bcf(:,1:end-1);

if obj.runtimeParams.showPopResponse && obj.isTrained && nargin>=2;
    
%     if strcmp(obj.decoderParams.filterType,'direct')
% 
%     elseif strcmp(obj.decoderParams.filterType,'kalmanb')   && strcmp(obj.decoderParams.TuningFeatures,'dx')
%         Bc=obj.decoderProps.workingCopy.K;
%     elseif strcmp(obj.decoderParams.filterType,'kalmanb')   && strcmp(obj.decoderParams.TuningFeatures,'xdx')
%         Bc=obj.decoderProps.workingCopy.K(2:2:end,:);
%     end
    
    n_features=size(Bc,2);
    x1=[zeros(n_features,1) Bc(1,:)'.*curZ]';
    x2=[zeros(n_features,1) Bc(2,:)'.*curZ]';
    
    
else
    x1=[];
    x2=[];
end
