%TO FIND CHANNEL NAMES, MAKE SURE YOU USE THE BLC FILE CHANNEL INFO AND NOT
%THE MAPFILE 


mapBM=GridMap('\\striatum\Data\neural\working\Real Touch\P008_realtouch\P08_Research_62218_RealTouch_map.csv');
blcBM=BLc.Reader('\\striatum\Data\neural\working\Real Touch\P008_realtouch\P08_Research_62218_RealTouch-000.blc');
dataBM=blcBM.read;

% mapJR=GridMap('\\STRIATUM\Data\neural\incoming\unsorted\rancho\RANGEL_JORGE@20161021_000003\Patient5_DC1824300_t2.segment12.map');
% blcJR=BLc.Reader('\\STRIATUM\Data\neural\incoming\unsorted\rancho\RANGEL_JORGE@20161021_000003\Patient5_DC1824300_t2-segment12.blc');
% %fix the days for this patient
% newStartTime=[15 20 30 000];
% newEndTime=[22 01 01 001];
% [OriginTimeJR, newStartEnd_s, recDaySt, recDayEnd] = Analysis.ArtSens.timeAdjust(blcJR, newStartTime, 'recordingDay', 2, 'endTime', newEndTime);
% dataJR=blcJR.read('time', [newStartEnd_s(1) newStartEnd_s(2)]);

% mapEG=GridMap('\\striatum\Data\neural\incoming\unsorted\rancho\GAYTAN_ELISA@20160919_000003\Patient5_DC1824300_t7.segment2.map');
% blcEG=BLc.Reader('\\striatum\Data\neural\incoming\unsorted\rancho\GAYTAN_ELISA@20160919_000003\Patient5_DC1824300_t7-segment2-000.blc');
% dataEG=blcEG.read
% 
% mapJO=GridMap('\\STRIATUM\Data\neural\working\Real Touch\P012_realtouch\P012\P012_101817_Real_touch2_map.csv');
% blcJO=BLc.Reader('\\STRIATUM\Data\neural\working\Real Touch\P012_realtouch\P012\P012_101817_Real_touch2-000.blc');
% dataJO=blcJO.read;

% mapCG=GridMap('\\STRIATUM\Data\neural\working\CG_62716_RealTouch\Patient4_DC1824300_t5.segment01.map');
% blcCG=BLc.Reader('\\STRIATUM\Data\neural\working\CG_62716_RealTouch\Patient4_DC1824300_t5-segment01.blc');
% dataCG=blcCG.read;


% filtbandpower=struct;
% filtbandpowerdB=struct;
 [ this.bm] = Analysis.ArtSens.artsens_proc( blcBM, 'ch', [86 96], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataBM, 'quickrun', false);

%[ this.bm, ~, ~, ~, filtbandPower.bm, filtbandPowerdB.bm, ~, filtITIBM ] = Analysis.ArtSens.artsens_proc( blcBM, 'ch', [86 96], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataBM, 'quickrun', false);
%[ ~, specPowerBM5, specgramcBM5, elec_pBM5 ] = Analysis.ArtSens.artsens_proc( blcBM, 'ch', [33 96], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.5 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataBM, 'quickrun', true);



%[ ~, ~, ~, ~, filtbandPower.jr, filtbandPowerdB.jr, itiCheckResultsJR, filtITIBMJR ] = Analysis.ArtSens.artsens_proc( blcJR, 'ch', [70 75], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataJR, 'quickrun', false, 'OriginTime', OriginTimeJR);
%[ ~, specPowerJR5, specgramcJR5, elec_pJR5 ] = Analysis.ArtSens.artsens_proc( blcJR, 'ch', [71 75], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.5 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataJR, 'quickrun', false, 'OriginTime', OriginTimeJR);
%54 117

%[ this.eg, ~, ~, ~, filtbandPower.eg, filtbandPowerdB.eg, ~, filtITIEG ] = Analysis.ArtSens.artsens_proc( blcEG, 'ch', [1 64], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataEG, 'quickrun', true);
% %[ thisEG5, specPowerEG5, specgramcEG5, elec_pEG5 ] = Analysis.ArtSens.artsens_proc( blcEG, 'ch', [1 64], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.5 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataEG, 'quickrun', true);
 
% [ this.JO, ~, ~, ~, filtbandPower.jo, filtbandPowerdB.jo,~, filtITIBMJO ] = Analysis.ArtSens.artsens_proc( blcJO, 'ch', [1 20], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'data', dataJO, 'quickrun', false);
% %[ thisJO5, specPowerJO5, specgramcJO5, elec_pJO5 ] = Analysis.ArtSens.artsens_proc( blcJO, 'ch', [1 20], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.5 0.005], 'data', dataJO, 'quickrun', true);

%this subject ended up not having anything somatosensory
%[ thisCG2, specPowerCG2, specgramcCG2, elec_pCG2 ] = Analysis.ArtSens.artsens_proc( blcCG, 'ch', [49 112], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'data', dataCG, 'quickrun', true);
%%[ thisCG5, specPowerCG5, specgramcCG5, elec_pCG5 ] = Analysis.ArtSens.artsens_proc( blcCG, 'ch', [49 112], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.5 0.005], 'data', dataCG, 'quickrun', true);

%To get just the raw data, comment out the freqbandpower part of the
%artsens_proc and run these
%[ this.bm] = Analysis.ArtSens.artsens_proc( blcBM, 'ch', [33 96], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataBM, 'quickrun', true);
%[ this.jr] = Analysis.ArtSens.artsens_proc( blcJR, 'ch', [54 117], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataJR, 'quickrun', true, 'OriginTime', OriginTimeJR);
%[ this.eg] = Analysis.ArtSens.artsens_proc( blcEG, 'ch', [1 64], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'gridtype', 1, 'orientation',  1, 'data', dataEG, 'quickrun', true);
% [ this.jo] = Analysis.ArtSens.artsens_proc( blcJO, 'ch', [1 20], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005], 'data', dataJO, 'quickrun', true);
