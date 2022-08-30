
%Runs through all of the people to get the peak data and run stats on it.

% Currently running everything off of a 0.2 window except alpha off a 0.5
% window.


Nstep=0.005;
Nwin=0.1;


%TO CHANGE WHICH CHANNELS STRUCT YOU WANT, SWITCH IT HERE
channels=sch;


assert(~isempty(sch), 'need to load ch in the flash drive probably in: "\\Striatum\flash\RealTouchAll\SpecgramcOutputsAllSubj\RelevantChAll.mat"');


 %[ powerpeaksN, continuousPowerMeanN, continuousPowerdBN]=Analysis.ArtSens.powerPeak( filtbandPowerdB, Nstep, Nwin, 'dB', false);
 powerpeaks=powerpeaksN;

<<<<<<< HEAD
[ powerpeaks.bm, allpeak2.bm]=Analysis.ArtSens.specpeak( specPowerBM2, Nstep, Nwin, specgramcBM2.SoftTouch.t, 'window', [0.2 0.005]);
=======
%[ powerpeaks.bm, allpeak2.bm]=Analysis.ArtSens.specpeak( specPowerBM2, Nstep, Nwin, specgramcBM2.SoftTouch.t, 'window', [0.2 0.005]);
>>>>>>> master
% %[ powerpeaks.cg]=Analysis.ArtSens.specpeak( specPowerCG2, Nstep, Nwin, specgramcCG2.SoftTouch.t, 'window', [0.2 0.005]);
% [ powerpeaks.eg, allpeak2.eg]=Analysis.ArtSens.specpeak( specPowerEG2, Nstep, Nwin, specgramcEG2.SoftTouch.t, 'window', [0.2 0.005]);
% [ powerpeaks.jo, allpeak2.jo]=Analysis.ArtSens.specpeak( specPowerJO2, Nstep, Nwin, specgramcJO2.SoftTouch.t, 'window', [0.2 0.005]);
% [ powerpeaks.jr, allpeak2.jr]=Analysis.ArtSens.specpeak( specPowerJR2, Nstep, Nwin, specgramcJR2.SoftTouch.t, 'window', [0.2 0.005]);
%
% [ powerpeaks.bm, allpeak5.bm]=Analysis.ArtSens.specpeak( specPowerBM2, Nstep, Nwin, specgramcBM5.SoftTouch.t, 'window', [0.5 0.005]);
% %[ powerpeaks.cg]=Analysis.ArtSens.specpeak( specPowerCG5, Nstep, Nwin, specgramcCG5.SoftTouch.t, 'window', [0.5 0.005]);
% [ powerpeaks.eg, allpeak5.eg]=Analysis.ArtSens.specpeak( specPowerEG5, Nstep, Nwin, specgramcEG5.SoftTouch.t, 'window', [0.5 0.005]);
% [ powerpeaks.jo, allpeak5.jo]=Analysis.ArtSens.specpeak( specPowerJO5, Nstep, Nwin, specgramcJO5.SoftTouch.t, 'window', [0.5 0.005]);
% [ powerpeaks.jr, allpeak5.jr]=Analysis.ArtSens.specpeak( specPowerJR5, Nstep, Nwin, specgramcJR5.SoftTouch.t, 'window', [0.5 0.005]);

nmes=fields(sch);
touch=fields(powerpeaks.bm);
bands=fields(powerpeaks.bm.DeepTouch);

tempHGH=[];
catHGH=[];
tempAlphaL=[];
catAlphaL=[];
tempBetaL=[];
catBetaL=[];
tempGammaL=[];
catGammaL=[];
allpeakS=struct;
allpeakSmat=struct;
for ii=1:length(nmes)
    for kk=1:length(touch)
        allpeakS.(nmes{ii}).(touch{kk})=[];
    end
end



%create a ch count for only S1 channels
% sch=struct;
% for jj=1:length(nmes)
% for kk=1:length(touch)
%     sch.(nmes{jj}).high.(touch{kk})=ch.(nmes{jj}).high.(touch{kk})(ismember(ch.(nmes{jj}).high.(touch{kk}),schsonly.(nmes{jj})));
%     sch.(nmes{jj}).low.(touch{kk})=ch.(nmes{jj}).low.(touch{kk})(ismember(ch.(nmes{jj}).low.(touch{kk}),schsonly.(nmes{jj})));
% end
% end




