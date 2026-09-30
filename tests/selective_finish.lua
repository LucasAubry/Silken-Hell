local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 Profile.character=1;Profile.name='QA';for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 local tick,handled=0,-1;local draw=love.draw;local started
 love.draw=function()draw();tick=tick+1 end
 love.update=function()
  if handled==tick then return end;handled=tick
  if tick==0 then App.practice=10;App.start(4);started=love.timer.getTime()
  elseif tick==180 then print('180 rendered octopus frames in',love.timer.getTime()-started);App.capture='selective-ocean-final.png'
  elseif tick==183 then love.window.setMode(960,600,{resizable=true,highdpi=true});love.resize(love.graphics.getDimensions())
  elseif tick==185 then assert(App.scenePixelHeight>=600);App.practice=10;App.start(7)
  elseif tick==188 then love.window.setMode(1440,900,{resizable=true,highdpi=true});love.resize(love.graphics.getDimensions())
  elseif tick==190 then assert(App.scenePixelHeight>600);App.capture='selective-abyss-final.png'
  elseif tick==193 then Secret.open(false);Secret.page=7;Secret.refresh();App.capture='selective-queen-sanctuary.png'
  elseif tick==196 then Secret.duel=nil;App.state='menu';App.selectedWorld=1;App.capture='selective-menu-final.png'
  elseif tick==199 then
   -- Show corrected source proportions through the actual game draw functions.
   local g=love.graphics;local old=g.getCanvas();local c=g.newCanvas(1200,720)
   g.setCanvas(c);g.clear(.08,.11,.16,1);g.setColor(1,1,1);g.setFont(UI.fonts.body)
   for row,prefix in ipairs({'merle_flight','gull','lanternfish'}) do
    for col,dir in ipairs({'down','left','right','up'}) do
     local key=prefix..'_'..dir;if prefix=='merle_flight' and dir=='right' then key='merle_flight' end
     local a=assert(Art.images[key]);local size=145;local k=size/math.max(a.w,a.h)
     Art.draw(key,150+(col-1)*290,105+(row-1)*190,a.w*k,0,a.h*k)
    end
   end
   Art.draw('abyss_fish',600,655,180)
   g.setCanvas(old);c:newImageData():encode('png','selective-proportions.png');c:release()
   -- Verify both rendering and invalidation of the cached sky border.
   App.practice=1;App.start(6);require('biome_borders').draw();assert(require('biome_borders').skyCanvas)
   for _,w in ipairs(Worlds.order) do local d=require('icon_composer').make(w);assert(d:getWidth()>=512);d:release() end
   print('PASS resize, abyss lighting, queen sanctuary, main menu, 7 biome icons')
   love.event.quit()
  end
 end
end
return T
