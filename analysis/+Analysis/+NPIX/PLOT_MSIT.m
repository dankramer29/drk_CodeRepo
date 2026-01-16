% for plotting and next analysis

colorTempTest = {'#678CEC', '#D49BAE'}; %can change the color here to any hex code.#E4287C is pink lemonade. and here is a good three #678CEC #D49BAE and #BBCB50 which is blue/pink/green
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end



% for plotting units
tt= -500:1499;
%does 10 units
idx1 = [1,2,5,6,9,10,13,14,17,18];
idx2 = idx1+2;
unitSt = 1; unitEnd = unitSt + 9;
%does 6 units
idx1 = [1,2,5,6,9,10];
idx2 = idx1+2;
unitSt = 1; unitEnd = unitSt + 6;

idx = 1;
figure
for ii = unitSt:unitEnd
    mn = spkStimOn.smMean(ii,:);
    sd= spkStimOn.smSTD(ii,:);
    sE = sd/sqrt((size(spkStimOn.spk{1},1)));
    shP= shuffleHist{ii,2};
    shN= shuffleHist{ii,3};
    shPplt= repmat(shP,1,length(mn));
    shNplt= repmat(shN,1,length(mn));
    rst = spkStimOn.spk{ii}(:, 251:end-250); %TO DO, FIX THIS IN PARSE SO IT CUTS THE TAILS OFF
    sH = shuffleHist{ii,1};

    %plots individual units
    % figure
    % subplot(3,1,1)
    % plot(tt,mn)
    % %shadedErrorBar(tt,mn,std);
    % hold on
    % plot(tt, shPplt)
    % plot(tt, shNplt)
    % subplot(3,1,2)
    % plt.raster_plot(rst,'tm', tt);
    % subplot(3,1,3)
    % histogram(sH, 50);

    %plots a bunch of units    
    subplot(10,2,idx1(idx))
    plot(tt,mn)
    shadedErrorBar(tt,mn,sE);
    title(['Unit ' num2str(ii)])
    ylabel('Firing Rate (Hz)')

    hold on
    plot(tt, shPplt)
    plot(tt, shNplt)
    subplot(10,2,idx2(idx))
    plt.raster_plot(rst,'tm', tt);
    idx = idx+1;
end


%% for doing multiple units at the same time
% CONDITION BASED
% for plotting units
%does 10 units
tt= -500:1499;
idx1 = [1,2,5,6,9,10,13,14,17,18];
idx2 = idx1+2;
subplotSz = 10;

unitSt = 70; unitEnd = unitSt + 9;

idx = 1;
figure
for ii = unitSt:unitEnd

    mnC = spkStimOn.congMean{1}(ii,ttSt:ttEnd);    
    mnI = spkStimOn.incongMean{1}(ii,ttSt:ttEnd);
    sEC = spkStimOn.congSE{1}(ii,ttSt:ttEnd);    
    sEI = spkStimOn.incongSE{1}(ii,ttSt:ttEnd);
    shP= shuffleHist{ii,2};
    shN= shuffleHist{ii,3};
    shPplt= repmat(shP,1,length(mnC));
    shNplt= repmat(shN,1,length(mnC));
    rstC = spkStimOn.congSpk{ii,1}(:, ttSt:ttEnd); 
    rstI = spkStimOn.incongSpk{ii,1}(:, ttSt:ttEnd); 
    rstComb = vertcat(rstC, rstI);
    sH = shuffleHist{ii,1};
    
    %plots individual units
    % figure
    % subplot(3,1,1)
    % plot(tt,mn)
    % %shadedErrorBar(tt,mn,std);
    % hold on
    % plot(tt, shPplt)
    % plot(tt, shNplt)
    % subplot(3,1,2)
    % plt.raster_plot(rst,'tm', tt);
    % subplot(3,1,3)
    % histogram(sH, 50);
    
    if ii == unitSt+1
        %plots a bunch of units
        subplot(subplotSz,2,idx1(idx))
        %plot(tt,mn)
        H1 = shadedErrorBar(tt,mnC,sEC);
        H1.mainLine.LineWidth=1;
        H1.patch.FaceColor=C(1,:);
        H1.patch.EdgeColor=C(1,:);
        H1.mainLine.Color=C(1,:);
        H1.edge(1).Color=C(1,:);
        H1.edge(2).Color=C(1,:);

        hold on
        H2 = shadedErrorBar(tt,mnI,sEI);
        H2.mainLine.LineWidth=1;
        H2.patch.FaceColor=C(2,:);
        H2.patch.EdgeColor=C(2,:);
        H2.mainLine.Color=C(2,:);
        H2.edge(1).Color=C(2,:);
        H2.edge(2).Color=C(2,:);

        title(['Unit ' num2str(ii)])
        ylabel('Firing Rate (Hz)')
        lg = legend([H1.mainLine H2.mainLine],{'Congruent', 'Incongruent'});
        set(lg, 'Units', 'normalized')
        lg.Position = [0.8 0.5 0.15 0.05];
        xlim([tt(1), tt(end)])

    else
        subplot(subplotSz,2,idx1(idx))
        %plot(tt,mn)
        H3 = shadedErrorBar(tt,mnC,sEC);
        H3.mainLine.LineWidth=1;
        H3.patch.FaceColor=C(1,:);
        H3.patch.EdgeColor=C(1,:);
        H3.mainLine.Color=C(1,:);
        H3.edge(1).Color=C(1,:);
        H3.edge(2).Color=C(1,:);

        hold on
        H4 = shadedErrorBar(tt,mnI,sEI);
        H4.mainLine.LineWidth=1;
        H4.patch.FaceColor=C(2,:);
        H4.patch.EdgeColor=C(2,:);
        H4.mainLine.Color=C(2,:);
        H4.edge(1).Color=C(2,:);
        H4.edge(2).Color=C(2,:);

        title(['Unit ' num2str(ii)])
        ylabel('Firing Rate (Hz)')
        xlim([tt(1), tt(end)])

    end

    hold on
    h1 = plot(tt, shPplt);
    h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
    h2 = plot(tt, shNplt);
    h2.Annotation.LegendInformation.IconDisplayStyle = 'off';

    subplot(subplotSz,2,idx2(idx))
    plt.raster_plot(rstComb,'tm', tt, 'condSep', size(rstC, 1)+1, 'colorChoice', colorTempTest);
    xlim([tt(1), tt(end)])

    idx = idx+1;
