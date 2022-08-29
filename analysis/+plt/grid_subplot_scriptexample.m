%%THIS IS A SCRIPT FOR RUNNING VARIOUS SUBPLOTS FROM ARTSENSE_PROC and specifically RUN_script_artsens


%this FIRST PART is an example of how to use the plot.grid_subplot to make a subplot,
%it's too individual for each plot to be able to generalize, but will give
%an idea.  i will try to annotate further in the future

% The rest is a variety of different plot examples for artsens_proc outputs 

gridtype=1;
orientation=1;

specgramc=specgramcBM2;
blc=blcBM2;
touch=fields(specgramc);


%ch2plot=plot.grid_subplot('gridtype', gridtype, 'orientation', orientation);
ch2plotTemp=[];
if gridtype==1 %if mini
    labels={blc.ChannelInfo.Label};
    loc=cellfun(@(x)strcmpi(x,'MG1'), labels, 'UniformOutput', false);
    loc=cell2mat(loc);
    row_buff=find(loc==1); %this is the buffer to add to the row to make your matrix rows match up
    ch2plotTemp=ch2plot+row_buff-1; %now the rows match up to the channels
end


%makes a grid plot figure
for ff=1:length(touch)    
       
       
       
       %figtitle=['Power across the grid ',  blc.SourceBasename, ' ', ecog.evtNames{ff}];
       %figure('Name', figtitle, 'Position', [5 150 1200 750]) %x bottom left, y bottom left, x width, y height
       figure
       [rw,cl]=size(ch2plotTemp);
       ch2plot_order=ch2plotTemp'; %it is flipped in order to go in the same order as the subplot      
       %"normalize" the colors next to each other, it excludes outliers
       %(anything over 2sd from the mean)
       for ii=1:rw*cl
           mx(ii)=max(max(specgramc.(touch{ff}).(blc.ChannelInfo(ch2plot_order(ii)).Label)));
           mn(ii)=min(min(specgramc.(touch{ff}).(blc.ChannelInfo(ch2plot_order(ii)).Label)));
       end
       mx(isoutlier(mx))=[];
       mn(isoutlier(mn))=[];
       mxT=max(mx); mnT=min(mn);
       for ii=1:rw*cl
           
           subplot(rw,cl, ii);
           %im=imagesc(tplot,f, heatpow); axis xy;
           im=imagesc(tplot,f, specgramc.(touch{ff}).(blc.ChannelInfo(ch2plot_order(ii)).Label)); axis xy;
           ax=gca;
           caxis([mnT mxT])
           ax.Position(3)=0.19;
           ax.Position(1)=ax.Position(1)-0.03;
           ax.FontSize=22;
           ax.FontName='Arial';
           xlim([-0.1 1.6]); %only show the plot buffer pre and buffer post
           %title([' Channel ', blc.ChannelInfo(ch2plot_order(ii)).Label])
           colorbar
           colormap(inferno(100))
           
           
       end 
end


%to make a subplot of the average power at the different frequency bands,
%requires running:

% [ temp2.bm]=ArtSens.specpeak( specPowerBM2, Nstep, Nwin, specgramcBM2.SoftTouch.t, 'window', [0.2 0.005]);
% %[ temp2.cg]=ArtSens.specpeak( specPowerCG2, Nstep, Nwin, specgramcCG2.SoftTouch.t, 'window', [0.2 0.005]);
% [ temp2.eg]=ArtSens.specpeak( specPowerEG2, Nstep, Nwin, specgramcEG2.SoftTouch.t, 'window', [0.2 0.005]);
% [ temp2.jo]=ArtSens.specpeak( specPowerJO2, Nstep, Nwin, specgramcJO2.SoftTouch.t, 'window', [0.2 0.005]);
% [ temp2.jr]=ArtSens.specpeak( specPowerJR2, Nstep, Nwin, specgramcJR2.SoftTouch.t, 'window', [0.2 0.005]);
% 
% [ temp5.bm]=ArtSens.specpeak( specPowerBM2, Nstep, Nwin, specgramcBM5.SoftTouch.t, 'window', [0.5 0.005]);
% %[ temp5.cg]=ArtSens.specpeak( specPowerCG5, Nstep, Nwin, specgramcCG5.SoftTouch.t, 'window', [0.5 0.005]);
% [ temp5.eg]=ArtSens.specpeak( specPowerEG5, Nstep, Nwin, specgramcEG5.SoftTouch.t, 'window', [0.5 0.005]);
% [ temp5.jo]=ArtSens.specpeak( specPowerJO5, Nstep, Nwin, specgramcJO5.SoftTouch.t, 'window', [0.5 0.005]);
% [ temp5.jr]=ArtSens.specpeak( specPowerJR5, Nstep, Nwin, specgramcJR5.SoftTouch.t, 'window', [0.5 0.005]);
%%
N=36;
C=linspecer(N); 
ch_2plot=34;
ss=4;

