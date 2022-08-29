function [outputArg1,outputArg2] = testpeaks(CH,specpeakall)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here



nmes{1}='bm';
temp2.bm=specpeakall;
touch=fields(temp2.bm);


HG=table;
Alpha=table;
Beta=table;
Gamma=table;



tempHG=[];
for kk=1:length(touch)
    
    for jj=1:length(nmes)
        for ii=1:length(CH.(nmes{jj}).high)
            if isempty(tempHG)
                tempHG(1,1:4)=temp2.(nmes{jj}).(touch{kk}).HighGamma(CH.(nmes{jj}).high(ii),:);
                catHG{1,1}=touch{kk};
            else
                tempHG(end+1,1:4)=temp2.(nmes{jj}).(touch{kk}).HighGamma(CH.(nmes{jj}).high(ii),:);
                catHG{end+1,1}=touch{kk};
            end
        end
    end
end



end

