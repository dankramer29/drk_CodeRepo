function [acc,fracZeroVar] = suaLDA(spk1, spk2, varargin)
%LDA for single unit activity over time
%   runs an LDA across 2 conditions

%Inputs:
% data formatted as this: spk1{unit}(trials,time) so the cells of units [nTrials1 x nTime]
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

[varargin, spk3]=util.argkeyval('spk3', varargin, []); %enter a third set of data if you want (and expand from there if you want)

[varargin, plt]=util.argkeyval('plt', varargin, true); %toggle plotting the decode on and off
[varargin, tt]=util.argkeyval('tt', varargin, []); %time vector [-500 1000] means 500 before st (below variable) and 1000 after, for plotting, put in as start and end time compared to start, but need to enter start (below variable)
[varargin, st]=util.argkeyval('st', varargin, []); %time from the start of the data when the center event occurs (so like 750 if the data starts 750 before the stim on. i.e. put in interval.preStimOn)
[varargin, myTitle]=util.argkeyval('myTitle', varargin, 'Image On Congruent v Incongruent'); %optional title


%TO DO NEED TO FIX THIS BECAUSE THE LABELS ARE ACTUALLY
%CONGRUENT/INCONGRUENT AND THEN THE CELLS ARE THE RESPONSES. JUST SET IT UP
%AS TWO DIFFERENT TYPES OF RUN, AND DO THE CODE AGAIN BELOW OR GET THE DATA
%INTO A SINGLE FORMAT.

% flds = fields(spk); %find the fields for whatever conditions you want
% cond1t = find(strcmp(flds, cond1)==1);
% cond2t = find(strcmp(flds, cond2)==1);
% if ~isempty(cond3)
%     cond3t = find(strcmp(flds, cond3)==1);
% end
% if length(cond1t)>1 || length(cond2t)>1
%     warning('multiple conditions match cond1 or cond2')
% end

nUnits = size(spk1,1); %find number of units

[nTr1, nTime] = size(spk1{1});
[nTr2, ~]     = size(spk2{1});
if ~isempty(spk3)
    [nTr3, ~]     = size(spk3{1});
    labels = [ones(nTr1,1); 2*ones(nTr2,1); 3*ones(nTr3,1)];
    confMat = zeros(3,3,nTime);   % optional
else
    labels = [ones(nTr1,1); 2*ones(nTr2,1)];
end

k = 5;                                  % k-fold CV
cvp = cvpartition(labels,'KFold',k); %~20% test

acc = nan(nTime,1);

for ii = 1:nTime
    % for each time point, get each unit across all trials
    % Build feature matrix: trials x units
    X1 = nan(nTr1, nUnits);
    X2 = nan(nTr2, nUnits);
    if ~isempty(spk3)
        X3 = nan(nTr3, nUnits);
    end

    for jj = 1:nUnits        
        X1(:,jj) = spk1{jj,1}(:,ii);
        X2(:,jj) = spk2{jj,1}(:,ii);
        if ~isempty(spk3) 
            X1(:,jj) = spk1{jj,1}(:,ii);
            X2(:,jj) = spk2{jj,1}(:,ii);
            X3(:,jj) = spk3{jj,1}(:,ii);        
        end
    end

    X = [X1; X2];
    if ~isempty(spk3)
        X = [X1; X2; X3];
    end

    foldAcc = nan(k,1);
    foldCM  = zeros(3,3);


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
        if ~isempty(spk3)
            foldCM = foldCM + confusionmat(labels(testIdx), yhat, ...
                'Order',[1 2 3]);
        end
    end

    acc(ii) = mean(foldAcc);
    if ~isempty(spk3)
            confMat(:,:,ii) = foldCM ./ sum(foldCM,2);
    end
end

if plt %TO DO IS UPDATE THE PLOTTING FOR 3
    if isempty(tt)
        tt(1) = 0;
        tt(2) = length(acc)-1;
    end
    if isempty(st)
        st=1;
    end
    ttt = tt(1):tt(2)-1;
    ttidx(1) = st+tt(1);
    ttidx(2) = st+tt(2);

    figure;
    set(0, 'DefaultAxesFontSize', 14)
    plot(ttt, acc(ttidx(1)+1:ttidx(2)),'LineWidth',2);
    xlabel('Time',  'FontSize', 18 , 'FontWeight' , 'bold' );
    ylabel('Decoding accuracy', 'FontSize', 18 , 'FontWeight' , 'bold');
    ylim([0 1]);
    xlim([ttt(1) ttt(end)]);
    if isempty(spk3)
        yline(0.5,'k--');
    else
        yline(1/3, 'k--');
    end
    title(['LDA decoding ', newline, myTitle], 'FontSize', 14 , 'FontWeight' , 'bold');
end


end