tt256=-0.5:2.5/640:2-2.5/640;
tt=-0.5:2.5/500:2-2.5/500;

% plot the averages for the different bands
figure
set(0, 'DefaultAxesFontSize', 22)
hold on
subplot(4,1,1)
hold on
H=shadedErrorBar(tt256,real(allpeakS.(nmes{ss}).DeepTouch(7).Alpha(:,1)),real(allpeakS.(nmes{ss}).DeepTouch(7).Alpha(:,2)),'lineprops', {'-r', 'markerfacecolor', C(1,:)});
H.mainLine.LineWidth=4;
H=shadedErrorBar(tt256,real(allpeakS.(nmes{ss}).LightTouch(2).Alpha(:,1)),real(allpeakS.(nmes{ss}).DeepTouch(2).Alpha(:,2)),'lineprops', {'-g', 'markerfacecolor', C(7,:)});
H.mainLine.LineWidth=4;
H=shadedErrorBar(tt256,real(allpeakS.(nmes{ss}).SoftTouch(3).Alpha(:,1)),real(allpeakS.(nmes{ss}).SoftTouch(3).Alpha(:,2)),'lineprops', {'-b', 'markerfacecolor', C(3,:)});
H.mainLine.LineWidth=4;
%plot(tt,.DeepTouch(ch_2plot).Alpha, 'LineWidth', 3, 'color', C(1, :))
plot(tt,temp5d.LightTouch(ch_2plot).Alpha, 'LineWidth', 3, 'color', C(3, :), 'LineStyle', '--')
plot(tt,temp5d.SoftTouch(ch_2plot).Alpha, 'LineWidth', 3, 'color', C(6, :), 'LineStyle', ':')
xlim([-0.1 1.6]); ylim([-50 5]); legend('DT', 'LT', 'ST');
subplot(4,1,2)
hold on
plot(tt,temp5d.DeepTouch(ch_2plot).Beta, 'LineWidth', 3, 'color', C(7, :))
plot(tt,temp5d.LightTouch(ch_2plot).Beta, 'LineWidth', 3, 'color', C(10, :), 'LineStyle', '--')
plot(tt,temp5d.SoftTouch(ch_2plot).Beta, 'LineWidth', 3, 'color', C(13, :), 'LineStyle', ':')
xlim([-0.1 1.6]); ylim([-50 4]);legend('DT', 'LT', 'ST');
subplot(4,1,3)
hold on
plot(tt,temp2d.DeepTouch(ch_2plot).Gamma, 'LineWidth', 3, 'color', C(24, :))
plot(tt,temp2d.LightTouch(ch_2plot).Gamma, 'LineWidth', 3, 'color', C(26, :), 'LineStyle', '--')
plot(tt,temp2d.SoftTouch(ch_2plot).Gamma, 'LineWidth', 3, 'color', C(29, :), 'LineStyle', ':')
xlim([-0.1 1.6]); ylim([-40 0]);legend('DT', 'LT', 'ST');
subplot(4,1,4)
hold on
plot(tt,temp2d.DeepTouch(ch_2plot).HighGamma, 'LineWidth', 3, 'color', C(30, :))
plot(tt,temp2d.LightTouch(ch_2plot).HighGamma, 'LineWidth', 3, 'color', C(33, :), 'LineStyle', '--')
plot(tt,temp2d.SoftTouch(ch_2plot).HighGamma, 'LineWidth', 3, 'color', C(36, :), 'LineStyle', ':')
xlim([-0.1 1.6]); ylim([-20 24]); legend('DT', 'LT', 'ST');
ylim([-44 0])

