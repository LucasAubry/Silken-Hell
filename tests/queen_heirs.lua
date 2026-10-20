local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 Campaign.select(3);player.level=1;reset_level();App.state='playing'
 local F=require('final_spider');local H=require('queen_heirs');local B=require('queen_brood')
 local function reset()F.reset(true);F.engaged=true;F.phase='webs';F.x=480;F.y=300;player.x=100;player.y=450;player.reset=false end
 reset();F.shot=100;for i=1,1000 do F.update(.01) end
 assert(#F.eggs==0 and F.eggSerial==0,'No timed laying')
 reset();F.damage();assert(F.hp==12 and #F.eggs==0)
 F.damageGrace=0;F.damage();assert(F.hp==11 and F.pendingEggs==1 and #F.eggs==0,'One egg queued per two lost HP');F.layEgg();F.pendingEggs=0
 F.breakEgg(1);assert(F.hp==10 and #F.eggs==0,'Broken egg damages even during contact grace')
 F.damageGrace=0;F.damage();assert(F.hp==9 and F.pendingEggs==1);F.layEgg();F.pendingEggs=0;assert(#F.eggs==1 and F.eggSerial==2)
 local e=F.eggs[1];e.age=e.hatch;F.updateEggs(.01)
 assert(#F.eggs==0 and #F.babies==1,'Egg hatches large heir')
 local b=F.babies[1];local hp=F.hp;local eggs=F.eggSerial
 b.contactGrace=0;player.x=b.x-15;player.y=b.y-12;H.update(F,.01)
 assert(player.reset and F.hp==hp,'Heir contact kills without HP loss');player.reset=false;H.jump(b)
 player.x=400;player.y=450;F.webs={}
 for i=1,85 do H.update(F,.01)end
 assert(b.phase=='webs' and #F.webs==8 and F.eggSerial==eggs,'Heir landing fires reduced volley, never eggs')
 for _,w in ipairs(F.webs)do assert(w.owner==b.id)end
 F.webs={};F.fire(F,true);assert(#F.webs==10,'Queen landing volley reduced')
 F.webs={};F.shoot();assert(#F.webs<=2,'Aimed volley reduced')
 reset();H.hatch(F,{x=250,y=250,seed=1});H.hatch(F,{x=650,y=250,seed=2})
 local a,c=F.babies[1],F.babies[2]
 F.webs={{x=c.x,y=c.y,vx=10,vy=0,age=0,owner=a.id}};F.updateWebs(.01)
 assert(c.frozen>2 and a.frozen==0,'Cross-fire stuns other heir')
 local x,y=c.x,c.y;H.update(F,.1);assert(c.x==x and c.y==y,'Frozen heir stays still')
 H.update(F,2.2);assert(c.frozen==0,'Freeze expires')
 F.webs={{x=F.x,y=F.y,vx=10,vy=0,age=0,owner=a.id}};F.updateWebs(.01)
 assert(F.frozen>2,'Heir projectile freezes queen')
 F.webs={{x=a.x,y=a.y,vx=10,vy=0,age=0,owner=a.id}};F.updateWebs(.01);assert(a.frozen==0,'Owner immune to own projectile')
 assert(H.color(0)[1]~=H.color(1)[1] and H.color(1)[1]~=H.color(2)[1],'Distinct projectile colors')
 F.bombs={};B.spawn(F,100,100);F.bombs[1].age=2.4;B.update(F,.01);assert(F.stuck[1].r==12,'Ground web radius greatly reduced')
 reset();F.layEgg();F.phase='webs';F.shot=.7;local egg=F.eggs[1];player.x=egg.x+150;player.y=egg.y-12
 F.x=egg.x-100;F.y=egg.y;local old=F.x;F.update(.01);assert(F.x>old,'Queen moves between egg and player')
 F.webs={};F.fire(F,true);H.hatch(F,{x=250,y=250,seed=1});F.fire(F.babies[1],true);H.hatch(F,{x=650,y=250,seed=2});F.fire(F.babies[2],true)
 local g=love.graphics;local canvas=g.newCanvas(960,600);g.push('all');g.setCanvas(canvas);g.clear(.08,.08,.1);F.draw();g.pop();canvas:newImageData():encode('png','queen-heirs.png');canvas:release()
 F.reset(true);assert(#F.babies==0 and F.frozen==0 and F.eggSerial==0)
 App.state='menu';UI.draw()
 print('PASS HP-based eggs, egg damage, immortal heirs, landing volleys, cross-fire freeze/expiry/ownership, protection, small silk, render and reset')
 love.event.quit(0)
end
return T
