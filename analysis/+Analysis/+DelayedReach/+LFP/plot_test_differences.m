function plot_test_differences(test_differences, chan_str, func_str, test_ID)
    
    subplot_rows = length(test_differences);
    fband_names = {'Theta 4-8' 'Alpha 8-12' 'Beta 12-30' 'Low Gamma 30-80'...
        'High Gamma 80-200'}; 
    
    
    FigTitle = sprintf('Test Diff - %s', test_ID);
    figure('Name', FigTitle, 'NumberTitle', 'off','position', [-1702 263 1539 910])
    
    
    for sp = 1:subplot_rows
        subplot(subplot_rows, 1, sp)
        plot(test_differences{sp})
        hold on
        plot([0,59],[0, 0], 'k')
        hold off
        ylabel(fband_names{sp})
        ylim([-1 1])
    end
    anno_str = sprintf('Func: %s\nChan: %s', func_str, chan_str);
    annotation('textbox', [0 0.95 0.15 0.05], 'String', anno_str, 'FitBoxToText', 'on')