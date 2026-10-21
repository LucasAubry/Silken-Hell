local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;App.singleLevel=true;App.practice=1;App.start(6);require('run_start').active=false
 local G=require('mobs.moth_gust');local N=require('cloud_snail');local W=require('sky_weather')
 Arena.walls={};Arena.interior={};Realms.holes={};Realms.tornadoes={};Realms.tunnels={};W.reset();W.storm=false;W.active=false
 player.x=385;player.y=288;player.reset=false;player.falling=false;player.speed=1;player.venom=0
 local moth={type='mist_moth',x=200,y=300,vx=1,vy=0,phase='gust',phaseTime=10,age=1}
 mobs={moth}
 for _,a in ipairs({0,math.pi/4,math.pi/2,math.pi,math.pi*1.5}) do
  moth.vx,moth.vy=math.cos(a),math.sin(a);moth.x=400-moth.vx*150;moth.y=300-moth.vy*150
  local x,y=G.playerVelocity(-moth.vx*540,-moth.vy*540,true,540)
  assert(math.abs(x)<.001 and math.abs(y)<.001,'Sprint exactly cancels a head-on gust')
  x,y=G.playerVelocity(0,0,false,540)
  assert(math.abs(math.sqrt(x*x+y*y)-300)<.001,'Idle player is pushed more slowly')
 end
 moth.x=200;moth.y=300;moth.vx=1;moth.vy=0
 Replay.input={-1,0,false};local x,y=player.x,player.y;App.move(1/60)
 assert(math.abs(player.x-x)<.001 and math.abs(player.y-y)<.001,'Actual movement cancels both forces before collision')
 Replay.input={0,0,false};App.move(1/60);assert(math.abs(player.x-x-5)<.001,'Actual idle wind movement is 300 px/s')
 player.x=100;player.y=100
 local snail={type='cloud_snail',x=400,y=300,cx=300,cy=300,snailId=1,age=1,speed=66,tx=800,ty=300,roamTime=10,hitBox_width=32,hitBox_height=28,hitBox_offset_x=-16,hitBox_offset_y=-14}
 mobs={moth,snail};G.update(moth,.05)
 assert(snail.x>400 and not snail.cx and not snail.cy,'Wind discards stale digging anchor')
 local px,py=snail.x,snail.y;N.update(snail,.15)
 assert(not snail.falling,'Snail survives resuming digging after gust')
 for _,p in ipairs(W.snailHoles) do assert((p.tx-p.x)^2+(p.ty-p.y)^2<20^2,'No artificial digging bridge across forced movement') end
 player.x=snail.x-15;player.y=snail.y-12;player.reset=false;Realms.contact()
 assert(player.reset,'Touching a snail is lethal')
 print('PASS wind balance: cancellation in five directions, slower drift, stale trail anchor, resumed digging and lethal snail contact')
 love.event.quit()
end
return T
