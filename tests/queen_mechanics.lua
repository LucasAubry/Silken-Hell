local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 for _,w in ipairs(Worlds.order)do Profile.completed[w]=true end
 App.start(3);local F=require('final_spider')
 F.update(2);assert(not F.engaged)
 local x,y=F.x,F.y;player.x=x-15;player.y=y-12;F.update(.01)
 assert(F.phase=='intro_jump' and not player.reset)
 F.update(.4);assert(F.jumpHeight>90 and #F.webs==0 and not player.reset)
 F.update(.5);assert(F.phase=='webs' and F.jumpHeight==0 and math.abs(F.x-x)>200 and math.abs(F.y-y)>250)
 for _,angle in ipairs({.15,.5,-1.3,2.8})do F.angle=angle;local a=F.visualAngle();assert(math.abs(math.sin(a*2))<.00001,'Only cardinal poses')end
 Hazards.kill();App.resolveDeath();assert(F.engaged and F.phase=='webs','Death skips intro')
 F.phase='recover';F.phaseTime=0;F.eggs={{x=300,y=300,age=.4,hatch=7.5,seed=1}};player.x=285;player.y=288;player.dashing=false
 local hp=F.hp;F.update(.01);assert(#F.eggs==1 and F.eggs[1].hits==1 and F.hp==hp)
 for i=1,10 do F.update(.01)end;assert(#F.eggs==1 and F.eggs[1].hits==1,'Standing still is not a second crossing')
 player.x=320;F.update(.01);assert(F.eggs[1].touching,'Hysteresis avoids boundary double hits')
 player.x=350;F.update(.01);assert(not F.eggs[1].touching)
 player.x=285;F.update(.01);assert(#F.eggs==0 and F.hp==hp-1 and #F.shells==1)
 App.start(3);assert(not F.engaged,'New run has its own intro')
 local tick=0
 love.update=function()
 tick=tick+1
 if tick==1 then player.x=F.x-15;player.y=F.y-12;F.update(.01);F.update(.4);App.capture='queen-intro-jump.png'
 elseif tick==5 then print('PASS first-contact leap; cardinal facing; direct retry; two distinct egg crossings; one HP per broken egg; fresh run resets intro');love.event.quit()end
 end
end
return T
