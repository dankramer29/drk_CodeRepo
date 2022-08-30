function Rancho(et,varargin)
% et.hPupil.ip = '192.168.100.101';
% et.hPupil.pupilFrequency = 120;
% et.hPupil.bufferClearingFudgeFactor = 20;

if strcmp(getenv('computername'),'DECODE')
    et.remoteIP = '192.168.100.72';
    et.remotePort = '50020';
    comment(et,sprintf('Running on DECODE setting remoteIP to tcp://%s:%s',et.remoteIP,et.remotePort),0)
else
    et.remoteIP = '127.0.0.1';
    et.remotePort = '50020';
    comment(et,sprintf('NOT on DECODE setting remoteIP to local (tcp://%s:%s)',et.remoteIP,et.remotePort),0) 
end
