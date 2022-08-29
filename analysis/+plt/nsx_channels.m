function fig = nsx_channels(ns,varargin)

% process inputs
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
if ~found_debug,debug=Debug.Debugger('plot_channels');end
if ischar(ns)
    assert(exist(ns,'file')==2,'Must provide valid path to existing file');
    ns = Blackrock.NSx(ns,debug);
end
[~,packet] = max(ns.PointsPerDataPacket);
[varargin,packet] = util.argkeyval('packet',varargin,packet);
[varargin,win] = util.argkeyval('win',varargin,[1 ns.PointsPerDataPacket(packet)]);
[varargin,channels] = util.argkeyval('channels',varargin,[ns.ChannelInfo.ChannelID],2);
[varargin,fig,~,found_fig] = util.argkeyval('figure',varargin,[],3);
[varargin,freqband] = util.argkeyval('freqband',varargin,[]);
[varargin,flt] = util.argkeyval('filter',varargin,[]);
[varargin,spacing] = util.argkeyval('spacing',varargin,2);
[varargin,offsets] = util.argkeyval('offsets',varargin,[]);
util.argempty(varargin);

% read data
dt = ns.read('packet',packet,'channels',channels,'points',win,'ref','packet');
dt = dt';
if ~isempty(freqband) || ~isempty(flt)
    if ~isempty(freqband)
        assert(freqband(2)<=(ns.Fs/2),'Requested frequency band (%s) violates Nyquist rate for NSx sampling rate (%d)',util.vec2str(freqband),ns.Fs);
    end
    if isempty(flt)
        freq1_stop = max(eps,floor(0.9*freqband(1)));
        if freqband(1)-freq1_stop<1
            new_freqband1 = freq1_stop+1;
            debug.log(sprintf('Requested low passband (%d Hz) is too low for transition band. Filter will be designed for transition band [%d %d] Hz.',freqband(1),freq1_stop,new_freqband1),'warn');
            freqband(1) = new_freqband1;
        end
        freq1 = [freq1_stop freqband(1)];
        freq2_stop = ceil(1.1*freqband(2));
        if freq2_stop-freqband(2)<1
            freq2_stop = freq2_stop+1;
        end
        if freq2_stop>ns.Fs/2
            freq2_stop = ns.Fs/2;
            new_freqband2 = freq2_stop-1;
            debug.log(sprintf('Requested high passband (%d Hz) is too high for transition band below Nyquist rate. Filter will be designed for transition band [%d %d] Hz.',freqband(2),freq2_stop,new_freqband2),'warn');
            freqband(2) = new_freqband2;
        end
        freq2 = [freqband(2) freq2_stop];
        flt = designfilt('bandpassiir',...
            'DesignMethod','ellip',...
            'StopbandFrequency1',freq1(1),...
            'PassbandFrequency1',freq1(2),...
            'PassbandFrequency2',freq2(1),...
            'StopbandFrequency2',freq2(2),...
            'StopbandAttenuation1',40,...
            'PassbandRipple',0.01,...
            'StopbandAttenuation2',40,...
            'SampleRate',ns.Fs);
    end
    dt = filtfilt(flt,dt);
else
    freqband = [0 ns.Fs/2];
end

% create figure and axes
if ~found_fig
    fig = figure(...
        'PaperPositionMode','auto',...
        'Position',[100 100 1200 800]);
end
ax = axes(fig);

% add in offsets
if isempty(offsets)
    pct = prctile(dt,[10 90]);
    match = sum(diff(pct))/length(channels);
    offsets = cumsum([0 pct(2,2:end)+pct(1,1:end-1)+spacing*match]);
end
assert(isnumeric(offsets)&&length(offsets)==size(dt,2),'Invalid data offsets');
for kk=2:length(offsets)
    df = diff(offsets(kk-1:kk));
    if df<=0
        offsets(kk:end) = offsets(kk:end) + max(-df+1,nanmedian(diff(offsets)));
    end
end
dt = dt + offsets;

% compute time vector
t = ns.Timestamps(packet) + (win(1)-1)/ns.Fs + (0:(1/ns.Fs):(win(2)/ns.Fs-1/ns.Fs));

% plot the data
plot(ax,t,dt);
xlim(ax,t([1 end]));
pct = prctile(dt,[0.05 99.95]);
match = sum(diff(pct))/length(channels);
yl1 = floor(pct(1,1)-match/2);
yl2 = ceil(pct(2,end)+match/2);
ylim(ax,[yl1 yl2])
centers = nanmedian(dt);
set(ax,'YTick',centers,'YTickLabels',{ns.ChannelInfo(channels).Label});
title(ax,sprintf('%s (packet %d) %s Hz',ns.SourceBasename,packet,util.vec2str(freqband)));
