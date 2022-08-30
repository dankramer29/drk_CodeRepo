function loadServerRemote(u)
fwrite(u,uint8(Blackrock.Stimulator.ServerCommand.LOADSERVER),'uint8');