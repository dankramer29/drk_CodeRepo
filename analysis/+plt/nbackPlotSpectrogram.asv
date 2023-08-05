function [figIdxNow] = nbackPlotSpectrogram(nbackCompare, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[varargin, comparison]=util.argkeyval('comparison', varargin, 1); %toggle between 1, and 2 for now. 1 shows identity next to emotion. 2 shows difference, will want to load in stats between the two
[varargin, figTitleName]=util.argkeyval('figTitleName', varargin, 'Image On'); %Name of what you are comparing
[varargin, timePlot]=util.argkeyval('timePlot', varargin, []); %pull in the time plot vector
[varargin, frequencyRange]=util.argkeyval('frequencyRange', varargin, []); %pull in the frequency range
[varargin, chName]=util.argkeyval('chName', varargin, []); %use the channel names for labeling
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

for ii = 1:length(chNum)
    clear Sdiff; clear SdiffIDTask; clear SdiffEmTask;
    idx1 = 1;
    idx2 = 4;
    %% identities
    for jj = 1:8 %first do all identities
        if jj == 4 || jj == 8
            S1 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultNameAll{3});%identity task allIDs/allEmots mean
            S1 = normalize(S1, 2);
            sigClustIDTask{jj} = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultNameAll{5});
            mx(idx1) = max(max(S1)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S1)); idx2 = idx2+1;
            S2 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultNameAll{8});%emotion task allIDs/allEmots mean
            S2 = normalize(S2, 2);
            sigClustEmTask{jj} = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultNameAll{10});
            mx(idx1) = max(max(S2)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S2)); idx2 = idx2+1;
        else
            S1 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultName{1});%identity task mean
            S1 = normalize(S1, 2);
            sigClustIDTask{jj} = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultName{3});
            mx(idx1) = max(max(S1)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S1)); idx2 = idx2+1;
            S2 = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultName{6});%emotion task mean
            S2 = normalize(S2, 2);
            sigClustEmTask{jj} = nbackCompare.(chNum{ii}).(conditionName{jj}).(resultName{8});
            mx(idx1) = max(max(S2)); idx1 = idx1+1; %this is to get the colorbars to be equal across figures.
            mn(idx2) = min(min(S2)); idx2 = idx2+1;
        end
        switch comparison
            case 1
                SdiffIDTask{jj} = S1; %identity Task
                
                SdiffEmTask{jj} = S2; %emotion task
                
            case 2
                Sdiff{jj} = S1-S2; %identity - emotion
        end
    end
    %this adjusts the colormaps and prevents outliers from screwing it up.
    if adjustedColorMap
        mxStd=std(mx); mnStd=-std(mn);
        mxMean=mean(mx); mnMean=mean(mn);
        mx(mx>=mxMean+mxStd*3)=[]; mn(mn<=mnMean+mnStd*3)=[]; %removes maxes that are over xsd
        %mx(mx>=mxMean)=[]; mn(mn<=mnMean)=[]; %removes maxes that are over the mean to better visualize changes.

        mxT=max(mx); mnT=min(mn);
    elseif flatColorMap
        mxT = 3; mnT = -3;
    end


    %plot the identities for both tasks
    if comparison == 1
        %% identities for both tasks
        figtitle = strcat('Fig', num2str(figIdx), '  LFP Power during ', {' '}, figTitleName, ' Identities for ', {' '}, (chName{ii,1}), {' '}, (chNum{ii}));    
        figIdx = figIdx +1;
        figtitleSplit = strcat('LFP Power during ', {' '}, figTitleName, '\n', ' Identities for ', {' '}, (chName{ii,1}), {' '}, (chNum{ii})); 
        figure('Name', figtitle{1}, 'Position', [10 100 1200 750]) %x bottom left, y bottom left, x width, y height
        sgtitle(compose(figtitleSplit)); %gives a supertitle

    
        idx1 = 1; idx2 = 2; idx3 = 1;
        for jj = 1:4  
            
            %identity task
            subplot(4, 2, idx1)
            mask = ones(size(SdiffIDTask{jj})); %this fades the color except where positive
            if doMask
                mask = mask*maskPerc;
            end
            if nnz(sigClustIDTask{jj})
                mask(logical(sigClustIDTask{jj})) = 1;
                bw = bwperim(sigClustIDTask{jj});
            else
                bw = zeros(size(sigClustIDTask{jj}));
            end
            SS = SdiffIDTask{jj};
            minV= min(min(SS));
            SS(bw>0) = minV;
            im=imagesc(tt,ff, SS); axis xy;
            ax=gca;
            if jj == 4
                title(['Identity Task: All Faces '])
            else
                title(['Identity Task: Face ' num2str(idx3)])
            end
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
            colormap(inferno(100));
            im.AlphaData = mask;
            idx1 = idx1+2;
           
            %emotion task
            subplot(4, 2, idx2)
            mask = ones(size(SdiffEmTask{jj})); %this fades the color except where positive
            if doMask
                mask = mask*maskPerc;
            end
            if nnz(sigClustEmTask{jj})
                mask(logical(sigClustEmTask{jj})) = 1;
                bw = bwperim(sigClustEmTask{jj});
            else
                bw = zeros(size(sigClustEmTask{jj}));
            end
            SS = SdiffEmTask{jj};
            minV= min(min(SS));
            SS(bw>0) = minV;
            im=imagesc(tt,ff, SS); axis xy;
            ax=gca;
            if jj == 4
                title(['Emotion Task: All Faces '])
            else
                title(['Emotion Task: Face ' num2str(idx3)])
            end            
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
            colormap(inferno(100));
            
            im.AlphaData = mask;
            idx2 = idx2+2;
            idx3 = idx3+1;
          
        end
        %% emotions for both tasks
        figtitle = strcat('Fig', num2str(figIdx), '  LFP Power during ', {' '}, figTitleName, newline, ' Emotions for ', {' '}, (chName{ii,1}), {' '}, (chNum{ii}));        
        figIdx = figIdx +1;
        figure('Name', figtitle{1}, 'Position', [10 100 1200 750]) %x bottom left, y bottom left, x width, y height
        figtitleSplit = strcat('LFP Power during ', {' '}, figTitleName, '\n', ' Emotions for ', {' '}, (chName{ii,1}), {' '}, (chNum{ii}));
        sgtitle(compose(figtitleSplit)); %gives a supertitle

    
        idx1 = 1; idx2 = 2; idx3 = 1;
        for jj = 5:8
            %identity task
            subplot(4, 2, idx1)         
            mask = ones(size(SdiffIDTask{jj})); %this fades the color except where positive
            if doMask
                mask = mask*maskPerc;
            end
            if nnz(sigClustIDTask{jj})
                mask(logical(sigClustIDTask{jj})) = 1;
                bw = bwperim(sigClustIDTask{jj});
            else
                bw = zeros(size(sigClustIDTask{jj}));
            end
            SS = SdiffIDTask{jj};
            minV= min(min(SS));
            SS(bw>0) = minV;
            im=imagesc(tt,ff, SS); axis xy;
            ax=gca;
            if jj == 8
                title(['Identity Task: All Emotions '])
            else
                title(['Identity Task: Emotion ' num2str(idx3)])
            end
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
            colormap(inferno(100));
            im.AlphaData = mask;
            idx1 = idx1+2;


            %emotion task
            subplot(4, 2, idx2)
            mask = ones(size(SdiffEmTask{jj})); %this fades the color except where positive
            if doMask
                mask = mask*maskPerc;
            end
            if nnz(sigClustEmTask{jj})
                mask(logical(sigClustEmTask{jj})) = 1;
                bw = bwperim(sigClustEmTask{jj});
            else
                bw = zeros(size(sigClustEmTask{jj}));
            end
            SS = SdiffEmTask{jj};
            minV= min(min(SS));
            SS(bw>0) = minV;
            im=imagesc(tt,ff, SS); axis xy;
            ax=gca;
            if jj == 8
                title(['Emotion Task: All Emotions '])
            else
                title(['Emotion Task: Emotion ' num2str(idx3)])
            end            
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
            colormap(inferno(100));
            
            im.AlphaData = mask;
            idx2 = idx2+2;
            idx3 = idx3+1;          
            
        end

    else %THIS PART HAS NOT BEEN CHECKED RECENTLY AND WILL NEED TO BE ADJUSTED FOR NEW RESULTNAMES BUT ALSO JUST USE THE ONE ABOVE IT

        %ID 1
        subplot(6,4, [1 2 5 6])

        im=imagesc(tt,ff, Sdiff{1}); axis xy;
        ax=gca;
        title('Face 1')
        xlabel('Time (s)','Fontsize',13);
        ylabel('Frequency (Hz)','Fontsize',13);
        colorbar;
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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
        if flatColorMap || adjustedColorMap; caxis([mnT mxT]); end
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

figIdxNow = figIdx;




end