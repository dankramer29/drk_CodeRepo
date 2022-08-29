function [sepcoh,sepd,sepf] = run(varargin)

% set up debug
[varargin,flagDebug] = util.argflag('debug',varargin,false,5);

% set up caching
[varargin,nocacheread] = util.argflag('nocacheread',varargin,false,6);
cacheread = ~nocacheread;
[varargin,nocachewrite] = util.argflag('nocachewrite',varargin,false,6);
cachewrite = ~nocachewrite;

% set up which things to plot
[varargin,flagCohVSep] = util.argflag('cohvsep',varargin,false,5);
[varargin,flagCohVFreq] = util.argflag('cohvfreq',varargin,false,5);
[varargin,flagGridHHD] = util.argflag('gridhhd',varargin,false,5);
[varargin,flagFullHHD] = util.argflag('fullhhd',varargin,false,5);
[varargin,flagNoFigures] = util.argflag('nofigures',varargin,false,5);
if ~flagCohVSep && ~flagCohVFreq && ~flagGridHHD && ~flagFullHHD && ~flagNoFigures
    flagCohVSep = true;
    flagCohVFreq = true;
    flagGridHHD = true;
    flagFullHHD = true;
end

% set up run time and ID
runid = sprintf('run_%s',datestr(now,'yyyymmdd_HHMMSS'));
[varargin,runid] = util.argkeyval('runid',varargin,runid);

% set up debugger
idx = cellfun(@(x)isa(x,'Debug.Debugger'),varargin);
if any(idx)
    debugger = varargin{idx};
    varargin(idx) = [];
else
    debugger = Debug.Debugger(runid);
end

% set up results directory
resultdir = fullfile(env.get('results'),'ecogres',runid);
if exist(resultdir,'dir')~=7
    [status,msg] = mkdir(resultdir);
    assert(status,'Could not create directory ''%s'': %s',resultdir,msg);
end
debugger.log(sprintf('Results directory is ''%s''',resultdir),'info');

% get data sources
src = keck.ecogres.getSources(varargin{:});

% common values
badfreq = [60 120 180 240 300 360 420 480];
badfreqmargin = 9;
movingwin = [2 1];
tapers = [5 9];
fpass = [0 200];
debugger.log(sprintf('movingwin set to %s',util.vec2str(movingwin)),'info');
debugger.log(sprintf('tapers set to %s',util.vec2str(tapers)),'info');
debugger.log(sprintf('fpass set to %s',util.vec2str(fpass)),'info');

coh = cell(1,size(src,1));
sepcoh = cell(1,size(src,1));
sepd = cell(1,size(src,1));
sepf = cell(1,size(src,1));
hhd = cell(1,size(src,1));
hf = cell(1,size(src,1));
for ss=1:size(src,1)
    debugger.log(sprintf('Processing grid %d/%d: %s',ss,size(src,1),src.longname{ss}),'info');
    debugger.log(sprintf(['Grid information:\n'...
        '\tPatient ID: %s\n'...
        '\tGrid ID:    %s\n'...
        '\tType:       %s\n'...
        '\tSpacing:    %g mm\n'...
        '\tChannels:   %d\n'...
        '\tLocation:   %s'],...
        src.pid{ss},src.gid{ss},src.type{ss},src.spacing(ss),...
        nnz(isfinite(src.channels{ss})),src.location{ss}),'info');
    
    % tag and parameters for caching
    tag = cache.Taggable('mfilename',mfilename('fullpath'),'gid',src.gid{ss},'movingwin',movingwin,'tapers',tapers,'fpass',fpass);
    params = table2struct(src(ss,:));
    
    % compute coherence
    [coh{ss},phi,cx,f,colpairs] = gen_coh(params,movingwin,tapers,fpass,cacheread,cachewrite,tag,debugger);
    chanpairs = src.channels{ss}(colpairs);
    
    % compute channel separations
    layout = src.layout{ss}; % channel layout
    spacing = src.spacing(ss); % 400 um
    d = proc.helper.chansep(layout,spacing,chanpairs,[],1);
    
    % generate coherence vs separation distance
    [sepcoh{ss},sepd{ss},sepf{ss},ncontrib,sepcoh_ci,freqband] = gen_coh_v_sep(params,coh{ss},f,d,fpass,cacheread,cachewrite,tag,debugger);
    
    % generate half-height decay
    [hhd{ss},hf{ss}] = gen_hhd2(params,sepcoh{ss},sepf{ss},sepd{ss},resultdir,flagDebug);
    
    % one plot with half-height decay (units in mm) vs frequency
    if flagGridHHD
        plot_hhd(params,resultdir,hhd{ss},hf{ss},badfreq,badfreqmargin);
    end
    
    % one plot per frequency band: coherency over separation distance
    if flagCohVSep
        plot_coh_v_sep(params,resultdir,sepcoh{ss},freqband,badfreq,badfreqmargin,sepd{ss},ncontrib,sepcoh_ci,debugger);
    end
    
    % one plot per separation distance: coherency over frequency
    if flagCohVFreq
        plot_coh_v_freq(params,coh{ss},f,d,badfreq,badfreqmargin,resultdir,cacheread,cachewrite,tag,debugger);
    end