end
%% 
%does 6 units
unitSt = 11; unitEnd = unitSt + 5;

colorTempTest = {'#374d7c', '#46edc8'}; %mint and blue, can change the color here to any hex code.#E4287C is pink lemonade. and here is a good three #678CEC #D49BAE and #BBCB50 which is blue/pink/green
%colorTempTest = {'#678CEC', '#D49BAE'}; %blue pink
for ii = 1:length(colorTempTest)
    str = colorTempTest{ii};
    C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

ttSt_realTime = 100; %ms before the center you want 
ttSt = interval.preStim-ttSt_realTime;
ttEnd_realTime = 1000;
ttEnd = ttEnd_realTime+interval.preStim;
tt=-ttSt_realTime:ttEnd_realTime;

idx1 = [1,2,5,6,9,10];
idx2 = idx1+2;
subplotSz = 6;

idx = 1;
figure
for ii = unitSt:unitEnd

    mnC = spkStimOn.congMean{1}(ii,ttSt:ttEnd);    
    mnI = spkStimOn.incongMean{1}(ii,ttSt:ttEnd);
    sEC = spkStimOn.congSE{1}(ii,ttSt:ttEnd);    
    sEI = spkStimOn.incongSE{1}(ii,ttSt:ttEnd);
    shP= shuffleHist{ii,2};
    shN= shuffleHist{ii,3};
    shPplt= repmat(shP,1,length(mnC));
    shNplt= repmat(shN,1,length(mnC));
    rstC = spkStimOn.congSpk{ii,1}(:, ttSt:ttEnd); 
    rstI = spkStimOn.incongSpk{ii,1}(:, ttSt:ttEnd); 
    rstComb = vertcat(rstC, rstI);
    sH = shuffleHist{ii,1};
    
    %plots individual units
    % figure
    % subplot(3,1,1)
    % plot(tt,mn)
    % %shadedErrorBar(tt,mn,std);
    % hold on
    % plot(tt, shPplt)
    % plot(tt, shNplt)
    % subplot(3,1,2)
    % plt.raster_plot(rst,'tm', tt);
    % subplot(3,1,3)
    % histogram(sH, 50);
    
    if ii == unitSt+1
        %plots a bunch of units
        subplot(subplotSz,2,idx1(idx))
        %plot(tt,mn)
        H1 = shadedErrorBar(tt,mnC,sEC);
        H1.mainLine.LineWidth=1;
        H1.patch.FaceColor=C(1,:);
        H1.patch.EdgeColor=C(1,:);
        H1.mainLine.Color=C(1,:);
        H1.edge(1).Color=C(1,:);
        H1.edge(2).Color=C(1,:);

        hold on
        H2 = shadedErrorBar(tt,mnI,sEI);
        H2.mainLine.LineWidth=1;
        H2.patch.FaceColor=C(2,:);
        H2.patch.EdgeColor=C(2,:);
        H2.mainLine.Color=C(2,:);
        H2.edge(1).Color=C(2,:);
        H2.edge(2).Color=C(2,:);

        title(['Unit ' num2str(ii)])
        ylabel('Firing Rate (Hz)')
        lg = legend([H1.mainLine H2.mainLine],{'Congruent', 'Incongruent'});
        set(lg, 'Units', 'normalized')
        lg.Position = [0.8 0.5 0.15 0.05];
        xlim([tt(1), tt(end)])

    else
        subplot(subplotSz,2,idx1(idx))
        %plot(tt,mn)
        H3 = shadedErrorBar(tt,mnC,sEC);
        H3.mainLine.LineWidth=1;
        H3.patch.FaceColor=C(1,:);
        H3.patch.EdgeColor=C(1,:);
        H3.mainLine.Color=C(1,:);
        H3.edge(1).Color=C(1,:);
        H3.edge(2).Color=C(1,:);

        hold on
        H4 = shadedErrorBar(tt,mnI,sEI);
        H4.mainLine.LineWidth=1;
        H4.patch.FaceColor=C(2,:);
        H4.patch.EdgeColor=C(2,:);
        H4.mainLine.Color=C(2,:);
        H4.edge(1).Color=C(2,:);
        H4.edge(2).Color=C(2,:);

        title(['Unit ' num2str(ii)])
        ylabel('Firing Rate (Hz)')
        xlim([tt(1), tt(end)])

    end

    hold on
    h1 = plot(tt, shPplt);
    h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
    h2 = plot(tt, shNplt);
    h2.Annotation.LegendInformation.IconDisplayStyle = 'off';

    subplot(subplotSz,2,idx2(idx))
    plt.raster_plot(rstComb,'tm', tt, 'condSep', size(rstC, 1)+1, 'colorChoice', colorTempTest);
    xlim([tt(1), tt(end)])

    idx = idx+1;
