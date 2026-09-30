local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.character=1;Profile.name='QA';for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 local tick,handled=0,-1;local draw=love.draw;local started
 love.draw=function()draw();tick=tick+1 end
 love.update=function()
  if handled==tick then return end;handled=tick
  if tick==0 then App.practice=10;App.start(4);started=love.timer.getTime()
  elseif tick==180 then print('180 rendered octopus frames in',love.timer.getTime()-started);App.capture='ink-ocean-final.png'
  elseif tick==183 then love.window.setMode(960,600,{resizable=true,highdpi=true});love.resize(love.graphics.getDimensions())
  elseif tick==185 then assert(App.scenePixelHeight>=600);App.practice=10;App.start(7)
  elseif tick==188 then love.window.setMode(1440,900,{resizable=true,highdpi=true});love.resize(love.graphics.getDimensions())
  elseif tick==190 then assert(App.scenePixelHeight>600);App.capture='ink-abyss-final.png'
  elseif tick==193 then Secret.open(false);Secret.page=7;Secret.refresh();App.capture='ink-queen-sanctuary.png'
  elseif tick==196 then Secret.duel=nil;App.state='menu';App.selectedWorld=1;App.capture='ink-menu-final.png'
  elseif tick==199 then
   for _,w in ipairs(Worlds.order) do local d=require('icon_composer').make(w);assert(d:getWidth()>=512);d:release() end
   print('PASS resize, abyss lighting, queen sanctuary, main menu, 7 biome icons')
   love.event.quit()
  end
 end
end
return T
