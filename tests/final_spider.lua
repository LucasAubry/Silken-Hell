local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Profile.save=function() end;Bestiary.save=function() end;Replay.disabled=true
 local F=require('final_spider');local V=require('victory_screen');local checkpoints={};Online.checkpoint=function(n) checkpoints[#checkpoints+1]=n end
 local completed=0;local complete=Profile.complete;Profile.complete=function(w) assert(w==3);completed=completed+1 end
 local function start() App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;App.hardcore=false;App.start(3) end
 start();assert(Ending.active and F.active and F.hp==20 and not Ending.locked());assert(#mobs==0 and not Renaissance.active)
 local before=timer;App.simulate(.02);assert(timer>before and RunDetails.rows[1].time>0)
 F.wave=1;F.batch=0;local carried=F.carried;for i=1,8 do F.layEgg() end
 assert(#F.eggs==8 and F.carried==carried-8)
 local first=F.eggs[1];player.x=first.x-15;player.y=first.y-12;player.dashing=true
 F.phase='lay';F.phaseTime=0;F.update(.01);assert(F.hp==19 and #F.shells==1,'Dash breaks egg for one HP')
 player.x=50;player.y=500;player.dashing=false;for _,e in ipairs(F.eggs) do e.age=e.hatch end
 F.update(.01);assert(#F.babies==7 and #F.eggs==0 and #F.shells==8,'Each egg hatches exactly one baby and leaves shell')
 F.webs={{x=35,y=360,vx=-335,vy=0}};F.updateWebs(.03);assert(#F.webs==0 and #F.stuck==1)
 F.updateWebs(10);assert(#F.stuck==1,'Wall webs persist')
 player.x=F.stuck[1].x-15;player.y=F.stuck[1].y-12;F.phase='webs';F.updateWebs(.01);assert(F.snare>0 and Ending.locked() and F.phase=='aim')
 local x=player.x;App.move(.04);assert(player.x==x and not player.dashing)
 start();F.x=200;F.y=250;player.x=500;player.y=450
 local baby={x=400,y=250,age=2,seed=1,variant='red'};F.babies={baby};F.webs={{x=375,y=250,vx=335,vy=0}}
 F.updateWebs(.05);assert(baby.webbed and F.target==baby and F.phase=='aim','Web catches baby before player')
 F.update(.66);assert(F.phase=='charge');for i=1,15 do F.update(.03) end
 assert(F.hp==19 and #F.babies==0,'Mother kills webbed baby for exactly one HP')
 start();F.phase='aim';F.chargeX=player.x+15;F.chargeY=player.y+12;F.snare=2.1
 F.update(.7);for i=1,30 do if not player.reset then F.update(.02) end end
 assert(player.reset,'Mother charge kills player');App.resolveDeath();assert(F.hp==20 and #F.eggs==0 and #F.stuck==0 and F.snare==0,'Death resets the entire encounter')
 -- Defeat and door preserve elapsed time, deaths and both level splits.
 timer=42;RunDetails.rows[1]={level=1,time=42,deaths=1}
 F.babies={{x=220,y=320,age=2,seed=1,variant='white'}}
 for i=1,20 do F.damage() end
 assert(F.defeated and F.hp==0 and F.snare==0)
 player.x=205;player.y=308;F.update(.01);assert(not player.reset,'Babies harmless after defeat')
 for i=1,100 do F.update(.03) end;assert(F.gate)
 player.x=Arena.width*.5-15;player.y=25;F.update(.01)
 assert(player.level==2 and App.state=='playing' and not F.active and timer==42 and RunDetails.rows[1].time==42,'Door opens level two without resetting run')
 local earlyX,earlyY=Ending.partner.x,Ending.partner.y;Ending.update(.02);local fast=((Ending.partner.x-earlyX)^2+(Ending.partner.y-earlyY)^2)^.5
 Ending.partner.x,Ending.partner.y=earlyX,earlyY;Ending.clock=30;Ending.update(.02);local slow=((Ending.partner.x-earlyX)^2+(Ending.partner.y-earlyY)^2)^.5;assert(slow<fast)
 App.simulate(.02);player.x=Ending.partner.x-15;player.y=Ending.partner.y-12;Ending.update(.01)
 assert(App.state=='credits' and completed==1 and #V.run.rows==2 and checkpoints[#checkpoints]==2)
 Ending.update(.1);assert(completed==1,'Completion only once');Ending.updateCredits(Ending.creditDuration()+1)
 assert(App.state=='victory' and #V.run.rows==2 and not Ending.active,'Combined recap follows credits')
 local result=V.run
 -- Render states for visual review.
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1;UI.clock=4
  if frame==1 then start();F.wave=1;F.batch=0;for i=1,8 do F.layEgg() end;for i,e in ipairs(F.eggs) do e.age=i*.7 end;F.wallWeb(34,300);F.babies={{x=350,y=360,age=2,seed=1,variant='red'},{x=460,y=390,age=2,seed=2,variant='white'},{x=560,y=420,age=2,seed=11,variant='black'}};App.capture='final-boss-eggs.png'
  elseif frame==4 then F.hp=1;F.damage();F.phaseTime=3;F.gate=true;F.x=Arena.width*.5;F.y=100;App.capture='final-boss-door.png'
  elseif frame==7 then Ending.openReunion();App.capture='final-reunion.png'
  elseif frame==10 then Ending.startCredits();Ending.creditTime=Ending.creditDuration()-3;App.capture='final-thanks.png'
  elseif frame==13 then V.run=result;App.state='victory';App.capture='final-two-level-recap.png'
  elseif frame==16 then Profile.complete=complete;print('PASS final boss: 20HP, eggs/hatching/shells, persistent webs, immobilization, baby bait, lethal charge/reset, peaceful retreat/door, slower partner, credits, combined splits');love.event.quit() end
 end
end
return T
