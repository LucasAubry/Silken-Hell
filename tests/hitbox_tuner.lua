local Test={}
function Test.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.recording=false;LevelLayouts.disabled=true
 Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 local T=require('hitbox_tuner');T.reset(true);T.open=true;T.paused=false
 App.singleLevel=true;App.practice=2;App.start(1);player.reset=false
 player.x=100;player.y=200
 local a={type='ange',x=140,y=200,hitBox_width=10,hitBox_height=24}
 assert(not isTouching(player,a))
 T.set('player','sx',2);assert(isTouching(player,a),'Player slider changes actual mob collision')
 T.reset(true);T.set('ange','sx',4);assert(isTouching(player,a),'Enemy slider changes actual contact')
 local other={type='snake',x=140,y=200,hitBox_width=10,hitBox_height=24}
 assert(not isTouching(player,other),'Enemy settings are per type')
 T.reset(true);T.set('player','dx',30);assert(T.projectile(146,205,1,1),'Projectiles use adjusted player bounds')
 assert(not T.projectile(101,205,1,1),'Old player position is no longer a collision')
 T.reset(true);assert(not T.touchCircle('storm',160,212,34))
 T.set('storm','sx',2);assert(T.touchCircle('storm',160,212,34),'Circular boss contacts scale')
 T.reset(true);assert(not T.featherTouches(135,212,17));T.set('player_feathers','sx',2)
 assert(T.featherTouches(135,212,17),'Feather collision has real tuning')
 T.reset(true)
 local oldWalls=Walls;Walls={{x=132,y=200,w=3,h=24}}
 assert(not willCollide(100,200));T.set('player','sx',2);assert(willCollide(100,200),'Player wall collision matches overlay');Walls=oldWalls
 T.reset(true);T.selected='player';T.collect()
 local x,y,s=T.layout()
 love.mousepressed(x+160*s,y+122*s,1);assert(T.drag and T.blocked(),'Slider captures pointer and pauses simulation')
 love.mousemoved(x+302*s,y+122*s);assert(T.values.player.sx==2.5)
 love.mousereleased(x+302*s,y+122*s,1);assert(not T.drag,'Release ends drag')
 assert(App.hitboxTest and not Replay.recording and not Online.current,'Edited run is local')
 local value=T.values.player.sx;reset_level();assert(T.values.player.sx==value,'Settings survive death/reset')
 local clock=timer;T.paused=true;App.simulate(.1);assert(timer==clock,'Test pause stops simulation')
 T.paused=false;love.keypressed('f3');assert(not T.open);love.keypressed('f3');assert(T.open)
 T.reset(true);assert(next(T.values)==nil)
 -- Real bone silhouettes move with the offset slider, including collision lookup.
 App.practice=10;App.start(7);local bone=Abyss.bones[1];local mask=Art.images[bone.key].mask
 local sampleX,sampleY
 for yy=0,191 do for xx=0,191 do
  if not sampleX and mask[yy*192+xx] then sampleX=xx;sampleY=yy end
 end end
 assert(sampleX,'Bone alpha mask exists')
 local ux=((sampleX+.5)/192-.5)*bone.w;local uy=((sampleY+.5)/192-.5)*bone.h
 if bone.flip then ux=-ux end
 local xx=bone.x+math.cos(bone.angle)*ux-math.sin(bone.angle)*uy
 local yy=bone.y+math.sin(bone.angle)*ux+math.cos(bone.angle)*uy
 assert(Abyss.boneTouches(bone,xx,yy))
 T.set('skeleton_fish','dx',90);assert(Abyss.boneTouches(bone,xx+90,yy),'Offset moves actual bone mask')
 T.reset(true)
 -- Every encounter renders its real collision geometry, including masks and tentacles.
 for _,world in ipairs({1,2,4,5,6,7,3})do
  App.practice=world==3 and 1 or 10;App.start(world);player.reset=false;T.collect();T.drawWorld();T.drawPanel()
 end
 print('PASS hitbox tuner: actual rectangle/circle/projectile/wall collisions, per-type settings, pointer capture, pause, reset persistence, F3, seven boss renderers')
 local tick=0;local draw=love.draw
 love.update=function()
  tick=tick+1
  if tick==1 then App.practice=2;App.start(1);player.reset=false;T.selected='ange'
  elseif tick==3 then App.practice=10;App.start(6);player.reset=false;T.selected='storm'
  elseif tick==5 then App.practice=10;App.start(7);player.reset=false;T.selected='skeleton_fish'
  elseif tick==7 then love.event.quit()end
 end
 love.draw=function()
  draw()
  if tick==1 or tick==3 or tick==5 then
   local path='/tmp/silken-hitbox-tuner-'..tick..'.png'
   love.graphics.captureScreenshot(function(data)local f=assert(io.open(path,'wb'));f:write(data:encode('png'):getString());f:close()end)
  end
 end
end
return Test