%%
N=36;
C=linspecer(N); 
nmes=fields(allpeakS);
touch=fields(allpeakS.bm);


% plot the averages for the different bands
for ii=1:length(nmes)
    for jj=1:length(touch)
        if ii==3 && jj==3
            break
        else
            %get this from running PEAKS_script
            tmp1means.(nmes{ii}).(touch{jj})=squeeze(mean(allpeakSmat.(nmes{ii}).(touch{jj}),1));
           
        end
    end
end

%%
% plot the averages for the different bands for each subject individually

figure
set(0, 'DefaultAxesFontSize', 22)
hold on




tt2.bm=specgramcBM2.DeepTouch.t;
tt5.bm=specgramcBM5.DeepTouch.t;
tt2.eg=specgramcEG2.DeepTouch.t;
tt5.eg=specgramcEG5.DeepTouch.t;
tt2.jo=specgramcJO2.DeepTouch.t;
tt5.jo=specgramcJO5.DeepTouch.t;
tt2.jr=specgramcJR2.DeepTouch.t;
tt5.jr=specgramcJR5.DeepTouch.t;

for ii=1:length(nmes)
   
    subplot(4,4,ii)
    hold on
    %Alpha
    if ii~=3
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{3})(2,:), 'LineWidth', 3, 'color', C(1, :))
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{2})(2,:), 'LineWidth', 3, 'color', C(3, :), 'LineStyle', '--')
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{1})(2,:), 'LineWidth', 3, 'color', C(6, :), 'LineStyle', ':')
        legend('DT', 'LT', 'ST');

    else
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{2})(2,:), 'LineWidth', 3, 'color', C(3, :), 'LineStyle', '--')
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{1})(2,:), 'LineWidth', 3, 'color', C(6, :), 'LineStyle', ':')
        legend('LT', 'ST');
    end
    axis tight
    xlim([0 1.6]); 
    
    
    subplot(4,4,(ii+4))
    hold on
    %Beta
    if ii~=3
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{3})(3,:), 'LineWidth', 3, 'color', C(7, :))
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{2})(3,:), 'LineWidth', 3, 'color', C(10, :), 'LineStyle', '--')
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{1})(3,:), 'LineWidth', 3, 'color', C(13, :), 'LineStyle', ':')
        legend('DT', 'LT', 'ST');
       
    else
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{2})(3,:), 'LineWidth', 3, 'color', C(10, :), 'LineStyle', '--')
        plot(tt5.(nmes{ii}),tmp1means.(nmes{ii}).(touch{1})(3,:), 'LineWidth', 3, 'color', C(13, :), 'LineStyle', ':')
        legend('LT', 'ST');
    end
    axis tight
    xlim([0 1.6]);   
    
    
    subplot(4,4,(ii+8))
    hold on
    %Gamma
    if ii~=3
        plot(tt,tmp1means.(nmes{ii}).(touch{3})(4,:), 'LineWidth', 3, 'color', C(24, :))
        
        plot(tt,tmp1means.(nmes{ii}).(touch{2})(4,:), 'LineWidth', 3, 'color', C(26, :), 'LineStyle', '--')
        plot(tt,tmp1means.(nmes{ii}).(touch{1})(4,:), 'LineWidth', 3, 'color', C(29, :), 'LineStyle', ':')
        legend('DT', 'LT', 'ST');
       
    else
        
        plot(tt,tmp1means.(nmes{ii}).(touch{2})(4,:), 'LineWidth', 3, 'color', C(26, :), 'LineStyle', '--')
        plot(tt,tmp1means.(nmes{ii}).(touch{1})(4,:), 'LineWidth', 3, 'color', C(29, :), 'LineStyle', ':')
        legend('LT', 'ST');
    end
    axis tight
    xlim([0 1.6]);
    
    
    subplot(4,4,(ii+12))
    hold on
    %High gamma
    if ii~=3
        plot(tth,tmp1means.(nmes{ii}).(touch{3})(1,:), 'LineWidth', 3, 'color', C(30, :))
        plot(tth,tmp1means.(nmes{ii}).(touch{2})(1,:), 'LineWidth', 3, 'color', C(33, :), 'LineStyle', '--')
        plot(tth,tmp1means.(nmes{ii}).(touch{1})(1,:), 'LineWidth', 3, 'color', C(36, :), 'LineStyle', ':')
        legend('DT', 'LT', 'ST');
        
    else
        plot(tth,tmp1means.(nmes{ii}).(touch{2})(1,:), 'LineWidth', 3, 'color', C(33, :), 'LineStyle', '--')
        plot(tth,tmp1means.(nmes{ii}).(touch{1})(1,:), 'LineWidth', 3, 'color', C(36, :), 'LineStyle', ':')
        legend('LT', 'ST');
    end
    axis tight
    xlim([0 1.6]);
    
    
