function srctable = defGrids
src = cell(1e3,12);
grid_idx = 0;

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    'p1',... % PID
    'p1mg',... % GID
    'mini',... % TYPE
    'motor-sensory',... % LOCATION
    'p1mg',... % SHORTNAME
    'P1 Mini-ECoG Grid (Motor-Sensory)',... % LONGNAME
    'RAMIREZ~ FERNA_d1bc9c28-1bc2-47c1-b536-63c3fe82ff07_export002.blx',... % FILENAME
    [500 700],... % TIME
    65:127,... % CHANNELS
    [81 97:105 106:107 113:117 119:123],... % BADCHANNELS
    3,... % SPACING
    64+[nan 63:-1:57; % LAYOUT
    56:-1:49;
    48:-1:41;
    40:-1:33;
    32:-1:25;
    24:-1:17;
    16:-1:9;
    8:-1:1;]};

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    'p1',... % PID
    'p1lt',... % GID
    'macro',... % TYPE
    'left-temporal',... % LOCATION
    'p1lt',... % SHORTNAME
    'P1 Macro-ECoG Grid (Left-Temporal)',... % LONGNAME
    'RAMIREZ~ FERNA_d1bc9c28-1bc2-47c1-b536-63c3fe82ff07_export002.blx',... % FILENAME
    [500 700],... % TIME
    1:20,... % CHANNELS
    [],... % BADCHANNELS
    10,... % SPACING
    [16:20; % LAYOUT
    11:15;
    6:10;
    1:5;]};

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    'p1',... % PID
    'p1rt',... % GID
    'macro',... % TYPE
    'right-temporal',... % LOCATION
    'p1rt',... % SHORTNAME
    'P1 Macro-ECoG Grid (Right-Temporal)',... % LONGNAME
    'RAMIREZ~ FERNA_d1bc9c28-1bc2-47c1-b536-63c3fe82ff07_export002.blx',... % FILENAME
    [500 700],... % TIME
    33:52,... % CHANNELS
    [40 42],... % BADCHANNELS
    10,... % SPACING
    32+[5:-1:1; % LAYOUT
    10:-1:6;
    15:-1:11;
    20:-1:16;]};

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    'p2',... % PID
    'p2mg',... % GID
    'mini',... % TYPE
    'motor-sensory',... % LOCATION
    'p2mg',... % SHORTNAME
    'P2 Mini-ECoG Grid (Motor-Sensory)',... % LONGNAME
    'MILLER~ BRIDGE_a4675b97-fb82-432a-9ce4-2c0b2dc808cb_export005.blx',... % FILENAME
    [3690 3890],... % TIME
    33:96,... % CHANNELS
    [36 41 47:48 54 60 62:64],... % BADCHANNELS
    3,... % SPACING
    32+[64:-1:57; % LAYOUT
    56:-1:49;
    48:-1:41;
    40:-1:33;
    32:-1:25;
    24:-1:17;
    16:-1:9;
    8:-1:1;]};

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    'p2',... % PID
    'p2lt',... % GID
    'macro',... % TYPE
    'left-temporal',... % LOCATION
    'p2lt',... % SHORTNAME
    'P2 Macro-ECoG Grid (Left-Temporal)',... % LONGNAME
    'MILLER~ BRIDGE_a4675b97-fb82-432a-9ce4-2c0b2dc808cb_export005.blx',... % FILENAME
    [3690 3890],... % TIME
    13:32,... % CHANNELS
    [],... % BADCHANNELS
    10,... % SPACING
    12+[5:-1:1; % LAYOUT
    10:-1:6;
    15:-1:11;
    20:-1:16;]};

