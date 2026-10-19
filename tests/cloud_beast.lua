local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true
 Profile.save=function()end;Bestiary.save=function()end
 App.practice=1;App.start(6);require('run_start').active=false
 local B=require('mobs.cloud_beast');local G=require('mobs.moth_gust');local W=require('sky_weather')
 Arena.walls={};Arena.interior={};W.storm=false
 player.x=600;player.y=300;player.reset=false
 local m={type='cloud_beast',x=250,y=200,age=0,phase=0,speed=330,hitBox_width=32,hitBox_height=30,hitBox_offset_x=-16,hitBox_offset_y=-15};mobs={m}
 B.update(m,.81);assert(m.phase=='dive' and #m.sparks==1)
 B.update(m,.46);assert(m.phase=='hidden' and Realms.underground(m))
 local x=m.x;B.update(m,.5);assert(m.x~=x and not player.reset,'Travels underneath clouds')
 B.update(m,.61);assert(m.phase=='emerge' and #m.sparks>0)
 local vx,vy=m.vx,m.vy;B.update(m,.41);assert(m.phase=='charge')
 player.x=800;B.update(m,.1);assert(m.vx==vx and m.vy==vy,'Charge keeps its initial heading')
 m.is_frozen=true;x=m.x;B.update(m,.1);assert(m.x==x);m.is_frozen=false
 player.x=m.x-16;player.y=m.y-15;B.update(m,.001);assert(player.reset,'Emergent charge is lethal')
 player.reset=false
 local g=love.graphics;local c=g.newCanvas(680,300);local state=require('json').encode(require('replay_state').snapshot())
 g.push('all');g.setCanvas(c);g.origin();g.clear(.30,.40,.52)
 for i,p in ipairs({'surface','dive','hidden','emerge','charge'}) do
  local pose={x=65+(i-1)*130,y=150,phase=p,phaseTime=.2,age=2,angle=-math.pi/2,sparks={{x=65+(i-1)*130,y=150,age=.2}}}
  B.draw(pose)
 end
 g.pop();c:newImageData():encode('png','cloud-beast-phases.png');c:release()
 assert(state==require('json').encode(require('replay_state').snapshot()),'Drawing preserves simulation')
 local line=g.line;local count=0;g.line=function(...)count=count+1;return line(...)end
 G.draw({phase='windup',x=200,y=200,vx=1,vy=0,age=1});g.line=line
 assert(count==0,'No wind indicator before firing')
 local sky=require('sky').layout(1,960);local found=false
 for _,e in ipairs(sky.entities)do if e.type=='cloud_beast' then found=true end end
 assert(found and require('layout_schema').validate(sky),'Creature appears in valid native sky levels')
 print('PASS cloud beast: dive, underwater travel, emergence, locked charge, freeze, lethal contact, art, no wind tell and campaign integration');love.event.quit()
end
return T
