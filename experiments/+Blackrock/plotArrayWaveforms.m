function [hFigure,ax] = plotArrayWaveforms(waveforms,channels,map,varargin)
% PLOTARRAYWAVEFORMS plot array waveforms
%
%   [HFIGURE,AX] = PLOTARRAYWAVEFORMS(WAVEFORMS,CHANNELS,MAP)
%   If WAVEFORMS is a cell array, the Kth cell must contain a NSAMPLESxN
%   array of NSAMPLE-length waveforms for the Kth channel in CHANNELS, or 
%   an empty array if no waveforms exist for that channel.  CHANNELS must 
%   contain the channel identity of each cell of WAVEFORMS.
%
%   If WAVEFORMS is a numeric array, it must be NSAMPLESxN, and CHANNELS
%   must be a vector of length N identifying the channel associated with
%   each column of WAVEFORMS.
%
%   MAP can be a valid path to a *.cmp file, or a valid Blackrock.ArrayMap
%   object.
%
%   HFIGURE is a handle to the created figure; AX is an array of handles to
%   the channel subplots.
%
%   PLOTARRAYWAVEFORMS(...,'RAW')
%   PLOTARRAYWAVEFORMS(...,'HIST')
%   Either plot the raw waveforms (default) or plot a 2D histogram of the
%   waveforms.
%
%   PLOTARRAYWAVEFORMS(...,'NSAMPLES',VAL)
%   Customize the number of samples per waveform (default is 48).
%
%   PLOTARRAYWAVEFORMS(...,'MAXWAVEFORMS',VAL)
%   Only use the first VAL waveforms for plotting or generating the
%   histogram.
%
%   PLOTARRAYWAVEFORMS(...,'YLIMSCOPE', 'GLOBAL')
%   PLOTARRAYWAVEFORMS(...,'YLIMSCOPE', 'LOCAL')
%   Use the entire dataset or just each channel's dataset to calculate
%   ylimits.
%
%   PLOTARRAYWAVEFORMS(...,'YLIMPRCTILE',[MIN MAX])
%   Customize the percentile range used for determining the ylimits.
%   Default is [1 99].
%
%   PLOTARRAYWAVEFORMS(...,'TITLE','FigureTitle')
%   Define a custom title for the figure.
%
%   PLOTARRAYWAVEFORMS(...,'LABELS')
%   PLOTARRAYWAVEFORMS(...,'NOLABELS')
%   Enable (default) or disable channel and electrode labels on each
%   subplot.
%
%   PLOTARRAYWAVEFORMS(...,'SAVE')
%   PLOTARRAYWAVEFORMS(...,'NOSAVE')
%   Enable or disable (default) saving the generated plot.  The default
%   output directory is the current directory, and the default filename
%   will be 'arrayWaveforms'.
%
%   PLOTARRAYWAVEFORMS(...,'OUT[PUTDIRECTORY]',DIRECTORY)
%   Override the default output directory with the value in DIRECTORY.
%
%   PLOTARRAYWAVEFORMS(...,'Q[UIET]')
%   PLOTARRAYWAVEFORMS(...,'V[ERBOSE]')
%   Enable (default) or disable verbose mode, which will print some
%   feedback information to the command window.
%
%   PLOTARRAYWAVEFORMS(...,'YLIMABSOLUTE',[MINVAL, MAXVAL])
%   Enable or disable (default) setting up a YLimits with specific values.
%   If it's empty (default), it will use the settings in ylimPrctile;
%   otherwise, it will set minimum value of y-axis to MINVAL, and its
%   maximum value to MAXVAL. Units are in microvolts.
%
%   See also BLACKROCK.ARRAYMAP.

