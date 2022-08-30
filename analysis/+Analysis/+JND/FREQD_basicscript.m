%Some basic code to change around to break up the freq discrim results

cor=3;
guess=4;
both=5;

%uncomment to split by over or under a frequency
%idx=1; idx2=1; clear yy; clear zz; 
% for ii=1:length(xx)
%     if xx(ii,1)<50 && xx(ii,2)<50
%         yy(idx,size(xx,2))=xx(ii,:); idx=idx+1;
%     
%     else
%         zz(idx2,size(xx,2))=xx(ii,:); idx2=idx2+1;
%     end
% end

corM=[];
incorM=[];
guesM=[];
bothM=[];
%uncomment to split based on a condition
idx1=1; idx2=1; idx3=1; idx4=1;
for ii=1:length(xx)
    if xx(ii,cor)==1
        corM(idx1,1:size(xx,2))=xx(ii,:);
        idx1=idx1+1;
    else
        incorM(idx2, 1:size(xx,2))=xx(ii,:);
        idx2=idx2+1;
    end
    if xx(ii,guess)==1
        guesM(idx3, 1:size(xx,2))=xx(ii,:);
        idx3=idx3+1;
    end
    if xx(ii, both)==0
        bothM(idx4, 1:size(xx,2))=xx(ii,:);
        idx4=idx4+1;
    end
        
end

clm=3;

% temp_table=[nnz(corM(:, clm)),  nnz(incorM(:,clm)); length(corM(:,clm))-nnz(corM(:,clm)), length(incorM(:,clm))-nnz(incorM(:,clm))];
% [h, p, sts]=fishertest(temp_table)
% hghr=nnz(corM(:,clm))/length(corM(:,clm))
% lwr=nnz(incorM(:,clm))/length(incorM(:,clm))



%plot the differences as a whole

N=36;
C=linspecer(N);
figure
hold on
p1=plot(corM(:,6), corM(:,7), 'o');
p1.MarkerFaceColor=C(1,:);  p1.MarkerEdgeColor=C(1,:);
p1.MarkerSize=15;
p1.LineWidth=2;
p2=plot(incorM(:,6), incorM(:,7), 'o');
p2.MarkerFaceColor=C(36,:);p2.MarkerEdgeColor=C(36,:);
p2.MarkerSize=15;

p4=plot(bothM(:,6), bothM(:,7), 'd');
p4.MarkerFaceColor='none'; p4.MarkerEdgeColor=C(20,:);
p4.MarkerSize=10;
p4.LineWidth=1;
p3=plot(guesM(:,6), guesM(:,7), '+');
p3.MarkerFaceColor=C(10,:); p3.MarkerEdgeColor=C(10,:);
p3.MarkerSize=10;
p3.LineWidth=2;
xlim([0 90])
ylim([0 127])

set(gca,'FontSize', 22)

figure
hold on
p1=plot(corM(:,6), corM(:,7), 'o');
p1.MarkerFaceColor='y';  p1.MarkerEdgeColor='k';
p1.MarkerSize=15;
p1.LineWidth=2;
p2=plot(incorM(:,6), incorM(:,7), 'o');
p2.MarkerFaceColor=C(33,:);p2.MarkerEdgeColor='k';
p2.MarkerSize=15;
p2.LineWidth=2;

p4=plot(bothM(:,6), bothM(:,7), 'd');
p4.MarkerFaceColor='none'; p4.MarkerEdgeColor=C(11,:);
p4.MarkerSize=10;
p4.LineWidth=2;
p3=plot(guesM(:,6), guesM(:,7), '+');
p3.MarkerFaceColor=C(1,:); p3.MarkerEdgeColor=C(1,:);
p3.MarkerSize=10;
p3.LineWidth=2;
xlim([0 90])
ylim([0 129])

set(gca,'FontSize', 22)

