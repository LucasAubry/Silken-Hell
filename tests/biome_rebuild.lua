local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;Profile.recordBoss=function()end
 App.sessionLayout=nil;App.singleLevel=false;App.preview=false;App.practice=nil;App.hardcore=false;Secret.duel=nil
 local function level(w,n)
  Campaign.select(w);player.level=n;reset_level();App.state='playing'
  require('run_start').active=false;require('run_start').goAge=nil
 end
 -- Exercise actual loaded campaign layouts as well as procedural fallback.
 for _,disabled in ipairs({false,true}) do
  LevelLayouts.disabled=disabled
  for n=1,10 do
   level(6,n)
   assert(#mobs==0 and not Bosses.alive() and not Storm.active,'Ciel must have no creatures or boss')
   assert(#Arena.interior==0 and #Realms.holes==0 and #Realms.tornadoes==0 and #Realms.rainSites==0,'Ciel must have no terrain or weather')
   assert(#levels[n].larme_position==0 and objet.larme.taken,'Ciel must have no collectible')
   local x,y=player.x,player.y
   for _=1,180 do Realms.update(1/60);Campaign.updateTear(1/60) end
   assert(x==player.x and y==player.y and not player.reset,'Empty sky must not push or kill')
   assert(not Realms.fallAt(30,300),'Ciel edges are no longer falling hazards')
  end
 end
 local sky=require('sky')
 local old={world=6,level=1,width=960,height=600,entities={{kind='mob',type='gull',x=300,y=200}}}
 sky.prepare(old);assert(old.skyRevision==1 and #old.entities==1 and old.entities[1].kind=='spawn','Old editor layouts migrate to empty Ciel')
 old.entities[#old.entities+1]={kind='tear',x=400,y=300};sky.prepare(old)
 assert(#old.entities==2,'New Ciel edits survive subsequent loads')
 -- Switching direction or entering/leaving a branch retargets a moving marker.
 local M=require('world_map')
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 App.selectedWorld=1;M.open()
 for i=1,100 do
  local index=i%7+1;M.select(Worlds.selection[index],index);M.update(.002)
  assert(#M.route<=1,'Selection cannot build a backlog')
 end
 local x,y=M.x,M.y;M.select(3,7)
 assert(M.x==x and M.y==y,'Retargeting must not teleport')
 M.update(1/60);assert(((M.x-x)^2+(M.y-y)^2)^.5<=650/60+.001,'Marker keeps normal travel speed')
 for _=1,180 do M.update(1/60) end
 assert(#M.route==0 and M.y==1430,'Only latest destination is reached')
 M.select(1,1);M.branch(true,true);M.branch(false,true);assert(#M.route==1,'Branch toggles replace stale route')
 -- The lava remains lethal but cannot create a projectile on its own.
 level(2,10);assert(Wasp.updateLava==nil,'Eruption code must be removed')
 Wasp.reset(true);Wasp.updateBees=function()end;Wasp.projectiles={}
 Hazards.lava={{x=200,y=200,rx=80,ry=50}}
 for _=1,600 do Wasp.update(1/60) end
 assert(#Wasp.projectiles==0,'Lava cannot shoot')
 player.x=185;player.y=188;player.reset=false;player.abyssGrace=0;Hazards.contact();assert(player.reset,'Lava still kills on contact')
 local F=require('final_spider');level(3,1);F.reset(true)
 local counts={}
 for _,hp in ipairs({13,8,4}) do
  F.hp=hp;F.volley=0;F.webs={}
  for _=1,4 do F.shoot() end
  counts[#counts+1]=#F.webs
  local shot=F.webs[1];local speed=(shot.vx^2+shot.vy^2)^.5
  assert(speed>=460 and speed<=510,'Projectile pressure is bounded')
 end
 assert(counts[1]<counts[2] and counts[2]<counts[3],'Boss patterns intensify with damage')
 assert(F.maxHp==13,'Difficulty comes from patterns, not extra HP')
 -- Direct renders compile the shaders and check state isolation.
 local g=love.graphics;local c=g.newCanvas(1000,600)
 local function shot(name,draw)
  g.push('all');g.setCanvas(c);g.origin();g.setShader();g.setScissor();g.clear(.12,.15,.17,1)
  draw();g.pop();local d=c:newImageData();d:encode('png','rebuild-'..name..'.png');d:release()
 end
 shot('objects',function()
  for row,w in ipairs({1,5,2}) do
   g.setColor(1,1,1)
   for i=1,4 do require('trap_art').draw(i<=2 and 'piege' or 'scie',120+i*145,50+row*130,100,w,i==2,i*.5) end
  end
 end)
 LevelLayouts.disabled=false;level(5,5)
 shot('earth',function() Campaign.draw();for _,m in ipairs(mobs) do Campaign.drawMob(m) end;Campaign.drawTear() end)
 level(3,1);F.reset(true);F.engaged=true;F.phase='webs';F.x=500;F.y=260;F.clock=3;F.hp=7;F.carried=24;F.shoot()
 for i,w in ipairs(F.webs) do w.x=350+i*90;w.y=390 end
 shot('renaissance',function() Campaign.draw();F.draw() end)
 level(6,1);shot('sky',function() Campaign.draw() end)
 local scene=require('sanctuary_scene');Secret.open();Secret.cameraX=Secret.position(3)-Arena.width/2;Secret.x=Secret.position(3)
 shot('sanctuary',function() scene.draw(Secret) end)
 assert(scene.hallCanvas and scene.hallWidth==Arena.width,'Blurred background is cached')
 local cached=scene.hallCanvas;shot('sanctuary-cache',function() scene.draw(Secret) end);assert(scene.hallCanvas==cached,'No per-frame blur allocation')
 -- Stress the final compositing path, including a letterboxed empty Ciel.
 level(6,1);local draw=love.draw;draw();love.resize(1440,800);draw()
 Secret.duel={kind='boss'};level(6,10);assert(Storm.active,'The shared Merle encounter remains playable in the Sanctuary');draw();Secret.duel=nil
 print('PASS biome rebuild: 20 empty Ciel resets, rapid selector input, inert lethal lava, staged queen attacks, relief/rock/foliage/blur renders and resize')
 print('VISUALS '..love.filesystem.getSaveDirectory())
 love.event.quit()
end
return T
