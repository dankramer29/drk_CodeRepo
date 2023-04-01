[bandfilterAmp, bandfilterPhase] = Analysis.PAC.bandfiltersAP(fs, 'AmpFreq_Bandwidth', 2, 'MaxAmpFreq',...
    100, 'MinAmpFreq', 10, 'MaxPhaseFreq', 30, 'MinPhaseFreq', 1, 'nerdcoPACFilter', true);
bandFilter.bandfilterAmp = bandfilterAmp;
bandFilter.bandfilterPhase = bandfilterPhase;


%take a chunk of data 3 seconds long
dataTest = preStartData(behavioralIndexImageOn(2):behavioralIndexImageOn(2)+(500*3),1);
%needs 60 hz filtering
notchFilt60 = designfilt('bandstopiir','FilterOrder',2, ...
        'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
        'SampleRate',fs,'DesignMethod','butter');

dataTest = filtfilt(notchFilt60, dataTest);

%create fake data
signal = Analysis.SampleData.PACsampleData(1:100, 20, 70, 'data', dataTest);

%try PAC
Analysis.PAC.nerdcoPAC(signal, signal, 'fs', 500, 'epochLength', 3, 'bandFilter', bandFilter);
