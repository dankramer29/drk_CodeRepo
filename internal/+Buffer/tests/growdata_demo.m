%{
This is a set of demos to show the usage of growdata and growdata2.

Dynamic growth of an array in matlab is an easy thing to do. Its
also a terrible waste of cpu cycles. The problem is that every time 
you append new rows (or columns) to an existing array, Matlab needs
to re-allocate you entire array. If you append new rows to a matrix,
then its even worse, since it needs to shuffle all the numbers around.

Far better is to pre-allocate your arrays to their final dimension.
Now you just use indexing to replace the old rows of zeros with their
final values. This is MUCH better. But sometimes you just don't know
how many rows or colums you will have in the end. So you get stuck.

A better solution for small numbers of appendations is to use a cell
array, coupled with one big concatenation at the end. This actually
works acceptably. The problem is not to pass that array back and
forth constantly. This takes much time, over thousands of iterations.
So any function that does this appending operation is best written to
keep it permanently in memory.

The much better solution is to use growdata or growdata2. These
came from a discussion on comp.soft-sys.matlab. Growdata works by
keeping its data as a persistent variable. Growdata2 uses a nested
function to store its data until it is time to unpack the array.

Both growdata and growdata2 require 3 steps for growth. They allow
you to append any sizes of new elements, as long as they will be
conformable for the final concatenation step.

- An intialization step

- Growth inside a loop

- An unpacking step

Growdata2 is more sophisticated. It allows you to append as either
rows or columns, whereas growdata only allows you to append new
rows to your data. Growdata does have one virtue though, as it
should run on somewhat older releases of matlab. Growdata2 will
require at least R14 of matlab, since it uses nested functions.

%}

%% Simple concatenation of 10000 blocks, using growdata
% In this case, yes, we know exactly the final size of the array.
% This example is merely a time test, plus it shows that growdata
% produces the correct size result.

tic
% The initialization call
growdata

% growth
for i = 1:10000
  growdata(rand(2,5))
end

% unpacking step
data = growdata;
toc

% The data array should be 20000x5.
size(data)

%% Appending differently sized blocks, as columns using growdata2

tic
% initialize a function handle to grow as columns
funh = growdata2('columns');

for ind = 1:50000
  c = round(rand(1)*5)+1;
  newcols = ind + rand(1,c);
  funh(newcols)
end

data = funh();
toc

size(data)

%% Growth of two variables at once
% Growdata can only grow one array at a time, because it uses persistent
% variables. But growdata2 can grow as many different variables as you
% want.

tic
gfun1 = growdata2('rows');
gfun2 = growdata2('columns');
A = {eye(3),rand(2,3)};
% growth for an unknown number of cycles
for ind = 1:(200000*rand(1))
  % append a 3x3 and a 2x3 alternately to array 1
  gfun1(A{rem(ind,2)+1})
  
  % appending a single scalar variable, as columns of array 2
  gfun2(rand(1))
end

data1 = gfun1();
data2 = gfun2();
toc

size(data1)
% Note that the loop actually ran for length(data2) steps.
size(data2)

%% Growth with larger chunks
% You can grow any size chunks you want. If the chunks are
% really large, then it might make sense to specify a larger
% blockwize for growdata2, but these tools automatically
% adjust their blocksizes internally if you append large
% chunks of data.

tic
funh = growdata2;
steps = rand(1)*20000;
for ind = 1:steps
  newcols = rand(300,1);
  funh(newcols)
end
data = funh();
toc

%% Do these tools work linearly in time?

% Grow with fixed size blocks to make the comparison
% a valid one.

tic
funh = growdata2;
steps = 10000;
for ind = 1:steps
  funh(eye(5))
end
data = funh();
toc

tic
funh = growdata2;
steps = 20000;
for ind = 1:steps
  funh(eye(5))
end
data = funh();
toc

tic
funh = growdata2;
steps = 40000;
for ind = 1:steps
  funh(eye(5))
end
data = funh();
toc

% Note that the time required grew quite linearly with
% the length of the loop.

