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
 for _,world in ipairs({1,2,3,4,5,6,7,9}) do
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
  print('PASS biome '..world..': visible lights, three quality levels, animation and simulation isolation')
 end
 App.practice=5;App.start(7);Graphics.effects=true
 local black=g.newCanvas(Arena.width,600)
 g.push('all');g.setCanvas(black);g.clear(0,0,0,1);g.pop()
 local dark=apply(black):newImageData();local r,green,b=dark:getPixel(100,100)
 assert(r==0 and green==0 and b==0,'Abyss lighting must not reveal completely dark surfaces');dark:release()
 local hidden=Abyss.playerHidden;Abyss.playerHidden=function()return true end
 assert(apply(black)==black and #L.lights==0,'Hidden Abyss phases must bypass decorative light')
 Abyss.playerHidden=hidden;black:release()
 for _,world in ipairs(Worlds.order) do Profile.completed[world]=true end
 Secret.open(false);love.draw();local hall=rendered:newImageData();hall:encode('png','radiance-sanctuary.png');hall:release()
 assert(B.biome()==8 and #L.lights==2,'Sanctuary lobby receives its own lights without stale gameplay sources')
 L.apply=apply;Graphics.quality=2
 print('PASS all biomes, Sanctuary, hidden Abyss phases and preserved darkness');love.event.quit()
end
return T