end
if flagFullHHD
    plot_hhd_full(resultdir,hhd,hf,badfreq,badfreqmargin,src);
end


function [hhd,f] = gen_hhd2(src,mcoh,f,seps,resultdir,flagPlot,ftype)

% prepare the data
[seps, f, mcoh] = prepareSurfaceData( seps, f, mcoh );

% Set up fittype and options.
ft_ = fittype( 'lowess' );
fo_ = fitoptions( 'Method', 'LowessFit' );
fo_.Normalize = 'on';
fo_.Robust = 'Bisquare';
fo_.Span = 0.05;

max_f = max(f);
cl = ceil(max_f/10);
max_f = ceil(max_f/cl)*cl;
max_sep = max(seps);
cl = ceil(max_sep/10);
max_sep = ceil(max_sep/cl)*cl;

% Fit model to data.
sf_ = fit( [seps, f], mcoh, ft_, fo_ );
seps_fit = linspace(0,max_sep,100);
f_fit = linspace(0,max_f,100);
[seps_grid,f_grid] = meshgrid(seps_fit,f_fit);
mcoh_grid = sf_(seps_grid,f_grid);

% compute the half-height coherence
range = prctile(mcoh_grid(:),[1 99]);
dr = diff(range);
hh = range(1) + dr/2;

% plot the data (primarily to get contour line)
fig = figure('Position',[35 350 1800 700],'PaperPositionMode','auto');
subplot(121);
C = plot(sf_,'XLim',[0 max_sep],'YLim',[0 max_f],'Style','Contour');
set(C,'LevelList',hh,'ShowText','on');
xlabel('Separation Distance (mm)');
ylabel('Frequency (Hz)');
title(sprintf('Grid %s / HH Contour %.2f',src.gid,hh));
subplot(122);
plot(sf_,'XLim',[0 max_sep],'YLim',[0 max_f],'Style','Surface');
xlabel('Separation Distance (mm)');
ylabel('Frequency (Hz)');
title(sprintf('Grid %s / HH Contour %.2f',src.gid,hh));

% loop over frequencies and find the best half-height separation for each
f = sort(unique(C.ContourMatrix(2,:)),'ascend');
hhd = nan(size(f));
for kk=1:length(f)
    hhd(kk) = nanmax(C.ContourMatrix(1,f==f(kk)));
end

% save the figure
saveas(fig,fullfile(resultdir,sprintf('hhdfit_%s.png',src.gid)));
saveas(fig,fullfile(resultdir,sprintf('hhdfit_%s.fig',src.gid)));
close(fig);



function [hhd,f] = gen_hhd(src,mcoh,f,seps,resultdir,flagPlot,ftype)
f = mean(f,2);
hhd = zeros(1,length(f));
if nargin<6||isempty(flagPlot),flagPlot=false;end
if nargin<7||isempty(ftype),ftype='smoothingspline';end
% if nargin<7||isempty(ftype),ftype='polynomial';end

