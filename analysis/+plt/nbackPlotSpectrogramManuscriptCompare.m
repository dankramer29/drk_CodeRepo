function [figIdxNow] = nbackPlotSpectrogramManuscriptCompare(nbackCompare, varargin)
%This is to put in nice figures and output the comparison of the two
%allemotions/allidentities.
%   Detailed explanation goes here

% input
%       chName = 'ch1312' or whatever

[varargin, comparison]=util.argkeyval('comparison', varargin, 1); %toggle between 1, and 2 for now. 1 shows identity next to emotion. 2 shows difference, will want to load in stats between the two
[varargin, figTitleName]=util.argkeyval('figTitleName', varargin, 'Image On'); %Name of what you are comparing
[varargin, timePlot]=util.argkeyval('timePlot', varargin, []); %pull in the time plot vector
[varargin, frequencyRange]=util.argkeyval('frequencyRange', varargin, []); %pull in the frequency range
[varargin, chName]=util.argkeyval('chName', varargin, []); %chNumber you are using like ch1312
[varargin, chLocationName]=util.argkeyval('chLocationName', varargin, []); %ch location like L amygdala
[varargin, adjustedColorMap]=util.argkeyval('adjustedColorMap', varargin, false); %this will adjust a colormap to prevent outliers from making the map too dull
[varargin, flatColorMap]=util.argkeyval('flatColorMap', varargin, true); %this just sets it at 3 SD (can adjust below to a different set). if both of these are off the heatmaps will set their own colormaps
[varargin, doMask]=util.argkeyval('doMask', varargin, true); %set a mask for only the significant portions
[varargin, figIdx]=util.argkeyval('figIdx', varargin, 1); %set the numbering so it's easier to find the right figures

maskPerc = .75;


if comparison == 1
    comparisonTitle = ['Identity Task compared to Emotion Task ', figTitleName];
elseif comparison == 2
    comparisonTitle = ['Identity Task minus Emotion Task ', figTitleName];
end


chNum = fieldnames(nbackCompare);

conditionName = fieldnames(nbackCompare.(chNum{1}));

resultName = fieldnames(nbackCompare.(chNum{1}).(conditionName{1}));

resultNameAll = fieldnames(nbackCompare.(chNum{1}).(conditionName{4}));

if ~isempty(timePlot)
    tt = timePlot;
else
    tt = 1:size(nbackCompare.(chNum{1}).(conditionName{1}).(resultName{1}),2);
end

if ~isempty(frequencyRange)
    ff = frequencyRange;
else
    ff = 1:size(nbackCompare.(chNum{1}).(conditionName{1}).(resultName{1}),1);
end

if isempty(chName)
    chName = chNum;
end
if isempty(chLocationName)
    chLocationName = ' ';
end


%% plot

for ii = 1:length(chName)
    idx1 = 1;
    idx2 = 1;
    S1 = nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{3});%iidentity task all identities
    S1 = normalize(S1, 2);
    sigClustIDTask = nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{5});
    mx(idx1) = max(max(S1)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
    mn(idx2) = min(min(S1)); idx2 = idx2+1;
    S2 = nbackCompare.(chName{ii}).(conditionName{8}).(resultNameAll{8});%emotion task  all emotions
    S2 = normalize(S2, 2);
    sigClustEmTask = nbackCompare.(chName{ii}).(conditionName{8}).(resultNameAll{10});
    mx(idx1) = max(max(S2)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
    mn(idx2) = min(min(S2)); idx2 = idx2+1;

    if adjustedColorMap
        mxStd=std(mx); mnStd=-std(mn);
        mxMean=mean(mx); mnMean=mean(mn);
        mx(mx>=mxMean+mxStd*3)=[]; mn(mn<=mnMean+mnStd*3)=[]; %removes maxes that are over xsd
        %mx(mx>=mxMean)=[]; mn(mn<=mnMean)=[]; %removes maxes that are over the mean to better visualize changes.

        mxT=max(mx); mnT=min(mn);
    elseif flatColorMap
        mxT = 3; mnT = -3;
    end
    figtitle = strcat('Fig', num2str(figIdx), '  LFP Power during ', {' '}, figTitleName, ' Identities for ', {' '}, (chLocationName{ii}), {' '}, (chName{ii}));
   % figIdx = figIdx +1;
    figtitleSplit = strcat('LFP Power during ', {' '}, figTitleName, ' Identities for ', {' '}, (chLocationName{ii}), {' '}, (chName{ii}));
    figure('Name', figtitle{1}, 'Position', [10 100 1200 750]) %x bottom left, y bottom left, x width, y height
    sgtitle(compose(figtitleSplit)); %gives a supertitle

    subplot(2, 1, 1)
    mask = ones(size(S1)); %this fades the color except where positive
    if doMask
        mask = mask*maskPerc;
    end
    if nnz(sigClustIDTask)
        mask(logical(sigClustIDTask)) = 1;
        bw = bwperim(sigClustIDTask);
    else
        bw = zeros(size(sigClustIDTask));
    end
    minV= min(min(S1));
    S1(bw>0) = minV;
    im=imagesc(tt,ff, S1); axis xy;
    ax=gca;
    
    title(['Identity Task'])
   
        
   
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
    colormap(inferno(100));
    im.AlphaData = mask;
    %idx1 = idx1+2;
    
    
    %emotion task
    subplot(2, 1, 2)
    mask = ones(size(S2)); %this fades the color except where positive
    if doMask
        mask = mask*maskPerc;
    end
    if nnz(sigClustEmTask)
        mask(logical(sigClustEmTask)) = 1;
        bw = bwperim(sigClustEmTask);
    else
        bw = zeros(size(sigClustEmTask));
    end
    
    minV= min(min(S2));
    S2(bw>0) = minV;
    im=imagesc(tt,ff, S2); axis xy;
    ax=gca;
    
    title(['Emotion Task'])
    
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
    colormap(inferno(100));

    im.AlphaData = mask;
    %idx2 = idx2+2;

end


end
