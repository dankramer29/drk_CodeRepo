function xhat = smoothmj(x,kernelwidth,period,halfkernel,causal)
% SMOOTHMJ Smooth a signal using a min-jerk kernel
%
%   XHAT = SMOOTHMJ(X,DURATION,PERIOD,HALFFILT,CAUSAL)
%   Creates a min-jerk kernel of duration DURATION (arbitrary units - must
%   match sampling period) and sampling period PERIOD (time per sample).
%   If HALFFILT is true, only the second half of the kernel will be used.
%   If CAUSAL is true, the kernel will be applied to x in the forward
%   direction only. If CAUSAL is false, the kernel will be applied in the
%   forward and reverse directions to produce zero phase distortion, but
%   each data point will contain information about future data points.
%   Set HALFFILT to true when CAUSAL is also true in order to avoid
%   excessive phase delay.
%
%   Based on code by Tyson Aflalo.

% defaults
if nargin<4||isempty(halfkernel),halfkernel=false;end
if nargin<5||isempty(causal),causal=false;end

% number of samples
nsamples = floor(kernelwidth/period)+1;

% min jerk kernel
kernel = diff(min_jerk([0;1],nsamples));

% make sure it will all work out
assert(size(x,1)>=3*length(kernel),'Signal must be at least %d samples long (only has %d samples)',3*length(kernel),size(x,1));

% use half the kernel or the full kernel
if halfkernel
    kernel = kernel(ceil(length(kernel)/2):end);
end
kernel = kernel(:)/sum(kernel);

% perform causal or noncausal convolution
if causal
    xhat = filtmirr(kernel,1,x);
else
    xhat = filtmirr(kernel,1,x,'zeroPhase');
end



function [trj, psg] = min_jerk(pos, dur, vel, acc, psg)
% MIN_JERK Compute minimum-jerk trajectory through specified points
%
%   [trj, psg] = min_jerk(pos, dur, vel, acc, psg)
%
%     INPUTS:
%     pos: NxD array with the D-dimensional coordinates of N points
%     dur: number of time steps (integer)
%     vel: 2xD array with endpoint velocities, [] sets vel to 0
%     acc: 2xD array with endpoint accelerations, [] sets acc to 0
%     psg: (N-1)x1 array of via-point passage times (between 0 and dur);
%          [] causes optimization over the passage times
%
%     OUTPUTS
%     trj: dur x D array with the minimum-jerk trajectory
%     psg: (N-1)x1 array of passage times
%
%   This is an implementation of the algorithm described in:
%
%     Todorov, E. and Jordan, M. (1998) Smoothness maximization along
%     a predefined path accurately predicts the speed profiles of
%     complex arm movements. Journal of Neurophysiology 80(2): 696-714
%
%   The paper is available online at www.cogsci.ucsd.edu/~todorov
%
%   Copyright (C) Emanuel Todorov, 1998-2006

% parameters
N = size(pos,1); % number of points
D = size(pos,2); % dimensionality

% defaults
if nargin<3||isempt(vel),vel=zeros(2,D);end % default endpoint velocity is 0
if nargin<4||isempt(acc),acc=zeros(2,D);end % default endpoint acceleration is 0
if nargin<5,psg=[];end % default no via-points

% construct passage times
t0 = [0; dur];
if isempty(psg) % passage times unknown, optimize
   if N>2
      psg = (dur/(N-1):dur/(N-1):dur-dur/(N-1))';
      func = @(psg_) mjCOST(psg_, pos, vel, acc, t0);
      psg = fminsearch(func, psg);
   else
      psg = [];
   end
end

% create trajectory
trj = mjTRJ(psg, pos, vel, acc, t0, dur); 


function J = mjCOST(t, x, v0, a0, t0)
% MJCOST Compute jerk cost

N = max(size(x)); D = min(size(x));

[v,a] = mjVelAcc(t, x, v0, a0, t0);
aa = [a0(1,:);a;a0(2,:)]; aa0 = aa(1:N-1,:); aa1 = aa(2:N,:);
vv = [v0(1,:);v;v0(2,:)]; vv0 = vv(1:N-1,:); vv1 = vv(2:N,:);
tt = [t0(1);t;t0(2)]; T = diff(tt)*ones(1,D);
xx0 = x(1:N-1,:); xx1 = x(2:N,:);

j=3.*(3.*aa0.^2.*T.^4-2.*aa0.*aa1.*T.^4+3.*aa1.^2.*T.^4+24.*aa0.*T.^3.*vv0-...
  16.*aa1.*T.^3.*vv0 + 64.*T.^2.*vv0.^2 + 16.*aa0.*T.^3.*vv1 -             ...
  24.*aa1.*T.^3.*vv1 + 112.*T.^2.*vv0.*vv1 + 64.*T.^2.*vv1.^2 +            ...
  40.*aa0.*T.^2.*xx0 - 40.*aa1.*T.^2.*xx0 + 240.*T.*vv0.*xx0 +             ...
  240.*T.*vv1.*xx0 +240.*xx0.^2 - 40.*aa0.*T.^2.*xx1 + 40.*aa1.*T.^2.*xx1- ...
  240.*T.*vv0.*xx1 - 240.*T.*vv1.*xx1 - 480.*xx0.*xx1 + 240.*xx1.^2)./T.^5;

J = sum(sum(abs(j)));


function X = mjTRJ(tx, x, v0, a0, t0, P)
% MJTRJ Compute trajectory

