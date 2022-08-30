function saveOpenFigs(varargin)
    % saveOpenFigs('SavePath','ImageType','CloseFigs')
    %
    % saveOpenFigs('SavePath','...') provide full path to desired save
    % location. Default = GUI to choose directory
    %
    % saveOpenFigs('ImageType','type') provide desired image filetype.
    % Options: 'png'(Default) 'jpeg' 'tiff'(compressed) 'dbmp' 'fig'
    %
    % saveOpenFigs('CloseFigs', true/false) whether to close the figure
    % after saving it. Default = false
    
    [varargin,SavePath,~,found] = util.argkeyval('SavePath',varargin,'');
    if ~found
        SavePath = uigetdir('C:\Users\Mike\Documents');
    end
    
    [varargin,ImageType] = util.argkeyval('ImageType',varargin,'png');
    
    [varargin,CloseFigs] = util.argkeyval('CloseFigs', varargin, false);
    
    util.argempty(varargin);

    Figs = findobj('type', 'figure'); %will get info on all open figures
    %Need to change this so that the Filename has \ between dir and figname
    for i = 1:size(Figs,1)
        FigName = Figs(i).Name;
        Filename = fullfile(SavePath,sprintf('%s.%s', FigName, ImageType));
        saveas(Figs(i), Filename)
        if CloseFigs
            close(Figs(i))
        end
    end
end