% this example script shows how to convert an existing ASCII file to a BLc
% file. Use the Natus NeuroWorks EEG viewer to export the ASCII file. There
% also needs to be a grid map file.

% debugger to manage log messages
debug = Debug.Debugger('debugger_name');

% ascii and grid map files
asciifile = 'C:\Path\to\ascii.txt';
mapfile = 'C:\Path\to\gridfile.map';
outdir = 'C:\Path\to\output\directory';
outbase = 'output_file_basename';

% create XLTekTxt object (represents ascii file)
xlt = Natus.XLTekTxt(asciifile,debug);

% create BLc Writer object (to create BLc file)
% in this example, one output file will contain all data (Inf sec per file)
blcw = BLc.Writer(xlt,'SecondsPerOutputFile',Inf,'MapFile',mapfile,debug);

% create the BLc file
files = blcw.save('dir',outdir,'base',outbase);

% just to make sure we can open and read from the new file
% WATCH OUT - make sure this doesn't try to read too much data
blc = BLc.Reader(files{1},debug);
dt = blc.read;
figure
plot(dt(:,1));