classdef Analyze < handle
    
    properties
        hDebug % handle to Debug.Debugger object
        hBlackrock % handle to NSx or NEV object
        hMap % handle to GridMap object
        numSeconds % number of samples to use in analysis
    end % END properties
    
    methods
        function this = Analyze(varargin)
            
            % process inputs
            [varargin,this.numSeconds] = util.argkeyval('numSeconds',varargin,120);
            [varargin,this.hBlackrock] = util.argfn(@(x)isa(x,'Blackrock.NSx')||isa(x,'Blackrock.NEV'),varargin,[]);
            [varargin,this.hDebug,found] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found
                this.hDebug = Debug.Debugger('Blackrock.Analyze');
            end
            [varargin,this.hMap] = util.argisa('GridMap',varargin,[]);
            if isempty(this.hMap)
                basename = regexprep(this.hBlackrock.SourceBasename,'^(.*)-\d{1,3}$','$1');
                mapfile = fullfile(this.hBlackrock.SourceDirectory,sprintf('%s_map.csv',basename));
                if exist(mapfile,'file')==2
                    this.hMap = GridMap(mapfile);
                end
            end
            util.argempty(varargin);
            
            % validate setup
            assert(~isempty(this.hBlackrock),'Must provide a Blackrock.NSx or Blackrock.NEV object');
            assert(~isempty(this.hMap),'Must provide a GridMap object');
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
            
            % process user inputs
            [varargin,outdir] = util.argkeyval('outdir',varargin,env.get('results'));
            [varargin,basename] = util.argkeyval('basename',varargin,'nsx');
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
            
            % run boxplot
            if flag_boxplot && isa(this.hBlackrock,'Blackrock.NSx')
                this.hDebug.log(sprintf('Running boxplot analysis for "%s"',this.hBlackrock.SourceBasename),'info');
                fig = boxplot(this);
                if flag_save
                    for kk=1:length(fig)
                        plot.save(fig{kk},'outdir',outdir,'basename',sprintf('%s_boxplot',basename),'overwrite','formats',formats,this.hDebug);
                        close(fig{kk});
                    end
                end
            end
            
            % run ksdensity
            if flag_ksdensity && isa(this.hBlackrock,'Blackrock.NSx')
                this.hDebug.log(sprintf('Running ksdensity analysis for "%s"',this.hBlackrock.SourceBasename),'info');
                fig = ksdensity(this);
                if flag_save
                    for kk=1:length(fig)
                        plot.save(fig{kk},'outdir',outdir,'basename',sprintf('%s_ksdensity',basename),'overwrite','formats',formats,this.hDebug);
                        close(fig{kk});
                    end
                end
            end
            
            % run corrmat
            if flag_corrmat && isa(this.hBlackrock,'Blackrock.NSx')
                this.hDebug.log(sprintf('Running corrmat analysis for "%s"',this.hBlackrock.SourceBasename),'info');
                fig = corrmat(this);
                if flag_save
                    plot.save(fig,'outdir',outdir,'basename',sprintf('%s_corrmat',basename),'overwrite','formats',formats,this.hDebug);
                    close(fig);
                end
            end
            
            % run cohvsep
            if flag_cohvsep && isa(this.hBlackrock,'Blackrock.NSx')
                this.hDebug.log(sprintf('Running cohvsep analysis for "%s"',this.hBlackrock.SourceBasename),'info');
                fig = cohvsep(this);
                if flag_save
                    for kk=1:length(fig)
                        plot.save(fig{kk},'outdir',outdir,'basename',sprintf('%s_cohvsep',basename),'overwrite','formats',formats,this.hDebug);
                        close(fig{kk});
                    end
                end
            end
        end % END function run
        
        function fig = boxplot(this)
            fig = cell(1,this.hMap.NumGrids);
            [npoints,which] = max(this.hBlackrock.PointsPerDataPacket);
            fs2ttr = this.hBlackrock.TimestampTimeResolution/this.hBlackrock.Fs;
            et = min(npoints*fs2ttr,this.numSeconds*this.hBlackrock.TimestampTimeResolution)/this.hBlackrock.TimestampTimeResolution;
            for gg=1:this.hMap.NumGrids
                this.hDebug.log(sprintf('Running boxplot analysis on grid "%s"',this.hMap.GridInfo.Label{gg}),'info');
                
                % get channel indices for this grid
                idxch = this.hMap.GridChannelIndex{gg};
                
                % get raw data
                dt = this.hBlackrock.read('channels',idxch,'time',[0 et],'ref','packet','packet',which);
                
                h = 400;
                w = 200+this.hMap.NumChannelsPerGrid(gg)*20;
                fig{gg} = figure(...
                    'Position',[100 100 w h],...
                    'PaperPositionMode','auto',...
                    'Name',sprintf('boxplot: grid %d (%s)',this.hMap.GridInfo.GridNumber(gg),this.hMap.GridInfo.Label{gg}));
                ax = axes('Units','pixels');
                boxplot(ax,dt,'PlotStyle','compact','Symbol','r.')
                title(sprintf('Statistics (grid "%s")',this.hMap.GridInfo.Label{gg}));
                left = 40;
                bottom = 40;
                width = w - left - 10;
                height = h - bottom - 40;
                set(ax,'Units','pixels','Position',[left bottom width height]);
                drawnow;
            end
        end % END function boxplot
        
        function fig = ksdensity(this)
            fig = cell(1,this.hMap.NumGrids);
            [npoints,which] = max(this.hBlackrock.PointsPerDataPacket);
            fs2ttr = this.hBlackrock.TimestampTimeResolution/this.hBlackrock.Fs;
            et = min(npoints*fs2ttr,this.numSeconds*this.hBlackrock.TimestampTimeResolution)/this.hBlackrock.TimestampTimeResolution;
            for gg=1:this.hMap.NumGrids
                this.hDebug.log(sprintf('Running ksdensity analysis on grid "%s"',this.hMap.GridInfo.Label{gg}),'info');
                
                % get channel indices for this grid
                idxch = this.hMap.GridChannelIndex{gg};
                
                % get raw data
                dt = this.hBlackrock.read('channels',idxch,'time',[0 et],'ref','packet','packet',which);
                lims = prctile(dt(:),[0.5 99.5]);
                dt = dt(1:10:end,:);
                
                % compute kernel smoothing function estimate
                kd = cell(1,size(dt,2));
                xi = linspace(lims(1),lims(2),500);
                parfor cc=1:size(dt,2)
                    kd{cc} = ksdensity(dt(:,cc),xi,'Function','pdf','Bandwidth',0.01);
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
                    'Name',sprintf('ksdensity: grid %d (%s)',this.hMap.GridInfo.GridNumber(gg),this.hMap.GridInfo.Label{gg}));
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
            [npoints,which] = max(this.hBlackrock.PointsPerDataPacket);
            fs2ttr = this.hBlackrock.TimestampTimeResolution/this.hBlackrock.Fs;
            et = min(npoints*fs2ttr,this.numSeconds*this.hBlackrock.TimestampTimeResolution)/this.hBlackrock.TimestampTimeResolution;
            dt = this.hBlackrock.read('time',[0 et],'ref','packet','packet',which);
            rho = corrcoef(dt,'rows','complete');
            fig = figure(...
                'PaperPositionMode','auto',...
                'Name','corrmat');
            ax = axes;
            imagesc(ax,rho);
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
            ticks{gg} = [ticks{gg} ch(end)];
            lbls{gg} = [lbls{gg} sprintf('%s-%d',gridlbl,ch(end)-ch(1)+1)];
            ticks = cat(2,ticks{:});
            ticks = ticks(:);
            lbls = cat(2,lbls{:});
            set(ax,'YTick',ticks,'YTickLabels',lbls,'XTick',ticks,'XTickLabels',lbls);
            title('corrmat');
        end % END function corrmat
        
        function fig = cohvsep(this)
            % COH plot coherence vs separation distance for each grid
            
            freqbinwidth = 10; % size of the frequency bins
            fig = cell(1,this.hMap.NumGrids);
            [npoints,which] = max(this.hBlackrock.PointsPerDataPacket);
            fs2ttr = this.hBlackrock.TimestampTimeResolution/this.hBlackrock.Fs;
            et = min(npoints*fs2ttr,this.numSeconds*this.hBlackrock.TimestampTimeResolution)/this.hBlackrock.TimestampTimeResolution;
            for gg=1:this.hMap.NumGrids
                this.hDebug.log(sprintf('Running cohvsep analysis on grid "%s"',this.hMap.GridInfo.Label{gg}),'info');
                
                % get channel indices for this grid
                idxch = this.hMap.GridChannelIndex{gg};
                
                % get raw data
                dt = this.hBlackrock.read('channels',idxch,'time',[0 et],'ref','packet','packet',which);
                
                % compute coherence
                [coh,~,~,f,chanpairs] = proc.blc.chanpaircoh(dt,this.hBLc.SamplingRate,[2 2],[3 5],[0 100]);
                [~,~,bin] = histcounts(f,f(1):freqbinwidth:(f(end)+freqbinwidth));
                coh = arrayfun(@(x)mean(coh(bin==x,:),1),1:max(bin),'UniformOutput',false);
                coh = cat(1,coh{:});
                f = arrayfun(@(x)mean(f(bin==x)),1:max(bin));
                
                % calculate average coherence at each separation distance
                layout = this.hMap.gridlayout(gg);
                spacing = this.hMap.GridInfo.ElectrodeSpacing(gg);
                pairsep = proc.helper.chansep(layout,spacing,chanpairs,[],1);
                [cohvsep,d] = proc.basic.quantvsep(coh,pairsep);
                
                fig{gg} = figure(...
                    'PaperPositionMode','auto',...
                    'Name',sprintf('cohvsep: grid %d (%s)',this.hMap.GridInfo.GridNumber(gg),this.hMap.GridInfo.Label{gg}));
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
            end
        end % END function cohvsep
    end % END methods
end % END classdef Analyze