% grid_idx = grid_idx + 1;
% src(grid_idx,:) = {...
%     'p3',... % PID
%     'p3mg',... % GID
%     'mini',... % TYPE
%     'motor-sensory',... % LOCATION
%     'p3mg',... % SHORTNAME
%     'P3 Mini-ECoG Grid (Motor-Sensory)',... % LONGNAME
%     'BERNAL~ JENNIF_d651436c-1a43-4e6d-9c24-0ca0eca0fccb_export002.blx',... % FILENAME
%     [16620 16820],... % TIME
%     1:64,... % CHANNELS
%     [],... % BADCHANNELS
%     3,... % SPACING
%     [64:-1:57; % LAYOUT
%     56:-1:49;
%     48:-1:41;
%     40:-1:33;
%     32:-1:25;
%     24:-1:17;
%     16:-1:9;
%     8:-1:1;]};

% grid_idx = grid_idx + 1;
% src(grid_idx,:) = {...
%     'p3',... % PID
%     'p3rt',... % GID
%     'macro',... % TYPE
%     'left-temporal',... % LOCATION
%     'p3rt',... % SHORTNAME
%     'P3 Macro-ECoG Grid (Right-Temporal)',... % LONGNAME
%     'BERNAL~ JENNIF_d651436c-1a43-4e6d-9c24-0ca0eca0fccb_export002.blx',... % FILENAME
%     [16620 16820],... % TIME
%     65:84,... % CHANNELS
%     [],... % BADCHANNELS
%     10,... % SPACING
%     64+[5:-1:1; % LAYOUT
%     10:-1:6;
%     15:-1:11;
%     20:-1:16;]};

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    'p4',... % PID
    'p4macro',... % GID
    'macro',... % TYPE
    'sensory',... % LOCATION
    'p4macro',... % SHORTNAME
    'P4 Macro Array (Sensory)',... % LONGNAME
    'VLAHOS~ ATHANA_ec3d19ef-72cb-449a-be08-56ccfb1604b5_export_131011.blx',... % FILENAME
    [0 200],... % TIME
    1:48,... % CHANNELS
    [18:20 26:28 34:35 42:43],...
    10,... % SPACING
    [41:48; % LAYOUT
    33:40;
    25:32;
    17:24;
    9:16;
    1:8;]};
    

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    's2',... % PID
    's2mea1',... % GID
    'mea',... % TYPE
    'sensory',... % LOCATION
    's2mea1',... % SHORTNAME
    'S2 Micro-Electrode Array 1 (Sensory)',... % LONGNAME
    fullfile('20170221','s1x','baseline.ns3'),...%fullfile('20170104','s1x','test.ns3'),... % FILENAME
    [5 120],... %[5 180],... % TIME
    [1:5 7 33:45 47:49 51 53 65:88],... % CHANNELS
    [33 42 48 49 75 78],... % BADCHANNELS
    0.4,... % SPACING
    [NaN    77    74    35    83    47    48 % LAYOUT
    65    79    76    37     3    49    42
    67     2    78    39    34    86    44
    69    66    80    41    36    85    51
    71    68    81    45    38     4    53
    73    70     1    82    40     7    87
    75    72    33    84    43     5    88]};

grid_idx = grid_idx + 1;
src(grid_idx,:) = {...
    's2',... % PID
    's2mea2',... % GID
    'mea',... % TYPE
    'sensory',... % LOCATION
    's2mea2',... % SHORTNAME
    'S2 Micro-Electrode Array 2 (Sensory)',... % LONGNAME
    fullfile('20170221','s1x','baseline.ns3'),...%fullfile('20170104','s1x','test.ns3'),... % FILENAME
    [5 120],... %[5 180],... % TIME
    [6 8:32 46 50 52 54:64 89:96],... % CHANNELS
    [17 29],... % BADCHANNELS
    0.4,... % SPACING
    [NaN    56    19    10    59    29    22 % LAYOUT
     6    55    54    12    94    31    24
     9    89    52    23    93    64    26
    17    90    58    25    14    61    28
    15     8    57    21    16    63    30
    50    11    91    62    20    96    32
    46    13    92    60    27    18    95]};

src((grid_idx+1):end,:) = [];

srctable = cell2table(src,'VariableNames',{'pid','gid','type','location','shortname','longname','filename','time','channels','bad_channels','spacing','layout'});