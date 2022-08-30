function plt_stereo( data, task, params, phase_length, varargin )
%plt_stereo does subplots for the stereo eeg set up
%   Detailed explanation goes here
% 
% 
% TO DO:
%     -IF THERE ARE MACROS OF DIFFERENT SIZES, THIS DOES NOT ACCOUNT FOR THAT

%find the number of micros, usually 6
[varargin, micro]=util.argkeyval('micro', varargin, 6);
%find the number of macros, usually 2
[varargin, macro]=util.argkeyval('macro', varargin, 2);
%find the size of the macro, usually 8 contacts
[varargin, mac_sz]=util.argkeyval('mac_sz', varargin, 8);
%find the if full_grid true or not
[varargin, full_grid]=util.argkeyval('full_grid', varargin, true);
%find the channels if entered, this is assuming it's getting clipped data
%input. if being used on own, should specify channels
[varargin, ch, ~, found]=util.argkeyval('ch', varargin, [1 76]); 
if ~found
    fprintf('Unless otherwise specified in ch, assumes 76 channels\n');
end
%make sure the channels entered is an even number
assert(mod(ch(1,2)-ch(1,1),2)==1, 'must enter even number of channels')

util.argempty(varargin);
%%
%allow for just plotting random channels
switch full_grid
    case true
        %%
        %This is mostly temporary until the map is made
        figtitle={'L amygdala' ...
            'L head of hippo', ...
            'L tail of hippo', ...
            'R amygdala', ...
            'R head of hippo', ...
            'R tail of hippo'}; ...
            
        %%
        %Plot micros
        %for each micro that exists, usually 6 but in case it needs to be
        %changed do so in the micro varargin
        idx=1;
        for kk=(0:micro-1)*10 %to increment by the micros
            figure('Name', figtitle{idx},'NumberTitle', 'off')
            
            for mm=1:10
                %create the micro subplots
                subplot(10,1, mm)
                hold on
                plzero=phase_length-phase_length(1,1);
                %plot data type 1 and 2 (e.g. L and R)
                plot(data.type1.data(phase_length(1,1):end,kk+mm))
                plot(data.type2.data(phase_length(1,1):end,kk+mm))
                %THIS CHANNEL TITLE NEEDS TO BE FIXED AND ADJUSTED TO A MAP
                title([' Ch ' num2str(kk+mm)]);
                mx(1,1)=max(data.type1.data(phase_length(1,1):end,kk+mm));
                mx(1,2)=max(data.type2.data(phase_length(1,1):end,kk+mm));
                mx=max(mx);
                for ii=2:length(phase_length)
                    plot([phase_length(1,ii)-phase_length(1,1), phase_length(1,ii)-phase_length(1,1)], [0, mx+5], 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':')
                end
                if length(phase_length)==6
                    ax=gca;
                    plt_labels( mx, phase_length, kk+mm, task, ax );                    
                end
            end
            idx=idx+1;
        end %end plotting micros
        %%
        figtitle2={'L parietal', ...
            'R parietal'};
        idx=1;
        %Plot macros
        for kk=(0:macro-1)*mac_sz+micro*10   %start the channels after the micros
            figure('Name', figtitle2{idx},'NumberTitle', 'off')
            for mm=1:mac_sz
                %create the micro subplots
                subplot(mac_sz,1, mm)
                hold on
                plzero=phase_length-phase_length(1,1);
                %plot data type 1 and 2 (e.g. L and R)
                plot(data.type1.data(phase_length(1,1):end,kk+mm))
                plot(data.type2.data(phase_length(1,1):end,kk+mm))
                %THIS CHANNEL TITLE NEEDS TO BE FIXED AND ADJUSTED TO A MAP
                title([' Ch ' num2str(kk+mm)]);
                mx(1,1)=max(data.type1.data(phase_length(1,1):end,kk+mm));
                mx(1,2)=max(data.type2.data(phase_length(1,1):end,kk+mm));
                mx=max(mx);
                for ii=2:length(phase_length)
                    plot([phase_length(1,ii)-phase_length(1,1), phase_length(1,ii)-phase_length(1,1)], [0, mx+5], 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':')
                end
                if length(phase_length)==6
                    ax=gca;
                    plt_labels( mx, phase_length, kk+mm, task, ax );
                    
                end
            end
            idx=idx+1;
        end
        
    case false
        chname=arrayfun(@num2str,ch, 'uniformoutput', false);        
        figtitle=['Ch ' chname{1,1} ' - ' chname{1,2} ' type 1 vs type 2'];
        
        %%
        idx=1;
        %this is to set up the incrementing. Currently it will do a
        %subplots by 4, but can change the subplts amount below to adjust
        %it.
        subplts=2;
        totl=size(data.type1.data,2)/subplts;
        for kk=(0:totl-1)*subplts %to increment subplots of 4 each
            figure('Name', figtitle,'NumberTitle', 'off')
          
                for mm=1:subplts
                    
                    %create the micro subplots
                    subplot(subplts,1, mm)
                    hold on
                    plzero=phase_length-phase_length(1,1);
                    %plot data type 1 and 2 (e.g. L and R)
                    plot(data.type1.data(phase_length(1,1):end,kk+mm))
                    plot(data.type2.data(phase_length(1,1):end,kk+mm))
                    %THIS CHANNEL TITLE NEEDS TO BE FIXED AND ADJUSTED TO A MAP
                    title([' Ch ' num2str(kk+mm)]);
                    mx(1,1)=max(data.type1.data(phase_length(1,1):end,kk+mm));
                    mx(1,2)=max(data.type2.data(phase_length(1,1):end,kk+mm));
                    mx=max(mx);
                    for ii=2:length(phase_length)
                        plot([phase_length(1,ii)-phase_length(1,1), phase_length(1,ii)-phase_length(1,1)], [0, mx+5], 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':')
                    end
                    if length(phase_length)==6
                        ax=gca;
                        plt_labels( mx, phase_length, kk+mm, task, ax );
                        
                    end
                end
                idx=idx+1;
            
        end
end



end

