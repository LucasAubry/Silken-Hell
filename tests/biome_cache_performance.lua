local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end;Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 Profile.character=1;Profile.achievements={};Profile.skinEffects={};Profile.skinGrants={};Profile.completed={};Profile.storyTexts={}
 require('achievement_notice').init();require('skin_unlock').init()
 Graphics.quality=2;Graphics.effects=true;Graphics.showFPS=false
 local g=love.graphics;local clock=love.timer.getTime;local json=require('json');local results={}
 local H=require('ground_holes');local L=require('world_lighting')
 local function hash(data)return love.data.encode('string','hex',love.data.hash('sha256',data))end
 for _,world in ipairs({1,6,5,4,7,2,3}) do
  love.math.setRandomSeed(3910+world);App.singleLevel=true;App.practice=1;App.start(world)
  local start=require('run_start');start.active=false;start.arrival=nil
  UI.clock=4;Realms.clock=4;player.reset=false
  local output=g.newCanvas(g.getDimensions());local setCanvas=g.setCanvas
  local function draw()
   g.push('all');setCanvas(output);g.origin()
   g.setCanvas=function(target,...)return setCanvas(target or output,...)end
   love.timer.getTime=function()return 4 end
   love.draw();love.timer.getTime=clock;g.setCanvas=setCanvas;g.pop()
  end
  draw()
  local total=0;local calls=0;local geometry=H.geometry
  H.geometry=function(...)local t=clock();local r=geometry(...);total=total+clock()-t;calls=calls+1;return r end
  local mapTime=0;local map=L.renderMap
  L.renderMap=function(...)local t=clock();map(...);mapTime=mapTime+clock()-t end
  local rng=love.math.getRandomState()
  for i=1,20 do draw() end
  assert(love.math.getRandomState()==rng,'Rendering preserves gameplay RNG')
  H.geometry=geometry;L.renderMap=map
  local data=output:newImageData();local pixels=hash(data:getString());data:release()
  local hits={};local t=clock()
  for i=1,4000 do hits[i]=Arena.blocked((i*137)%Arena.width,(i*73)%600,30,24) and '1' or '0' end
  local blocked=(clock()-t)*1000
  -- Changes in place must invalidate wall caches, including editor and resize use.
  local wall=Arena.interior[1]
  if wall then wall.x=wall.x+7;wall.w=wall.w+3;wall.rotation=(wall.rotation or 0)+17 end
  draw();local changed=output:newImageData();local edited=hash(changed:getString());changed:release();output:release()
  local row={world=world,geometryMs=total*1000/20,geometryCalls=calls/20,lightsMs=mapTime*1000/20,collisionMs=blocked,pixels=pixels,edited=edited,hits=hash(table.concat(hits))}
  results[#results+1]=row
  print(string.format('BIOME_CACHE world=%d geometry=%.3fms calls=%.0f lighting=%.3fms collision4000=%.3fms',world,row.geometryMs,row.geometryCalls,row.lightsMs,row.collisionMs))
 end
 local stroke=H.stroke({100,100,180,100,180,180},20)
 local original=H.geometry(stroke);local old=stroke.points[3];stroke.points[3]=old+17
 assert(H.geometry(stroke).signature~=original.signature,'Editing an interior point invalidates geometry')
 stroke.points[3]=old;assert(H.geometry(stroke)==original,'Restoring a stroke reuses its identical geometry')
 local x0=H.bounds(stroke);stroke.radius=30;assert(H.bounds(stroke)==x0-10,'Brush resizing invalidates bounds')
 local walls=Arena.walls;local wall={x=200,y=200,w=100,h=20};Arena.walls={wall}
 assert(not Arena.blocked(250,240,2,2));wall.rotation=90;assert(Arena.blocked(250,240,2,2),'Rotating the same wall invalidates its angle')
 Arena.walls=walls
 love.filesystem.write('biome-cache-results.json' ,json.encode(results))
 print('PASS seven biome snapshots, edited walls, collision queries and unchanged rendering RNG');love.event.quit()
end
return T
