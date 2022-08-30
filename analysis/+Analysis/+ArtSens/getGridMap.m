function fullgridlbls = getGridMap(subject,varargin)

% default values
[varargin,motorcolor] = util.argkeyval(varargin,'motor',[0 0.3 0.6]);
[varargin,sensorycolor] = util.argkeyval(varargin,'sensory',[0.8 0.8 0.1]);
[~,diam] = util.argkeyval(varargin,'diameter',3);

filepath = fullfile(env.get('results'),'ECoG','Raw',upper(subject));


% load the ECoG grid map and orientation
load(fullfile(filepath,'gridMap.mat'));
fingerlbls = {'D1','D2','D3','D4','D5'};
shortlbls = {'PALM','FACE','TONGUE','ARM'};
palmlbls = {'W','X','Y','Z'}; 

% create labels for ECoG grid and colors to plot
gridcolors = cell(max(map.row),max(map.column));
gridlbls = cell(size(gridcolors));
fullgridlbls = cell(size(gridlbls));

fid = fopen(fullfile(filepath,'mapping.csv'));

if fid > 0
    mapfile = textscan(fid,'%f %f %s %s %s %s','Headerlines',1,'Delimiter',',');
    [elec1,elec2,location,amplitude,type,description] = mapfile{:};
    fclose(fid);
    
    %parsedLocs = cellfun(@(x)strsplit(util.cell2str(x),{';'}),location,'UniformOutput',false);
    fulllocs = cellfun(@(x)strsplit(util.cell2str(x),{';'}),location,'UniformOutput',false);
    parsedLocs = cellfun(@(x)regexp(x,'(?<finger>[\D\d])(?<grid>\D)\;|(?<finger>[\D\d])(?<grid>\D)','names'),location,'UniformOutput',false);
    idxLoc = cellfun(@(x)[x.finger]',parsedLocs,'UniformOutput',false);
    idxLoc(cellfun(@isempty,idxLoc)) = {''}; % make sure the 'empty' ones have an empty char
    if strcmpi(subject,'marco')
        parsedLocs = cellfun(@(x)regexp(x,'(?<hand>[\D+]|(?<hand>[\D])(?<grid>\d)\;|(?<hand>[\D])(?<grid>\d)','names'),location,'UniformOutput',false);
        handLoc = cellfun(@(x)[x.hand]',parsedLocs,'UniformOutput',false);
        handLoc(cellfun(@isempty,handLoc)) = {''};
    end
    
    parsedTypes = cellfun(@(x)strsplit(util.cell2str(x),{';'}),type,'UniformOutput',false);
    for nn = 1:length(elec1)
        col1 = map.column(map.elec == elec1(nn));
        col2 = map.column(map.elec == elec2(nn));
        row1 = map.row(map.elec == elec1(nn));
        row2 = map.row(map.elec == elec2(nn));
        if any(strcmpi(parsedTypes{nn},'motor'))
            typecolor = motorcolor;
        else
            typecolor = sensorycolor;
            if ischar(idxLoc{nn}); curIdx = str2num(idxLoc{nn})'; else, curIdx = idxLoc{nn}; end
            index = sub2ind(size(gridlbls),[row1 row2],[col1 col2]);
            if all(cellfun(@isempty,gridlbls(index)))
                gridlbls(index) = {util.cell2str(unique(fingerlbls(curIdx)))};
                fullgridlbls(index) = {util.cell2str(fulllocs{nn})};
            elseif any(cellfun(@isempty,gridlbls(index)))
                idx = cellfun(@isempty,gridlbls(index));
                gridlbls(index(idx)) =  {util.cell2str(unique(fingerlbls(curIdx)))};
                gridlbls(index(~idx)) = {util.cell2str(unique([gridlbls(index(~idx)),fingerlbls(curIdx)]))};
                fullgridlbls(index) = {util.cell2str(fulllocs{nn})};
                fullgridlbls(index(~idx)) = {util.cell2str(unique([fullgridlbls(index(~idx)),fulllocs{nn}]))};
            else
                gridlbls(index) = {util.cell2str(unique([gridlbls(index),fingerlbls(curIdx)]))};
                fullgridlbls(index) = {util.cell2str(unique([fullgridlbls(index),fulllocs{nn}]))};
            end
        end
        if isempty(gridcolors{row1,col1})
            gridcolors{row1,col1} = typecolor;
        else
            gridcolors{row1,col1} = mean([gridcolors{row1,col1};typecolor]);
        end
        if isempty(gridcolors{row2,col2})
            gridcolors{row2,col2} = typecolor;
        else
            gridcolors{row2,col2} = mean([gridcolors{row2,col2};typecolor]);
        end
    end
    
    % Compute coverage of hand map by electrodes
    area = (pi*(diam/2)^2)*ones(size(gridlbls));
    subind = ['a':'h']';
    fingerGridLbls = cell(length(subind),length(fingerlbls));
    fingerGrid = nan(length(subind),length(fingerlbls));
    fingerElecs = zeros(1,length(fingerlbls));
    gridLoc = cellfun(@(x)[x.grid]',parsedLocs,'UniformOutput',false);
    fingerElecArea = zeros(1,length(fingerlbls));
    for nn = 1:length(fingerlbls)
        idxfinger = cellfun(@(x)strfind(x',num2str(nn)),idxLoc,'UniformOutput',false);
        idxgrid = cell2mat(cellfun(@(x)ismember(subind',x'),gridLoc(~cellfun(@isempty,idxfinger)  & ~strcmpi('motor',type)),'UniformOutput',false));
        fingerGrid(:,nn) = sum(idxgrid)';
        if nn == 1
            fingerGridLbls(:,nn) = cellstr([repmat(fingerlbls{nn},length(subind),1),subind])';
        else
            fingerGridLbls(1:6,nn) = cellstr([repmat(fingerlbls{nn},length(subind)-2,1),subind(1:6)])';
        end
        fingerElecs(nn) = sum(cellfun(@(x)any(strfind(x,fingerlbls{nn})),gridlbls(:)));
        fingerElecArea(nn) = sum(area(cellfun(@(x)any(strfind(x,fingerlbls{nn})),gridlbls)));
    end
    
    % plot finger/hand coverage
    figure;
    bar(1:(length(fingerlbls)),nansum(fingerGrid>0)*100./[length(subind) repmat(length(subind)-2,1,4)]);
    hold on; box off;
    ylabel('Finger area mapped (%)','fontsize',13);
    set(gca,'XTickLabel',fingerlbls,'YLim',[0 100]);
    yyaxis right;
    plot(1:length(fingerlbls),fingerElecs,'linewidth',3);
    ylim([0 15])
    ylabel('Number of electrodes','fontsize',12)
    xlabel('Fingers ID','fontsize',13)
    
    savedir = fullfile(env.get('results'),'ECoG',mfilename);
    if exist(savedir,'dir') == 0; mkdir(savedir); end
    name = [subject,'_fingerGridMap'];
    Common.plotsave(fullfile(savedir,name));
    close all
    
    % plot grid
    side = 6;
    figure;
    for kk = 8:-1:1
        curBottom = 0 + (8-kk)*side;
        for jj = 1:8
            curLeft = 0 + (jj-1)*side;
            if ~isempty(gridcolors{kk,jj})
                patch([curLeft curLeft+side curLeft+side curLeft],[curBottom curBottom curBottom+side curBottom+side],gridcolors{kk,jj},'LineStyle','--','LineWidth',1.5);
                hold on; box off
                %x = curLeft+side/2 + cos(linspace(0,2*pi,100))*side/3;
                %y = curBottom+side/2 + sin(linspace(0,2*pi,100))*side/3;
                %patch(x,y,gridcolors{kk,jj},'EdgeColor',gridcolors{kk,jj})
                if ~isempty(gridlbls{kk,jj}); text(curLeft + side/4,curBottom + side/2,strsplit(gridlbls{kk,jj},',')); end
            else
                 patch([curLeft curLeft+side curLeft+side curLeft],[curBottom curBottom curBottom+side curBottom+side],[0.5 0.5 0.5],'LineStyle','--','LineWidth',1.5);
                 hold on; box off
            end
        end
    end
    if map.antInfElec > map.postInfElec
        xtick = map.antInfElec:-8:map.postInfElec;
    else
        xtick = map.antInfElec:8:map.postInfElec;
    end
    if map.antSupElec > map.antInfElec
        ytick = map.antInfElec:1:map.antSupElec;
    else
        ytick = map.antInfElec:-1:map.antSupElec;
    end
    set(gca,'XTick',side/2:side:side*jj,'Ytick',side/2:side:side*jj,'XTickLabel',xtick,'YTickLabel',ytick);
    axis square;
    
    name = [lower(subject),'_mapping'];
    Common.plotsave(fullfile(savedir,name));
else
    error('No mapping file found for subject %s',subject);
end
end