local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 local F=require('final_spider');local H=require('queen_heirs');local B=require('queen_brood');local L=require('boss_liberation')
 local function reset()
  L.reset();Campaign.select(3);player.level=1;reset_level();App.state='playing';Aftermath.reset()
  F.reset(true);F.engaged=true;F.phase='webs';F.x=480;F.y=300;player.x=100;player.y=450;player.reset=false
 end
 reset();player.x=85;player.y=488;local nest=F.chooseNest();F.x=nest.x;F.y=nest.y;F.layEgg()
 local far=F.eggs[1];assert(far.x==Arena.width-55 and far.y==70 and far.hatch==1.5,'Egg uses opposite corner and fast hatch')
 nest=F.chooseNest();F.x=nest.x;F.y=nest.y;F.layEgg();assert(#F.eggs==2 and (far.x-F.eggs[2].x)^2+(far.y-F.eggs[2].y)^2>=48^2,'Remote eggs never overlap')
 F.updateEggs(1.49);assert(#F.babies==0);F.updateEggs(.02);assert(#F.babies==2 and #F.eggs==0,'Eggs hatch after 1.5 seconds')
 reset();player.x=Arena.width-100;player.y=88;nest=F.chooseNest();F.x=nest.x;F.y=nest.y;F.layEgg();assert(F.eggs[1].x==55 and F.eggs[1].y==530,'Nest follows player location')
 reset();B.spawn(F,player.x+15,player.y+12);B.update(F,.01);assert(player.reset,'Small spider contact kills')
 reset();H.hatch(F,{x=player.x+15,y=player.y+12,seed=1});F.babies[1].contactGrace=0;H.update(F,.01);assert(player.reset,'Large spider contact kills')
 reset();H.hatch(F,{x=250,y=300,seed=1});local b=F.babies[1];b.phase='charge';b.chargeX=700;b.chargeY=300;b.contactGrace=0;player.x=350;player.y=288;F.snare=2
 H.update(F,.2);assert(player.reset,'Swept large spider charge kills ensnared player')
 reset();F.phase='charge';F.chargeX=700;F.chargeY=300;player.x=550;player.y=288;F.snare=2;F.updateCharge(.2)
 assert(player.reset and F.hp==13,'Queen charge kills ensnared player without taking damage')
 reset();player.x=F.x-15;player.y=F.y-12;F.update(.01);assert(F.hp==12 and not player.reset,'Queen remains vulnerable to ordinary contact')
 reset();F.layEgg();local e=F.eggs[1];local hp=F.hp;player.x=e.x-15;player.y=e.y-12
 for i=1,20 do F.updateEggs(.01)end;assert(e.hits==1 and F.hp==hp,'Standing on egg counts once')
 for i=2,4 do player.x=100;player.y=450;F.updateEggs(.01);player.x=e.x-15;player.y=e.y-12;F.updateEggs(.01) end
 assert(#F.eggs==0 and F.hp==hp-1,'Four separate contacts break egg for one HP')
 reset();H.hatch(F,{x=300,y=300,seed=1});b=F.babies[1];H.jump(b);b.jumpHeight=80;F.jumpHeight=90;F.hp=1;F.damageGrace=0;F.damage()
 assert(L.busy());L.update(.1);assert(b.jumpHeight<80 and b.jumpHeight>0 and F.jumpHeight<90,'Airborne actors descend during liberation')
 for i=1,25 do L.update(.1)end
 assert(b.jumpHeight==0 and F.jumpHeight==0)
 player.x=100;player.y=450
 for i=1,400 do F.update(.02)end
 assert(b.y<=61 and F.y<=96,'Family gathers at top')
 local expected=math.atan2(player.y+12-b.y,player.x+15-b.x)-math.pi/2
 assert(math.abs(b.angle-expected)<.001,'Family faces player after retreat')
 reset();F.frozen=2;F.shells={{x=player.x+15,y=player.y+12,seed=1}};F.stuck={{x=300,y=300,r=12,age=1,life=7}}
 local order={};local ground,draw,drawPlayer,tear=F.drawGround,F.draw,Ending.drawPlayer,Campaign.drawTear
 F.drawGround=function(...)order[#order+1]='ground';return ground(...)end
 F.draw=function(...)order[#order+1]='boss';return draw(...)end
 Ending.drawPlayer=function(...)order[#order+1]='player';return drawPlayer(...)end
 Campaign.drawTear=function(...)order[#order+1]='tear';return tear(...)end
 love.draw();local index={};for i,name in ipairs(order)do index[name]=i end
 assert(index.ground<index.player and index.player<index.boss and index.boss<index.tear,'Ground/player/boss/tear layering')
 F.drawGround=ground;F.draw=draw;Ending.drawPlayer=drawPlayer;Campaign.drawTear=tear
 local g=love.graphics;local c=g.newCanvas(960,600)
 for _,world in ipairs({2,7})do
  Campaign.select(world);player.level=1;reset_level();App.state='playing'
  g.push('all');g.setCanvas(c);g.origin();g.clear();draw_level();require('hell_frame').draw();require('biome_edge_life').draw();g.pop()
  c:newImageData():encode('png','polished-biome-'..world..'.png')
 end
 c:release()
 print('PASS lethal contacts/charges, four-hit eggs, liberation descent, family gaze, render layers and Abyss/Hell renders')
 love.event.quit(0)
end
return T
