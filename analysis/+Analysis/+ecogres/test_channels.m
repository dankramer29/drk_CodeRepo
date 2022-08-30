patients = ecogres.defPatients;
grids = ecogres.defGrids;
datadir = 'C:\Users\Spencer\Documents\Data\Keck\';

%% RAMIREZ
tm = [0 1000];
ch = 1:127;
blc = BLc.Reader(fullfile(datadir,'Ramirez Fernando_4116_Ph2D2\RAMIREZ~ FERNA_d1bc9c28-1bc2-47c1-b536-63c3fe82ff07_export002.blx'));
plot.chunk(blc,tm,ch);


%% MILLER
tm = [3350 4350];
ch = 1:96;
blc = BLc.Reader(fullfile(datadir,'Miller Bridget_61716_Ph2D2\MILLER~ BRIDGE_a4675b97-fb82-432a-9ce4-2c0b2dc808cb_export005.blx'));
plot.chunk(blc,tm,ch);


%% BERNAL
tm = [16000 17000];
ch = 1:84;
blc = BLc.Reader(fullfile(datadir,'Bernal Jennifer_11916_Ph2D2\BERNAL~ JENNIF_d651436c-1a43-4e6d-9c24-0ca0eca0fccb_export002.blx'));
plot.chunk(blc,tm,ch);


%% VLAHOS
tm = [1200 2200];
ch = 1:48;
blc = BLc.Reader(fullfile(datadir,'vlahos - 2 years old macro stim\VLAHOS~ ATHANA_ec3d19ef-72cb-449a-be08-56ccfb1604b5\VLAHOS~ ATHANA_ec3d19ef-72cb-449a-be08-56ccfb1604b5_export_130912.blx'));
plot.chunk(blc,tm,ch);