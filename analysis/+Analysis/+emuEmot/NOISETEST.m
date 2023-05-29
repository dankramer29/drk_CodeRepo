% NOISE TESTING SCRIPT
% basic noise testing for EMUNBACKPROC

%taskName = fields(dataLFP);

stdAbove = 4; %number of STDs above the mean something needs to be to flag the system
plotNoiseCheck = true; %if you want to plot


tplotBP = emotionTaskLFP.tPlotImageBandPass;
tplotSp = emotionTaskLFP.tPlotImage;
ff = emotionTaskLFP.freq;
for cc = 1:length(channelName)
    for jj = 1:3        
        idxFl = 1;
        sAll = emotionTaskLFP.byemotion.(channelName{cc}).image.bandPassed.filter1to200{jj};
        meanS = mean(sAll,2);
        meanSacrosstrials = mean(sAll,1);
        if jj == 1
            allChannelMean(:, cc) = meanSacrosstrials;
        end
        meanSall = mean(meanS);              
        sdS = std(sAll, [], 2);
        sdSall = std(sdS);
        meanLine(1:length(tplotBP)) = meanSall;
        sdSline(1:length(tplotBP)) = sdSall;
        for ii = 1:size(sAll,1)
            mx = max(sAll(ii,:));
            mn = min(sAll(ii,:));
            if mx >= (meanSall + stdAbove*sdSall) || mn <= (meanSall -stdAbove*sdSall)
                flaggedTrials(idxFl) = ii; 
                flaggedChannel{idxFl} = channelName{cc}; 
                flaggedTrialType{idxFl} = 1; %place holder. will be emotion or identity
                idxFl = idxFl + 1;
                figure
                sgtitle(['trial', num2str(ii), ' ', channelName{cc}, 'emotion task'])                
                subplot(2,1,1)
                imagesc(tplotSp, ff, normalize(emotionTaskLFP.byemotion.(channelName{cc}).image.specD{jj}(:,:,ii),2)); axis xy; colorbar;
                subplot(2,1,2)
                plot(tplotBP, meanLine)
                hold on
                plot(tplotBP, meanS(ii) + stdAbove*sdSline)
                plot(tplotBP, meanS(ii) - stdAbove*sdSline)
                plot(tplotBP, sAll(ii, :))
            end
        end
        if plotNoiseCheck
            [subN1, subN2] = plt.subplotSize(size(sAll,1));
            figure
            for kk = 1:size(sAll,1)
                sgtitle([channelName{cc}, ' ', 'emotion task', ' ', 'mean LFP across trials'])
                subplot(subN1,subN2,kk)
                plot(tplotBP, meanLine)
                hold on
                plot(tplotBP, meanS(kk) + stdAbove*sdSline)
                plot(tplotBP, meanS(kk) - stdAbove*sdSline)
                plot(tplotBP, sAll(kk, :))
                title(['trial', num2str(kk)])
            end
        end
    end
end


