function [x,t,fs] = createPianoTones(which,fs,varargin)

def_nharm = 5;
t = (pi/(2*def_nharm)):pi/(2*def_nharm):(pi/2 - pi/(2*def_nharm));
def_harmampl = [1 exp(-8*t).*abs(cos(2*pi*t+pi/6))]/10;
def_harmphase = zeros(1,def_nharm);%(0:def_nharm)*pi/6;
def_harmstretch = 1.001;

% process inputs
[varargin,nharm] = util.argkeyval('nharm',varargin,def_nharm);
[varargin,harmampl] = util.argkeyval('harmampl',varargin,def_harmampl);
[varargin,harmphase] = util.argkeyval('harmphase',varargin,def_harmphase);
[varargin,harmstretch] = util.argkeyval('harmstretch',varargin,def_harmstretch);
[varargin,save] = util.argflag('save',varargin,false);
[varargin,play] = util.argflag('play',varargin,false);
[varargin,duration] = util.argkeyval('duration',varargin,0.5);
[varargin,ramp1duration] = util.argkeyval('ramp1dur',varargin,0.1);
[varargin,ramp2duration] = util.argkeyval('ramp2dur',varargin,0.6);
assert((ramp1duration+ramp2duration)<=1,'Ramp duration must not exceed the total duration');
[varargin,format] = util.argkeyval('format',varargin,'.wav');
assert(any(strcmpi(format,{'.wav','.m4a','.mp4','.flac','.ogg','.oga'})),'Invalid format ''%s''; see help for audiowrite',format);
[varargin,outdir] = util.argkeyval('outdir',varargin,'.');
util.argempty(varargin);

% sampling frequency
defaultfs = 44100;
if nargin<2, fs = defaultfs; end
dt = 1/fs;
t = 0:dt:duration - dt;

% calculate frequencies
freq = note2freq(which);

% ramp up/down
ramp1duration = ramp1duration*duration;
ramp2duration = ramp2duration*duration;
ramp1freq = 1/(4*ramp1duration);
ramp1idx = 1:round(ramp1duration*fs);
ramp2freq = 1/(4*ramp2duration);
ramp2idx = 1:round(ramp2duration*fs);
ramp = [sin(t(ramp1idx)*2*pi*ramp1freq).^2 ones(1,length(t)-length(ramp1idx)-length(ramp2idx)) cos(t(ramp2idx)*2*pi*ramp2freq).^2];

% create sound data
x = zeros(length(t),length(freq));
for kk=1:length(freq)
    
    % pre-allocate for harmonics
    xharm = nan(length(t),nharm);
    
    % calculate individual harmonics
    for nn=1:nharm
        fharm = freq(kk) + (nn-1)*freq(kk)*harmstretch;
        aharm = harmampl(nn);
        pharm = harmphase(nn);
        xharm(:,nn) = aharm*sin(fharm*2*pi*t+pharm);
    end
    
    % sum harmonics to final signal, apply ramp
    x(:,kk) = sum(xharm,2).*ramp(:);
end

% save sound files
if save
    for kk=1:size(x,2)
        basename = sprintf('n%03d_d%04d',which(kk),duration*1000);
        fullpath = fullfile(outdir,sprintf('%s%s',basename,format));
        try
            audiowrite(fullpath,x(:,kk),fs);
        catch ME
            util.errorMessage(ME);
            fprintf('Please correct the error and press F5 to continue.\n');
            keyboard
        end
    end
end

% play sound files
if play
    for kk=1:size(x,2)
        sound(x(:,kk),fs);
        pause(duration);
    end
end


function freq = note2freq(note)
% piano keys (1:88) determine frequency according to:
%   f(n) = (12th-root-2)^(n-49) * 440

freq = zeros(size(note));
for kk=1:length(note)
    freq(kk) = nthroot(2,12)^(note(kk)-49) * 440;
end