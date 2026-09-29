local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 Profile.character=1;App.practice=9;App.start(1)
 
 local tick=0
 local originalDraw=love.draw
 love.draw=function() originalDraw();tick=tick+1 end
 local handled=-1
 local sizes={{960,600},{1440,900},{1920,1080}}
 love.update=function()
  if handled==tick then return end;handled=tick
  if tick==1 or tick==4 or tick==7 then
   local size=sizes[math.floor((tick-1)/3)+1]
   love.window.setMode(size[1],size[2],{resizable=true,highdpi=true});love.resize(love.graphics.getDimensions())
  elseif tick==2 or tick==5 or tick==8 then
   local _,ph=love.graphics.getPixelDimensions()
   local w,h=love.graphics.getDimensions();local displayed=600*App.viewport(w,h)*ph/h
   assert(math.abs(App.scenePixelHeight-math.max(600,math.min(displayed,2400)))<2,'Scene must match displayed arena pixels')
   local B=require('biome_borders');assert(B.canvas:getPixelHeight()==App.scenePixelHeight,'Borders must match scene resolution')
   print('Display/scene pixels:',ph,App.scenePixelHeight)
   local pixels=B.canvas:newImageData();local _,_,_,alpha=pixels:getPixel(math.floor(pixels:getWidth()/2),math.floor(10*B.canvas:getDPIScale()));pixels:release()
   assert(alpha>.5,'Visible border restored after mode change')
   if tick==8 then App.capture='paradis-contraste.png' end
  elseif tick==10 then
   App.practice=nil;App.start(6)
  elseif tick==11 then
   assert(App.scenePixelHeight==600,'Sky renderer remains unchanged')
   App.practice=10;App.start(1)
  elseif tick==12 then App.capture='paradis-contraste-boss.png'
  elseif tick==14 then
   assert(App.scenePixelHeight>600,'Native resolution also used for the boss')
   print('PASS native-resolution Paradise at three sizes, sharp border cache, resize/world changes and boss')
   love.event.quit()
  end
 end
end
return T
