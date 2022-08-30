%% basic processing for a new R
%% TO RUN THESE INDIVIDUALLY, HIT RUN SECTION AND YOU CAN DEBUG

% %Task open YES USE THIS ONE, IT'S THE SERGEY ONE
% ns5file='C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\121218_b7_NPTL_COData\LateralGrid_121218_b7\7_cursorTask_Complete_t5_bld(007)008.ns5';
% load('C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\121218_b7_NPTL_COData\cursorTaskR_T5.mat')
% R=R(1:64);
% %optional
% ns5=openNSx('read', ns5file, 'c:01:96'); 
% if isa(ns5.Data, 'cell')
%     data=double(ns5.Data{end})';
% else
%     data=double(ns5.Data)';
% end

%head move task
ns5file='C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\t5.2019.03.18_HeadMoveData\Data\NS5_block10Head\10_cursorTask_Complete_t5_bld(010).ns5';
% %should be lateral grid
load('C:\Users\kramdani\Dropbox\My PC (Cerebro2)\Documents\Data\t5.2019.03.18_HeadMoveData\Data\R_structs\R_block_10.mat')
R=R(1:64);
%optional
ns5=openNSx('read', ns5file, 'c:01:96'); 
if isa(ns5.Data, 'cell')
    data=double(ns5.Data{end})';
else
    data=double(ns5.Data)';
end


%%
rState=double([R.state]);
rCP=double([R.cursorPosition]); %1 and 3 are position, 2 and 4 are velocity for grid task, and it's derivative of cp in grid task or row 1:2 of xp
rFCT=double([R.firstCerebusTime])+ 10*30; %There is a 10ms offset from ns5 and firstCerebusTime, unknown why, but verified. difference between row 1 and 2 is 6ms, lastcerebrustime is 29 and 35ms respectively for row 1/2
rMinA=double([R.minAcausSpikeBand])';
if isempty(cell2mat(strfind(fields(R), 'spikeRaster')))
    threshMultiplier = -4.5;
    RMSvals = channelRMS( R );
    thresholds = RMSvals.*threshMultiplier;
    thresholds = thresholds'; % make column vector
    for iTrial = 1 : numel( R )
        R(iTrial).spikeRaster = R(iTrial).minAcausSpikeBand < repmat( thresholds, 1, size( R(iTrial).minAcausSpikeBand, 2 ) );
    end
end
rSpk=double([R.spikeRaster]);

%% prep all the data.
fs=30000;
preTrialSt=2; %start 2 seconds before the trial
preTrialEnd=2; %start 2 seconds after the trial
trialSt=rFCT(1)-fs*preTrialSt;
trialEnd=rFCT(end)+fs*preTrialEnd;
downSample=2000;
tT=tic;
[dataProc.DataAllTemp, dataProc.params]=Analysis.BasicDataProc.dataPrep(Analysis.BasicDataProc.downSample(data, fs, downSample), 'Spectrogram', true, 'doBandFilterBroad', true);
toc(tT)


%% to run this, hit run section, or it won't stop on the break point
%evaluate the states, to make sure it matches up.
trialNum=[10 20];
%grid task dots
gridDots=[R.posTarget];
figure
subplot(2,2,1)
plot(gridDots(1,:), gridDots(2,:), 'o', 'MarkerEdgeColor', 'g');

for ii=trialNum(1):trialNum(2)
    speedPos=[];
    subplot(2,2,1)
    hold on
    cpTrial=R(ii).cursorPosition;
    rSpkTrial=R(ii).spikeRaster;
    speedPos(1,:)=diff(cpTrial(1,:));
    speedPos(2,:)=diff(cpTrial(2,:));
    %comet(cpTrial(1,:), cpTrial(2,:))
    plot(cpTrial(1,:), cpTrial(2,:))
%     for jj=1:size(cpTrial,2)
%         plot(cpTrial(1,jj), cpTrial(2,jj))
%         pause(.01)
%     end
    title('position on grid')
    sgtitle(num2str(ii))
    hold off
    
    subplot(2,2,3)
    hold off
    plot(cpTrial(1,:))
    hold on
    plot(cpTrial(2,:))
    title('position')
    
    subplot(2,2,2)
    hold off
    plot(speedPos(1,:))
    hold on
    plot(speedPos(2,:))
    title('speed')
    
    subplot(2,2,4)
    hold off
    rStateT=R(ii).state;
    plot(rStateT)
    title('state')
    
end

%%
%%check the move state for spiking changes

spkWin=20; %window for spike smoothing
epochW=1000; %ms to make a window on either side of the changing position.

targetSpk=[]; targetSpk=[]; targetCp=[]; targetSpkAll=[];
[spk, spkRate, spkRateSmooth, tm] = Analysis.BasicDataProc.spikeRate(rSpk(1:96,:), 'win', spkWin);

