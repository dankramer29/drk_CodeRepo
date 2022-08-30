function loadServerLocal(stimdir)
cmd = fullfile(stimdir,'NeuralStimulator.bat &');
try system(cmd); catch ME, Utilities.errorMessage(ME); end