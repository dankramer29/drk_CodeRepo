function [outputArg1,outputArg2] = nbackPlotSpectrogram(nbackCompare, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[varargin, comparison]=util.argkeyval('comparison', varargin, 1); %toggle between 1, 2, and 3. 1 is difference between Identity task and Emotion Task, 2 is just identity task, 3 is just emotion task
[varargin, timePlot]=util.argkeyval('timePlot', varargin, []); %pull in the time plot vector
[varargin, frequencyRange]=util.argkeyval('frequencyRange', varargin, []); %pull in the frequency range
[varargin, chName]=util.argkeyval('chName', varargin, []); %use the channel names for labeling

if comparison == 1
    comparisonTitle = 'Identity Task minus Emotion Task ';
elseif comparison == 2
    comparisonTitle = 'Identity Task ';
elseif comparison == 3
    comparisonTitle = 'Emotion Task ';
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
idx1 = 1;
idx2 = 1;
for ii = 1:length(chNum)
    clear Sdiff
    %% identities
    for jj = 1:8 %first do all identities
        if jj == 4 || jj == 8
            S1 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultNameAll{3});%identity task allIDs mean
            S1 = normalize(S1, 2);
            mx(idx1) = max(max(S1)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S1)); idx2 = idx2+1;
            S2 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultNameAll{6});%emotion task allIDs mean
            S2 = normalize(S2, 2);
            mx(idx1) = max(max(S2)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S2)); idx2 = idx2+1;
        else
            S1 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultName{1});%identity task mean
            S1 = normalize(S1, 2);
            mx(idx1) = max(max(S1)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S1)); idx2 = idx2+1;
            S2 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultName{4});%emotion task mean
            S2 = normalize(S2, 2);
            mx(idx1) = max(max(S2)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S2)); idx2 = idx2+1;
        end
        switch comparison
            case 1
                Sdiff{jj} = S1-S2; %identity - emotion
            case 2
                Sdiff{jj} = S1; %identity task
            case 3
                Sdiff{jj} = S2; % emotion task
        end
    end
    %this adjusts the colormaps and prevents outliers from screwing it up.   
    mxStd=std(mx); mnStd=-std(mn);
    mxMean=mean(mx); mnMean=mean(mn);
    mx(mx>=mxMean+mxStd*3)=[]; mn(mn<=mnMean+mnStd*3)=[]; %removes maxes that are over xsd
        %mx(mx>=mxMean)=[]; mn(mn<=mnMean)=[]; %removes maxes that are over the mean to better visualize changes.

    mxT=max(mx); mnT=min(mn);


    %plot the identities for both tasks
    
    figtitle=[comparisonTitle, 'for Face Identities for ', (chName{ii,1}), ' ', (chNum{ii}), ' Heatmap '];

    figure('Name', figtitle, 'Position', [10 100 1200 750]) %x bottom left, y bottom left, x width, y height
    sgtitle(figtitle); %gives a supertitle

    %ID 1
    subplot(6,4, [1 2 5 6])

    im=imagesc(tt,ff, Sdiff{1}); axis xy;
    ax=gca;
    title('Face 1')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar; caxis([mnT mxT]);
    colormap(inferno(100));
    if nnz(nbackCompare.(chNum{ii}).(conditionName{1}).(resultName{3}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{1}).(resultName{3});
        subplot(6,4, 9)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')        
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{1}).(resultName{6}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{1}).(resultName{6});
        subplot(6,4, 10)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end

    %ID 2
    subplot(6,4, [3 4 7 8])

    im=imagesc(tt,ff, Sdiff{2}); axis xy;
    ax=gca;
    title('Face 2')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100)); 
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{2}).(resultName{3}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{2}).(resultName{3});
        subplot(6,4, 11)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{2}).(resultName{6}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{2}).(resultName{6});
        subplot(6,4, 12)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end

    %ID 3
    subplot(6,4, [13 14 17 18])

    im=imagesc(tt,ff, Sdiff{3}); axis xy;
    ax=gca;
    title('Face 3')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100));
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{3}).(resultName{3}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{3}).(resultName{3});
        subplot(6,4, 9)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{3}).(resultName{6}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{3}).(resultName{6});
        subplot(6,4, 10)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end

    %ALL IDs
    subplot(6,4, [15 16 19 20])

    im=imagesc(tt,ff, Sdiff{4}); axis xy;
    ax=gca;
    title('All Faces')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100));
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{4}).(resultNameAll{5}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{4}).(resultNameAll{5});
        subplot(6,4, 9)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{4}).(resultNameAll{8}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{4}).(resultNameAll{8});
        subplot(6,4, 10)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    %% now the emotions
    idx = 1;
    

    %plot the identities for both tasks
    figtitle=[comparisonTitle, 'for Emotion Identities for ', (chName{ii,1}), ' ', (chNum{ii}), ' Heatmap '];

    figure('Name', figtitle, 'Position', [10 100 1200 750]) %x bottom left, y bottom left, x width, y height
    sgtitle(figtitle); %gives a supertitle

    %Emotion 1
    subplot(6,4, [1 2 5 6])

    im=imagesc(tt,ff, Sdiff{5}); axis xy;
    ax=gca;
    title('Emotion 1')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100));
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{4}).(resultName{3}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{4}).(resultName{3});
        subplot(6,4, 9)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    elseif nnz(nbackCompare.(chNum{ii}).(conditionName{4}).(resultName{6}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{4}).(resultName{6});
        subplot(6,4, 10)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end

    %Emotion 2
    subplot(6,4, [3 4 7 8])

    im=imagesc(tt,ff, Sdiff{6}); axis xy;
    ax=gca;
    title('Emotion 2')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100));
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{5}).(resultName{3}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{5}).(resultName{3});
        subplot(6,4, 11)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{5}).(resultName{6}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{5}).(resultName{6});
        subplot(6,4, 12)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end

    %Emotion 3
    subplot(6,4, [13 14 17 18])

    im=imagesc(tt,ff, Sdiff{7}); axis xy;
    ax=gca;
    title('Emotion 3')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100));
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{6}).(resultName{3}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{6}).(resultName{3});
        subplot(6,4, 9)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{6}).(resultName{6}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{6}).(resultName{6});
        subplot(6,4, 10)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end

    %ALL Emotions
    subplot(6,4, [15 16 19 20])

    im=imagesc(tt,ff, Sdiff{8}); axis xy;
    ax=gca;
    title('All Emotions')
    xlabel('Time (s)','Fontsize',13);
    ylabel('Frequency (Hz)','Fontsize',13);
    colorbar;
    colormap(inferno(100));
    caxis([mnT mxT]);
    if nnz(nbackCompare.(chNum{ii}).(conditionName{8}).(resultNameAll{5}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{8}).(resultNameAll{5});
        subplot(6,4, 9)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Identity task significance mask')
        colorbar;
        colormap(inferno(100));
    end
    if nnz(nbackCompare.(chNum{ii}).(conditionName{8}).(resultNameAll{8}))
        sigCluster = nbackCompare.(chNum{ii}).(conditionName{8}).(resultNameAll{8});
        subplot(6,4, 10)
        im=imagesc(tt,ff, sigCluster); axis xy;
        ax=gca;
        title('Emotion task significance mask')
        colorbar;
        colormap(inferno(100));
    end


end






end