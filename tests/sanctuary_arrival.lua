local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Profile.save=function()end;Bestiary.save=function()end
 Secret.returnSelection=nil;Secret.open(false)
 assert(App.state=='bossWorld' and Secret.intro,'Every entrance starts the scene')
 local x=Secret.x;local rng=love.math.getRandomState();local shown={}
 local R=require('sanctuary_scene');local boss=R.boss
 R.boss=function(p,...)shown[p.type]=true;return boss(p,...)end
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  g.push('all');setCanvas(c);g.setCanvas=function(target,...)if target==nil then return setCanvas(c) end;return setCanvas(target,...)end
  love.draw();g.setCanvas=setCanvas;setCanvas();g.pop();c:newImageData():encode('png','sanctuary-council-'..name..'.png');c:release()
 end
 local oldMove=Input.move;local dx,dy=1,0;Input.move=function()return dx,dy end
 for _,at in ipairs({.4,2,4,6.5}) do
  while Secret.intro.age<at do Secret.update(math.min(.05,at-Secret.intro.age)) end
  capture(tostring(at));assert(Secret.x==x and Secret.page==1,'Cinematic blocks selection and walking')
  assert(Secret.key('space',false),'Space cannot launch during entrance')
 end
 for _,p in ipairs(Secret.normalBosses) do assert(shown[p.type],'Every boss appears') end
 while Secret.intro do Secret.update(.05) end
 dx,dy=0,0;Secret.update(.05)
 local calls,thrones=0,0;local arrow=UI.arrowArt;local throne=R.throneAt
 UI.arrowArt=function(x,y,dir,hover,angle,ink)calls=calls+1;assert(angle==math.pi/2 and ink[1]==1 and ink[3]<.3);return arrow(x,y,dir,hover,angle,ink)end
 R.throneAt=function(...)thrones=thrones+1;return throne(...)end
 capture('selected-first');assert(calls==1 and thrones==7,'One downward menu arrow and seven thrones')
 UI.arrowArt=arrow;R.throneAt=throne
 for i=2,7 do
  dx=1;Secret.update(.05);dx=0;Secret.update(.05)
  assert(Secret.page==i and Secret.x==x,'Movement keys select instead of moving the player')
 end
 for i=1,20 do Secret.update(.05) end
 assert(Secret.turn>0,'Spider faces the selected boss on the right');capture('selected-last')
 Secret.page=1;Secret.navigate(0,-1);assert(Secret.page>1,'Up selects a throne further into the chamber')
 assert(love.math.getRandomState()==rng,'Presentation preserves gameplay RNG')
 Input.move=oldMove;R.boss=boss
 Secret.page=2;Secret.key('space',false)
 assert(Secret.duel and App.state=='playing' and require('run_start').active,'Selected encounter waits for manual start')
 Secret.returnToSanctuary()
 assert(Secret.intro and App.state=='bossWorld' and Secret.page==2,'Returning from a duel replays the entrance and retains selection')
 print('PASS Sanctuary council: permanent tableau, seven thrones, directional selection, shared yellow arrow, facing, encounter and repeated entrance')
 love.event.quit()
end
return T
