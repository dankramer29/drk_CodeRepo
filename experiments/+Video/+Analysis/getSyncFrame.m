function [frames,srcTimes,idx] = getSyncFrame(matFile,which,times)
%GETSYNCFRAME get frame or frames of video corresponding timestamps from
%  the video file, computer clock, or cbmex.
%
%  Arguments:
%
%  matFile      path to MATLAB mat-file containing data for the recording
%  which        'cbmex', 'video', or 'computer' (which time vector to use)
%  times        requested times (scalar, 10, begin/end, [1 10], contiguous
%               1:10, string representation of any of the above
%
%  Examples:
%
%  % get frames of video for cbmex timestamps between 1-10 sec
%  [frames,srcTimes,idx] = getSyncFrame('c:\path\to\file.mat','cbmex',[1 10]);
%
%  % get frames of video for for video timestamps 30-60 sec
%  [frames,srcTimes,idx] = getSyncFrame('c:\path\to\file.mat','video','30:60')


% check whether file exists
[path,basename] = fileparts(matFile);
mp4File=fullfile(path,[basename '.mp4']);
if(exist(mp4File,'file')~=2)
    error('Could not find %s: check path and try again',mp4File);
end
if(exist(matFile,'file')~=2)
    error('Could not find %s: check path and try again',matFile);
end

% load metadata
CONTAINER = load(matFile);

% input: which time source to use
if(strcmpi(which,'cbmex'))
    sourceTimes = CONTAINER.TIMING.cbmexTime;
elseif(strcmpi(which,'video'))
    sourceTimes = CONTAINER.TIMING.videoTime;
elseif(strcmpi(which,'computer'))
    sourceTimes = CONTAINER.TIMING.computerTime;
end
% input: character representation of requested times
if(ischar(times))
    times = eval(times);
end

% find frame indices
[~,idx1] = min(abs(sourceTimes-times(1)));
[~,idx2] = min(abs(sourceTimes-times(end)));
idx = CONTAINER.TIMING.videoFrames([idx1 idx2]);
srcTimes = sourceTimes(idx1:idx2);

% read the appropriate frames
try
    vr = VideoReader(mp4File);
    frames = read(vr,idx);
catch ME
    fprintf('Unable to read video due to the following error:\n');
    fprintf('%s\n',ME.message);
end
