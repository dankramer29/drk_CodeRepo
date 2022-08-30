function addData(this,varargin)
%
%   ADDDATA(THIS,DATA1,DATA2,...)
%   Load data provided as input in the DATA1, DATA2, etc. arguments.  Each
%   of DATAn must be a struct in the same format returned by the READ
%   method of the Blackrock.NEV class.  The following table lists the
%   fields required for each data type (other fields may be present but
%   will be ignored). Multiple recording blocks may be provided as cell
%   arrays of structs.
%
%     Spikes    -- Timestamps, Units, Channels, Waveforms
%     Comments  -- Timestamps, Color, CharSet, Text
%     Digital   -- Timestamps, Flags, Data
%     Video     -- Timestamps, FileNumber, FrameNumber, SourceIDs
%     Tracking  -- Timestamps, ParentID, NodeID, NodeCount, PointCount, 
%                  Points
%     Button    -- Timestamps, TriggerType
%     Config    -- Timestamps, ChangeType, Changed
%
%   Note that Spike data must include waveforms.
%
%   ** Only Spikes, Comments, and Digital data are supported currently;
%   provided different data types will result in an error.

% data types
dtype = {'Spike','Comment','Digital','Video','Tracking','Button','Config'};
avail = [1:3 7];

% fields required to identify input structs as a particular data type
reqfields.Spike = {'Timestamps','Units','Channels','Waveforms'};
reqfields.Comment = {'Timestamps','Color','CharSet','Text'};
reqfields.Digital = {'Timestamps','Flags','Data'};
reqfields.Video = {'Timestamps','FileNumber','FrameNumber','SourceIDs'};
reqfields.Tracking = {'Timestamps','ParentID','NodeID','NodeCount','PointCount','Points'};
reqfields.Button = {'Timestamps','TriggerType'};
reqfields.Config = {'Timestamps','ChangeType','Changed'};

% metadata fields
metafields = Blackrock.NEV.getMetadataFields;

% data properties
dtprop.Spike = 'SpikeData';
dtprop.Comment = 'CommentData';
dtprop.Digital = 'DigitalData';
dtprop.Video = 'VideoData';
dtprop.Tracking = 'TrackingData';
dtprop.Button = 'ButtonData';
dtprop.Config = 'ConfigData';

% functions to get packet IDs
pktidfn.Spike = @(x)x.Channels;
pktidfn.Comment = @(x)65535*ones(length(x.Timestamps),1);
pktidfn.Digital = @(x)0*ones(length(x.Timestamps),1);
pktidfn.Video = @(x)65534*ones(length(x.Timestamps),1);
pktidfn.Tracking = @(x)65533*ones(length(x.Timestamps),1);
pktidfn.Button = @(x)65532*ones(length(x.Timestamps),1);
pktidfn.Config = @(x)65531*ones(length(x.Timestamps),1);

% functions to preprocess input data
preprocfn.Spike = {@procSpike,this.hArrayMap};

% look for data inputs
idx = 1;
while idx<=length(varargin)
    
    % if empty input, remove and move on
    if isempty(varargin{idx})
        varargin(idx) = [];
        continue;
    end
    
    % check for required fields
    match = false(1,length(dtype));
    placeholder = false(1,length(dtype));
    if ischar(varargin{idx})
        
        % check for placeholder
        placeholder = strcmpi(varargin{idx},dtype);
        
        % process placeholders
        if any(placeholder)
            assert(nnz(placeholder)==1,'Cannot infer data type');
            assert(ismember(dtype{placeholder},dtype(avail)),'Can only process %s for now (received ''%s'')',strjoin(dtype(avail),', '),dtype{placeholder});
            
            % create empty struct
            args = {};
            for kk=1:length(reqfields.(dtype{placeholder}))
                args = [args {reqfields.(dtype{placeholder}){kk},[]}];
            end
            dt.(dtype{placeholder}) = struct(args{:});
            
            % add empty packet IDs
            dt.(dtype{placeholder}).PacketIDs = [];
            
            % remove the input
            varargin(idx) = [];
        end
    else
        
        % check for data matches
        for tt=1:length(dtype)
            match(tt) = all(ismember(reqfields.(dtype{tt}),fieldnames(varargin{idx})));
        end
        
        % process matches
        if any(match)
            assert(nnz(match)==1,'Cannot infer data type');
            assert(ismember(dtype{match},dtype(avail)),'Can only process %s for now',strjoin(dtype(avail),', '));
            
            % save the data
            dt.(dtype{match}) = varargin{idx};
            varargin(idx) = [];
            
            % run through the preprocessing function if it exists
            if isfield(preprocfn,dtype{match})
                feval(preprocfn.(dtype{match}){1});
            end
            
            % add packet IDs
            dt.(dtype{match}).PacketIDs = feval(pktidfn.(dtype{match}),dt.(dtype{match}));
        end
    end
    
    % update the index
    if ~any(placeholder) && ~any(match)
        idx = idx+1;
    end
end

% make sure no remaining inputs
util.argempty(varargin);

% reduce to just the available data types
dtype = fieldnames(dt);
assert(~isempty(dtype),'No data provided');

% add data to the NEVWriter's properties
for tt=1:length(dtype)
    dtfields = reqfields.(dtype{tt});
    mtfields = metafields.(dtype{tt});
    type = dtype{tt};
    prop = dtprop.(type);
    args = {};
    for ff=1:length(dtfields)
        args = [args {dtfields{ff},{dt.(type).(dtfields{ff})}}];
    end
    for ff=1:length(mtfields)
        if isfield(dt.(type),mtfields{ff})
            args = [args {mtfields{ff},{dt.(type).(mtfields{ff})}}];
        end
    end
    args = [args {'PacketIDs',{dt.(type).PacketIDs}}];
    this.(prop) = [this.(prop) {struct(args{:})}];
end

    function procSpike
        % PROCSPIKE process spike data (convert el/ch, add sort info)
        
        % check whether channel numbers are available
        if ~isempty(this.hArrayMap)
            if isfield(dt.Spike,'Electrodes') && ~isfield(dt.Spike,'Channels')
                
                % convert electrode numbers into channel numbers
                dt.Spike.Channels = this.hArrayMap.el2ch(dt.Spike.Electrodes);
            elseif isfield(dt.Spike,'Channels') && ~isfield(dt.Spike,'Electrodes')
                
                % convert electrode numbers into channel numbers
                dt.Spike.Electrodes = this.hArrayMap.ch2el(dt.Spike.Channels);
            end
        end
        
        % update the sorting info
        for cc = 1:length(this.ExtendedHeaders.ChannelInfo)
            ChannelID = this.ExtendedHeaders.ChannelInfo(cc).ChannelID;
            uid = unique(dt.Spike.Units(dt.Spike.Channels==ChannelID));
            uid(uid<=0 | uid>=255) = [];
            this.ExtendedHeaders.ChannelInfo(cc).NumSortedUnits = this.ExtendedHeaders.ChannelInfo(cc).NumSortedUnits + nnz(uid);
        end
    end % END function procSpike
end