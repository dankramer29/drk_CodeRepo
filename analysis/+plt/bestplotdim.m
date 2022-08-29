function [nr,nc] = bestplotdim(num)
% BESTPLOTDIM Find the best subplot layout for a given number of subplots
%
%   [NR,NC] = BESTPLOTDIM(NUM)
%   Returns the number of rows NR and number of columns NC for the layout
%   closest to square given the number of subplots required NUM.

% possible numbers of rows
row_range = 1:num;

% possible numbers of columns
col_range = num./row_range;

% minimize the sum of numbers of rows + numbers of columns
[~,idx] = min(row_range+col_range);

% return the row/column with minimum sum
nr = row_range(idx);
nc = ceil(col_range(idx));