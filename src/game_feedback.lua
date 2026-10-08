-- Observe completed simulation steps; never consume gameplay RNG or change actors.
local F={events={},clock=0}
local colors={capture={1,.66,.28},respawn={1,.81,.49},start={1,.87,.56},charge={.35,.85,1}}
function F.reset()
 F.clock=0;F.events={};F.level=player.level;F.deaths=player.death;F.charges=player.charges or 0
 F.frozen=setmetatable({},{__mode='k'});F.levelAt=nil;F.deathAt=nil;F.chargeAt=nil;F.pendingRespawn=nil
end
function F.emit(kind,x,y)
 if not Graphics.effects or Replay.ghost then return end
 if #F.events>=16 then table.remove(F.events,1) end
 F.events[#F.events+1]={kind=kind,x=x,y=y,age=0,duration=.42}
end
function F.update(dt)
 F.clock=F.clock+dt
 for i=#F.events,1,-1 do local e=F.events[i];e.age=e.age+dt;if e.age>=e.duration then table.remove(F.events,i) end end
 if F.level~=player.level or F.deaths~=player.death then F.events={} end
 if F.level~=player.level then F.levelAt=F.clock;F.frozen=setmetatable({},{__mode='k'}) end
 if player.death>(F.deaths or player.death) then F.deathAt=F.clock;F.pendingRespawn=true end
 if F.pendingRespawn and not player.falling and not player.reset then F.emit('respawn',player.x+15,player.y+12);F.pendingRespawn=nil end
 if (player.charges or 0)>(F.charges or 0) and player.death==F.deaths then F.chargeAt=F.clock;F.emit('charge',player.x+15,player.y+12) end
 F.level=player.level;F.deaths=player.death;F.charges=player.charges or 0
 F.frozen=F.frozen or setmetatable({},{__mode='k'})
 for _,m in ipairs(mobs) do
  if m.is_frozen and not F.frozen[m] then
   F.emit('capture',m.x+(m.hitBox_offset_x or 0)+(m.hitBox_width or 0)/2,m.y+(m.hitBox_offset_y or 0)+(m.hitBox_height or 0)/2)
  end
  F.frozen[m]=m.is_frozen or nil
 end
end
function F.drawWorld()
 if not Graphics.effects then return end
 local g=love.graphics;g.push('all');g.setShader()
 for _,e in ipairs(F.events) do
  local t=e.age/e.duration;local c=colors[e.kind];local fade=(1-t)^2
  local radius=e.kind=='capture' and 31-13*(1-(1-t)^3) or 17+22*(1-(1-t)^3)
  g.setColor(.025,.035,.04,fade*.7);g.setLineWidth(3);g.circle('line',e.x,e.y,radius)
  g.setColor(c[1],c[2],c[3],fade*.9);g.setLineWidth(1.2);g.circle('line',e.x,e.y,radius)
  for i=0,5 do local a=i*math.pi/3+t*.3
   local r=radius+4+6*t;g.line(e.x+math.cos(a)*r,e.y+math.sin(a)*r,e.x+math.cos(a)*(r+3*(1-t)),e.y+math.sin(a)*(r+3*(1-t)))
  end
 end
 g.pop()
end
function F.drawHud()
 if not Graphics.effects then return end
 local g=love.graphics;g.push('all');g.setShader()
 local function pulse(at,x,y,width,c)
  if not at then return end
  local t=(F.clock-at)/.48;if t<0 or t>=1 then return end
  g.setColor(c[1],c[2],c[3],(1-t)^2);g.setLineWidth(2)
  local span=width*(.35+.65*t)/2;g.line(x-span,y,x+span,y)
 end
 pulse(F.levelAt,600,43,65,{1,.86,.45})
 pulse(F.deathAt,296,45,44,{1,.48,.3})
 if Campaign.biome==7 and not Abyss.encounterActive() then pulse(F.chargeAt,835,43,88,colors.charge) end
 g.pop()
end
return F
