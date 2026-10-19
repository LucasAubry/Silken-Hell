local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 App.practice=1;App.start(6);require('run_start').active=false
 local B=require('mobs.sky_insects');local G=require('mobs.moth_gust');local W=require('sky_weather')
 local m={type='mist_moth',x=220,y=300,age=0,phase=0,cooldown=0,speed=55,hitBox_width=30,hitBox_height=24,hitBox_offset_x=-15,hitBox_offset_y=-12}
 Arena.walls={};Arena.interior={};W.storm=false;W.strikes={};W.holes={};W.trails={};W.mist={};mobs={m}
 local contact=Hazards.contact;Hazards.contact=function()end
 player.x=355;player.y=288;player.reset=false;player.falling=false
 B.update(m,.4);assert(m.phase=='windup' and m.x==220 and player.x==355,'Tell is stationary and safe')
 B.update(m,.46);assert(m.phase=='gust' and player.x>355,'Gust pushes the player')
 assert(G.power>=500,'Wind has a strong push')
 local vx,vy=m.vx,m.vy;player.y=360;B.update(m,.01)
 assert(m.vx==vx and m.vy==vy,'Gust keeps its direction when the player dodges');assert(m.y~=300,'Moth moves while firing')
 assert(not G.reaches(m,m.x-m.vy*50,m.y+m.vx*50) and G.reaches(m,m.x+m.vx*600,m.y+m.vy*600),'Wind stays narrow but crosses the arena')
 player.y=288
 local x=player.x;Arena.walls={{x=290,y=220,w=25,h=160}}
 B.update(m,.2);assert(player.x==x,'Walls shelter the player')
 Arena.walls={};m.is_frozen=true;B.update(m,.2);assert(player.x==x,'Frozen moth cannot push');m.is_frozen=false
 B.update(m,1.5);assert(m.phase=='gust','Gust lasts for two seconds');B.update(m,.3);assert(m.phase=='recover','Gust is followed by recovery')
 x=player.x;local mx=m.x;B.update(m,.2);assert(player.x==x and m.x==mx,'Recovery gives safe crossing time')
 B.update(m,.5);assert(m.phase=='roam');B.update(m,.1);assert(m.x~=220 or m.y~=300,'Moth resumes flying')
 assert(#W.mist==0,'Moth never leaves persistent mist')
 m.phase='roam';m.cooldown=0;player.x=m.x-15;player.y=m.y+180
 G.update(m,.86);assert(m.phase=='gust' and m.vy>.99,'The next gust aims at the new player position')
 m.phase='gust';m.phaseTime=.6;m.x=220;m.y=300;m.vx=1;m.vy=0;player.x=355;player.y=288
 local other={x=450,y=300,type='cloud_snail',hitBox_width=24,hitBox_height=20,hitBox_offset_x=-12,hitBox_offset_y=-10}
 local moth={x=480,y=300,type='mist_moth',hitBox_width=30,hitBox_height=24,hitBox_offset_x=-15,hitBox_offset_y=-12}
 mobs={m,other,moth};G.update(m,.01);assert(other.x>450,'Wind pushes other monsters')
 assert(moth.x==480 and moth.y==300,'Wind never pushes another wind moth')
 m.x=220;m.y=300;player.x=355;player.y=288
 local contacts=0;Hazards.contact=function()contacts=contacts+1;if player.x>=365 then player.reset=true end end
 G.update(m,.5);assert(player.reset and contacts>0 and player.x<370,'Push checks hazards in small steps and stops on death')
 Hazards.contact=contact;player.reset=false
 local snapshot=require('json').encode(require('replay_state').snapshot())
 local canvas=love.graphics.newCanvas(Arena.width,600);love.graphics.push('all');love.graphics.setCanvas(canvas);B.draw(m);love.graphics.pop();canvas:release()
 assert(require('json').encode(require('replay_state').snapshot())==snapshot,'Wind drawing preserves simulation')
 print('PASS moth gust: tell, push, shelter, freeze, recovery, roaming, no mist, hazard substeps and draw isolation');love.event.quit()
end
return T
