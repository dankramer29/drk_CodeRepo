function  raster_plot( spk_times, varargin )
%A quick raster plot function for a single time series or multiple
%   spk_times=      enter as the spike_times(:,1) and the trial or feature
%   or channel as spike_time(:,2).  This is mostly set up to come from
%   target_split output of center_out.spkrates_pertarget

%%
%check if a title is provided, this is good for independent raster plots,
%not as part of another plotting function
[varargin, title]=util.argkeyval('title', varargin, []);

%%
%include the featdef if needed for channel labels and such
[varargin, featdef]=util.argkeyval('featdef', varargin, []);

%figure if you need a blank figure
[varargin, fig]=util.argkeyval('fig', varargin, false);

hashWidth = 0.8;  % default width


if size(spk_times,1) > size(spk_times,2)
    spk_times = spk_times'; %convert to rows are trials and columns are spike times
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
[varargin, color]=util.argkeyval('color', varargin, 8);

N=36;
C=linspecer(N); 

if fig
    figure
end

[Trials, Time] = size(spk_times);
figure; hold on;

for i = 1:Trials
    spikeIdx = find(spk_times(i,:));
    for s = 1:length(spikeIdx)
        x = [spikeIdx(s) , spikeIdx(s)];
        y = [i- hashWidth/2, i + hashWidth/2];
        line(x, y, 'Color', C(color,:), 'LineWidth', 2);
    end
end

xlabel('Time (samples)');
ylabel('Trial');
xlim([1 Time]);
ylim([0 Trials+1]);
set(gca, 'YDir', 'reverse');



%%simple version
% 
% spk_times(spk_times==0)=NaN;
% 
% plot(spk_times(:,1), 'marker','.','linestyle','none','MarkerSize', 4, 'color', C(color,:))
% %plot(spk_times(:,1), spk_times(:,2), 'marker','.','linestyle','none','MarkerSize', 4, 'color', C(color,:))
% axis tight
% %pbaspect([8 1 1]);%this changes the aspect ratio x y z
% 


end

