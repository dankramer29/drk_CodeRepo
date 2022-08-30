function metafields = getMetadataFields(dtype)
% GETMETADATAFIELDS Get a list of user-defined metadata fields for NEV data
%
%   METAFIELDS = GETMETADATAFIELDS
%   Return a structure METAFIELDS with one field per NEV data packet type.
%   Each field contains a cell array of strings listing the metadata fields
%   that may be available for that data packet type. For example,
%   METAFIELDS.SPIKE may contain the cell array {'QUALITY'}. In this case,
%   if the metadata file contains the appropriate data, when the READ
%   method is called the returned structure will contain QUALITY in 
%   addition to CHANNELS, UNITS, etc. 
%
%   METAFIELDS = GETMETADATAFIELDS(DTYPE)
%   Provide a string or cell array of string indicating the requested data
%   types.  Available data types are: SPIKE, COMMENT, DIGITAL, VIDEO,
%   TRACKING, BUTTON, and CONFIG.

% list all metadata fields here
metafields.Spike = {'Quality'};
metafields.Comment = {};
metafields.Digital = {};
metafields.Video = {};
metafields.Tracking = {};
metafields.Button = {};
metafields.Config = {};

% validate/process inputs
if nargin==0||isempty(dtype),dtype={'Spike','Comment','Digital','Video','Tracking','Button','Config'};end
dtype = util.ascell(dtype);
cellfun(@(x)assert(ischar(x),'Inputs must be char, not ''%s''',class(x)),dtype);
cellfun(@(x)assert(ismember(x,fieldnames(metafields)),'Input ''%s'' is not a valid data packet type (must be one of %s)',x,strjoin(fieldnames(metafields))),dtype);

% remove fields not requested before returning
mtfields = fieldnames(metafields);
for mm=1:length(mtfields)
    if ~any(strcmpi(mtfields{mm},dtype))
        metafields = rmfield(metafields,mtfields{mm});
    end
end

% reduce to a single cell array, if only a single data type
dtype = fieldnames(metafields);
if length(dtype)==1
    metafields = metafields.(dtype{1});
end