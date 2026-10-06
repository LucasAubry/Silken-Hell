local T={}
function T.run()
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 local P=require('podium_celebration');local V=require('victory_screen');local g=love.graphics
 local saved={world=1};V.run=saved;App.state='menu'
 local scores=#Profile.scores;local rng=love.math.getRandomState();local selected=App.selectedWorld
 for rank=1,3 do
  P.test();assert(App.state=='victory' and V.run.podiumPreview==rank)
  assert(V.rank(V.run)=='#'..rank)
  UI.buttons={};V.draw();assert(V.run.animatedRank==rank and App.state=='victory')
  local started=V.run.rankStarted;UI.clock=UI.clock+12
  local canvas=g.newCanvas(1200,750);g.push('all');g.setCanvas(canvas);g.origin();g.clear();UI.buttons={};V.draw();g.pop()
  assert(V.run.rankStarted==started and #UI.buttons==2,'Animation stays inline; preview has no progression actions')
  local data=canvas:newImageData();local f=assert(io.open('/tmp/silken-inline-podium-'..rank..'.png','wb'));f:write(data:encode('png'):getString());f:close();data:release();canvas:release()
 end
 love.keypressed('escape');assert(App.state=='menu' and V.run==saved)
 local run={};P.drawRank(run,'ENVOI…',95,467);assert(not run.animatedRank)
 P.drawRank(run,'#4',95,467);assert(not run.animatedRank)
 P.drawRank(run,'#1',95,467);assert(run.animatedRank==1)
 local initial=run.rankStarted;UI.clock=UI.clock+6;P.drawRank(run,'#1',95,467);assert(run.rankStarted==initial)
 Graphics.effects=false;P.drawRank(run,'#2',95,467);Graphics.effects=true
 assert(#Profile.scores==scores and App.selectedWorld==selected and love.math.getRandomState()==rng)
 print('PASS inline podium: three ranks on victory page, no modal, persistent light after 12 seconds, stable animation start, pending/outside-top-three cases, effects toggle, preview isolation and escape restoration')
 love.event.quit()
end
return T
