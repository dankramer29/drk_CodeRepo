
%% working data set
data = rand(1e5,1e1);

% initialize buffers
cap = 100;
buf = Buffer.FIFO(cap,'r');

% pre-allocate to store time taken
ftime_add = zeros(1,size(data,2));
ftime_rem = zeros(1,size(data,2));

% pre-determine random number of elements to add each iteration of loop
num_add=nan(size(data,1),1);
num_rem=nan(size(data,1),1);
amount_add=0;
k=1;
while(amount_add<size(data,1))
    num_add(k)=randi(cap,1);
    num_rem(k)=randi(num_add(k),1);
    amount_add=amount_add+num_add(k);
    k=k+1;
end
num_add(k:end)=[];
num_add(end)=size(data,1)-sum(num_add(1:end-1));
num_rem(k:end)=[];
num_rem(end)=cap;

% add data to the buffer
idx=0; % index into data
k=0; % index into num
while(idx<size(data,1))
    k=k+1;
    
    currdata = data(idx+(1:num_add(k)),:);

    % add data to buffers
    t=tic; add(buf,currdata); ftime_add(k)=toc(t);
    idx=idx+num_add(k);
    
    % remove data from buffers
    t=tic; vals=get(buf,num_rem(k)); ftime_rem(k)=toc(t);

    % update user
    if(rem(k,1000)==0), fprintf('%d/%d\n',k,length(num_add)); end
end



%% test correctness of get/prepend operations
data = rand(1,1e5);
buf = Buffer.FIFO(100,'c');

% add too much data
vals_in = data(1:150);
buf.add(vals_in);
vals_out = buf.get;
assert(all(vals_out==vals_in(1:100)));

% add half, prepend half
vals_in1 = data(1:50);
vals_in2 = data(51:100);
buf.add(vals_in1);
buf.prepend(vals_in2);
assert(buf.numEntries==100);
vals_out = buf.get;
assert(all(vals_out==[vals_in2 vals_in1]));

% add full, prepend full
vals_in1 = data(1:100);
vals_in2 = data(101:200);
buf.add(vals_in1);
buf.prepend(vals_in2);
vals_out = buf.get;
assert(all(vals_out==vals_in2));

% force wrap around from add
vals_in1 = data(1:90);
vals_in2 = data(91:150);
buf.add(vals_in1);
vals_out = buf.get(50);
assert(all(vals_out==vals_in(1:50)));
buf.add(vals_in2);
vals_out = buf.get;
assert(all(vals_out==[vals_in1(51:end) vals_in2]));

% force wrap around from prepend