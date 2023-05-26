% NOISE TESTING SCRIPT
% basic noise testing for EMUNBACKPROC

stdAbove = 4; %number of STDs above the mean something should be to flag the system
pltNoiseCheck = true; %if you want to plot


tplotBP = emotionTaskLFP.tPlotImageBandPass;
tplotSp = emotionTaskLFP.tPlotImage;
ff = emotionTaskLFP.freq;
for jj = 1:3
    idxFl = 1;
    Sall = emotionTaskLFP.byemotion.ch97.image.bandPassed.filter1to200{jj};
    meanS = mean(Sall,2);
    meanSall = mean(meanS);
    sdS = std(Sall, [], 2);
    sdSall = std(sdS);
    meanLine(1:length(tplotBP)) = meanSall;
    sdSline(1:length(tplotBP)) = sdSall;
    for ii = 1:size(Sall,1)
        mx = max(Sall(ii,:));
        mn = min(Sall(ii,:));
        if mx > meanSall + stdAbove*sdSline || mn < meanSall -stdAbove*sdSLine
            flaggedTrials(idxFl) = ii;
            figure
            subplot(2,1,1)
            imagesc(tplotSp, ff, normalize(emotionTaskLFP.byemotion.ch97.image.specD{jj}(:,:,ii),2)); axis xy; colorbar;
            subplot(2,1,2)
            
            subplot(8,2,ii)
            title(['trial', num2str(ii)])
            plot(tplotBP, meanLine)
            hold on            
            plot(tplotBP, meanS(ii) + stdAbove*sdSline)
            plot(tplotBP, meanS(ii) - stdAbove*sdSline)
            plot(tplotBP, Sall(ii, :))
        end
    end
    if plotNoiseCheck
        figure
        for ii = 1:size(Sall(ii,:))           
            subplot(8,2,ii)
            title(['trial', num2str(ii)])
            plot(tplotBP, meanLine)
            hold on            
            plot(tplotBP, meanS(ii) + stdAbove*sdSline)
            plot(tplotBP, meanS(ii) - stdAbove*sdSline)
            plot(tplotBP, Sall(ii, :))
        end
    end
end


for ii=1:size(emotionTaskLFP.byemotion.ch97.image.bandPassed.filter1to200{jj},1)
    S1 = emotionTaskLFP.byemotion.ch97.image.bandPassed.filter1to200{3}(ii,:);
    figure
    subplot(2,1,1)
    plot(tplotBP,S1);
    subplot(2,1,2)
    periodogram(S1,[],length(S1), fs);
end