 function [evtData,evtTimeStamps,evtNames] = get_event_data(blc, varargin)
 % [EVT,TS,NAMES] = GETEVENTDATA(THIS,VARARGIN) Get
 % timestamps of marked events.
 
%  OUTPUT:
%     EVTDATA=    The actual XX ZZ start and end times, split among the evtNames (soft touch etc)
%     EVTTIMESTAMPS=  The time stamps of each event from evtdata
%     EVTNAMES=   The names of each type, soft touch, deep touch, light touch
 
 %this appears to work based on michelle's
 
 % check for event file
 file_name=fullfile(blc.SourceDirectory,sprintf('%s%s%s',blc.SourceBasename,'_Events','.txt'));
 fid = fopen(file_name);
 
 evtcell = textscan(fid,'%s %s','HeaderLines',6,'Delimiter','\t');
 fclose(fid);
 
 
 % check for phase/task names
 idx = ~cellfun(@isempty,(cellfun(@(x)strfind(x,'TOUCH'),evtcell{2},'UniformOutput',false)));
 evtNames = evtcell{2}(idx)';
 
 % get range of times for each phase/task name
 evtData = cell(1,length(evtNames));
 evtTimeStamps = evtData;
 ik = find(idx);
 for nn = 1:length(ik)
     if nn < length(ik)
         evtData{nn} = evtcell{2}(ik(nn)+1:ik(nn+1)-1);
         evtTimeStamps{nn} = evtcell{1}(ik(nn)+1:ik(nn+1)-1);
     else
         evtData{nn} = evtcell{2}(ik(nn)+1:end);
         evtTimeStamps{nn} = evtcell{1}(ik(nn)+1:end);
     end
 end
 end % END of getEventData
