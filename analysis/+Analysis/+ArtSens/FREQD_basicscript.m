%Some basic code to change around to break up the freq discrim results

idx=1; idx2=1; clear yy; clear zz; 
for ii=1:length(xx)
    if xx(ii,1)<50 && xx(ii,2)<50
        yy(idx,1:6)=xx(ii,:); idx=idx+1;
    
    else
        zz(idx2,1:6)=xx(ii,:); idx2=idx2+1;
    end
end

% for ii=1:length(xx)
%     if xx(ii,5)==1
%         yy(idx,1:6)=xx(ii,:);
%         idx=idx+1;
%     else
%         zz(idx2, 1:6)=xx(ii,:);
%         idx2=idx2+1;
%     end
% end

clm=3;

temp_table=[nnz(yy(:, clm)),  nnz(zz(:,clm)); length(yy(:,clm))-nnz(yy(:,clm)), length(zz(:,clm))-nnz(zz(:,clm))];
[h, p, sts]=fishertest(temp_table)
hghr=nnz(yy(:,clm))/length(yy(:,clm))
lwr=nnz(zz(:,clm))/length(zz(:,clm))