local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end
 Secret.open(false);Secret.category='mobs';Secret.refresh();local list=Secret.creatures;local move=Input.move;Input.move=function()return 0,0 end
 for n,entry in ipairs(list) do
  Secret.open(false);Secret.category='mobs';Secret.page=math.ceil(n/6);Secret.refresh();local slot=(n-1)%6+1
  local x,y=Secret.position(slot);Secret.x=x;Secret.y=y-22;Secret.cooldown=0
  Secret.update(.7);assert(App.state=='bossWorld' and Secret.charging==slot)
  Secret.x=x+100;Secret.update(.1);assert(Secret.charge==0,'Leaving circle resets charge')
  Secret.x=x;Secret.update(.7);Secret.update(.71)
  assert(App.state=='playing' and Secret.duel.kind=='mob' and Secret.duel.name==entry.name,'Circle launches selected monster '..entry.name)
  assert(#mobs==1,'Exactly one enemy for '..entry.name..', got '..#mobs)
  assert(mobs[1].type==entry.type,'Correct monster spawned')
  assert(not Ending.active and not Raven.active and not Wasp.active and not Hedgehog.active and not Octopus.active and not Storm.active and not Abyss.boss)
  Secret.updateDuel(10);reset_level();assert(Secret.duel.time==0 and #mobs==1,'Death resets duel')
  Secret.updateDuel(19.9);assert(App.state=='playing');Secret.updateDuel(.1);assert(App.state=='customVictory')
  love.keypressed('escape');assert(App.state=='bossWorld' and Secret.category=='mobs' and Secret.page==math.ceil(n/6),'Returns to selected creature page')
 end
 Input.move=move
 local scene=require('sanctuary_scene');local original=Art.draw;local points={}
 Art.draw=function(key,x,y,...)
  if key=='skeleton_head' or key=='skeleton_tail' or key=='skeleton_spine' then points[#points+1]={key,love.graphics.transformPoint(x,y)} end
  return original(key,x,y,...)
 end
 for _,clock in ipairs({0,1,2,3,4,5}) do
  UI.clock=clock;points={};scene.boss({type='skeleton_head',kind='boss',art='skeleton_head'},500,245)
  local yy=points[1][3];for _,v in ipairs(points)do assert(math.abs(v[3]-yy)<.001,'Skeleton segments share the same motion')end
 end
 Art.draw=original
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=2
  if tick==1 then Secret.open(false);Secret.page=5;Secret.refresh();App.capture='sanctuary-synced-abyss.png'
  elseif tick==4 then Secret.category='mobs';Secret.page=1;Secret.refresh();local x,y=Secret.position(2);Secret.x=x;Secret.y=y-22;Secret.charging=2;Secret.charge=.8;App.capture='sanctuary-monster-circles.png'
  elseif tick==7 then print('PASS '..#list..' individual monster circles, one opponent per duel, hold/cancel, retry/return, and synchronized abyss assembly');love.event.quit()end
 end
end
return T
