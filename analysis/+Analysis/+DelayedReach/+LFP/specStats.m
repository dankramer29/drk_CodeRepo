function [StatArray, varargout] = specStats(SpectrogramArray, varargin)
    % [PValues, SigCount] = specStats(SpectrogramArray, Targets)
    % Process anovas of the spectrogram for each location combination for each
    % channel. Returns PValues, an array = TimeBins x FreqBins x Channels x 28
    % which is the # of unique combinations of 2 locations. 
    % Currently takes ~ 30 minutes on 159x52x76x55 double 
    % 
    % Required: 
    %     - SpectrogramArray: Time x Freq x Channels x Trials
    % Mode Requirements:
    %     ('Mode', 'PValues', 'Targets', TargetArray)
    %     - TargetArray: Vector that contains targets matching Trials dimension
    %       in SpectrogramArray. 
    %     ('Mode', 'BootCI', 'Dimension', Dimension#)
    %     - Dimension#: Dimension number to compute boostrapped average and
    %     CI of. 
    %     - Optional: ('BootNum', BootStrap#). Number of bootstrapped
    %     samples to generate. Default = 1000.

    [varargin, Mode, ~, Found] = util.argkeyval('Mode', varargin, '');
    if ~Found
        Mode = input('Must specify stats mode, PValues, BootCI, etc', 's');
    end
    
    switch Mode
        case 'PValues'
            [varargin, Targets, ~, TFound] = util.argkeyval('Targets', varargin, []);
            assert(TFound == 1, 'Must provide Targets vector for p-value computation')
            [StatArray, SigCount] = pValues(SpectrogramArray, Targets);
            varargout{1} = SigCount;
        case 'BootCI'
            [varargin, Dimension, ~, DFound] = util.argkeyval('Dimension', varargin, []);
            if ~DFound
                Dimension = input('Input dimension # to compute bootci stats: ');
            end
            [varargin, BootNum] = util.argkeyval('BootNum', varargin, 1000);
            StatArray = bootCIStats(SpectrogramArray, Dimension, BootNum);

    end
    
    util.argempty(varargin);
    
    function [PValues, SigCount] = pValues(SpectrogramArray, Targets)
        % Get dimensions for iteration
        NumTBin = size(SpectrogramArray, 1);
        NumFBin = size(SpectrogramArray, 2);
        NumChan = size(SpectrogramArray, 3);
        NumTrs  = size(SpectrogramArray, 4);

        % Check that Target input matches Spectrogram input
        assert(NumTrs == max(size(Targets)), 'Target vector not the same size as Trial dimension of Spectrogram')
        assert(min(size(Targets)) == 1 && length(size(Targets)) == 2, 'Target input not a vector')


        %--- Statistical calculation loop

        % pre allocate
        PVal = zeros(28, NumTBin, NumFBin, NumChan); % 28 = permutation of 8 target location comparisons
        SpecsPermute = permute(SpectrogramArray, [4 1 2 3]); %trials x time x freq x ch

        % Loop over every time bin, frequency bin and channel. The Comparison Table
        % output by multcompare gives the group combinations and corresponding
        % confidence intervals, means, and p values. Only the p values are
        % collected. 
        parfor t = 1:NumTBin
            for f = 1:NumFBin
                 for c = 1:NumChan
                    [~, ~, AnovaStats] = anova1(SpecsPermute(:,t,f,c), Targets, 'off');
                    CompTable = multcompare(AnovaStats, 'Display', 'off');
                    PVal(:,t,f,c) = CompTable(:,6);
                end % end channel loop
            end % end frequency bins loop
        end % end time bins loop

        PValues = permute(PVal, [2 3 4 1]);


        %--- Count significant p values

        CompRows = size(PValues, 4); %Rows in the comparison table from multcompare above

        % table with a value for each Channel comparison across all time and frequencies specified
        SigCount = zeros(CompRows, NumChan);

        for Ch = 1:NumChan
            for Row = 1:CompRows
                SigCount(Row, Ch) = size(find(PValues(:,:,Ch,Row) < 0.05), 1);
            end
        end

        end %end PValues function
    
    function BootCIStats = bootCIStats(SpectrogramArray, Dimension, BootNum)
        %bootstrap average and confidence intervals of the 20 samples for each
        %channel
        % spectrogramarray = n x m x l 
        if Dimension == 2
            OutDim = 3;
        elseif Dimension ==3
            OutDim = 2;
        end
        fprintf('computing bootstrap CI\n')
        DimSize = size(SpectrogramArray, OutDim);
        MeanCells = cell(1, DimSize); %keep Channels as column dimension
        CICells  = cell(1, DimSize);
        BootCIStats = cell(2, DimSize);

        if Dimension == 3
            parfor i = 1:DimSize
                SA = squeeze(SpectrogramArray(:, i, :)); % n x l
                SA = SA'; % mean defaults to 1st dim, need mean across l
                [CI, BSMeans] = bootci(BootNum, @mean, SA); % CI 2xn, BSMeans = BootNum x n
                MMean = mean(BSMeans); % MMean 1 x n
                MeanCells(1,i) = {MMean};
                CICells(1,i) = {CI};
            end
            BootCIStats(1,:) = MeanCells;
            BootCIStats(2,:) = CICells; %2 x DimSize cell

        elseif Dimension == 2
            parfor i = 1:DimSize
                SA = squeeze(SpectrogramArray(:, :, i)); % n x m
                SA = SA'; % mean defaults to 1st dim, need mean across m
                [CI, BSMeans] = bootci(BootNum, @mean, SA); % CI 2xn, BSMeans = BootNum x n
                MMean = mean(BSMeans); % MMean 1 x n
                MeanCells(1,i) = {MMean};
                CICells(1,i) = {CI};
            end
            BootCIStats(1,:) = MeanCells;
            BootCIStats(2,:) = CICells; %2 x DimSize cell
        end
    end %end bootCIStats function
    


end % End Function
