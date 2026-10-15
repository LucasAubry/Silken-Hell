local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end
 local g=love.graphics
 local oldDraw=Art.draw
 local calls=0
 for _,id in ipairs({1,22}) do
  for _,dir in ipairs({'down','up','left','right'}) do
   local key=Characters.model(dir,id)
   local pose=(dir=='left' or dir=='right') and 'profil' or dir
   assert(key=='player_skin_base_marron_'..pose)
   local art=assert(Art.images[key])
   assert(art.w>0 and art.h>0)
   Art.draw=function(actual,...)
    assert(actual==key and g.getShader()==nil,'Base skin must retain authored brown and amber colors')
    calls=calls+1;return oldDraw(actual,...)
   end
   Characters.portrait(id,100,100,59,dir,false)
   Art.draw=oldDraw
   Characters.portrait(id,100,100,59,dir,false,{walkMoving=true,walkPhase=.7})
   Characters.portrait(id,100,100,26,dir,false)
  end
 end
 assert(calls==8)
 assert(Characters.model('down',2)=='player_skin_down','Perle must retain its common source')
 local frame=0
 love.update=function()
  frame=frame+1
  if frame>3 then print('PASS painted base skin: all directions, legacy Soie ID, authored colors, walking mesh and miniatures');love.event.quit() end
 end
 love.draw=function()
  g.clear(.11,.14,.15);g.setColor(1,1,1)
  local w,h=g.getDimensions()
  for i,dir in ipairs({'down','up','left','right'}) do
   Characters.portrait(1,w*(i-.5)/4,h*.30,180,dir,false)
   Characters.portrait(1,w*(i-.5)/4,h*.67,90,dir,false,{walkMoving=true,walkPhase=.7})
   Characters.portrait(1,w*(i-.5)/4,h*.85,26,dir,false)
  end
  if frame==2 then g.captureScreenshot('base-skin-painted.png') end
 end
end
return T
