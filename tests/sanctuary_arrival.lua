local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 Secret.returnSelection=nil;Secret.open(false)
 assert(App.state=='bossWorld' and Secret.intro,'Explicit entry starts the revenge scene')
 local x=Secret.x;local rng=love.math.getRandomState();local shown={}
 local R=require('sanctuary_scene');local boss=R.boss
 R.boss=function(p,...)shown[p.type]=true;return boss(p,...)end
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(Arena.width,600)
  g.push('all');g.setCanvas(c);g.clear();Secret.drawWorld();g.pop()
  c:newImageData():encode('png','sanctuary-revenge-'..name..'.png');c:release()
 end
 local oldMove=Input.move;Input.move=function()return 1,-1 end
 for _,at in ipairs({.4,2,4,6.5,8.7}) do
  while Secret.intro.age<at do Secret.update(math.min(.05,at-Secret.intro.age)) end
  capture(tostring(at))
  if at==6.5 then
   local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
   g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
   love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png','sanctuary-revenge-game-view.png');c:release()
  end
  assert(Secret.x==x and not Secret.pending,'Cinematic blocks movement and challenges')
  assert(Secret.key('space',false),'Space cannot accidentally launch a challenge')
 end
 for _,p in ipairs(Secret.normalBosses) do assert(shown[p.type],'Every boss appears in the final confrontation') end
 while Secret.intro do Secret.update(.05) end
 assert(App.state=='bossWorld' and Secret.x==x and not Secret.pending,'Finishes in the sanctuary without starting a fight')
 assert(love.math.getRandomState()==rng,'Cinematic does not consume gameplay RNG')
 capture('hall');Input.move=oldMove;R.boss=boss
 Secret.returnSelection={page=1,category='boss',x=x};Secret.open()
 assert(not Secret.intro,'Returning from a challenge does not replay the entrance')
 print('PASS Sanctuary revenge: all bosses, rear view, input isolation, smooth hall return, no replay after duel')
 love.event.quit()
end
return T
