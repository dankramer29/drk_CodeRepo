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
[varargin, channelsDone, ~, found]=util.argkeyval('channelsDone', varargin, '_'); %if you want to do multiple versions of the same file

% THIS FUNCTION DOESN'T REALLY WORK. I USED THIS CODE AND DID IT BY HAND:
folder_create=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName);
folder_name=strcat(folder_create, '\', subjName, '\', mat2str(chInterest), '_', date);
if ~isfolder(folder_name)
    %make the directory folder
    mkdir (folder_name)
end
fileName = [folder_name, '\', 'AllPatientsSigClusterSummStats', '.mat'];
%saveas(h, get(h,'Name'), 'jpg')
save(fileName);


%THIS PART NEEDS WORK ALTHOUGH DEFINITELY SOLVEABLE
if ~isempty(subjName)
    folder_create=strcat('C:\Users\kramdani\Documents\Data\EMU_nBack', '\', sessionName);
    folder_name=strcat(folder_create, '\', subjName, '\', channelsDone, '_', date);
    if ~isfolder(folder_name)
        %make the directory folder
        mkdir (folder_name)
    end
    fileName = [file_name, '\', singleFile, '.mat'];
        %saveas(h, get(h,'Name'), 'jpg')
        save([fullfile(folder_name), '\', singleFile, '.mat']);
end

end