end

%%
%plot the bar graphs
mns=struct;
mns.Alpha=meansAlphaL;
mns.Beta=meansBetaL;
mns.Gamma=meansGammaL;
mns.High_Gamma=meansHGH;

nn=fields(mns);
tch{1}='DT';
tch{2}='LT';
tch{2}='ST';
%%
wdth=0.8;
figure
for ii=1:length(nn)
    subplot(4,1,ii)
    hold on
    err(:,1)=mns.(nn{ii})(:,1)-mns.(nn{ii})(:,2);
    err(:,2)=mns.(nn{ii})(:,1)+mns.(nn{ii})(:,2);
    p1=barh(1, mns.(nn{ii})(3,1)); 
    p2=barh(2, mns.(nn{ii})(2,1)); 
    p3=barh(3.0, mns.(nn{ii})(1,1));
    errorbar(mns.(nn{ii})(3,1), 1, mns.(nn{ii})(3,2), 'horizontal', '.', 'CapSize', 18, 'LineWidth', 2, 'Color', 'k'); 
    errorbar(mns.(nn{ii})(2,1), 2, mns.(nn{ii})(2,2), 'horizontal', '.', 'CapSize', 18, 'LineWidth', 2, 'Color', 'k');
    errorbar(mns.(nn{ii})(1,1), 3, mns.(nn{ii})(1,2), 'horizontal', '.', 'CapSize', 18, 'LineWidth', 2,'Color', 'k');
   
    if ii==1
        set(p1, 'FaceColor', C(1,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p2, 'FaceColor', C(3,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p3, 'FaceColor', C(6,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        title('Alpha')
        
    elseif ii==2
        set(p1, 'FaceColor', C(7,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p2, 'FaceColor', C(10,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p3, 'FaceColor', C(13,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        title('Beta')
        
    elseif ii==3
        set(p1, 'FaceColor', C(20,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p2, 'FaceColor', C(23,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p3, 'FaceColor', C(26,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        title('Gamma')
     
    elseif ii==4
        set(p1, 'FaceColor', C(30,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p2, 'FaceColor', C(33,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        set(p3, 'FaceColor', C(36,:), 'EdgeColor', 'k', 'BarWidth', wdth);
        title('High Gamma')
        
    end
    xlim([0 1.6])
    ylim([0.6 3.4])
     yticklabels({'Deep Touch'; 'Light Touch'; 'Soft Touch' })
end


%% spectrograms with the powers underneath


N=36;
C=linspecer(N);
clrs=[1,3,6; 7, 10, 13; 24, 26, 29; 30, 33, 36]';

ss=1; %jr=4
ch_2plot=47;
figure
%change the person here
tt=specgramcBM2.SoftTouch.t;
ff=specgramcBM2.SoftTouch.f;

subplot(5,3,1)
imagesc(tt, ff, specgramcBM2.DeepTouch.MG47); axis xy; colormap(inferno);
xlim([-0.1 1.6])

subplot(5,3,2)
imagesc(tt, ff, specgramcBM2.LightTouch.MG47); axis xy; colormap(inferno);
xlim([-0.1 1.6])

subplot(5,3,3)
imagesc(tt, ff, specgramcBM2.SoftTouch.MG47); axis xy; colormap(inferno);
xlim([-0.1 1.6])

idx=3;
idxband=2;
for ii=4:15
    tempidx=floor(idxband);
    subplot(5,3,ii)
    if ii<13 %alpha beta gamma
        ch_used=find(channels.(nmes{ss}).low.(touch{idx})==ch_2plot);
    else %high gamma
        ch_used=find(channels.(nmes{ss}).high.(touch{idx})==ch_2plot);
    end
    if isempty(ch_used)
        continue
    else
        
        H=shadedErrorBar(tt2000,real(allpeakS.(nmes{ss}).(touch{idx})(ch_used).(bands{tempidx})(:,1)),real(allpeakS.(nmes{ss}).(touch{idx})(ch_used).(bands{tempidx})(:,2)));
        H.mainLine.LineWidth=4;
        H.patch.FaceColor=C(clrs(ii-3),:);
        H.patch.EdgeColor=C(clrs(ii-3),:);
        H.mainLine.Color=C(clrs(ii-3),:);
        H.edge(1).Color=C(clrs(ii-3),:);
        H.edge(2).Color=C(clrs(ii-3),:);
        axis tight
        xlim([-0.1 1.6])
        ylim_perrow(ii,:)=ylim;
        if ii==1 || ii==4 || ii==7 || ii==10 || ii==13
            
        else
            set(gca,'YTickLabel',[]);
        end
        
        
        if idx>1
            idx=idx-1;
        else
            idx=3;
        end
        idxband=idxband+0.33;
    end
end

% 
% 
% subplot(5,3,ii)
% H=shadedErrorBar(tt256,real(allpeakS.(nmes{ss}).LightTouch(2).Alpha(:,1)),real(allpeakS.(nmes{ss}).LightTouch(2).Alpha(:,2)));
% H.mainLine.LineWidth=4; 
% H.patch.FaceColor=C(3,:);
% H.patch.EdgeColor=C(3,:);
% H.mainLine.Color=C(3,:);
% H.edge(1).Color=C(3,:);
% H.edge(2).Color=C(3,:);
% xlim([-0.1 1.6])
% 
%     
% subplot(5,3,ii)
% H=shadedErrorBar(tt256,real(allpeakS.(nmes{ss}).SoftTouch(3).Alpha(:,1)),real(allpeakS.(nmes{ss}).LightTouch(3).Alpha(:,2)));
% H.mainLine.LineWidth=4; 
% H.patch.FaceColor=C(6,:);
% H.patch.EdgeColor=C(6,:);
% H.mainLine.Color=C(6,:);
% H.edge(1).Color=C(6,:);
% H.edge(2).Color=C(6,:);
% xlim([-0.1 1.6])

%% find the mean for each subject for each touch, normalizes it
%
meantouchZ=[];
meantouchZ=struct;

allpeakS.jo.SoftTouch(1).HighGamma=[];
allpeakS.jo.LightTouch(1).HighGamma=[];
allpeakS.jo.DeepTouch(1).Alpha=[];
allpeakS.jo.DeepTouch(1).Beta=[];
allpeakS.jo.DeepTouch(1).Gamma=[];
allpeakS.jo.DeepTouch(1).HighGamma=[];

for ii=1:length(nmes)
    for kk=1:length(touch)
        for jj=2:5
            bandmat=[];
            idx=0;
          
            for rr=1:size(allpeakS.(nmes{ii}).(touch{kk}),2)
                if ~isempty(allpeakS.(nmes{ii}).(touch{kk})(:,rr).(bands{jj}))
                    idx=idx+1;
                end
            end
            if idx>0
                for mm=1:idx
                    bandmat(:,mm)=allpeakS.(nmes{ii}).(touch{kk})(:,mm).(bands{jj})(:,1);
                end
            end
            
            a=mean(mean(bandmat,2));
            b=std(mean(bandmat,2));
            bandmat=(bandmat-a)./b;
            meantouchZ.(nmes{ii}).(touch{kk}).(bands{jj})(:,1)=mean(bandmat,2);
            meantouchZ.(nmes{ii}).(touch{kk}).(bands{jj})(:,2)=std(bandmat,[],2);
            meantouchZ.(nmes{ii}).(touch{kk}).(bands{jj})(:,3)=size(bandmat,2);
            
            %to collapse over all channels and all subjects, would need to
            %make the same size, then put side by side in a matrix, then
            %mean. would also need to get a std in the same way and do the
            %combo std thing with the Ns
            
            
            
            
        end
    end
end

        

%% plot the means next to each other for each subject on one graph

figure
set(0, 'DefaultAxesFontSize', 22)
idxnmes=1;
touchnames{1}='Deep Touch';
touchnames{2}='Light Touch';
touchnames{3}='Soft Touch';
touch={'DeepTouch', 'LightTouch', 'SoftTouch'};
tt256=-0.5:2.5/640:2-2.5/640;
tt2000=-0.5:2.5/500:2-2.5/500;
clrs=[1,3, 5, 7; 9, 11, 13 15; 22, 24, 26, 28; 32, 34, 35, 36]';
clridx=1;


ii=1;
for idxbands=2:5
    for idxtouch=1:3
        
        subplot(4,3,ii)
        hold on
        %if no data, skip that one by plotting the empty
        if isempty(meantouchZ.(nmes{1}).(touch{idxtouch}).(bands{idxbands})(:,1))
            plot(meantouchZ.(nmes{1}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx),:))
            fprintf('%s %s %s', nmes{1}, touch{idxtouch}, bands{idxbands});
        else
            plot(tt2000, meantouchZ.(nmes{1}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx),:), 'LineWidth', 2)            
            mx=max(meantouchZ.(nmes{1}).(touch{idxtouch}).(bands{idxbands})(:,2));
            zz=find(tt2000>-0.005 & tt2000<0.005);
            zzv=meantouchZ.(nmes{1}).(touch{idxtouch}).(bands{idxbands})(zz,1);
            ee=errorbar(0, zzv(1), mx, 'color', C(clrs(clridx),:), 'CapSize', 8, 'LineWidth', 2);
        end
        
        if isempty(meantouchZ.(nmes{2}).(touch{idxtouch}).(bands{idxbands})(:,1))
            plot(meantouchZ.(nmes{2}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx+1),:))
            fprintf('%s %s %s', nmes{2}, touch{idxtouch}, bands{idxbands});
            
        else
            plot(tt256, meantouchZ.(nmes{2}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx+1),:), 'LineWidth', 2)
            mx=max(meantouchZ.(nmes{2}).(touch{idxtouch}).(bands{idxbands})(:,2));
            zz=find(tt256>-0.005 & tt256<0.005);
            zzv=meantouchZ.(nmes{2}).(touch{idxtouch}).(bands{idxbands})(zz,1);
            ee=errorbar(-0.02, zzv(1), mx, 'color', C(clrs(clridx+1),:), 'CapSize', 8, 'LineWidth', 2);
        end
        
        
        if isempty(meantouchZ.(nmes{3}).(touch{idxtouch}).(bands{idxbands})(:,1))
            plot( meantouchZ.(nmes{3}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx+2),:))
            fprintf('%s %s %s', nmes{3}, touch{idxtouch}, bands{idxbands});
            
        else
            plot(tt2000, meantouchZ.(nmes{3}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx+2),:), 'LineWidth', 2)
            mx=max(meantouchZ.(nmes{3}).(touch{idxtouch}).(bands{idxbands})(:,2));
            zz=find(tt2000>-0.005 & tt2000<0.005);
            zzv=meantouchZ.(nmes{3}).(touch{idxtouch}).(bands{idxbands})(zz,1);
            ee=errorbar(-0.03, zzv(1), mx, 'color', C(clrs(clridx+2),:), 'CapSize', 8, 'LineWidth', 2);
        end
        
        
        if isempty(meantouchZ.(nmes{4}).(touch{idxtouch}).(bands{idxbands})(:,1))
            plot( meantouchZ.(nmes{4}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx+3),:))
            fprintf('%s %s %s', nmes{4}, touch{idxtouch}, bands{idxbands});
            
        else
            plot(tt256, meantouchZ.(nmes{4}).(touch{idxtouch}).(bands{idxbands})(:,1), 'color', C(clrs(clridx+3),:), 'LineWidth', 2)
            mx=max(meantouchZ.(nmes{4}).(touch{idxtouch}).(bands{idxbands})(:,2));
            zz=find(tt256>-0.005 & tt256<0.005);
            zzv=meantouchZ.(nmes{4}).(touch{idxtouch}).(bands{idxbands})(zz,1);
            ee=errorbar(-0.04, zzv(1), mx, 'color', C(clrs(clridx+3),:), 'CapSize', 8, 'LineWidth', 2);
        end
        
        
        
      
        
        xlim([-0.1 1.6])
        %ylim([-7 7])
        %set(gca,'YTickLabel',[]);
        if ii<4
            title(touchnames{idxtouch})
        end
        
        ii=ii+1;
    end
    clridx=clridx+4;
end








