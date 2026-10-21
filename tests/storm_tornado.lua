local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Profile.save=function()end;Profile.record=function()end;Profile.recordBoss=function()end;Bestiary.save=function()end
 Replay.disabled=true;Replay.playing=false;App.hardcore=false;App.practice=nil;Secret.duel=nil
 local json=require('json');local kill=Hazards.kill
 local layout={world=6,level=10,width=960,height=600,environment={lightning=false},entities={{kind='spawn',x=480,y=300},{kind='boss',type='storm',x=480,y=140}}}
 local function setup()
  App.sessionLayout=json.decode(json.encode(layout));App.singleLevel=true;LevelLayouts.disabled=false
  App.start(6);require('run_start').active=false;require('retry_wait').reset();Replay.input={0,0,true}
  local b=Bosses.items[1].boss
  return b
 end
 local b=setup();local patterns={};local routeKeys={}
 -- The generated campaign spawn is near the bottom; edge routes must still escape.
 for _,pos in ipairs({{480,535},{60,65},{900,535}})do
  player.x=pos[1]*Arena.width/960-15;player.y=pos[2]-12
  for _=1,3 do
   b.setPhase('approach');local first,last=b.route[1],b.route[#b.route]
   assert((first.x-b.cx)^2+(first.y-b.cy)^2<(b.radius-26)^2,'Edge spawn stays inside the safe island')
   assert((last.x-b.cx)^2+(last.y-b.cy)^2>(b.radius+30)^2,'Edge route ends beyond the hole')
  end
 end
 b=setup()

 -- All three fixed routes, sampled with real phase transitions and tornado growth.
 Hazards.kill=function()end
 local function cycle()
  local previous=0
  for frame=1,3700 do
   Realms.updateTraversal(1/60);b.update(1/60)
   if b.phase=='orbit' and b.round~=previous then
    previous=b.round
    if #patterns<3 then
     patterns[#patterns+1]=b.pattern;local route=b.route;local p=route[1]
     assert((p.x-b.cx)^2+(p.y-b.cy)^2<(b.radius-26)^2,'First tornado is inside the circle')
     for i=2,#route do
      local dx,dy=math.abs(route[i].x-route[i-1].x),math.abs(route[i].y-route[i-1].y)
      assert(dx<.001 or dy<.001 or math.abs(dx-dy)<.001,'Routes use cardinal or diagonal launches')
      assert(math.sqrt(dx*dx+dy*dy)<1050*1.5,'Every hop is within flight range')
      assert(route[i].x>30 and route[i].x<Arena.width-30 and route[i].y>30 and route[i].y<570,'Tornado stays on the map')
     end
     local last=route[#route];assert((last.x-b.cx)^2+(last.y-b.cy)^2>(b.radius+30)^2,'Last tornado escapes the ring')
     routeKeys[#routeKeys+1]=json.encode(route)
    end
   end
   if b.phase=='orbit' and b.phaseAge>2.3 and b.phaseAge<2.32 then
    assert(#Realms.tornadoes>=3,'Tornadoes appear progressively')
    local a,c=Realms.tornadoes[1],Realms.tornadoes[#Realms.tornadoes]
    assert(a.growth>c.growth,'Growth is staggered')
   end
   if b.phase=='orbit' and b.phaseAge>7.5 and b.phaseAge<7.52 then
    assert(b.holeAt(b.cx+b.radius,b.cy) and not b.holeAt(b.cx,b.cy),'Continuous annular hole surrounds a safe center')
    local g=love.graphics;local canvas=g.newCanvas(Arena.width,600)
    g.push('all');g.setCanvas(canvas);g.origin();draw_level();b.draw();draw_player('down');g.pop()
    local pixels=canvas:newImageData();pixels:encode('png','storm-tornado-pattern-'..b.pattern..'.png');pixels:release();canvas:release()
   end
  end
 end
 cycle();assert(table.concat(patterns,',')=='1,2,3','Fixed pattern order')
 assert(routeKeys[1]~=routeKeys[2] and routeKeys[2]~=routeKeys[3],'Different tornado layouts')
 Hazards.kill=kill
 -- Limited push: safe in the middle, lethal only near the exit edge.
 for _,near in ipairs({false,true}) do
  b=setup();player.x=(near and Arena.width-45 or Arena.width/2+30)-15;player.y=288
  b.setPhase('sweepTell');b.setPhase('sweep');local start=player.x
  for i=1,180 do b.update(1/60);if player.reset or b.phase~='sweep' then break end end
  if near then assert(player.reset,'Edge-adjacent player falls from the sweep')
  else assert(not player.reset and math.abs(player.x-start-70)<.1,'Center player is pushed a bounded distance')end
 end
 b=setup();b.setPhase('approach');b.setPhase('orbit');b.holes[1].arc=math.pi*2
 player.x=b.cx+b.radius-15;player.y=b.cy-12;player.throw={vx=1050,vy=0,time=1.5}
 b.x=player.x+15;b.y=player.y+12;local hp=b.hp;b.contact()
 assert(b.hp==hp-1 and not player.reset,'Projected player damages the boss over its hole')
 b.contact();assert(b.hp==hp-1,'Only one hit per launch')
 player.throw=nil;player.whirl=nil;player.reset=false;b.x=b.cx;b.y=b.cy-150
 player.x=b.cx-15;player.y=b.cy-12
 b.projectiles={{x=player.x+15,y=player.y+12,vx=0,vy=0,life=1,age=0}}
 b.update(.001);assert(player.reset,'Electric feather is lethal')
 b=setup();b.setPhase('approach');b.setPhase('orbit');b.holes={}
 player.x=Arena.width/2-15;player.y=288;player.throw={vx=1050,vy=0,time=1.5}
 b.x=player.x+15+90;b.y=300;local previousHp=b.hp
 Realms.updateTraversal(.12)
 assert(b.hp==previousHp-1 and not player.reset,'Swept tornado movement hits the boss through real collision dispatch')
 b=setup();Realms.tornadoes={{x=200,y=300,cooldown=0},{x=700,y=300,cooldown=0}}
 b.setPhase('sweep');for i=1,120 do Realms.updateTraversal(1/60)end
 assert(#Realms.tornadoes==0,'Swept tornadoes leave the map and disappear')
 b=setup();b.setPhase('approach');b.setPhase('orbit');b.hp=1
 player.x=b.x-15;player.y=b.y-12;player.throw={vx=1050,vy=0,time=1.5};b.contact()
 assert(b.defeated and b.liberating,'Final projected hit completes the fight')
 require('boss_liberation').reset()
 print('PASS new Merle: three reachable deterministic routes, staggered growth, annular void, limited/edge push, electric feathers, airborne damage, tornado removal and victory')
 love.event.quit()
end
return T
