function stopServerRemote(u)
fwrite(u,uint8(Blackrock.Stimulator.ServerCommand.STOPSERVER),'uint8');