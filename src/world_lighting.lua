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
 -- Abyss lighting also controls gameplay visibility and keeps its own renderer.
 if not Graphics.effects or App.state=='playing' and (Campaign.biome==7 or Abyss.playerHidden() or Abyss.encounterActive()) then return L.lights end
 if App.state=='bossWorld' or Secret.inArena() then
  require('biome_radiance').sources(add,UI.clock);return L.lights
 end
 local time=Realms.clock or 0
 local function storm(boss)
  if not boss.active or boss.defeated then return end
  for _,p in ipairs(boss.pickups or {}) do
   if not p.invalid and p.cooldown<=0 then add(p.x,p.y,80,.35,blue) end
  end
  if (boss.charges or 0)>0 then add(player.x+15,player.y+12,75+boss.charges*30,.20*boss.charges,blue) end
  for _,p in ipairs(boss.strikes or {}) do
   if p.age>=0 and p.age<.85 then add(p.x,p.y,80,p.age/.85*.22,gold)
   elseif p.age>=.85 and Campaign.biome~=6 then add(p.x,p.y,330,math.max(0,1-(p.age-.85)/.5)*.8,gold) end
  end
 end
 storm(Storm)
 for _,item in ipairs(Bosses.items or {}) do if item.kind=='storm' then storm(item.boss) end end
 for _,p in ipairs(Hazards.lava) do
  add(p.x,p.y,math.max(p.rx,p.ry)*3+75,1.1,fire)
 end
 for _,p in ipairs(Magma.pools or {}) do
  add(p.x,p.y,130,.5*pulse(time,p.x),fire)
 end
 for _,m in ipairs(mobs) do if not m.dead and not m.abyssHeld and not m.spent then
  local dx,dy=require('render_motion').offset(m)
  if m.type=='lanternfish' then add(m.x+dx,m.y+dy-15,145,.65,gold)
  elseif Campaign.biome==1 and m.type=='ange' then add(m.x+dx,m.y+dy,105,.24,gold)
  elseif Campaign.biome==2 and m.type=='lava_scorpion' then add(m.x+dx,m.y+dy,85,.25,fire)
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
 -- Reserve a fixed transient budget: explosions must never evict lava lights.
 local limit=Graphics.quality==1 and 8 or 16
 local transientSlots=Graphics.quality==1 and 2 or 4
 while #L.lights>limit-transientSlots do table.remove(L.lights) end
 local function burst(x,y,radius,power,color)
  if #L.lights<limit then add(x,y,radius,power,color) end
 end
 for _,p in ipairs(Magma.bursts or {}) do
  burst(p.x,p.y,125,math.max(0,1-p.age/.55)^2*.45,fire)
 end
 for _,p in ipairs(BossFX.events or {}) do
  burst(p.x,p.y,110+(p.power or 3)*25,math.max(0,1-p.age/.4)^2*.65,p.color)
 end
 for _,p in ipairs(require('storm_lightning').events) do
  burst(p.x,p.y,430,math.max(0,1-p.age/.55)*.85,{.65,.79,1})
 end
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
 for _,key in ipairs({'bloomA','bloomB','emissionMask'}) do
  if not L[key] or L[key]:getWidth()~=width or L[key]:getHeight()~=height then
   if L[key] then L[key]:release() end
   L[key]=g.newCanvas(width,height,{dpiscale=1});L[key]:setFilter('linear','linear')
  end
 end
 L.bloomShader=L.bloomShader or g.newShader('assets/shaders/soft_bloom.glsl')
 L.sourceShader=L.sourceShader or g.newShader('assets/shaders/world_light.glsl')
 L.composite=L.composite or g.newShader('assets/shaders/world_light_composite.glsl')
end
-- Molten terrain keeps its own emission independently of explosion flashes.
function L.renderEmissionMask()
 local g=love.graphics;g.push('all');g.setCanvas(L.emissionMask);g.origin();g.setShader();g.clear(0,0,0,1)
 g.scale(L.emissionMask:getWidth()/Arena.width,L.emissionMask:getHeight()/600)
 g.setBlendMode('replace','premultiplied');g.setColor(1,1,1,1)
 if Campaign.biome==2 and App.state=='playing' then
  for _,p in ipairs(Hazards.lava) do
   if p.points then require('ground_holes').draw(p) else g.ellipse('fill',p.x,p.y,p.rx,p.ry) end
  end
  g.setColor(0,0,0,1)
  for _,r in ipairs(Arena.interior) do
   g.push();g.translate(r.x+r.w/2,r.y+r.h/2);g.rotate((r.rotation or 0)*math.pi/180)
   g.rectangle('fill',-r.w/2,-r.h/2,r.w,r.h);g.pop()
  end
 end
 g.pop()
