local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Profile.save=function()end;Bestiary.save=function()end
 LevelLayouts.disabled=true;App.singleLevel=true;App.practice=1
 local H=require('ground_holes');local schema=require('layout_schema');local json=require('json');local g=love.graphics
 App.start(2)
 for n=1,10 do player.level=n;reset_level();assert(#Hazards.lava==0,'No generated lava puddles')end
 local loop=H.stroke({200,160,440,160,440,380,200,380,200,175},24)
 assert(H.contains(loop,320,260),'Closed brush contours fill without painting the centre')
 assert(not H.contains(loop,500,260),'Filling never leaks outside the brush contour')
 local bent=H.stroke({200,160,440,160,440,380},24)
 assert(not H.contains(bent,300,300),'Open strokes do not fill unrelated ground')
 local crossed=H.stroke({200,160,440,380,200,380,440,160,200,160},24)
 assert(H.contains(crossed,320,200) and H.contains(crossed,320,340),'Self-crossing contours fill both enclosed pockets')
 local function layout(world,zone)
  return {world=world,level=1,width=960,height=600,entities={{kind='spawn',x=740,y=500},{kind='tear',x=800,y=470},zone}}
 end
 local lava=H.stroke({0,220,240,220,240,400,0,400,0,220},32,'lava')
 local map=layout(2,lava);assert(schema.validate(map))
 local legacy=json.decode(json.encode(map));legacy.entities[#legacy.entities+1]={kind='lava',x=500,y=200,rx=42,ry=27}
 schema.migrate(legacy);assert(#legacy.entities==3 and legacy.entities[3].points,'Legacy puddles are removed without removing drawn lava')
 local original=json.encode(map)
 Arena.width=1440;assert(LevelLayouts.apply(map))
 assert(json.encode(map)==original,'Loading retains the saved points')
 assert(H.contains(Hazards.lava[1],180,300),'Lava scales to the arena')
 assert(not Arena.blocked(0,280,30,24),'The boundary wall opens where lava reaches it')
 assert(Arena.blocked(0,100,30,24),'The rest of the boundary remains solid')
 player.reset=false;player.x=165;player.y=288;Hazards.contact();assert(player.reset,'Filled lava centre is lethal')
 local snapshot=LevelLayouts.snapshot();assert(schema.validate(snapshot))
 local saved;for _,e in ipairs(snapshot.entities)do if e.kind=='lava' then saved=e end end
 assert(saved and saved.points and saved.points~=Hazards.lava[1].points,'Snapshots retain independent lava paths')
 local old=Hazards.lava[1];H.resize(old,2/3);assert(H.contains(old,120,300),'Resizing preserves brush width and filled regions')
 local function border(world,zone)
  App.start(world);Arena.width=960;Realms.holes={};Hazards.lava={}
  if world==6 then Realms.holes={zone} else Hazards.lava={zone} end
  local canvas=g.newCanvas(960,600)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);require('biome_borders').draw();g.pop()
  local pixels=canvas:newImageData();local _,_,_,cut=pixels:getPixel(10,300);local _,_,_,wall=pixels:getPixel(10,100)
  assert(cut<.01 and wall>.5,'Border is absent only at the connection to the painted zone')
  pixels:encode('png','terrain-border-'..world..'.png');pixels:release();canvas:release()
 end
 border(2,lava)
 local hole=json.decode(json.encode(lava));hole.kind='hole';border(6,hole)
 -- A single opaque draw fills the pocket, independent of how many times the brush passed there.
 local canvas=g.newCanvas(960,600)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.5,.6,.7);g.setColor(0,0,0);H.draw(loop);g.pop()
 local pixels=canvas:newImageData();local r,green,b=pixels:getPixel(320,260)
 assert(r==0 and green==0 and b==0,'The enclosed centre is black')
 pixels:release();canvas:release()
 local light=require('world_lighting');local apply=light.apply;local rendered
 light.apply=function(scene)rendered=apply(scene);return rendered end
 for _,world in ipairs({2,6}) do
  local zone=json.decode(json.encode(lava));zone.kind=world==2 and 'lava' or 'hole'
  App.sessionLayout=layout(world,zone);LevelLayouts.disabled=false;App.start(world);require('run_start').active=false
  player.reset=false;love.draw();local data=rendered:newImageData();data:encode('png','terrain-zones-'..world..'.png');data:release()
 end
 light.apply=apply
 print('PASS drawn terrain: no legacy lava puddles, closed and self-crossing fills, open strokes, lethal lava, validation, snapshots, resizing, open boundary collisions and clipped sky/lava borders')
 love.event.quit()
end
return T
