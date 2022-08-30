function [spikeData, peakAmp] = tremorAlign(spkData, posData, varargin)
%tremorAlign is the workhorse of data tremor alignment of kinematics to
%neural  alignment
%   
%   Inputs
%       spkData - raw spike data filtered with typical low and high pass
%       filters from the AO
%       posData - should be in x,y,z and position, not accel or velocity
%   Outputs
%        spikeData - all of the spike outputs from the raw voltage
        

[varargin, fsSpk] = util.argkeyval('fsSpk',varargin, 44000); %sampling rate of spike data
[varargin, fsPos] = util.argkeyval('fsPos',varargin, 2750); %sampling rate of position data
[varargin, direction] = util.argkeyval('direction',varargin, 1); %desired direction to align with 1=x 2=y 3=z
[varargin, epoch] = util.argkeyval('epoch',varargin, 500); %ms to gather around each movement
[varargin, win] = util.argkeyval('win',varargin, 20); %window to smooth spikes over in ms
[varargin, phaseLengthEndpt] = util.argkeyval('phaseLengthEndpt',varargin, 100); %what is the phase length considered "endpoint" and then the other phases
[varargin, binDegree] = util.argkeyval('binDegree',varargin, 20); %the number of bins wanted of the cycle that will make up each bin of degrees, so if this =20, then 360/20 or 18degree bins
[varargin, reachPerc] = util.argkeyval('reachPerc',varargin, 20); %the percentile of fast reaches you want to look at
[varargin, plotAlignment] = util.argkeyval('plotAlignment',varargin, 1); %plot alignment
[varargin, plotPolar] = util.argkeyval('plotPolar',varargin, 1); %plot alignment



%% make spike raster
[spikeRaster, spikeTimeStamp, spikeMsRaster]=Analysis.BasicDataProc.spikeTime(spkData, 'rmsMethod', 1, 'threshMultiplier', -4.5, 'fs', fsSpk);
%% smooth spikes
[spk, spkRate, spkRateSmooth, tmSpk] = Analysis.BasicDataProc.spikeRate(spikeMsRaster, 'win', win/1000);

%get the length of the segment in ms (and compare neural data to positional
%to ensure same length)
tmPosTotalMs=size(posData,1)/(fsPos/1000);
if tmSpk(end)-tmPosTotalMs>=10
    warning('more than 10ms difference between position data time and spike data time');
end

%% load spike data for output
spikeData=struct;
spikeData.spikeRaster=spikeRaster;
spikeData.spikeTimeStamp=spikeTimeStamp;
spikeData.spikeMsRaster=spikeMsRaster;
spikeData.spk=spk;
spikeData.spkRate=spkRate;
spikeData.spkRateSmooth=spkRateSmooth;
spikeData.timeStampe=tmSpk;

%% time convert
tmPos=linspace(0, length(posData)/(fsPos/1000), length(posData));

%% smooth positional data
posDataSm=smoothdata(posData, 'gaussian', fsPos/10); %smooth the jitter in the accel data

%WILL DEPEND ON HOW THE DLC DATA LOOKS
peakDistance=0.160; %in seconds, how far apart should the peaks be to not include small humps, it's eyeballed right now
peakHeight=30; %in arbitrary units, how hight should the peaks be, also to not include small humps

[maxX, maxLocX]=findpeaks(posDataSm(:,1), 'MinPeakDistance', fsPos*peakDistance, 'MinPeakProminence', peakHeight);
[minX, minLocX]=findpeaks(-posDataSm(:,1), 'MinPeakDistance', fsPos*peakDistance, 'MinPeakProminence', peakHeight);
[maxY, maxLocY]=findpeaks(posDataSm(:,2), 'MinPeakDistance', fsPos*peakDistance, 'MinPeakProminence', peakHeight);
[minY, minLocY]=findpeaks(-posDataSm(:,2), 'MinPeakDistance', fsPos*peakDistance, 'MinPeakProminence', peakHeight);
[maxZ, maxLocZ]=findpeaks(posDataSm(:,3), 'MinPeakDistance', fsPos*peakDistance, 'MinPeakProminence', peakHeight);
[minZ, minLocZ]=findpeaks(-posDataSm(:,3), 'MinPeakDistance', fsPos*peakDistance, 'MinPeakProminence', peakHeight);

