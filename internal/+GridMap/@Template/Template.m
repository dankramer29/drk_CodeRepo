classdef Template < handle
    
    properties
        TemplateDirectory
        TemplateExt
        TemplateName
    end % END properties
    
    methods
        function this = Template(varargin)
            
            % process user inputs/defaults
            [varargin,this.TemplateDirectory] = util.argkeyval('template_dir',varargin,fullfile(env.get('internal'),'def','grids'));
            [varargin,this.TemplateExt] = util.argkeyval('template_ext',varargin,'.csv');
            if ~isempty(varargin)
                assert(length(varargin)==1&&ischar(varargin{1}),'Must provide char template label, not "%s"',class(varargin{1}));
                this.TemplateName = varargin{1};
                varargin(1) = [];
            end
            util.argempty(varargin);
        end % END function Template
        
        function [gridinfo,chaninfo] = read(this,template)
            if nargin<2||isempty(template),template=this.TemplateName;end
            
            % identify the template
            templateDir = fullfile(this.TemplateDirectory,template);
            assert(exist(templateDir,'dir')==7,'Could not find template "%s"',template);
            templateFiles = dir(fullfile(templateDir,sprintf('*%s',this.TemplateExt)));
            assert(~isempty(templateFiles),'Could not find any templates matching "%s"',template);
            [~,idx] = sort([templateFiles.datenum],'descend');
            templateFullFile = fullfile(templateDir,templateFiles(idx(1)).name);
            
            % process the grid template file
            fid = util.openfile(templateFullFile,'r');
            try
                
                % run through any empty lines at the top
                gridline = fgetl(fid);
                while ~isempty(regexpi(gridline,'^\s*$'))
                    gridline = fgetl(fid);
                end
                
                % pull out metadata in the header
                while any(cellfun(@isempty,regexpi(gridline,{'GridElectrode','GridRow','GridColumn','GridBank'})))
                    if isempty(gridline),continue;end
                    terms = strsplit(gridline,',');
                    terms(cellfun(@isempty,terms)) = [];
                    if ~isempty(terms)&&~all(cellfun(@isempty,terms))
                        gridinfo.(terms{1}) = terms{2};
                    end
                    gridline = fgetl(fid);
                end
                
                % find out how many channels
                chaninfo = cell(1024,1);
                gg = 1;
                while ~feof(fid)
                    chaninfo{gg} = fgetl(fid);
                    gg = gg+1;
                end
                chaninfo(gg:end) = [];
                chaninfo = cellfun(@(x)strsplit(x,','),chaninfo,'UniformOutput',false);
                chaninfo = cat(1,chaninfo{:});
                chaninfo = cellfun(@str2double,chaninfo,'UniformOutput',false);
                chaninfo = cell2table(chaninfo,'VariableNames',{'GridElectrode','GridRow','GridColumn','GridBank'});
            catch ME
                util.closefile(fid);
                rethrow(ME);
            end
            util.closefile(fid);
        end % END function Template
    end % END methods
end % END classdef Template