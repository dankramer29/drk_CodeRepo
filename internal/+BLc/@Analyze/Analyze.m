classdef Analyze < handle
    
    properties
        hDebug % handle to Debug.Debugger object
        hBLc % handle to BLc.Reader object
        hMap % handle to GridMap object
        numSeconds % number of samples to use in analysis
    end % END properties
    
    methods
        function this = Analyze(varargin)
            
            % process inputs
            [varargin,this.numSeconds] = util.argkeyval('numSeconds',varargin,120);
            [varargin,this.hBLc] = util.argisa('BLc.Reader',varargin,[]);
            [varargin,this.hDebug] = util.argisa('Debug.Debugger',varargin,[]);
            if isempty(this.hDebug)
                this.hDebug = Debug.Debugger('BLc.Analyze');
            end
            [varargin,this.hMap] = util.argisa('GridMap.Interface',varargin,[]);
            if isempty(this.hMap)
                basename = regexprep(this.hBLc.SourceBasename,'^(.*)-\d{1,3}$','$1');
                mapfile = fullfile(this.hBLc.SourceDirectory,sprintf('%s_map.csv',basename));
                if exist(mapfile,'file')==2
                    this.hMap = GridMap.Interface(mapfile);
                end
            end
            util.argempty(varargin);
            
            % validate setup
            assert(~isempty(this.hBLc),'Must provide a BLc.Reader object');
            assert(~isempty(this.hMap),'Must provide a GridMap.Interface object');
            assert(~isempty(this.hDebug),'Must provide a Debug.Debugger object');
        end % END function Analyze
        
        function run(this,varargin)
            % RUN Run the analyses
            %
            %   RUN(THIS)
            %   Run all analyses and save them to the default directory
            %   (the RESULTS environment variable) with the default
            %   basename ("blc"). Plots will be saved as FIG and PNG.
            %
            %   RUN(...,'OUTDIR',D)
            %   Specify the directory in which to save files.
            %
            %   RUN(...,'BASENAME',B)
            %   Specify the basename with which to save files.
            %
            %   RUN(...,'FORMATS',{FMT1,FMT2,...})
            %   Specify list of file formats with which to save the
            %   figures.
            %
            %   RUN(...,'NOSAVE')
            %   Disable saving the plots.
            %
            %   RUN(...,'BOXPLOT')
            %   RUN(...,'KSDENSITY')
            %   RUN(...,'CORRMAT')
            %   RUN(...,'COHVSEP')
            %   Enable single analyses. If one or more of these is
            %   provided, it will override the default behavior which is to
            %   run all of them.
            %
            %   RUN(...,'NONE')
            %   Run none of the analyses (for personal introspection only).
