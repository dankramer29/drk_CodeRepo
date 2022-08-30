function [ sort_data ] = trial_sort( task, params, debug, varargin )
%trial_sort Generic data in function that returns data only from the trials
%you want in certain positions
%   sort_type       =the different ways to sort the data
%           1= L and R strict
%           2= L sided and R sided targets




%%
%check if sort_type was specified
[varargin, sort_type]=util.argkeyval('sort_type', varargin, 1);
util.argempty(varargin);

%
switch sort_type
    case 1 %strict L and R
        ID1 =  7;
        ID2 =  3;
    case 2 %L and R sided 
        ID1 = [8 7 6];
        ID2 = [2 3 4];
    case 3 %upward and downward
        ID1 = [8 1 2];
        ID2 = [4 5 6];
    case 4 %break them all up
        ID1=1;
        ID2=2;
        ID3=3;
        ID4=4;
        ID5=5;
        ID6=6;
        ID7=7;
        ID8=8;
end

numTrials = length(task.trialdata);


%idx to move up each of the cases
leftRow = 0;
rightRow = 0;
upperRow = 0;
lowerRow = 0;


for trialNumber = 1:numTrials
    %find the trial id
    targetLocation = task.trialdata(trialNumber).tr_prm.targetID;
    %make sure it was a successful trial
 %   if task.trialdata(trialNumber).ex_success == 1 %RIGHT NOW OUR TRIAL
 %   SUCCESS IS NOT TOTALLY WORKING, SO IGNORING THIS
        
        if any( targetLocation == ID1)
            leftRow = leftRow+1;
            sort_data.leftLocations(leftRow).trialNumber = trialNumber;
            sort_data.leftLocations(leftRow).targetLocation = targetLocation;
            sort_data.leftLocations(leftRow).startFrameID = task.trialdata(trialNumber).et_phase(5);
            sort_data.leftLocations(leftRow).stopFrameID = task.trialdata(trialNumber).et_trialCompleted;
        
        elseif any( targetLocation == ID2)
            rightRow = rightRow+1;
            sort_data.rightLocations(rightRow).trialNumber = trialNumber;
            sort_data.rightLocations(rightRow).targetLocation = targetLocation;
            sort_data.rightLocations(rightRow).startFrameID = task.trialdata(trialNumber).et_phase(5);
            sort_data.rightLocations(rightRow).stopFrameID = task.trialdata(trialNumber).et_trialCompleted;
        elseif any( targetLocation == ID1)
            
        
        end %region sorting for successful trials
    
    %else store don't know trial data and failure trial data separately
    
  %  end %successful trial sorting
    
    
end %end all trial sorting


end

