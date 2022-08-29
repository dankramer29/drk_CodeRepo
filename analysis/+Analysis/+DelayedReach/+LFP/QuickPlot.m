
% Shows a plot for each channel, blue dotted line is an average of all Left 
% locations for that channel and red dashed line all Right locations
% averaged
for i = 1:size(LTrialsAvg,2)
    figure('Position', [0 700 2550 650]);
    plot(LRelTimes, LTrialsAvg(:,i), 'b:')
    hold on
    plot(RRelTimes, RTrialsAvg(:,i), 'r--')
    hold off
end


%%
% Shows all channels averaged for each L trial
for i = 1:size(LChanAvg,2)
    TrialNum = num2str(i);
    figure
    plot(LRelTimes, LChanAvg(:,i))
    tStr = ['Left Trial ' TrialNum];
    title(tStr)
end

%%
% Shows all channels averaged for each R trial
for i = 1:size(LChanAvg,2)
    TrialNum = num2str(i);
    figure
    plot(RRelTimes, RChanAvg(:,i))
    tStr = ['Right Trial ' TrialNum];
    title(tStr)
end

%%
% Shows all channels for specific trial
% ex: Left(7) location trial #3 (19th trial overall)
% Trial19 = LNeuralDataCells(:,:,3);
keys = {'L_Amyg', 'L_H_Hippo', 'L_T_Hippo', 'R_Amyg', 'R_H_Hippo', 'R_T_Hippo', 'L_Par', 'R_Par'};
values = {'1:10', '17:26', '33:42', '49:58', '65:74', '81:90', '97:104', '113:120'};
timeStart = LTableOfDataUsed{3,'LNeuralStarts'};
timeEnd = LTableOfDataUsed{3,'LNeuralEnds'};

for i = 1:length(keys)
    leadName = keys{i};
    channels = str2num(values{i});
    Analysis.DelayedReach.LFP.inspectChannels(ns, channels, leadName, timeStart, timeEnd)
end

%% L parietal spectrograms and P values. Specs for location 3 and 7 trial averaged

Oct24Spec3 = Specs(:,1:30,:,Target3Logical); % Selects spectrogram data for all target loc = 3 159x30x76x7
Oct24Spec3 = mean(Oct24Spec3, 4); % 159x30x76 averages over the trial dimension
Oct24Spec7 = Specs(:,1:30,:,Target7Logical); % Selects spectrogram data for all target loc = 3 159x30x76x7
Oct24Spec7 = mean(Oct24Spec7, 4); % 159x30x76 averages over the trial dimension
Oct24Freq = Frequencies(1,1:30); % first 30 frequency values ~ 0:113 Hz
Oct24P = PValues(17,:,1:30,:); % Anova P Values. Row 17 is comparing targets 3 to 7. 1:30 freq to match spectrograms 
Oct24P = permute(Oct24P, [2 3 4 1]); % 159x30x76. Singleton is dropped


