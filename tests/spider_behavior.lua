local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.start(3);local F=require('final_spider');local A=require('final_art')
 for i=1,3 do assert(not love.filesystem.getInfo('assets/sprites/final/web_drape'..i..'.png'))end
 player.x=200;player.y=400;F.x=650;F.y=150;F.update(.01)
 local expected=math.atan2(player.y+12-F.y,player.x+15-F.x)-math.pi/2
 assert(math.abs(F.angle-expected)<.001,'Faces player while firing despite moving')
 F.shoot();assert(math.abs(F.angle-expected)<.001)
 F.webs={};F.x=500;F.y=300;player.x=200;player.y=288;F.phase='lay';F.phaseTime=.64;F.batch=0
 local before=F.x;F.update(.04);assert(F.x>before and #F.eggs==1,'Flees and lays simultaneously')
 assert(F.layPulse>0 and F.eggs[1].fromX and F.carried==23,'Egg drop and contraction animation start')
 for i=1,70 do F.update(.04)end
 assert(#F.eggs>=6 and not player.reset,'Continues laying while escaping')
 local deaths=player.death;player.x=F.x-15;player.y=F.y-12;F.phase='lay';F.update(.01)
 assert(player.reset and player.death==deaths+1,'Touching the boss is lethal')
 App.resolveDeath();assert(not player.reset and #ghosts==0)
 local move,slow,update=Input.move,Input.slow,Ending.update
 Input.move=function()return 1,0 end;Input.slow=function()return false end;Ending.update=function()end
 for i=1,4 do App.simulate(.025)end;assert(#ghosts>0,'Dash still draws short-lived trail')
 Input.move=function()return 0,0 end;App.simulate(.2);assert(#ghosts==0,'Trail fades after final encounter respawn')
 Input.move=move;Input.slow=slow;Ending.update=update
 F.defeated=true;player.x=F.x-15;player.y=F.y-12;F.update(.01);assert(not player.reset,'Defeated queen remains harmless')
 reset_level();F.wallWeb(player.x+15,player.y+12);F.updateWebs(0);assert(F.snareSource=='floor')
 local draw=A.draw;local webs=0;A.draw=function(name,...)if name=='web_wall'then webs=webs+1 end;return draw(name,...)end;F.draw();A.draw=draw;assert(webs==1,'Only existing ground web is drawn')
 local tick=0
 love.update=function()
  tick=tick+1;UI.clock=2
  if tick==1 then reset_level();F.phase='lay';F.phaseTime=.7;F.x=650;F.y=300;player.x=250;player.y=290;F.update(.02);App.capture='spider-flee-laying.png'
  elseif tick==4 then F.wallWeb(34,300);F.wallWeb(Arena.width-34,420);App.capture='spider-restored-webs.png'
  elseif tick==7 then print('PASS original webs restored; firing orientation; lethal touch; continuous fleeing/laying and egg animation; dash trail expiry after respawn');love.event.quit()end
 end
end
return T
