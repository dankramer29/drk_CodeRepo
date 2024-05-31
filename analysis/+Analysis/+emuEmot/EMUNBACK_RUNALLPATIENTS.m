
TSigClustSummStatsTemp = [];
TSigClustSummStatsIndividTemp = [];
TSigClustChannelCountTemp = [];
PercKeptAll = zeros(12,12);
idx1 = 1;
%turns off the plotting since it's been done a bunch
DoPlot = 0; savePlot = 0;


%MW24
fileVariation = 4;
sessionName = 'MW_24';
subjName = 'MW_24';
matNameId = 'NBack_IDENTITY_2023_09_05.13_01_39'; 
matNameEm = 'NBack_EMOTION_2023_09_05.13_10_38';
identityFilter = 'JM_MW24_Session_6_filter.nwb';
emotionFilter = 'JM_MW24_Session_7_filter.nwb';
chInterestActual = [24:27, 33:36, 45:48, 145:148];
removeTrialsEmot = [1,2,5,7,12, 13,15,19,21,22,24,31,32, 33, 34,35,36,38,40,41,42,44,45,46,47,48,49,50,52,54:114,117:126,128:166, 170:172];
removeTrialsId = [2:39,41:42,44,47:164,166:180];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll

%MW2
fileVariation = 2;
sessionName = 'MW_2';
subjName = 'MW_2';
matNameId = 'NBack_2021_3_23.17_28_41'; 
matNameEm = 'NBack_2021_3_23.17_32_58'; 
emotionidentityFilter = 'MW2_Session_7_filter.nwb';
load MW2_Session_7_EventKey.mat;    
chInterestActual = [47:50, 85:88, 97:100, 149:152];
removeTrialsEmot = [8, 14:26, 28,31, 32, 34];

removeTrialsId = [1,2,8,9:12, 14, 15:19, 21:30,32:35,37:38,40, 42:67,72,73, 75,79,88:103];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW5 
fileVariation = 2;
sessionName = 'MW_5';
subjName = 'MW_5';
matNameId = 'NBack_IDENTITY_2021_7_18.13_27_48'; 
matNameEm = 'NBack_EMOTION_2021_7_18.13_32_34'; 
emotionidentityFilter = 'JM_MW5_Session_8_filter.nwb';
load JM_MW5_Session_8_EventKey.mat;    
chInterestActual = [37:40,49:51,61:64,139:140,151:151];
removeTrialsEmot = [1,2,4:9, 11, 13:18, 20:26, 28:32, 35, 38:51, 53:61, 63:70, 72, 74:78];
removeTrialsId = [2:6, 11:13, 17:21, 25, 26, 29:36, 39:47, 49:53,56:83, 86:100];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW18 channels NOTE MW18 HAS CHANNELS MISSING

% fileVariation = 3;
sessionName = 'MW_18';
subjName = 'MW_18';
matNameId = 'NBack_IDENTITY_2022_10_20.13_12_18'; 
matNameEm = 'NBack_EMOTION_2022_10_20.13_20_21'; 
identityFilter = 'JM_MW18_Session_11_filter.nwb'; %does NOT need to be placed in a folder
emotionFilter = 'JM_MW18_Session_12_filter.nwb';
load JM_MW18_Session_11_EventKey.mat
EvKeyId = EvKey;
load JM_MW18_Session_12_EventKey.mat
EvKeyEm = EvKey;
chInterestActual = [12,13, 22:27, 36:39, 149:152, 158:161];
removeTrialsEmot = [1,2,4,6:21,25,29:31, 36, 37, 39, 40, 41, 42,42, 48, 49, 50, 51, 52, 53, 54, 58, 59, 60, 61, 64:67, 69, 70, 71, 72, 73:76, 79:81, 83, 85:94, 97:99, 103, 105, 112,113, 114,115, 119:121, 123:125, 149,152, 153];
removeTrialsId = [1,2,4,5:15, 17, 20:23, 25:34, 37:44, 46:49, 54:63, 67:80, 84:97, 99, 102, 103, 107:117, 119, 123, 126, 130:133, 135:137, 143, 148, 158, 160];
fastRun = true;


run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW16 CAN UNCOMMENT THIS AND RUN IT.
fileVariation = 3;
sessionName = 'MW_16';
subjName = 'MW_16';
matNameId = 'NBack_IDENTITY_2022_08_29.16_54_54'; 
matNameEm = 'NBack_EMOTION_2022_08_30.14_37_58'; 
identityFilter = 'JM_MW16_Session_1_filter.nwb'; %does NOT need to be placed in a folder
emotionFilter = 'JM_MW16_Session_3_filter.nwb';
load JM_MW16_Session_1_EventKey.mat
EvKeyId = EvKey;
load JM_MW16_Session_3_EventKey.mat
EvKeyEm = EvKey;
chInterestActual = [1,2,3,9,10,11,12,13,14,25,26,27,28,39,40,41,42,54,55,66,67,68];
removeTrialsEmot = [1,2, 4:6, 8:13, 16:28, 30:37, 39, 41:44, 47:49, 51:53, 55:58, 60, 62, 64:66, 69:95, 99:100, 102:109, 116, 118, 120, 122:123, 126:127, 129, 131:223];
removeTrialsId = [1:10, 13:38,40:43,46:49, 55:56, 58:59, 62, 64:69, 71:75, 77:83,85:89,91:227];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW23 channels

