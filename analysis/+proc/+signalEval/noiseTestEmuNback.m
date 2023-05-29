function [T, meanSacrosstrials] = noiseTestEmuNBack(dataLFP, channelName, varargin)
%takes in the emotionLFP or identityLFP input and noise tests.


[varargin, stdAbove] = util.argkeyval('stdAbove',varargin, 10); %number of STDs above the mean something needs to be to flag the system
[varargin, plotNoiseCheckAll] = util.argkeyval('plotNoiseCheckAll',varargin, false); %plot the noise check or not
[varargin, flaggedplotNoiseCheck] = util.argkeyval('flaggedplotNoiseCheck',varargin, false); %plot the noise check or not
[varargin, taskName] = util.argkeyval('taskName',varargin, 'EmotionTask'); %what is the type of task you are looking at


flaggedTrials = []; 
flaggedVariant = [];
flaggedChannel = []; 
flaggedTrialType = [];

tplotBP = dataLFP.tPlotImageBandPass;
tplotSp = dataLFP.tPlotImage;
ff = dataLFP.freq;
idxFl = 1;
for cc = 1:length(channelName)
    for jj = 1:3                
        sAll = dataLFP.byemotion.(channelName{cc}).image.bandPassed.filter1to200{jj};
        meanS = mean(sAll,2);        
        if jj == 1
            meanSacrosstrials(cc,:) = mean(sAll,1);
        end
        meanSall = mean(meanS);              
        sdS = std(sAll, [], 2);
        sdSall = std(sdS);
        meanLine(1:length(tplotBP)) = meanSall;
        sdSline(1:length(tplotBP)) = sdSall;
        for ii = 1:size(sAll,1)
            mx = max(sAll(ii,:));
            mn = min(sAll(ii,:));
            if mx >= (meanSall + (stdAbove*sdSall)) || mn <= (meanSall - (stdAbove*sdSall))
                flaggedTrials(idxFl,1) = ii; 
                flaggedChannel{idxFl,1} = channelName{cc}; 
                flaggedVariant(idxFl,1) = jj;
                flaggedTrialType{idxFl,1} = taskName; %place holder. will be emotion or identity
                idxFl = idxFl + 1;
                if flaggedplotNoiseCheck
                    [subN1, subN2] = plt.subplotSize(size(sAll,1));
                    subN1d = subN1*2;
                    multip = [1:subN2];
                    oddN = 1:2:subN1d;
                    evenN = 2:2:subN1d;
                    idx = 1;
                    clear matN
                    for mm = 0:subN2:(subN1d*subN2)
                        matN(idx,:) = multip+mm;
                        idx = idx + 1;
                    end
                    F = figure;
                    F.WindowState = 'fullscreen';
                    sgtitle([channelName{cc}, ' ', 'variant', num2str(jj), ...
                        ' ', taskName, ' ', 'mean LFP across trials'])
                    idxT = 1;
                    idxT2 = 1;
                    for kk = 1:subN1d*subN2
                        [rw, cl] = find(matN==kk);
                        if ismember(rw, oddN) && idxT <= size(sAll,1)
                            subplot(subN1d,subN2,kk)
                            plot(tplotBP, meanLine)
                            hold on
                            plot(tplotBP, meanS(idxT) + stdAbove*sdSline)
                            plot(tplotBP, meanS(idxT) - stdAbove*sdSline)
                            plot(tplotBP, sAll(idxT, :))
                            if ismember(idxT, flaggedTrials)
                                title(['* trial', num2str(idxT)])
                            else
                                title(['\color{magenta}trial', num2str(idxT)])
                            end
                            idxT = idxT +1;
                        elseif ismember(rw, evenN) && idxT2 <= size(sAll,1)%spectrogram
                            subplot(subN1d,subN2,kk)
                            imagesc(tplotSp, ff, normalize(dataLFP.byemotion.(channelName{cc}).image.specD{jj}(:,:,idxT2),2)); axis xy;
                            idxT2 = idxT2 +1;
                        end
                    end
                end
            end
        end
        %% this can plot all of them, but is a ton of figures (3 per channel)
        if plotNoiseCheckAll
            [subN1, subN2] = plt.subplotSize(size(sAll,1));
            subN1d = subN1*2;
            multip = [1:subN2];
            oddN = 1:2:subN1d;
            evenN = 2:2:subN1d;
            idx = 1;
            clear matN
            for mm = 0:subN2:(subN1d*subN2)
                matN(idx,:) = multip+mm;
                idx = idx + 1;
            end
            F = figure;
            F.WindowState = 'fullscreen';
            sgtitle([channelName{cc}, ' ', 'variant', num2str(jj), ...
                ' ', taskName, ' ', 'mean LFP across trials'])
            idxT = 1;
            idxT2 = 1;
            for kk = 1:subN1d*subN2
                [rw, cl] = find(matN==kk);
                if ismember(rw, oddN) && idxT <= size(sAll,1)
                    subplot(subN1d,subN2,kk)
                    plot(tplotBP, meanLine)
                    hold on
                    plot(tplotBP, meanS(idxT) + stdAbove*sdSline)
                    plot(tplotBP, meanS(idxT) - stdAbove*sdSline)
                    plot(tplotBP, sAll(idxT, :))                    
                    if ismember(idxT, flaggedTrials)
                        title(['* trial', num2str(idxT)])
                    else
                        title(['\color{magenta}trial', num2str(idxT)])
                    end
                    idxT = idxT +1;
                elseif ismember(rw, evenN) && idxT2 <= size(sAll,1)%spectrogram
                    subplot(subN1d,subN2,kk)
                    imagesc(tplotSp, ff, normalize(dataLFP.byemotion.(channelName{cc}).image.specD{jj}(:,:,idxT2),2)); axis xy; 
                    idxT2 = idxT2 +1;
                end
            end
        end
    end
end

T = table(flaggedTrialType, flaggedChannel, flaggedVariant, flaggedTrials);

end