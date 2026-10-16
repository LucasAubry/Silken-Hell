local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 local function start(world,layout)
  App.sessionLayout=layout;App.singleLevel=true;App.practice=1;App.start(world);App.practice=nil
  require('run_start').active=false;player.reset=false;player.abyssGrace=0
 end
 local g=love.graphics;local json=require('json')
 start(2,{world=2,level=1,width=960,height=600,entities={{kind='spawn',x=180,y=280},{kind='wall',x=350,y=300,w=24,h=260},{kind='tear',x=800,y=500}}})
 Walls={};assert(willCollide(340,280),'Player collisions must use the rendered arena after an authored load')
 local move,slow=Input.move,Input.slow;Input.move=function()return 1,0 end;Input.slow=function()return false end
 App.move(.8);assert(player.x<330,'A long dash cannot pass through a Hell wall');Input.move,Input.slow=move,slow
 start(6);local weather=require('sky_weather');weather.storm=false
 weather.fog(400,300);weather.fog(450,300);for _,p in ipairs(weather.mist) do p.age=1 end
 weather.warn(400,300);player.x=100;player.y=100;weather.update(1.61)
 assert(weather.fogCleared(400,300) and not weather.fogCleared(500,300))
 player.x=385;player.y=288;assert(not weather.playerHidden(),'Lightning tears a visible opening through the fog')
 assert(weather.fallAt(400,300),'The ground hole remains dangerous under cleared fog')
 player.x=465;weather.contact();assert(not player.reset,'Smoke is no longer electrified')
 local moth=mobs[2];local minX,maxX,minY,maxY=moth.x,moth.x,moth.y,moth.y
 for i=1,3600 do
  require('mobs.sky_insects').update(moth,1/60)
  minX=math.min(minX,moth.x);maxX=math.max(maxX,moth.x);minY=math.min(minY,moth.y);maxY=math.max(maxY,moth.y)
 end
 assert(maxX-minX>Arena.width*.5 and maxY-minY>260,'Moth must visit distant sectors across both axes')
 local old={world=6,level=1,width=960,height=600,entities={{kind='mob',type='wind_cloud',x=400,y=300}}}
 require('layout_schema').migrate(old);assert(old.entities[1].type=='wind_bat')
 start(4);mobs={};player.x=315;player.y=288;player.reset=false
 Realms.bolts={{x=355,y=300,vx=100,vy=0,life=2,seed=1}};Realms.updateProjectiles(0)
 assert(player.reset,'Touching the visible lightning tail is lethal, not only its tip')
 start(2);Graphics.effects=true;Graphics.quality=2;mobs={};BossFX.events={};Magma.bursts={};Hazards.lava={}
 for i=1,16 do Hazards.lava[i]={x=40+i*40,y=300,rx=25,ry=20} end
 local lighting=require('world_lighting');local initial={}
 for i,p in ipairs(lighting.collect()) do initial[i]={p.x,p.y,p.radius} end
 Magma.bursts={{x=800,y=200,age=.05}}
 local after=lighting.collect();for i,p in ipairs(initial) do assert(after[i].x==p[1] and after[i].y==p[2] and after[i].radius==p[3],'Explosions must not evict static lava light sources') end
 start(7);assert(not Abyss.encounterActive());player.charges=0;local dark=Abyss.playerVisibility()
 player.charges=2;player.illuminated=4;assert(Abyss.playerVisibility()>dark and Abyss.playerLightRadius()>300,'The whole Abyss uses the boss charge light response')
 start(3);local queen=require('final_spider');queen.reset(true);queen.engaged=true;queen.hp=7;queen.x=300;queen.y=160;player.x=600;player.y=450
 local weave=require('queen_weave');weave.begin(queen);local angle=queen.weaveAngle
 player.x=800;queen.phaseTime=.8;weave.update(queen);assert(#queen.webs==0,'Silk sweep must warn before firing')
 queen.phaseTime=.86;weave.update(queen);assert(#queen.webs==1 and queen.weaveAngle==angle,'Sweep aim is locked before firing')
 queen.phaseTime=2.5;weave.update(queen);assert(#queen.webs==5 and queen.phase=='webs','Sweep resolves then resumes the regular combat')
 queen.reset(true);queen.engaged=true;queen.hp=7;queen.phase='webs';queen.phaseTime=1;queen.volley=5;queen.shot=0;queen.jumpCooldown=10
 player.x=Arena.width-100;player.y=480;player.reset=false;queen.update(.01)
 assert(queen.phase=='weave','The real boss update selects the new attack at the intended cadence')
 local image=g.newCanvas(1200,800);local state=json.encode(require('replay_state').snapshot());local rng=love.math.getRandomState()
 for _,time in ipairs({.2,1.2,3.2}) do
  g.push('all');g.setCanvas(image);g.origin();g.setShader();g.setScissor();g.clear(.08,.11,.15)
  for index,entry in ipairs(Bestiary.entries) do
   local x=80+((index-1)%8)*150;local y=80+math.floor((index-1)/8)*175
   require('bestiary_animation').draw(entry,x,y,90,time)
   g.setColor(1,1,1);g.print(entry.id,x-65,y+55)
  end
  g.pop()
  local pixels=image:newImageData();pixels:encode('png','bestiary-animation-'..time..'.png');pixels:release()
 end
 assert(json.encode(require('replay_state').snapshot())==state and love.math.getRandomState()==rng,'Bestiary animation cannot mutate combat or RNG')
 local worm=Art.drawWorm;local scale
 Art.drawWorm=function(dir,x,y,size,time)scale=size;return worm(dir,x,y,size,time)end
 require('bestiary_animation').draw({id='larva'},100,100,80,1);Art.drawWorm=worm
 assert(scale==40,'The tiny worm uses the actual gameplay worm rig at half size')
 start(6);weather.phaseTime=999;weather.clock=2
 for i=1,24 do weather.fog(Arena.width*.65+math.sin(i)*50,350+math.cos(i)*45);weather.mist[#weather.mist].age=2 end
 weather.warn(Arena.width*.65,350);weather.update(1.61);weather.strikes={};weather.warn(Arena.width*.35,420);weather.strikes[1].age=1.1
 player.x=100;player.y=100;player.reset=false
 local bat=mobs[3];bat.phase='blow';bat.age=1;bat.vx=1;bat.vy=0;bat.angle=-math.pi/2
 local frame=0;love.update=function()
  frame=frame+1
  if frame==1 then App.capture='ecosystem-sky.png'
  elseif frame==3 then print('PASS ecosystem: authored Hell walls and dash, smoke openings, roaming moth, bat migration, lethal lightning tail, stable lava lighting, Abyss charge visibility, telegraphed queen sweep, all animated bestiary entries and shared tiny-worm rig');love.event.quit() end
 end
end
return T
