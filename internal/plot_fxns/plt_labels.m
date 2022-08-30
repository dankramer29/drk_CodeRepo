function plt_labels( mx, phase_length, ch, task, ax, xl )
%plt_labels to simplify a line that adds these labels and marks
%   Detailed explanation goes here

%mx(1,1)=max(data.type1.data(phase_length(1,1):end,ch));
%mx(1,2)=max(data.type2.data(phase_length(1,1):end,ch));
%mx=max(mx);
for ii=2:length(phase_length)
    plot([phase_length(1,ii)-phase_length(1,1), phase_length(1,ii)-phase_length(1,1)], [0, mx+1], 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':')
end


plzero=phase_length-phase_length(1,1);
ax.XTick=plzero;
ax.XTickLabels=plzero*.05;
h1=get(gca,'XTick');
h2=get(gca,'XTickLabel');
h3=length(h1);
xdiff=h1(2)-h1(1); % assuming uniform step interval in x-axis
h1=h1+0.2*xdiff; % this factor of 0.2 can be adjusted to move labels around
ax.YLim=([0 mx+1]);
ax.XLim=([0 xl]);
%0.3 is how far below the line the names exist
for nn=1:h3-1
    text(h1(nn),-0.3,task.phaseNames(:,nn), 'FontSize', 8, 'FontWeight' , 'bold'  );
end


end

