function [TestData, TestDataTimes, TrialTargetNumbers] = fakeSignal(varargin);

    
    [varargin, LeadUpTime] = util.argkeyval('LeadUpTime', varargin, 3); % ITI, Fix, Cue time
    [varargin, ActionTime] = util.argkeyval('ActionTime', varargin, 3); % Increased activity after cue, during delay and respond
    [varargin, SampleFrequency] = util.argkeyval('SampleFrequency', varargin, 2000);
    [varargin, Targets] = util.argkeyval('Targets', varargin, 8);
    [varargin, TrialsPerTarget] = util.argkeyval('TrialsPerTarget', varargin, 5);
    [varargin, ChannelsPerGroup] = util.argkeyval('LeadUpTime', varargin, 3);
    
    % make sure no orphan input arguments
    util.argempty(varargin);

    LowFreq = 7;
    HighFreq = 130;
    TargetRange = 1:Targets;

    
    %Call Functions with Parameters given
    TrialTargetNumbers = targetNumbers(TargetRange, TrialsPerTarget);

    [NonTunedData, TestDataTimes] = nonTunedChannels(ChannelsPerGroup, TrialTargetNumbers, LeadUpTime, ActionTime, SampleFrequency, LowFreq, HighFreq);

    [TunedData7, ~] = tunedChannels(ChannelsPerGroup, TrialTargetNumbers, 7, LeadUpTime, ActionTime, SampleFrequency, LowFreq, HighFreq);

    [NonTunedData2, ~] = nonTunedChannels(ChannelsPerGroup, TrialTargetNumbers, LeadUpTime, ActionTime, SampleFrequency, LowFreq, HighFreq);

    [TunedData3, ~] = tunedChannels(ChannelsPerGroup, TrialTargetNumbers, 3, LeadUpTime, ActionTime, SampleFrequency, LowFreq, HighFreq);

    
    %Combine generated data arrays to resemble actual data array
    % TimeXChannels
    MaxLength = size(NonTunedData,1);
    TunedData7 = TunedData7(1:MaxLength,:,:);
    TunedData3 = TunedData3(1:MaxLength,:,:);
    TestData = [NonTunedData TunedData7 NonTunedData2 TunedData3];


    function N = targetNumbers(TargetRange, TrialsPerTarget)
        TR = max(TargetRange);
        N = zeros(TR * TrialsPerTarget, 1);
        s = 1;
        e = TR;
        for i = 1:TrialsPerTarget
            N(s:e,1) = randperm(TR,TR);
            s = s + TR;
            e = e + TR;
        end
    end

    function [NonTunedData, TrialSampleTime] = nonTunedChannels(NumberOfChannels, TrialTargetNumbers, LeadUpTime, ActionTime, SampleFrequency, LowFreq, HighFreq)
        TrialDuration = LeadUpTime + ActionTime;
        TrialSampleTime = 0:1/SampleFrequency:TrialDuration;
        %TaskSampleTime = size(TrialSampleTime,2) * length(TrialTargetNumbers);
        NonTunedData = zeros(length(TrialSampleTime), NumberOfChannels, length(TrialTargetNumbers));
        for Ch = 1:NumberOfChannels
            rng('shuffle');
            for Tr = 1:length(TrialTargetNumbers)
                Rand1 = (2 * rand(1,size(TrialSampleTime,2))) -1;
                LowSignal = sin(2*pi*LowFreq*TrialSampleTime);
                HighSignal = (0.7)*sin(2*pi*HighFreq*TrialSampleTime);
                TrialSignal = (LowSignal + HighSignal) + Rand1;
                NonTunedData(:,Ch,Tr) = TrialSignal;
            end % Trial Loop
        end % Channel Loop
    end % End Function

    function [TunedData, TrialSampleTime] = tunedChannels(NumberOfChannels, TrialTargetNumbers, TargetTuned, LeadUpTime, ActionTime, SampleFrequency, LowFreq, HighFreq)
        TrialDuration = LeadUpTime + ActionTime;
        TrialSampleTime = 0:1/SampleFrequency:TrialDuration;
        %TaskSampleTime = size(TrialSampleTime,2) * length(TrialTargetNumbers);
        TunedData = zeros(length(TrialSampleTime), NumberOfChannels, length(TrialTargetNumbers));
        for Ch = 1:NumberOfChannels
            rng('shuffle');
            for Tr = 1:length(TrialTargetNumbers)
                Rand1 = (2 * rand(1,size(TrialSampleTime,2))) -1;
                LowSignal = sin(2*pi*LowFreq*TrialSampleTime);
                HighSignal = (0.7)*sin(2*pi*HighFreq*TrialSampleTime);
                TrialSignal = (LowSignal + HighSignal) + Rand1;
                if TrialTargetNumbers(Tr,1) == TargetTuned
                    TrialOffset = ((TrialDuration-ActionTime) * SampleFrequency); %How far into this trial should the data change?
                    NSignalSamples = TrialSampleTime(TrialOffset:end);
                    NRand1 = (2 * rand(1,size(NSignalSamples,2))) -1;
                    NLowSignal = 1.15 * sin(2 * pi * LowFreq * NSignalSamples);
                    NHighSignal = 1.02 * sin(2 * pi * HighFreq * NSignalSamples);
                    NTrialSignal = (NLowSignal + NHighSignal) + NRand1;
                    TrialSignal(1,TrialOffset:end) = NTrialSignal(1,:);
                end % end different signal tuning targets
                TunedData(:,Ch,Tr) = TrialSignal;
            end % Trial loop
        end % Channel Loop 
    end % End Function

end % end fakeSignal Function