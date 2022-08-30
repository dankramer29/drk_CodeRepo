classdef Preface < handle & Experiment2.StageInterface & util.Structable & util.StructableHierarchy
    
    properties
        name = 'Preface';
    end % END properties
    
    methods
        function this = Preface(parent)
            this = this@Experiment2.StageInterface(parent);
            
            % big try-catch: errors in constructors sometimes leave handles
            % to half-constructed objects stranded in memory
            try
                % set up phases from parameters
                assert(all(cellfun(@iscell,this.hTask.params.prefaceDefinitions)),'Invalid phase definitions (empty elements)');
                assert(all(cellfun(@(x)ischar(x{1})||isa(x{1},'function_handle'),this.hTask.params.prefaceDefinitions)),'Invalid phase definitions (missing function handle)');
                for kk=1:length(this.hTask.params.prefaceDefinitions)
                    this.phaseAdd(this.hTask.params.prefaceDefinitions{kk});
                end
            catch ME
                delete(this);
                rethrow(ME);
            end
        end % END function Preface
        
        function skip = structableSkipFields(this)
            skip = structableSkipFields@Experiment2.StageInterface(this);
        end % END function structableSkipFields
        
        function st = structableManualFields(this)
            st = structableManualFields@Experiment2.StageInterface(this);
        end % END function structableManualFields
    end % END methods
end % END classdef Preface