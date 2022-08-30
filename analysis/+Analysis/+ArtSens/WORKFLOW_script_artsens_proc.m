%%FULL RUN SCRIPT
%THIS WILL INCLUDE A PLAN TO RUN THROUGH EVERYTHING WHEN ALL PATIENTS ARE
%SET UP. THE PURPOSE OF THIS IS TO HAVE A WORK FLOW SO THESE SCRIPTS DON'T
%GET SO CONFUSING. IN THEORY IT'S PUSH BUTTON, BUT LIKELY STUFF WILL NEED
%TO BE CHANGED AND LOOKED OVER

%%
%Loading previously run data (4 subjects)
% \\striatum\Data\user home\Dan\RealTouchAll\SpecgramcOutputsAllSubj
% This contains the data from previously run trials so you don't have to redo it
% blcfiles_all has the blc file outputs from blc.reader for all 4 subjects
% chRelevant has all fo the channels with statistically significant areas, this can be mapped to the spread sheet Results Overall.4, made after reviewing the outputs
% filtered_power_all is the power bandpass filtered
% filtered_power_integrated_peaks is the filtered power run through the integral smoothing from specpeak.m
% filtered_power_normalized_db_andnondb_all is filtered and normalized, this is the one you want to use for running through PEAKS_script (or run new within that script)
% specgramcall is the specgram output of all the subjects from the main art_sens_proc output
% specPowerAll is the main Power output from the main art_sens_proc output, which is just the averaged power from specgramc over the frequency bands at either 2 (200ms window) or 5 (500ms window), however, it's mostly replaced by the filtered power, so long story short, likely don't need this

% To find the data (from matlab):  \\striatum\Data\user home\Dan
% 
% The data for gridmaps and for blc is in \\STRIATUM\Data\neural\working\Real Touch
% 
% To find the natus data raw: \\striatum\Data\neural\incoming\unsorted


%NOTE: IF A NEW PATIENT IS ADDED, THAT WILL NEED TO BE RUN THROUGH
%ARTSENS_PROC IN THE SAME WAY IT IS IN THE SCRIPT RUN_SCRIPT_ARTSENS_PROC
%REMEMBER TO MAKE AN _EVENTS FILE WITH THE SAME BASE NAME. IF FROM .E
%FILES, MEANING MOVE IT INTO THE SAME FOLDER AND MAKE THE SAME NAME AS THE
%BLC WITH A _Events FILE AFTER.
%WILL HAVE TO MAKE BY HAND. EASIEST WAY IS TO HAVE THE TIME IN A LEFT
%COLUMN AND THE XX/ZZ IN THE RIGHT.  THE TIMES NEED TO HAVE 3 DIGITS, SO
%ADD A 0 SO IT'S 04:24:32.230.  IF IT DOESN'T WORK, ADD TWO SPACES AFTER
%THE NUMBERS (SHOULD BE FIXED THOUGH)

%TO FIND CHANNEL NAMES, MAKE SURE YOU USE THE BLC FILE CHANNEL INFO AND NOT
%THE MAPFILE 

%IF DOING JR: the map skips channel 54, but when you run it through the blc
%file, that channel info has them as 54 to 117



%%
%%this is the bulk of the processing, run this with comments off to add
%%everyone. last i left it (5/25/18) it is set up to just run the
%%normalization part, but can add all outputs if doing it fresh, like this
%%although the next run, at a 500ms window, don't need the last two since
%%it is independent of the window
%[ thisCG2, specPowerCG2, specgramcCG2, elec_pCG2, filtbandPower.cg, filtbandPowerdB.cg ]  = Analysis.ArtSens.artsens_proc( blcCG, 'ch', [49 112], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'data', dataCG, 'quickrun', true);

Analysis.ArtSens.RUN_script_artsens_proc.m

%%
%%then run below.  Will want to uncomment line 19, the part that runs
%%powerPeak and all of the statistical outputs at the bottom

Analysis.ArtSens.PEAKS_script.m


%%
%%then the below plotting script has blocks to make different plots. IT
%%CANNOT BE RUN AS ONE, IT JUST HAS MULTIPLE BLOCKS OF INDEPENDENT PLOTTING
%%SCRIPTS.  IT IS NOT WELL ORGANIZED OR COMMENTED AND WILL GIVE SPENCER AN
%%ULCER, HOWEVER, MANY OF THEM WORK JUST FINE WITHIN THE BLOCK

Analysis.ArtSens.PLOTTING_script_mblocks.m



