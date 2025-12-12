for rr = 10:20
    xx(rr,:)= mean(shuffleMatrix{jj}(:,:,rr),1);
end

figure
plot(xx')

%quick raster
plot(spk(800000:820000), 'marker','.','linestyle','none','MarkerSize', 4)


jj=1;
xx=spkITI.posSection(jj,:);
xx=double(xx);
xx(xx==0)=NaN;
yy=spkITI.smMean;
zzP=shuffleHist{jj,2};
zzzP = repmat(zzP,1,length(yy));
zzN=shuffleHist{jj,3};
zzzN = repmat(zzN,1,length(yy));

%plot the individual smooth mean units

x1 = jjj;
xx=posSection(x1,:);
zz=spk.spk{x1};
yy=smMean(x1,:);
xxx=shuffleHist{x1,2};
zzz = repmat(xxx,1,length(yy));
yyy=shuffleHist{x1,3};
x2 = repmat(yyy,1,length(yy));

figure
subplot(3,1,1)
plot(xx)
hold on
plot(yy)
plot(zzz)
plot(x2)
ylim([0 max(yy)+xxx])
subplot(3,1,2)
plt.raster_plot(zz)
subplot(3,1,3)
histogram(shuffleHist{x1,1}, 40)
%%

for zz = 60:70

figure
xx= spkStimOn.spk{179,1}(zz,:);
yy= spkStimOn.spkRateSm{179,1}(zz,:);
plot(yy)
hold on
plot(xx, 'marker','.','linestyle','none','MarkerSize', 4)

xx = spkStimOn.spk{zz,1}(ii,1:100);
nansum(xx)
end

zzz=mean(spkStimOn.spkRateSm{2});
figure
plot(zzz)

xxx=round(unitSpikesCl{jj}*1000);
yyy=find(xxx>900000 & xxx < 901000);
zzz = zeros(1,round(lastSpikeTime*1000));
zzz(xxx) = 1;
xx = zzz(900000:901000);
xx=tempAllSize(900000:901000);
zz = find(unitSpikesCl{jj}(:)>900 & unitSpikesCl{jj}<901);
yy=unitSpikesCl{jj}(unitSpikesCl{jj}(:)>900 & unitSpikesCl{jj}<901);
figure
plot(xx, 'marker','.','linestyle','none','MarkerSize', 4)
ylim([0.5, 2])


%plot the significant units
x1 = jjj;
xx=posSection(x1,:);
zz=spkStimOn.spk{x1};
yy=smMean(x1,:);
xxx=shuffleHist{x1,2};
zzz = repmat(xxx,1,length(yy));
yyy=shuffleHist{x1,3};
x2 = repmat(yyy,1,length(yy));

figure
subplot(3,1,1)
plot(xx)
hold on
plot(yy)
plot(zzz)
plot(x2)
ylim([0 max(yy)+xxx])
subplot(3,1,2)
plt.raster_plot(zz)
subplot(3,1,3)
histogram(shuffleHist{x1,1}, 40)
