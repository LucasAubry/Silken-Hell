local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true
 local crab=MobBehaviors.crab;local bossX=Octopus.x;local bossArms=Octopus.wrapArms
 for _,e in ipairs(Bestiary.entries)do Bestiary.seen[e.id]=true end
 for _,id in ipairs({'hedgehog','octopus','hedgehog','octopus'})do
  Bestiary.open(id)
  for tick=1,4 do
   UI.clock=tick*3;love.draw()
   local row
   for j,v in ipairs(Bestiary.list('boss'))do if v.entry.id==id then row=(j-1)%8+1 end end
   assert(row);UI.click(200,165+(row-1)*51+20);UI.click(200,165+(row-1)*51+20)
   love.draw();assert(Bestiary.entries[UI.bestSelected].id==id)
  end
 end
 assert(MobBehaviors.crab==crab and Octopus.x==bossX and Octopus.wrapArms==bossArms,'Preview must not change live boss or crab behaviour')
 local R=require('crash_report');assert(R.handler and love.errorhandler==R.handler,'Crash handler installed at startup')
 for i=1,60 do R.note('test.action',i)end
 assert(#R.events==50)
 local path=assert(R.write('diagnostic test','test traceback'))
 local report=assert(love.filesystem.read(path))
 assert(report:find('screen=bestiary',1,true) and report:find('bestiary=octopus',1,true) and report:find('test traceback',1,true) and report:find('test.action 60',1,true))
 assert(love.filesystem.read('last-crash.log')==report)
 local nextPath=assert(R.write('second diagnostic test'))
 assert(nextPath~=path and love.filesystem.getInfo(path),'Reports survive a second crash')
 love.filesystem.remove(path);love.filesystem.remove(nextPath);love.filesystem.remove('last-crash.log')
 local g=love.graphics;local canvas=g.newCanvas(1100,650)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.07,.08,.12,1);g.setColor(1,1,1)
 for row,index in ipairs({4,10,5})do
  assert(not Characters.customSprites[index], 'Marine skins use the shared base')
  for _,dir in ipairs({'down','up','left','right'})do assert(Characters.model(dir,index)==Characters.model(dir,5),'Exact same base in every direction')end
  for column,dir in ipairs({'down','up','left','right'})do
   Characters.portrait(index,130+(column-1)*270,105+(row-1)*215,175,dir,false)
   Characters.portrait(index,220+(column-1)*270,175+(row-1)*215,45,dir,false)
  end
 end
 g.pop();canvas:newImageData():encode('png','skin-refresh-qa.png');canvas:release()
 local skin=require('integrated_skins')
 assert(not skin.bubble(4) and skin.bubble(9) and skin.hideMarineOverlay(4) and skin.hideMarineOverlay(10))
 local bubble=require('breathing_bubble');local drawAt,lantern=bubble.drawAt,bubble.drawLantern
 bubble.drawAt=function()error('Unexpected bubble')end;bubble.drawLantern=function()error('Unexpected lantern')end
 local selected=Characters.selected
 for _,index in ipairs({4,10})do Characters.selected=function()return index end;bubble.drawBubble();require('skin_accessories').draw(index,0,0,59,'down',false,true,1)end
 Characters.selected=selected;bubble.drawAt=drawAt;bubble.drawLantern=lantern
 print('PASS Skin/bestiary refresh: repeated double-clicks, octopus rig isolation, persistent crash reports, three skins in four directions, no bubble/lantern overlays')
 love.event.quit()
end
return T
