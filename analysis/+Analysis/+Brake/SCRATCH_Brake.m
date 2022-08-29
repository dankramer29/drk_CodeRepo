%basic script for accelerometer data with ET patients
%% run this section to preprocess the data for analysis.

load('C:\Users\kramdani\Dropbox\My PC (NSG-M-4P72P53)\Documents\Local Data\AccelerometerETData\Case 2\RT1D10.235F0005.mat')

fsSpk=44000;
fsPos=2750;

timeCutSt=7.5; %start and end of the block you want to look at
timeCutEnd=11; 


posTst=timeCutSt*fsPos;
spkTst=timeCutSt*fsSpk;
posTEnd=timeCutEnd*fsPos;
spkTEnd=timeCutEnd*fsSpk;

xx=CACC_3___01___Sensor_1___X;
yy=CACC_3___02___Sensor_1___Y;
zz=CACC_3___03___Sensor_1___Z;
accelDtemp(:,1)=xx;
accelDtemp(:,2)=yy;
accelDtemp(:,3)=zz;



spkData=CSPK_01(spkTst:spkTEnd);
posData=double(accelDtemp(posTst:posTEnd, :));



tmPos=linspace(0, length(posData)/(fsPos/1000), length(posData));

posDataT=posData-mean(posData);


%convert position to velocity and acceleration

posDataV=diff(trlT);
%convert to velocity
posDataV(:,1)=cumtrapz(tmPos, posDataT(:,1));
posDataV(:,2)=cumtrapz(posData(:,2), tmPos);
posDataV(:,3)=cumtrapz(posData(:,3), tmPos);

%convert to velocity different way
dt=1/fsPos;
dtVel=posDataT(:,1).*dt;
posDataV2(:,1)=cumsum([dtVel]);

figure
plot(tmPos, posDataV)
figure
plot(tmPos, posData(:,1))


%% cross correlation
[P1,Q1]=rat(fsPos/50);
spkRateSmoothR=resample(spkRateSmooth, P1, Q1);
%normalize the signals
spkRateSmoothN=spkRateSmoothR./max(spkRateSmoothR);
posDataN=(posDataSm./max(abs(posDataSm),[],1).*-1);

[crossCorr, Lag]=xcorr(spkRateSmoothN, posDataN(:,3));
figure 
plot(Lag/fsPos, Cc)

% same but downsample instead of upsample, shows the same thing

dwns=floor(length(posDataSm)/length(spkRateSmooth));
posDataDownSample=downsample(posDataSm, dwns);
if length(posDataDownSample)~=length(spkRateSmooth)
    diff=length(posDataDownSample)-length(spkRateSmooth);
    posDataDownSample(end-diff+1:end, :)=[];
end
figure
plot(tmSpk, posDataDownSample);
hold on
plot(tmPos, posDataSm);
%normalize the signals
spkRateSmoothN=spkRateSmooth./max(spkRateSmooth);
posDataDownSampleN=(posDataDownSample./max(abs(posDataDownSample),[],1).*-1);
figure
plot(tmSpk, posDataDownSampleN(:,1));
figure
plot(tmSpk, posDataDownSample(:,1));
for ii=1:3
[crossCorr(:,ii), crossCorrLag(:,ii)]=xcorr(spkRateSmoothN, posDataDownSampleN(:,ii));
end
figure
stem(crossCorrLag(:,1),crossCorr(:,1))

%
td=finddelay(spkRateSmoothN, posDataN);

%% mscohere
%doesnt' work, need to figure out how to use mscohere first
cohereD=mscohere(posDataDownSampleN(:,1), spkRateSmoothN, 10, 2, 100);
figure
plot(cohereD )


%%psd


params = struct;
params.Fs = fsPos;   % in sampling rate (not Hz)
params.fpass = [0 10];     % [minFreqz maxFreq] in Hz, remember you can change here to keep it to a smaller size to highlight lower frequencies.
params.tapers = [5 9];
params.pad = 0;
params.trialave = 0;
   % size and step size for windowing continuous data

