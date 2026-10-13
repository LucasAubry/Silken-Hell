local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false
 Profile.save=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 local H=require('ground_holes');local json=require('json');local schema=require('layout_schema')
 App.singleLevel=true;App.practice=1;App.start(6);App.practice=nil
 for n=1,10 do player.level=n;reset_level();assert(#Realms.holes==0,'Sky levels have no generated ground holes') end
 player.level=1;reset_level()
 local shape=H.stroke({220,180,420,180,420,360},24)
 local layout={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=480,y=500},{kind='tear',x=800,y=480},shape}}
 assert(schema.validate(layout))
 local malformed=json.decode(json.encode(layout));malformed.entities[3].points={0,0,2};assert(not schema.validate(malformed))
 malformed=json.decode(json.encode(layout));malformed.entities[3].points[1]=0/0;assert(not schema.validate(malformed))
 malformed=json.decode(json.encode(layout));malformed.entities[3].points[1]=5000;assert(not schema.validate(malformed))
 local old=json.decode(json.encode(layout));old.entities[#old.entities+1]={kind='hole',x=700,y=300,rx=39,ry=28}
 schema.migrate(old);assert(#old.entities==3 and old.entities[3].points,'Migration removes only legacy oval sky holes')
 local original=json.encode(layout)
 Arena.width=1440;assert(LevelLayouts.apply(layout))
 assert(json.encode(layout)==original,'Loading does not modify saved brush points')
 assert(Realms.fallAt(450,180) and Realms.fallAt(630,280),'Strokes connect and scale to wide arenas')
 assert(not Realms.fallAt(450,300),'The empty inside of a bent stroke remains solid ground')
 assert(Realms.fallAt(663,280) and not Realms.fallAt(670,280),'Brush width scales horizontally with the arena')
 local snapshot=LevelLayouts.snapshot();assert(schema.validate(snapshot))
 local saved
 for _,e in ipairs(snapshot.entities) do if e.kind=='hole' then saved=e end end
 assert(saved and saved.points and saved.points~=Realms.holes[1].points,'Snapshots preserve independent point arrays')
 local g=love.graphics;local canvas=g.newCanvas(960,600)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.55,.68,.8);g.setColor(.03,.04,.07)
 H.draw(shape);local create=g.newMesh;g.newMesh=function()error('Hole mesh rebuilt each frame')end
 H.draw(shape);g.newMesh=create;g.pop()
 assert(json.encode(layout)==original,'Mesh cache never leaks into saved levels')
 local pixels=canvas:newImageData();assert(pixels:getPixel(300,180)<.1 and pixels:getPixel(300,300)>.4,'Visible brush footprint matches collision')
 pixels:encode('png','drawn-holes.png');pixels:release();canvas:release()
 App.sessionLayout=layout;LevelLayouts.disabled=false;App.practice=1;App.start(6);App.practice=nil
 player.reset=false;require('run_start').active=false
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then App.capture='drawn-holes-game.png'
  elseif tick==3 then print('PASS drawn holes: empty sky defaults, brush collision, wide arenas, validation, migration, snapshots and cached geometry');love.event.quit() end
 end
end
return T
