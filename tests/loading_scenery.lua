local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false
 local P=require('texture_preload');assert(P.ready and not P.font)
 P.begin();P.started=love.timer.getTime()-2
 assert(Art.images.original==require('loading_scenery').spider)
 local step=0
 love.update=function() end
 love.draw=function()
  step=step+1
  if step==1 then
   P.draw()
   love.graphics.captureScreenshot('loading-crevasse.png')
  elseif step==2 then
   P.finish();assert(P.font==nil and Art.onLoad==nil)
   assert(Art.images.original.image:getWidth()>0)
   App.state='menu';UI.background();UI.menu()
   love.graphics.captureScreenshot('loading-crevasse-menu.png')
  else print('PASS loading scene renders and releases bootstrap resources; shared spider survives menu return');love.event.quit() end
 end
end
return T