end


%% plot a single unit
ii = 6; %choose the unit

colorTempTest = {'#374d7c', '#46edc8'}; %mint and blue, can change the color here to any hex code.#E4287C is pink lemonade. and here is a good three #678CEC #D49BAE and #BBCB50 which is blue/pink/green
%colorTempTest = {'#678CEC', '#D49BAE'}; %blue pink
for jj = 1:length(colorTempTest)
    str = colorTempTest{jj};
    C(jj,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

ttSt_realTime = 100; %ms before the center you want 
ttSt = interval.preStim - ttSt_realTime;
ttEnd_realTime = 1000;
ttEnd = +interval.preStim + ttEnd_realTime;
tt=-ttSt_realTime:ttEnd_realTime;


mnC = spkStimOn.congMean{1}(ii,ttSt:ttEnd);
mnI = spkStimOn.incongMean{1}(ii,ttSt:ttEnd);
sEC = spkStimOn.congSE{1}(ii,ttSt:ttEnd);
sEI = spkStimOn.incongSE{1}(ii,ttSt:ttEnd);
shP= shuffleHist{ii,2};
shN= shuffleHist{ii,3};
shPplt= repmat(shP,1,length(mnC));
shNplt= repmat(shN,1,length(mnC));
rstC = spkStimOn.congSpk{ii,1}(:,ttSt:ttEnd);
rstI = spkStimOn.incongSpk{ii,1}(:, ttSt:ttEnd);
rstComb = vertcat(rstC, rstI);
sH = shuffleHist{ii,1};

figure
subplot(2,1,1)
%plot(tt,mn)
H1 = shadedErrorBar(tt,mnC,sEC);
H1.mainLine.LineWidth=1;
H1.patch.FaceColor=C(1,:);
H1.patch.EdgeColor=C(1,:);
H1.mainLine.Color=C(1,:);
H1.edge(1).Color=C(1,:);
H1.edge(2).Color=C(1,:);

hold on
H2 = shadedErrorBar(tt,mnI,sEI);
H2.mainLine.LineWidth=1;
H2.patch.FaceColor=C(2,:);
H2.patch.EdgeColor=C(2,:);
H2.mainLine.Color=C(2,:);
H2.edge(1).Color=C(2,:);
H2.edge(2).Color=C(2,:);

title(['Unit ' num2str(ii)])
ylabel('Firing Rate (Hz)')
lg = legend([H1.mainLine H2.mainLine],{'Congruent', 'Incongruent'}, 'Location', 'northeast');
set(lg, 'Units', 'normalized')
%lg.Position = [0.8 0.5 0.15 0.05];

hold on
h1 = plot(tt, shPplt);
h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
h2 = plot(tt, shNplt);
h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
xlim([tt(1), tt(end)])
subplot(2,1,2)
plt.raster_plot(rstComb,'tm', tt, 'condSep', size(rstC, 1)+1, 'colorChoice', colorTempTest);
xlim([tt(1), tt(end)])


%% plot pca
plt.PCAcolorplt(out.score(1:2500,1), out.score(1:2500,2), 'data3', out.score(1:2500,3), 'colorChoice', {'#395886', '#B1C9EF'});

plt.PCAcolorplt(out.score(2501:end,1), out.score(2501:end,2), 'data3', out.score(2501:end,3), 'colorChoice', {'#341514', '#E17888'}, 'newFig', false);

