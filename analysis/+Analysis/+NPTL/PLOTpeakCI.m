% for plotting the peaks and CI

N=100;
C=linspecer(N);
nme=fields(Peak);
betaMin=46; betaMax=40; spkMin=10; spkMax=4;
spots=[spkMin; spkMax; betaMin; betaMax];

numCh=[2:length(nme)-4];
subN1=sqrt(length(numCh));
if round(subN1)<subN1
    subN1=floor(subN1); 
    subN2=subN1+1; 
elseif subN1==round(subN1) %if sqrt is whole
    subN2=subN1;
else
    subN1=ceil(subN1);
    subN2=subN1+1; 
end %this is fancy math to make a subplot the right number
for jj=1:2:length(numCh) %do all of the channels, go by 2 to get the spikes then the bands
    subplot(subN1, subN2, jj);
    idxColor=7;
       loc=spots(1);
        pk=Peak(loc).(nme{numCh(jj)});
        pkCIL=Peak(loc+1).(nme{numCh(jj)});
        pkCIH=Peak(loc+2).(nme{numCh(jj)});
        plot(pk, 0.1, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idxColor,:))
        hold on
        yy=pkCIL:pkCIH;
        zz=zeros(size(yy))+0.1;
        plot(yy, zz, 'LineWidth', 2, 'Color', C(idxColor-3,:))
        idxColor=idxColor+20;
        
        loc=spots(2);
        pk=Peak(loc).(nme{numCh(jj)});
        pkCIL=Peak(loc+1).(nme{numCh(jj)});
        pkCIH=Peak(loc+2).(nme{numCh(jj)});
        plot(pk, 0.2, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idxColor,:))
        hold on
        yy=pkCIL:pkCIH;
        zz=zeros(size(yy))+0.2;
        plot(yy, zz, 'LineWidth', 2, 'Color', C(idxColor-3,:))
        idxColor=idxColor+20;
        
        loc=spots(3);
        pk=Peak(loc).(nme{numCh(jj+1)});
        pkCIL=Peak(loc+1).(nme{numCh(jj+1)});
        pkCIH=Peak(loc+2).(nme{numCh(jj+1)});
        plot(pk, 0.3, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idxColor,:))
        hold on
        yy=pkCIL:pkCIH;
        zz=zeros(size(yy))+0.3;
        plot(yy, zz, 'LineWidth', 2, 'Color', C(idxColor-3,:))
        idxColor=idxColor+20;
        
        loc=spots(4);
        pk=Peak(loc).(nme{numCh(jj+1)});
        pkCIL=Peak(loc+1).(nme{numCh(jj+1)});
        pkCIH=Peak(loc+2).(nme{numCh(jj+1)});
        plot(pk, 0.4, 's', 'MarkerSize', 10, 'LineWidth', 4, 'Color', C(idxColor,:))
        hold on
        yy=pkCIL:pkCIH;
        zz=zeros(size(yy))+0.4;
        plot(yy, zz, 'LineWidth', 2, 'Color', C(idxColor-3,:))
        idxColor=idxColor+20;

ax=gca;
ax.YLim=[0 0.6];
if jj==(subN1-1)*subN2+1 %bottom corner.
    ax.XLabel.String=('Time (ms)');
else
    ax.XLabel.String=[];
end

ax.YTickLabel=[];
legend({'Spike Minima', 'Spike Maxima', 'Beta Minima', 'Beta Maxima'});
tempT=nme{numCh(jj)};
titleN=tempT(1:7);
title(titleN);
end 

sgtitle('Spike and Beta maxima and Minima');
