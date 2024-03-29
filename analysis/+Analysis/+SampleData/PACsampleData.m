function [signalfinal, fsS, timeTotal] = PACsampleData(freqRange, lowFreq, highFreq, varargin)

%Creates sample Phase Amplitude Coupling data.
% 
% Inputs:
%     freqRange= [startingfreq endfreq] typically 1 200 will work
%     lowFreq= the low frequency you want to couple, can be a band
%     highFreq= the high frequency you want to couple, can be a band
% Outputs 
%    signalfinal= the output of a single signal with noise built in,
% and coupling of the two frequencies
% 
% couples by multiplying the higher frequency by increasing factors during
% only the up phase of the lower frequency

%to create sample data form this for ucsfPAC, run this:
%{
for kk=1:8
    for jj=1:9
        signal(:,jj,kk)=Analysis.SampleData.PACsampleData(1:200, 20, 70);
    end
end
%}
[varargin, data] = util.argkeyval('data',varargin, []); % option to add in a known signal
[varargin, fs] = util.argkeyval('fs',varargin, 500); % fs


%TO DO, MAKE IT SO YOU CAN SEE A BAND OF FREQUENCIES
% FIRST THING, RUN A SPECTROGRAM TO SEE IF THIS FAKE ADDED SIGNAL IS REALLY
% A SIGNAL. THEN TAKE A REAL SIGNAL AND ADD THIS PAC SIGNAL TO IT.
addPACtoSignal=true;
completelyFakeSignal=false;
if isempty(data)
    error('need to add data as varargin')
end


combined=true;

plotOn=true; %turn to true if you want to plot the fake data

fsS=1/fs; %sampling rate
T=3; %lenth of recording time, in seconds
timeTotal=T;
t=0:fsS:T; %x input, i.e. the points

%how much to divide the amplitude of the noise by, so that it's not a crazy
%amount, if 2, you are dividing the amplitude of the noise by half the
%amplitude of that frequency
noiseFactor=2; 
%% this allows adding of a PAC to a known signal so the signal is real and infinite
if addPACtoSignal %adds a pac to a known signal
    if size(data,1) > size (data,2)
        data = data';
    end
    mx = max(data);
    AmpBase=mx*.1; %the amplitude range you want
    %signalfinal=zeros(1,length(t));
    idx1=1;
%     for ii=1:length(f)
%         clear ampF, clear xx, clear zz, clear signalfreq, clear noise,
        ii=lowFreq;
        phse=0;      
        Amp=AmpBase*1/ii; %amplitude, 1/f        
        noise=Amp/noiseFactor*(rand(1,length(t)));
        Af1 = lowFreq-5;
        Af2 = lowFreq+5;
        bandFilt1 = designfilt('bandpassfir','FilterOrder',100,'CutoffFrequency1',Af1,'CutoffFrequency2',Af2, 'SampleRate',fs);
        dataLow = filtfilt(bandFilt1, data);
        signalfreq=Amp*dataLow;
        signalfreq=Amp*sin(2*pi*ii*t+phse);
        signalfreq=signalfreq+noise; %add the noise
        
        signalfinal=data+signalfreq;
       
        jj=highFreq;

        phse=0;
        halfphase=0:fsS:1/(lowFreq(idx1)*2)-fsS; %create time points for half the phase of the lower freq
        xx=sin(2*pi*lowFreq(idx1)*halfphase); %make a sin wave for half the phase
        zz=zeros(1,length(halfphase)); %make ones for the other half
        xx=[xx zz]; %combine them
        ampF=repmat(xx,1,lowFreq(idx1)*T); %make this the length of the time series
        dif=length(t)-length(ampF); %whatever is short from the length, add zeros, (e.g. 21 Hz isn't divisible into 2000 samples/sec)
        ampF=[ampF zeros(1,dif)];
        ampF=ampF+1; %add 1 so that this becomes a multiplication factor to amplify only the in phase stuff
        Amp = AmpBase*1/jj;
        Af1 = highFreq-5;
        Af2 = highFreq+5;
        bandFilt2 = designfilt('bandpassfir','FilterOrder',100,'CutoffFrequency1',Af1,'CutoffFrequency2',Af2, 'SampleRate',fs);
        dataHigh = filtfilt(bandFilt2, data);
        signalfreq=Amp*dataHigh;
        signalfreq=signalfreq+noise; %add the noise
        signalfreq=signalfreq.*ampF;
        %signalPh(:,idx1)=signalfreq;
        signalfinal=signalfinal+signalfreq;

        idx1=idx1+1;

        if plotOn
            figure
            hold on
            plot(t,signalfinal)
            plot(t,data)
        end
end





%% Make a fake random signal, however, probably don't use due to:
% CONCERN THAT THE SIGNAL IS NOT INFINITE SINCE STITCHED TOGETHER

%frequency of your signal
%complex signal,builds a signal from your low to high frequencies, starting
%at 1Hz
if completelyFakeSignal
    %% SET FREQUENCY PARAMETERS
    f=freqRange; %can also make independent fs, e.g. f=[20 80]
    AmpBase=0.25; %the amplitude range you want
    signalfinal=zeros(1,length(t));
    idx1=1;
    for ii=1:length(f)
        clear ampF, clear xx, clear zz, clear signalfreq, clear noise,
        f(ii)=ii;
        %     if ii==1 || ii==2 || ii==3
        %         Amp(ii)=AmpBase*.1;
        %     else
        Amp(ii)=AmpBase*(1/f(ii)); %amplitude, 1/f
        %     end
        noise=Amp(ii)/noiseFactor*(rand(1,length(t)));
        phse=randi(360);

        if ismember(ii,lowFreq)
            phse=0;
        end
        if ismember(ii,highFreq)

            phse=0;
            halfphase=0:fsS:1/(lowFreq(idx1)*2)-fsS; %create time points for half the phase of the lower freq
            xx=sin(2*pi*lowFreq(idx1)*halfphase); %make a sin wave for half the phase
            zz=zeros(1,length(halfphase)); %make ones for the other half
            xx=[xx zz]; %combine them
            ampF=repmat(xx,1,lowFreq(idx1)*T); %make this the length of the time series
            dif=length(t)-length(ampF); %whatever is short from the length, add zeros, (e.g. 21 Hz isn't divisible into 2000 samples/sec)
            ampF=[ampF zeros(1,dif)];
            ampF=ampF+1; %add 1 so that this becomes a multiplication factor to amplify only the in phase stuff

            signalfreq=Amp(ii)*sin(2*pi*f(ii)*t+phse);
            signalfreq=signalfreq+noise; %add the noise
            signalfreq=signalfreq.*ampF;
            signalPh(:,idx1)=signalfreq;
            idx1=idx1+1;

        else
            signalfreq=Amp(ii)*sin(2*pi*f(ii)*t+phse);
            signalfreq=signalfreq+noise; %add the noise
        end


        signalfinal=signalfinal+signalfreq;
    end



    %%
    if plotOn
        figure
        hold on
        plot(t,signalfinal)
    end

end
