function save_plots( figs, varargin )
%save_plots Summary of this function goes here
%   INPUTS:
%         figs=   an array of which figures you want to save, enter as [1,
%         3:5, 8], if you want all figures you can just put an empty set in
%         [];
%         varargin=     
%                     'subj_name', task  Input this if you want it to save it to the file that your data is in

%TO DO FIX IF THE INPUTS AREN'T ENTERED, RIGHT NOW THEY ARE NEEDED REALLY
%%
%find if task and folder was entered
[varargin, sessionName, ~, found]=util.argkeyval('sessionName', varargin, []);
%Save the figures. Currently as jpg because the fig files are huge.
%make it be a cell array
[varargin, subjName, ~, found]=util.argkeyval('subjName', varargin, []);
[varargin, versionNum, ~, found]=util.argkeyval('versionNum', varargin, '_'); %if you want to do multiple versions of the same file


if ~isempty(subjName)
    folder_create=strcat('Z:\KramerEmotionID_2023\Data\EMU_nBack', '\', sessionName);    
    folder_name=strcat(folder_create, '\', subjName, '\', versionNum, '_', date);  
    %make the directory folder

    mkdir(folder_name)
    
    for ii=1:length(figs)
        h=figure(figs(ii));
        %saveas(h, get(h,'Name'), 'jpg')
        saveas(h, [fullfile(folder_name),'\', get(h,'Name')], 'jpg');
    end
% %THIS NEEDS FIXING BELOW TO MATCH WITH ABOVE    
% elseif isempty(sessionName)
%     if ~isempty(subjName)
%         name = strcat(subjName, date);
%         folder_create=strcat('C:\Users\Daniel\Documents\DATA\', name);
%         folder_name=strcat(folder_create, '\', sessionName, '\', subjName);
%         %make the directory filder
%         mkdir (folder_create,   subjName)
%         for ii=1:length(figs)
%             h=figure(figs(ii));
%             saveas(h, fullfile(folder_name, get(h,'Name')), 'jpg');
%         end
%     else
%         for ii=1:length(figs)
%             h=figure(figs(ii));
%             saveas(h, get(h,'Name'), 'jpg');
%         end
%     end
end



end

