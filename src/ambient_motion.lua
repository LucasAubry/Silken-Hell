-- Visual time may continue while input, hazards and replay time are held.
local V={offset=0}
function V.reset()V.offset=0 end
function V.update(dt)
 dt=math.min(dt,.05);V.offset=V.offset+dt
 if particleSystem then particleSystem:update(dt) end
end
function V.beginDraw()
 if App.state~='playing' then return end
 local sky=require('sky_weather')
 V.saved={timer=timer,realm=Realms.clock,sky=sky.clock}
 timer=timer+V.offset;Realms.clock=Realms.clock+V.offset;sky.clock=sky.clock+V.offset
end
function V.endDraw()
 if not V.saved then return end
 timer=V.saved.timer;Realms.clock=V.saved.realm;require('sky_weather').clock=V.saved.sky;V.saved=nil
end
return V
