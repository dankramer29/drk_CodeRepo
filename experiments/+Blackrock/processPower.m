function [pwr,f,ch] = processPower(src,f,win,numwins,varargin)
% PROCESSPOWER Calculate power in a range of frequency bands for NSx file
%
%   [PWR,F,CH] = PROCESSPOWER(SRC)
%   For the source NSx file SRC, calculate the average power in each 
%   channel CH in SRC returned in PWR.  By default, operates in 10-Hz
%   frequency bands from 0-300 Hz using 100 5-sec nonoverlapping windows,
%   or the available number of full 5-second windows if the file is
%   shorter.
%
%   [PWR,F,CH] = PROCESSPOWER(SRC,F,WIN)
%   Specify the N frequency bands in the Nx2 matrix F, and the window and
%   step size in the 1x2 vector WIN.

% defaults
if nargin<4||isempty(numwins),numwins=100;end
if nargin<3||isempty(win),win=[3 3];end
if nargin<2||isempty(f),f=[(0:10:490)' (10:10:500)'];end

% inputs
[varargin,FlagQuiet] = util.ProcVarargin(varargin,'quiet');
util.ProcVarargin(varargin);

% validate input
assert(exist(src,'file')==2,'Cannot locate ''%s''',src);
[~,~,srcext] = fileparts(src);
assert(strcmpi(srcext(1:end-1),'.ns'),'Input file must be *.nsX where X=1,2,3,4,5,6');
assert(exist('Blackrock.NSx','class')==8,'Cannot find dependency ''Blackrock.NSx''');

% open the data file
ns = Blackrock.NSx(src,'quiet');
[~,whichpkt] = max(ns.PointsPerDataPacket);
numwins = min(numwins,floor(ns.PointsPerDataPacket(whichpkt)/(ns.Fs*max(win))));
ch = [ns.ChannelInfo.ChannelID];

% preallocate
pwr = nan(numwins,ns.ChannelCount,size(f,1));

% start calculating power
tm = 0;
tocs = nan(1,numwins);
for kk=1:numwins
    stopwatch = tic;
    
    % update user
    if ~FlagQuiet
        numrem = numwins-kk;
        timeper = nanmedian(tocs);
        if ~isnan(timeper)
            fprintf('win %d/%d (%s remaining)\n',kk,numwins,util.hms((numrem+1)*timeper,'mm:ss'));
        else
            fprintf('win %d/%d\n',kk,numwins);
        end
    end
    
    % read win-size data
    try
        data = ns.read('Time',[tm tm+win(1)],'units','microvolts','channels',ch);
    catch ME
        util.errorMessage(ME);
        continue;
    end
    
    % calculate band power
    for ff=1:size(f,1)
        pwr(kk,:,ff) = bandpower(data',ns.Fs,f(ff,:));
    end
    
    % measure time for this loop
    tocs(kk) = toc(stopwatch);
    
    % add step-size
    tm = tm+win(2);
end