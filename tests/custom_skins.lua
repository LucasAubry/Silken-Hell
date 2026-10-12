local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Bestiary.save=function()end
 Profile.character=23;Profile.achievements={maxance=true,flawless_all=true}
 Profile.completed={};Profile.skinGrants={};Profile.skinEffects={};Profile.tearExtension=false
 for _,world in ipairs(Worlds.order)do Profile.completed[world]=true end
 Characters.browsed=nil;App.state='menu';Graphics.showFPS=false
 local g=love.graphics;local walk=require('brown_walk');local draw=Art.draw
 local walkDraw=walk.draw;local calls=0
 for _,id in ipairs({14,23})do
  assert(Characters.unlocked(id))
  for _,dir in ipairs({'down','up','left','right'})do
   local key=Characters.model(dir,id);local art=assert(Art.images[key])
   assert(key~='player_skin_'..dir,'Each custom skin uses its own directional artwork')
   assert(art.w>0 and art.h>0 and art.w/art.h>.45 and art.w/art.h<2,'Directional silhouette fits the shared rig')
   Art.draw=function(actual,x,y,width,...)
    assert(actual==key and g.getShader()==Characters.customSkinShader,'Custom artwork retains its own ink material')
    assert(math.abs(width-59*art.w/math.max(art.w,art.h))<.001,'Gameplay silhouette stays at the standard scale')
    calls=calls+1;return draw(actual,x,y,width,...)
   end
   g.setColor(1,1,1);Characters.portrait(id,150,150,59,dir)
   Art.draw=draw
   walk.draw=function(image,pose,x,y,width,state,quad)
    assert(image==art.image and quad==art.quad and pose==(dir=='right' and 'left' or dir))
    assert(g.getShader()==Characters.customSkinShader and math.abs(width-59*art.w/math.max(art.w,art.h))<.001)
    calls=calls+1;return walkDraw(image,pose,x,y,width,state,quad)
   end
   Characters.portrait(id,150,150,59,dir,false,{walkMoving=true,walkPhase=.7})
   walk.draw=walkDraw
  end
  -- The rendered PNG owns the eye colors, including Maxance's brown irises.
  local ellipse=g.ellipse
  g.ellipse=function()error('Custom miniatures must not repaint their eyes with the common blue iris')end
  Characters.portrait(id,150,150,26,'down')
  g.ellipse=ellipse
 end
 assert(calls==16,'Both skins render in all four poses and through the walking mesh')
 App.state='skins';UI.draw();assert(#UI.buttons==19,'Eighteen selectable skins plus Return')
 UI.buttons[15].run();assert(Profile.character==23 and App.state=='menu','The last catalogue card equips Cocon')
 local tick=0
 local labels={'Face','Dos','Gauche','Droite'}
 local shots={'still','walk-a','walk-b','catalogue'}
 love.update=function()
  tick=tick+1;UI.clock=4
  if tick>#shots then
   print('PASS custom Cocon/Maxance poses, authored colors, miniature eyes, shared walking mesh, gameplay scale and noncontiguous skin catalogue')
   love.event.quit()
  end
 end
 love.draw=function()
  g.clear(.025,.035,.05);local width,height=g.getDimensions();local scale=math.min(width/1200,height/750)
  g.push('all');g.translate((width-1200*scale)/2,(height-750*scale)/2);g.scale(scale)
  if tick==4 then App.state='skins';UI.draw()
  else
   local phase=tick==2 and .7 or 2.8
   for row,id in ipairs({14,23})do
    local y=row==1 and 210 or 555
    UI.text(Characters.names[id],60,y-160,'heading',{1,1,1},1080,'center')
    g.setColor(1,1,1);Characters.portrait(id,740,y-143,26,'down')
    for col,dir in ipairs({'down','up','left','right'})do
     local x=150+(col-1)*300
     g.setColor(1,1,1)
     Characters.portrait(id,x,y,216,dir,false,tick>1 and {walkMoving=true,walkPhase=phase} or nil)
     UI.text(labels[col],x-120,y+125,'body',{1,1,1},240,'center')
    end
   end
  end
  g.pop()
  local name=shots[tick]
  if name then g.captureScreenshot(function(data)
   local path='/tmp/silken-custom-skins-'..name..'.png';local f=assert(io.open(path,'wb'))
   f:write(data:encode('png'):getString());f:close()
  end)end
 end
end
return T