%which direction of the 3 is being focused on.
switch direction
    case 1 %x
        maxLoc=maxLocX; minLoc=minLocX;
    case 2 %y
        maxLoc=maxLocY; minLoc=minLocY;
    case 3 %z
        maxLoc=maxLocZ; minLoc=minLocZ;
end



%convert to ms timing
minLocMs=round(minLoc/(fsPos/1000));
maxLocMs=round(maxLoc/(fsPos/1000));

%make the vectors the same size 
if length(minLocMs)>length(maxLocMs)
    minLocMs(1)=[];
elseif length(minLocMs)<length(maxLocMs)
    maxLocMs(1)=[];
end

%% arrange according to whether a min or a max is first.
if minLocMs(1)<maxLocMs(1)
    timeOrderMs(:,1)=minLocMs; timeOrderMs(:,2)=maxLocMs;
    peakOne(1)=1; peakOne(2)=2;
    minPeaksFirst=true;
else
    timeOrderMs(:,1)=maxLocMs; timeOrderMs(:,2)=minLocMs;
    peakOne(1)=2; peakOne(2)=1;
    minPeaksFirst=false;
end

%% find the frequency of the tremor


%% find the spike count in each percentile of a tremor wave to createa a polar plot
%will section the 360 degrees of a cycle into binDegree degree chunks and find the
%spike count in each one, then develop a polar plot
%since the amplitude can change on an up and a down, adjusts for that.

for ii=1:length(timeOrderMs)-1
    peak2peak1=timeOrderMs(ii,2)-timeOrderMs(ii,1); %could be min could be max, see minPeaksFirst
    peak2peak2=timeOrderMs(ii+1,1)-timeOrderMs(ii,2); %for velocity
    
    peakAmp(ii,1)=posDataSm(round(timeOrderMs(ii,2)*(fsPos/1000)),direction)-posDataSm(round(timeOrderMs(ii,1)*(fsPos/1000)),direction); %record the amplitude of the peak, the time adjustment is to get the posData in MS
    peakAmp(ii,2)=posDataSm(round(timeOrderMs(ii+1,1)*(fsPos/1000)),direction)-posDataSm(round(timeOrderMs(ii,2)*(fsPos/1000)),direction); %record the amplitude of the peak
    peakVelocity(ii,1)=peakAmp(ii,1)/peak2peak1; %Y/X? FOR SLOPE %NEED TO DO THE INTEGRAL? DERIVATIVE? HERE TO GET
    %THE VELOCITY TO FIND THE FASTEST REACHES. IT'S POSSIBLE JUST GETTING
    %THE SLOPE IS BETTER HERE THAN THE INSTANTANEOUS VELOCITY
    peakVelocity(ii,2)=peakAmp(ii,2)/peak2peak2; %again, just the slope here
    %now create a sinusoidal wave for each oscillation
    binMs=round(peak2peak1/(binDegree/2));%find how many ms are in the percentile that makes up the binning of degrees (essentially theta for a polar plot) but do half at a time for the cycle
    idx=1;
    for jj=0:binMs:peak2peak1-binMs
        spikeCount(idx,ii)=sum(spikeMsRaster(timeOrderMs(ii)+jj:timeOrderMs(ii)+jj+binMs));
        idx=idx+1;
    end
    %for the second half of the cycle
        %note the idx doesn't start over, in order to fill the second half
        %of the cycle
    binMs=round(peak2peak2/(binDegree/2));%find how many ms are in the percentile that makes up the binning of degrees (essentially theta for a polar plot) but do half at a time for the cycle    for jj=0:binMs:peak2peak1
    for  jj=0:binMs:peak2peak2-binMs
        spikeCount(idx,ii)=sum(spikeMsRaster(timeOrderMs(ii)+jj:timeOrderMs(ii)+jj+binMs));
        idx=idx+1;
    end
    %% record spikes per 
end


%% find the fastest reaches
mxPkVelocity=max(max(abs(peakVelocity))); %find the absolute max and minimum values (the extrema)
minPkVelocity=min(min(abs(peakVelocity)));
percLine=mxPkVelocity-minPkVelocity*(reachPerc/100);%find a percentile you want to look above or below


