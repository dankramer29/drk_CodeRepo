 if mod(S.t,16)==0;
set(S.pl,'YData',S.Signals(S.vch,:))
    set(S.implot1,'YLim',[-200 100])
    set(S.implot1,'XLim',[0 S.fs*S.T])
end
set(S.space,'XData',[S.N(1,:) S.x])
set(S.space,'YData',[S.N(2,:) S.y])
set(S.space,'ZData',[S.N(3,:) S.z])
set(S.splot,'XLim',[-1 1])
set(S.splot,'YLim',[-1 1])
set(S.splot,'ZLim',[-1 1])