%get the states hovering
idxH=1; idxM=1; idxCheck=1; idxT=1;
for ii=1:numel(rState)-1 %first trial is different than the rest
    %if rState(ii)-rState(ii)==-4 %this is for grid task
    %if rState(ii)==2 && rState(ii-1)~=2 && ii>1000 %for center out task, 2 when target appears
    if rState(ii)==2 && rState(ii+1)==3 && ii>epochW %for head tracking task, 3 is move, 2 is target appearing, 1000 ensures it's not the going back phase   
    %Make a matrix for around the target appearing.  This is to test a
        %new R
        
            tempSt=find(tm>=ii-epochW & tm<=ii+epochW);            
            if ~isempty(targetSpk)
                if length(tempSt)<length(targetSpk{1})
                    break
                end
                if length(tempSt)<size(targetSpk{idxT-1},1)
                    tempSt(end+1)=tempSt(end)+1;
                elseif length(tempSt)>size(targetSpk{idxT-1},1)
                    tempSt(end)=[];
                end
            end
            if length(spkRateSmooth)<tempSt(end)
                diffTS=tempSt(end)-length(spkRateSmooth);
                meanTS=mean(spkRateSmooth);                
                for jj=1:diffTS; spkRateSmooth(end+1,:)=meanTS; end  %this is in case the time is longer than the trial, add the means
            end
            if ii+epochW > size(rCP, 2)
                diffCP=ii+epochW-size(rCP,2);
                rCP(:,end+1:end+diffCP)=repmat(rCP(:,end),1,diffCP);
            end
            targetSpk{idxM}=spkRateSmooth(tempSt(1):tempSt(end), :);            
            targetCp(:, :, idxM)=rCP(:, ii-1000:ii+1000);            
            targetSpkAll(:, :, idxM)=spkRateSmooth(tempSt(1):tempSt(end), :);
            tempSt=[]; tempEnd=[];
            idxT=idxT+1; 

        idxM=idxM+1; 
    end
end

    [allChSpk,allTrialSpk] = Analysis.NPTL.checkSpikes(targetSpkAll,targetCp);

%%
%%check the correlation
itiD=data(R(1).firstCerebusTime(1,1)-(30000*6)-300:R(1).firstCerebusTime(1,1)-15000-300, :);%also subtract the 10ms offset, or 300 samples

idxch2el=[78,88,68,58,56,48,57,38,47,28,37,27,36,18,45,17,46,8,35,16,24,7,26,6,25,5,15,4,14,3,13,2,77,67,76,66,75,65,74,64,73,54,63,53,72,43,62,55,61,44,52,33,51,34,41,42,31,32,21,22,11,23,10,12,96,87,95,86,94,85,93,84,92,83,91,82,90,81,89,80,79,71,69,70,59,60,50,49,40,39,30,29,19,20,1,9];
%run a correlation coeffecient if need be
corrCoef=true;
if corrCoef
    [Corr, dataClassBand] = Analysis.BasicDataProc.gridCorrCoef(itiD, 'channelOrder', idxch2el, 'plt', false);
else
    dataClassBand=[];
end

%% make sure the timing of the spikes and the ns5 are on
dtLength=300;
cH=8;
trl=1;
tempFCT=rFCT(1,1:dtLength)'; %adjustment factor, this should have already
%been done at the rFCT level
%tempFCTadj=tempFCT-(30*10); 
tempSpk=rSpk(:,1:dtLength)*-300; %100 is an adjustment to see it on the plot
tempMinA=rMinA(1:dtLength, 1:96);
tempHFO=data(tempFCT(1):tempFCT(end),:);
%tempHFOadj=data(tempFCTadj(1):tempFCTadj(end),:);
tempHFOp=Analysis.BasicDataProc.dataPrep(tempHFO, 'Spectrogram', false, 'BandPassed', false, 'DoBandFilterBroad', false);
%tempHFOpadj=Analysis.BasicDataProc.dataPrep(tempHFOadj, 'Spectrogram', false, 'BandPassed', false, 'DoBandFilterBroad', false);
bam1 = [0.95321773445431  -1.90644870937033 0.95323097500802 1 -1.90514144409761 0.90775595733389; ...
        0.97970016700443  -1.95938672569874 0.97968655878878 1 -1.95804317832840 0.96073029104793];
gm1 = 1;
filtD = dfilt.df2sos(bam1, gm1);
tempHFOF=filtfilthd(filtD, tempHFOp.dataBasicFilter);
%tempHFOFadj=filtfilthd(filtD, tempHFOpadj.dataBasicFilter);
tempHFOFmin=Analysis.BasicDataProc.minVoltForSpike(tempHFOF);
%tempHFOFminadj=Analysis.BasicDataProc.minVoltForSpike(tempHFOFadj);

tSpk=linspace(0, dtLength, dtLength);
tHFO=linspace(0, dtLength, length(tempHFOF));

figure
plot(tSpk, tempSpk(cH,:), '.', 'MarkerSize', 10)
hold on
plot(tSpk, tempHFOFmin(:,cH))
plot(tSpk, tempMinA(:, cH), 'g')
legend('spikes', 'highpass ns5', 'minAcausSpikeBand');


