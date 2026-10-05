local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 App.singleLevel=true;App.practice=10;App.start(6);player.reset=false
 local b=Storm;local kill=Hazards.kill;Hazards.kill=function()end
 for hp=10,1,-1 do
  b.reset(true);b.hp=hp;local size=hp>5 and 3 or 5
  for salvo=1,8 do
   local gold=0
   for i=1,size do b.fire();if b.projectiles[#b.projectiles].golden then gold=gold+1 end end
   assert(gold==2,'Two yellow feathers in every salvo at every HP')
  end
 end
 local FX=require 'mobs.bosses.encounter_fx'
 local points=FX.boltPoints(500,350,2,.55)
 for i=1,#points-2,2 do assert(FX.boltTouches(500,350,2,.55,(points[i]+points[i+2])/2,(points[i+1]+points[i+3])/2,1),'Collision follows the actual zigzag')end
 local function setup(golden,age)
  b.reset(true);b.shot=100;b.bolt=100;b.rainClock=100;player.x=80;player.y=500
  b.strikes={{x=500,y=350,seed=2,age=age,struck=true}}
  b.projectiles={{x=465,y=340,vx=800,vy=0,life=3,age=0,golden=golden}}
 end
 for _,golden in ipairs({false,true}) do
  setup(golden,.9);b.update(.05)
  assert(#b.projectiles==3,'A fast crossing replaces one feather with three')
  for i,p in ipairs(b.projectiles) do
   assert(p.split and p.golden==golden and math.abs(math.sqrt(p.vx*p.vx+p.vy*p.vy)-960)<.001)
   local q=b.projectiles[i%3+1];assert(math.abs((p.vx*q.vx+p.vy*q.vy)/(960*960)+.5)<.001,'Fragments diverge at 120 degrees')
   assert(not b.splitFeather(p),'Fragments cannot split recursively')
  end
  b.update(.01);assert(#b.projectiles==3,'Remaining inside the bolt cannot multiply fragments')
 end
 setup(false,.4);b.update(.05);assert(#b.projectiles==1 and not b.projectiles[1].split,'Lightning warning cannot split feathers')
 setup(false,1.35);b.update(.05);assert(#b.projectiles==1,'Expired lightning cannot split feathers')
 assert(not b.splitFeather({returned=true}),'Collected feathers keep their single homing hit')
 Hazards.kill=kill
 assert(Characters.playerWidth==59 and player.hitBox_width==30 and player.hitBox_height==24,'Very small visual reduction keeps the established body hitbox')
 local W=require 'brown_walk';local original=W.draw;local calls=0
 W.draw=function(...)calls=calls+1;return original(...)end
 player.walkMoving=true;player.walkPhase=1;player.reset=false
 for _,skin in ipairs({1,2,3,4,5,22}) do
  Profile.character=skin;local completed=Profile.hasCompleted;Profile.hasCompleted=function()return true end
  for _,dir in ipairs({'up','down','left','right'}) do local before=calls;draw_player(dir);assert(calls==before+1,'Actual gameplay renders animated legs for each skin and view')end
  Profile.hasCompleted=completed
 end
 W.draw=original;Profile.character=1;player.walkMoving=false
 assert(Art.images.original_down.image:getFilter()=='nearest','Pixel skin must stay sharp')
 print('PASS spider and feathers: smaller body, connected leg rig on six skins/four views, nearest filtering, constant gold, swept lightning intersection, three faster 120-degree fragments, no recursive splitting')
 -- Capture menu and a moving in-game player with a freshly split volley.
 local draw=love.draw;local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.state='menu';App.selectedWorld=6
  elseif tick==3 then App.start(6);setup(false,.9);b.update(.05);b.update(.08);player.walkMoving=true;player.walkPhase=1.2
  elseif tick==5 then player.walkPhase=3.3
  elseif tick==7 then love.event.quit()end
 end
 love.draw=function()
  draw()
  if tick==1 or tick==3 or tick==5 then
   local name=tick==1 and 'menu' or 'walk-'..tick
   love.graphics.captureScreenshot(function(data)local f=assert(io.open('/tmp/silken-spider-'..name..'.png','wb'));f:write(data:encode('png'):getString());f:close()end)
  end
 end
end
return T
