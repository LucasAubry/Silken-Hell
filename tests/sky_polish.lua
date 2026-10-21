local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;App.singleLevel=true;App.practice=1;App.start(6);require('run_start').active=false
 local N=require('cloud_snail');local W=require('sky_weather');local B=require('mobs.cloud_beast')
 Arena.walls={};Arena.interior={};Realms.holes={};Realms.tornadoes={};Realms.tunnels={};W.reset();W.active=false
 player.x=100;player.y=100;player.reset=false
 local m={type='cloud_snail',x=400,y=400,age=0,speed=66,tx=400,ty=150,roamTime=10,hitBox_width=32,hitBox_height=28,hitBox_offset_x=-16,hitBox_offset_y=-14}
 mobs={m}
 for i=1,100 do N.update(m,1/60) end
 assert(not m.falling and #W.snailHoles>2,'Snail walks without digging beneath itself')
 local last=W.snailHoles[#W.snailHoles]
 assert(math.abs(last.ty-m.y)<40,'Back-facing trail meets the snail rather than leaving a distant gap')
 m.tx,m.ty=800,m.y
 for i=1,100 do N.update(m,1/60) end
 assert(not m.falling,'A right angle does not swing the digging anchor under the snail')
 for _,p in ipairs(W.snailHoles) do assert((p.tx-p.x)^2+(p.ty-p.y)^2<15^2,'Continuous short trail segments') end
 local g=love.graphics;local c=g.newCanvas(Arena.width,600)
 g.push('all');g.setCanvas(c);g.origin();draw_level();N.drawTrail();N.draw(m);g.pop()
 c:newImageData():encode('png','snail-trail-polish.png');c:release()
 Realms.tornadoes={{x=450,y=300,cooldown=0}}
 local larva={type='cloud_beast',x=450,y=300,tx=450,ty=300,phase='hidden',phaseTime=0,age=0,roamSeed=0,sparks={},hitBox_width=32,hitBox_height=30,hitBox_offset_x=-16,hitBox_offset_y=-15}
 mobs={larva};B.update(larva,.01)
 assert(larva.phase=='hidden' and (larva.tx-450)^2+(larva.ty-300)^2>=100^2,'Larva stays hidden and seeks a clear emergence point')
 -- Actual hedgehog collision dispatch, including swept wall impact.
 App.start(5,{skipArrival=true});Arena.walls={};Arena.interior={};Realms.holes={};mobs={};player.reset=false
 local H=Hedgehog;H.active=true;H.defeated=false;H.phase='ball';H.x=400;H.y=300;H.vx=500;H.vy=0
 player.x=410;player.y=288;local x=player.x;H.contact()
 assert(not player.reset and player.x>x,'Rolling contact pushes without killing')
 H.x=player.x-10;local x2=player.x;H.contact();assert(player.x>x2 and not player.reset,'Repeated contact pushes again')
 H.x=400;player.x=410;player.y=288;Arena.walls={{x=450,y=240,w=30,h=120}};H.contact()
 assert(player.reset,'Pushed collision with a wall kills')
 H.active=false;Profile.hasCompleted=function() return true end;Profile.levels=Profile.levels or {};Profile.levels[6]=10
 assert(App.practiceLevel(6,2,true));assert(player.level==2 and require('run_start').arrival==nil,'Practice arrow target starts without arrival')
 local hud=g.newCanvas(1200,100);g.push('all');g.setCanvas(hud);g.origin();g.clear(.06,.12,.18,1);UI.buttons={};UI.gameHud();g.pop();hud:newImageData():encode('png','practice-navigation.png');hud:release()
 print('PASS sky polish: continuous snail trail and turns, clear larva emergence, repeat hedgehog shoves, lethal wall impact, direct practice navigation')
 love.event.quit()
end
return T
