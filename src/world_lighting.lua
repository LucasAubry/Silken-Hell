-- Presentation only: read live effects, without changing simulation or its RNG.
local L={lights={},blockers={},rotations={}}
local fire={1,.32,.055}
local gold={1,.73,.23}
local blue={.22,.62,1}
local function add(x,y,radius,power,color)
 if not x or not y or power<=.005 then return end
 if x+radius<0 or y+radius<0 or x-radius>Arena.width or y-radius>600 then return end
 L.lights[#L.lights+1]={x=x,y=y,radius=radius,power=power,color=color}
end
local function pulse(time,seed)
 return .92+.055*math.sin(time*3.7+seed)+.025*math.sin(time*8.1+seed*2)
end
function L.collect()
 L.lights={}
 if not Graphics.effects or App.state=='playing' and Abyss.playerHidden() then return L.lights end
 if App.state=='bossWorld' or Secret.inArena() then
  require('biome_radiance').sources(add,UI.clock);return L.lights
 end
 local time=Realms.clock or 0
 -- Transient sources get priority when a crowded custom map reaches the budget.
 for _,p in ipairs(BossFX.events or {}) do
  add(p.x,p.y,110+(p.power or 3)*25,math.max(0,1-p.age/.4)^2*.95,p.color)
 end
 for _,p in ipairs(Magma.bursts or {}) do add(p.x,p.y,190,math.max(0,1-p.age/.38),fire) end
 for _,p in ipairs(require('sky_lightning').events) do
  add(p.x,p.y,430,math.max(0,1-p.age/.55)*.85,{.65,.79,1})
 end
 local function storm(boss)
  if not boss.active or boss.defeated then return end
  for _,p in ipairs(boss.strikes or {}) do
   if p.age>=0 and p.age<.85 then add(p.x,p.y,80,p.age/.85*.22,gold)
   elseif p.age>=.85 and Campaign.biome~=6 then add(p.x,p.y,330,math.max(0,1-(p.age-.85)/.5)*.8,gold) end
  end
 end
 storm(Storm)
 for _,item in ipairs(Bosses.items or {}) do if item.kind=='storm' then storm(item.boss) end end
 for _,p in ipairs(Hazards.lava) do
  add(p.x,p.y,math.max(p.rx,p.ry)*3+75,1.1*pulse(time,p.x*.03+p.y),fire)
 end
 for _,p in ipairs(Magma.pools or {}) do
  add(p.x,p.y,130,.5*pulse(time,p.x),fire)
 end
 for _,m in ipairs(mobs) do if not m.dead and not m.abyssHeld and not m.spent then
  local dx,dy=require('render_motion').offset(m)
  if m.type=='lanternfish' then add(m.x+dx,m.y+dy-15,145,.65,gold)
  elseif Campaign.biome==1 and m.type=='ange' then add(m.x+dx,m.y+dy,105,.24,gold)
  elseif Campaign.biome==2 and m.type=='imp' then add(m.x+dx,m.y+dy,85,.25,fire)
  elseif m.type=='light_jelly' or Campaign.biome==4 and m.type=='jelly' then add(m.x+dx,m.y+dy,100,.4,blue)
  elseif m.type=='magma_larva' then
   local charge=math.max(0,1-((m.fuse or 3.6)-(m.age or 0))/.8)
   add(m.x+dx,m.y+dy,75+charge*45,.25+charge*.4,fire)
  elseif m.electric then add(m.x+dx,m.y+dy,90,.35,gold) end
 end end
 if Campaign.biome==7 then
  local x,y=Ocean.lightPosition()
  local exposed=(player.illuminated or 0)>0
  add(x,y,exposed and Abyss.playerLightRadius() or 75,exposed and .45 or .18,gold)
  for _,p in ipairs(Realms.vents or {}) do add(p.x,p.y-p.ry*.6,65,.3,blue) end
 end
 if Story.wallAvailable() then local x,y=Story.wallSpot();add(x,y,58,.65,gold) end
 require('biome_radiance').sources(add,UI.clock)
 -- Keep source selection deterministic, so replay rendering stays repeatable.
 local limit=Graphics.quality==1 and 8 or 16
 while #L.lights>limit do table.remove(L.lights) end
 return L.lights
end
function L.resize(scene)
 local g=love.graphics
 local height=({150,200,300})[Graphics.quality]
 local width=math.ceil(height*Arena.width/600)
 if not L.map or L.map:getWidth()~=width or L.map:getHeight()~=height then
  if L.map then L.map:release() end
  L.map=g.newCanvas(width,height,{dpiscale=1});L.map:setFilter('linear','linear')
 end
 if not L.output or L.output:getWidth()~=scene:getWidth() or L.output:getHeight()~=scene:getHeight()
  or L.output:getDPIScale()~=scene:getDPIScale() then
  if L.output then L.output:release() end
  L.output=g.newCanvas(scene:getWidth(),scene:getHeight(),{dpiscale=scene:getDPIScale()})
  L.output:setFilter('linear','linear')
 end
 L.sourceShader=L.sourceShader or g.newShader('assets/shaders/world_light.glsl')
 L.composite=L.composite or g.newShader('assets/shaders/world_light_composite.glsl')
end
function L.renderMap()
 local g=love.graphics;local shader=L.sourceShader
 -- Large obstacles cast first; rotate each occluder in its own local space.
 local walls={}
 if App.state~='bossWorld' then
  for _,wall in ipairs(Arena.interior) do walls[#walls+1]=wall end
 end
 table.sort(walls,function(a,b)return a.w*a.h>b.w*b.h end)
 local count=math.min(24,#walls)
 for i=1,24 do
  local wall=walls[i]
  if wall then
   L.blockers[i]={wall.x+wall.w/2,wall.y+wall.h/2,wall.w/2,wall.h/2}
   local angle=(wall.rotation or 0)*math.pi/180;L.rotations[i]={math.cos(angle),math.sin(angle)}
  else L.blockers[i]={0,0,0,0};L.rotations[i]={1,0} end
 end
 shader:send('blockerCount',count);shader:send('blockers',unpack(L.blockers));shader:send('rotations',unpack(L.rotations))
 shader:send('arenaSize',{Arena.width,600})
 g.setCanvas(L.map);g.clear(0,0,0,1);g.origin();g.scale(L.map:getWidth()/Arena.width,L.map:getHeight()/600)
 g.setBlendMode('add','premultiplied');g.setColor(1,1,1)
 require('biome_radiance').drawMap();g.setShader(shader)
 for _,p in ipairs(L.lights) do
  shader:send('source',{p.x,p.y,p.radius,p.power});shader:send('lightColor',p.color)
  g.rectangle('fill',p.x-p.radius,p.y-p.radius,p.radius*2,p.radius*2)
 end
end
function L.apply(scene)
 L.collect()
 if #L.lights==0 and not require('biome_radiance').active() then return scene end
 L.resize(scene)
 local g=love.graphics;g.push('all');g.setScissor()
 L.renderMap()
 g.setCanvas(L.output);g.origin();g.clear();g.setColor(1,1,1);g.setBlendMode('replace','premultiplied')
 L.composite:send('lightMap',L.map);L.composite:send('lightStep',{1/L.map:getWidth(),1/L.map:getHeight()})
 local biome=require('biome_radiance').biome()
 local ambient=({[1]=.91,[2]=.91,[3]=.87,[4]=.88,[5]=.88,[6]=.91,[7]=1,[8]=.97})[biome] or .97
 L.composite:send('ambient',ambient)
 L.composite:send('scatter',biome==7 and 0 or biome==4 and .06 or biome==8 and .016 or .035)
 L.composite:send('softHighlights',biome~=7 and biome~=2 and require('biome_radiance').active() and 1 or 0)
 g.setShader(L.composite);g.draw(scene);g.pop()
 return L.output
end
return L
