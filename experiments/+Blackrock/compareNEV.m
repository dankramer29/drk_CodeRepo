function compareNEV(nvfile1,nvfile2)
% COMPARENEV compare the neural data contents of two NEV files

% process the inputs
assert(exist(nvfile1,'file')==2,'Could not find input 1: %s',nvfile1);
assert(exist(nvfile2,'file')==2,'Could not find input 2: %s',nvfile2);
[~,nvbase1,nvext1] = fileparts(nvfile1);
[~,nvbase2,nvext2] = fileparts(nvfile2);
nvname1 = sprintf('%s%s',nvbase1,nvext1);
nvname2 = sprintf('%s%s',nvbase2,nvext2);

% create NEV objects
nv1 = Blackrock.NEV(nvfile1);
nv2 = Blackrock.NEV(nvfile2);

% read data
dt1 = nv1.read('all','UniformOutput',false);
dt2 = nv2.read('all','UniformOutput',false);

% get channel info
ch1 = [nv1.ChannelInfo.ChannelID];
ch2 = [nv2.ChannelInfo.ChannelID];
chans = union(ch1(:),ch2(:));

% identify block structure
[~,blk1] = max(cellfun(@(x)length(x.Channels),dt1.Spike));
[~,blk2] = max(cellfun(@(x)length(x.Channels),dt2.Spike));
assert(blk1==blk2,'The two files should have the same block with the most spike events');
blk = blk1;

% bar plot of number of spikes per channel
n1 = histcounts(dt1.Spike{blk}.Channels,[min([nv1.ChannelInfo.ChannelID])-1 [nv1.ChannelInfo.ChannelID]]+0.5);
n2 = histcounts(dt2.Spike{blk}.Channels,[min([nv2.ChannelInfo.ChannelID])-1 [nv2.ChannelInfo.ChannelID]]+0.5);
figure('Position',[125 125 1000 500]);
ax = subplot(211);
clrs = get(gca,'ColorOrder');
h1 = bar(ax,chans(:)',[n1(:) n2(:)]);
set(h1(1),'FaceColor',clrs(1,:));
set(h1(2),'FaceColor',clrs(2,:));
title('Number of Spike Events Per Channel');
xlabel('Channel');
ylabel('Spike Event Count');
legend({nvname1,nvname2});
ax = subplot(212);
h2 = bar(ax,chans(:)',abs(n1(:)-n2(:)));
set(h2,'BarWidth',h1(1).BarWidth/2);
set(h2,'FaceColor',h1(1).FaceColor);
set(h2,'EdgeColor',h1(1).EdgeColor);
xlabel('Channel');
ylabel('Difference in Spike Event Count')

% waveforms per channel
for ch=chans(:)'
    
    % get spikes from each file
    idx_ch1 = dt1.Spike{blk}.Channels==ch;
    idx_ch2 = dt2.Spike{blk}.Channels==ch;
    if ~any(idx_ch1) && ~any(idx_ch2)
        fprintf('No spikes on Channel %d for either file\n',ch);
        continue;
    end
    
    % create figure
    figure('position',[100 100 800 500])
    
    % plot mean + 95% c.i.
    if nnz(idx_ch1)>0
        mn1 = mean(dt1.Spike{blk}.Waveforms(:,idx_ch1),2);
        ci1 = bootci(5e2,{@nanmean,dt1.Spike{blk}.Waveforms(:,idx_ch1)'});
        plt.shadedErrorBar(1:48,mn1,[ci1(1,:)-mn1(:)'; mn1(:)'-ci1(2,:)],'lineprops',{'-','color',clrs(1,:)},'transparent',1);
    end
    if nnz(idx_ch2)>0
        mn2 = mean(dt2.Spike{blk}.Waveforms(:,idx_ch2),2);
        ci2 = bootci(5e2,{@nanmean,dt2.Spike{blk}.Waveforms(:,idx_ch2)'});
        plt.shadedErrorBar(1:48,mn1,[ci2(1,:)-mn2(:)'; mn2(:)'-ci2(2,:)],'lineprops',{'-','color',clrs(2,:)},'transparent',1);
    end
    box on;
    xlim([1 48]);
    yl = get(gca,'YLim');
    set(gca,'YLim',[yl(1)-0.2*diff(yl) yl(2)+0.2*diff(yl)]);
    legend({...
        sprintf('%s (N=%d) (95% c.i.)',nvname1,nnz(idx_ch1)),...
        sprintf('%s (N=%d) (95% c.i.)',nvname2,nnz(idx_ch2))},'location','SouthEast');
    title(sprintf('Spike Waveform (ch %d blk %d)',ch,blk));
end