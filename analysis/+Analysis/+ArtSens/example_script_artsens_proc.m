%basic script for running the artsens_proc

mapBM2=GridMap('C:\Users\dkramer\Documents\DATA\BM\P08_Research_62218_RealTouch_map.csv');
blcBM2=BLc.Reader('C:\Users\dkramer\Documents\DATA\BM\P08_Research_62218_RealTouch-000.blc');


%REMEMBER TO MAKE AN _EVENTS FILE WITH THE SAME BASE NAME. IF FROM .E
%FILES, MEANING MOVE IT INTO THE SAME FOLDER AND MAKE THE SAME NAME AS THE
%BLC WITH A _Events FILE AFTER.
%WILL HAVE TO MAKE BY HAND. EASIEST WAY IS TO HAVE THE TIME IN A LEFT
%COLUMN AND THE XX/ZZ IN THE RIGHT.  THE TIMES NEED TO HAVE 3 DIGITS, SO
%ADD A 0 SO IT'S 04:24:32.230.  IF IT DOESN'T WORK, ADD TWO SPACES AFTER
%THE NUMBERS (SHOULD BE FIXED THOUGH)

%TO FIND CHANNEL NAMES, MAKE SURE YOU USE THE BLC FILE CHANNEL INFO AND NOT
%THE MAPFILE 

%IF DOING JR: the map skips channel 54, but when you run it through the blc
%file, that channel info has them as 54 to 117

%enter the channels as the actual row, not the grid number
[ thisBM2, specPowerBM2, specgramcBM2, elec_pBM2 ] = ArtSens.artsens_proc( blcBM2, 'ch', [72 86], 'itiWin', 1.5, 'prepost', [0.5 2], 'window', [0.2 0.005]);
%then click the channels you want to have mapped together