[Spos, fpos]=chronux.ct.mtspectrumc(posDataSm(:,1), params);
params.Fs=50;
[Sspk, fspk]=chronux.ct.mtspectrumc(spkRateSmooth(:,1), params); 
figure
plot(fpos,Spos)
hold on
figure
plot(fspk, Sspk)

%%coherence
[P1, f1]=periodogram(signalX, [],[],1000, 'power');
[P2, f2]=periodogram(signalY, [],[],1000, 'power');
figure
plot(f1, P1)
figure
hold on
plot(f2, P2)

[cxy, ff]=mscohere(signalX, signalY, hamming(50), [], [], 1000, 'mimo');
figure
plot(ff, cxy)

[P1, f1]=periodogram(posDataSm(:,1),[],[1:10],fsPos, 'power');
[P2, f2]=periodogram(spkRateSmooth, [],[1:10],50,'power');
figure
plot(f1, P1)
figure
plot(f2, P2)
params = struct;
params.Fs = 1000/win;   % in sampling rate (not Hz)
params.fpass = [0 30];     % [minFreqz maxFreq] in Hz, remember you can change here to keep it to a smaller size to highlight lower frequencies.
params.tapers = [5 9];
params.pad = 0;
params.trialave = 0;
params.win = [0.2 0.05];   % size and step size for windowing continuous data

[Cc, phi, S12, s1, s2, fc]=chronux.ct.coherencyc(posDataDownSampleN(:,1), spkRateSmoothN, params);
figure
plot(fc,Cc);
[C,phi,S12,S1,S2,t,f]=chronux.ct.cohgramc(posDataDownSampleN(:,1), spkRateSmoothN, params.win, params)
figure
plot(C);
%%
sampleT=length(xx);

fs=CACC_3___01___Sensor_1___X_KHz*1000; %samples/second

totTime=length(CACC_3___01___Sensor_1___X)/fs; %total time in seconds

tt=linspace(0, totTime, sampleT);

tst=4;
tst=tst*fs; %convert to seconds
tpl=18;
tpl=tpl*fs;
figure
hold on
plot(tt(tst:tpl), xx(tst:tpl))
plot(tt(tst:tpl), yy(tst:tpl))
plot(tt(tst:tpl), zz(tst:tpl))
xlabel('time (s)');
%figure
%plot3(xx(tst:tpl),yy(tst:tpl),zz(tst:tpl));

figure
%comet3(xx(tst:tpl),yy(tst:tpl),zz(tst:tpl));

%%

fsPos=2750;

accelDtemp(:,1)=xx;
accelDtemp(:,2)=yy;
accelDtemp(:,3)=zz;
posData=accelDtemp;

posDataSm=smoothdata(posData, 'gaussian', fsPos/10); %smooth the jitter in the accel data

[maxX, maxLocX]=findpeaks(posDataSm(:,1));
[minX, minLocX]=findpeaks(-posDataSm(:,1));
[maxY, maxLocY]=findpeaks(posDataSm(:,2));
[minY, minLocY]=findpeaks(-posDataSm(:,2));
[maxZ, maxLocZ]=findpeaks(posDataSm(:,3));
[minZ, minLocZ]=findpeaks(-posDataSm(:,3));


    

%%


posData=accelDtemp;

%xxx=zz(2000:2000+2750*10); 

xs=smoothdata(xx,'gaussian',275*1);
ys=smoothdata(yy,'gaussian',275*1);
zs=smoothdata(zz,'gaussian',275*1);
accelDtemp(:,1)=xs;
accelDtemp(:,2)=ys;
accelDtemp(:,3)=zs;
alls=mean(accelDtemp, 2);
figure
hold on
plot(tt(tst:tpl), xs(tst:tpl))
plot(tt(tst:tpl), ys(tst:tpl))
plot(tt(tst:tpl), zs(tst:tpl))
plot(tt(tst:tpl), alls(tst:tpl))
xlabel('time (s)');
figure
plot3(xs(tst:tpl),ys(tst:tpl),zs(tst:tpl));
figure
comet3(xs(tst:tpl),ys(tst:tpl),zs(tst:tpl));

pks=findpeaks(xs);

%%
posDataSmN=posDataSm-mean(posDataSm);
posDataSmN=posDataSmN/10;

