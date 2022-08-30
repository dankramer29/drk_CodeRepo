Incr = 1000;
IdxStart = 1;
IdxEnd = 20001;
h = figure('Position', [-1920 350 960 900]);

% subplot(10,1,1);

%plot(LAmygRelT(IdxStart:IdxEnd,1), LAmygTest(IdxStart:IdxEnd,:));
plot(LAmygRelT(IdxStart:IdxEnd,1), LAmygAvg(IdxStart:IdxEnd,:));
legend('show')

% subplot(10,1,2);
% % ax = gca;
% % ax.YLim = [-500 500];
% % ax.XLim = [IdxStart IdxEnd];
% p2 = plot(LAmygRelT(IdxStart:IdxEnd,1), LAmygTest(IdxStart:IdxEnd,2));

for sections = 1:(size(LAmygRelT,1)/Increment)
    IdxStart = IdxStart + Incr;
    IdxEnd = IdxEnd + Incr;
%     plot(LAmygRelT(IdxStart:IdxEnd,1), LAmygTest(IdxStart:IdxEnd,:));
    plot(LAmygRelT(IdxStart:IdxEnd,1), LAmygAvg(IdxStart:IdxEnd,:));
%     p1.XData = LAmygRelT(IdxStart:IdxEnd,:);
%     p1.YData = LAmygTest(IdxStart:IdxEnd,:);
%     p2.XData = LAmygRelT(IdxStart:IdxEnd,1);
%     p2.YData = LAmygTest(IdxStart:IdxEnd,1);
    legend('show')
    ax = gca;
    %ax.XLim = [IdxStart/Incr IdxEnd/Incr];
    ax.YLim = [-500 500];
    ax.XLim = [IdxStart/2000 IdxEnd/2000];
    drawnow
    pause(0.5)
end