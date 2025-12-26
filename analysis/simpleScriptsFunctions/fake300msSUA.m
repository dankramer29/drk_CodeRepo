%a chat gpt fake firing rate that is decodable after 300 ms
%% Parameters
rng(1);                     % reproducibility

nUnits   = 50;
nTrials  = 80;
T        = 1500;             % ms
dt       = 1;                % ms bins
time     = 1:T;

smoothSD = 30;               % ms (Gaussian smoothing)
kernelT  = -4*smoothSD:4*smoothSD;
gKernel  = exp(-kernelT.^2/(2*smoothSD^2));
gKernel  = gKernel / sum(gKernel);

baselineRate = 5;            % Hz
modRate      = 10;           % Hz (condition effect)
effectOnset  = 300;          % ms

%% Preallocate
spkFake = struct();


%% Generate data
for u = 1:nUnits

    % Unit-specific gain
    unitGain = 0.5 + rand;

    % Mean firing rate templates
    rate1 = baselineRate * ones(1,T);
    rate2 = baselineRate * ones(1,T);

    rate1(time >= effectOnset) = baselineRate + unitGain*modRate;
    rate2(time >= effectOnset) = baselineRate - unitGain*modRate/2;

    % Prevent negative rates
    rate2(rate2 < 0) = 0.1;

    % Smooth mean rates
    rate1 = conv(rate1, gKernel, 'same');
    rate2 = conv(rate2, gKernel, 'same');

    % Generate trials (Poisson spiking → rate estimate)
    fr1 = zeros(nTrials, T);
    fr2 = zeros(nTrials, T);

    for tr = 1:nTrials
        fr1(tr,:) = poissrnd(rate1 * dt / 1000) * (1000/dt);
        fr2(tr,:) = poissrnd(rate2 * dt / 1000) * (1000/dt);
    end

    % Final smoothing (as in real pipelines)
    fr1 = conv2(fr1, gKernel, 'same');
    fr2 = conv2(fr2, gKernel, 'same');

    spkFake.cong{u,1} = fr1;
    spkFake.incong{u,1} = fr2;
end

figure
plot(mean(spkFake.cong{1}))
hold on
plot(mean(spkFake.incong{1}))