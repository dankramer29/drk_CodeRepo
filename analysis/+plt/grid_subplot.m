function ch2plot=grid_subplot( varargin )
%grid_subplot will output a matrix that has the order, number, and
%orientation of a grid for plotting a subplot
%   Layout of the different grids and then plotting whatever you are
%   interested in next to each other like the actual grid layout
%
% Varargin
%     gridttype=  options are mini=1 and twenty (4x5)=2 right now
%     
%     orientation=    the way it's laying on the brain, two numbers [x
%     y],x: 1=left 2=right, y: tails pointing: 1=inferior, 2=posterior,
%     3=superior, 4=anterior
%     
%     plottype=   what kind of data are you plotting, heatmap vs standard
%     graph (OTHERS CAN BE ADDED AS SEEN FIT)
%
%     channels2plot=  if the user doesn't want to have to choose the
%     channels to plot and just wants to enter them, still puts them in the
%     correct order

%for an example on how to plot, see plot.grid_subplot_scriptexample
%     
%these are arranged the way you would look at a brain straight on (like the
%3d reconstructions
%MINI layout with tails at the bottom (standard on the sheet) also:


%Orientation 1 L inferior pointing tails or R inferior pointing tails
%antsup L inf tails                             antsup R inf tails
%        57    49    41    33    25    17     9     1
%        58    50    42    34    26    18    10     2
%        59    51    43    35    27    19    11     3
%        60    52    44    36    28    20    12     4
%        61    53    45    37    29    21    13     5
%        62    54    46    38    30    22    14     6
%        63    55    47    39    31    23    15     7
%        64    56    48    40    32    24    16     8


%Orientation 2 L posterior pointing tails or R anterior pointing tails
%antsup  L post tails                   antsup R ant tails
%      1     2     3     4     5     6     7     8
%      9    10    11    12    13    14    15    16
%     17    18    19    20    21    22    23    24
%     25    26    27    28    29    30    31    32
%     33    34    35    36    37    38    39    40
%     41    42    43    44    45    46    47    48
%     49    50    51    52    53    54    55    56
%     57    58    59    60    61    62    63    64

%Orientation 3 L anterior pointing tails or R posterior pointing tails
% ant sup L ant tails                   antsup R post tails
%     64    63    62    61    60    59    58    57
%     56    55    54    53    52    51    50    49
%     48    47    46    45    44    43    42    41
%     40    39    38    37    36    35    34    33
%     32    31    30    29    28    27    26    25
%     24    23    22    21    20    19    18    17
%     16    15    14    13    12    11    10     9
%      8     7     6     5     4     3     2     1

%Orientation 4 L or R superior pointing tails
%antsup L sup tails                         antsup R sup tails
%      8    16    24    32    40    48    56    64
%      7    15    23    31    39    47    55    63
%      6    14    22    30    38    46    54    62
%      5    13    21    29    37    45    53    61
%      4    12    20    28    36    44    52    60
%      3    11    19    27    35    43    51    59
%      2    10    18    26    34    42    50    58
%      1     9    17    25    33    41    49    57

%these are arranged the way you would look at a brain straight on (like the
%3d reconstructions
%Orientation 1  R or L inferior pointing tails
%antsup L                   antsup for R
%      1     6    11    16 
%      2     7    12    17
%      3     8    13    18
%      4     9    14    19
%      5    10    15    20


%Orientation 2 R posterior pointing tails or L anterior pointing tails
% antsup L ant tails         antsup for R post tails
%     5     4     3     2     1
%     10     9     8     7     6
%     15    14    13    12    11
%     20    19    18    17    16

%Orientation 3 L posterior pointing tails or R anterior pointing tails
% antsup L post tails           antsup for R post tails
%      16    17    18    19    20
%      11    12    13    14    15
%      6     7     8     9    10
%      1     2     3     4     5





[varargin, gridtype] = util.argkeyval('gridtype',varargin, 1); %types of grids, options are mini=1 and 4x5=2 at this time
[varargin, orientation] = util.argkeyval('orientation',varargin, 1); %the orientation on the brain that the tails are pointing
[varargin, xch2plot] = util.argkeyval('xch2plot',varargin, []);  %if userinput false, then xch2plot takes the input channels or does all by default
[varargin, blc] = util.argkeyval('blc',varargin, []);  %if userinput false, then xch2plot takes the input channels or does all by default

util.argempty(varargin); % check all additional inputs have been processed

gridmap=cell(64,1);
%start positions at 1
xp=20; %start on the left (20 20 is the bottom left)
yp=20; %start at the bottom
mveX=80;
mveY=30;
ch=nan(8,8);
%%
switch gridtype
    case 1 %mini
        gridlayout=[1:8; 9:16; 17:24; 25:32; 33:40; 41:48; 49:56; 57:64];
        
       
        if orientation(1)==1 %Orientation 1 L inferior pointing tails or R inferior pointing tails
            gridlayout=fliplr(gridlayout');
        elseif orientation(1)==2 %Orientation 2 L posterior pointing tails or R anterior pointing tails
            gridlayout=gridlayout; %keep in the same
        elseif orientation(1)==3 %Orientation 3 L anterior pointing tails or R posterior pointing tails
            gridlayout=fliplr(flip(gridlayout));
        elseif orientation(1)==4 %Orientation 4 L or R superior pointing tails
            gridlayout=fliplr(gridlayout)';
        end
        if ~isempty(xch2plot)
            for ii=1:length(xch2plot)
                [row, col]=find(gridlayout==xch2plot(ii));
                ch(row,col)=xch2plot(ii);
            end
        else
            
            %%
            figure('Position', [400 400 40+80*9 40+30*9])
            
            for ii=1:64
                [row, col]=find(gridlayout==ii);
                gridmap{ii}=uicontrol('Style','checkbox','String', num2str(gridlayout(row, col)), 'Position', ...
                    [xp+mveX*(col-1) yp+mveY*(8-row) 60 20], 'SelectionHighlight', 'on', 'Callback', @make_grid_callback);
                
            end
            axis off
            title('Choose the electrodes you want plotted against each other, close when finished');
            
        end
    case 2 %WILL NEED TO WORK ON THIS 4x5
        gridlayout=[1:5;6:10;11:15;16:20];
        if orientation(1)==1 %Orientation 1  R or L inferior pointing tails
            gridlayout=gridlayout';
        elseif orientation(1)==2 %Orientation 2 R posterior pointing tails or L anterior pointing tails
            gridlayout=fliplr(gridlayout);
        elseif orientation(1)==3 %Orientation 3 L posterior pointing tails or R anterior pointing tails
            gridlayout=flip(gridlayout);
        elseif orientation(1)==4 %Orientation 4 L sup pointing tails or R sup pointing tails
            fliplr(flip(gridlayout'));
        end
        if ~isempty(xch2plot)
            for ii=1:length(xch2plot)
                [row, col]=find(gridlayout==xch2plot(ii));
                ch(row,col)=xch2plot(ii);
            end
        else
            
            %%
            figure('Position', [400 400 40+80*9 40+30*9])
            
            for ii=1:20
                [row, col]=find(gridlayout==ii);
                gridmap{ii}=uicontrol('Style','checkbox','String', num2str(gridlayout(row, col)), 'Position', ...
                    [xp+mveX*(col-1) yp+mveY*(8-row) 60 20], 'SelectionHighlight', 'on', 'Callback', @make_grid_callback);
                
            end
            axis off
            title('Choose the electrodes you want plotted against each other, close when finished');
            
        end
end



uiwait(gcf);

%%
%load the number into the ch matrix
    function make_grid_callback(h,evt)
        idx=str2double(h.String);
        [row, col]=find(gridlayout==idx);
        ch(row,col)=idx;
    end

%%
%create a smaller grid that has the dimensions and values for the plotting
[r, c]=find(isfinite(ch));
ch2plot=gridlayout(r(1):r(end),c(1):c(end));


if ~isempty(blc)
    if gridtype==1 %if mini, adjust to correct spot for channels
        labels={blc.ChannelInfo.Label};
        loc1=cellfun(@(x)strcmpi(x,'MG1'), labels, 'UniformOutput', false);
        loc2=cellfun(@(x)strcmpi(x,'MOTOR1'), labels, 'UniformOutput', false);
        loc1=cell2mat(loc1);
        loc2=cell2mat(loc2);
        if nnz(loc1)>0
            loc=loc1;            
            stpt=find(loc==1); %this is the buffer to add to the row to make your matrix rows match up
        elseif nnz(loc2)>0
            loc=loc2;            
            stpt=find(loc==1); %this is the buffer to add to the row to make your matrix rows match up
        else
            stpt=inputdlg('Choose starting channel for MotorGrid (check blc.ChannelInfo if unsure, or start with first channel entered)');
            stpt=str2double(stpt{1});
        end
        
        ch2plot=ch2plot+stpt-1; %now the rows match up to the channels
    end
    if gridtype==2 %if 4x5, adjust to correct spot for channels through user choice
        stpt=inputdlg('Choose starting channel for 4x5 (usually pick first channel interested in)');
        stpt=str2double(stpt{1});
        ch2plot=ch2plot+stpt-1; %now the rows match up to the channels
    end

end


end

