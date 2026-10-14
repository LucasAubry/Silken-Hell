local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true;love.focus=function()end
 Graphics.effects=true;Graphics.quality=2
 local g=love.graphics;local lighting=require('world_lighting');local apply=lighting.apply;local scene
 lighting.apply=function(canvas)scene=apply(canvas);return scene end
 love.filesystem.createDirectory('sky-overhaul')
 for _,level in ipairs({1,6,10}) do
  App.practice=level;App.singleLevel=true;App.start(6);require('run_start').active=false
  Realms.clock=3.8;UI.clock=3.8;timer=12.3
  if level==10 then
   local C=require('mobs.bosses.storm.conductors');C.place(Storm);Storm.charges=2
   Storm.clock=3.8;Storm.summon();Storm.update(.45)
  else
   Realms.tornadoes[1].cooldown=0
   player.whirl={tornado=Realms.tornadoes[1],dx=0,dy=-1,time=.4}
   for _,m in ipairs(mobs) do if m.type=='gull' then m.age=2;m.electric=level==6 end end
  end
  local random=love.math.getRandomState();local checkpoint=require('replay_state').hash()
  love.draw()
  assert(love.math.getRandomState()==random,'Sky art must not consume gameplay RNG')
  assert(require('replay_state').hash()==checkpoint,'Rendering cannot move hazards or creatures')
  local pixels=scene:newImageData();pixels:encode('png','sky-overhaul/level-'..level..'.png');pixels:release()
 end
 lighting.apply=apply
 -- Every direction must reveal the new beak inside the original warning lane.
 local warning=g.newCanvas(Arena.width,600,{dpiscale=1})
 Storm.phase='flightTell';Storm.hidden=true;Storm.trails={};Storm.projectiles={}
 for _,dir in ipairs({'left','right','up','down'}) do
  Storm.dir=dir;Storm.x=Arena.width/2;Storm.y=300
  g.push('all');g.setCanvas(warning);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,0);g.setColor(1,1,1);Storm.draw();g.pop()
  local pixels=warning:newImageData();local visible=0
  local _,_,cx,cy,cw,ch=Storm.previewPose()
  for y=0,599 do for x=0,Arena.width-1 do
   local _,_,_,alpha=pixels:getPixel(x,y)
   if alpha>.1 then visible=visible+1;assert(x>=math.floor(cx) and x<=math.ceil(cx+cw) and y>=math.floor(cy) and y<=math.ceil(cy+ch),'Warning stays in its lane') end
  end end
  assert(visible>8,'A visible beak must announce the '..dir..' dash')
  pixels:release()
 end
 warning:release()
 print('PASS sky overhaul: normal birds, electrified birds, steering tornado, boss, lightning and three captures; stable simulation and RNG')
 love.event.quit()
end
return T
