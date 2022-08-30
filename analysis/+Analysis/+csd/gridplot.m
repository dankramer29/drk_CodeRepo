function [tt1]=gridplot( data,map, varargin)
%gridplot make an easy way to quickly plot data off the different grids
%   Gives an easy way to do some simple plots from the data produced from
%   blc_csd
%  
%{  FOR MORE DETAILS REGARDING HOW EACH COMPONENT WORKS, SEE blx_plt_ecog2
% 
%     INPUTS
%       data=     The actual data, can be anything
%       map=      The map file needed for names
%   
%    Varargins
%       datatype=   the different possible data types.
%                     1=raw data from ds_ecog
%                     2=filtered data from flt
%                     3=filtered low pass data, usually 5Hz from params.lwps
%                     4=power data from a low pass filter from pwr_lwps
%                     5=integral data from intg_flt
%       gridtype=   the grid type to put the different types into an
%            appropriate plot
%                 1= 4x5 grid
%                 2= 1x6 strips
%                 3= 3 1x6 strips, an easy way to do them all at once
%                        
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
%   [ttx]=csd.gridplot(  flt_lwps4, map, 'datatype', 1, 'dsrt', dsrt, 'sz', CutPre, 'ch', [ch1 ch2], 'figtitle', figtitle );
%}

%%
%check if downsample rate was specified
[varargin, datatype]=util.argkeyval('datatype', varargin, 1);
%%
%check if downsample rate was specified
[varargin, dsrt, ~, found]=util.argkeyval('dsrt', varargin, 2000);
if ~found
    warning('downsample rate set at default 2000 samples/sec');
end
%%
%check if gridtype was specified
[varargin, gridtype]=util.argkeyval('gridtype', varargin, 2); %RIGHT NOW ONLY DOES 4X5 AND 1X6
%%
%check if xL was specified
[varargin, xL]=util.argkeyval('xL', varargin, []);
%%
%check if yL was specified
[varargin, yL,]=util.argkeyval('yL', varargin, []);
%%
%check if number of channels was specified
[varargin, ch]=util.argkeyval('ch', varargin, [1 size(data,2)]);
%%
%check if the title was specified
[varargin, figtitle, ~, found ]=util.argkeyval('figtitle', varargin, []);
if ~found
    figtitle=['S0? Sz? ' figtitle];
end
%%
%check if sz time was specified
[varargin, sz, ~, found]=util.argkeyval('sz', varargin, 1);
if ~found
    warning('Seizure origin time not specified, set at the beginning. Specify by stating how much time was taken prior to the seizure, i.e. the CutPre');
end
%  Find the seizure time which will be the CutPre time from 0, so convert to seconds then *dsrt.
%  szrow represents the row of voltage values that it starts as.
szrow=sz*60*dsrt;
pldsrt=dsrt/floor(dsrt/(5*2));
%%
%make the channel names from the map
if isempty(map)
    chname=ch(1,1):ch(1,2)+1;
    chname=arrayfun(@num2str,chname,'uniformoutput',false);
else
    chname=map.ChannelInfo{ch(1,1):ch(1,2)+1,2};
end

%check if change data is entered rate was specified. change is a struct of
%change_data.change_data and change_data.extendedchange_data for the purpose of
%highlighting changes in the data
[varargin, change_data]=util.argkeyval('c_data', varargin, []);
%%
%makes sure that the varargin is processed properly
util.argempty(varargin);
%%
%set up the datatypes to graph
switch datatype
    case 1
        tt1=(0:1/dsrt:size(data,1)/dsrt-1/dsrt)-szrow/dsrt;
        yL=0.25;
    case 2
        tt1=(0:1/dsrt:size(data,1)/dsrt-1/dsrt)-szrow/dsrt;
        yL=0.00001;
    case 3
        tt1=(0:1/dsrt:size(data,1)/dsrt-1/dsrt)-szrow/dsrt;
        yL=0.01;
    case 4
        tt1=(0:1/pldsrt:size(data,1)/pldsrt-1/pldsrt)-(szrow/dsrt);
        yL=0.025;
    case 5
        tt1=(0:1/dsrt:size(data,1)/dsrt-1/dsrt)-szrow/dsrt;
        %yL=? not sure what is a good scale for this, currently integral data looks
        %terrible so it's like 10e-11 axis.
end
%%
% a function for visually pleasing colors 1:18, but can make any number,
% factors of 6 are nice
C=linspecer(36);
%%
switch gridtype
    case 1 %4x5 grid
        figure('Name', figtitle,'NumberTitle', 'off')
        idx=1;
        for ii=1:size(data,2)
            if ii==5 || ii== 10 || ii==15
                continue
            else
                subplot(4,4,idx)                
                plot(tt1, data(:,ii), 'color', C(6,:))
                hold on
                plot(tt1, change_data.extendedchange_data(:,ii), 'color', C(7,:))
                plot(tt1, change_data.change_data(:,ii), 'color', C(8,:))
                if ~isempty(xL)
                    set(gca,'xlim', [-xL xL]);
                end
                if ~isempty(yL)
                    set(gca,'ylim', [-yL yL]);
                end
                title([' Ch ' chname{ii,1} '-' chname{ii+1,1}]);
                idx=idx+1;
            end
        end
    case 2 %6 electrode strip
        figure('Name', figtitle,'NumberTitle', 'off')
        idx=1;
        for ii=1:size(data,2)
            
                subplot(5,1,idx)                             
                plot(tt1, data(:,ii), 'color', C(6,:))
                hold on
                plot(tt1, change_data.extendedchange_data(:,ii), 'color', C(7,:))
                plot(tt1, change_data.change_data(:,ii), 'color', C(8,:))
                if ~isempty(xL)
                    set(gca,'xlim', [-xL xL]);
                end
                if ~isempty(yL)
                    set(gca,'ylim', [-yL yL]);
                end
                title([' Ch ' chname{ii,1} '-' chname{ii+1,1}]);
                idx=idx+1;
         
        end
        
        case 3 %6 electrode strip
        figure('Name', figtitle,'NumberTitle', 'off')
        idx=1;
        for ii=1:size(data,2)
            if ii==6 || ii== 12 
                continue
            else
                subplot(3,5,idx)                             
                plot(tt1, data(:,ii), 'color', C(6,:))
                hold on
                plot(tt1, change_data.extendedchange_data(:,ii), 'color', C(7,:))
                plot(tt1, change_data.change_data(:,ii), 'color', C(8,:))
                if ~isempty(xL)
                    set(gca,'xlim', [-xL xL]);
                end
                if ~isempty(yL)
                    set(gca,'ylim', [-yL yL]);
                end
                title([' Ch ' chname{ii,1} '-' chname{ii+1,1}]);
                idx=idx+1;
         
            end
        end
end


end