fileVariation = 4;
sessionName = 'MW_23';
subjName = 'MW_23';
matNameId = 'NBack_IDENTITY_2023_06_27.13_22_22'; 
matNameEm = 'NBack_EMOTION_2023_06_27.13_29_53';
identityFilter = 'JM_MW23_Session_8_filter.nwb';
emotionFilter = 'JM_MW23_Session_9_filter.nwb';
chInterestActual = [46:48,54:57,68:70,145:147,154:158];
removeTrialsEmot = [1,3,4,7, 10, 12, 20, 21,22,45];
removeTrialsId = [1, 2, 5, 6, 8,9, 25, 37, 48, 49];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW19 channels:
% 
fileVariation = 4;
sessionName = 'MW_19';
subjName = 'MW_19';
matNameId = 'NBack_IDENTITY_2022_10_31.16_02_28'; 
matNameEm = 'NBack_EMOTION_2022_10_31.16_10_12';
identityFilter = 'JM_MW19_Session_6_filter.nwb';
emotionFilter = 'JM_MW19_Session_7_filter.nwb';
chInterestActual = [11:14, 23:25, 115:117, 123:125];
removeTrialsEmot = [4,6, 11, 16, 17, 18, 21, 28, 30];
removeTrialsId = [11,12,13,14,19,20,21,22, 23, 24, 29];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW22 channels:

fileVariation = 4;
sessionName = 'MW_22';
subjName = 'MW_22';
matNameId = 'NBack_IDENTITY_2023_04_10.15_56_32'; 
matNameEm = 'NBack_EMOTION_2023_04_10.16_04_57'; 
identityFilter = 'JM_MW22_Session_6_filter.nwb';
emotionFilter = 'JM_MW22_Session_7_filter.nwb';
chInterestActual=[16:19,28:31,40:42,169:171,178:181];
removeTrialsEmot =[3, 5, 10, 12, 15,22,23,24, 25,26,28,30,31,34,35:49, 51,53:58, 60, 62,63, 65:69, 71:73, 75:85, 86,89:90, 100, 101, 125, 128, 130, 133,136];
removeTrialsId = [1,2:9, 13, 15, 16, 17, 18, 20, 21, 22:26, 28, 31:52, 54:85, 87, 94:95, 110, 111, 112, 116, 117, 118];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


% %MW21 channels:

fileVariation = 4;
sessionName = 'MW_21';
subjName = 'MW_21';
matNameId = 'NBack_IDENTITY_2023_02_20.13_33_51'; 
matNameEm = 'NBack_EMOTION_2023_02_20.13_43_16'; 
identityFilter = 'JM_MW21_Session_10_filter.nwb';
emotionFilter = 'JM_MW21_Session_12_filter.nwb';
chInterestActual = [49,50,57,58,65,66,67,68];
removeTrialsEmot =[1, 8, 15];
removeTrialsId = [1,2, 5, 6];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll


%MW13 channels:
fileVariation = 6;
sessionName = 'MW_13';
subjName = 'MW_13';
matNameId = 'NBack_IDENTITY_2022_5_29.18_5_50'; 
matNameEm = 'NBack_EMOTION_2022_5_29.18_10_57'; 
identityFilter = 'JM_MW13_Session_9_filter.nwb'; 
emotionFilter = 'JM_MW13_Session_10_filter.nwb';
EvKeyEm = [];
EvKeyId = [];
chInterestActual = [1,2,3,9,10,11,17,18,19,67:69,81:83,93:96];
removeTrialsEmot = [2, 6, 9, 11,14,32,36,37,40];
removeTrialsId = [1,4];
fastRun = true;

run Analysis.emuEmot.EMUNBACK_PROC.m
run Analysis.emuEmot.EMUNBACK_NOISECHECK
run Analysis.emuEmot.EMUNBACK_WITHINCOMPARISON_PLOT
TSigClustSummStatsTemp = vertcat(TSigClustSummStatsTemp, MWX.SigClusterSummStats);
TSigClustSummStatsIndividTemp = vertcat(TSigClustSummStatsIndividTemp, MWX.SigClusterSummStatsIndividEmId);
TSigClustChannelCountTemp = vertcat(TSigClustChannelCountTemp, MWX.SigClusterChannelCount);
PercKeptAll(idx1,:) = MWX.percentKeptIti.Id; idx1 = idx1+1;
PercKeptAll(idx1,:) = MWX.percentKeptIti.Em; idx1 = idx1+1;

clearvars -except TSigClustSummStatsTemp TSigClustSummStatsIndividTemp TSigClustChannelCountTemp TSigClustChannelCountTemp PercKeptAll