%             warning('not working right now');
%             return;
%             
            % process user inputs
            [varargin,outdir] = util.argkeyval('outdir',varargin,env.get('results'));
            [varargin,basename] = util.argkeyval('basename',varargin,'blc');
            [varargin,formats] = util.argkeyval('formats',varargin,{'fig','png'},6);
            [varargin,flag_save] = util.argflag('nosave',varargin,true);
            flag_found = false(1,4);
            flag_all = true;
            [varargin,flag_boxplot,~,flag_found(1)] = util.argflag('boxplot',varargin,false);
            [varargin,flag_ksdensity,~,flag_found(2)] = util.argflag('ksdensity',varargin,false);
            [varargin,flag_corrmat,~,flag_found(3)] = util.argflag('corrmat',varargin,false);
            [varargin,flag_cohvsep,~,flag_found(4)] = util.argflag('cohvsep',varargin,false);
            if ~any(flag_found) % default is to do everything
                [varargin,flag_all] = util.argflag('none',varargin,true);
            end
            if flag_all
                flag_boxplot = true;
                flag_ksdensity = true;
                flag_corrmat = true;
                flag_cohvsep = true;
            end
            util.argempty(varargin);
            
            % set up labels
            lbl = arrayfun(@(x)sprintf('g%02d-%s',x,this.hMap.GridInfo.Label{x}),1:this.hMap.NumGrids,'UniformOutput',false);
            try
            
            % run boxplot
            if flag_boxplot
                this.hDebug.log(sprintf('Running boxplot analysis for "%s"',this.hBLc.SourceBasename),'info');
                outbase = cellfun(@(x)sprintf('%s_boxplot_%s',basename,x),lbl,'UniformOutput',false);
                idx_exist = cellfun(@(x)exist(fullfile(outdir,sprintf('%s.%s',x,formats{1})),'file')==2,outbase);
                flag_compute = true;
                if any(idx_exist)
                    response = questdlg('Output files already exist for "boxplot". Overwrite, skip, or cancel?','Existing output files','Overwrite','Skip','Cancel','Skip');
                    if strcmpi(response,'skip')
                        flag_compute = false;
                    elseif strcmpi(response,'cancel')
                        return;
                    end
                end
                
                if flag_compute
                    fig = boxplot(this);
                    if flag_save
                        for kk=1:length(fig)
                            plt.save(fig,'outdir',outdir,'basename',outbase{kk},'overwrite','formats',formats,this.hDebug);
                            close(fig);
                        end
                    end
                end
            end
            
            % run ksdensity
            if flag_ksdensity
                this.hDebug.log(sprintf('Running ksdensity analysis for "%s"',this.hBLc.SourceBasename),'info');
                outbase = cellfun(@(x)sprintf('%s_ksdensity_%s',basename,x),lbl,'UniformOutput',false);
                idx_exist = cellfun(@(x)exist(fullfile(outdir,sprintf('%s.%s',x,formats{1})),'file')==2,outbase);
                flag_compute = true;
                if any(idx_exist)
                    response = questdlg('Output files already exist for "ksdensity". Overwrite, skip, or cancel?','Existing output files','Overwrite','Skip','Cancel','Skip');
                    if strcmpi(response,'skip')
                        flag_compute = false;
                    elseif strcmpi(response,'cancel')
                        return;
                    end
                end
                
                if flag_compute
                    fig = ksdensity(this);
                    if flag_save
                        for kk=1:length(fig)
                            plt.save(fig{kk},'outdir',outdir,'basename',outbase{kk},'overwrite','formats',formats,this.hDebug);
                            close(fig{kk});
                        end
                    end
                end
            end
            
            % run corrmat
            if flag_corrmat
                this.hDebug.log(sprintf('Running corrmat analysis for "%s"',this.hBLc.SourceBasename),'info');
                outbase = sprintf('%s_corrmat',basename);
                idx_exist = exist(fullfile(outdir,sprintf('%s.%s',outbase,formats{1})),'file')==2;
                flag_compute = true;
                if any(idx_exist)
                    response = questdlg('Output file already exists for "corrmat". Overwrite, skip, or cancel?','Existing output files','Overwrite','Skip','Cancel','Skip');
                    if strcmpi(response,'skip')
                        flag_compute = false;
                    elseif strcmpi(response,'cancel')
                        return;
                    end
                end
                
                if flag_compute
                    fig = corrmat(this);
                    if flag_save
                        plt.save(fig,'outdir',outdir,'basename',outbase,'overwrite','formats',formats,this.hDebug);
                        close(fig);
                    end
                end
            end
            
            % run cohvsep
            if flag_cohvsep
                this.hDebug.log(sprintf('Running cohvsep analysis for "%s"',this.hBLc.SourceBasename),'info');
                outbase = cellfun(@(x)sprintf('%s_cohvsep_%s',basename,x),lbl,'UniformOutput',false);
                idx_exist = cellfun(@(x)exist(fullfile(outdir,sprintf('%s.%s',x,formats{1})),'file')==2,outbase);
                flag_compute = true;
                if any(idx_exist)
                    response = questdlg('Output files already exist for "cohvsep". Overwrite, skip, or cancel?','Existing output files','Overwrite','Skip','Cancel','Skip');
                    if strcmpi(response,'skip')
                        flag_compute = false;
                    elseif strcmpi(response,'cancel')
                        return;
                    end
                end
                
                if flag_compute
                    fig = cohvsep(this);
                    if flag_save
                        for kk=1:length(fig)
                            if isempty(fig{kk}),continue;end
                            plt.save(fig{kk},'outdir',outdir,'basename',sprintf('%s_cohvsep_%s',basename,lbl{kk}),'overwrite','formats',formats,this.hDebug);
                            close(fig{kk});
                        end
                    end
                end
            end
            catch ME
                util.errorMessage(ME);
                keyboard
            end
        end % END function run
        
        function fig = boxplot(this)
            
            % get raw data
            N = 1e5;
            [~,section] = max([this.hBLc.DataInfo.Duration]);
            dt = this.hBLc.read('section',section,'context','section');
            idx = unique(round(linspace(1,size(dt,1),N)));
            dt = dt(idx,:);
            
            % create figure
            ax1pos = [0.05 0.58 0.92 0.36];
            ax2pos = [0.05 0.20 0.92 0.36];
            fig = figure(...
                'PaperPositionMode','auto',...
                'Position',[100 100 1600 600],...
                'Name','boxplot');
            ax(1:2) = [axes('Position',ax1pos) axes('Position',ax2pos)];
            
            % plot
            boxplot(ax(1),dt,'PlotStyle','compact','Symbol','r.')
            boxplot(ax(2),zscore(dt),'PlotStyle','compact','Symbol','r.');%,'Labels',this.hMap.ChannelInfo.Label);%,'LabelOrientation','inline')
            set(ax(1),'Position',ax1pos);
            set(ax(2),'Position',ax2pos);
            title(ax(1),'Statistics');
            ylabel(ax(1),'raw amplitude');
            ylabel(ax(2),'standard deviations');
            set(ax,'TickLabelInterpreter','none');
            set(ax(1),'XTick',1:size(dt,2),'XTickLabel',{' '});
            set(ax(2),'XTick',1:size(dt,2),'XTickLabel',this.hMap.ChannelInfo.Label,'XTickLabelRotation',90);
        end % END function boxplot
        
        function fig = ksdensity(this)
            
            % process
            fig = cell(1,this.hMap.NumGrids);
            for gg=1:this.hMap.NumGrids
                this.hDebug.log(sprintf('Running ksdensity analysis on grid "%s"',this.hMap.GridInfo.Label{gg}),'info');
                
                % get channel indices for this grid
                idxch = this.hMap.GridChannelIndex{gg};
                
                % get raw data
                [~,section] = max([this.hBLc.DataInfo.Duration]);
                t = [0 floor(min(this.numSeconds,seconds(this.hBLc.DataInfo(section).Duration)))];
                dt = this.hBLc.read('channels',idxch,'time',t,'section',section,'context','section');
                lims = prctile(dt(:),[0.5 99.5]);
                N = round(size(dt,1)/min(size(dt,1),30e3));
                dt = dt(1:N:end,:);
                
                % compute kernel smoothing function estimate
                bandwidth = 7500/size(dt,1);
                kd = cell(1,size(dt,2));
                xi = linspace(lims(1),lims(2),500);
                parfor cc=1:size(dt,2)
                    kd{cc} = ksdensity(dt(:,cc),xi,'Function','pdf','Bandwidth',bandwidth);
                    kd{cc} = kd{cc}/sum(kd{cc});
                end
                kd = arrayfun(@(x)kd{x}+0.15*x*max(cellfun(@max,kd)),1:length(kd),'UniformOutput',false);
                kd = cat(1,kd{:});
                
                % plot the PDFs 150/18
                w = 180+this.hMap.NumChannelsPerGrid(gg)*20;
                h = 500;
                fig{gg} = figure(...
                    'Position',[100 50 w h],...
                    'PaperPositionMode','auto',...
                    'Name',sprintf('ksdensity: grid %d (%s)',this.hMap.GridInfo.GridID(gg),this.hMap.GridInfo.Label{gg}));
                ax = axes('Units','pixels');
                colormap autumn;
                colors = autumn(size(kd,1)+floor(0.4*size(kd,1)));
                hold(ax,'on');
                for cc=1:size(dt,2)
                    plot(kd(cc,:),xi,'Color',colors(cc,:));
                    text(kd(cc,end-1)+0.4*median(diff(kd(:,2))),xi(end-1),sprintf('ch-%d',cc),'Rotation',270);
                end
                hold(ax,'off');
                box(ax,'on');
                set(ax,'YLim',[lims(1)-0.01*diff(lims) lims(2)+0.01*diff(lims)]);
                set(ax,'XLim',[0 1.01*max(kd(:))]);
                set(ax,'XTick',[]);
                title(sprintf('ksdensity (grid "%s")',this.hMap.GridInfo.Label{gg}));
                left = 40;
                bottom = 10;
                width = w - left - 10;
                height = h - bottom - 40;
                set(ax,'Units','pixels','Position',[left bottom width height]);
                drawnow;
            end
        end % END function ksdensity
        
        function fig = corrmat(this)
            this.hDebug.log('Running corrmat analysis on full dataset','info');
            [~,section] = max([this.hBLc.DataInfo.Duration]);
            t = [0 floor(min(this.numSeconds,seconds(this.hBLc.DataInfo(section).Duration)))];
            dt = this.hBLc.read('time',t,'section',section,'context','section');
            rho = corrcoef(dt,'rows','complete');
            fig = figure(...
                'PaperPositionMode','auto',...
                'Position',[100 100 1600 600],...
                'Name','corrmat');
            ax = [subplot(121) subplot(122)];
            imagesc(ax(1),rho);
            imagesc(ax(2),abs(rho));
            set(ax(1),'CLim',[-1 1]);
            set(ax(2),'CLim',[0 1]);
            h = colorbar('peer',ax(1));
            ylabel(h,'Correlation Coefficient');
            set(get(h,'ylabel'),'rotation',270);
            set(h,'YTick',[-1 1]);
            h = colorbar('peer',ax(2));
            ylabel(h,'abs(Correlation Coefficient)');
            set(get(h,'ylabel'),'rotation',270);
            set(h,'YTick',[0 1]);
            ticks = cell(1,this.hMap.NumGrids);
            lbls = cell(1,this.hMap.NumGrids);
            for gg=1:this.hMap.NumGrids
                ch = this.hMap.GridChannelIndex{gg};
                gridlbl = this.hMap.GridInfo.Label{gg};
                if length(ch)<20
                    ticks{gg} = mean(ch);
                    lbls{gg} = {sprintf('%s %d-%d',gridlbl,ch(1),ch(end))};
                else
                    ticks{gg} = [ch(1) mean(ch)];
                    lbls{gg} = {sprintf('%s-1',gridlbl),sprintf('%s %d-%d',gridlbl,ch(1),ch(end))};
                end
            end
            %ticks{gg} = [ticks{gg} ch(end)];
            %lbls{gg} = [lbls{gg} sprintf('%s-%d',gridlbl,ch(end)-ch(1)+1)];
            ticks = cat(2,ticks{:});
            ticks = ticks(:);
            lbls = cat(2,lbls{:});
            set(ax,'TickLabelInterpreter','none');
            set(ax,'YTick',ticks,'YTickLabels',lbls,'XTick',ticks,'XTickLabels',lbls,'XTickLabelRotation',45);
            title(ax(1),['\bf{x-corr}' newline '\rm{tick marks centered on grid channels}'])
            title(ax(2),['\bf{abs(x-corr)}' newline '\rm{tick marks centered on grid channels}'])
            %title({'corrmat','tick marks centered on grid channels'});
        end % END function corrmat
        
        function fig = cohvsep(this)
            % COH plot coherence vs separation distance for each grid
            
            freqbinwidth = 10; % size of the frequency bins
            fig = cell(1,this.hMap.NumGrids);
            for gg=1:this.hMap.NumGrids
                switch this.hMap.GridInfo.Type{gg}
                    case {'SubduralGrid','SubduralStrip'}
                        this.hDebug.log(sprintf('Running cohvsep analysis on grid "%s"',this.hMap.GridInfo.Label{gg}),'info');
                        
                        % get channel indices for this grid
                        idxch = this.hMap.GridChannelIndex{gg};
                        
                        % get raw data
                        [~,section] = max([this.hBLc.DataInfo.Duration]);
                        t = [0 floor(min(this.numSeconds,seconds(this.hBLc.DataInfo(section).Duration)))];
                        dt = this.hBLc.read('channels',idxch,'time',t,'section',section,'context','section');
                        
                        % compute coherence
                        [coh,~,~,f,chanpairs] = proc.blc.chanpaircoh(dt,this.hBLc.SamplingRate,[2 2],[3 5],[0 100]);
                        [~,~,bin] = histcounts(f,f(1):freqbinwidth:(f(end)+freqbinwidth));
                        coh = arrayfun(@(x)mean(coh(bin==x,:),1),1:max(bin),'UniformOutput',false);
                        coh = cat(1,coh{:});
                        f = arrayfun(@(x)mean(f(bin==x)),1:max(bin));
                        
                        % calculate average coherence at each separation distance
                        layout = this.hMap.gridlayout(gg);
                        spacing = this.hMap.GridInfo.Custom{gg}.ElectrodeSpacing;
                        if ischar(spacing),spacing=str2double(spacing);end
                        pairsep = proc.helper.chansep(layout,spacing,chanpairs,[],1);
                        [cohvsep,d] = proc.basic.quantvsep(coh,pairsep);
                        
                        fig{gg} = figure(...
                            'PaperPositionMode','auto',...
                            'Name',sprintf('cohvsep: grid %d (%s)',this.hMap.GridInfo.GridID(gg),this.hMap.GridInfo.Label{gg}));
                        ax = axes;
                        colormap autumn;
                        colors = autumn(max(bin));
                        hold(ax,'on');
                        for kk=1:max(bin)
                            plot(d,cohvsep(kk,:),'Color',colors(kk,:));
                        end
                        hold(ax,'off');
                        colorbar('Ticks',linspace(0,1,10),...
                            'Ticklabels',arrayfun(@(x)sprintf('%.1f Hz',x),f(floor(linspace(1,length(f),10))),'UniformOutput',false));
                        xlabel('Separation Distance (mm)');
                        ylabel('Coherence');
                        title(sprintf('Coherence vs Separation Distance (grid "%s")',this.hMap.GridInfo.Label{gg}));
                        set(ax,'XLim',d([1 end]),'YLim',[0 1]);
                        drawnow
                    otherwise
                        this.hDebug.log(sprintf('cohvsep analysis not supported for grid type "%s"',this.hMap.GridInfo.Type{gg}),'info');
                end
            end
        end % END function cohvsep
    end % END methods
end % END classdef Analyze