% Plot 3 images in a row: Target 7 spect | P Values 3vs7 | Target 3 spect
% for a given channel range
EndChannel = 68; % 61:68 L Parietal Channels
for i = 61:EndChannel
    FString = sprintf('L Parietal Ch(%d) PVal_Spec_T7_3', i);
    f = figure('Name', FString, 'NumberTitle', 'off', 'Position', [10 10 2550 720]);
    p = uipanel('Parent', f, 'BorderType', 'none');
    p.Title = sprintf('Comparing Targets 7 and 3 in L Parietal Ch(%d)', i);
    p.TitlePosition = 'centertop'; p.FontSize = 14; p.FontWeight = 'bold';
    
    % Middle image: P values of an anova of this channel's trials at
    % location 7 compared to location 3
    subplot(1,3,2, 'Parent',p)
    imagesc(TimeBins, Oct24Freq, Oct24P(:,:,i)'); axis xy;
    xlabel('Time After Cue Presentation (s)');
    ylabel('Frequency (Hz)');
    %yticks([0:10:115]);
    TString = sprintf('L Parietal Ch(%d) P Values', i);
    title(TString);
    c = colorbar;
    c.Label.String = 'P Values';
    caxis([0 0.05])

    % Right image: spectrogram of target 3 trials averaged for the channel
    subplot(1,3,3, 'Parent', p)
    imagesc(TimeBins, Oct24Freq, 10*log10(Oct24Spec3(:,:,i))'); axis xy;
    %yticks([0:5:120]);
    ylabel('Frequency (Hz)');
    xlabel('Time After Cue Presentation (s)');
    TString3 = sprintf('L Parietal Ch(%d) Target 3 Averaged', i);
    title(TString3);
    c = colorbar;
    c.Label.String = ' log Power (dB)';
    caxis([0 20])

    % Left image: spectrogram of target 7 trials averaged for the channel
    subplot(1,3,1, 'Parent', p)
    imagesc(TimeBins, Oct24Freq, 10*log10(Oct24Spec7(:,:,i))'); axis xy;
    %yticks([0:5:120]);
    ylabel('Frequency (Hz)');
    xlabel('Time After Cue Presentation (s)');
    TString7 = sprintf('L Parietal Ch(%d) Target 7 Averaged', i);
    title(TString7);
    c = colorbar;
    c.Label.String = 'log Power (dB)';
    caxis([0 20])
    
    % Sub figure common settings
    fig = findobj(gcf, 'type','axes');
    for k = 1:size(fig,1)
        set(fig(k), 'YLim', [0,115], 'YTick', [0:5:120], 'YMinorTick', 'on',...
            'XLim', [0,8], 'XTickLabel', {'-2' '-1' '0' '1' '2' '3' '4' '5' '6'},...
            'TickDir', 'out', 'Box', 'off' );
    end
    
end

clear i k TString TString3 TString7 c f FString fig EndChannel p

%% R parietal spectrograms and P values. Specs for location 3 and 7 trial averaged
% code same as above but for R parietal channels
% 69: 76 R Parietal Channels
for i = 69:76
    FString = sprintf('R Parietal Ch(%d) PVal_Spec_T7_3', i);
    f = figure('Name', FString, 'NumberTitle', 'off', 'Position', [10 670 2550 700]);
    p = uipanel('Parent', f, 'BorderType', 'none');
    p.Title = sprintf('Comparing Targets 7 and 3 in L Parietal Ch(%d)', i);
    p.TitlePosition = 'centertop'; p.FontSize = 14; p.FontWeight = 'bold';    
    
    subplot(1,3,2, 'Parent',p)
    imagesc(TimeBins, Oct24Freq, Oct24P(:,:,i)'); axis xy;
    xlabel('Time After Cue Presentation (s)');
    ylabel('Frequency (Hz)');
    TString = sprintf('R Parietal Ch(%d) P Values', i);
    title(TString);
    c = colorbar;
    c.Label.String = 'P Values';
    caxis([0 0.05])

    subplot(1,3,3, 'Parent', p)
    imagesc(TimeBins, Oct24Freq, 10*log10(Oct24Spec3(:,:,i))'); axis xy;
    ylabel('Frequency (Hz)');
    xlabel('Time After Cue Presentation (s)');
    TString3 = sprintf('R Parietal Ch(%d) Target 3 Averaged', i);
    title(TString3);
    c = colorbar;
    c.Label.String = 'Power (dB)';
    caxis([0 20])

    subplot(1,3,1, 'Parent', p)
    imagesc(TimeBins, Oct24Freq, 10*log10(Oct24Spec7(:,:,i))'); axis xy;
    ylabel('Frequency (Hz)');
    xlabel('Time After Cue Presentation (s)');
    TString7 = sprintf('R Parietal Ch(%d) Target 7 Averaged', i);
    title(TString7);
    c = colorbar;
    c.Label.String = 'Power (dB)';
    caxis([0 20])
    
    fig = findobj(gcf, 'type','axes');
    for k = 1:size(fig,1)
        set(fig(k), 'YLim', [0,115], 'YTick', [0:5:120], 'YMinorTick', 'on',...
            'XLim', [0,8], 'XTickLabel', {'-2' '-1' '0' '1' '2' '3' '4' '5' '6'},...
            'TickDir', 'out', 'Box', 'off' );
    end

end

clear i k TString TString3 TString7 c f FString
p.Title = 'L Parietal Channels Averaged PVal';
%%
% Save all open figures
Figs = findobj('type', 'figure'); %will get info on all open figures
SaveLocation = 'C:\Users\Mike\Documents\Data\P010\20170830\Results\LFP\';
ImageType = '-dpng'; %-djpeg, -dtiff (compressed), -dbmp

for i = 1:size(Figs,1)
    FigName = Figs(i).Name;
    Filename = [SaveLocation FigName];
    print(Figs(i), Filename, ImageType)
    close(Figs(i))
end

%%
% Show all channels in fake signal
f = figure('Name', 'Fake Signal All Channels', 'NumberTitle', 'off', 'Position', [0 100 1000 1200]);
NumChannels = size(TestDataConcat, 2);
XMin = min(TestDataConcatTime);
XMax = max(TestDataConcatTime);
YMin = -4;
YMax = 4;
for i = 1:NumChannels
    subplot(4,3,i)
    plot(TestDataConcatTimes, TestDataConcat(:,i))
    xlim([XMin XMax])
    ylim([YMin YMax])
    Title = sprintf('Channel %d', i);
    title(Title)
end

%%
% Show spectrograms from all channels for 1 trial
f = figure('Name', 'Fake Signal Spectrograms', 'NumberTitle', 'off', 'Position', [0 40 1200 1300]); %just about half a screen
NumChannels = size(TestSpecgram, 3);
Target7Trial = 1;
Target3Trial = 8;
TrialNum = Target7Trial;
YMin = 0;
YMax = 200;

for i = 1:NumChannels
    subplot(4,3,i)
    imagesc(TestTBins, TestFBins, 10*log10(TestSpecgram(:,:,i,TrialNum))', [-20 -15]); axis xy;
    ylim([YMin YMax])
    Title = sprintf('Channel %d Trial %d Target %d', i, TrialNum, TestTargets(TrialNum));
    title(Title)
end
