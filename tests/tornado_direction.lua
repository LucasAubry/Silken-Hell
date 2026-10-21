local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;App.singleLevel=true;App.practice=1;App.start(6);require('run_start').active=false
 local savedInput=Replay.input
 local function input(dx,dy) Replay.input={dx,dy,false} end
 local function enter(dx,dy)
  input(0,0)
  Realms.holes={};Realms.tornadoes={{x=Arena.width/2,y=300,cooldown=0}};Realms.tunnels={}
  player.reset=false;player.whirl=nil;player.throw=nil;player.x=Arena.width/2-15;player.y=288
  player.lastMoveX=dx;player.lastMoveY=dy;player.dashing=true
  Realms.updateTraversal(.01)
  assert(player.whirl and not player.dashing,'Entering starts the spin')
  local length=math.sqrt(dx*dx+dy*dy);if length==0 then dx,dy,length=0,1,1 end
  assert(math.abs(player.whirl.dx-dx/length)<.0001 and math.abs(player.whirl.dy-dy/length)<.0001,'Entry supplies the initial fallback')
 end
 local function steer(dx,dy,dt)
  input(dx,dy)
  local x,y=player.x,player.y;App.move(dt)
  assert(player.x==x and player.y==y,'Directional input cannot walk out of the tornado')
  Realms.clock=.2;Realms.updateTraversal(dt)
 end
 local function checkThrow(dx,dy)
  local length=math.sqrt(dx*dx+dy*dy);dx,dy=dx/length,dy/length
  local throw=assert(player.throw)
  assert(not player.whirl and math.abs(throw.vx-dx*1050)<.0001 and math.abs(throw.vy-dy*1050)<.0001,'Launch uses the most recent nonzero direction during the spin')
  assert(math.abs(math.sqrt(throw.vx^2+throw.vy^2)-1050)<.001,'Cardinal, diagonal and analog input share launch speed')
  input(-dx,-dy)
  local x,y=player.x,player.y;Realms.updateTraversal(.04)
  assert(math.abs(player.x-x-dx*42)<.01 and math.abs(player.y-y-dy*42)<.01,'After launch, changing input no longer steers the throw')
  assert(Realms.tornadoes[1].cooldown>1,'Cooldown prevents immediate recapture')
 end
 for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1},{.2,.1}})do
  enter(0,1);steer(-d[1],-d[2],.2);assert(player.whirl,'Spin lasts until release')
  steer(d[1],d[2],.46);checkThrow(d[1],d[2])
 end
 enter(1,0);steer(0,-1,.2);steer(0,0,.46);checkThrow(0,-1)
 enter(-1,0);steer(0,0,.66);checkThrow(-1,0)
 enter(0,0);steer(0,0,.66);checkThrow(0,1)
 enter(0,1);steer(1,0,.66);checkThrow(1,0)
 Realms.updateTraversal(1.5);assert(player.reset and not player.throw,'Launch still falls at the sky edge')
 enter(1,0);steer(0,1,.66);checkThrow(0,1)
 Realms.holes={require('ground_holes').stroke({player.x+15,player.y+75},20)}
 Realms.updateTraversal(.2);assert(not player.reset and player.throw,'Thrown player flies across drawn void zones')
 -- Capture is checked along the whole flight, even when a frame crosses a vortex.
 enter(1,0);steer(1,0,.66)
 local target={x=player.x+15+90,y=player.y+12,cooldown=0}
 Realms.tornadoes[2]=target
 Realms.holes={require('ground_holes').stroke({target.x,target.y},100)}
 Realms.updateTraversal(.2)
 assert(player.whirl and player.whirl.tornado==target and not player.throw and not player.reset,'Flight chains into another tornado over the void')
 Realms.contact();assert(not player.reset,'Spinning remains above the void')
 steer(-1,0,.66);assert(player.throw and player.throw.vx<0,'Second tornado launches in the newly chosen direction')
 -- A short flight ending over a hole must fall as soon as its lift expires.
 player.whirl=nil;player.x=Arena.width/2-15;player.y=288
 player.throw={vx=1050,vy=0,time=.01};Realms.tornadoes={}
 Realms.holes={require('ground_holes').stroke({Arena.width/2+10,300},60)}
 Realms.updateTraversal(.02)
 assert(player.reset and not player.throw,'Landing over void still falls')
 -- Leaving any screen edge kills immediately, before the flight timer expires.
 for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
  player.reset=false;player.falling=false;player.whirl=nil;Realms.tornadoes={};Realms.holes={}
  player.x=(d[1]>0 and Arena.width-2 or d[1]<0 and 2 or Arena.width/2)-15
  player.y=(d[2]>0 and Arena.height-2 or d[2]<0 and 2 or 300)-12
  player.throw={vx=d[1]*1050,vy=d[2]*1050,time=1.5}
  Realms.updateTraversal(.02)
  assert(player.reset and player.falling and not player.throw,'Flying out of each map edge kills immediately')
 end
 player.reset=false;player.falling=false;player.x=Arena.width/2-15;player.y=288
 player.throw={vx=1050,vy=0,time=1.2}
 local function state() return Replay.canonical({player.x,player.y,player.throw,player.death}) end
 local before=state();local rng=love.math.getRandomState()
 local canvas=love.graphics.newCanvas(1200,750)
 love.graphics.push('all');love.graphics.setCanvas(canvas);love.graphics.clear(.08,.15,.22,1)
 draw_player('right');love.graphics.pop()
 assert(state()==before and love.math.getRandomState()==rng,'Flight effects never change simulation or replay RNG')
 canvas:release();player.throw=nil
 Campaign.biome=1;Realms.custom=true;enter(0,1);steer(-1,0,.66);checkThrow(-1,0)
 Realms.reset(6,1);assert(not player.whirl and not player.throw,'Reset clears traversal state')
 Replay.input=savedInput
 print('PASS tornado steering: eight headings, analog normalization, final-frame changes, release/entry fallback, controlled spin, fixed flight, cooldown, void flight, chained capture, landing hazards, custom arenas and replay-aware input')
 love.event.quit()
end
return T
