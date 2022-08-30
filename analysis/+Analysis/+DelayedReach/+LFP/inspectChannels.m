function inspectChannels(ns, channels, leadName, timeStart, timeEnd)
    Data = ns.read('time', [timeStart timeEnd], 'channels', channels);
    x_range = [timeStart:(1/ns.Fs): timeEnd - (1/ns.Fs)];
    %total = max(channels);
    leg = strsplit(num2str(channels));
    figName1 = ['All Channels in ' leadName];
    
    f1 = figure('Name', figName1, 'Position', [0 0 1280 1440]);
    plot(x_range,Data)
    legend(leg)

    
    
    %figure with all channels in range given split into separate figures
    figName2 = ['Separate Channels in ' leadName];
    f2 = figure('Name', figName2, 'Position', [1280 0 1280 1440]);
    
    for i = 1:length(channels)
        ch = leg(i);
        tStr = ['Channel ' ch];
        ax = subplot(length(channels),1,i);
        
        plot(x_range, Data(i,:))
        ax.YLim = [-500 500];
        title(tStr)
        %drawnow
    end
    

end