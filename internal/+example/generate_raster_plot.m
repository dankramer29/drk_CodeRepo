% before running this script:
%  * create a FrameworkTask object called "task"
%  * create a Debug.Debugger object called "debug"
%  * get a Blackrock.NEV object for the data you want to plot called "nv"

% not working (neural data restart):
% 20170913-103921-103949-DelayedReach
taskfile = '\\striatum\Data\neural\incoming\unsorted\keck\Tadeo Jose psych task\Task\20170913-103921-104545-DelayedReach.mat';
debug = Debug.Debugger('test_raster');
task = FrameworkTask(taskfile,debug);
nv = task.getNeuralDataObject('nev','allgrids');

% get task information
% (to do it task specific, do proc.task.timestamps. that splits it into the
% time bins
[ts,featdef_ts,procdef_ts] = proc.blackrock.timestamps(nv,debug,'UniformOutput',true,'sparse');
trialst_relt = task.trialTimes(:,1)-(procdef_ts.win_start(1));

% plot raster/psth of the full dataset
fig_raster = figure('Position',[300 300 1500 600],'PaperPositionMode','auto');
[~,ax] = plot.raster((0:size(ts{1},1)-1)/nv{1}.ResolutionTimestamps',ts{1},fig_raster,debug,'sort','fr_asc',...
    'title','Raster of all sorted spikes');

%the way this looks is you have 0:the total # events -1/3000 or whatever the sampling rate was which is
%nv{1}.ResolutionTimestamps.  That's all T which is the time stamps. then
%ts{1} which is the sparse matrix of spikes. fig_raster is a sample set up
%for where to put it, 'sort', 'fr_asc' which organizes them in ascending
%order of frequency of firing rate.  then title.
%
%you can also do a 'groups', {4,15,26} to just plot those channels (or
%features)

%if i'm going to do the raster, probably the idea is to figure out the time
%stamps in terms of the rows, then plot from that row to the row that is
%the end of that trial, and do that for all the trials that are of that
%locations, and just pick that channel.  it's possible it's easier to
%rewrite it, but maybe just use that code.


plot.markerLines(ax(2),trialst_relt,...
    'markerlabels',arrayfun(@(x)sprintf('Trial %d',x),1:task.numTrials,'UniformOutput',false),...
    'linewidth',1,'horizontaloffset',7);