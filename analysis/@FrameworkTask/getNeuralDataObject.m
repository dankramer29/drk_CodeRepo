function obj = getNeuralDataObject(this,varargin)
            % GETNEURALDATAOBJECT Retrieve neural data associated with task
            %
            %  OBJ = GETNEURALDATAOBJECT(THIS)
            %  By default, returns the neural data object associated with
            %  all available neural data types from each available array.
            %  The output will be arranged in a cell array with one cell
            %  per array; each of these cells will be a cell array with one
            %  cell per available neural data type. The neural data objects
            %  will be of type Blackrock.NSx or Blackrock.NEV.
            %
            %  OBJ = GETNEURALDATAOBJECT(...,NSPS)
            %  Specify a single char or cell array of chars indicating
            %  NSP names. These strings must match (case-insensitive)
            %  with an entry in the property 'nspNames'.
            %
            %  OBJ = GETNEURALDATAOBJECT(...,TYPES)
            %  Specify a single char or cell array of chars indicating
            %  neural data types.
            %
            %  OBJ = GETNEURALDATAOBJECT(...,VARARGIN)
            %  Any input not matching the above configurations will be
            %  passed along to the constructor(s) of the requested neural
            %  data objects.
            %
            %  SEE ALSO AVAILABLENEURALDATATYPES, Blackrock.NSx,
            %  Blackrock.NEV.
            if this.neuralSourceIsSimulated
                log(this.hDebug,'Neural source is simulated','warn');
                obj = [];
                return;
            end
            [varargin,debug,found_debug] = util.argisa('Debug.Debugger',varargin,[]);
            if ~found_debug,debug=this.hDebug;end
            
            % get list of files
            [data_type,~,~,files] = availableNeuralDataTypes(this,varargin{:});
            obj = cell(1,length(files));
            for ff=1:length(files)
                switch lower(data_type{ff})
                    case 'blc'
                        obj{ff} = BLc.Reader(files{ff},debug);
                end
            end
        end % END function getNeuralDataObject