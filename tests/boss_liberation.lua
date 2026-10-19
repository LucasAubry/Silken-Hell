local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 local L=require('boss_liberation');local F=require('final_spider')
 local function start(world)
  App.practice=world==3 and 1 or 10;App.singleLevel=true;App.sessionLayout=nil;App.preview=false;Secret.duel=nil
  App.start(world);player.reset=false
  if world==6 then Bosses.reset();Storm.reset(true);Campaign.carrier=nil;objet.larme_dropped=true end
 end
 local function ground(b)
  local conductors=require('mobs.bosses.storm.conductors');conductors.place(b);b.charges=1;conductors.discharge(b,b.rods[1])
 end
 local cases={
  {'paradis',1,function()
   Raven.hp=1;Raven.inside=false
   Raven.chicks={{x=200,y=190,dir='down',age=1,kind='shooter'},{x=700,y=360,dir='left',age=1,kind='charger'}}
   player.x=Raven.x-15;player.y=Raven.y-12;player.dashing=true;Raven.contact();return Raven
  end},
  {'ciel',6,function()Storm.hp=1;Storm.charges=1;ground(Storm);return Storm end},
  {'terre',5,function()Hedgehog.hp=1;Hedgehog.finishRound();return Hedgehog end},
  {'ocean',4,function()
   Octopus.releaseCrabs();for _,c in ipairs(Octopus.crabs) do c.emerge=nil end
   Octopus.hp=1;Octopus.arms={1,0,0,0,0,0,0,0};Octopus.tearArm(1);return Octopus
  end},
  {'abysse',7,function()Abyss.hurt(10);return Abyss end},
  {'enfer',2,function()
   Wasp.hp=1;for i,b in ipairs(Wasp.bees) do b.hp=i==1 and 1 or 0;b.phase=i==1 and 'fatigued' or 'dead' end
   Wasp.fireLarva(Wasp.bees[1]);player.x=Wasp.bees[1].x-15;player.y=Wasp.bees[1].y-12;Wasp.contact();return Wasp
  end},
  {'renaissance',3,function()
   F.babies={};local heirs=require('queen_heirs');heirs.hatch(F,{x=250,y=340,seed=1});heirs.hatch(F,{x=600,y=420,seed=2})
   F.hp=1;F.damage();return F
  end},
 }
 for _,c in ipairs(cases) do
  start(c[2]);local b=c[3]();assert(L.busy() and b.defeated and b.liberating,c[1]..': real final hit starts liberation')
  assert(#L.events[1].threads>0);assert(objet.larme.taken and not Campaign.canCollect())
  local x,y,deaths,clock=player.x,player.y,player.death,timer
  local count=#mobs;Hazards.kill();assert(not player.reset and player.death==deaths)
  Aftermath.update(0);assert(not Aftermath.cleared and #mobs==count,'Actors survive until threads snap')
  for i=1,35 do App.simulate(.05) end
  assert(L.busy() and objet.larme.taken and not Campaign.canCollect(),'No early reward')
  assert(player.x==x and player.y==y and timer==clock,'Interlude freezes movement and scored clock')
  App.simulate(.25)
  assert(not L.busy() and not b.liberating and not objet.larme.taken and Campaign.canCollect(),c[1]..': reward follows rupture')
  assert(Aftermath.cleared and #mobs==0)
  assert(not Aftermath.canEnter() and Aftermath.portalScale()==0,'Portal starts closed')
  Aftermath.update(.9);assert(Aftermath.portalScale()>.4 and Aftermath.portalScale()<.6 and not Aftermath.canEnter(),'Portal grows progressively')
  Aftermath.update(.91);assert(Aftermath.canEnter() and Aftermath.portalScale()==1,'Portal opens after growth')
 end
 -- The final guardian now leads into the existing reunion through the tear.
 local record=Profile.record;Profile.record=function()end
 player.x=objet.larme.x;player.y=objet.larme.y;F.update(.01)
 assert(player.level==2 and Ending.active and not F.active,'Final tear opens reunion')
 player.x=Ending.partner.x-15;player.y=Ending.partner.y-12;Ending.update(.01)
 assert(App.state=='credits','Reunion still leads into credits')
 Ending.updateCredits(Ending.creditDuration()+1);assert(App.state=='victory','Credits retain final results')
 Profile.record=record
 start(6);Storm.hp=1;Storm.charges=1;ground(Storm);reset_level()
 assert(not L.busy() and not Storm.liberating and not Storm.defeated and objet.larme.taken,'Restart cancels pending reward')
 -- Multiple editor bosses cannot release the map reward prematurely.
 start(5);Bosses.load({{type='hedgehog',x=240,y=180},{type='hedgehog',x=600,y=180}},{},{})
 Hedgehog.active=false
 local a,b=Bosses.items[1].boss,Bosses.items[2].boss
 a.hp=1;a.finishRound();L.update(2);assert(not Campaign.canCollect() and not Aftermath.cleared)
 b.hp=1;b.finishRound();L.update(2);assert(Campaign.canCollect() and Aftermath.cleared)
 start(6);Graphics.effects=false;Storm.hp=1;Storm.charges=1;ground(Storm);L.update(2)
 assert(Campaign.canCollect(),'Reduced effects never block progression');Graphics.effects=true
 Secret.launch({kind='boss',name='Merle noir',world=6});
 local sky=Storm.active and Storm or Bosses.items[1].boss
 sky.hp=1;sky.charges=1;ground(sky);L.update(2);assert(Secret.duel and Campaign.canCollect(),'Sanctuary retains its collectible reward')
 Aftermath.update(1.81);player.x=objet.larme.x;player.y=objet.larme.y;App.simulate(.01);assert(App.state=='customVictory','Sanctuary duel ends after collection')
 Secret.duel=nil;LevelLayouts.disabled=true
 print('PASS liberation: all seven real defeats, delayed reward, protected actors/player, frozen clock, reset cancellation, editor bosses, reduced effects and final reunion')
 local shots={}
 for _,c in ipairs(cases) do
  shots[#shots+1]={name=c[1]..'-fils',run=function()start(c[2]);c[3]();L.update(.62)end}
  shots[#shots+1]={name=c[1]..'-rupture',run=function()L.update(.31)end}
  shots[#shots+1]={name=c[1]..'-portail',run=function()L.update(1.1);Aftermath.update(.9)end}
 end
 local tick=0;local draw=love.draw
 love.update=function()tick=tick+1;if shots[tick] then shots[tick].run()else love.event.quit()end end
 love.draw=function()
  draw()
  if shots[tick] then
   local path='/tmp/silken-liberation-'..shots[tick].name..'.png'
   love.graphics.captureScreenshot(function(data)local file=assert(io.open(path,'wb'));file:write(data:encode('png'):getString());file:close()end)
  end
 end
end
return T
