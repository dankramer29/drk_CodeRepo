function alignSession(session,varargin)
% ALIGNSESSION Run alignment for all data files in a session
%
%   ALIGNSESSION(SESSION,SUBJECT)
%   Run the alignment function for all data files in the session identified
%   by SESSION (string with format YYYMMDD) and SUBJECT (a valid subject
%   identifier).
%
%   ALIGNSESSION(...,'OVERWRITE')
%   Overwrite existing aligned files.
%
%   ALIGNSESSION(...,DBG)
%   Provide a DEBUG.DEBUGGER object DBG. If one is not provided, one will
%   be created internally.
[varargin,flag_overwrite] = util.argflag('overwrite',varargin,false);
[varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,false);
if ~found_debug,debug=Debug.Debugger('align');end
if ischar(session)
    [varargin,subject,found_subject] = util.argfn(@(x)ischar(x)&&hst.helper.isValidSubject(x),varargin,'dummy_subject');
    if found_subject
        subject = hst.Subject(subject,debug);
    else
        [varargin,subject,found_subject] = util.argisa('hst.Subject',varargin,nan);
    end
    assert(found_subject,'If session input is char, must also provide subject');
    session = hst.Session(session,subject,debug);
end
assert(isa(session,'hst.Session'),'Must provide valid hst.Session, not "%s"',class(session));

if ~debug.isRegistered('Blackrock.NSx')
    debug.registerClient('Blackrock.NSx','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('Blackrock.NEV')
    debug.registerClient('Blackrock.NEV','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('Blackrock.NSx.Writer')
    debug.registerClient('Blackrock.NSxWriter','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('Blackrock.NEVWriter')
    debug.registerClient('Blackrock.NEVWriter','verbosityScreen',Debug.PriorityLevel.CRITICAL,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('FrameworkTask')
    debug.registerClient('FrameworkTask','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end
if ~debug.isRegistered('hst.getTaskFiles')
    debug.registerClient('hst.getTaskFiles','verbosityScreen',Debug.PriorityLevel.ERROR,'verbosityLogfile',Debug.PriorityLevel.INSANITY);
end

% set up args for threshold function
args = {};
if flag_overwrite,args=[args {'overwrite'}];end
args = [args(:)' varargin(:)'];

% get a list of neural data files from (arbitrarily) the first array
% we'll use this as a master sorting list to identify files which have
% recordings from 3+ arrays
master_datafile_list = session.getNeuralDataFiles(session.ArrayInfo.ID{1},'ns6','unaligned');
master_folder_list = session.ArrayInfo.FolderName;
if length(master_folder_list)<3
    error('No alignment needed for fewer than 3 NSPs (found %d)',length(master_folder_list));
end

% find datafiles that have instances for all three arrays (two or fewer
% don't need alignment)
datafiles = cell(length(master_datafile_list),size(session.ArrayInfo,1));
matched_all_nsps = false(length(master_datafile_list),1);
for tt=1:length(master_datafile_list)
    array_datafiles = cell(1,length(master_folder_list));
    array_datafiles{1} = master_datafile_list{tt};
    found_datafile = nan(1,length(master_folder_list));
    found_datafile(1) = true;
    for aa=2:length(master_folder_list)
        array_datafiles{aa} = regexprep(array_datafiles{1},master_folder_list{1},master_folder_list{aa});
        found_datafile(aa) = exist(array_datafiles{aa},'file')==2;
    end
    assert(~any(isnan(found_datafile)),'Problem - did not evaluate something correctly');
    if all(found_datafile)
        datafiles(tt,:) = array_datafiles;
        matched_all_nsps(tt) = true;
    end
end
datafiles(~matched_all_nsps,:) = [];

% process the NS6 files
N = size(datafiles,1);
debug.log(sprintf('Found %d data files for session %s',N,session.ID),'info');
loop_times_files = nan(1,N);
for nn=1:N
    stopwatch_files = tic;
    datafile = datafiles{nn,1};
    time_left = nnz(isnan(loop_times_files))*nanmean(loop_times_files);
    
    % rethreshold
    try
        [~,datafile_basename] = fileparts(datafile);
        datafile_basename = regexprep(datafile_basename,master_folder_list{1},'*');
        debug.log(sprintf('Processing data file %d/%d (%s) (%s remaining)',nn,N,datafile_basename,util.hms(time_left)),'info');
        Blackrock.alignNSPs(datafile,debug,args{:});
    catch ME
        util.errorMessage(ME);
        continue;
    end
    loop_times_files(nn) = toc(stopwatch_files);
end