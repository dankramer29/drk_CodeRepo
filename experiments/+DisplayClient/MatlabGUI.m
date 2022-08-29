classdef MatlabGUI < handle & DisplayClient.Interface & util.Structable
    
    properties
        hFigure
        handles
    end % END properties
    
    methods
        function this = MatlabGUI
            this.hFigure = figure;
            this.handles.ax = axes('Position',[0 0 1 1],'XTick',[],'YTick',[],'Box','off','ylim',[-1 1],'xlim',[-1 1]);
        end % END function MatlabGUI
        
        function h = getResource(this,shape)
            switch shape
                case Experiment.Type.Shape.LINE
                    h(1) = line;
                    h(2) = line;
            end
        end
        
        function delete(this)
            if ~isempty(this.hFigure) && ishandle(this.hFigure)
                close(this.hFigure);
            end
        end % END function delete
    end % END methods
    
    methods(Static)
        
        function createLineTarget(this,obj)
        end
        
        function updateRotatingLineTarget(this,obj)
            pos = obj.position + deg2rad(90);
            if pos>deg2rad(90)
                pos = deg2rad(180)-pos;
                xdata1 = [cos(pos) 0]; % hand
                ydata1 = [-sin(pos) 0];
                xdata2 = [0 -cos(pos)]; % thumb
                ydata2 = [0 sin(pos)];
            elseif pos==deg2rad(90)
                xdata1 = [0 0]; % hand
                ydata1 = [-1 0];
                xdata2 = [0 0]; % thumb
                ydata2 = [0 1];
            else
                xdata1 = [-cos(pos) 0]; % hand
                ydata1 = [-sin(pos) 0];
                xdata2 = [0 cos(pos)]; % thumb
                ydata2 = [0 sin(pos)];
            end
            set(obj.resource(1),...
                'XData',xdata1,...
                'YData',ydata1,...
                'LineWidth',obj.scale,...
                'Color',[0 0 0]);
            set(obj.resource(2),...
                'XData',xdata2,...
                'YData',ydata2,...
                'LineWidth',obj.scale,...
                'Color',[1 0 0]);
            if all(obj.color==0)
                set(obj.resource,'Visible','off');
            else
                set(obj.resource,'Visible','on');
            end
        end % END function updateRotatingLineTarget
        
        function updateVerticalTranslatingLineTarget(this,obj)
            pos = obj.position;
            xdata = [-1 1];
            ydata = [-pos -pos];
            set(obj.resource,...
                'XData',xdata,...
                'YData',ydata,...
                'LineWidth',obj.scale,...
                'Color',[1 0 0]);
            if all(obj.color==0)
                set(obj.resource,'Visible','off');
            else
                set(obj.resource,'Visible','on');
            end
        end % END function updateVerticalTranslatingLineTarget
    end % END methods(Static)
    
end % END classdef MatlabGUI