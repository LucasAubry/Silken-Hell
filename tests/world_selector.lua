local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Bestiary.save=function()end
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Hardcore.completed[tostring(w)]=true;Profile.levels[w]=Worlds.levelCount(w) end
 local cases={{6,false},{1,false},{5,false},{4,false},{7,false},{2,false},{3,false},{8,false},{6,true}}
 local preview=require('world_preview');local g=love.graphics
 local done,scores=Profile.completed,Profile.scores
 Profile.completed={};Profile.scores={}
 assert(preview.revealed(1) and not preview.revealed(8),'Unlocked worlds show reached levels')
 local mystery=g.newCanvas(680,300)
 g.push('all');g.setCanvas(mystery);g.origin();g.clear();preview.draw(7,0,0,680,300,false);g.pop()
 mystery:newImageData():encode('png','world-preview-undiscovered.png');mystery:release()
 Profile.completed[1]=true;assert(preview.revealed(1),'Completion reveals the preview')
 Profile.completed={};Profile.scores={{world=1,hardcore=false}};assert(preview.revealed(1),'Existing completed runs reveal previews')
 Profile.completed=done;Profile.scores=scores
 preview.babies=nil;local babies=preview.updateBabies(0);local bx,by=babies[1].x,babies[1].y
 preview.updateBabies(.05)
 local d=math.sqrt((babies[1].x-bx)^2+(babies[1].y-by)^2)
 assert(d>0 and d<=129*.05+.001 and babies[1].walkMoving,'Babies pursue with gameplay speed and walking animation')
 local rng=love.math.getRandomState();local px,py=player.x,player.y
 local oldClock=UI.clock;local oldEffects=Graphics.effects;Graphics.effects=true
 local canvas=g.newCanvas(680,900)
 for _,world in ipairs({1,2,3,4,5,6,7,8}) do
  g.push('all');g.setCanvas(canvas);g.origin();g.clear()
  for i,time in ipairs({.5,1,2.8}) do
   UI.clock=time;preview.draw(world,0,(i-1)*300,680,300,false)
   assert(g.getCanvas()==canvas,'Preview restores the target canvas')
  end
  g.pop();if world==5 or world==7 then canvas:newImageData():encode('png','world-preview-motion-'..world..'.png') end
 end
 canvas:release();UI.clock=oldClock;Graphics.effects=oldEffects
 assert(player.x==px and player.y==py and love.math.getRandomState()==rng,'Preview leaves gameplay and RNG untouched')
 local _,redY=preview.fishPose(0,1,false);local _,redLater=preview.fishPose(.4,1,false)
 local _,yellowY=preview.fishPose(0,3,true);local _,yellowLater=preview.fishPose(.4,3,true)
 assert(redY==redLater and math.abs(yellowY-yellowLater)>1,'Red fish cross straight; yellow fish zigzag')
 local frame=0
 love.update=function()
  frame=frame+1;UI.clock=4
  if frame%2==1 then
   local c=cases[(frame+1)/2]
   if not c then print('PASS world selector: all biomes, hardcore, practice and entry controls');love.event.quit();return end
   App.selectedWorld=c[1];WorldMap.hardcore=c[2];WorldMap.open();App.capture='world-selector-'..c[1]..(c[2] and '-hardcore' or '')..'.png'
  else
   local function click(x,y)
    for _,b in ipairs(UI.buttons) do if b.x==x and b.y==y then b.run();return true end end
    return false
   end
   local old=App.openEntry;local entered
   App.openEntry=function(w,h)entered={w,h}end
   assert(click(790,587) and entered[1]==App.selectedWorld and entered[2]==WorldMap.hardcore,'Entry preserves world and mode');App.openEntry=old
   if App.selectedWorld~=8 and not WorldMap.hardcore then
    local practice=App.practiceLevel;local called
    App.practiceLevel=function(w,l)called={w,l}end
    assert(click(790,471) and called[1]==App.selectedWorld and called[2]==1,'Practice button');App.practiceLevel=practice
   end
  end
 end
end
return T
