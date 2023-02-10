function [outputArg1,outputArg2] = nbackPlotSpectrogram(nbackCompare, varargin)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[varargin, sigComparison]=util.argkeyval('sigComparison', varargin, []); %can pull in some output that says which figures are significant
[varargin, timePlot]=util.argkeyval('timePlot', varargin, []); %pull in the time plot vector
[varargin, frequencyRange]=util.argkeyval('frequencyRange', varargin, []); %pull in the frequency range
[varargin, savePlots]=util.argkeyval('savePlots', varargin, true); %toggle through whether or not saving the plots is desired.



chName = fieldnames(nbackCompare); 

conditionName = fieldnames(nbackCompare.(chName{1}));

resultName = fieldnames(nbackCompare.(chName{1}).(conditionName{1}));

resultNameAll = fieldnames(nbackCompare.(chName{1}).(conditionName{4}));

if ~isempty(timePlot)
    tt = timePlot;
else
    tt = 1:size(nbackCompare.(chName{1}).(conditionName{1}).(resultName{1}),2);
end

if ~isempty(frequencyRange)
    ff = frequencyRange;
else
    ff = 1:size(nbackCompare.(chName{1}).(conditionName{1}).(resultName{1}),1);
end

siCluster = [];
for ii = 1:length(chName)
    idx1 = 1;
    for jj = 1:3 %first do all identities
        S1 = nbackCompare.(chName{ii}).(conditionName{jj}).(resultName{1});%identity task mean
        S2 = nbackCompare.(chName{ii}).(conditionName{jj}).(resultName{4});%emotion task mean
        Sdiff{jj} = S1-S2; %identity - emotion
    end
    S1 = nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{3});%identity task allIDs mean
    S2 = nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{6});%emotion task allIDs mean
    Sdiff{4} = S1-S2; %identity - emotion

    %plot the identities for both tasks
            figtitle=['IdentityTask minus EmotionTask for Face Identities for ', (chName{1}), ' Heatmap '];
            figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
            
            %ID 1
            subplot(6,4, [1 2 5 6])
            
            im=imagesc(tt,ff, Sdiff{1}); axis xy;
            ax=gca;
            title('Identity - Emotion for Face 1')
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
                    if nnz(nbackCompare.(chName{ii}).(conditionName{1}).(resultName{3}))
                    sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{1}).(resultName{3}));
                    subplot(6,4, 9)
                    im=imagesc(tt,ff, sigCluster); axis xy;
                    ax=gca;
                    title('Identity task')
                    colorbar;
                    colormap(inferno(100));
                    elseif nnz(nbackCompare.(chName{ii}).(conditionName{1}).(resultName{6}))
                    sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{1}).(resultName{6}));
                    subplot(6,4, 10)
                    im=imagesc(tt,ff, sigCluster); axis xy;
                    ax=gca;
                    title('Emotion task')
                    colorbar;
                    colormap(inferno(100));
                    end
            
            %ID 2
            subplot(6,4, [3 4 7 8])
            
            im=imagesc(tt,ff, Sdiff{2}); axis xy;
            ax=gca;
            title('Identity - Emotion for Face 2')
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
                if nnz(nbackCompare.(chName{ii}).(conditionName{2}).(resultName{3}))
                sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{2}).(resultName{3}));
                subplot(6,4, 11)
                im=imagesc(tt,ff, sigCluster); axis xy;
                ax=gca;
                title('Identity task')
                colorbar;
                colormap(inferno(100));
                elseif nnz(nbackCompare.(chName{ii}).(conditionName{2}).(resultName{6}))
                sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{2}).(resultName{6}));
                subplot(6,4, 12)
                im=imagesc(tt,ff, sigCluster); axis xy;
                ax=gca;
                title('Emotion task')
                colorbar;
                colormap(inferno(100));
                end

            %ID 3
            subplot(6,4, [13 14 17 18])
            
            im=imagesc(tt,ff, Sdiff{3}); axis xy;
            ax=gca;
            title('Identity - Emotion for Face 3')
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
                    if nnz(nbackCompare.(chName{ii}).(conditionName{3}).(resultName{3}))
                    sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{3}).(resultName{3}));
                    subplot(6,4, 9)
                    im=imagesc(tt,ff, sigCluster); axis xy;
                    ax=gca;
                    title('Identity task')
                    colorbar;
                    colormap(inferno(100));
                    elseif nnz(nbackCompare.(chName{ii}).(conditionName{3}).(resultName{6}))
                    sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{3}).(resultName{6}));
                    subplot(6,4, 10)
                    im=imagesc(tt,ff, sigCluster); axis xy;
                    ax=gca;
                    title('Emotion task')
                    colorbar;
                    colormap(inferno(100));
                    end

            %ALL IDs
            subplot(6,4, [15 16 19 20])
            
            im=imagesc(tt,ff, Sdiff{4}); axis xy;
            ax=gca;
            title('Identity - Emotion for All Faces')
            xlabel('Time (s)','Fontsize',13);
            ylabel('Frequency (Hz)','Fontsize',13);
            colorbar;
            colormap(inferno(100));
                    if nnz(nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{5}))
                    sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{5}));
                    subplot(6,4, 9)
                    im=imagesc(tt,ff, sigCluster); axis xy;
                    ax=gca;
                    title('Identity task')
                    colorbar;
                    colormap(inferno(100));
                    elseif nnz(nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{7}))
                    sigCluster = nnz(nbackCompare.(chName{ii}).(conditionName{4}).(resultNameAll{7}));
                    subplot(6,4, 10)
                    im=imagesc(tt,ff, sigCluster); axis xy;
                    ax=gca;
                    title('Emotion task')
                    colorbar;
                    colormap(inferno(100));
                    end           


end

end