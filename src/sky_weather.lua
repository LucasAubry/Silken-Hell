-- Sky hazards use simulation time only; drawing never changes their state.
local S={zones={},strikes={},holes={},trails={},snailHoles={},mist={},mistCuts={},clock=0,phaseTime=4,active=false,storm=false,seed=0}
function S.reset()
 require('sky_trails').reset()
 S.strikes={};S.holes={};S.trails={};S.snailHoles={};S.mist={};S.mistCuts={};S.clock=0;S.phaseTime=4;S.seed=0
 S.zones=require('lightning_config').zones(LevelLayouts.activeLayout,Arena.width)
 S.zoneStep=#S.zones>0 and 0 or nil
 S.storm=require('level_environment').active('lightning') and not Secret.inArena();S.active=S.storm or require('sky').openEdges()
 for _,m in ipairs(mobs) do if m.type=='dragonfly' or m.type=='mist_moth' or m.type=='wind_bat' or m.type=='cloud_snail' then S.active=true end end
end
function S.trail(x,y,tx,ty)
 require('sky_trails').add(S.trails,x,y,tx,ty,S.clock)
end
function S.fog(x,y)
 S.mist[#S.mist+1]={x=x,y=y,age=0,life=7,radius=68}
 if #S.mist>100 then table.remove(S.mist,1) end
end
function S.fogShape(p)
 local radius=p.radius*(.65+math.min(p.age/3,1)*.45)
 return p.x+math.sin(p.age*.6+p.x*.02)*9,p.y-math.min(p.age*2,12),radius*.68,radius*.51
end
function S.inFog(p,x,y)
 if p.age<.18 or p.life<.5 or S.fogCleared(x,y) then return false end
 local cx,cy,rx,ry=S.fogShape(p)
 return ((x-cx)/rx)^2+((y-cy)/ry)^2<=1
end
function S.playerVisibility()
 if not S.active then return 1 end
 local x,y=player.x+15,player.y+12
 if S.fogCleared(x,y) then return 1 end
 local thickness=0
 for _,p in ipairs(S.mist) do
  local cx,cy,rx,ry=S.fogShape(p)
  local d=((x-cx)/rx)^2+((y-cy)/ry)^2
  if d<1 then thickness=thickness+(1-d)*math.min(1,p.age*2,p.life/1.6)*.55 end
 end
 return .24+.76*math.exp(-thickness)
end
function S.playerHidden() return false end
-- Lightning cuts a lasting opening through every puff above its impact hole.
function S.clearFog(x,y)
 for _,p in ipairs(S.mistCuts) do if (x-p.x)^2+(y-p.y)^2<20^2 then p.life=8;return end end
 S.mistCuts[#S.mistCuts+1]={x=x,y=y,life=8}
 if #S.mistCuts>16 then table.remove(S.mistCuts,1) end
end
function S.fogCleared(x,y)
 for _,list in ipairs({S.holes,S.mistCuts}) do for _,p in ipairs(list) do if (x-p.x)^2+(y-p.y)^2<58^2 then return true end end end
 return false
end
-- Segment against the player rectangle, expanded by the visible electric core.
local function touches(p)
 local x0=player.x+(player.hitBox_offset_x or 0)-5
 local y0=player.y+(player.hitBox_offset_y or 0)-5
 local x1=x0+(player.hitBox_width or 30)+10
 local y1=y0+(player.hitBox_height or 24)+10
 if math.max(p.x,p.tx)<x0 or math.min(p.x,p.tx)>x1 or math.max(p.y,p.ty)<y0 or math.min(p.y,p.ty)>y1 then return false end
 local lo,hi=0,1
 for _,axis in ipairs({{p.x,p.tx-p.x,x0,x1},{p.y,p.ty-p.y,y0,y1}}) do
  local origin,delta,a,b=unpack(axis)
  if math.abs(delta)<.00001 then if origin<a or origin>b then return false end
  else
   local t0,t1=(a-origin)/delta,(b-origin)/delta
   if t0>t1 then t0,t1=t1,t0 end
   lo=math.max(lo,t0);hi=math.min(hi,t1);if lo>hi then return false end
  end
 end
 return true
end
function S.contact()
 if not S.active or player.skyThrow or player.tunnelTravel then return end
 if require('sky_trails').near(player.x,player.y,30,24,function(p)return S.clock-p.time>=.22 and touches(p) end) then Hazards.kill('electric_trail');return end
end
function S.warn(x,y,zoneSlot)
 S.seed=S.seed+1
 local _,delay=require('lightning_config').values(LevelLayouts.activeLayout,player.level)
 S.strikes[#S.strikes+1]={x=x,y=y,age=0,delay=delay,seed=S.seed,zoneSlot=zoneSlot}
end
-- Fixed map sequence: no RNG consumption and no targeting based on player movement.
local function choose()
 if #S.zones>0 then
  S.zoneStep=S.zoneStep%5+1
  for i,zone in ipairs(S.zones) do
   local x,y=require('lightning_config').point(zone,S.zoneStep);S.warn(x,y,(i-1)*5+S.zoneStep)
  end
  return
 end
 S.seed=S.seed+1
 local spawn=levels[player.level].player_position
 for i=1,20 do
  local x=85+((S.seed*173+i*131)%(math.max(1,Arena.width-170)))
  local y=85+(S.seed*109+i*97)%430
  local safe=(x-spawn.x-15)^2+(y-spawn.y-12)^2>135^2 and not Arena.blocked(x-48,y-48,96,96)
  for _,p in ipairs(levels[player.level].larme_position) do if (x-p.x-15)^2+(y-p.y-39)^2<105^2 then safe=false end end
  for _,p in ipairs(S.holes) do if (x-p.x)^2+(y-p.y)^2<95^2 then safe=false end end
  if safe then S.warn(x,y);return end
 end
end
function S.update(dt)
 if not S.active then return end
 S.clock=S.clock+dt
 for _,list in ipairs({S.mist,S.mistCuts}) do for i=#list,1,-1 do
  local p=list[i];p.life=p.life-dt;p.age=(p.age or 0)+dt
  if p.life<=0 then table.remove(list,i) end
 end end
 S.contact()
 for i=#S.strikes,1,-1 do
  local p=S.strikes[i];p.age=p.age+dt
  if p.age>=p.delay and not p.spent then
   p.spent=true
   local exists=false
   if p.zoneSlot then for _,hole in ipairs(S.holes) do if hole.zoneSlot==p.zoneSlot then exists=true;break end end end
   if not exists then
    local hole=require('ground_holes').stroke({p.x-5,p.y+2,p.x+4,p.y-3,p.x+6,p.y+3},34);hole.seed=p.seed;hole.zoneSlot=p.zoneSlot
    S.holes[#S.holes+1]=hole
   end
   BossFX.burst(p.x,p.y,{.78,.88,1},.55)
   if (player.x+15-p.x)^2+(player.y+12-p.y)^2<42^2 then Hazards.kill('sky_lightning');if player.reset then player.falling=true end end
  end
  if p.age>p.delay+.45 then table.remove(S.strikes,i) end
 end
 if S.storm and (#S.zones>0 or #S.holes<8) then
  S.phaseTime=S.phaseTime-dt
  if S.phaseTime<=0 then choose();S.phaseTime=require('lightning_config').values(LevelLayouts.activeLayout,player.level) end
 end
end
function S.fallAt(x,y)
 for _,p in ipairs(S.holes) do if require('ground_holes').containsFast(p,x,y) then return true end end
 return false
end
function S.resize(ratio)
 for _,zone in ipairs(S.zones or {}) do zone.x=zone.x*ratio;zone.w=zone.w*ratio end
 local snail=require("cloud_snail");snail.list=nil;snail.revision=(snail.revision or 0)+1
 for _,list in ipairs({S.strikes,S.mist,S.mistCuts,S.snailHoles}) do for _,p in ipairs(list) do p.x=p.x*ratio;if p.tx then p.tx=p.tx*ratio end end end
 require('sky_trails').resize(S.trails,ratio)
 for _,p in ipairs(S.holes) do require('ground_holes').resize(p,ratio) end
 for _,m in ipairs(mobs) do if m.type=='dragonfly' or m.type=='mist_moth' or m.type=='cloud_snail' then if m.tx then m.tx=m.tx*ratio end;if m.cx then m.cx=m.cx*ratio end end end
end
function S.drawGround()
 if not S.active then return end
 local g=love.graphics;g.push('all');g.setShader()
 require('terrain_surface').draw(S.holes,'hole',S.clock,1,Campaign.biome)
 g.pop()
end
function S.drawElectric()
 if S.active then require('sky_trails').draw(S.trails,S.clock) end
end
function S.drawAtmosphere()
 if not S.active then return end
 require('sky_atmosphere').draw(S.clock)
 local g=love.graphics;g.push('all');g.setShader()
 S.mistShader=S.mistShader or g.newShader('assets/shaders/sky_mist.glsl')
 g.setShader(S.mistShader);S.mistShader:send('clock',S.clock)
 local cuts={}
 for _,list in ipairs({S.holes,S.mistCuts}) do for _,p in ipairs(list) do if #cuts<24 then cuts[#cuts+1]={p.x,p.y,58} end end end
 S.mistShader:send('cutCount',#cuts)
 while #cuts<24 do cuts[#cuts+1]={-1000,-1000,0} end
 S.mistShader:send('cuts',unpack(cuts))
 -- One softly feathered, turbulent puff instead of stacked opaque ellipses.
 S.mistTexture=S.mistTexture or g.newImage(love.image.newImageData(1,1))
 for _,p in ipairs(S.mist) do
  local alpha=math.min(1,p.age*2,p.life/1.6)*.32
  local radius=p.radius*(.65+math.min(p.age/3,1)*.45)
  local drift=math.sin(p.age*.6+p.x*.02)*9
  S.mistShader:send('drift',{p.x*.021,p.y*.019})
  S.mistShader:send('puffBounds',{p.x+drift-radius,p.y-math.min(p.age*2,12)-radius*.75,radius*2,radius*1.5})
  g.setColor(1,1,1,alpha)
  g.draw(S.mistTexture,p.x+drift-radius,p.y-math.min(p.age*2,12)-radius*.75,0,radius*2,radius*1.5)
 end
 g.setShader()
 for _,p in ipairs(S.strikes) do
  if not p.spent then
   require('sky_storm_art').warning(p,S.clock,S.mistTexture)
  else
   local fade=math.max(0,1-(p.age-p.delay)/.45)
   for layer=2,1,-1 do
    g.setColor(layer==2 and .48 or .94,layer==2 and .70 or .98,1,fade*(layer==2 and .35 or 1))
    g.setLineWidth(layer==2 and 13 or 3)
    local points={}
    for i=0,9 do points[#points+1]=p.x+math.sin(i*2.7+p.seed)*((9-i)*2);points[#points+1]=p.y-(9-i)*34 end
    g.line(points)
   end
   g.setColor(.85,.94,1,fade*.45);g.ellipse('fill',p.x,p.y,45,35)
  end
 end
 g.pop()
end
return S
