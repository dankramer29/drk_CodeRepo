function u = getUDP(ipAddress,remotePort,localPort,varargin)
%getUDP wrapper to get a UDP object, first finding and deleting existing
%UDP objects with same IP/ports.  returned UDP object is already open.
%
% u = getUDP(ipAddress,remotePort,localPort)
%
% Can provide name-value parameter pairs which get passed directly through
% to the underlying MATLAB UDP function:
% u = getUDP(...,'ParameterName','Value',...)
%
% By default, calls FOPEN on the newly constructed UDP object. To customize
% this behavior, use the 'FOPEN' input:
% u = getUDP(...,'FOPEN',TRUE|FALSE);

% check whether user wants to fopen the objects
flag_fopen = true;
idx = strcmpi(varargin,'fopen');
if any(idx)
    flag_fopen = varargin{circshift(idx,1,2)};
    varargin(idx|circshift(idx,1,2)) = [];
end

% find existing instruments and delete
ff = instrfind('RemoteHost',ipAddress,'RemotePort',remotePort,'LocalPort',localPort);
if ~isempty(ff)
    delete(ff);
end

% initialize new instrument
u = udp(ipAddress,remotePort,'LocalPort',localPort,varargin{:});

% open instrument
if flag_fopen
    fopen(u);
end