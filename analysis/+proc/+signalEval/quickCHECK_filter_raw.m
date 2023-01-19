PCname = getenv('COMPUTERNAME'); 

switch PCname
    case 'DESKTOP-95LU6PO'
        nwbLOC = 'F:\01_Coding_Datasets\LossAversionPipeTest\CLASE007\NWB-data\20220526a\NWB_Data';
    case 'DESKTOP-I5CPDO7' % Office pc
        nwbLOC = 'Z:\LossAversion\Patient folders\CLASE007\NWB-data\20220526a\NWB_Data';
    case 'DESKTOP-FAGRV5G' % JAT home pc
        nwbLOC = 'F:\01_Coding_Datasets\LossAversionPipeTest\CLASE007\NWB-data\NWB_Data';
        % matnwb
        addpath(genpath('C:\Users\Admin\Documents\MATLAB\matnwb-2.5.0.0'));


end




%% 4a. Use CLASE007

% Brain Area: amygdala
bAREA = 'amygdala';
% Hemisphere: Left
hemi2f = 'L';
% Wire number: 1
% Number of contacts: 8
% CSC# / Rows: CSC 1:8 / matrix rows 1:8

%% 4b. Load in NWB filtered
cd(nwbLOC);
tmpLoad = nwbRead("MW13_Session_5_filter.nwb");
eleCtable = tmpLoad.general_extracellular_ephys_electrodes.vectordata;

chanID = eleCtable.get('channID').data.load();
hemis = cellstr(eleCtable.get('hemisph').data.load());
label = cellstr(eleCtable.get('label').data.load());
location = cellstr(eleCtable.get('location').data.load());
wireID = eleCtable.get('wireID').data.load();

macroROWS = contains(label,'MA_');
macro_hemi = hemis(macroROWS);
macro_location = location(macroROWS);
macro_wire = wireID(macroROWS);

% load macrodata
macroDATA = tmpLoad.processing.get('ecephys').nwbdatainterface.get('LFP').electricalseries.get('MacroWireSeries').data.load();

% Brain area index
brainAind = matches(macro_location,bAREA);
hemiIND = matches(macro_hemi,hemi2f);
macroINDs = find(brainAind & hemiIND);

% Get channels of interest
amyData_filter = macroDATA(macroINDs,:);

%% Plot Filtered Macro data (FMD)
% Raw voltage stack plot
[stkTaball, stkTabBP] = convertRAWmac2stktab('seeg',amyData_filter,500,1);

%% Stack of all (FMD)
close all
toplotTime = 5*500; % seconds x sampling frequency
maxY_FMD_all = max(table2array(stkTaball),[],'all');
minY_FMD_all = min(table2array(stkTaball),[],'all');
s_FMD_all = stackedplot(stkTaball(1:toplotTime,:));
for yC = 1:width(stkTaball)
    s_FMD_all.AxesProperties(yC).YLimits = [minY_FMD_all maxY_FMD_all];
end

%% Stack of bipolar (FMD)
figure;
maxY_FMD_bp = max(table2array(stkTabBP),[],'all');
minY_FMD_bp = min(table2array(stkTabBP),[],'all');
s_FMD_bp = stackedplot(stkTabBP(1:toplotTime,:));
for yC = 1:width(stkTabBP)
    s_FMD_bp.AxesProperties(yC).YLimits = [minY_FMD_bp maxY_FMD_bp];
end

%% Stack of all PSD (FMD)
figure;
[FMD.all.pxx,FMD.all.f] = pspectrum(stkTaball,'FrequencyLimits',[0 80]);
FMD.all.pwRspec = pow2db(FMD.all.pxx);
FMD.all.pwRspecT = array2table(FMD.all.pwRspec);
psd_FMD_all = stackedplot(FMD.all.pwRspecT);


%% Stack of all PSD (FMD)
figure;
[FMD.bp.pxx,FMD.bp.f] = pspectrum(stkTabBP,'FrequencyLimits',[0 80]);
FMD.bp.pwRspec = pow2db(FMD.bp.pxx);
FMD.bp.pwRspecT = array2table(FMD.bp.pwRspec);
psd_FMD_bp = stackedplot(FMD.bp.pwRspecT);



%% 5a. Load in NWB filtered
cd(nwbLOC);
tmpLoad_raw = nwbRead("MW13_Session_5_raw.nwb");

% load macrodata
macroDATA_raw = tmpLoad_raw.acquisition.get('MacroWireSeries').data.load();

% Get channels of interest
amyData_raw = macroDATA_raw(macroINDs,:);

%% Plot Filtered Macro data (RMD)
% Raw voltage stack plot
[stk_RMD_all, stk_RMD_bp] = convertRAWmac2stktab('seeg',amyData_raw,4000,1);

%% Stack of all (RMD)
close all
toplotTime = 5*4000; % seconds x sampling frequency
maxY_RMD_all = max(table2array(stk_RMD_all),[],'all');
minY_RMD_all = min(table2array(stk_RMD_all),[],'all');
s_RMD_all = stackedplot(stk_RMD_all(1:toplotTime,:));
for yC = 1:width(stk_RMD_all)
    s_RMD_all.AxesProperties(yC).YLimits = [minY_RMD_all maxY_RMD_all];
end

%% Stack of bipolar (RMD)
close all
maxY_RMD_bp = max(table2array(stk_RMD_bp),[],'all');
minY_RMD_bp = min(table2array(stk_RMD_bp),[],'all');
s_RMD_bp = stackedplot(stk_RMD_bp(1:toplotTime,:));
for yC = 1:width(stk_RMD_bp)
    s_RMD_bp.AxesProperties(yC).YLimits = [minY_RMD_bp maxY_RMD_bp];
end

%% Stack of all PSD (RMD)
close all
[RMD.all.pxx,RMD.all.f] = pspectrum(stk_RMD_all,'FrequencyLimits',[0 80]);
RMD.all.pwRspec = pow2db(RMD.all.pxx);
RMD.all.pwRspecT = array2table(RMD.all.pwRspec);
psd_RMD_all = stackedplot(RMD.all.pwRspecT);


%% Stack of all PSD (RMD)
close all
[RMD.bp.pxx,RMD.bp.f] = pspectrum(stk_RMD_bp,'FrequencyLimits',[0 80]);
RMD.bp.pwRspec = pow2db(RMD.bp.pxx);
RMD.bp.pwRspecT = array2table(RMD.bp.pwRspec);
psd_RMD_bp = stackedplot(RMD.bp.pwRspecT);