D = min(size(x));

if ~isempty(tx),
   [v,a] = mjVelAcc(tx, x, v0, a0, t0);
   aa = [a0(1,:);a;a0(2,:)];
   vv = [v0(1,:);v;v0(2,:)]; 
   tt = [t0(1);tx;t0(2)];
else
   aa = a0;
   vv = v0; 
   tt = t0;
end;
   
ii = 1;
for i = 1:P
  t = (i-1)/(P-1)*(t0(2)-t0(1)) + t0(1);
  if( t>tt(ii+1) ), ii = ii+1; end; 
  T = (tt(ii+1)-tt(ii))*ones(1,D); t = (t-tt(ii))*ones(1,D);
  aa0 = aa(ii,:); aa1 = aa(ii+1,:);
  vv0 = vv(ii,:); vv1 = vv(ii+1,:);
  xx0 = x(ii,:); xx1 = x(ii+1,:);

  X(i,:) = ...
    aa0.*t.^2./2 + t.*vv0 + xx0 + t.^4.*(3.*aa0.*T.^2./2 - aa1.*T.^2 +      ...
    8.*T.*vv0 + 7.*T.*vv1 + 15.*xx0 - 15.*xx1)./T.^4 +                      ...
    t.^5.*(-(aa0.*T.^2)./2 + aa1.*T.^2./2 - 3.*T.*vv0 - 3.*T.*vv1 - 6.*xx0+ ...
    6.*xx1)./T.^5 + t.^3.*(-3.*aa0.*T.^2./2 + aa1.*T.^2./2 - 6.*T.*vv0 -    ...
    4.*T.*vv1 - 10.*xx0 + 10.*xx1)./T.^3;
end;


function [v,a] = mjVelAcc(t, x, v0, a0, t0)
% MJVELACC Compute intermediate velocities and accelerations

N = max(size(x)); D = min(size(x));
mat = zeros(2*N-4,2*N-4); vec = zeros(2*N-4,D); 
tt = [t0(1);t;t0(2)];

for i=1:2:2*N-4
  ii = ceil(i/2)+1; T0 = tt(ii)-tt(ii-1); T1 = tt(ii+1)-tt(ii);
  tmp = [-6/T0 			-48/T0^2 	+18*(1/T0+1/T1) ...
	 +72*(1/T1^2-1/T0^2) 	-6/T1 		+48/T1^2];
  if i==1, le = 0; else le = -2; end;
  if i==2*N-5, ri = 1; else ri = 3; end;
  mat(i,i+le:i+ri) = tmp(3+le:3+ri);
  vec(i,:) = 120*(x(ii-1,:)-x(ii,:))/T0^3 + 120*(x(ii+1,:)-x(ii,:))/T1^3; 
end;

for i=2:2:2*N-4
  ii = ceil(i/2)+1; T0 = tt(ii)-tt(ii-1); T1 = tt(ii+1)-tt(ii);
  tmp = [48/T0^2 		336/T0^3 	+72*(1/T1^2-1/T0^2) ...
	 +384*(1/T1^3+1/T0^3) 	-48/T1^2 	+336/T1^3];
  if i==2, le = -1; else le = -3; end;
  if i==2*N-4, ri = 0; else ri = 2; end;
  mat(i,i+le:i+ri) = tmp(4+le:4+ri);
  vec(i,:) = 720*(x(ii,:)-x(ii-1,:))/T0^4 + 720*(x(ii+1,:)-x(ii,:))/T1^4; 
end;

T0 = tt(2)-tt(1); T1 = tt(N)-tt(N-1);
vec(1,:) = vec(1,:) + 6/T0*a0(1,:) + 48/T0^2*v0(1,:);
vec(2,:) = vec(2,:) - 48/T0^2*a0(1,:) - 336/T0^3*v0(1,:);
vec(2*N-5,:) = vec(2*N-5,:) + 6/T1*a0(2,:) - 48/T1^2*v0(2,:);
vec(2*N-4,:) = vec(2*N-4,:) + 48/T1^2*a0(2,:) - 336/T1^3*v0(2,:);

avav = inv(mat)*vec;
a = avav(1:2:2*N-4,:); v = avav(2:2:2*N-4,:);



function xhat = filtmirr(b,a,x,varargin)

% defaults and user input
[varargin,zeroPhase] = util.argflag('zeroPhase',varargin,false);
[varargin,IC] = util.argkeyval('IC',varargin,[]);
util.argempty(varargin);

% filter size
N = max([length(b) length(a)])*3;
dims = size(x);

% data class
dtclass = class(x);
if ~strcmpi(dtclass,'double')
    x = cast(x,'double');
end

% create mirrored signal
signalMirrored = [x((N+1):-1:2,:); x(:,:); x((end-1):-1:end-N-1,:)];
signalMirrored = reshape(signalMirrored,[size(signalMirrored,1) dims(2:end)]);

% filter with zero phase (forward/backward) or normally
if zeroPhase
    signalout_mirrored = filtfilt(b,a,signalMirrored);
else
    signalout_mirrored = filter(b,a,signalMirrored,IC,1);
end

% remove buildup samples
xhat = signalout_mirrored(N+1:end-N-1,:);
assert(numel(xhat)==numel(x),'Something went wrong with the reshaping');
xhat = reshape(xhat,[size(xhat,1) dims(2:end)]);

% restore data class
if ~strcmpi(dtclass,'double')
    xhat = cast(xhat,dtclass);
end