for kk=1:length(touch)
    idxband=5;
    %High Gamma
    for jj=1:length(nmes)
        idx=1;
        for ii=1:length(channels.(nmes{jj}).high.(touch{kk}))
            if isempty(tempHGH)
                tempHGH(1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).high.(touch{kk})(ii),:);
                
                catHGH{1,1}=touch{kk};
                catHGH{1,2}=nmes{jj};
            else
                tempHGH(end+1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).high.(touch{kk})(ii),:);
                
                catHGH{end+1,1}=touch{kk};
                catHGH{end,2}=nmes{jj};
            end
            
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,1)=continuousPowerMeanN.(nmes{jj})(channels.(nmes{jj}).high.(touch{kk})(ii)).(touch{kk}).(bands{idxband});
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,2)=std(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).high.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),[],2);
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,3)=size(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).high.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),2);
            
            idx=idx+1;
        end
    end
    
    
    
    idxband=2;
    
    %Alpha
    for jj=1:length(nmes)
        idx=1;
        for ii=1:length(channels.(nmes{jj}).low.(touch{kk}))
            if isempty(tempAlphaL)
                tempAlphaL(1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).low.(touch{kk})(ii),:);
                
                catAlphaL{1,1}=touch{kk};
                catAlphaL{1,2}=nmes{jj};
            else
                tempAlphaL(end+1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).low.(touch{kk})(ii),:);
                
                catAlphaL{end+1,1}=touch{kk};
                catAlphaL{end,2}=nmes{jj};
            end
            
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,1)=continuousPowerMeanN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband});
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,2)=std(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),[],2);
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,3)=size(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),2);
            
            idx=idx+1;
            
            
        end
        
    end
    
    
    idxband=3;
    %Beta
    for jj=1:length(nmes)
        idx=1;
        for ii=1:length(channels.(nmes{jj}).low.(touch{kk}))
            if isempty(tempBetaL)
                tempBetaL(1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).low.(touch{kk})(ii),:);
                
                catBetaL{1,1}=touch{kk};
                catBetaL{1,2}=nmes{jj};
            else
                tempBetaL(end+1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).low.(touch{kk})(ii),:);
                
                catBetaL{end+1,1}=touch{kk};
                catBetaL{end,2}=nmes{jj};
            end
            
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,1)=continuousPowerMeanN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband});
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,2)=std(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),[],2);
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,3)=size(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),2);
            
            idx=idx+1;
            
        end
        
    end
    
    
    idxband=4;
    %Gamma
    for jj=1:length(nmes)
        idx=1;
        for ii=1:length(channels.(nmes{jj}).low.(touch{kk}))
            if isempty(tempGammaL)
                tempGammaL(1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).low.(touch{kk})(ii),:);
                
                
                catGammaL{1,1}=touch{kk};
                catGammaL{1,2}=nmes{jj};
            else
                tempGammaL(end+1,1:4)=powerpeaks.(nmes{jj}).(touch{kk}).(bands{idxband})(channels.(nmes{jj}).low.(touch{kk})(ii),:);
                
                
                catGammaL{end+1,1}=touch{kk};
                catGammaL{end,2}=nmes{jj};
            end
            
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,1)=continuousPowerMeanN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband});
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,2)=std(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),[],2);
            allpeakS.(nmes{jj}).(touch{kk})(idx).(bands{idxband})(:,3)=size(continuousPowerdBN.(nmes{jj})(channels.(nmes{jj}).low.(touch{kk})(ii)).(touch{kk}).(bands{idxband}),2);
            idx=idx+1;
        end
        
    end
    
end

%%

% % 
% [~,~, statsHGL]=anova1(tempHGH(:,3), catHGH(:,1), 'off');
% [rHGL, meansHGL]=multcompare(statsHGL, 'Ctype', 'bonferroni')
% [~,~, statsAlphaH]=anova1(tempAlphaL(:,1), catAlphaL(:,1), 'off');
% [rAlphaH, meansAlphaH]=multcompare(statsAlphaH, 'Ctype', 'bonferroni')
% [~,~, statsBetaH]=anova1(tempBetaL(:,1), catBetaL(:,1),  'off');
% [rBetaH, meansBetaH]=multcompare(statsBetaH, 'Ctype', 'bonferroni')
% [~,~, statsGammaH]=anova1(tempGammaL(:,1), catGammaL(:,1),  'off');
% [rGammaH, meansGammaH]=multcompare(statsGammaH, 'Ctype', 'bonferroni')
% 
% [~,~, statsHGH]=anova1(tempHGH(:,1), catHGH(:,1), 'off');
% [rHGH, meansHGH]=multcompare(statsHGH, 'Ctype', 'bonferroni')
% [~,~, statsAlphaL]=anova1(tempAlphaL(:,3), catAlphaL(:,1),  'off');
% [rAlphaL, meansAlphaL]=multcompare(statsAlphaL, 'Ctype', 'bonferroni')
% [~,~, statsBetaL]=anova1(tempBetaL(:,3), catBetaL(:,1), 'off');
% [rBetaL, meansBetaL]=multcompare(statsBetaL, 'Ctype', 'bonferroni')
% [~,~, statsGammaL]=anova1(tempGammaL(:,3), catGammaL(:,1), 'off');
% [rGammaL, meansGammaL]=multcompare(statsGammaL, 'Ctype', 'bonferroni')
% 
% %low for HG and high for rest
% [~,~, statsHGpL]=anova1(tempHGH(:,4), catHGH(:,1), 'off');
% [rHGpL, meansHGpL]=multcompare(statsHGpL, 'Ctype', 'bonferroni')
% [~,~, statsAlphapH]=anova1(tempAlphaL(:,2), catAlphaL(:,1),  'off');
% [rAlphapH, meansAlphapH]=multcompare(statsAlphapH, 'Ctype', 'bonferroni')
% [~,~, statsBetapH]=anova1(tempBetaL(:,2), catBetaL(:,1));
% [rBetapH, meansBetapH]=multcompare(statsBetapH, 'Ctype', 'bonferroni')
% [~,~, statsGammapH]=anova1(tempGammaL(:,2), catGammaL(:,1));
% [rGammapH, meansGammapH]=multcompare(statsGammapH, 'Ctype', 'bonferroni')
% 
% %low for HG and high for rest
% [~,~, statsHGpH]=anova1(tempHGH(:,2), catHGH(:,1),  'off');
% [rHGpH, meansHGpH]=multcompare(statsHGpH, 'Ctype', 'bonferroni')
% [~,~, statsAlphapL]=anova1(tempAlphaL(:,4), catAlphaL(:,1),  'off');
% [rAlphapL, meansAlphapL]=multcompare(statsAlphapL, 'Ctype', 'bonferroni')
% [~,~, statsBetapL]=anova1(tempBetaL(:,4), catBetaL(:,1),  'off');
% [rBetapL, meansBetapL]=multcompare(statsBetapL, 'Ctype', 'bonferroni')
% [~,~, statsGammapL]=anova1(tempGammaL(:,4), catGammaL(:,1),  'off');
% [rGammapL, meansGammapL]=multcompare(statsGammapL, 'Ctype', 'bonferroni')
% 
