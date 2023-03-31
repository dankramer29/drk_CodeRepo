%% load

cd('C:\Users\Admin\Downloads')
load('F211001-0003.mat')
%%

dbs0 = double(CDBS_0);
dbs1 = double(CDBS_1);


                    tmpLFPtab = array2table(tmpLFParray);
                    tmpLFPtab.Properties.VariableNames = chanTabLabs_LFP{1};
                    app.lfpTTraw = table2timetable(tmpLFPtab,'SampleRate',app.lfpMODsf);
                    
 lfpTTppDs = retime(lfpTTppSm,'regular','mean','SampleRate',250);
 tmpLFPnotch = spectrumInterpolation(tmpLFPraw, app.lfpMODsf, 60, 3, 1);

%%

dbs0dn = downsample(dbs0,3);

%%

fs = 300;

figure
subplot(2,1,1);
pspectrum(normal,fs,'spectrogram','TimeResolution',0.5)
title('Normal Signal')

subplot(2,1,2);
pspectrum(aFib,fs,'spectrogram','TimeResolution',0.5)
title('AFib Signal')