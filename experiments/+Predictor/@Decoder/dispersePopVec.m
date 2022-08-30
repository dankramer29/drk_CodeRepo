function newH=dispersePopVec(obj,origH)

options = optimoptions('fmincon','Algorithm','active-set','Display','off');

normH=Utilities.mnorm(origH);

funcObjective= @(x) redistributeCostFunction(x,origH);
funcCont=@(x) redistributeConstraintFunction(x,normH);

for i=1:100;
    % H=H+.5*repmat(mnorm(H),1,2).*randn(size(H));
    Htmp=origH+mean(normH)*randn(size(origH));
    Htmp=Htmp./repmat(Utilities.mnorm(Htmp),1,2).*repmat(normH,1,2);
    [Htest{i},fval(i)] = fmincon(funcObjective,Htmp,[],[],[],[],[],[],funcCont,options);
end
[minVal,INDX]=min(fval);
newH=Htest{INDX};

function [tmp,eqc]=redistributeConstraintFunction(H,normH)

tmp=0;
% constraint
eqc=sum((Utilities.mnorm(H)-normH).^2);

function D=redistributeCostFunction(H,origH)

% cost1
% things shouldn't change
% cost1=sum(mnorm((NewVal-InitVal)./se))

% cost 2
D = sum(1./pdist(H,'euclidean').^2) + sum(Utilities.mnorm((H-origH)).^2);
% D = acos(1-pdist(H,'cosine'))*180/pi