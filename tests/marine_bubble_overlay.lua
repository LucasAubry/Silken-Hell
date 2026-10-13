local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 Profile.completed={};Profile.scores={};Profile.skinGrants={};Profile.skinEffects={}
 Profile.achievements={flawless_all=true};Profile.unlocked=8
 for _,world in ipairs(Worlds.order) do Profile.completed[world]=true end
 for index=1,#Characters.keys do Profile.skinGrants[tostring(index)]=true end
 -- Same lure geometry in front/back/right; left is the matching mirrored curve.
 local g=love.graphics;local lure=g.newCanvas(96,96,{dpiscale=1})
 local reference
 for _,pose in ipairs({'down','up','right'}) do
  g.push('all');g.setCanvas(lure);g.clear();g.origin()
  Ocean.drawLantern(48,55,12,0,false,1,pose)
  g.pop();local pixels=lure:newImageData();local visible=0
  for y=0,95 do for x=0,95 do
   local _,_,_,a=pixels:getPixel(x,y);if a>0 then visible=visible+1 end
   if reference then
    local r,green,b,alpha=pixels:getPixel(x,y)
    local rr,gg,bb,aa=reference:getPixel(x,y)
    assert(r==rr and green==gg and b==bb and alpha==aa,'Lantern design is identical across poses')
   end
  end end
  assert(visible>20,'The same small lure is visible in every pose')
  if not reference then reference=pixels else pixels:release() end
 end
 reference:release();lure:release()
 for _,dir in ipairs({'down','up','left','right'}) do
  local x,y,r=Ocean.headPosition(0,0,59,dir,10)
  local lx,ly=Ocean.lanternPosition(x,y,r,0,dir)
  assert(math.abs(lx-x)<=r and y-ly<r*1.3,'The lure stays small and close to the head')
  if dir=='up' then assert(y<0,'Back-facing bubble follows the upper head') end
 end
 local draw,overlay=Characters.draw,Ocean.drawAt
 local seen,bubbles=0,0;local insideSkin=false
 Characters.draw=function(...)
  seen=seen+1;insideSkin=true;local result=draw(...);insideSkin=false;return result
 end
 Ocean.drawAt=function(x,y,r,clock,lantern,...)
  -- The reward preview now also displays accessories; count only the map marker.
  if App.state=='worlds' and not insideSkin and math.abs(x-(WorldMap.x or 365))>2 then return overlay(x,y,r,clock,lantern,...) end
  assert(seen>0,'The marine bubble must be drawn after the skin')
  local world=App.state=='worlds' and App.selectedWorld or Campaign.biome
  assert(lantern==(world==7),'The lantern exists only in the Abyss, in game and on the map')
  assert(r<18,'The bubble encloses only the head')
  if App.state=='worlds' and not insideSkin then
   assert(y>WorldMap.y-WorldMap.scroll,'The front-view head sits below the body center')
  end
  bubbles=bubbles+1;return overlay(x,y,r,clock,lantern,...)
 end
 for _,world in ipairs({4,7}) do
  App.singleLevel=true;App.practice=1;App.hardcore=false;App.start(world);App.practice=nil
  player.reset=false;require('run_start').active=false
  for skin=1,#Characters.keys do
   Profile.character=skin
   for _,dir in ipairs({'up','down','left','right'}) do
    direction=dir;seen,bubbles=0,0;love.draw()
    assert(bubbles==(require('integrated_skins').bubble(skin) and 0 or 1),'No extra overlay over the PNG bubble')
   end
  end
 end
 for _,world in ipairs({1,4,7,5}) do
  App.selectedWorld=world;WorldMap.hardcore=false;WorldMap.open()
  for skin=1,#Characters.keys do
   Profile.character=skin;seen,bubbles=0,0;love.draw()
   local base=Characters.crowned[skin] or skin
   local bubble=(world==4 or world==7) and not require('integrated_skins').bubble(base)
   assert(bubbles==(bubble and 1 or 0),'Marine markers and Ocean skins keep exactly one bubble')
  end
 end
 Characters.draw,Ocean.drawAt=draw,overlay
 -- Inspect the actual darkness uniforms with other light sources removed.
 App.singleLevel=true;App.practice=1;App.start(7);App.practice=nil
 player.reset=false;require('run_start').active=false;direction='down'
 local savedMobs,savedVents=mobs,Realms.vents;mobs={};Realms.vents={}
 local addA,addB,addT=Abyss.addLights,Bosses.addLights,AbyssTerrain.addLights
 Abyss.addLights=function()end;Bosses.addLights=function()end;AbyssTerrain.addLights=function()end
 Realms.drawDarkness()
 local shader,setShader=Realms.darkShader,love.graphics.setShader
 local lights;local proxy={send=function(_,name,...)
  if name=='lights' then lights={...} end
  return shader:send(name,...)
 end}
 Realms.darkShader=proxy
 love.graphics.setShader=function(value)return setShader(value==proxy and shader or value)end
 for _,dir in ipairs({'up','down','left','right'}) do
  direction=dir
  for charges=0,3 do
   player.charges=charges;player.illuminated=charges>0 and 1 or 0
   Realms.drawDarkness()
   local lx,ly=Ocean.lightPosition();local active=0
   for _,light in ipairs(lights) do if light[4]>0 then
    active=active+1
    assert(math.abs(light[1]-lx)<1e-6 and math.abs(light[2]-ly)<1e-6,'Player light originates at the lantern')
   end end
   assert(active==1,'No second light at the body or bubble')
  end
 end
 player.abyssHeld={};Realms.drawDarkness()
 for _,light in ipairs(lights) do assert(light[4]==0,'Hidden lantern emits no player light') end
 player.abyssHeld=nil;player.charges=0;player.illuminated=0
 Realms.darkShader=shader;love.graphics.setShader=setShader
 Abyss.addLights,Bosses.addLights,AbyssTerrain.addLights=addA,addB,addT;mobs,Realms.vents=savedMobs,savedVents
 print('PASS marine overlays: 26 skins, head-sized bubbles, Abyss-only lantern, single lantern light source in all directions and charge states')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 or tick==3 then
   App.selectedWorld=tick==1 and 4 or 7;Profile.character=tick==1 and 1 or 23
   WorldMap.hardcore=false;WorldMap.open();App.capture='marine-map-'..App.selectedWorld..'.png'
  elseif tick==5 or tick==7 then
   App.singleLevel=true;App.practice=1;App.start(tick==5 and 4 or 7);App.practice=nil
   player.reset=false;require('run_start').active=false;direction='down'
   App.capture='marine-overlay-'..Campaign.biome..'.png'
  elseif tick==9 then love.event.quit() end
 end
end
return T
