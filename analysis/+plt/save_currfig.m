function save_currfig(varargin)
% save_currfig('SavePath','ImageType','CloseFigs')
%
% saveOpenFigs('SavePath','...') provide full path to desired save
% location, name of BLc.Reader object, or name of task object to make save folder. Default = GUI to choose directory
%
% saveOpenFigs('ImageType','type') provide desired image filetype.
% Options: 'png'(Default) 'jpeg' 'tiff'(compressed) 'dbmp' 'fig'
%
% saveOpenFigs('CloseFigs', true/false) whether to close the figure
% after saving it. Default = false

%Example
%   plot.save_currfig('SavePath', blc)

[varargin,SavePath,~,found] = util.argkeyval('SavePath',varargin,'');


[varargin,ImageType] = util.argkeyval('ImageType',varargin,'jpg');

[varargin,CloseFig] = util.argkeyval('CloseFig', varargin, false);

if isa(SavePath,'BLc.Reader')
    folder_name=strcat(SavePath.SourceBasename, '_Results');
    file_name=fullfile(SavePath.SourceDirectory,  folder_name);
    %make a new folder each time
    if exist(file_name)~=7
        mkdir (file_name)
    %{ 
    elseif exist(file_name)==7
        for ii=1:100
            file_name_new=strcat(file_name, '_', num2str(ii));
            if exist(file_name_new)==7
                continue
            else
                mkdir (file_name_new)
                break
            end
        end
        %}
    end
elseif isa(SavePath, 'FrameworkTask')
    folder_name=strcat(SavePath.taskString, '_Results');
    file_name=fullfile(SavePath.sessionPath,  folder_name);
    %make the directory filder
    if exist(file_name)~=7
        mkdir (file_name)
    end
    
elseif exist(SavePath, 'file')==7 %if a file path is entered
    file_name=fullfile(SavePath, 'Fig_Results');
    if exist(file_name)~=7
        mkdir(file_name)
    
    end   
elseif ~found    
    SavePath = uigetdir('C:\Users\');
    file_name=fullfile(SavePath, '_Results');
    if exist(file_name)~=7
        mkdir(file_name)
    
    end
else
    error('was unable to make directory');
end


figs=length(get(0,'children')); %find out how many figures are open
for ii=1:figs
    h=figure(ii);
    nme=get(h,'Name');
    full_name=fullfile(file_name, nme);
    try
    saveas(h, full_name, ImageType);
    catch
        warning('not saving for weird reason, the weird reason is you need to restart matlab')
        try
        savefig(h, full_name, ImageType);
        catch
            warning('still didnt work')
        end
    end
end
if CloseFig
    close all
end
end

