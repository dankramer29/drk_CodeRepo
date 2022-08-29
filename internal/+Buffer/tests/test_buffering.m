
% working data set
data = rand(1e5,1e1);

% initialize buffers
dbuf = Buffer.Dynamic('r');
cbuf = Buffer.Circular(100,'r');
fbuf = Buffer.FIFO(100,'r');
%gbuf = growdata2;

% pre-allocate to store time taken
dtime = zeros(1,size(data,2));
ctime = zeros(1,size(data,2));
ftime = zeros(1,size(data,2));
%gtime = zeros(1,size(data,2));

% pre-determine random number of elements to add each iteration of loop
num=nan(size(data,1),1);
amount=0;
k=1;
while(amount<size(data,1))
    num(k)=randi(1000,1);
    amount=amount+num(k);
    k=k+1;
end
num(k:end)=[];
num(end)=size(data,1)-sum(num(1:end-1));

% add data to the buffer
idx=0; % index into data
k=0; % index into num
while(idx<size(data,1))
    k=k+1;

    % add data to buffers
    t=tic; add(dbuf,data(idx+(1:num(k)),:)); dtime(k)=toc(t);
    t=tic; add(cbuf,data(idx+(1:num(k)),:)); ctime(k)=toc(t);
    t=tic; add(fbuf,data(idx+(1:num(k)),:)); ftime(k)=toc(t);
    %t=tic; gbuf(data(idx+(1:num(k)),:)); gtime(k)=toc(t);
    idx=idx+num(k);

    % % check stored/returned values
    % try
    %     assert(dbuf.Length==idx);
    %     for m=1:10:idx
    %         ddata=get(dbuf,m);
    %         assert(nnz(ddata==data((idx-m+1):idx,:))==m*size(data,2));
    %     end
    %     for m=1:10:min(idx,cbuf.Capacity)
    %         cdata=get(cbuf,m);
    %         assert(nnz(cdata==data((idx-m+1):idx,:))==m*size(data,2));
    %     end
    % catch ME
    %     fprintf(2,'In ''%s'' on line %d: %s\n',ME.stack(2).name,ME.stack(2).line,ME.message);
    %     keyboard
    % end

    % update user
    if(rem(k,1000)==0), fprintf('%d/%d\n',k,length(num)); end
end

% retrieve and compare
ddata=get(dbuf);
assert(nnz(ddata==data)==numel(ddata));
cdata=get(cbuf);
assert(nnz(cdata==data((end-cbuf.capacity+1):end,:))==numel(cdata));
fdata=get(fbuf);
assert(nnz(fdata==data(1:fbuf.capacity,:))==numel(fdata));
%gdata=gbuf();
%assert(nnz(gdata==data)==numel(gdata));

% plot times
figure
plot(dtime,'b');
hold on
plot(ctime,'r');
plot(ftime,'k');
%plot(gtime,'k');
%legend({'Dynamic','Circular','growdata'});
legend({'Dynamic','Circular','FIFO'});

% print out results
clc
fprintf('\n');
fprintf('RESULTS\n');
fprintf('          dynamic\tcircular\tFIFO\n');
fprintf('mean:     %1.2e\t%1.2e\t%1.2e sec\n',mean(dtime),mean(ctime),mean(ftime));
fprintf('median:   %1.2e\t%1.2e\t%1.2e sec\n',median(dtime),median(ctime),median(ftime));
fprintf('std:      %1.2e\t%1.2e\t%1.2e sec\n',std(dtime),std(ctime),std(ftime));
%fprintf('          grow\t\tdynamic\t\tcircular\n');
%fprintf('mean:     %1.2e\t%1.2e\t%1.2e sec\n',mean(gtime),mean(dtime),mean(ctime));
%fprintf('median:   %1.2e\t%1.2e\t%1.2e sec\n',median(gtime),median(dtime),median(ctime));
%fprintf('std:      %1.2e\t%1.2e\t%1.2e sec\n',std(gtime),std(dtime),std(ctime));
fprintf('\n');