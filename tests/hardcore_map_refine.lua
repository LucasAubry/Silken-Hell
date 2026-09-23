local T={}
function T.run()
 Online.enabled=false
 local savedCompleted,savedScores=Profile.completed,Profile.scores
 Profile.completed={};Profile.scores={}
 assert(not Hardcore.unlocked() and not Hardcore.available(1))
 Profile.completed[1]=true;Profile.completed[6]=true
 assert(not Hardcore.available(1),'First two completed worlds do not unlock hardcore')
 Profile.completed[5]=true
 assert(Hardcore.unlocked() and Hardcore.available(1) and Hardcore.available(6) and Hardcore.available(5))
 assert(not Hardcore.available(4) and not Hardcore.available(8),'Each world must also be completed')
 App.selectedWorld=5;WorldMap.hardcore=false;WorldMap.open();assert(WorldMap.branch(true));WorldMap.update(1)
 local x,y,scroll=WorldMap.x,WorldMap.y,WorldMap.scroll
 WorldMap.step(1);assert(App.selectedWorld==4 and not WorldMap.hardcore)
 WorldMap.update(.1);assert(WorldMap.x<x and math.abs(WorldMap.y-y)<.01 and WorldMap.scroll==scroll,'Return left before descending')
 WorldMap.update(1);assert(WorldMap.y>y and not WorldMap.hardcore,'Arrival on normal lower world')
 assert(not WorldMap.branch(true),'Incomplete world blocks branch')
 local state=App.state;assert(App.openEntry(4,true)==false and App.state==state)
 App.hardcore=true;assert(App.start(4)==false and App.state==state);App.hardcore=false
 Profile.completed[4]=true;WorldMap.branch(true);WorldMap.update(1)
 WorldMap.open();assert(WorldMap.target==4 and WorldMap.hardcore,'Reopen preserves correct world index')
 local sounds={};local play=Audio.play;Audio.play=function(name) sounds[#sounds+1]=name end
 Hardcore.notify('Niveau suivant');Hardcore.notify('Niveau précédent',true)
 assert(sounds[1]=='levelUp' and sounds[2]=='levelDown')
 local rectangles=0;local rectangle=love.graphics.rectangle;love.graphics.rectangle=function() rectangles=rectangles+1 end
 Hardcore.draw();love.graphics.rectangle=rectangle;Audio.play=play
 assert(rectangles==0,'No level-change banner drawn over playfield')
 Profile.completed=savedCompleted;Profile.scores=savedScores
 Profile.completed[Worlds.order[3]]=true;Profile.completed[1]=true
 print('PASS hardcore unlock/entry guards, left-before-down route, reopen location, sound feedback without banner')
 require('tests.request_hardcore').run()
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then Profile.completed={[1]=true,[6]=true};Profile.scores={};App.selectedWorld=5;WorldMap.hardcore=false;WorldMap.open();App.capture='map-refine-locked.png'
  elseif tick==3 then Profile.completed[5]=true;WorldMap.branch(true);WorldMap.update(1);App.capture='map-refine-hardcore.png'
  elseif tick==5 then WorldMap.step(1);WorldMap.update(.1);App.capture='map-refine-left.png'
  elseif tick==7 then WorldMap.update(1);App.capture='map-refine-down.png'
  elseif tick==9 then love.window.setMode(1440,700,{resizable=true});App.capture='map-refine-wide.png'
  elseif tick==11 then love.window.setMode(800,1000,{resizable=true});App.capture='map-refine-tall.png'
  elseif tick==13 then io.stdout:flush();love.event.quit(0) end
 end
end
return T
