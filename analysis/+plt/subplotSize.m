function [subN1,subN2] = subplotSize(subplotNum)
%Get the first and second number to make a nice square subplot
%makes a subplot the right size
%input the size of the data you are trying to arrange.

subN1=sqrt(subplotNum);
if round(subN1)<subN1
    subN1=floor(subN1); 
    subN2=subN1+1; 
elseif subN1==round(subN1) %if sqrt is whole
    subN2=subN1;
else
    subN1=ceil(subN1);
    subN2=subN1+1; 
end 

end