% process inputs
[varargin,FlagLabel]        = util.argflag('nolabel',varargin,true);
[varargin,FlagVerbose]      = util.argflag('verbose',varargin);
[varargin,FlagSave]         = util.argflag('save',varargin);
[varargin,OutSubDir]        = util.argkeyval('outsubdir',varargin,'ArrayWaveforms',3);
[varargin,Filename]         = util.argkeyval('filename',varargin,sprintf('arrwvfrm_%s',datestr(now,'yyyymmdd_HHMMSS')));
[varargin,histargs]         = util.argkeyval('histargs',varargin,'log',5,{'log','linear'});
[varargin,plotType]         = util.argkeyval('type',varargin,'raw',4,{'raw','hist'});
[varargin,FigureTitle]      = util.argkeyval('title',varargin,'Array Waveforms');
[varargin,nSamples]         = util.argkeyval('nsamples',varargin,48);
[varargin,maxWaveforms]     = util.argkeyval('maxWaveforms',varargin,Inf);
[varargin,ylimScope]        = util.argkeyval('ylimScope',varargin,'global',5,{'global','local'});
[varargin,ylimPrctile]      = util.argkeyval('ylimPrctile',varargin,[1 99]);
[varargin,hFigure]          = util.argkeyval('hFigure',varargin,nan);
[varargin,ButtonDownFcn]    = util.argkeyval('ButtonDownFcn',varargin,@(h,evt)h);
[varargin,plotargs]         = util.argkeyval('plotargs',varargin,{});
[varargin,ylimAbsolute]     = util.argkeyval('ylimAbsolute', varargin, []);
[varargin,nWaveformSamples] = util.argkeyval('nwaveformsamples',varargin,48);
[varargin,colormode]        = util.argkeyval('colormode',varargin,'normal');
[varargin,cmapname]         = util.argkeyval('colormap',varargin,'copper');
[varargin,colordata]        = util.argkeyval('colordata',varargin,nan);
util.argempty(varargin);

% array map
hArray = {};
if isa(map,'Blackrock.ArrayMap')
    hArray = map;
elseif ischar(map) && exist(map,'file')==2 && strcmpi(map(end-(min(length(map),3)):end),'.cmp')
    hArray = Blackrock.ArrayMap(map);
end
assert(~isempty(hArray),'Must provide a map file or Blackrock.ArrayMap object');

% correct orientation for waveforms
if size(waveforms,1)~=nWaveformSamples
    waveforms=waveforms';
end
assert(size(waveforms,1)==nWaveformSamples,'Invalid array size for waveform samples (expected %d waveform samples but found %d)',nWaveformSamples,size(waveforms,1));

% convert array input to cell input
if ~iscell(waveforms)
    
    % save inputs to temporary variables
    wv = waveforms;
    ch = channels;
    
    % build cell array of waveforms
    channels = sort(unique(ch),'ascend');
    waveforms = cell(1,length(channels));
    for cc=1:length(channels)
        waveforms{cc} = wv(:,ch==channels(cc));
    end
    
    % clear temporary variables
    clear wv ch;
    
end
assert(iscell(colordata)&&length(colordata)==length(channels),'Invalid color data');

% make sure input channels and waveforms dimensions agree
assert(length(waveforms)==length(channels),'Must provide waveforms for each entry in channels');

% make sure each cell is 48xN
assert(all(cellfun(@(x)isempty(x)||size(x,1)==nSamples,waveforms)),'If waveforms provided as cell array, each cell must be NSAMPLESxN (or empty array)');

% figure name, handle, colormap, handle to all subplots
if ~ishandle(hFigure) && isnan(hFigure)
    hFigure = figure(...
        'Visible','on',...
        'NumberTitle','off',...
        'Name',FigureTitle,...
        'PaperPositionMode','auto',...
        'InvertHardcopy','off',...
        'Color',[1 1 1],...
        'Position',[50 50 1200 800]);
end
num_days = [min(cat(1,colordata{:})) max(cat(1,colordata{:}))];
cmap = feval(cmapname,diff(num_days)+1);

% find global min/max for ylimits
if strcmpi(ylimScope,'global')
    
    % concatenate all data together
    data = [waveforms{:}];
    data = data(:);
    
    % get rid of nans
    data(isnan(data)) = [];
    
    % default ylims
    if isempty(ylimAbsolute)
        YLimits = [-100 100];
    else
        YLimits = ylimAbsolute; % if there is ylimAbsolute input, then set it as YLimits
    end
    
    % calculate ylims from remaining data
    if ~isempty(data)
        YLimits = prctile(data(:),ylimPrctile);
    end
    
    % free up memory
    clear data;
    if FlagVerbose, fprintf('Calculated global min/max for ylims: [%d,%d]',YLimits); end
end

% specify a channel to print out tick marks and labels on y-axis
rows = arrayfun(@(x)hArray.ch2row(x), channels);
ch_maxRow = channels(rows == max(rows));    % Channels in the last row; last row corresponds to the row on the top of the screen
[~, chIdx_maxRow_minCol] = min(arrayfun(@(x)hArray.ch2col(x), ch_maxRow)); % Index of the channel in the first column among ch_maxRow. It may not correspond to col=0, depending on the shape of the array map
chosenCh = ch_maxRow(chIdx_maxRow_minCol);  % Chosen channel on the top left corner; last row, 1st column