%%
tt=3000;
timeSpk=tt/win;
timePos=tt*fsPos/1000;
shortSpkRateSmooth=spkRateSmooth(timeSpk:end-timeSpk);
shortPosData=posDataSm;

%normalize
spkN=spkRateSmooth./max(spkRateSmooth);
posN=posDataSm./max(posDataSm(:,1));

%zscore and plot them all together
spikeMsRasterP=spikeMsRaster;
spikeMsRasterP(spikeMsRasterP==0)=NaN;
spkZ=(spkRateSmooth-mean(spkRateSmooth))./std(spkRateSmooth);
posZ=(posDataSm-mean(posDataSm,1))./std(posDataSm,[],1);

figure
plot(spikeMsRasterP, 'Marker', '.', 'LineStyle', 'none')
hold on
plot(tmSpk, spkZ);
plot(tmPos, posZ(:,1));


%% plot position and spk data
dwns=floor(length(posDataSm)/length(spkRateSmooth));
posDataDownSample=downsample(posDataSm, dwns);
if length(posDataDownSample)~=length(spkRateSmooth)
    diff=length(posDataDownSample)-length(spkRateSmooth);
    posDataDownSample(end-diff, :)=[];
end
figure
yyaxis right
plot(tmSpk, spkRateSmooth);
hold on
yyaxis left
plot(tmSpk, posDataDownSample(:,1));

%% other plots
%show the maximum and minimum on the actual plot
clear mxL
clear mnL
mxL(:,1)=maxLocMs;
mxL(:,2)=maxX;
mnL(:,1)=minLocMs;
mnL(:,2)=minX;

figure
hold on
plot(tmPos, posDataSm(:,1))
plot(mxL(:,1), mxL(:,2), 'o')
plot(mnL(:,1), -mnL(:,2), 'o')


%% check spike rates

figure
spikeMsRasterT=spikeMsRaster*50;
plot(spikeMsRaster, '.')
hold on
plot(tmSpk, spkRateSmooth)

%% phase angle and spike field coherence estimates
%essentially, for each cycle up and down, find the phase of the cycle it's
%contained in, which means normalize each up and down to a phase of sin
%wave cycle in radians, and then do a polar plot, so you end up with rho as
%the number of spikes in that bin of the phase.

theta=linspace(0, 360, 20);
thetaR=deg2rad(theta);
spikeCountTot=sum(spikeCount,2);
figure
polarplot(thetaR, spikeCountTot);
ax=gca;

if minPeaksFirst
ax.ThetaZeroLocation='bottom';
ax.ThetaTickLabel{1}='0 bottom Peak';
ax.ThetaTickLabel{7}='180 top Peak';
else
ax.ThetaZeroLocation='top';
ax.ThetaTickLabel{1}='0 top Peak';
ax.ThetaTickLabel{6}='180 bottom Peak';    
end


%%
params = struct;
params.Fs = fsPos;   % in Hz
params.fpass = [0 15];     % [minFreqz maxFreq] in Hz
params.tapers = [5 9]; %second number is 2x the first -1, and the tapers is how many ffts you do.
params.pad = 0;
%params.err = [1 0.05];
params.err=0;
params.trialave = 0; % average across trials

win=fsPos; %take a window of 1 s

[S, F]=chronux.ct.mtspectrumc(posDataSm(:,1), params);
figure
plot(F,S)

% [Ss, Ff]=chronux.ct.mtspecgramc(posDataSm(:,1),win,params);
% figure
% imagesc(Ff,tmPos,Ss');
% axis xy

ff=[0:10];
[pxx,w, pxxc]=periodogram(posDataSm(1:2750,1), [], ff, 2750);
figure
plot(ff, 10*log10(pxx))




Fs = 1000;            % Sampling frequency
T = 1/Fs;             % Sampling period       
L = 1500;             % Length of signal
t = (0:L-1)*T;        % Time vector

S = 0.7*sin(2*pi*50*t) + sin(2*pi*120*t);

Y = fft(S);

P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;
figure
plot(f,P1) 

    
L=length(posDataSm(:,1));    
Y = fft(posDataSm(:,1));
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = (2750)*(0:(L/2))/L;
figure
plot(f,P1) 