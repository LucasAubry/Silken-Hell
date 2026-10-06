local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 App.singleLevel=true;App.practice=10;App.start(6);player.reset=false
 local R=require 'sky_rain';local b=Storm;local kill=Hazards.kill;local hits=0
 Hazards.kill=function()hits=hits+1 end
 player.x=485;player.y=288
 local p={x=500,y=300,age=0};local drops={p}
 local originalMobs=mobs;local hit={type='gull',x=500,y=300};local outside={type='gull',x=525,y=300};local dead={type='gull',x=500,y=300,dead=true};mobs={hit,outside,dead}
 R.update(drops,.84);assert(not hit.electric,'Telegraph does not electrify early');assert(hits==0,'Rain warning must be safe until the visible landing')
 R.update(drops,.011);assert(hits==1,'Damage starts exactly when the drop lands')
 assert(hit.electric and not outside.electric and not dead.electric,'Only live gulls inside the strike become electric')
 local late={type='gull',x=500,y=300};mobs[#mobs+1]=late
 p.age=1.21;R.update(drops,.01);assert(hits==1,'Fading impact is harmless')
 assert(not late.electric,'Fading bolt is harmless to gulls');mobs=originalMobs
 for _,offset in ipairs({{24.1,0},{0,12.1},{25,13}}) do
  player.x=485+offset[1];player.y=288+offset[2];R.update({{x=500,y=300,age=.9}},.01)
 end
 assert(hits==1,'Outside the drawn landing ellipse is safe')
 player.x=485;player.y=288;R.update({{x=500,y=300,age=.8}},.5)
 assert(hits==2,'A long update cannot skip the impact')
 R.update(drops,1);assert(#drops==0,'Rain expires')
 local lastCount,lastInterval=0,math.huge
 for hp=10,1,-1 do
  b.hp=hp;b.rain={};local count,interval=b.rainSettings();b.summonRain()
  assert(count>=lastCount and interval<=lastInterval,'Rain grows progressively with lost HP')
  assert(#b.rain==count and b.rainClock==interval,'Actual waves use the HP settings')
  for i,p in ipairs(b.rain) do
   assert(not Arena.blocked(p.x-24,p.y-12,48,24),'Landing site is on usable ground')
   for j=1,i-1 do local q=b.rain[j];assert((p.x-q.x)^2+(p.y-q.y)^2>=64^2,'Impacts do not overlap')end
  end
  lastCount,lastInterval=count,interval
 end
 b.hp=10;local c,interval=b.rainSettings();assert(c==1 and interval==2.2)
 b.hp=1;c,interval=b.rainSettings();assert(c==4 and interval<1.3)
 b.rain={};b.rainClock=0;b.setPhase('leave');b.update(.01);assert(#b.rain==0,'No new rain during a dash windup')
 b.reset(true);b.shot=100;b.bolt=100;b.rainClock=100;b.summon();b.update(.86)
 for _,hole in ipairs(b.holes) do assert(hole.r<=22,'Smaller lightning leaves smaller holes')end
 b.hp=1;b.hurt(true);assert(#b.rain==0,'Liberation clears rain')
 -- The user's authored arena has fixed rain sites: there must be no second rain stream.
 reset_level();player.reset=false
 Realms.rainSites={{x=170,y=170,phase=1},{x=340,y=340,phase=1},{x=510,y=170,phase=1},{x=680,y=340,phase=1}}
 Realms.rainClock=0;Realms.rain={};Realms.update(.01);assert(#Realms.rain==0,'Boss owns authored rain cadence')
 b.hp=1;b.summonRain();assert(#b.rain==4)
 for _,p in ipairs(b.rain) do local found=false;for _,site in ipairs(Realms.rainSites) do if p.x==site.x and p.y==site.y then found=true end end;assert(found,'Authored impact locations are preserved')end
 b.hurt(true);Realms.rainClock=0;Realms.update(.01);assert(#Realms.rain==0,'Authored rain cannot restart after boss death')
 Hazards.kill=kill
 print('PASS lightning replacement and gull electrification: impact timing, exact hit area, expiry, HP density and cadence, separated sites, dash pause, smaller strikes, liberation cleanup')
 -- Render actual menus and the boss arena, including the discreet version footer.
 local draw=love.draw;local step=0;local g=love.graphics
 local frames={'menu','worlds','rain-warning','rain-impact','rain-final','lightning','loading'}
 love.update=function()
  step=step+1;local name=frames[step];if not name then love.event.quit();return end
  if step<=2 then App.state=name
  elseif name=='loading' then require('texture_preload').begin()
  else
   if step==3 then reset_level();player.reset=false;player.x=450;player.y=380 end
   App.state='playing';b.strikes={};b.holes={};b.projectiles={};b.rain={};b.hp=step==5 and 1 or 10;b.summonRain()
   for _,p in ipairs(b.rain) do p.age=step==4 and .92 or .6 end
   if step==6 then b.rain={};b.strikes={{x=400,y=300,age=.94,seed=2}} end
  end
 end
 love.draw=function()
  local name=frames[step];if not name then return end
  if name=='loading' then require('texture_preload').draw() else draw()end
  g.captureScreenshot(function(data)local f=assert(io.open('/tmp/silken-'..name..'-revision.png','wb'));f:write(data:encode('png'):getString());f:close()end)
 end
end
return T
