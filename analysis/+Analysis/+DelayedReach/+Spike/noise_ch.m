function [ wanted_ch ] = noise_ch( data, varargin )
%noise_ch clean out noisey channels
%   THIS IS A SIMPLE VERSION TO GET RID OF KNOWN NOISE CHANNELS, WILL NEED
%   TO MAKE A MORE COMPLICATED ONE

%%
[varargin, ch]=util.argkeyval('ch', varargin, [1 128]);

%find the set up if specified
[varargin, standard, ~, found]=util.argkeyval('standard', varargin, 1);
if ~found
    warning('Unless otherwise specified in standard, set up is 3 10ch micros and 2 8 channel macros next to eachother');
end
util.argempty(varargin);


 cl_noise = data;
 %clear anything over 128
 cl_noise(:,129:end,:)=[];
 switch standard
     % to make a new set up, figure out the channels you want in cl_noise,
     % then repeat down for ch_wanted, then change the ch(1,2) below so
     % that the new end number matches the amount, to find out that amount,
     % can do it like this but with the new clear channel numbers in [ ]
     %ch_wanted=1:128;
     %ch_wanted( [11:16 27:32 43:48 59:128]) = [];, then set the ch (1,2)
     %to whatever the last channel on ch_wanted is (like above is 58)
     case 1 %6 sets of 10micros with 6 dead channels and then 2 sets 8 macros with 8 dead plugged into each port
         
         cl_noise(:, [11:16 27:32 43:48 59:64 75:80 91:96 105:112 121:128],:) = [];
         
         %%
         %no clear the channels not desired
         %WILL NEED TO FIX IF TOTAL CHANNELS IS MORE THAN 128
         ch_wanted=1:128;
         ch_wanted(:, [11:16 27:32 43:48 59:64 75:80 91:96 105:112 121:128],:) = [];
         %restructure the end channel to the last real channel if the user
         %wants the full amount of channels.  also return an error if it's
         %an uneven number
         if ch(1,2)==128
             ch(1,2)=120;  
         elseif isempty(find((ch_wanted==ch(1,2)), 1))
             error('end channel desired is a noise channel, see Analysis.DelayedReach.noise_ch for set up and must make new set up or pick different channels');                
         end
         ch_col(1,1)=find(ch_wanted==ch(1,1));
         ch_col(1,2)=find(ch_wanted==ch(1,2));
         wanted_ch=cl_noise(:, ch_col(1,1):ch_col(1,2), :);
         
     case 2 %same amount, but plugged in consecutively for the macros so the last 16 are dead
         
         cl_noise(:, [11:16 27:32 43:48 59:64 75:80 91:96 113:128], :) = [];
         %%
         %no clear the channels not desired
         %WILL NEED TO FIX IF TOTAL CHANNELS IS MORE THAN 128
         ch_wanted=1:128;
         ch_wanted(:, [11:16 27:32 43:48 59:64 75:80 91:96 113:128],:) = [];
         if ch(1,2)==128
             ch(1,2)=112;  
         elseif isempty(find((ch_wanted==ch(1,2)), 1))
             error('end channel desired is a noise channel, see Analysis.DelayedReach.noise_ch for set up and must make new set up or pick different channels');                
         end
         ch_col(1,1)=find(ch_wanted==ch(1,1));
         ch_col(1,2)=find(ch_wanted==ch(1,2));
         wanted_ch=cl_noise(:, ch_col(1,1):ch_col(1,2), :);
         
     case 3 %3 sets of micros and no macros plugged in
         cl_noise(:, [11:16 27:32 43:48 59:64 75:80 91:128], :) = [];
         %%
         %no clear the channels not desired
         %WILL NEED TO FIX IF TOTAL CHANNELS IS MORE THAN 128
         ch_wanted=1:128;
         ch_wanted(:, [11:16 27:32 43:48 59:64 75:80 91:128],:) = [];
         if ch(1,2)==128
             ch(1,2)=90;  
         elseif isempty(find((ch_wanted==ch(1,2)), 1))
             error('end channel desired is a noise channel, see Analysis.DelayedReach.noise_ch for set up and must make new set up or pick different channels');                
         end
         ch_col(1,1)=find(ch_wanted==ch(1,1));
         ch_col(1,2)=find(ch_wanted==ch(1,2));
         wanted_ch=cl_noise(:, ch_col(1,1):ch_col(1,2),:);
     case 4 %3 sets of micros and macros 6 and 6 and put on top of each other
         cl_noise(:, [11:16 27:32 43:48 59:64 75:80 91:96 109:128], :) = [];
         %%
         %no clear the channels not desired
         %WILL NEED TO FIX IF TOTAL CHANNELS IS MORE THAN 128
         ch_wanted=1:128;
         ch_wanted(:, [11:16 27:32 43:48 59:64 75:80 90:96 109:128 ],:) = [];
         if ch(1,2)==128
             ch(1,2)=108; %this needs to be the last real channel in the recording. 
         elseif isempty(find((ch_wanted==ch(1,2)), 1))
             error('end channel desired is a noise channel, see Analysis.DelayedReach.noise_ch for set up and must make new set up or pick different channels');                
         end
         ch_col(1,1)=find(ch_wanted==ch(1,1));
         ch_col(1,2)=find(ch_wanted==ch(1,2));
         wanted_ch=cl_noise(:, ch_col(1,1):ch_col(1,2), :);
     case 5 %4 sets of micros only and no macros plugged in
         cl_noise(:, [11:16 27:32 43:48 59:128], :) = [];
         %%
         %no clear the channels not desired
         %WILL NEED TO FIX IF TOTAL CHANNELS IS MORE THAN 128
         ch_wanted=1:128;
         ch_wanted(:, [11:16 27:32 43:48 59:128], :) = [];
         if ch(1,2)==128
             ch(1,2)=58;
         elseif isempty(find((ch_wanted==ch(1,2)), 1))
             error('end channel desired is a noise channel, see Analysis.DelayedReach.noise_ch for set up and must make new set up or pick different channels');
         end
         ch_col(1,1)=find(ch_wanted==ch(1,1));
         ch_col(1,2)=find(ch_wanted==ch(1,2));
         wanted_ch=cl_noise(:, ch_col(1,1):ch_col(1,2),:);
     case 6 %if the channels are blacked out on blackrock, it doesn't show up at all and the channels are all non noise channels, so this just takes it as is, but not the full 128
         ch_wanted=1:size(data,2);
         if ch(1,2)==128
             ch(1,2)=size(data,2);
         elseif isempty(find((ch_wanted==ch(1,2)), 1))
             error('end channel desired is a noise channel, see Analysis.DelayedReach.noise_ch for set up and must make new set up or pick different channels');
         end
         ch_col(1,1)=find(ch_wanted==ch(1,1));
         ch_col(1,2)=find(ch_wanted==ch(1,2));
         wanted_ch=cl_noise(:, ch_col(1,1):ch_col(1,2),:);
         
 end
 

 
 
 
 

end

