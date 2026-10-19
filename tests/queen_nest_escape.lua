local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local F=require('final_spider');local H=require('queen_heirs')
 local function reset()
  require('boss_liberation').reset();Campaign.select(3);player.level=1;reset_level();App.state='playing'
  F.reset(true);F.engaged=true;F.phase='webs';F.x=Arena.width*.5+110;F.y=300;F.hp=11;F.pendingEggs=1
  player.x=Arena.width*.5-15;player.y=288;player.reset=false;F.contactGrace=0;F.jumpCooldown=4
 end
 reset();local hp=F.hp;F.update(.01)
 assert(F.phase=='intro_jump' and F.hp==hp,'Approach at arena centre triggers escape without a damage hit')
 local tx,ty=F.jump.tx,F.jump.ty
 assert((tx-player.x-15)^2+(ty-player.y-12)^2>(Arena.width*.4)^2,'Queen jumps to a distant nest')
 assert(#F.eggs==0,'Egg does not teleport to destination')
 F.update(.4);assert(#F.eggs==0 and F.x~=tx,'Queen physically travels before laying')
 -- Moving across the middle must not retarget an already committed leap.
 player.x=player.x+20;F.update(.46)
 assert(F.x==tx and F.y==ty and #F.eggs==1 and F.pendingEggs==0,'Queen lays immediately on landing')
 assert(F.eggs[1].x==F.x and F.eggs[1].y==F.y,'Egg is laid at the queen position')
 F.update(.01);assert(#F.eggs==1,'Landing cannot lay twice')
 reset();F.phase='seek_nest';F.nest={x=55,y=70};F.x=400;F.y=150;player.x=Arena.width-100;player.y=490
 F.trap(player);assert(F.phase=='seek_nest','A pending egg takes priority over a new charge')
 F.update(.01);local nest=F.nest;player.x=55;player.y=490;F.update(.01)
 assert(F.nest==nest and F.nest.x==55 and F.nest.y==70,'Walking nest stays fixed when player changes sides')
 reset();H.hatch(F,{x=55,y=70,seed=1});H.jump(F.babies[1],F);F.leap('webs')
 local j=F.babies[1].jump;assert((F.jump.tx-j.tx)^2+(F.jump.ty-j.ty)^2>=110^2,'Nest avoids another spider landing')
 reset();F.pendingEggs=0;F.hp=13;F.x=300;F.y=150;F.damage();assert(F.pendingEggs==0,'First HP lost does not grant an egg')
 F.damage(true);assert(F.pendingEggs==1,'Second HP lost grants one egg')
 print('PASS queen escape: centre approach, distant physical leap, immediate landing egg, fixed nest, charge priority, distinct landings and two-HP cadence');love.event.quit()
end
return T
