local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;Profile.name='Lucas';Profile.language='fr';LevelLayouts.disabled=true
 App.state='playing';Campaign.select(7);player.level=10;reset_level();if Abyss.arrival then require('mobs.bosses.abyss.arrival').finish(Abyss);require('mobs.bosses.abyss.ricochet').setup(Abyss) end;player.reset=false
 local R=require('mobs.bosses.abyss.ricochet');local H=require('mobs.bosses.abyss.hunt')
 local mx,my=Abyss.mouth();Abyss.biteCooldown=0;player.x=mx+95-15;player.y=my-12
 local _,speed,_,biting=H.update(Abyss,.01,player.x+15,player.y+12)
 assert(biting and Abyss.bite and speed==160,'Proximity starts a visible bite windup')
 local n=#Abyss.returnShots;R.fire(Abyss);assert(#Abyss.returnShots==n,'Bite blocks all firing')
 local color=Abyss.eyeColor();assert(color[1]==1 and color[2]<.1,'Biting eye is red')
 _,speed,_,biting=H.update(Abyss,.3,player.x+15,player.y+12);assert(biting and speed==570,'Bite accelerates after windup')
 Abyss.returnKnockTime=.4;H.update(Abyss,.01,player.x+15,player.y+12);assert(not Abyss.bite,'Successful hit interrupts bite')
 local request=Online.request;local calls={};Online.request=function(path,body,cb)calls[#calls+1]={path=path,body=body};cb({},200)end
 local row={id='test-map',owned=true};Workshop.star(row);assert(#calls==0,'Creator cannot vote in client')
 local S=require('workshop_stats');App.workshopMap=row;S.begin();assert(not S.run,'Creator tests are excluded')
 row.owned=false;timer=0;player.death=0;S.begin();assert(S.run)
 player.x=100;player.y=300;player.death=1;timer=4;S.death();S.death();assert(S.run.deaths==1,'Death recorded once')
 timer=12;App.state='customVictory';S.update(.01);assert(S.run.completed and S.pending[S.run.id].elapsed==12,'Completion captures elapsed time')
 S.pending={};S.run=nil;love.filesystem.remove('workshop-stats-outbox.json');Online.request=request
 local frame=0
 love.update=function()
  frame=frame+1
  if frame==1 then
   App.state='workshop';Workshop.stats={row={title='Ma carte'},data={sessions=25,players=12,deaths=84,completions=15,averageAttempts=4.8,averageTime=46,bestTime=19,hotspots={{zone='1:2:1',deaths=34},{zone='1:0:0',deaths=20}}}};App.capture='workshop-author-stats.png'
  elseif frame==3 then
   Workshop.stats=nil;App.state='playing';Campaign.select(7);player.level=10;reset_level();if Abyss.arrival then require('mobs.bosses.abyss.arrival').finish(Abyss);require('mobs.bosses.abyss.ricochet').setup(Abyss) end;player.reset=false;require('run_start').active=false
   Abyss.bite={age=.3};Abyss.open=true;Abyss.returnMouth=1;Abyss.buildBones();App.capture='abyss-bite-red-eye.png'
  elseif frame==5 then print('PASS reactive bite, firing suppression, red eye, recoil cancellation, creator voting and session telemetry');love.event.quit()end
 end
end
return T
