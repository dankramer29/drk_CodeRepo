function saveFiles( singleFile, varargin )
%saveFiles Summary of this function goes here
%   INPUTS:
%         singleFile=   any file you want to save. just one at a time
%         varargin=     
%                     'subj_name', task  Input this if you want it to save it to the file that your data is in


%%
%find if task and folder was entered
[varargin, sessionName, ~, found]=util.argkeyval('sessionName', varargin, []);
%Save the figures. Currently as jpg because the fig files are huge.
%make it be a cell array
[varargin, subjName, ~, found]=util.argkeyval('subjName', varargin, []);
[varargin, versionNum, ~, found]=util.argkeyval('versionNum', varargin, '_'); %if you want to do multiple versions of the same file


if ~isempty(subjName)
    folder_create=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName);    
    folder_name=strcat(folder_create, '\', subjName, '\', versionNum, '_', date);  
    if ~isfolder(folder_name)
        %make the directory folder
        mkdir (folder_name)
    end
    %saveas(h, get(h,'Name'), 'jpg')
    save([folder_name, '\', singleFile] , 'close');

end