% create a figure if plot requested
if flagPlot
    fig = figure;
    ax(1) = subplot(211);
    ax(2) = subplot(212);
    lh = [];
end

% add in 0-mm separation
seps = [0; seps];
mcoh = [ones(size(mcoh,1),1) mcoh];

% loop over frequencies to determine half-height decay at each
for kk=1:length(f)
    
    % fit a smoothing function to the raw coherence-vs-separation data
    ok_ = isfinite(seps) & isfinite(mcoh(kk,:)');
    if nnz(ok_)==0
        hhd(kk)=nan;
        continue;
    end
    if strcmpi(ftype,'smoothingspline')
        fo_ = fitoptions('Method','SmoothingSpline','SmoothingParam',0.25); % 0.0098
        ft_ = fittype('smoothingspline');
        cf_ = fit(seps(ok_),mcoh(kk,ok_)',ft_,fo_);
    elseif strcmpi(ftype,'polynomial')
        fo_ = fitoptions('Method','LinearLeastSquares','Normalize','on','Robust','bisquare');
        ft_ = fittype( 'poly7' );
        cf_ = fit(seps(ok_),mcoh(kk,ok_)',ft_,fo_);
    elseif strcmpi(ftype,'linear')
        fo_ = fitoptions('Method','LinearLeastSquares','Robust','LAR');
        ft_ = fittype('poly2');
        cf_ = fit(seps(ok_),mcoh(kk,ok_)',ft_,fo_);
    else
        error('Unknown fit type ''%s''',ftype);
    end
    
    % determine half-height decay: 
    % the interpolated x-position at which coherence equals half the
    % amplitude difference between (coherence at min separation) and
    % (coherence at max separation).
    
    % spline fits force an inflection point prior to the minimum separation
    % (i.e. start at a coherence below that of the minimum separation)
    % identify the inflection point and set that as the minimum separation
    % to consider.
    x = 0:0.01:seps(end); % range of separation distances
    y = cf_(x); % function values at those separations
    dy = diff(y); % derivative
    [~,idx_min_sep] = min(abs(x-seps(1)));
    assert(x(idx_min_sep)-seps(1)<=0.1,'Could not identify x coresponding to minimum separation');
    if dy(1)>0 && dy(idx_min_sep)<0
        [~,idx_min_sep] = min(abs(dy(1:idx_min_sep)));
    else
        idx_min_sep = 1;
    end
    x = x(idx_min_sep):0.01:seps(end);
    
    % identify the min and max coherence to calculate the range
    % min_coh = nanmin(mcoh(kk,:)); % minimum coherence value
    % max_coh = nanmax(mcoh(kk,:)); % maximum coherence value
    min_coh = min(cf_(seps(end)));
    max_coh = max(cf_(seps(1)));
    % [min_coh,min_idx] = nanmin(mcoh(kk,end-4:end)); % minimum coherence value
    % min_coh = nanmean(mcoh(kk,end-4:end)); % minimum coherence value
    % min_idx = (size(mcoh,2)-4)+min_idx-1;
    % [max_coh,max_idx] = nanmax(mcoh(kk,1:5)); % max coherence value
    % dr      = abs(1 - min_coh); % difference in range
    dr = abs(max_coh - min_coh);
    hh = min_coh+dr/2; % half-height point
    % hh      = min_coh + 0.05;
    
    % calculate the separation corresponding to a drop of half the range
    err = cf_(x)-hh;
    ii = find(err<0,1,'first');
    
    %[~,ii] = min(abs(cf_(x)-hh));
    % [~,ii]  = min(abs(cf_(x)-hh)); % index of amplitude closest to midway
    hhd(kk) = x(ii); % save that separation distance
    
    % plot the data if requested
    if flagPlot
        
        if isempty(lh)
            
            % plot the fit and original data
            subplot(ax(1));
            lh{1} = plot(seps,mcoh(kk,ok_),'x');
            hold on;
            lh{2} = plot(cf_);
            lh{3} = plot(x(ii),cf_(x(ii)),'k.','MarkerSize',10);
            hold off;
            ylim([-0.2 1.1]);
            xlabel('Separation Distance (mm)');
            ylabel('Coherence');
            
            % plot the half-height decay
            subplot(ax(2))
            hold on;
            lh{4} = plot(f(1:kk),hhd(1:kk),'k.','MarkerSize',10);
            xlim([f(1) f(end)]);
            ylim([0 seps(end)]);
            hold off;
            xlabel('Frequency (Hz)');
            ylabel('Half-Height (mm)');
            box(ax(2),'on');
        else
            
            % update x/y data for each plot
            set(lh{1},'XData',seps,'YData',mcoh(kk,ok_));
            set(lh{2},'XData',x,'YData',cf_(x));
            set(lh{3},'XData',x(ii),'YData',cf_(x(ii)));
            
            hold(ax(2),'on');
            set(lh{4},'XData',f(1:kk),'YData',hhd(1:kk));
            hold(ax(2),'off');
        end
        title(ax(1),sprintf('%s / %g Hz',src.gid,f(kk)));
        saveas(fig,fullfile(resultdir,sprintf('hhdfit_%s_f%.2fHz.png',src.gid,f(kk))));
        saveas(fig,fullfile(resultdir,sprintf('hhdfit_%s_f%.2fHz.fig',src.gid,f(kk))));
    end
end
if flagPlot
    close(fig);
end





function [coh,phi,cx,f,chanpairs] = gen_coh(src,movingwin,tapers,fpass,cacheread,cachewrite,tag,debugger)

% create local specific cache tag
tag = tag.copy;
tag.add('subfcn','get_coh');

% check whether data is cached, and if so load it
[cached,valid] = cache.query(tag,src,debugger);
if cached && valid && cacheread
    [coh,phi,cx,f,chanpairs] = cache.load(tag,debugger);
    return;
end

% start a timer
local_tmr = tic;

% read raw data
srcfile = fullfile(src.directory,src.filename);
[~,~,srcext] = fileparts(srcfile);
switch lower(srcext)
    case '.blx'
        debugger.log(sprintf('Loading data from BLx file ''%s''',srcfile),'info');
        blx = keck.BLx(srcfile);
        fs = blx.SamplingRate;
        data = blx.read('channels',src.channels,'time',src.time);
    case {'.ns1','.ns2','.ns3','.ns4','.ns5','.ns6'}
        debugger.log(sprintf('Loading data from NSx file ''%s''',srcfile),'info');
        nsx = Blackrock.NSx(srcfile);
        fs = nsx.Fs;
        data = nsx.read('channels',src.channels,'time',src.time);
        data = data';
    otherwise
        error('Unknown extension ''%s''',srcext);
end

% attenuate 60-Hz noise
chr = struct('Fs',fs,'tapers',tapers,'fpass',[0 fs/2],'trialave',0,'pad',1);
parfor kk=1:size(data,2)
    data(:,kk) = chronux.ct.rmlinesmovingwinc(data(:,kk),[2 1],10,chr,0.05);
end

% compute channel pair coherence
debugger.log(sprintf('Calculating coherence between each pair of %d channels',size(data,2)),'info');
[coh,phi,cx,f,chanpairs] = proc.basic.chanpaircoh(data,fs,movingwin,tapers,fpass);

% update user on timing
debugger.log(sprintf('Took %.2f seconds to generate data from scratch',toc(local_tmr)),'debug');

% place raw data into cache
if cachewrite
    cache.save(tag,src,debugger,coh,phi,cx,f,chanpairs);
end




function [sepcoh,sepd,sepf,ncontrib,sepcoh_ci,freqband] = gen_coh_v_sep(src,coh,f,d,fpass,cacheread,cachewrite,tag,debugger)

% create local specific cache tag
tag = tag.copy;
tag.add('subfcn','gen_coh_v_sep');

% collapse within frequency bands
bandwidth = 2;
freqband = [fpass(1):bandwidth:fpass(2)-bandwidth; fpass(1)+bandwidth:bandwidth:fpass(2)]';
sepf = mean(freqband,2);
numbands = size(freqband,1);
newcoh = cell(1,numbands);
newd = cell(1,numbands);
for kk=1:numbands
    newcoh{kk} = coh( f>=freqband(kk,1) & f<freqband(kk,2), : );
    newd{kk} = repmat(d(:),size(newcoh{kk},1),1);
end
tag.add('freqband',freqband);
numfreq = max(cellfun(@(x)size(x,1),newcoh));
for kk=1:numbands
    if size(newcoh{kk},1)<numfreq
        numrows = numfreq-size(newcoh{kk},1);
        newcoh{kk} = [newcoh{kk}; nan(numrows,size(newcoh{kk},2))];
        newd{kk} = [newd{kk}; nan(numrows*size(newcoh{kk},2),1)];
    end
    newcoh{kk} = newcoh{kk}';
    newcoh{kk} = newcoh{kk}(:)';
end

% check whether data is cached, and if so load it
[cached,valid] = cache.query(tag,src,debugger);
if cached && valid && cacheread
    [sepcoh,sepd,ncontrib,sepcoh_ci] = cache.load(tag,debugger);
    return;
else
    
    % start a timer
    local_tmr = tic;
    
    % find mean, 95% c.i.
    sepcoh = cell(1,numbands);
    sepd = cell(1,numbands);
    ncontrib = cell(1,numbands);
    sepcoh_ci = cell(1,numbands);
    parfor ff=1:numbands
        [sepcoh{ff},sepd{ff},ncontrib{ff}] = proc.basic.quantvsep(newcoh{ff},newd{ff},false,{@nanmean,1});
        sepcoh_ci{ff} = proc.basic.quantvsep(newcoh{ff},newd{ff},true,{@nanmean,1});
    end
    first_not_empty = find(~cellfun(@isempty,sepcoh),1,'first');
    normal_size = size(sepcoh{first_not_empty});
    all_empty = cellfun(@isempty,sepcoh);
    sepcoh(all_empty) = arrayfun(@(x)nan(normal_size),1:nnz(all_empty),'UniformOutput',false);
    ncontrib(all_empty) = arrayfun(@(x)nan(normal_size),1:nnz(all_empty),'UniformOutput',false);
    sepcoh_ci(all_empty) = arrayfun(@(x)nan(2,normal_size(1),normal_size(2)),1:nnz(all_empty),'UniformOutput',false);
    sepcoh = cat(1,sepcoh{:});
    sepd = sepd{first_not_empty};
    ncontrib = cat(1,ncontrib{:});
    sepcoh_ci = cat(2,sepcoh_ci{:});
    
    % update user on timing
    debugger.log(sprintf('Took %.2f seconds to generate data from scratch',toc(local_tmr)),'debug');
    
    % place raw data into cache
    if cachewrite
        cache.save(tag,src,debugger,sepcoh,sepd,ncontrib,sepcoh_ci);
    end
end




function plot_hhd(src,resultdir,hhd,f,badfreq,badfreqmargin)

% generate list of bad frequencies (i.e. line noise contamination)
idx_bad = false(size(f));
for kk=1:length(badfreq)
    idx_bad = idx_bad|abs(f-badfreq(kk))<=badfreqmargin;
end

% replace bad frequency values with NaNs
hhd(idx_bad) = nan;

% plot the data
fig = figure('Position',[35 350 1800 700],'PaperPositionMode','auto');
plot(f,hhd,'Color','k','LineWidth',3);
ylim([0 ceil(max(hhd)/10)*10]);
xlim([0 ceil(max(f))]);
ylabel('Half-height decay (mm)');
xlabel('Frequency (Hz)');
title(sprintf('%s: Half-Height Decay',src.longname));
saveas(fig,fullfile(resultdir,sprintf('hhd_%s.png',src.gid)));
saveas(fig,fullfile(resultdir,sprintf('hhd_%s.fig',src.gid)));
close(fig);




function plot_hhd_full(resultdir,hhd,f,badfreq,badfreqmargin,src)

% % unify the incoming data (different frequency points)
% all_f = unique(cat(2,f{:}))';
% all_hhd = nan(length(all_f),length(hhd));
% for kk=1:length(hhd)
%     all_hhd(ismember(all_f,f{kk}),kk) = hhd{kk};
% end
% f = all_f;
% hhd = all_hhd;

% generate list of bad frequencies (i.e. line noise contamination)
idx_bad = cell(1,length(hhd));
for nn=1:length(hhd)
    idx_bad{nn} = false(size(f{nn}));
    for kk=1:length(badfreq)
        idx_bad{nn} = idx_bad{nn}|abs(f{nn}-badfreq(kk))<=badfreqmargin;
    end
end

% find a smooth polynomial fit for the raw hhd points
hhdfits = cell(1,length(hhd));
ok_ = cell(1,length(hhd));
fo_ = fitoptions('Method','LinearLeastSquares','Robust','bisquare','Normalize','on');
ft_ = fittype('poly9');
for kk=1:length(hhd)
    
    % find points that are okay to fit: finite, not marked bad previously
    ok_{kk} = isfinite(f{kk}) & isfinite(hhd{kk}) & ~idx_bad{kk};
    
    % find "outliers" e.g., diffs that are too big
    dh = abs(diff(hhd{kk}(ok_{kk})));
    idx_out = util.outliers(dh);
    idx_ok = find(ok_{kk});
    ok_{kk}(idx_ok(idx_out)) = false;
    
%     % account for scenario with no good points
%     if nnz(ok_)==0
%         hhdfits{kk} = nan(size(hhd(:,kk)));
%         continue;
%     end
    
    % fit a smoothing function to the raw coherence-vs-separation data
    cf_ = fit(f{kk}(ok_{kk})',hhd{kk}(ok_{kk})',ft_,fo_);
    hhdfits{kk} = cf_(f{kk});
end

yl = [-inf inf];
xl = [-inf inf];

fig = figure('Position',[35 350 1800 700],'PaperPositionMode','auto');
grid_types = unique(src.type);
base_colors = plot.distinguishable_colors(length(grid_types));
lbl = cell(1,size(src,1));
idx_plot = 0;
for tt=1:length(grid_types)
    idx_type = find(strcmpi(src.type,grid_types{tt}));
    num_of_type = length(idx_type);
    clr = plot.rgbshades(base_colors(tt,:),num_of_type);
    for nn=1:num_of_type
        ii = idx_type(nn);
        idx_plot = idx_plot + 1;
        hhdfits_data = hhdfits{ii};
        hhdfits_data(idx_bad{ii}) = nan;
        % plot(f,hhd(:,ii),'Color',clr(nn,:),'LineWidth',3);
        plot(f{ii},hhdfits_data,'Color',clr(nn,:),'LineWidth',2);
        if idx_plot==1, hold on; end
        lbl{idx_plot} = src.longname{ii};
        yl = [min(0,yl(1)) max(max(hhd{ii}/10)*10,yl(2))];
        xl = [min(0,xl(1)) max(ceil(max(f{ii})),xl(2))];
    end
end
for tt=1:length(grid_types)
    idx_type = find(strcmpi(src.type,grid_types{tt}));
    num_of_type = length(idx_type);
    clr = plot.rgbshades(base_colors(tt,:),num_of_type);
    for nn=1:num_of_type
        ii = idx_type(nn);
        hhd_data = hhd{ii};
        hhd_data(~ok_{ii}) = nan;
        plot(f{ii},hhd_data,'x','MarkerSize',8,'LineWidth',2,'Color',clr(nn,:));
    end
end
ylim([0 30]);%ylim(yl);
xlim([0 170]);%xlim(xl);
ylabel('Half-height decay (mm)');
xlabel('Frequency (Hz)');
legend(lbl);
title('Half-Height Decay');
saveas(fig,fullfile(resultdir,'hhd_full.png'));
saveas(fig,fullfile(resultdir,'hhd_full.fig'));
close(fig);







function plot_coh_v_sep(src,resultdir,sepcoh,freqband,badfreq,badfreqmargin,sepd,ncontrib,sepcoh_ci,debugger)

% plot decay at each frequency
numbands = size(freqband,1);
fig = figure('Position',[35 350 1800 700],'PaperPositionMode','auto');
for ff=1:numbands
    if isnan(freqband(ff,1)),continue;end
    debugger.log(sprintf('Plotting %s / %d-%d Hz',src.gid,freqband(ff,1),freqband(ff,2)),'info');
    sepc = sepcoh(ff,:)';
    ci_lower = nanmax(sepc,squeeze(sepcoh_ci(1,ff,:))); % values <0 or >1 do not make sense
    ci_upper = nanmin(1-sepc,squeeze(sepcoh_ci(2,ff,:)));
    clf;
    plot(sepd,sepc,'LineWidth',3,'Color','k');
    hold on
    errorbar(sepd,sepc,ci_lower,ci_upper,'Color','k');
    ylim([0 1]);
    xlim([0 ceil(max(sepd))]);
    ylabel('Magnitude Coherence');
    xlabel('Separation Distance (mm)');
    title(sprintf('%s: Coherence vs. Separation (%d-%d Hz) (N=%d)',src.longname,freqband(ff,1),freqband(ff,2),ncontrib(ff)));
    legend({'coherence','95% confidence interval'});
    saveas(fig,fullfile(resultdir,sprintf('cohvsep_%s_%03d-%03dHz.png',src.gid,freqband(ff,1),freqband(ff,2))));
    saveas(fig,fullfile(resultdir,sprintf('cohvsep_%s_%03d-%03dfHz.fig',src.gid,freqband(ff,1),freqband(ff,2))));
end
close(fig)





function plot_coh_v_freq(src,coh,f,d,badfreq,badfreqmargin,resultdir,cacheread,cachewrite,tag,debugger)

% collapse within distance ranges
rangewidth = 0.1; % mm
maxd = ceil(nanmax(d));
seps = [0:rangewidth:maxd-rangewidth; rangewidth:rangewidth:maxd]';
numseps = size(seps,1);
newd = d;
for kk=1:numseps
    idx = d>=seps(kk,1)&d<seps(kk,2);
    newd(idx) = seps(kk,1);
end

% determine bad frequency indices
idx_bad = false(size(f));
for kk=1:length(badfreq)
    idx_bad( abs(f-badfreq(kk))<=badfreqmargin ) = true;
end

% compute mean, 95% c.i.
[sepcoh,sepd,ncontrib] = proc.basic.quantvsep(coh,newd,false,{@nanmean,1});
sepcoh_ci = proc.basic.quantvsep(coh,newd,true,{@nanmean,1});

% plot decay over frequency at each separation
fig = figure('Position',[35 350 1800 700],'PaperPositionMode','auto');
for ss=1:length(sepd)
    debugger.log(sprintf('Plotting %s / %1.1f-%1.1f mm',src.gid,sepd(ss),sepd(ss)+rangewidth),'info');
    seps = sepcoh(:,ss)';
    seps(idx_bad) = nan;
    ci_lower = nanmax(seps,squeeze(sepcoh_ci(1,:,ss))); % values <0 or >1 do not make sense
    ci_upper = nanmin(1-seps,squeeze(squeeze(sepcoh_ci(2,:,ss))));
    ci_lower(idx_bad) = nan;
    ci_upper(idx_bad) = nan;
    clf;
    plot(f,seps,'LineWidth',3,'Color','k');
    hold on
    errorbar(f,seps,ci_lower,ci_upper,'Color','k');
    ylim([0 1]);
    xlim([0 ceil(max(f))]);
    ylabel('Magnitude Coherence');
    xlabel('Frequency (Hz)');
    title(sprintf('%s: Coherence vs. Frequency (%01.1f-%01.1f mm) (N=%d)',src.longname,sepd(ss),sepd(ss)+rangewidth,ncontrib(ss)));
    legend({'coherence','95% confidence interval'});
    saveas(fig,fullfile(resultdir,sprintf('cohvfreq_%s_%01.1f-%01.1fmm.png',src.gid,sepd(ss),sepd(ss)+rangewidth)));
    saveas(fig,fullfile(resultdir,sprintf('cohvfreq_%s_%01.1f-%01.1fmm.fig',src.gid,sepd(ss),sepd(ss)+rangewidth)));
end
close(fig)