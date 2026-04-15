function colorOut = PCAcolorplt(data1, data2, varargin)
% plot a color changing line.

%output is the middle color to make the legend.

[varargin, data3] = util.argkeyval('data3',varargin, []);  %if 3d data
[varargin, colorChoice] = util.argkeyval('colorChoice',varargin, []);  %enter colors if you want them, in hexcode
[varargin, threeColor] = util.argkeyval('threeColor',varargin, true);  %if you want a 3 color transition.
[varargin, newFig] = util.argkeyval('newFig',varargin, true);  %creates a new figure, so can do hold on and no new figure if two pcas
[varargin, eventIdx] = util.argkeyval('eventIdx',varargin, 1);  %mark an event index can be several spots
[varargin, eventLbl] = util.argkeyval('eventLbl',varargin, 'start');  %mark an event index with a label, 
[varargin, dataLbl] = util.argkeyval('dataLbl',varargin, '1');  %mark an event index with a label, 
[varargin, titlePCA]=util.argkeyval('titlePCA', varargin, {'PCA'}); %run it either congruent vs incongruent (1) or as choice 123 (2). which will be one figure of each but all put together for concat pcas.

if ~isempty(data3)
    Plot3D = 1;
else
    Plot3D = 0;
end

if size(colorChoice,1) < 3
    threeColor = false;
end


if isempty(colorChoice)
    if ~threeColor
        colorTempTest = {'#341514', '#E17888'}; %dark to light red
        for ii = 1:length(colorTempTest)
            str = colorTempTest{ii};
            C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
        end
        % figure %for plotting
        % X = repmat(10,1,length(C));
        % Y = 1:length(C);
        % bb = bar(Y,X);
        % bb.FaceColor = 'flat';
        % for ii = 1:length(C)
        %     bb.CData(ii,:) = C(ii,:);
        % end
    else
        colorTempTest = { '#769FCB', '#DDF0F7', '#FF6C65'}; %blue red combo
        for ii = 1:length(colorTempTest)
            str = colorTempTest{ii};
            C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
        end
    end
else
    colorTempTest = colorChoice;
    for ii = 1:length(colorTempTest)
        str = colorTempTest{ii};
        C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
    end
    if threeColor & length(colorTempTest)<3
        colorTempTest{end+1} = {'#000000'};
    end

end

if ~threeColor

    % Define start and end colors (RGB)
    c1 = C(1,:);   % color1
    c2 = C(2,:);   % color2

    % Create color gradient
    n = length(data1)-1;
    colors = [linspace(c1(1), c2(1), n)', ...
        linspace(c1(2), c2(2), n)', ...
        linspace(c1(3), c2(3), n)'];
else
    
    
    % Define 3 colors [R G B]
    c1 = C(1,:);   % blue
    c2 = C(2,:);   % green
    c3 = C(3,:);   % red

    n = length(data1)-1;

    % Split interpolation into two halves
    n1 = floor(n/2);
    n2 = n - n1;

    colors1 = [linspace(c1(1), c2(1), n1)', ...
        linspace(c1(2), c2(2), n1)', ...
        linspace(c1(3), c2(3), n1)'];

    colors2 = [linspace(c2(1), c3(1), n2)', ...
        linspace(c2(2), c3(2), n2)', ...
        linspace(c2(3), c3(3), n2)'];

    colors = [colors1; colors2];
end

if newFig
   figure('Name', titlePCA{1})
    set(gca,'FontSize', 16)
else
    hold on
end
if Plot3D

    hold on
    for i = 1:n
        plot3(data1(i:i+1), data2(i:i+1), data3(i:i+1), 'Color', colors(i,:), 'LineWidth', 2);
         if i == round(n/2)
            colorOut = colors(i,:);
        end
    end
    view(3)
    axis vis3d
    
    %label events
    for jj= 1:length(eventIdx)
        plot3(data1(eventIdx(jj)), data2(eventIdx(jj)), data3(eventIdx(jj)), ...
            'o', 'MarkerSize', 8, 'MarkerFaceColor', colors(end,:)) %need to change color of marker
        text(data1(eventIdx(jj)), data2(eventIdx(jj)), data3(eventIdx(jj)), ...
            eventLbl, ...
            'FontSize', 18, ...
            'Color', 'k')
    end

    xlabel('PC1')
    ylabel('PC2')
    zlabel('PC3')
    if newFig
    title( titlePCA{1})
    end
    % WILL PLACE A LEGEND BUT IF YOU ARE PLOTTING MULTIPLE ON THE SAME
    % FIGURE, IT WILL REPLACE THE LEGEND (SO DO IT OUTSIDE THIS FUNCTION OR
    % MAKE THIS FUNCTION PLOT ALL THREE)
    % hold on
    % h1 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', colors(end,:)); % dummy
    % legend(h1, {dataLbl});
else
    hold on
    for i = 1:n
        plot(data1(i:i+1), data2(i:i+1), 'Color', colors(i,:), 'LineWidth', 2);
        if i == round(n/2)
            colorOut = colors(i,:);
        end
    end
    for jj= 1:length(eventIdx)
        plot(data1(eventIdx(jj)), data2(eventIdx(jj)),  ...
            'o', 'MarkerSize', 8, 'MarkerFaceColor', colors(end,:)) %need to change color of marker
        text(data1(eventIdx(jj)), data2(eventIdx(jj)), ...
            eventLbl, ...
            'FontSize', 18, ...
            'Color', 'k')
        %% to label multiple events but I have not checked this
        % events = [200 400 600];
        % labels = {'Stim','Go','Reward'};
        % 
        % for i = 1:numel(events)
        %     idx = events(i);
        %     plot3(pc1(idx), pc2(idx), pc3(idx), 'ko', 'MarkerFaceColor','k')
        %     text(pc1(idx), pc2(idx), pc3(idx), labels{i}, ...
        %          'FontSize',9, 'FontWeight','bold')
        %   end
    end

    xlabel('PC1')
    ylabel('PC2')
    if newFig
    title(titlePCA{1})
    end
    %for plotting a legend, will pick a color midway through the transition

   
    %plot dummy lines and then can do a location for each, change the
    %color. currently i am running each independently with a hold on, so
    %need to make the legend outside of this function, but if want to do it
    %within.
    %     h1 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', [0 0 1]); % dummy
    % plotGradientTrajectory(pc1a, pc2a, pc3a, [0 0 1], [1 0 0]);
    % 
    % % ---- Trajectory 2 ----
    % h2 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', [0 1 0]);
    % plotGradientTrajectory(pc1b, pc2b, pc3b, [0 1 0], [1 0 1]);
    % 
    % % ---- Trajectory 3 ----
    % h3 = plot3(nan, nan, nan, 'LineWidth', 3, 'Color', [0 0 0]);
    % plotGradientTrajectory(pc1c, pc2c, pc3c, [0.5 0.5 0.5], [0 0 0]);
    % 
    % legend([h1 h2 h3], {'Condition A','Condition B','Condition C'}, ...
    %        'Location','best')
end

end