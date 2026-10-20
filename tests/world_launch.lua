local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 local saveProfile=Profile.save
 Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;Replay.disabled=true;Replay.playing=false;Replay.recording=false
 App.practice=nil;App.singleLevel=false;App.preview=false;App.sessionLayout=nil;Secret.duel=nil
 Input.speedHeld=function()return false end
 Profile.completed={};Profile.levels={};Profile.transitionsSeen={}
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Profile.levels[w]=10 end
 local C=require('run_start')
 local routes={[1]='portal',[6]='sky',[5]='earth',[4]='ocean',[7]='abyss',[2]='hell',[3]='renaissance'}
 for _,hard in ipairs({false,true}) do
  App.hardcore=hard
  for world,kind in pairs(routes) do
   App.start(world);assert(C.active and C.arrivalKind==kind,'Direct launch route '..world)
  end
 end
 App.hardcore=false
 local function capture(name)
  local g=love.graphics;local target=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(target);g.setCanvas=function(c,...)return setCanvas(c or target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();target:newImageData():encode('png',name..'.png');target:release()
 end
 for world,kind in pairs(routes) do
  if world~=1 then
   Profile.transitionsSeen={};App.start(world);C.advance(.05)
   App.start(world);assert(C.arrivalKind==kind,'Interrupted story remains unseen')
   while C.arrival do C.advance(.05) end
   assert(Profile.transitionsSeen[tostring(world)]==true,'Only completed stories are remembered')
   App.start(world);assert(C.arrivalKind=='brief' and C.arrivalDuration<3,'Repeat uses brief arrival')
   local B=C.scene();local w,h=love.graphics.getDimensions();local scale,x,y=App.viewport(w,h)
   local sx,sy=x+(player.x+15)*scale,y+(player.y+8)*scale
   assert(B.duration==2 and C.arrivalDuration==2,'Exactly two seconds of the original cinematic')
   assert(B.scene==require(kind..'_arrival'),'Uses the original scene renderer')
   assert(math.abs(B.scene.age-B.offset)<.00001,'Original state reconstructed at the final second')
   local rng=love.math.getRandomState();local px,py=player.x,player.y
   for i=1,40 do
    C.advance(.05)
    if i==15 then capture('brief-entry-'..world) end
    assert(timer==0 and player.x==px and player.y==py and love.math.getRandomState()==rng,'Brief arrival freezes gameplay')
   end
   assert(not C.active and not C.arrival,'Final second starts gameplay automatically')
   App.hardcore=true;App.start(world);assert(C.arrivalKind=='brief','Seen stories shared with hardcore');App.hardcore=false
  end
 end
 App.hardcore=false;App.practice=1;App.singleLevel=true
 for world in pairs(routes) do
  App.start(world);assert(C.arrivalKind=='portal' and C.arrivalPractice,'Training portal '..world)
  local rng=love.math.getRandomState();local x,y=player.x,player.y
  for i=1,100 do
   C.advance(.05)
   assert(timer==0 and player.x==x and player.y==y and love.math.getRandomState()==rng,'Portal freezes simulation')
  end
  assert(not C.active and not C.arrival and C.advance(.02)==.02,'Training resumes automatically')
 end
 local g=love.graphics;local canvas=g.newCanvas(1200,750)
 local function border(t)
  UI.clock=t;g.setCanvas(canvas);g.clear(0,0,0,0);Hardcore.drawBorder(1200,750);g.setCanvas();return canvas:newImageData()
 end
 UI.clock=0;Hardcore.beginTrainingBorder()
 local start=border(0);local _,_,_,a=start:getPixel(600,1);assert(a<.01)
 local middle=border(.2);local _,_,_,top=middle:getPixel(600,1);local _,_,_,side=middle:getPixel(1,375)
 assert(top>side,'Training ignites from the same fronts as hardcore')
 local full=border(.7);local r,green,b,alpha=full:getPixel(600,1)
 assert(green>r*1.5 and green>b and alpha>.5,'Training border is green')
 full:encode('png','training-border-test.png')
 App.practice=nil;App.singleLevel=false;App.hardcore=true
 local red=border(.8);r,green,b,alpha=red:getPixel(600,1);assert(r>green and r>b,'Hardcore stays red')
 App.hardcore=false;App.preview=true;App.start(6);assert(not C.active and not C.arrival)
 App.preview=false;Replay.playing=true;C.begin();assert(not C.active and not C.arrival)
 local write,read=love.filesystem.write,love.filesystem.read;local stored
 love.filesystem.write=function(path,data)if path=='profile.txt' then stored=data end;return true end
 Replay.playing=false;Profile.transitionsSeen={['3']=true,['7']=true};saveProfile()
 assert(stored and stored:find('transitionsSeen='),'Seen transitions serialized')
 love.filesystem.read=function(path,...)if path=='profile.txt' then return stored end;return read(path,...) end
 Profile.load();assert(Profile.transitionsSeen['3']==true and Profile.transitionsSeen['7']==true,'Seen transitions survive reload')
 love.filesystem.write=write;love.filesystem.read=read
 print('PASS world launch: all normal/hardcore routes, training portals, frozen simulation, automatic resume, green ignition, red hardcore, preview/replay exclusions')
 love.event.quit()
end
return T