% loop over all channels
ax = nan(1,length(channels));
for cc = 1:length(channels)
    ax(cc) = hArray.getChannelSubplot(channels(cc),'parent',hFigure,'innerspacing',0.001,'outerspacing',0.01,'ButtonDownFcn',ButtonDownFcn);
    cla(ax(cc));
    
    % find waveforms for this channel
    %idx = find(channels==cc);
    wv = waveforms{cc};
    if FlagVerbose, fprintf('Processing %d waveforms for channel %d\n',size(wv,2),channels(cc)); end
    
    % limit number of waveforms displayed
    if maxWaveforms<Inf
        wv(:,(maxWaveforms+1):end)=[];
    end
    
    % handle empty case
    if isempty(wv), wv=zeros(nSamples,1); end
    
    % find local min/max for ylimits
    if strcmpi(ylimScope,'local')
        YLimits = prctile(wv(:),ylimPrctile);
        if FlagVerbose, fprintf('Calculated local min/max for channel %d ylims: [%d,%d]',channels(cc),YLimits); end
    end
    
    % plot raw waveforms or histograms
    switch lower(plotType)
        case 'raw'
            
            % plot the waveforms
            h = plot(1:nSamples,wv,'Parent',ax(cc),'ButtonDownFcn',ButtonDownFcn,'UserData',struct('Channel',channels(cc)),plotargs{:});
            set(h,{'color'},num2cell(cmap(colordata{cc},:),2))
            set(ax(cc),'XLim',[1 nSamples],'YLim',YLimits);
            set(ax(cc),'Color',[1 1 1]);
            set(ax(cc),'XTick',[],'YTick',[]);
            set(ax(cc),'box','on');
            
            % print ylabels
            if channels(cc) == chosenCh
                tk = YLimits;
                numDigit = floor(log10(diff(tk)));
                tk(1) = round(tk(1)+0.15*diff(tk),-numDigit);
                tk(2) = round(tk(2)-0.15*diff(tk),-numDigit);
                if diff(tk)==0 || tk(1)<YLimits(1) || YLimits(2)<tk(2)  
                    tk = YLimits;
                    tk(1) = round(tk(1)+0.15*diff(tk),-numDigit+1);
                    tk(2) = round(tk(2)-0.15*diff(tk),-numDigit+1);
                end
                set(ax(cc),'YTick',tk,'FontSize',7);
                ylabel('µV')
            end
            labelColor = [0.1 0.1 0.1];
        case 'hist'
            
            % calculate and display histogram
            [counts,tind,xind] = util.histxt(wv',histargs{:},plotargs{:});
            imagesc(tind,xind,counts,'Parent',ax(cc),'ButtonDownFcn',ButtonDownFcn,'UserData',struct('Channel',channels(cc)));
            axis(ax(cc),'xy');
            set(ax(cc),'XLim',[1 nSamples],'YLim',YLimits);
            set(ax(cc),'Color',cmap(1,:));
            set(ax(cc),'XTick',[],'YTick',[]);
            set(ax(cc),'box','on');
            labelColor = [1 1 1];
        otherwise
            error('unknown plot type ''%s''',plotType);
    end
    
    % print channel/electrode number
    if FlagLabel
        
        % set tag identifier so we can pull this up in the future
        labelTag = sprintf('text_channelId_c%d',channels(cc));
        
        % position and string
        upleft = [1 round(0.75*YLimits(2))];
        labelText = sprintf('e%d/c%d',hArray.ch2el(channels(cc)),channels(cc));
        
        % see if tag already exists
        h = findobj(ax(cc),'tag',labelTag);
        if ~isempty(h)
            
            % just update the string and position
            set(h,'String',labelText,'Position',[upleft(1) upleft(2) 0]);
        else
            
            % create the text object
            text(upleft(1),upleft(2),labelText,...
                'Parent',ax(cc),...
                'FontSize',8,...
                'Color',labelColor,...
                'Tag',labelTag);
        end
    end
end

% % plot something darker into the disconnected electrodes
% h2 = getEmptySubplots(hArray,'innerspacing',0.002);
% for Empty = 1:length(h2)
%     imagesc(1*ones(100,100),'Parent',h2(Empty),[0 1]);
%     set(h2(Empty),'XTick',[],'YTick',[]);
% end

% save figure
if FlagSave
    plot.save(hFigure,'subdir',OutSubDir,'outbase',Filename);
end

end % END function plotArrayWaveforms