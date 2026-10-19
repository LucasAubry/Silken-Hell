local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end
 assert(require('menu_preload').ready,'Menu assets are prepared before input')
 local update=love.update
 local function frame(label)
  local t=love.timer.getTime();print('BEGIN '..label)
  update(1/60);love.draw();love.graphics.flushBatch()
  print(string.format('FRAME %s %.3f',label,love.timer.getTime()-t))
 end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.state='menu';App.selectedWorld=1;UI.pressed=nil;UI.clock=4;Input.active=false
 frame('menu');local portrait
 for _,b in ipairs(UI.buttons) do if b.w==210 and b.h==190 then portrait=b end end
 assert(portrait);UI.click(portrait.x+105,portrait.y+95);update(.12);assert(App.state=='skins');frame('player click')
 App.state='menu';UI.pressed=nil;frame('menu after player');UI.click(600,520);update(.12);assert(App.state=='entry');frame('play click')
 App.draftName='Test';local start=love.timer.getTime();UI.click(520,598);assert(App.state=='playing');print(string.format('START %.3f',love.timer.getTime()-start));frame('started game')
 App.state='menu';UI.pressed=nil;frame('menu return');UI.click(600,668);update(.12);assert(App.state=='worlds');frame('selector click')
 for _,w in ipairs(Worlds.selection) do
  App.selectedWorld=w;WorldMap.open();frame('world '..w);frame('world warm '..w)
 end
 print('PASS menu clicks: play, selector and every world render without blocking');love.event.quit()
end
return T
