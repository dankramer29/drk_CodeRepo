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
unitSt = 150; unitEnd = unitSt + 5;
idx1 = [1,2,5,6,9,10];
idx2 = idx1+2;
subplotSz = 6;

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
ii = 55; %choose the unit

%colorTempTest = {'#374d7c', '#46edc8'}; %mint and blue, can change the color here to any hex code.#E4287C is pink lemonade. and here is a good three #678CEC #D49BAE and #BBCB50 which is blue/pink/green
colorTempTest = {'#678CEC', '#D49BAE'}; %blue pink
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

%% PLOT multiple UNITS NEXT TO EACH OTHER

fignum = [49, 55, 72]; %choose the units

fignumIdx = 1:length(fignum)*2;
fignumIdxTop = 1:length(fignum);
fignumIdxBottom = fignumIdxTop + length(fignum);

%colorTempTest = {'#374d7c', '#46edc8'}; %mint and blue, can change the color here to any hex code.#E4287C is pink lemonade. and here is a good three #678CEC #D49BAE and #BBCB50 which is blue/pink/green
colorTempTest = {'#678CEC', '#D49BAE'}; %blue pink
for jj = 1:length(colorTempTest)
    str = colorTempTest{jj};
    C(jj,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

ttSt_realTime = 100; %ms before the center you want 
ttSt = interval.preStim - ttSt_realTime;
ttEnd_realTime = 1000;
ttEnd = +interval.preStim + ttEnd_realTime;
tt=-ttSt_realTime:ttEnd_realTime;
figure
for kk = 1:length(fignum)
    mnC = spkStimOn.congMean{1}(fignum(kk),ttSt:ttEnd);
    mnI = spkStimOn.incongMean{1}(fignum(kk),ttSt:ttEnd);
    sEC = spkStimOn.congSE{1}(fignum(kk),ttSt:ttEnd);
    sEI = spkStimOn.incongSE{1}(fignum(kk),ttSt:ttEnd);
    shP= shuffleHist{fignum(kk),2};
    shN= shuffleHist{fignum(kk),3};
    shPplt= repmat(shP,1,length(mnC));
    shNplt= repmat(shN,1,length(mnC));
    rstC = spkStimOn.congSpk{fignum(kk),1}(:,ttSt:ttEnd);
    rstI = spkStimOn.incongSpk{fignum(kk),1}(:, ttSt:ttEnd);
    rstComb = vertcat(rstC, rstI);
    sH = shuffleHist{fignum(kk),1};

    
    subplot(2,length(fignum),fignumIdxTop(kk))
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

    title(['Unit ' num2str(fignum(kk))])
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
    subplot(2,length(fignum),fignumIdxBottom(kk))
    plt.raster_plot(rstComb,'tm', tt, 'condSep', size(rstC, 1)+1, 'colorChoice', colorTempTest);
    xlim([tt(1)-1, tt(end)+1])%add the amount the raster plot makes the dash
end

%% plot units by response
%does 6 units (stim centered. only made it to 46. maybe unit 4, 12 has depression for all incongruent. 14
%depression. 17 is probably the best unit for this, looks to separate by
%button press and 18 too. 45 shows congruent but not incong activity and 46
%is a good one with different incong activity. 56 for response centered
%for all congruent
unitSt = 56; unitEnd = unitSt + 5;
colorTempTest = {'#F4C500', '#47181e',  '#f08ab1',  '#927db6', '#00b3e1',  '#87bf54' }; %orange, pink, brown, blue, purple, green, unsure of order



%colorTempTest = {'#678CEC', '#D49BAE'}; %blue pink
for fignum = 1:length(colorTempTest)
    str = colorTempTest{fignum};
    C(fignum,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

ttSt_realTime = 750; %ms before the center you want 
ttSt = interval.preResp-ttSt_realTime;
ttEnd_realTime = 500;
ttEnd = ttEnd_realTime+interval.preResp;
tt=-ttSt_realTime:ttEnd_realTime;

idx1 = [1,2,5,6,9,10];
idx2 = idx1+2;
subplotSz = 6;

idx = 1;
figure
for fignum = unitSt:unitEnd


    shP= shuffleHist{fignum,2};
    shN= shuffleHist{fignum,3};
    shPplt= repmat(shP,1,length(mnC));
    shNplt= repmat(shN,1,length(mnC));



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
    subplot(subplotSz,2,idx1(idx))
    for rr = 1:3
        mnC = spkResp.congMean{rr+1}(fignum,ttSt:ttEnd);
        sEC = spkResp.congSE{rr+1}(fignum,ttSt:ttEnd);
        H1 = shadedErrorBar(tt,mnC,sEC);
        H1.mainLine.LineWidth=2;
        H1.patch.FaceColor=C(rr,:);
        H1.patch.EdgeColor=C(rr,:);
        H1.mainLine.Color=C(rr,:);
        H1.edge(1).Color=C(rr,:);
        H1.edge(2).Color=C(rr,:);
        title(['Congruent Unit ' num2str(fignum)])
        ylabel('Firing Rate (Hz)')
        xlim([tt(1), tt(end)])       
        hold on
        h1 = plot(tt, shPplt);
        h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        h2 = plot(tt, shNplt);
        h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end
    if fignum == unitSt+1
        title(['Congruent Unit ' num2str(fignum)])
        ylabel('Firing Rate (Hz)')
        % lg = legend([H1.mainLine H2.mainLine],{'Congruent', 'Incongruent'});
        % set(lg, 'Units', 'normalized')
        % lg.Position = [0.8 0.5 0.15 0.05];
        xlim([tt(1), tt(end)])
    end
    subplot(subplotSz,2,idx2(idx))
    for rr = 1:3
        mnC = spkResp.incongMean{rr+1}(fignum,ttSt:ttEnd);
        sEC = spkResp.incongSE{rr+1}(fignum,ttSt:ttEnd);
        H1 = shadedErrorBar(tt,mnC,sEC);
        H1.mainLine.LineWidth=2;
        H1.patch.FaceColor=C(rr+3/2,:);
        H1.patch.EdgeColor=C(rr+3/2,:);
        H1.mainLine.Color=C(rr+3/2,:);
        H1.edge(1).Color=C(rr+3/2,:);
        H1.edge(2).Color=C(rr+3/2,:);
        title('Incongruent')
        xlim([tt(1), tt(end)])
        hold on
        h1 = plot(tt, shPplt);
        h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        h2 = plot(tt, shNplt);
        h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end

idx = idx+1;


end

%% response as above, but just one unit at a time or two units
% NOTE NEED TO WORK ON LEGENDS BUT DON'T HAVE TIME AND WILL DO BY HAND
unitSt = 56; 
unitEnd = 56;
colorTempTest = {'#F4C500', '#47181e',  '#f08ab1',  '#927db6', '#00b3e1',  '#87bf54' };  %orange, brown, pink, purple, blue, green, confirmed order

%colorTempTest = {'#678CEC', '#D49BAE'}; %blue pink
for fignum = 1:length(colorTempTest)
    str = colorTempTest{fignum};
    C(fignum,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

ttSt_realTime = 300; %ms before the center you want 
ttSt = interval.preResp-ttSt_realTime;
ttEnd_realTime = 200;
ttEnd = ttEnd_realTime+interval.preResp;
tt=-ttSt_realTime:ttEnd_realTime;

if unitSt == unitEnd
    idx1 = 1;
    idx2 = 2;
    subplotSz = 1;
else
    idx1 = [1,2,];
    idx2 = idx1+2;
    subplotSz = 2;
end

idx = 1;
figure
for fignum = unitSt:unitEnd


    shP= shuffleHist{fignum,2};
    shN= shuffleHist{fignum,3};
    shPplt= repmat(shP,1,length(tt));
    shNplt= repmat(shN,1,length(tt));
    subplot(subplotSz,2,idx1(idx))
    for rr = 1:3
        mnC = spkResp.congMean{rr+1}(fignum,ttSt:ttEnd);
        sEC = spkResp.congSE{rr+1}(fignum,ttSt:ttEnd);
        H1 = shadedErrorBar(tt,mnC,sEC);
        H1.mainLine.LineWidth=2;
        H1.patch.FaceColor=C(rr,:);
        H1.patch.EdgeColor=C(rr,:);
        H1.mainLine.Color=C(rr,:);
        H1.edge(1).Color=C(rr,:);
        H1.edge(2).Color=C(rr,:);
        title(['Congruent Unit ' num2str(fignum)])
        ylabel('Firing Rate (Hz)')
        xlim([tt(1), tt(end)])
        hold on
        h1 = plot(tt, shPplt);
        h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        h2 = plot(tt, shNplt);
        h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end
    if fignum == unitSt+1
        title(['Congruent Unit ' num2str(fignum)])
        ylabel('Firing Rate (Hz)')
        % lg = legend([H1.mainLine H2.mainLine],{'Congruent', 'Incongruent'});
        % set(lg, 'Units', 'normalized')
        % lg.Position = [0.8 0.5 0.15 0.05];
        xlim([tt(1), tt(end)])
    end
    subplot(subplotSz,2,idx2(idx))
    for rr = 1:3
        mnC = spkResp.incongMean{rr+1}(fignum,ttSt:ttEnd);
        sEC = spkResp.incongSE{rr+1}(fignum,ttSt:ttEnd);
        H1 = shadedErrorBar(tt,mnC,sEC);
        H1.mainLine.LineWidth=2;
        H1.patch.FaceColor=C(rr+3,:);
        H1.patch.EdgeColor=C(rr+3,:);
        H1.mainLine.Color=C(rr+3,:);
        H1.edge(1).Color=C(rr+3,:);
        H1.edge(2).Color=C(rr+3,:);
        title('Incongruent')
        xlim([tt(1), tt(end)])
        hold on
        h1 = plot(tt, shPplt);
        h1.Annotation.LegendInformation.IconDisplayStyle = 'off';
        h2 = plot(tt, shNplt);
        h2.Annotation.LegendInformation.IconDisplayStyle = 'off';
    end

idx = idx+1;


end


%% plot pca
plt.PCAcolorplt(out.score(1:2500,1), out.score(1:2500,2), 'data3', out.score(1:2500,3), 'colorChoice', {'#395886', '#B1C9EF'});

plt.PCAcolorplt(out.score(2501:end,1), out.score(2501:end,2), 'data3', out.score(2501:end,3), 'colorChoice', {'#341514', '#E17888'}, 'newFig', false);

