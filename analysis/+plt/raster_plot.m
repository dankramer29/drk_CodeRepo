function  raster_plot( spk_times, varargin )
%A quick raster plot function for a single time series or multiple
%   spk_times=      enter as the spike_times(:,1) and the trial or feature
%   or channel as spike_time(:,2).  This is mostly set up to come from
%   target_split output of center_out.spkrates_pertarget

%%
%check if a title is provided, this is good for independent raster plots,
%not as part of another plotting function
[varargin, title]=util.argkeyval('title', varargin, []);
[varargin, tm]=util.argkeyval('tm', varargin, []); % a time vector
[varargin, condSep]=util.argkeyval('condSep', varargin, []); % if some are in one condition and others are in another condition, list the number where the trials separate
[varargin, colorChoice]=util.argkeyval('colorChoice', varargin, []); %enter as hexcodes, put in one or two or more color choices

[varargin, hashWidth]=util.argkeyval('hashWidth', varargin, 0.8); % set the width. 0.8 is good if doing a lot of trials but bad if only one or two


%figure if you need a blank figure
[varargin, fig]=util.argkeyval('fig', varargin, false);

[varargin, rainbowC]=util.argkeyval('rainbowC', varargin, false); %although this works, it does not look good.


if size(spk_times,1) > size(spk_times,2)
    spk_times = spk_times'; %convert to rows are trials and columns are spike times
end

if isempty(condSep)
    condSep = length(spk_times); %just separate to the single condition
end

% if size(spk_times,2)<2
%     spk_times(:,2) = 1;
% end

%%
%create a pretty color scheme to insert, default is 11, a nice green, to
%see the colors, do:
% C=linspecer(N);
% figure
% hold on
% for ii=1:36
%   Y=X+ii;
%   plot(Y, 'LineWidth', 3, 'color', C(ii,:))
% end

if sum(isnan(spk_times)) > 0
    nanPlot = 1;
else
    nanPlot = 0;
end

if rainbowC
    colorTempTest = {'#1A1334', '#26294A', '#055459', '#077353', '#14C285', '#ABD96D', '#FCBF54', '#EE6C3B', '#EC0E47', '#A02C5D', '#710461', '#022B7A' };

    for ii = 1:length(colorTempTest)
        str = colorTempTest{ii};
        C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
    end
    color=1;
else
    if isempty(colorChoice)
    colorTempTest = {'#678CEC', '#D49BAE'}; %can change the color here to any hex code.#E4287C is pink lemonade. and here is a good three #678CEC #D49BAE and #BBCB50 which is blue/pink/green
    else
        colorTempTest = colorChoice;
    for ii = 1:length(colorTempTest)
        str = colorTempTest{ii};
        C(ii,:) = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
    end
    color = 1;
end

if fig
    figure
end

[Trials, Time] = size(spk_times);

if ~nanPlot
    if ~isempty(tm)
        Time = tm;
    end
    %figure;
    hold on;
    idx=color;
    for i = 1:Trials
        spikeIdx = find(spk_times(i,:));
        for s = 1:length(spikeIdx)
            x = [spikeIdx(s) + Time(1) , spikeIdx(s) + Time(1)];
            y = [i- hashWidth/2, i + hashWidth/2];
            if rainbowC

                line(x, y, 'Color', C(color+idx,:), 'LineWidth', 4);
            else
                line(x, y, 'Color', C(color,:), 'LineWidth', 4);
            end
        end
        idx= idx+1;
        if rainbowC
            if idx+color>length(colorTempTest)
                color = 1;
                idx=0;
            end
        end
    end

    xlabel('Time (samples)');
    ylabel('Trial');
    xlim([Time(1) Time(end)]);
    ylim([0 Trials+1]);
    set(gca, 'YDir', 'reverse');

    hold off
end

if nanPlot   
     tvec = 1:size(spk_times,2);  
     if ~isempty(tm)
         tvec = tvec+tm(1);
     end

    [nTrials, nBins] = size(spk_times);
    hold on;
    for tr = 1:nTrials
        % find spike times (NaNs automatically ignored)
        st = tvec(~isnan(spk_times(tr,:)));
        if tr < condSep
            color = 1;
        else
            color = 2;
        end

        % each spike is a short vertical line from trial-0.4 to trial+0.4
        for s = 1:numel(st)
            line([st(s) st(s)], [tr-0.4 tr+0.4], 'Color', C(color,:), 'LineWidth', 6);
        end
    end
    xlabel('Time (ms)')
    ylabel('Trial')
    ylim([0 nTrials+1])
    
    

    set(gca, 'YDir','reverse') % trial 1 at top

   
end

 % %%simple version
    % for ii = 1:size(spk_times,1)
    %     plot(spk_times(ii,:), 'marker','.','linestyle','none','MarkerSize', 4, 'color', C(color,:))
    %     hold on
    % end
    %axis tight
%%plot(spk_times(:,1), spk_times(:,2), 'marker','.','linestyle','none','MarkerSize', 4, 'color', C(color,:))
% axis tight
% %pbaspect([8 1 1]);%this changes the aspect ratio x y z
% 


end

