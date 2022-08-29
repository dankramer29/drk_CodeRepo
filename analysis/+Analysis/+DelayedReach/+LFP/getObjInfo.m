function [fullTaskName, nsGrids, nsType] = getObjInfo
    fullTaskName = getFileInfo;
    [nsGrids, nsType] = getNSInfo;

end %end function getObjInfo



function [fullTaskName] = getFileInfo
    [taskFileName, taskPathName] = uigetfile('C:\Users\Mike\Documents\Data\*.mat', 'Select Task Data File');
    
    
    if isequal(taskFileName,0)
       disp('User selected Cancel')
       taskFileName = 'none';
       taskPathName = 'none';
    else
       disp(['User selected ', fullfile(taskPathName, taskFileName)])
    end
    
    fullTaskName = fullfile(taskPathName, taskFileName);
    
end %end function getFileInfo
    
    
    
function [nsGrids, nsType] = getNSInfo
        promptG = 'Specify a single char or cell array of chars indicating array names (ex: allgrids): ';
        nsGrids = input(promptG, 's');
        promptT = 'Specify neural data type (ex: ns6): ';
        nsType = input(promptT, 's');
end %end function getNSInfo


