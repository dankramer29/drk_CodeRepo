nUnits = numel(data.cond1);

[nTr1, nTime] = size(data.cond1(1).fr);
[nTr2, ~]     = size(data.cond2(1).fr);
[nTr3, ~]     = size(data.cond3(1).fr);

labels = [ ...
    ones(nTr1,1); ...
    2*ones(nTr2,1); ...
    3*ones(nTr3,1)];

k = 5;
cvp = cvpartition(labels,'KFold',k);

acc = nan(nTime,1);
confMat = zeros(3,3,nTime);   % optional

for t = 1:nTime

    % ----- Build feature matrix -----
    X1 = nan(nTr1, nUnits);
    X2 = nan(nTr2, nUnits);
    X3 = nan(nTr3, nUnits);

    for u = 1:nUnits
        X1(:,u) = data.cond1(u).fr(:,t);
        X2(:,u) = data.cond2(u).fr(:,t);
        X3(:,u) = data.cond3(u).fr(:,t);
    end

    X = [X1; X2; X3];

    foldAcc = nan(k,1);
    foldCM  = zeros(3,3);

    for fold = 1:k
        trainIdx = training(cvp,fold);
        testIdx  = test(cvp,fold);

        % ----- z-score (training data only) -----
        mu = mean(X(trainIdx,:),1);
        sd = std(X(trainIdx,:),[],1);
        sd(sd==0) = 1;
        Xz = (X - mu) ./ sd;

        % ----- Train multiclass LDA -----
        lda = fitcdiscr(Xz(trainIdx,:), labels(trainIdx), ...
                        'DiscrimType','linear');

        % ----- Predict -----
        yhat = predict(lda, Xz(testIdx,:));

        foldAcc(fold) = mean(yhat == labels(testIdx));
        foldCM = foldCM + confusionmat(labels(testIdx), yhat, ...
                                       'Order',[1 2 3]);
    end

    acc(t) = mean(foldAcc);
    confMat(:,:,t) = foldCM ./ sum(foldCM,2);
end

% ----- Plot accuracy -----
figure;
plot(acc,'LineWidth',2);
xlabel('Time');
ylabel('Decoding accuracy');
ylim([0 1]);
yline(1/3,'k--');    % chance for 3 classes
title('3-class LDA decoding over time');
