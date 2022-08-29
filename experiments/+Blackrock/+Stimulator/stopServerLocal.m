function stopServerLocal(stimdir)
cmd = fullfile(stimdir,'closeServer.bat');
try system(cmd); catch ME, Utilities.errorMessage(ME); end