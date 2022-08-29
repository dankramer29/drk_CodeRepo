function TestFunc(sub_chaninfo, spectrums_cavg_targ_LF) 
    theta_deg=(0:45:360)'; %for polar plot rays
    theta=deg2rad(theta_deg);
    target_labels = {'1'; '2'; '3'; '4'; '5'; '6'; '7'; '8';};
    figure('Name', 'Breakit', 'NumberTitle', 'off','position', [-1919 121 1920 1083])
    r = [8:-1:1 16:-1:9 24:-1:17 32:-1:25 40:-1:33 48:-1:41 56:-1:49 64:-1:57];
    r = reshape(r, [8 8])';
    for i = [55 56 63 64]%1:64
        subplot_tight(2, 2, i, [0.08 0.08])
        chan = r(i);
        if chan ~= 4 & chan ~= 32
            if chan > 4 & chan < 32
                chan = chan - 1;
            elseif chan > 32
                chan = chan - 2;
            end
            chan_as_record = table2array(sub_chaninfo(chan,1));
            chan_label = table2array(sub_chaninfo(chan,2));
            ph_targ_avg = squeeze(spectrums_cavg_targ_LF(chan,:,:))';
            if size(ph_targ_avg, 1) < length(theta)
                ph_targ_avg(end+1,:) = ph_targ_avg(1,:); % add the first values to the end so the polar plot connects
            end
            polarplot(theta, ph_targ_avg)
            set(gca, 'ThetaDir', 'clockwise', 'ThetaZeroLocation', 'top', 'ThetaTick', theta_deg, 'ThetaTicklabel', target_labels)
            ts = sprintf('Ch%d %s', chan_as_record, chan_label{1});
            title(ts)
        elseif chan == 4
            ts = sprintf('Ch44 MP4 RM');
            title(ts)
        elseif chan == 32
            ts = sprintf('Ch72 MP32 RM');
            title(ts)
            continue
        end
    end
end