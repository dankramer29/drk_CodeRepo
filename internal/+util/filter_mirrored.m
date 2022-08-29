function signalout=filter_mirrored(b,a,signal,IC,dim,varargin)

[varargin,zeroPhase]=util.argflag('zeroPhase',varargin,false);
util.argempty(varargin);

N=max([length(b) length(a)])*3;

if dim==2
    signalMirrored=[signal(:,N:-1:1),signal,signal(:,end:-1:end-N)];
else
    signalMirrored=[signal(N:-1:1,:);signal;signal(end:-1:end-N,:)];
end

%%
if zeroPhase
    if dim==2
        [signalout_mirrored]=filtfilt(kernel,1,signalout_mirrored')';
    else
        [signalout_mirrored]=filtfilt(kernel,1,signalout_mirrored);
    end
else
    [signalout_mirrored]=filter(b,a,signalMirrored,IC,dim);
end

if dim==2
    signalout=signalout_mirrored(:,N+1:end-N-1);
else
    signalout=signalout_mirrored(N+1:end-N-1,:);
end


