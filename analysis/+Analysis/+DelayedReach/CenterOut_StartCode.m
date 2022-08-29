%this is just a quick run to start the day when it's blank

%make sure task and NSP1 or whatever has the neural data are at the same
%level in the source folder

params=Parameters.Dynamic(@Parameters.Config.BasicAnalysis, 'spk.type', 'nev', 'spk.unsorted', true);
params.dt.cacheread=false;
params.dt.cachewrite=false;
debug=Debug.Debugger('testdebug');

%Make sure you are using the trial you want, check the comments t
taskfile = 'C:\Users\Daniel\Documents\DATA\P013\20171103\Task\20171103-141428-141952-DelayedReach.mat';

task = FrameworkTask(taskfile,debug);
%you can remove ch and full_grid if you just want to run ch 1- 128
[ fire_rate, tuned_chs,  phase_length, targetmean, gof_stats] = Analysis.DelayedReach.spk_proc( task, params, debug, 'ch', [1 42], 'full_grid', false );
