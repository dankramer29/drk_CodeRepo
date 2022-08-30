function [header, record ] = layread(lay_file_name,recnum)
% input - file name of a .lay file that corresponds to a lay-dat pair
% output:   header - information from .lay file
%           record - EEG data from .dat file



%-------------------
%     lay file
%-------------------

%use inifile to read .lay file as .ini file
data = inifile(lay_file_name,'readall');
%change "empty" cells to '...'
emptyCells = cellfun(@isempty,data);
data(find(emptyCells)) = cellstr('');

%fileinfo
%find the fileinfo section of .lay file
fileInfoArray = data(find(strcmp('fileinfo',data(:,1))),:);
for ii=1:size(fileInfoArray,1)
    %get field name 
    field_name = char(fileInfoArray(ii,3));
    %make it syntax-valid (remove spaces, etc)
    valid_field_name = matlab.lang.makeValidName(field_name);
    %add field to struct with corresponding string data
    rawhdr.fileinfo.(valid_field_name)=char(fileInfoArray(ii,4));
end

%patient
patientArray = data(find(strcmp('patient',data(:,1))),:);
for ii=1:size(patientArray,1)
    %same as above, but more compact
    rawhdr.patient.(matlab.lang.makeValidName(char(patientArray(ii,3))))=char(patientArray(ii,4));
end

%montage
montageArray = data(find(strcmp('montage',data(:,1))),:);
for ii=1:size(montageArray,1)
    %storing a 2D vector of info on specific montage, rather than a string
    montage_data = data(find(strcmp(montageArray(ii,3),data(:,1))),3:4);
    rawhdr.montage.(matlab.lang.makeValidName(char(montageArray(ii,3)))) = montage_data;
end

%sampletimes
sampleTimesArray = data(find(strcmp('sampletimes',data(:,1))),:);
%sampletimes is a cell array, rather than a struct
rawhdr.sampletimes = {};
for ii=1:size(sampleTimesArray,1)
    %store it as a string like in .lay file
    %sampletimes_data = strcat(char(sampleTimesArray(ii,3)),'=',char(sampleTimesArray(ii,4)));
    rawhdr.sampletimes{ii}.sample = str2double(char(sampleTimesArray(ii,3)));
    rawhdr.sampletimes{ii}.time = str2double(char(sampleTimesArray(ii,4)));
end

%channelmap
channelMapArray = data(find(strcmp('channelmap',data(:,1))),:);
%channelmap is a cell array of channel names
rawhdr.channelmap = {};
for ii=1:size(channelMapArray,1)
    rawhdr.channelmap{ii} = char(channelMapArray(ii,3));
end

%-------------------
%      header
%-------------------
%move some info from raw header to header
if isfield(rawhdr,'fileinfo')
    %checking individual fields exist before moving them
    if isfield(rawhdr.fileinfo,'file')
        header.datafile = rawhdr.fileinfo.file;
    end
    if isfield(rawhdr.fileinfo,'samplingrate')
        header.samplingrate = str2double(rawhdr.fileinfo.samplingrate);
    end
    if isfield(rawhdr.fileinfo,'waveformcount')
        header.waveformcount = str2double(rawhdr.fileinfo.waveformcount);
    end
end
%making start time into one form
date = strrep(rawhdr.patient.testdate,'.','/');
time = strrep(rawhdr.patient.testtime,'.',':');
dn = datenum(strcat(date, ',', time));
header.starttime = datetime(dn,'ConvertFrom','datenum');
header.patient = rawhdr.patient;

%-------------------
%     comments
%-------------------
lay_file_ID = fopen(lay_file_name);
%comments need to be extracted manually
header.annotations = {};
rawhdr.comments = {};
comments = 0;
cnum = 1;
tline = fgets(lay_file_ID);
while ischar(tline)
    if (1==comments)
        contents = strsplit(tline,',');
        if numel(contents) < 5
            %this means there are no more comments
            break;
        elseif numel(contents) > 5
            %rejoin comments that have a comma in the text
            contents(5) = {strjoin(contents(5:end),',')};
        end
        %raw header contains just the original lines
        rawhdr.comments{cnum} = tline;
        samplenum = str2double(char(contents(1))) * str2double(char(rawhdr.fileinfo.samplingrate));
        %this calculates sample time
        i=1;
        while i<numel(rawhdr.sampletimes) && samplenum > rawhdr.sampletimes{i+1}.sample
            i=i+1;
        end
        samplenum = samplenum - rawhdr.sampletimes{i}.sample;
        samplesec = samplenum / str2double(char(rawhdr.fileinfo.samplingrate));
        timesec = samplesec + rawhdr.sampletimes{i}.time;
        commenttime= datestr(timesec/86400, 'HH:MM:SS');
        %use date calculated earlier
        dn = datenum(strcat(date, ',', commenttime));
        %put all that into a struct in the header
        header.annotations{cnum}.time = datetime(dn,'ConvertFrom','datenum');
        header.annotations{cnum}.duration = str2double(char(contents(2)));
        header.annotations{cnum}.text = char(contents(5));
        cnum=cnum+1;
    elseif strncmp('[Comments]',tline,9)
        %read until get to comments
        comments = 1;
    end
    tline=fgets(lay_file_ID);
end
fclose(lay_file_ID);

%put raw header in header
header.rawheader = rawhdr;

%-------------------
%     dat file
%-------------------
if nargout > 1
    dat_file_ID = fopen(rawhdr.fileinfo.file);
    %use header to get number of records and calibration
    recnum = str2double(rawhdr.fileinfo.waveformcount);
    calibration = str2double(rawhdr.fileinfo.calibration);
    %read either int32 or short data type
    if (rawhdr.fileinfo.datatype=='7')
        precision = 'int32';
    else
        precision = 'short';
    end
    %read data from .dat file into vector of correct size, then calibrate
    record = fread(dat_file_ID,[recnum,Inf],precision) * calibration;
    fclose(dat_file_ID);
end
end



