function [ change, change_d, Comp_data, Base_data ] = findchange( data, params, varargin )
%findchange This will locate spots of change in a signal
%   
%{  
This takes a moving window (not convolve) of size params.wnd(1,1) and
compares that to a window of size params.wnd(1,2) in the past and compares
the two.  To adjust for the movement of +/- signal, it takes an average of
the absolute value of the signal.


EXAMPLE:
params=[];
[ change_idx, change_data, Comp_data, Base_data ] = csd.findchange(ds_ecog1PST, params );

%}


%set parameters. CURRENTLY ONLY USING .PROC
if nargin==3 || isempty (params)
    params = struct;
    params.ch= [1 size(data,2)]; %channels to look at
    params.cuttime= [30 30]; %amount of data to take around the sz, in Min
    params.dsrt= 400; %downsample frequency, base is 400 samples/sec (for 200Hz by nyquist            
    params.wnd= [60 300]; %[Comp_wnd Base_wnd] C for the comparison and B for the baseline, done in seconds
    params.threshold=50; %the threshold you want to see if it's changed below
    params.extendedchange=3; %the factor that the change extends into, so it is X*C_wnd into the future
    params.lessmore=1; %choose 1 for a less than threshold and 2 for more than threshold
    params.change_idx=[];
    params.extendedchange_idx=[];
end
%%
%check if gridtype was specified
[varargin, dsrt, ~, found]=util.argkeyval('dsrt', varargin, 400);
if ~found
    dsrt=params.dsrt;
end

%check if tt was specified, the time axis to plot, this is mostly for
%debugging and doesn't need to be used anywhere
[varargin, tt]=util.argkeyval('tt', varargin, []);

%%
%set up values based on params
%the windows of seconds*samples per second from params.dsrt
Comp_wnd=params.wnd(1,1)*dsrt;
Base_wnd=params.wnd(1,2)*dsrt;
threshold=params.threshold*.01; %to convert to %
ec=params.extendedchange; %this is done as a factor for ease of change

%%
Comp_data=zeros(round(size(data,1)/Comp_wnd),size(data,2));
Base_data=zeros(round(size(data,1)/Base_wnd),size(data,2));
change_data=nan(size(data));
extendedchange_data=nan(size(data));
change_idx=nan(size(Comp_data));
extendedchange_idx=nan(size(Comp_data));

%%


%jj represents the moving comparison window and ii is the columns
for ii=1:size(data,2)
    idx1=1;
    for jj=1:Comp_wnd:size(data,1)
        %baseline data to compare to with Base_wnd, avoid the first few until
        %the baseline is big enough.
        
        if jj-Base_wnd>0&&jj+Comp_wnd<size(data,1)
            %comparison mean of the window Comp_wnd
            Comp_data(idx1,ii)=mean(abs(data(jj:jj+Comp_wnd,ii)));
            %baseline mean of the window Base_wnd behind the jj start point
            Base_data(idx1,ii)=mean(abs(data(jj-Base_wnd:jj,ii)));
            
            
            %%
            %Processing steps for comparison
            switch params.lessmore
                case 1
                    if abs(Comp_data(idx1,ii))<=abs(Base_data(idx1,ii)*threshold);
                        change_data(jj:jj+Comp_wnd,ii)=data(jj:jj+Comp_wnd,ii);
                        change_idx(idx1,ii)=jj;
                        %% a comparison of an extended window in front of the change to see if it is sustained
                        if jj+Comp_wnd*ec<size(data,1)
                            extchange_mean=mean(abs(data(jj:jj+Comp_wnd*ec,ii)));                            
                            if abs(extchange_mean)<=abs(Base_data(idx1,ii)*threshold)                                
                                extendedchange_data(jj:jj+Comp_wnd*ec,ii)=data(jj:jj+Comp_wnd*ec,ii);
                                extendedchange_idx(idx1,ii)=jj;                          
                            else
                                extendedchange_data(jj:jj+Comp_wnd*ec,ii)=NaN;
                                extendedchange_idx(idx1,ii)=NaN;
                            end
                        end
                    else
                        change_data(jj:jj+Comp_wnd,ii)=NaN;
                        change_idx(idx1,ii)=NaN;
                    end
                case 2                   
                    if abs(Comp_data(idx1,ii))>=abs(Base_data(idx1,ii)*threshold)
                        change_data(jj:jj+Comp_wnd,ii)=data(jj:jj+Comp_wnd,ii);
                        change_idx(idx1,ii)=jj;
                        %% a comparison of an extended window in front of the change to see if it is sustained
                        if jj+Comp_wnd*ec<size(data,1)
                            extchange_mean=mean(abs(data(jj:jj+Comp_wnd*ec,ii)));                            
                            if abs(extchange_mean)>=abs(Base_data(idx1,ii)*threshold)                                
                                extendedchange_data(jj:jj+Comp_wnd*ec,ii)=data(jj:jj+Comp_wnd*ec,ii);
                                extendedchange_idx(idx1,ii)=jj;                         
                            else
                                extendedchange_data(jj:jj+Comp_wnd*ec,ii)=NaN;
                                extendedchange_idx(idx1,ii)=NaN;
                            end
                        end
                    else
                        change_data(jj:jj+Comp_wnd,ii)=NaN;
                        change_idx(idx1,ii)=NaN;
                    end
                    
            end
            idx1=idx1+1;
        end
    end
    
end
%output variables
params.change_idx=change_idx;
params.extendedchange_idx=extendedchange_idx;
change=params;
change_d=struct;
change_d.change_data=change_data;
change_d.extendedchange_data=extendedchange_data;
end

