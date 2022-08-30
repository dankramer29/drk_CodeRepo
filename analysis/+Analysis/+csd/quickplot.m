function quickplot( data, tnum, varargin)
%quickplot make an easy way to quickly plot my data in different subplots
%   Gives an easy way to do some simple plots from the data produced from
%   blc_csd
%  
%{

    INPUTS
        data=       the actual data, can be anything
        tnum=       the time values, usually outputs of the blc_csd
        function
%   
%   Varargins
%       ch= [chst chend] so [5 8] which will be the columns of the data that's
%           plotted
%       xL=         xlimit so 1000 will make xL [-1000 1000] centered
%           around the seizure time
%       yL=         ylimit so 0.5 will make yL [-0.5 0.5]
%       ch=         channels you want to use, this is done within the
%           already made matrices of say ds_ecog, so if you have channels
%           41-50, ds_ecog will have 9 columns and you can pick the last 5 by
%           doing [6 9]
%       figtitle=   the figure title you want for saving purposes 'S01 Sz 4
%           filtered low pass PSG6-10'.   TO DO: (it should then input the actual name of
%           data (like lwps_flt) if no name is entered, but doesn't right now)
%
%
%
% TO DO:
%       -the tick labels are off
%       -the title if not entered, doesn't work.
%
%   csd.quickplot( flt_lwps4, tt14, 'xL', 60*40, 'yL', 0.01, 'ch', [6 9], 'figtitle', 'S01 Sz 4 filtered low pass PSG6-10' );
%}



%check if xL was specified
[varargin, xL]=util.argkeyval('xL', varargin, []);
%check if yL was specified
[varargin, yL,]=util.argkeyval('yL', varargin, []);
%check if number of channels was specified
[varargin, ch]=util.argkeyval('ch', varargin, [1 size(data,2)]);
%check if the title was specified 
titlename=whos('data'); 
[varargin, figtitle, ~, found ]=util.argkeyval('figtitle', varargin, titlename.name);
if ~found
    figtitle=['S0? Sz? ' figtitle];
end

%makes sure that the varargin is processed properly
util.argempty(varargin);





grd=ch(1,2)-ch(1,1)+1;
figure('Name', figtitle,'NumberTitle', 'off')
idx=1;
for ii=1:size(data,2)
    subplot(grd,1,idx)
    plot(tnum, data(:,ii))
    if ~isempty(xL)
    set(gca,'xlim', [-xL xL]);
    end
    if ~isempty(yL)
    set(gca,'ylim', [-yL yL]);
    end
    %set(gca, 'xtick', [tnum(1,1):100:tnum(1,end)]) %these don't work right
    %it won't just put tick marks, need to work on later.
    %set(gca, 'xticklabels', [tnum(1,1):1000:tnum(1,end)])
    idx=idx+1;
end


end

