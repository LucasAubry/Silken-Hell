local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 Campaign.select(3);player.level=1;reset_level();App.state='playing'
 local F=require('final_spider');local B=require('queen_brood')
 local function reset()
  F.reset(true);F.engaged=true;F.phase='webs';F.x=480;F.y=300
  player.x=100;player.y=400;player.reset=false
 end
 reset();player.x=F.x-15;player.y=F.y-12;F.update(.01)
 assert(F.hp==12 and F.phase=='intro_jump' and not player.reset,'Contact damages queen and immediately jumps')
 F.damage();assert(F.hp==12,'One contact cannot drain multiple HP')
 player.x=440;player.y=400
 for i=1,85 do F.update(.01) end
 assert(F.phase=='webs' and #F.webs>=10,'Landing fires radial volley')
 reset();F.shot=.01;local x,y=F.x,F.y;F.update(.02)
 assert(#F.webs>0 and F.x==x and F.y==y,'Queen stays planted while firing')
 for i=1,10 do F.update(.01) end
 assert(F.x==x and F.y==y,'Firing pose remains planted')
 for i=1,12 do F.update(.01) end
 assert(F.x~=x or F.y~=y,'Queen walks between shots')
 reset();F.webs={{x=40,y=200,vx=-300,vy=0,age=0}};F.updateWebs(.04)
 assert(#F.webs==0 and #F.bombs==1,'Wall impact spawns explosive spider')
 local b=F.bombs[1];local bx,by=b.x,b.y
 B.update(F,.3);assert(b.x~=bx or b.y~=by,'Explosive spider walks')
 b.age=b.life-.01;B.update(F,.02)
 assert(#F.bombs==0 and #F.stuck==1 and #F.bursts==1,'Timed explosion creates ground silk')
 local w=F.stuck[1];player.x=w.x-15;player.y=w.y-12
 assert(B.speed(F)<.5 and F.snare==0,'Floor silk slows without snaring')
 w.age=6;local faded=B.speed(F);assert(faded>.5 and faded<1,'Slow fades with silk')
 B.update(F,1.01);assert(#F.stuck==0 and B.speed(F)==1,'Silk expires')
 reset();F.webs={{x=player.x+15,y=player.y+12,vx=100,vy=0,age=0}};F.updateWebs(.01)
 assert(F.snare>0 and F.snareSource=='shot' and F.phase=='aim','Projectile keeps old snare and charge effect')
 reset();B.spawn(F,200,200);F.bombs[1].age=2.39;player.x=185;player.y=188;B.update(F,.02)
 assert(player.reset,'Explosion has a damaging radius')
 reset();B.spawn(F,200,200);F.stuck={{x=300,y=300,r=44,age=4,life=7}};F.bursts={{x=400,y=300,age=.15}}
 local g=love.graphics;local c=g.newCanvas(960,600);g.push('all');g.setCanvas(c);g.clear(.08,.08,.09);F.draw();g.pop()
 c:newImageData():encode('png','queen-revision.png');c:release()
 F.reset(true);assert(#F.bombs==0 and #F.stuck==0 and #F.bursts==0,'Retry clears all hazards')
 print('PASS queen contact damage, jump/landing volley, planted shots and movement, wall brood, timed explosion, fading slow, retained snare and reset/render')
 love.event.quit(0)
end
return T
