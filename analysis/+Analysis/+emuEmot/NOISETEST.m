% NOISE TESTING SCRIPT
% basic noise testing for EMUNBACKPROC

stdAbove = 4; %number of STDs above the mean something needs to be to flag the system
pltNoiseCheck = true; %if you want to plot


tplotBP = emotionTaskLFP.tPlotImageBandPass;
tplotSp = emotionTaskLFP.tPlotImage;
ff = emotionTaskLFP.freq;
for cc = 1:length(channelName)
    for jj = 1:3        
        idxFl = 1;
        Sall = emotionTaskLFP.byemotion.(channelName{cc}).image.bandPassed.filter1to200{jj};
        meanS = mean(Sall,2);
        if jj == 1
            allChannelMean(:, cc) = meanS;
        end
        meanSall = mean(meanS);              
        sdS = std(Sall, [], 2);
        sdSall = std(sdS);
        meanLine(1:length(tplotBP)) = meanSall;
        sdSline(1:length(tplotBP)) = sdSall;
        for ii = 1:size(Sall,1)
            mx = max(Sall(ii,:));
            mn = min(Sall(ii,:));
            if mx >= (meanSall + stdAbove*sdSline) || mn <= (meanSall -stdAbove*sdSLine)
                flaggedTrials(idxFl) = ii; 
                flaggedChannel{idxFl} = channelName{cc}; 
                flaggedTrialType{idxFl} = 1;
                idxFl = idxFl + 1;
                figure
                subplot(2,1,1)
                imagesc(tplotSp, ff, normalize(emotionTaskLFP.byemotion.(channelName{cc}).image.specD{jj}(:,:,ii),2)); axis xy; colorbar;
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
            [subN1, subN2] = plt.subplotSize(size(Sall,1));
            figure
            for ii = 1:size(Sall(1,:))
                subplot(subN1,subN2,ii)
                title(['trial', num2str(ii)])
                plot(tplotBP, meanLine)
                hold on
                plot(tplotBP, meanS(ii) + stdAbove*sdSline)
                plot(tplotBP, meanS(ii) - stdAbove*sdSline)
                plot(tplotBP, Sall(ii, :))
            end
        end
    end
end

%plot the periodogram for the mean of all trials across all channels
if plotNoiseCheck
   [subN1, subN2] = plt.subplotSize(length(channelName));
    figure
    for jj=1:2:length(channelName) %do all of the channels, go by 2 to get the spikes then the bands
        subplot(subN1, subN2, jj);
        title(channelName{jj})
        periodogram(allChannelMean(jj),[],size(allChannelMean(jj),1), fs);
    end
end