end
-- Preserve the original sort and occluder values, rebuilding only on edits.
function L.prepareBlockers()
 local walls=App.state~='bossWorld' and Arena.interior or {}
 local snapshot=L.wallSnapshot;local changed=not snapshot or #snapshot~=#walls
 if not changed then for i,wall in ipairs(walls) do
  local old=snapshot[i]
  if old.wall~=wall or old.x~=wall.x or old.y~=wall.y or old.w~=wall.w or old.h~=wall.h or old.rotation~=wall.rotation then changed=true;break end
 end end
 if not changed then return L.blockerCount end
 L.wallSnapshot={};local sorted={}
 for i,wall in ipairs(walls) do
  L.wallSnapshot[i]={wall=wall,x=wall.x,y=wall.y,w=wall.w,h=wall.h,rotation=wall.rotation};sorted[i]=wall
 end
 table.sort(sorted,function(a,b)return a.w*a.h>b.w*b.h end)
 L.blockerCount=math.min(24,#sorted)
 for i=1,24 do
  local wall=sorted[i]
  if wall then
   L.blockers[i]={wall.x+wall.w/2,wall.y+wall.h/2,wall.w/2,wall.h/2}
   local angle=(wall.rotation or 0)*math.pi/180;L.rotations[i]={math.cos(angle),math.sin(angle)}
  else L.blockers[i]={0,0,0,0};L.rotations[i]={1,0} end
 end
 return L.blockerCount
end
function L.renderMap()
 local g=love.graphics;local shader=L.sourceShader
 local count=L.prepareBlockers()
 shader:send('blockerCount',count);shader:send('blockers',unpack(L.blockers));shader:send('rotations',unpack(L.rotations))
 shader:send('arenaSize',{Arena.width,600})
 g.setCanvas(L.map);g.clear(0,0,0,1);g.origin();g.scale(L.map:getWidth()/Arena.width,L.map:getHeight()/600)
 g.setBlendMode('add','premultiplied');g.setColor(1,1,1)
 require('biome_radiance').drawMap(count,L.blockers,L.rotations);g.setShader(shader)
 for _,p in ipairs(L.lights) do
  shader:send('source',{p.x,p.y,p.radius,p.power*(require('biome_radiance').biome()==3 and 1.65 or .55)});shader:send('lightColor',p.color)
  g.rectangle('fill',p.x-p.radius,p.y-p.radius,p.radius*2,p.radius*2)
 end
end
-- Two small separable passes: no full-resolution blur and no scene geometry rebuild.
function L.renderBloom(scene)
 local g=love.graphics;local w,h=L.bloomA:getDimensions()
 g.origin();g.setShader(L.bloomShader);g.setColor(1,1,1);g.setBlendMode('replace','premultiplied')
 g.setCanvas(L.bloomA);g.clear()
 L.bloomShader:send('extract',1);L.bloomShader:send('direction',{1/w,0})
 g.draw(scene,0,0,0,w/scene:getWidth(),h/scene:getHeight())
 g.setCanvas(L.bloomB);g.clear()
 L.bloomShader:send('extract',0);L.bloomShader:send('direction',{0,1/h})
 g.draw(L.bloomA)
end
function L.apply(scene)
 L.collect()
 if #L.lights==0 and not require('biome_radiance').active() then return scene end
 L.resize(scene)
 local g=love.graphics;g.push('all');g.setScissor()
 L.renderMap()
 L.renderEmissionMask()
 L.renderBloom(scene)
 g.setCanvas(L.output);g.origin();g.clear();g.setColor(1,1,1);g.setBlendMode('replace','premultiplied')
 L.composite:send('emissionMask',L.emissionMask)
 L.composite:send('lightMap',L.map);L.composite:send('lightStep',{1/L.map:getWidth(),1/L.map:getHeight()})
 local biome=require('biome_radiance').biome()
 local ambient=biome==3 and .67 or biome==6 and 1 or .96
 L.composite:send('ambient',ambient)
 L.composite:send('bloomMap',L.bloomB)
 L.composite:send('bloomStrength',biome==3 and .28 or biome==6 and .10 or .07)
 L.composite:send('preserveEmbers',biome==2 and 1 or 0)
 L.composite:send('scatter',biome==3 and .16 or .02)
 L.composite:send('softHighlights',biome==3 and 1 or 0)
 g.setShader(L.composite);g.draw(scene);g.pop()
 return L.output
end
return L
