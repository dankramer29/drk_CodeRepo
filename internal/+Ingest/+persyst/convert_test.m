%files = dir('\\striatum\Data\neural\incoming\unsorted\keck\Olivar Jose*\*.erd');
files = dir('Z:\neural\incoming\unsorted\keck\*\*.erd');
AutoItExecutable = 'C:\Program Files (x86)\AutoIt3\AutoIt3.exe';
AutoItScript = 'C:\Users\Persyst\Documents\erd_to_edf\load_erd_save_edf.au3';
OutputDir = 'Z:\neural\working\per\';

%index only full erd files
ind=[];
for i = 1:numel(files)
    if isempty(regexp(files(i).name,'_\d\d\d.erd', 'once'))==1
        ind=[ind,i];
    end  
end
erd_files=files(ind);

%open and convert erd files to edf files with autoit
for i = 1:numel(erd_files)
  ErdFile=[erd_files(i).folder,'\',erd_files(i).name];
  cmd = sprintf('"%s" "%s" /ErdFile@"%s" /OutputDirectory@"%s"', ...
      AutoItExecutable,...
      AutoItScript,...
      ErdFile,...
      OutputDir);
  system(cmd);
  name=erd_files(i).name;
  name=[name(1:end-4),'_log.txt'];
  fileName=[OutputDir,name];
  wait_for_existence(fileName,'file',1,inf);
  pause(5)
  log=fileread(fileName);
  pause(5);
  while  isempty(strfind(log,'Finished Processing ERD'))~=0 %#ok<*STREMP>
      pause(5);
      log=fileread(fileName);
  end
  disp('victory')
end