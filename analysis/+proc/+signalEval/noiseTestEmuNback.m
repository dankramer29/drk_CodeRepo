function [T, meanSacrosstrials] = noiseTestEmuNBack(dataLFP, channelName, varargin)
%takes in the emotionLFP or identityLFP input and noise tests.


[varargin, stdAbove] = util.argkeyval('stdAbove',varargin, 5); %number of STDs above the mean something needs to be to flag the system
[varargin, plotNoiseCheckAll] = util.argkeyval('plotNoiseCheckAll',varargin, false); %plot the noise check or not
[varargin, flaggedplotNoiseCheck] = util.argkeyval('flaggedplotNoiseCheck',varargin, true); %plot the noise check or not
[varargin, taskNameSel] = util.argkeyval('taskNameSel',varargin, 1); %what is the type of task you are looking at. 1 is emotion task, 2 is identity task.
[varargin, savePlot] = util.argkeyval('savePlot', varargin, 1); %will save the figures as jpgs and close them so it's must smaller
[varargin, sessionName, ~, found]=util.argkeyval('sessionName', varargin, []);
[varargin, subjName, ~, found]=util.argkeyval('subjName', varargin, []);
[varargin, versionNum, ~, found]=util.argkeyval('versionNum', varargin, '_'); %if you want to do multiple versions of the same file

task = fieldnames(dataLFP);

if taskNameSel == 1
    taskType = 2;
    taskName = 'EmotionTask';
else
    taskType = 1;
    taskName = 'IdentityTask';
end

flaggedTrials = []; 
flaggedVariant = [];
flaggedChannel = []; 
flaggedTrialType = [];

tplotBP = dataLFP.tPlotImageBandPass;
tplotSp = dataLFP.tPlotImage;
ff = dataLFP.freq;
idxFl = 1;
idxNoise = 1;
idxFPlot = 1;
for cc = 1:length(channelName)
    for jj = 1:3                
        sAll = dataLFP.(task{taskType}).(channelName{cc}).image.bandPassed.filter1to200{jj};
        meanS = mean(sAll,2);        
        if jj == 1
            meanSacrosstrials(cc,:) = mean(sAll,1);
        end
        meanSall = mean(meanS);              
        sdS = std(sAll, [], 2);
        sdSall = mean(sdS);
        meanLine(1:length(tplotBP)) = meanSall;
        sdSline(1:length(tplotBP)) = sdSall;
        tempFltrials = [];
        idxTemp = 1;
        for ii = 1:size(sAll,1)
            mx= max(sAll(ii,:));
            mn = min(sAll(ii,:));
            if mx >= (meanSall + (stdAbove*sdSall)) || mn <= (meanSall - (stdAbove*sdSall))
                flaggedTrials(idxFl,1) = ii; 
                flaggedChannel{idxFl,1} = channelName{cc}; 
                flaggedVariant(idxFl,1) = jj;
                flaggedTrialType{idxFl,1} = taskName; %place holder. will be emotion or identity
                tempFltrials(idxTemp) = ii;
                idxTemp = idxTemp +1;
                idxFl = idxFl + 1;
                idxFPlot = idxFPlot + 1;
            end
        end
        if flaggedplotNoiseCheck
            if ~isempty(tempFltrials)
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
                F.Name = ([channelName{cc}, ' ', 'variant', num2str(jj), ...
                    ' ', taskName, ' ', 'mean LFP across trials']);
                sgtitle([channelName{cc}, ' ', 'variant', num2str(jj), ...
                    ' ', taskName, ' ', 'mean LFP across trials'])
                idxT = 1;
                idxT2 = 1;
                flTrNum = length(tempFltrials); %for some goofy math to count correctly
                for kk = 1:subN1d*subN2
                    [rw, cl] = find(matN==kk);
                    if ismember(rw, oddN) && idxT <= size(sAll,1)
                        subplot(subN1d,subN2,kk)
                        plot(tplotBP, meanLine)
                        hold on
                        plot(tplotBP, meanLine(idxT) + stdAbove*sdSline)
                        plot(tplotBP, meanLine(idxT) - stdAbove*sdSline)
                        plot(tplotBP, sAll(idxT, :))
                        if ismember(idxT, tempFltrials)
                            title(['* trial', num2str(idxT), ' line', num2str(idxFPlot-1-flTrNum+1)], 'FontSize', 14) %ignore the goofy math here, it's so if there are 3 in this session, and idxFl is at 11, you subtract 1 to bold this trial at 10 (where it's at) and then remove the number in this session (e.g. 3, but 10-3 is 7 so add one back to be 8) then subtract 1 from the idx so it's now subtracting 2 (+1 back) so the next is 9, and the final one will flag 10. i hope i never read this again. 
                            flTrNum = flTrNum - 1;
                        else
                            title(['\color{magenta}trial', num2str(idxT)])
                        end
                        idxT = idxT +1;
                    elseif ismember(rw, evenN) && idxT2 <= size(sAll,1)%spectrogram
                        subplot(subN1d,subN2,kk)
                        imagesc(tplotSp, ff, normalize(dataLFP.(task{taskType}).(channelName{cc}).image.specD{jj}(:,:,idxT2),2)); axis xy;
                        idxT2 = idxT2 +1;
                    end
                end
                if savePlot
                    if ~isempty(sessionName)
                        hh =  findobj('type','figure');
                        nh = length(hh);
                        if taskNameSel == 1;
                            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                                'versionNum', 'v1_NoisecheckEmotionTask');
                        elseif taskNameSel ==2;
                            plt.save_plots([1:nh], 'sessionName', sessionName, 'subjName', subjName, ...
                                'versionNum', 'v1_NoisecheckIdentityTask');
                        end
                        close
                    else
                        saveas(F, 'jpg')
                        close
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
            F.WindowState = 'maximize';
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
                        title(['* trial', num2str(idxNoise)])
                        idxNoise = idxNoise + 1;
                    else
                        title(['\color{magenta}trial', num2str(idxT)])
                    end
                    idxT = idxT +1;
                elseif ismember(rw, evenN) && idxT2 <= size(sAll,1)%spectrogram
                    subplot(subN1d,subN2,kk)
                    imagesc(tplotSp, ff, normalize(dataLFP.(task{taskType}).(channelName{cc}).image.specD{jj}(:,:,idxT2),2)); axis xy; 
                    idxT2 = idxT2 +1;
                end
            end
        end
    end
end

T = table(flaggedTrialType, flaggedChannel, flaggedVariant, flaggedTrials);

end