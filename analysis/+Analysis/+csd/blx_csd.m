function [ blc, dsrt, outputstruct] = blx_csd( FileName, map, params, varargin)
%blx_csd This is a function to run the entire process from start to finish
%of blc files through the csd processing
%{
   Must have the folders analysis and internal in the path to work

INPUTS:
    FileName=       The full path name, can get it by holding shift and
        right clicking on the file and doing "copy path", then paste and delete
        the " marks
    map=            The map file.  This is mostly for the titles
    params=         See below.  Can change most defaults in here
    
VARARGINS
    ch=             channels in the format [chstart chend]
    Sz=             The seizure time, done as a date time.  The date has to
                        be the date of the actual seizure (not when the file was started (so if
                        the file is 08-Jun-2016 and the seizure occurs the next day on
                        09-Jun-2016 put in 09.
    gridtype=       The type of grid put in.  1 is 4x5 and 2 is 1x6 and the
                        rest haven't been entered yet.



OUTPUTS:

    blc=            The blc output file
    dsrt=           The downsampled rate, typically 400hz
    ds_ecogS=       A struct containing the .data from the downsampled raw
                        data for other analysis, the .tt for time array for plotting (with the seizure
                        set as the 0), and .change for the substruct that contains the
                        information on what was run from the findchange function, which does
                        moving averages of set windows and baselines and
                        returns those data.  The data returned in the
                        change_idx and extendedchange_idx are the row
                        numbers of those that meet the criteria.  Extended
                        change is any change that occurrs and then
                        continues for a second window.
    fltS=            Same as above but for: The filtered data with a window averaging and a
                    bandpass
    flt_lwpsS=       Same as above but for: The filtered data with a lwps (really a low bandpass)
    intg_fltS=       Same as above but for:  The integral data with the subtraction of the average
                        (FOR THE MOST PART, THIS DOESNT WORK.  IN FABRICIUS THEY DO A 0.05 LOW
                        PASS FILTER AND THAT IS HARD FILTERED OUT IN THE DATA
    pwr_lwpsS=       Same as above but for: The power with a lowpass filter
                            (CURRENTLY NOT IN USE)
    change=         Struct that contains the locations of threshold
                        crossing changes from the function
                        csd.findchange.m. Locations are the row that it
                        starts, based on the comparison window you specify
                        within that function
    


EXAMPLE:
The date time for the seizure should be the actual date it occurs, not the
date of the origin of the file

Need the map
map=GridMap('Rios Geraldin_32715_Ph2D2_map.csv');
params=[];
FileName= 'Path';
[ blc3PSGall, dsrt3PSGall, ds_ecog3PSGall, flt3PSGall, flt_lwps3PSGall, intg_flt3PSGall, pwr_lwps3PSGall,changePSGall, tt13PSGall, tt23PSGall, tt33PSGall ] = Analysis.csd.blx_csd('C:\Users\Daniel\Documents\Rios Geraldin_32715_Ph2D2-000.blc', map, params,'ch', [21 40], 'Sz','28-Mar-2015 4:24:10');


TO DO:
       -Fix the comments and readme

%}

%%
%params is a struct for inputting optional variables.  the
%varargin ones will need to be included.
%so if there arent any inputs past Filename or params is empty at any point
if nargin==2 || isempty (params)
    params = struct;
    params.ch= [1 20]; %channels to look at (21 30 in GR)
    params.cuttime= [30 25]; %amount of data to take around the sz, in Min
    params.newfs= 400; %downsample frequency, base is 400 samples/sec (for 200Hz by nyquist)
    params.fltr= 60; %notch filter of 60Hz, does not work on harmonics right now(I think)
    params.proc= 2; %how many processing steps to do. 
        %1 - filtered voltage         
        %2 - 1+raw voltage squared (pwr) and then a low pass filter is
        %applied, currently at 5Hz, through subsampling
        %3 = 2+integral of the data and the integral filtered data (intg and
            %intg_flt
    params.wnd= [300 300]; %wnd1 and wnd2, set at 300s each, wdw 2 is the time constant decay
    params.bandpass= [0.5 40]; %bandpass filter set at 0.5 to 70Hz
    params.lowpass= 5; %the lowpass filter set at 5Hz right now, for 10 samples/second in the pwr analysis
    params.bipolar= true; % to run bipolar channel outputs.
    params.savefig= true; %turn on or off the saving of figures
   
    
end



%%    
%%VARARGINS

%Channels- pulling data from ch1 to ch2 and making the names of the
%channels to pass into the plot function
idx = find(strcmpi(varargin,'ch'),1);
if ~isempty(idx)
    params.ch = varargin{idx+1};
    varargin(idx:idx+1) = [];
    ch1 = params.ch(1,1);
    ch2 = params.ch(1,2);
else
    warning('channels set in params');
    ch1 = params.ch(1,1);
    ch2 = params.ch(1,2);
end
%get the downsample rate, set at 400 samples/sec by default
newfs=params.newfs;
    

%check initial inputs to make sure all represented

%Sz- find the seizure time
idx = find(strcmpi(varargin,'Sz'),1);
if ~isempty(idx)
    Sz = varargin{idx+1};
    varargin(idx:idx+1) = [];
else
    warning('no seizure time entered');
end


%Find the seizure time
x = datetime(Sz,'InputFormat','dd-MMM-yyyy HH:mm:ss');
CutPre=params.cuttime(1,1);
CutPost=params.cuttime(1,2);
cut = [minutes(-CutPre) minutes(CutPost)];

y = x + cut;

%check if gridtype was specified
[varargin, gridtype]=util.argkeyval('gridtype', varargin, 1); %RIGHT NOW ONLY DOES 4X5 AND 1X6
[varargin, CloseFig]=util.argkeyval('CloseFig', varargin, false); %RIGHT NOW ONLY DOES 4X5 AND 1X6


%makes sure that the varargin is processed properly
util.argempty(varargin);




%%
%Run the reader to pull the data
blc=BLc.Reader(FileName);



%%
%Run the reader to create actual data in ecog
ecog=blc.read('context', 'absolute', 'time', y, 'channels', ch1:ch2);  %can change the time or the channels

if params.bipolar
    for ii=1:size(ecog,2)-1;ecog(:,ii)=ecog(:,ii)-ecog(:,ii+1); end
end
ecog(:,size(ecog,2))=[];
    
%%
%Run the downsample function
[ ds_ecog, dsrt ] = Analysis.csd.blx_ds_data( ecog, blc, 'newfs', newfs); %currently does not pass params in


%%
%Run the processing function
t=tic;
[ flt, flt_lwps, intg_flt, pwr, pwr_lwps ] = Analysis.csd.blx_prc2( ds_ecog, dsrt, params);
toc(t)

%%
%Run the findchange function to find areas that have gone below the
%threshold for the specified period of time.  Currently set in
%params2.wnd=[60 300], which slides forward every 60 seconds, then compares
%to the 300s behind, and the extended change set at
%params2.extendedchange=3, which checks if the change is sustained for 3x
%in front, meaning the change lasts for 3 minutes below threshold.
params2=[];
[ change_ds_ecog,  change_data_ds_ecog, Comp_data, Base_data] = Analysis.csd.findchange( ds_ecog, params2 );
[ change_flt,  change_data_flt, Comp_data, Base_data] = Analysis.csd.findchange( flt, params2 );
[ change_flt_lwps,  change_data_flt_lwps, Comp_data, Base_data] = Analysis.csd.findchange( flt_lwps, params2 );
%[ change_intg_flt,  change_data_intg_flt, Comp_data, Base_data] = Analysis.csd.findchange( intg_flt, params2 );
[ change_pwr_lwps,  change_data_pwr_lwps,  Comp_data, Base_data] = Analysis.csd.findchange( pwr_lwps, params2, 'dsrt', 10 );
%%
%Run the plot functions
ch1n=map.ChannelInfo{ch1,2}; ch2n=map.ChannelInfo{ch2,2};
figtitle=[blc.SourceBasename ' Raw ecog ' ch1n{1,1} ' to ' ch2n{1,1}];
Analysis.csd.gridplot( ds_ecog,  map, 'datatype', 1, 'dsrt', dsrt, 'sz', CutPre, 'ch', [ch1 ch2], 'figtitle', figtitle, 'gridtype', gridtype, 'c_data', change_data_ds_ecog  );
figtitle=[blc.SourceBasename ' Filtered data ' ch1n{1,1} ' to ' ch2n{1,1}];
Analysis.csd.gridplot( flt,  map, 'datatype', 2, 'dsrt', dsrt, 'sz', CutPre, 'ch', [ch1 ch2], 'figtitle', figtitle, 'gridtype', gridtype, 'c_data', change_data_flt );
figtitle=[blc.SourceBasename ' Low pass ' num2str(params.lowpass) 'Hz ' ch1n{1,1} ' to ' ch2n{1,1}];
tt1=Analysis.csd.gridplot( flt_lwps,  map, 'datatype', 3, 'dsrt', dsrt, 'sz', CutPre, 'ch', [ch1 ch2], 'figtitle', figtitle, 'gridtype', gridtype, 'c_data', change_data_flt_lwps );
figtitle=[blc.SourceBasename ' Power with Low pass ' num2str(params.lowpass) 'Hz ' ch1n{1,1} ' to ' ch2n{1,1}];
tt3=Analysis.csd.gridplot( pwr_lwps,  map, 'datatype', 4, 'dsrt', dsrt, 'sz', CutPre, 'ch', [ch1 ch2], 'figtitle', figtitle, 'gridtype', gridtype, 'c_data', change_data_pwr_lwps );
%tt2=Analysis.csd.gridplot( intg_flt,  map, 'datatype', 5, 'dsrt', dsrt, 'sz', CutPre, 'ch', [ch1 ch2], 'figtitle', figtitle );
%tt2=[];


%%
%Make spectrograms
params2=[];
figtitle=[blc.SourceBasename ' Spectrogram '  ch1n{1,1} ' to ' ch2n{1,1}];
[Ss, ts, fs]=Analysis.csd.blx_split_spect( ds_ecog, params2, 'ch', [ch1 ch2], 'tt', tt1, 'gridtype', gridtype, 'figtitle', figtitle, 'map', map );

figtitle=[blc.SourceBasename ' Spectrogram as compared to first 5 min baseline ' ch1n{1,1} ' to ' ch2n{1,1}]; %alternatively 'Bridget Miller_Sz2_6212016_Ph2D6_005855-000 Spectrogram as a ratio compared to first 5 min baseline PST1 to PST6'
[Ss_c, ts_c, fs_c]=Analysis.csd.blx_split_spect_c( ds_ecog, params2, 'ch', [ch1 ch2], 'tt', tt1, 'gridtype', gridtype, 'figtitle', figtitle, 'map', map );

%%
%create the output structures
ds_ecogS=struct;
ds_ecogS.data=ds_ecog;
ds_ecogS.tt=tt1;
ds_ecogS.change=change_ds_ecog;

fltS=struct;
fltS.data=flt;
fltS.tt=tt1;
fltS.change=change_flt;

flt_lwpsS=struct;
flt_lwpsS.data=flt_lwps;
flt_lwpsS.tt=tt1;
flt_lwpsS.change=change_flt_lwps;

intg_fltS=struct;
intg_fltS=[]; %get rid of this if ever need to run intg_flt
%intg_fltS.data=intg_flt;
%intg_fltS.tt=tt2;
%intg_fltS.change=change_intg_flt;

pwr_lwpsS=struct;
pwr_lwpsS.data=pwr_lwps;
pwr_lwpsS.tt=tt3;
pwr_lwpsS.change=change_pwr_lwps;

spect_op=struct;
spect_op.ts=ts;
spect_op.fs=fs;
spect_op.Spectout=Ss;

spect_op_c=struct;
spect_op_c.ts=ts_c;
spect_op_c.fs=fs_c;
spect_op_c.Spectout=Ss_c;

%final output
outputstruct=struct;
outputstruct.ds_ecogS=ds_ecogS;
outputstruct.fltS=fltS;
outputstruct.flt_lwpsS=flt_lwpsS;
outputstruct.intg_fltS=intg_fltS;
outputstruct.pwr_lwpsS=pwr_lwpsS;
outputstruct.spect=spect_op;
outputstruct.spect_toBaseline=spect_op_c;
%%
plot.save_currfig('SavePath', blc, 'CloseFig', CloseFig);

%Save the figures. Currently as png because the fig files are huge.
% if params.savefig
%     h = get(0,'children');
%     for i=1:length(h)
%         saveas(h(i), get(h(i),'Name'), 'png');
%     end
% end

end

