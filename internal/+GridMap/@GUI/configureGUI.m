function configureGUI(this,varargin)
for nn=1:length(varargin)
    switch lower(varargin{nn})
        case 'mapfile__disabled'
            states = {...
                'buttonSelectMapfile','off';
                'buttonLoadMapfile','off';
                'buttonSaveMapfile','off'};
        case 'mapfile__enabled'
            if isempty(this.Mapfile)
                states = {...
                    'buttonSelectMapfile','on';
                    'buttonLoadMapfile','off';
                    '',''};
            else
                states = {...
                    'buttonSelectMapfile','on';
                    'buttonLoadMapfile','on';
                    '',''};
            end
            if isempty(this.hGridMap) || this.hGridMap.NumGrids==0
                states(3,:) = {'buttonSaveMapfile','off'};
            else
                states(3,:) = {'buttonSaveMapfile','on'};
            end
        case 'mapfile__limited_load'
            if isempty(this.Mapfile)
                states = {...
                    'buttonSelectMapfile','off';
                    'buttonLoadMapfile','off';
                    'buttonSaveMapfile','off'};
            else
                states = {...
                    'buttonSelectMapfile','off';
                    'buttonLoadMapfile','on';
                    'buttonSaveMapfile','off'};
            end
        case 'gridinfo__disabled'
            states = {...
                'listboxGridInfo','off';
                'buttonNewGrid','off';
                'buttonEditGrid','off';
                'buttonDeleteGrid','off';
                'buttonMoveGridUp','off';
                'buttonMoveGridDown','off';};
        case 'gridinfo__limited'
            states = {...
                'listboxGridInfo','off';
                'buttonNewGrid','on';
                'buttonEditGrid','off';
                'buttonDeleteGrid','off'
                'buttonMoveGridUp','off';
                'buttonMoveGridDown','off';};
        case 'gridinfo__enabled'
            states = {...
                'listboxGridInfo','on';
                'buttonNewGrid','on';
                'buttonEditGrid','on';
                'buttonDeleteGrid','on'
                'buttonMoveGridUp','on';
                'buttonMoveGridDown','on';};
        case 'channelinfo__disabled'
            states = {...
                'listboxChannelInfo','off';
                'buttonAllGrids','off';
                'buttonSelectedGrid','off'};
        case 'channelinfo__enabled'
            states = {...
                'listboxChannelInfo','on';
                'buttonAllGrids','on';
                'buttonSelectedGrid','on'};
        case 'gridsummary__disabled'
            states = {...
                'popupTemplate','off';
                'popupLocation','off';
                'popupHemisphere','off';
                'editLabel','off';
                'editElectrode','off';
                'editFirstAmpChannel','off';
                'checkboxBankAlign','off';
                'checkboxBankLock','off';
                'buttonSaveGrid','off';
                'buttonResetGrid','off';
                'buttonCancelGrid','off'};
        case 'gridsummary__enabled'
            states = {...
                'popupTemplate','on';
                'popupLocation','on';
                'popupHemisphere','on';
                'editLabel','on';
                'editElectrode','on';
                'editFirstAmpChannel','on';
                'checkboxBankAlign','on';
                'checkboxBankLock','on';
                'buttonSaveGrid','on';
                'buttonResetGrid','on';
                'buttonCancelGrid','on'};
        otherwise
            error('Unknown GUI mode "%s"',varargin{nn});
    end
    for kk=1:size(states,1)
        set(this.guiHandles.(states{kk,1}),'Enable',states{kk,2});
    end
end