local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.skinEffects={};Profile.character=1;Graphics.showFPS=false
 local g=love.graphics;local L=require('world_lighting');local B=require('biome_radiance')
 local json=require('json');local apply,rendered=L.apply,nil
 L.apply=function(scene)rendered=apply(scene);return rendered end
 local function draw()
  local rng=love.math.getRandomState();local state=json.encode(LevelLayouts.snapshot());local x,y=player.x,player.y
  love.draw()
  assert(rng==love.math.getRandomState(),'Decorative light must preserve gameplay RNG')
  assert(state==json.encode(LevelLayouts.snapshot()) and player.x==x and player.y==y,'Scenery must preserve collisions and actors')
  assert(g.getCanvas()==nil,'Light passes must restore canvas state')
  return rendered:newImageData()
 end
 for _,world in ipairs({1,2,3,4,5,6,9}) do
  App.practice=world==3 and 2 or world==9 and 1 or 5;App.singleLevel=true;App.start(world);require('run_start').active=false
  UI.clock=4;Realms.clock=4
  Graphics.quality=2;Graphics.effects=false
  assert(not B.active());local before=draw();before:encode('png','radiance-'..world..'-off.png')
  Graphics.effects=true;assert(B.active())
  local after=draw();after:encode('png','radiance-'..world..'.png')
  local difference=0;local w,h=after:getDimensions()
  for y=10,h-10,30 do for x=10,w-10,30 do
   local r,g,b=after:getPixel(x,y);local rr,gg,bb=before:getPixel(x,y)
   difference=difference+math.abs(r-rr)+math.abs(g-gg)+math.abs(b-bb)
  end end
  assert(difference>1,'Each requested biome needs visible lighting')
  before:release();after:release()
  for _,quality in ipairs({1,3}) do
   Graphics.quality=quality;local data=draw();data:release()
   assert(#L.lights<= (quality==1 and 8 or 16),'Light budget must remain bounded')
  end
  UI.clock=12;local data=draw();data:release()
  if world==1 or world==2 or world==3 or world==5 then
   local frame=require(world==1 and 'paradise_frame' or world==2 and 'hell_frame' or world==3 and 'renaissance_frame' or 'earth_frame');local canvas=g.newCanvas(Arena.width,600)
   local function foliage(time,effects)
    UI.clock=time;Graphics.effects=effects
    g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0)
    frame.draw();g.pop()
    return canvas:newImageData()
   end
   local first=foliage(0,true);local baked=frame.canvas
   local second=foliage(2,true)
   assert(first:getString()~=second:getString(),'Foreground foliage must sway with time')
   assert(frame.canvas==baked,'Animation must reuse baked foliage')
   first:release();second:release()
   first=foliage(0,false);second=foliage(2,false)
   assert(first:getString()==second:getString(),'Disabled effects must keep foliage still')
   first:release();second:release();canvas:release();Graphics.effects=true
   print('PASS biome '..world..' foreground: animated, cached, stationary with effects disabled')
  end
  print('PASS biome '..world..': visible lights, three quality levels, animation and simulation isolation')
 end
 -- Restore the pre-radiance renderer in every Abyss level, not just the boss.
 for level=1,10 do
  App.practice=level;App.start(7);Graphics.effects=true
  local scene=g.newCanvas(Arena.width,600)
  for quality=1,3 do
   Graphics.quality=quality
   assert(not B.active(),'Abyss uses only its original decorative effects')
   assert(apply(scene)==scene and #L.lights==0,'Abyss scene bypasses all new light compositing')
  end
  local data=draw();data:encode('png','legacy-abyss-'..level..'.png');data:release();scene:release()
 end
 App.practice=5;App.start(7);Graphics.effects=true
 local black=g.newCanvas(Arena.width,600)
 g.push('all');g.setCanvas(black);g.clear(0,0,0,1);g.pop()
 local dark=apply(black):newImageData();local r,green,b=dark:getPixel(100,100)
 assert(r==0 and green==0 and b==0,'Abyss lighting must not reveal completely dark surfaces');dark:release()
 local hidden=Abyss.playerHidden;Abyss.playerHidden=function()return true end
 assert(apply(black)==black and #L.lights==0,'Hidden Abyss phases must bypass decorative light')
 Abyss.playerHidden=hidden;black:release()
 -- New decorative passes must not recolor the boss's original charge lighting.
 App.practice=10;App.start(7);Graphics.effects=true
 Abyss.playerHidden=function()return false end
 local scene=g.newCanvas(Arena.width,600)
 for _,quality in ipairs({1,2,3}) do
  Graphics.quality=quality
  assert(Abyss.encounterActive() and not B.active(),'Abyss boss keeps its original lighting')
  assert(apply(scene)==scene and #L.lights==0,'Boss scene bypasses decorative compositing')
 end
 Abyss.defeated=true
 assert(not B.active() and apply(scene)==scene,'Original Abyss lighting remains after the boss is defeated')
 Abyss.defeated=false
 App.practice=5;App.start(6)
 Bosses.load({{type='skeleton_fish',x=200,y=300,skeletonStage=10}},{},{})
 assert(Abyss.encounterActive() and not B.active() and apply(scene)==scene,'Custom Abyss encounters also keep their original lighting')
 Bosses.reset();scene:release();Abyss.playerHidden=hidden
 print('PASS visible Abyss bosses bypass decorative light at every quality, including custom encounters')
 for _,world in ipairs(Worlds.order) do Profile.completed[world]=true end
 Secret.open(false);love.draw();local hall=rendered:newImageData();hall:encode('png','radiance-sanctuary.png');hall:release()
 assert(B.biome()==8 and #L.lights==2,'Sanctuary lobby receives its own lights without stale gameplay sources')
 L.apply=apply;Graphics.quality=2
 print('PASS other biomes and Sanctuary lighting; original Abyss rendering across all ten levels, three qualities, boss defeat and custom encounters');love.event.quit()
end
return T
