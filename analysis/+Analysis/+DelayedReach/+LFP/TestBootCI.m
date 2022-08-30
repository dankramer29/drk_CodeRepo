% ph = 5; fr = 5; ta = 8;
% TargLog = Targets == ta;
% TestPowerArray = PowerArray(PhaseLog(:,ph),FreqLog(fr,:),:,TargLog);
% TestPowerArray = permute(TestPowerArray, [3 1 2 4]); %76x56x246x6; Ch x
%  %phasetime x Freqbins x trialsfortarget
% TestPA = TestPowerArray(:,:);
% TestPA = TestPA'; %82656 x 76
% CI = zeros(2,76);
% BootStats = zeros(1000,76);
% parfor ch = 1:76
%     [CI, BS] = bootci(1000, @mean, TestPA(:,ch));
%     TestCI(:,ch) = CI;
%     TestBootStat(:,ch) = BS;
% end
% 

%%
% WORRRRRRRKS about 12.8s per loop (25.5863 min for 120 loops)
% 11.2s per loop on crunch (37.39 min for 200 loops)
Fs = size(FreqLog, 1);
Phs = size(PhaseLog, 2);
Ts = 8;


%When all else fails convert the body of of the parfor-loop into a function
MeanArray = zeros(76, Phs, Fs, Ts);
CIArray = zeros(76, 2, Phs, Fs, Ts);

parfor ph = 1:size(PhaseLog, 2)
    PermedPArray = permute(PowerArray, [3 1 2 4]);
    MA = zeros(76, Fs, Ts);
    CIA = zeros(76, 2, Fs, Ts);
    for fr = 1:size(FreqLog, 1)
        for ta = 1:8
            TargLog = Targets == ta;
            SubPowerArray = PermedPArray(:, PhaseLog(:,ph), FreqLog(fr,:), TargLog);
%             SubPowerArray = permute(SubPowerArray, [3 1 2 4]);
            SubPA = SubPowerArray(:,:);
            SubPA = SubPA';
            [OutputMean, OutputCI] = Analysis.DelayedReach.LFP.bootMeanCI(SubPA, 1000);
            MA(:,fr,ta) = OutputMean';
            CIA(:,:,fr,ta) = OutputCI';
        end
    end
    MeanArray(:,ph,:,:) = MA;
    CIArray(:,:,ph,:,:) = CIA;
end
% WORRRRRRRKS
%%

% ThetaLogical  = FreqBins > 4  & FreqBins < 8;
% AlphaLogical  = FreqBins > 8  & FreqBins < 12;
% BetaLogical   = FreqBins > 12 & FreqBins < 30;
% LGammaLogical = FreqBins > 30 & FreqBins < 80;
% HGammaLogical = FreqBins > 80 & FreqBins < 200;
% 
% ITILogical = TimeBins > 0   & TimeBins < 2.0;
% FixLogical = TimeBins > 2.0 & TimeBins < 4.0;
% CueLogical = TimeBins > 4.0 & TimeBins < 5.0;
% DelLogical = TimeBins > 5.0 & TimeBins < 6.0;
% ActLogical = TimeBins > 6.0;
% 
% FreqLog = [ThetaLogical; AlphaLogical; BetaLogical; LGammaLogical; HGammaLogical];
% PhaseLog = [ITILogical FixLogical CueLogical DelLogical ActLogical];
% 
% PA = zeros(size(PowerArray,3),5,5,8); % Ch x FreqBins x Phases x TargetLocation
% PowerRanges = zeros(size(PA,1),size(PA,2),2); % Ch x FreqBin x Min or Max
% 
% for ch = 1:size(PowerArray,3)
%     for fr = 1:size(FreqLog, 1)
%         for ph = 1:size(PhaseLog, 2)
%             for ta = 1:8
%                 TargLog = Targets == ta;
%                 A = squeeze(PowerArray(PhaseLog(:,ph), FreqLog(fr,:), ch, TargLog)); 
%                 mA = mean(A,3);
%                 mmA = mean(mA,2);
%                 mmmA = mean(mmA);
%                 PA(ch,fr,ph,ta) = mmmA;
%                 %PA(ch,fr,ph,ta) = 10*log10(mmmA);
%             end
%         end
%         MinVal = floor(min(min(PA(ch,fr,:,:),[],4)));
%         PowerRanges(ch,fr,1) = 10*log10(MinVal);
%         %PowerRanges(ch,fr,1) = floor(min(min(PA(ch,fr,:,:),[],4))); 
%         MaxVal = ceil(max(max(PA(ch,fr,:,:),[],4)));
%         PowerRanges(ch,fr,2) = 10*log10(MaxVal);
%         %PowerRanges(ch,fr,2) = ceil(max(max(PA(ch,fr,:,:),[],4)));
%     end
% end