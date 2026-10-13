local T={}
function T.run()
 local A=Audio;Profile.sound=0;Profile.music=0
 for _,id in ipairs({2,3,6}) do local s=assert(A.ambiences[id]);assert(s:isLooping() and s:getDuration()>100);s:stop() end
 for _,name in ipairs({'notice','inkStep','inkSpit','abyssSwallow'}) do local s=assert(A[name]);assert(not s:isLooping() and s:getDuration()>0);s:stop() end
 local actualAmbiences,actualMenu=A.ambiences,A.paradise
 local function source()
  return {plays=0,stops=0,playing=false,setVolume=function(s,v)s.volume=v end,
   isPlaying=function(s)return s.playing end,play=function(s)s.plays=s.plays+1;s.playing=true end,
   stop=function(s)s.stops=s.stops+1;s.playing=false end,pause=function(s)s.playing=false;s.paused=true end}
 end
 A.ambiences={[2]=source(),[3]=source(),[6]=source()};A.paradise=source();A.focused=true
 local p={sound=.37,music=.18};App.state='playing';Campaign.biome=6
 A.update(p);A.update(p);assert(A.ambiences[6].plays==1 and math.abs(A.ambiences[6].volume-.037)<.00001 and not A.ambiences[2].playing)
 App.state='pause';A.update(p);assert(not A.ambiences[6].playing and A.ambiences[6].paused)
 App.state='playing';A.update(p);assert(A.ambiences[6].plays==2)
 Campaign.biome=2;A.update(p);assert(A.ambiences[2].playing and not A.ambiences[6].playing)
 A.focus(false);assert(not A.ambiences[2].playing);A.update(p);assert(not A.ambiences[2].playing)
 A.focus(true);A.update(p);assert(A.ambiences[2].playing)
 Campaign.biome=3;Campaign.world=3;player.level=1;A.update(p);assert(not A.ambiences[3].playing and not A.ambiences[2].playing,'No birds during the Renaissance boss')
 player.level=2;A.update(p);assert(A.ambiences[3].playing,'Birds start in the reunion level')
 App.state='pause';A.update(p);assert(A.ambiences[3].paused and not A.ambiences[3].playing)
 App.state='playing';A.update(p);assert(A.ambiences[3].playing)
 player.level=1;A.update(p);assert(not A.ambiences[3].playing,'Returning to the boss stops birds')
 Campaign.world=8;player.level=2;A.update(p);assert(not A.ambiences[3].playing,'Birds are exclusive to Renaissance level 2')
 Campaign.world=3;A.update(p);assert(A.ambiences[3].playing)
 App.state='menu';A.update(p);assert(A.paradise.playing and not A.ambiences[3].playing)
 A.ambiences=actualAmbiences;A.paradise=actualMenu
 local sounds={};local play=A.play
 A.play=function(name)sounds[#sounds+1]=name end
 local state={};A.inkContact(state,true,0,0);A.inkContact(state,true,0,0);A.inkContact(state,true,10,0);assert(#sounds==1)
 A.inkContact(state,true,24,0);assert(#sounds==2);A.inkContact(state,false,24,0);A.inkContact(state,true,24,0);assert(#sounds==3)
 local N=require('achievement_notice');local D=require('discovery_notice');local card=require('notice_card');local draw=card.draw;card.draw=function()end
 Replay.playing=false;App.preview=false;App.sessionLayout=nil;require('run_start').active=nil
 N.init();D.active=nil;D.queue={};sounds={};App.state='settings';N.queue={Achievements.list[1],Achievements.list[2]}
 N.update(.1);N.draw();N.update(10);assert(#sounds==0 and N.active.age==0,'Hidden cards never sound or expire')
 App.state='menu';N.update(.1);N.draw();N.draw();assert(#sounds==1 and sounds[1]=='notice','First card sounds once when drawn')
 N.update(3.6);N.draw();assert(#sounds==1,'Queued card has not appeared yet');N.update(.1);N.draw();assert(#sounds==2)
 App.state='playing';D.queue={{id='crab',name='Crabe'}};D.update(.1);assert(not D.active,'Discoveries wait for the current achievement')
 N.update(3.6);D.update(.1);assert(D.active);N.queue={Achievements.list[3]};N.update(.1);assert(not N.active,'Achievements wait for the discovery')
 D.update(.1);D.draw();D.draw();assert(#sounds==3)
 App.state='pause';local age=D.active.age;D.update(8);D.draw();assert(D.active.age==age and #sounds==3)
 App.state='playing';D.update(3.6);N.update(.1);N.update(.1);N.draw();assert(#sounds==4)
 N.active=nil;N.queue={};D.active=nil;D.queue={};card.draw=draw
 -- Gameplay hooks fire on transitions, not every update or every ink pool.
 sounds={};Octopus.reset(false);Octopus.ink();assert(sounds[1]=='inkSpit' and #Octopus.projectiles==1)
 Octopus.projectiles={};Octopus.inkPools={{x=100,y=100,rx=38,ry=27,life=7}};player.x=85;player.y=88;player.reset=false
 Octopus.updateInk(.01);local n=#sounds;Octopus.updateInk(.01);assert(#sounds==n and sounds[n]=='inkStep')
 local crab={x=100,y=100};Octopus.inkCrab(crab,.01);assert(crab.inked and sounds[#sounds]=='inkStep');n=#sounds;Octopus.inkCrab(crab,.01);assert(#sounds==n)
 local cycle=require('mobs.bosses.abyss.pattern_cycle');local mouth=cycle.mouth;local burst=BossFX.burst
 cycle.mouth=function()return 100,100 end;BossFX.burst=function()end
 local boss={};player.x=85;player.y=88;cycle.suction(boss,.01);assert(boss.absorbed and sounds[#sounds]=='abyssSwallow');n=#sounds;cycle.suction(boss,.01);assert(#sounds==n)
 cycle.mouth=mouth;BossFX.burst=burst;A.play=play
 -- Repeated nearby crabs cannot restart the same sound every simulation tick.
 local clip=A.inkStep;local fake=source();A.inkStep=fake;A.nextInkStep=nil
 A.play('inkStep');A.play('inkStep');assert(fake.plays==1);A.inkStep=clip
 A.focus(false)
 local g=love.graphics;local canvas=g.newCanvas(1200,210,{dpiscale=1})
 local function capture(file,render)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear(.012,.024,.038);render();g.pop()
  local pixels=canvas:newImageData();pixels:encode('png',file);pixels:release()
 end
 App.state='menu';N.active={entry=Achievements.list[1],age=.5,sounded=true};D.active=nil
 capture('audio-achievement-notice.png',N.draw)
 N.active=nil;local crabEntry;for _,e in ipairs(Bestiary.entries) do if e.id=='crab' then crabEntry=e end end
 App.state='playing';D.active={entry=crabEntry,age=.5,sounded=true}
 capture('audio-discovery-notice.png',D.draw);D.active=nil
 print('PASS audio: seven decoded clips, three streamed loops, biome/pause/focus/volume lifecycle, sequential visible-only notification sounds, ink steps/spit and single swallow triggers')
 love.event.quit()
end
return T
