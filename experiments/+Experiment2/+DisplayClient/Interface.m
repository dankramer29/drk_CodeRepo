classdef Interface < handle
    
    methods(Abstract)
        displayMessage(this,msg,x,y,rgb);
        normPos2Client(this,pos);
        normScale2Client(this,scale);
        refresh(this);
        updateObject(this,object);
        drawOval(this,pos,diam,rgb);
    end % END methods
    
end % END classdef Interface