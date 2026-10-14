local T={}
function T.run()
 love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.state='playing';App.sessionLayout=nil;Campaign.select(7);player.level=10;reset_level()
 require('mobs.bosses.abyss.arrival').finish(Abyss)
 player.x=400;player.y=300;player.reset=false
 local F=require('mobs.bosses.abyss.charged_fish')
 local function counts()
  local red,yellow=0,0
  for _,f in ipairs(Abyss.chargedFish) do if f.yellow then yellow=yellow+1 else red=red+1 end end
  return red,yellow
 end
 F.setup(Abyss)
 for n=1,6 do
  F.trigger(Abyss)
  local red,yellow=counts()
  assert(red==10 and yellow==(n>=3 and 2 or 0),'Yellow fish appear at three charges during the current wave, without stacking')
 end
 local source=Abyss.chargedFish[11]
 assert(source.yellow and math.abs(source.heading-math.atan2(312-source.y,415-source.x))<.0001,'Yellow fish aim at the original player position')
 local clone=function(f)local c={};for k,v in pairs(f) do c[k]=v end;return c end
 local kill=Hazards.kill;local hits=0;Hazards.kill=function()hits=hits+1 end
 local last=0
 for _,n in ipairs({1,2,3,6,12}) do
  local f={x=200,y=100,angle=0,delay=0,life=5,age=0,committed=true}
  local a={fishCharge=n,chargedFish={f}}
  F.update(a,.1,-1000,-1000)
  local travel=f.x-200
  assert(travel>last and math.abs(travel-F.speed(n)*.1)<.001,'Existing fish speed increases with each charge')
  last=travel
 end
 local left,right=clone(source),clone(source);left.delay=0;right.delay=0
 local a,b={fishCharge=3,chargedFish={left}},{fishCharge=3,chargedFish={right}}
 for _=1,45 do
  F.update(a,1/60,-2000,-2000);F.update(b,1/60,2000,2000)
  assert(math.abs(left.x-right.x)+math.abs(left.y-right.y)<.001,'Yellow path never follows a moving target')
  assert(left.heading==source.heading,'Yellow heading stays locked')
 end
 local function lateral(travel)
  local x,y=F.project(source,travel)
  return -(x-source.x)*math.sin(source.heading)+(y-source.y)*math.cos(source.heading)
 end
 assert(lateral(45)>30 and lateral(135)<-30,'Yellow fish zigzag to both sides of the fixed attack axis')
 local delayed=clone(source);delayed.delay=.5
 local delayedOwner={fishCharge=3,chargedFish={delayed}}
 F.update(delayedOwner,.25,-1000,-1000);assert(delayed.x==source.x and delayed.y==source.y,'Warning delay prevents early movement')
 F.update(delayedOwner,.5,-1000,-1000)
 assert(math.abs(delayed.distance-F.speed(3,true)*.25)<.001,'Movement uses only time after the warning')
 local fast={x=100,y=100,angle=0,delay=0,life=5,age=0,committed=true}
 F.update({fishCharge=20,chargedFish={fast}},.3,300,100)
 assert(hits>0,'High-charge fish cannot skip player collisions')
 local yellow=clone(source);yellow.delay=0
 local owner={fishCharge=3,chargedFish={yellow}}
 F.update(owner,6,-2000,-2000);assert(#owner.chargedFish==0,'Yellow fish leave the arena and expire')
 F.setup(Abyss);F.update(Abyss,0,415,312)
 assert(#Abyss.chargedFish==0 and player.charges==0 and player.illuminated==0,'Reset clears charges and both fish types')
 Hazards.kill=kill
 print('PASS charge pressure: threshold, no stacking, speed scaling, fixed zigzag paths, delays, fast collisions and cleanup')
 love.event.quit()
end
return T
