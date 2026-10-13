local T={}
function T.run()
 io.stdout:setvbuf('no');Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Bestiary.save=function()end;love.focus=function()end
 local g=love.graphics;local L=require('world_lighting')
 App.start(2);require('run_start').active=false;Graphics.effects=true;Graphics.quality=2
 local count=#L.collect();local active,defeated,strikes=Storm.active,Storm.defeated,Storm.strikes
 Storm.active=true;Storm.defeated=false;Storm.strikes={{x=200,y=200,age=-.2}}
 assert(#L.collect()==count,'Delayed lightning must not illuminate before its warning')
 Storm.active,Storm.defeated,Storm.strikes=active,defeated,strikes
 local scene=g.newCanvas(Arena.width,600)
 L.resize(scene)
 local walls=Arena.interior
 Arena.interior={{x=350,y=225,w=20,h=150}}
 L.lights={{x=260,y=300,radius=300,power=1,color={1,.4,.1}}}
 local function sample(data,x,y)
  return data:getPixel(math.floor(x/Arena.width*data:getWidth()),math.floor(y/600*data:getHeight()))
 end
 local function map()
  g.push('all');L.renderMap();g.pop();return L.map:newImageData()
 end
 local data=map();local shadow=sample(data,410,300);local lit=sample(data,260,450)
 assert(lit>shadow*4,'Solid obstacles must block local light')
 local face=sample(data,360,300);assert(face>shadow*3,'The wall facing the light must stay illuminated')
 data:release()
 Arena.interior[1].rotation=90
 data=map();local rotated=sample(data,410,390);data:release()
 Arena.interior[1].rotation=0
 data=map();local straight=sample(data,410,390);data:release()
 assert(rotated>straight*3,'Occlusion must follow rotated editor walls')
 Arena.interior=walls
 local state=love.math.getRandomState();local x,y=player.x,player.y
 local before=require('json').encode(LevelLayouts.snapshot())
 g.push('all');g.setCanvas(scene);g.clear(.2,.2,.2,1);g.pop()
 local original=L.apply(scene)
 assert(original~=scene and #L.lights>0,'Hell must receive real colored surface lighting')
 assert(g.getCanvas()==nil,'Compositing must restore the render target')
 assert(love.math.getRandomState()==state and player.x==x and player.y==y,'Lighting must be independent of simulation')
 assert(require('json').encode(LevelLayouts.snapshot())==before,'Lighting must preserve map and actors')
 Graphics.effects=false;assert(L.apply(scene)==scene and #L.lights==0,'Disabled effects must bypass lighting')
 Graphics.effects=true
 for quality=1,3 do
  Graphics.quality=quality;L.apply(scene)
  assert(L.map:getHeight()==({150,200,300})[quality])
 end
 local dense=g.newCanvas(Arena.width,600,{dpiscale=2});L.apply(dense)
 assert(L.output:getDPIScale()==2,'Full resolution art must retain display density')
 dense:release();scene:release();Graphics.quality=2
 print('PASS colored light, wall shadows, rotated occlusion, graphics state, quality, Retina, effect toggle and simulation isolation')
 local apply,rendered=L.apply,nil
 L.apply=function(canvas)rendered=apply(canvas);return rendered end
 local function capture(name)
  love.draw()
  local image=rendered:newImageData()
  image:encode('png',name);image:release()
 end
 App.start(2);require('run_start').active=false
 Hazards.lava={{x=320,y=300,rx=45,ry=28}};Magma.pools={};mobs={}
 Arena.interior={{x=410,y=260,w=24,h=100},{x=245,y=395,w=95,h=22,rotation=20}}
 Arena.walls={};for _,wall in ipairs(Arena.interior)do Arena.walls[#Arena.walls+1]=wall end
 player.x=345;player.y=225;Graphics.effects=false;capture('lighting-hell-before.png')
 Graphics.effects=true;capture('lighting-hell-after.png')
 App.start(6);require('run_start').active=false;require('sky_lightning').trigger(Arena.width*.5,310,1);capture('lighting-sky.png')
 App.start(7);require('run_start').active=false;capture('lighting-abyss.png')
 L.apply=apply
 print('PASS lighting scenes: Hell, lightning and Abyss');love.event.quit()
end
return T
