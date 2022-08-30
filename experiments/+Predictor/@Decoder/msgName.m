function msgName(obj,msg,newLine,prefix)
% newLine containes number of newlines to print before/after the message
% for example, newLine = [0 1] means no newline before, one newline after
% newLine = [1 2] means one newline before, two after
% empty defaults to one newline printed after

if ~isempty(obj.hFramework)
    comment(obj.hFramework,'DECODER',msg);
else
    if nargin==3
        if length(newLine)>1
            for kk=1:newLine(1)
                fprintf('\n');
            end
        end
    end
    
    if nargin<4 || (nargin==4 && prefix)
        fprintf('[DECODER] ')
    end
    
    if nargin>=2
        fprintf('%s',msg)
    end
    
    if nargin<3
        fprintf('\n');
    else
        if length(newLine)>1
            for kk=1:newLine(2)
                fprintf('\n')
            end
        else
            for kk=1:newLine(1)
                fprintf('\n');
            end
        end
    end
end