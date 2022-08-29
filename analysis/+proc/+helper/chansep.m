function d = chansep(layout,spacing,chanpairs,arraynum,precision)
% CHANSEP Compute separation distance between pairs of channels
%
%   D = CHANSEP(LAYOUT)
%   Compute the normalized spacing (i.e., horizontally or vertically
%   neighboring channels have d=1) between pairs of channels, based on the
%   layout matrix LAYOUT. This matrix should have the same number of rows
%   and columns as the actual electrode array, and the relative positioning
%   of each electrode in LAYOUT should also be the same as in the actual
%   electrode array.
%
%   D = CHANSEP(LAYOUT,SPACING)
%   Optionally specify the spacing (in arbitrary units) between electrodes.
%   This effectively scales the distance by the constant factor SPACING.
%
%   D = CHANSEP(LAYOUT,SPACING,CHANPAIRS)
%   Optionally specify a list of channel pairs for which to compute
%   separation distance. The default behavior is to compute separation
%   distance between all possible channel pairs in LAYOUT.
%
%   D = CHANSEP(LAYOUT,SPACING,CHANPAIRS,ARRAYNUM)
%   Optionally specify array numbers; separation distances will not be
%   computed for channels from different arrays. The default behavior is to
%   consider all channels in LAYOUT as being in the same physical array.
%   This input argument may be useful when using data from split pedestal
%   arrays (i.e., channels from multiple physical arrays combined into a
%   single pedestal and therefore single recording file).
%
%   D = CHANSEP(LAYOUT,SPACING,CHANPAIRS,ARRAYNUM,PRECISION)
%   Optionally specify a precision, i.e., number of decimal places of
%   accuracy, in PRECISION. Note that PRECISION will be applied to
%   normalized separation distances (prior to scaling by the physical
%   separation distance if provided). The default value of PRECISION is 3.
if nargin<2||isempty(spacing),spacing=1;end
if nargin<3||isempty(chanpairs)
    
    % compute channel pairs from the layout; ignore NaNs.
    chlist = unique(layout(:));
    chlist(isnan(chlist)) = [];
    nch = length(chlist);
    chidx = nchoosek(1:nch,2);
    chanpairs = [chlist(chidx(:,1)) chlist(chidx(:,2))];
end
if nargin<4||isempty(arraynum)
    
    % default all channels from same physical array
    chlist = unique(layout(:));
    chlist(isnan(chlist)) = [];
    arraynum = nan(1,nanmax(layout(:)));
    arraynum(chlist) = 1;
end
if nargin<5||isempty(precision),precision=3;end

% compute separation distance between pairs of channels
% here, in normalized units of "minimum separation distance"
d = nan(size(chanpairs,1),1);
for kk=1:size(chanpairs,1)
    ch1 = chanpairs(kk,1);
    ch2 = chanpairs(kk,2);
    
    % shortcut to nan if not in same array (for now)
    if arraynum(ch1) ~= arraynum(ch2)
        d(kk) = nan;
        continue;
    end
    
    % compute spacing
    [c1,r1] = find(layout==ch1);
    [c2,r2] = find(layout==ch2);
    d(kk) = sqrt( (c1-c2)^2 + (r1-r2)^2 );
end

% convert to units of spacing input (i.e., mm)
d = spacing * d;

% apply precision
d = round(d*power(10,precision))/power(10,precision);