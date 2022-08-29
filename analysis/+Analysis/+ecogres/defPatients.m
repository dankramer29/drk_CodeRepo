function srctable = defPatients
src = cell(3,5);
pt_idx = 0;

pt_idx = pt_idx + 1;
src(pt_idx,:) = {...
    'p1',... % PID
    352372,... % MR
    'keck',... % INSTITUTION
    datenum('2016-03-31','yyyy-mm-dd'),... % DATE
    'Ramirez Fernando_4116_Ph2D2'}; % DIRECTORY

pt_idx = pt_idx + 1;
src(pt_idx,:) = {...
    'p2',... % PID
    1198874,... % MR
    'keck',... % INSTITUTION
    datenum('2016-06-16','yyyy-mm-dd'),... % DATE
    'Miller Bridget_61716_Ph2D2'}; % DIRECTORY

pt_idx = pt_idx + 1;
src(pt_idx,:) = {...
    'p3',... % PID
    3636539,... % MR
    'keck',... % INSTITUTION
    datenum('2017-01-18','yyyy-mm-dd'),... % DATE
    'Bernal Jennifer_11916_Ph2D2'}; % DIRECTORY

pt_idx = pt_idx + 1;
src(pt_idx,:) = {...
    'p4',... % PID
    'XXXXXX',... % MR
    'keck',... % INSTITUTION
    datenum('2017-03-20','yyyy-mm-dd'),... % DATE
    fullfile('vlahos - 2 years old macro stim','VLAHOS~ ATHANA_ec3d19ef-72cb-449a-be08-56ccfb1604b5')}; % DIRECTORY

pt_idx = pt_idx + 1;
src(pt_idx,:) = {...
    's2',... % PID
    2,... % MR
    'caltech',... % INSTITUTION
    datenum('2016-11-18','yyyy-mm-dd'),... % DATE
    'S2'}; % DIRECTORY

srctable = cell2table(src,'VariableNames',{'pid','mr','institution','date','directory'});