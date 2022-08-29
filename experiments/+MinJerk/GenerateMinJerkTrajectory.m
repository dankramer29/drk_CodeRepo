function out=GenerateMinJerkTrajectory(Pos,MT,HT,SR)

% generate a simulated movement signal in which a "hand" moves between
% and holds positions in space.
% Tyson Aflalo

% Pos   :   NxD Steady state positions
% MT    :   (N-1) movement times between Steady state positions (in ms)
% HT    :   (N) Hold Times at each Steady state position (in ms)
% SR    :   Sampling rate of signal (in ms)

% % Examples of valid input
% % Target Positions
% Pos=[[0,0];[3,1];[-2,0]; [2,1]]
% %movement Times (in ms)
% MT=[300,500, 250]
% %Hold Times (in ms)
% HT=[200,200,200,200]
% %Sampling rate in ms
% SR=10;
%
% Or a bunch of movements
% Ntargets=100;
% Pos=rand(Ntargets,3)*20-10;
% MT=round(rand(Ntargets-1)*200+100);
% HT=round(rand(Ntargets)*100+100);
% SR=10;
% out=GenerateMinJerkTrajectory(Pos,MT,HT,SR);
%     0.4284    0.3064    0.3196
%    -0.3586   -0.3603    0.1208
%    -0.0926    0.1490    0.3949

% for each dimension
for j=1:size(Pos,2)
    
    Trajectory=[repmat(Pos(1,j),HT(1),1)];
    time=[];
    
    for i=1:size(Pos,1) -1
        [trj] = MinJerk.min_jerk([Pos(i,j);Pos(i+1,j)], MT(i),[],[],[]);
        Trajectory=[Trajectory;trj];
        
        % append hold time in samples
        HT_samples=round(HT(i+1));
        Trajectory=[Trajectory;repmat(Pos(i+1,j),HT_samples,1)];
    end
    
    Velocity=[0;diff(Trajectory)]/(1/1000);
    Acceleration=[0;diff(Velocity)]/(1/1000);
    
    out.Position(:,j)=decimate(Trajectory,SR);
    out.Velocity(:,j)=decimate(Velocity,SR);
    out.Acceleration(:,j)=decimate(Acceleration,SR);
end


out.Time=[0:length(out.Position(:,1))-1]/1000*SR;





