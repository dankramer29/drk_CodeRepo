function chunk(blc,tm,ch)

data = blc.read('time',tm,'channels',ch);
data = data(:,end:-1:1);
sd = nanmean(std(data));
t = tm(1) + (0:(1/blc.SamplingRate):(size(data,1)/blc.SamplingRate-1/blc.SamplingRate));

set(0,'units','pixels');
res = get(0,'screensize');
pos(1) = res(1) + 0.1*(diff(res([1 3]))+1); % left
pos(2) = res(2) + 0.25*(diff(res([2 4]))+1); % bottom
pos(3) = 0.8*res(3); % width
pos(4) = 0.6*res(4); % height
figure('Position',pos,'PaperPositionMode','auto');
axes('Position',[0.05 0.05 0.9 0.9]);
plot(t,-data + 5*sd*repmat(0:size(data,2)-1,size(data,1),1)); axis xy;
%plot(t,data + 5*sd*repmat(0:size(data,2)-1,size(data,1),1)); axis xy;
set(gca,'YTick',5*sd*(0:size(data,2)-1),'YTickLabel',arrayfun(@(x)sprintf('%d',x),size(data,2):-1:1,'UniformOutput',false));
ylim([-5*sd 5*sd*size(data,2)+1]);
xlim(t([1 end]));

title(sprintf('%s / ch %d-%d / %g-%g sec',blc.SourceBasename,ch(1),ch(end),tm(1),tm(2)),'interpreter','none');