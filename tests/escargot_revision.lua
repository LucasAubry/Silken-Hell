local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.recording=false
 App.preview=true;App.practice=nil;App.singleLevel=true;App.hardcore=false;Secret.duel=nil
 Campaign.select(6);player.level=10;reset_level();App.state='playing'
 local S=Storm
 for _,item in ipairs(Bosses.items)do if item.kind=='storm' then S=item.boss;break end end
 assert(S.active and S.hp==9 and #S.snails==3,'Three usable snails from the start, including custom layouts')
 local kill=Hazards.kill;local deaths=0;Hazards.kill=function()deaths=deaths+1 end
 local p=S.snails[1];player.x=p.x-15;player.y=p.y-12;S.contact();assert(p.phase=='strike')
 local hp=S.hp
 for _=1,240 do S.updateSnails(1/120)end
 assert(S.hp==hp-1,'A launched snail damages the shell once')
 S.setPhase('tell');local angle=S.angle;player.x=80;player.y=480
 S.update(.2);assert(S.angle==angle,'Charge direction stays locked during warning')
 S.rings={{x=400,y=300,age=1,radius=155,angle=0}};S.phaseTime=10
 player.x=540;player.y=288;local before=deaths;S.update(.001);assert(deaths==before,'Wave gap is safe')
 player.x=385;player.y=443;S.update(.001);assert(deaths>before,'Wave arc collides')
 player.skyThrow=true;before=deaths;S.update(.001);assert(deaths==before,'Jump clears the wave');player.skyThrow=nil
 S.rings={};S.hp=1;S.snails={{x=S.x,y=S.y,phase='strike',age=0}};S.updateSnails(.01)
 assert(S.defeated and S.liberating,'Final snail triggers liberation')
 require('boss_liberation').update(2);assert(not objet.larme.taken,'Reward appears after liberation')
 Hazards.kill=kill
 local function capture(name)
  local g=love.graphics;local c=g.newCanvas(g.getDimensions());local set=g.setCanvas
  g.push('all');set(c);g.setCanvas=function(target,...)if target==nil then return set(c)end;return set(target,...)end
  love.draw();g.setCanvas=set;set();g.pop();local data=c:newImageData();data:encode('png',name..'.png');data:release();c:release()
 end
 App.preview=false;App.singleLevel=false;Campaign.select(1);player.level=10;reset_level()
 local B=require('egg_boss_arrival');assert(B.active,'Egg delivery starts on level ten')
 B.age=1.5;capture('egg-delivery');B.age=2.7;capture('egg-fall');B.age=4.6;capture('egg-landed')
 local landed=B.pose(B.duration);assert(math.abs(landed.eggY-(B.boss.y-5))<.001)
 assert(B.pose(2.9).eggY>B.pose(2.3).eggY,'Egg accelerates downwards')
 B.update(B.duration);assert(not B.active)
 Campaign.select(6);player.level=10;reset_level();require('sky_boss_arrival').active=false
 capture('escargot-boss')
 local g=love.graphics;local c=g.newCanvas(800,400);g.push('all');g.setCanvas(c);g.clear(.13,.16,.19,1)
 for i,index in ipairs({4,10})do for j,dir in ipairs({'down','up','left'})do g.setColor(1,1,1);Characters.portrait(index,100+(j-1)*180,100+(i-1)*200,135,dir)end end
 g.setCanvas();g.pop();local d=c:newImageData();d:encode('png','marine-skins-revision.png');d:release();c:release()
 print('PASS Escargot: immediate snails, damage, locked charge, wave gaps, jump, liberation; egg delivery and skin shaders')
 love.event.quit()
end
return T
