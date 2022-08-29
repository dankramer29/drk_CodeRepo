function save_plots( figs, varargin )
%save_plots Summary of this function goes here
%   INPUTS:
%         figs=   an array of which figures you want to save, enter as [1,
%         3:5, 8], if you want all figures you can just put an empty set in
%         [];
%         varargin=     
%                     'task', task  Input this if you want it to save it to the file that your data is in

%%
%find if task and folder was entered
[varargin, task, ~, found]=util.argkeyval('task', varargin, []);
%Save the figures. Currently as jpg because the fig files are huge.
%make it be a cell array
[varargin, name, ~, found]=util.argkeyval('name', varargin, []);

if ~isempty(task)
    folder_create=strcat('C:\Users\Daniel\Documents\DATA\', task.subject);
    folder_name=strcat(folder_create, '\', task.taskString, '\');  
    %make the directory filder
    mkdir (folder_create,   task.idString)
    for ii=1:length(figs)
        h=figure(figs(ii));
        saveas(h, fullfile(folder_name, get(h,'Name')), 'jpg');
    end
    
elseif isempty(task)
    if ~isempty(name)
        %NEED TO FIX THIS
        folder_create=strcat('C:\Users\Daniel\Documents\DATA\', name);
        folder_name=strcat(folder_create, '\', task.taskString, '\');
        %make the directory filder
        mkdir (folder_create,   task.idString)
        for ii=1:length(figs)
            h=figure(figs(ii));
            saveas(h, fullfile(folder_name, get(h,'Name')), 'jpg');
        end
    else
        for ii=1:length(figs)
            h=figure(figs(ii));
            saveas(h, get(h,'Name'), 'jpg');
        end
    end
end



end