reachVelocPercentiles=struct;



for ii=1:length(peakVelocity)
    for jj=1:100/reachPerc %for each reach percentile bin
        if peakVelocity(ii,1)>=minPkVelocity-percLine
            reachVelocPercentiles.Max{jj}=spikeCount(:, ii); %THIS IS NOT RIGHT need to make a cell or struct for each percentile of the reach velocities, that is reach by cell count binned
            %need to get the spike counts for the fastest reaches and compare
            %to the slower or slowest reaches. if doing just straight spike
            %counts, do it above in the velocity part, otherwise can look at
            %the smoothed spike counts
        end
   
end
        
        


  %%  
%FIRST ORDER IS LINE UP THE NEURAL DATA WITH THE POSITIONAL DATA
        %(EITHER TWO AXES OR BY NORMALIZING BOTH). THEN REMOVE THE PEAKS
        %THAT ARE TOO CLOSE TOGETHER. FIND OUT THE MEAN/MEDIAN DIFFERENCE
        %BETWEEN THE PEAKS (TO GET AN IDEA OF THE FREQUENCY OF THE
        %MOVEMENT) TO DECIDE WHAT IS THE AMOUNT AROUND THE PEAKS THAT IS
        %REASONABLE TO LOOK AT BETWEEN TREMOR PEAKS AND NADIRS (MEANING
        %WHAT'S THE BUFFER THAT IS "ENDPOINT".j
      %DO POLAR PLOT, AND ALSO A SFC BUT THE FIELD IS THE PHASE OF THE
      %MOVEMENT. OR EVEN JUST TAKE THE SHORT EPOCHS, SAY 45 MS AND LOOK HOW
      %MANY SPIKES ARE IN EACH OF THOSE.
      %TAKE THE LARGEST 10% OF THE AMPLITUDE OF THE MOVEMENT AND SHOW THAT
      %THE ALIGNMENT IS LINKED WITH THAT, SO BASICALLY TAKE THE HIGHEST AMPLITUDE CYCLES AND ALIGN THE SPIKES THAT WAY 
epochWin=ceil(epoch/win); %find out how many spike smooth steps are in the epoch

%DO SOME SORT OF CORRELATION, THEN MOVE THE PEAKS OVER BY A SET TIME TO SEE
%WHAT PHASE OFF SET THEY ARE, WHICH CAN TELL YOU WHICH PHASE THEY ARE MOST
%LINED UP WITH.

epochSt=find(timeOrderMs(:,peakOne(1))>=epoch); %starts and next line stop the search before running out of the epoch time at beg and end
epochEnd=find(timeOrderMs(:,peakOne(1))<=tmPosTotalMs-epoch);
idx=1;
for ii=epochSt(1):epochEnd(end)
    tmTemp=find(tmSpk>=timeOrderMs(ii,peakOne(1))); %identify the spike time of the peak of interest
    %tmTemp2=find(tmSpk>=timeOrder(ii+1,peakOne(1)));
    spkMin(idx,:)=spkRateSmooth(tmTemp(1)-epochWin:tmTemp(1)+epochWin); %takes the epoch window around the min
    %spkSine(idx,:)=spkRateSmooth(tmTemp(1)-epochWin:tmTemp2(1)+epochWin);
    idx=idx+1;
end

epochSt=find(timeOrderMs(:,peakOne(2))>=epoch);
epochEnd=find(timeOrderMs(:,peakOne(2))<=tmPosTotalMs-epoch);
idx=1;
for ii=epochSt(1):epochEnd(end)
    tmTemp=find(tmSpk>=timeOrderMs(ii,peakOne(2)));
    spkMax(idx,:)=spkRateSmooth(tmTemp(1)-epochWin:tmTemp(1)+epochWin); %takes the epoch window around the 
    idx=idx+1;
end

%% Normalize
spkMinN=spkMin./max(spkMin, [], 2);
spkMaxN=spkMax./max(spkMax, [], 2);
%% sort by FR peak
[~, peakMinSpkIdI]=max(spkMinN,[],2);%find the location of the peak
[~, peakMaxSpkIdI]=max(spkMaxN,[],2);

[~,I]=sort(peakMinSpkIdI);
sortedSpkMinN=spkMinN([I],:);
[~,I]=sort(peakMaxSpkIdI);
sortedSpkMaxN=spkMaxN([I],:);
 
%% find what % are around the end point phase, for phaseLengthEndpt defined before and after the endpoint (which is in the middle of the epoch)
phaseLengthEndptWin=round(phaseLengthEndpt/win);
midPt=round(size(spkMinN,2)/2);
[tempPkMin]=find(peakMinSpkIdI >= midPt-phaseLengthEndptWin & peakMinSpkIdI <= midPt+phaseLengthEndptWin);
[tempPkMax]=find(peakMaxSpkIdI >= midPt-phaseLengthEndptWin & peakMaxSpkIdI <= midPt+phaseLengthEndptWin);
PhaseAlignment=struct;
PhaseAlignment.Percentage.Min=length(tempPkMin)/length(peakMinSpkIdI);
PhaseAlignment.Percentage.Max=length(tempPkMax)/length(peakMaxSpkIdI);

difPeakTime=timeOrderMs(:,1)-timeOrderMs(:,2);
meanDifPeakTime=mean(difPeakTime);
medDifPeakTime=median(difPeakTime);

%% cross correlation NEEDS TO BE VERIFIED THAT IT WORKS
[P1,Q1]=rat(fsPos/50);
spkRateSmoothR=resample(spkRateSmooth, P1, Q1);
%normalize the signals
spkRateSmoothN=spkRateSmoothR./max(spkRateSmoothR);
posDataN=(posDataSm./max(abs(posDataSm),[],1).*-1);

[crossCorr, Lag]=xcorr(spkRateSmoothN, posDataN(:,3));

%% find the max amplitudes of the cycle and compare if the firing rate is better aligned.


%THINKING THAT DO A FULL CYCLE PLUS 100 MS PAST EACH END OF THE WAVE, BUT
%AS AN AVERAGE OF THE MOVEMENTS, THEN SHOW THE MEAN AND SE FIRING RATE.
%PLUS A RASTER PLOT. ALSO START WITH A CORRELATION. SOME MEASURE OF HOW
%WELL THE NEURAL SIGNAL LINES UP WITH THE POSITIONAL DATA.

%HISTOGRAM, MEAN PLUS SE AS SHADED, THEN ALSO NEED TO LOOK AT REMOVING THE
%ENDS. PLUS FIGURING OUT THE MIDDLE BETWEEN THE MIN AND MAX.

%% plotting
if plotAlignment
    tSpkPlot=linspace(-epoch, epoch, size(sortedSpkMinN,2));
    trialN=size(sortedSpkMinN,2);
    figure
    imagesc(tSpkPlot,  trialN, sortedSpkMinN)
    xlabel('Time (s) from position min')
    figure
    imagesc(tSpkPlot,  trialN, sortedSpkMaxN)
    xlabel('Time (s) from position max')
end
%% so probably do the whole trial, but then also want the 200 ms around each peak etc.first pass though, line up the single unit data

if plotPolar
    theta=linspace(0, 360, binDegree);
    thetaR=deg2rad(theta);
    spikeCountTot=sum(spikeCount,2);
    figure
    polarplot(thetaR, spikeCountTot);
    ax=gca;
    
    %break it into percentiles by 10
    
    ax.ThetaTick=0:36:360;
    ax.ThetaTickLabel={'0'; '10'; '20'; '30'; '40'; '50'; '60'; '70'; '80'; '90'; '100'};
    if minPeaksFirst
        ax.ThetaZeroLocation='bottom';
        ax.ThetaTickLabel{1}='bottom Peak';
        ax.ThetaTickLabel{6}='top Peak';
        title('Spike Count by Percentile of Tremor Cycle')
    else
        ax.ThetaZeroLocation='top';
        ax.ThetaTickLabel{1}='top Peak';
        ax.ThetaTickLabel{6}='bottom Peak';
        title('Spike Count by Percentile of Tremor Cycle')        
    end
end

if plotCrossCorr
figure 
plot(Lag/fsPos, crossCorr);
title('Cross Correlation Lag');
end

end

