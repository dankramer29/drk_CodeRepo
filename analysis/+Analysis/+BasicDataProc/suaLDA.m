function [acc,fracZeroVar] = suaLDA(spk,varargin)
%LDA for single unit activity over time
%   runs an LDA across 2 conditions

%Inputs:
% data formatted as this: spk.cond1{unit}(trials,time) so conditions in one field and then cells of units [nTrials1 x nTime]
% cond1 - the name of the condition as labeled as a field on struct. this
    % accesses the data so need to enter. this is built for
    % congruent/incongruent data so that is the default
% cond2 - the name of the other condition.
% plt - toggle on or off if you want to plot
% tt -time vector [500 1000] means 500 before st (below variable) and 1000 after, for plotting, put in as start and end time compared to start, but need to enter start (below variable)
% st -time from the start of the data when the center event occurs (so like 750 if the data starts 750 before the stim on. i.e. put in interval.preStimOn)

%Output:
%acc - the time resolved mean of the folds (currently 5, k below)
%fracZeroVar - the fraction that has no variance and is resolved by doing a
    %psuedolinear descrimination type (generally pretty low, but should not be
    %more than 20% or so

[varargin, cond1]=util.argkeyval('cond1', varargin, 'cong'); %enter what condition you want to compare which will be the name in your fields
[varargin, cond2]=util.argkeyval('cond2', varargin, 'incong'); %enter what condition you want to compare which will be the name in your fields
[varargin, plt]=util.argkeyval('plt', varargin, true); %toggle plotting the decode on and off
[varargin, tt]=util.argkeyval('tt', varargin, []); %time vector [500 1000] means 500 before st (below variable) and 1000 after, for plotting, put in as start and end time compared to start, but need to enter start (below variable)
[varargin, st]=util.argkeyval('st', varargin, []); %time from the start of the data when the center event occurs (so like 750 if the data starts 750 before the stim on. i.e. put in interval.preStimOn)
[varargin, optTitle]=util.argkeyval('optTitle', varargin, 'Image On'); %optional title


flds = fields(spk); %find the fields for whatever conditions you want
cond1 = find(strcmp(flds, 'cong')==1);
cond2 = find(strcmp(flds, 'incong')==1);
if length(cond1)>1 || length(cond2)>1
    warning('multiple conditions match cond1 or cond2')
end

nUnits = size(spk.(flds{cond1}),1); %find number of units

[nTr1, nTime] = size(spk.(flds{cond1}){1});
[nTr2, ~]     = size(spk.(flds{cond2}){1});

labels = [ones(nTr1,1); 2*ones(nTr2,1)];

k = 5;                                  % k-fold CV
cvp = cvpartition(labels,'KFold',k); %~20% test

acc = nan(nTime,1);

for ii = 1:nTime
    % for each time point, get each unit across all trials
    % Build feature matrix: trials x units
    X1 = nan(nTr1, nUnits);
    X2 = nan(nTr2, nUnits);

    for jj = 1:nUnits
        X1(:,jj) = spk.(flds{cond1}){jj,1}(:,ii);
        X2(:,jj) = spk.(flds{cond2}){jj,1}(:,ii);
    end

    X = [X1; X2];

    foldAcc = nan(k,1);

    for fold = 1:k
        trainIdx = training(cvp,fold);
        fracZeroVar(ii,fold) = mean(var(X(trainIdx,:),[],1) == 0); %measure how mny units have no variance (>20% problem)

        testIdx  = test(cvp,fold);

        %z-score using training spk (only)
        mu = mean(X(trainIdx,:),1);
        sd = std(X(trainIdx,:),[],1);
        sd(sd==0) = 1;

        Xz = (X - mu) ./ sd;

        %pseudolinear uses Moore–Penrose pseudoinverse for when a unit has
        %no variance (and therefore makes the matrix singular) 
        % "We used a diagonal/regularized linear discriminant classifier to
        % ensure stable covariance estimation given the limited trial counts and sparse firing."
        lda = fitcdiscr(Xz(trainIdx,:), labels(trainIdx), ...
                'DiscrimType','pseudoLinear');

        % test
        yhat = predict(lda, Xz(testIdx,:)); %predicts which are in which label
        foldAcc(fold) = mean(yhat == labels(testIdx)); %mean of percent that match
    end

    acc(ii) = mean(foldAcc);
end

if plt
    if isempty(tt)
        tt(1) = 0;
        tt(2) = length(acc)-1;
    end
    if isempty(st)
        st=1;
    end
    ttt = -tt(1):tt(2)-1;
    ttidx(1) = st-tt(1);
    ttidx(2) = st+tt(2);

    figure;
    set(0, 'DefaultAxesFontSize', 16)
    plot(ttt, acc(ttidx(1):ttidx(2)-1),'LineWidth',2);
    xlabel('Time',  'FontSize', 18 , 'FontWeight' , 'bold' );
    ylabel('Decoding accuracy', 'FontSize', 18 , 'FontWeight' , 'bold');
    ylim([0 1]);
    xticklabels
    xlim([ttt(1) ttt(end)])
    yline(0.5,'k--');
    title(['Time-resolved LDA decoding ' optTitle], 'FontSize', 18 , 'FontWeight' , 'bold');
end


end