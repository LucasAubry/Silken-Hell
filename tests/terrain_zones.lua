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
 -- Ignition follows the painted footprint, including long arms and filled pockets.
 player.reset=false;player.x=740;player.y=500
 Hazards.lava={bent};mobs={};LevelLayouts.spawn({type='imp',x=320,y=270})
 local walker=mobs[1]
 Burning.update(.01)
 assert(walker.burnTime==0 and #Burning.trails==0,'Dry ground inside a stroke bounding box does not ignite creatures')
 walker.x=440;walker.y=350;Burning.update(.01)
 assert(walker.burnTime==5 and #Burning.trails==1,'A distant painted arm ignites creatures immediately')
 walker.x=600;walker.y=400;Burning.update(.25)
 assert(walker.burnTime==4.75 and #Burning.trails==2,'Creatures carry visible fire after leaving lava')
 Burning.reset();walker.burnTime=0;walker.burnTrail=0
 Hazards.lava={loop};walker.x=280;walker.y=260;Burning.update(.01)
 assert(walker.burnTime==5,'Filled lava pockets ignite creatures away from the brush stroke')
 Hazards.lava={{x=440,y=350,rx=40,ry=25}};Burning.reset();walker.x=440;walker.y=350;Burning.update(.01)
 assert(walker.burnTime==5,'Legacy elliptical lava retains contact behavior')
 Hazards.lava={bent};Burning.reset();walker.burnTrail=0
 local flameCanvas=g.newCanvas(Arena.width,600)
 local function flamePixel()
  g.push('all');g.setCanvas(flameCanvas);g.origin();g.clear();Campaign.draw();g.pop()
  local data=flameCanvas:newImageData();local color={data:getPixel(440,344)}
  data:release();return color
 end
 local bare=flamePixel();Burning.update(.01);local lit=flamePixel()
 assert(math.abs(bare[1]-lit[1])+math.abs(bare[2]-lit[2])+math.abs(bare[3]-lit[3])>.1,'Fire trails remain visible above the lava surface')
 flameCanvas:release();Burning.reset();mobs={}
 local function border(world,zone)
  App.start(world);Arena.width=960;Realms.holes={};Hazards.lava={}
  if world==6 then Realms.holes={zone} else Hazards.lava={zone} end
  local canvas=g.newCanvas(960,600)
  g.push('all');g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);require('biome_borders').draw();g.pop()
  local pixels=canvas:newImageData();local _,_,_,cut=pixels:getPixel(10,300);local _,_,_,wall=pixels:getPixel(10,100)
  assert(wall>.5,'Border remains visible away from the painted zone')
  if world==2 then assert(cut>.5,'Lava reaching outside stays below the border')
  else assert(cut<.01,'A sky hole opens the border at its outside connection') end
  pixels:encode('png','terrain-border-'..world..'.png');pixels:release();canvas:release()
 end
 border(2,lava)
 local hole=json.decode(json.encode(lava));hole.kind='hole';border(6,hole)
 -- Both materials sit below the perimeter. Lava crossing any map edge must
 -- leave masonry intact; it also stays below placed/rotated walls.
 local rim=g.newCanvas(960,600,{dpiscale=1})
 local function scenePixels()
  g.push('all');g.setCanvas(rim);g.origin();g.setScissor();g.setShader();g.clear()
  Campaign.draw();g.pop();return rim:newImageData()
 end
 for _,world in ipairs({2,6}) do
  App.start(world);Arena.width=960;Realms.holes={};Hazards.lava={}
  local kind=world==2 and 'lava' or 'hole';local near=world==2 and 0 or 35
  local inset=world==2 and 10 or 30
  local probes={{inset,300},{960-inset,300},{300,inset},{300,600-inset}}
  if world==2 then
   Arena.walls={{x=0,y=0,w=960,h=22},{x=0,y=578,w=960,h=22},
    {x=0,y=0,w=22,h=600},{x=938,y=0,w=22,h=600},
    {x=460,y=300,w=100,h=24},{x=620,y=320,w=24,h=100,rotation=30}}
   probes[#probes+1]={510,312};probes[#probes+1]={632,370}
  end
  local uncut=scenePixels()
  local zones={H.stroke({near,220,near,400},20,kind),H.stroke({960-near,220,960-near,400},20,kind),
   H.stroke({220,near,420,near},20,kind),H.stroke({220,600-near,420,600-near},20,kind),
   H.stroke({0,160,180,160,180,near,420,near},20,kind)}
  if world==2 then zones[#zones+1]=H.stroke({440,285,675,415},70,kind);Hazards.lava=zones
  else Realms.holes=zones end
  local covered=scenePixels()
  for _,p in ipairs(probes) do
   local a,b,c=uncut:getPixel(p[1],p[2]);local x,y,z=covered:getPixel(p[1],p[2])
   assert(math.abs(a-x)+math.abs(b-y)+math.abs(c-z)<.02,'Walls remain above '..kind..' at '..p[1]..','..p[2])
  end
  covered:encode('png','terrain-'..kind..'-layering.png');covered:release();uncut:release()
  g.push('all');g.setCanvas(rim);g.origin();g.clear();require('biome_borders').draw();g.pop()
  local opening=rim:newImageData();local _,_,_,exitAlpha=opening:getPixel(10,160)
  if world==2 then assert(exitAlpha>.5,'Lava at an outside connection stays behind the wall')
  else assert(exitAlpha<.01,'A sky hole connection to the outside still opens the border') end
  opening:release()
 end
 rim:release()
 -- A single opaque draw fills the pocket, independent of how many times the brush passed there.
 local canvas=g.newCanvas(960,600)
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.5,.6,.7);g.setColor(0,0,0);H.draw(loop);g.pop()
 local pixels=canvas:newImageData();local r,green,b=pixels:getPixel(320,260)
 assert(r==0 and green==0 and b==0,'The enclosed centre is black')
 pixels:release();canvas:release()
 -- Material follows the union: no internal rims, deterministic rendering and
 -- no writes to the authored collision path, even on tiny/crossed brush strokes.
 local surface=require('terrain_surface')
 local branch=H.stroke({310,220,345,250,380,240,415,285,460,290},28)
 local authored=json.encode({loop,branch,crossed,bent})
 local random=love.math.getRandomState()
 local f=surface.field({loop,branch},'hole')
 assert(surface.field({loop,branch},'hole')==f,'Unchanged terrain reuses its distance field')
 local joined=g.newCanvas(960,600)
 for _,kind in ipairs({'hole','lava'}) do
  g.push('all');g.setCanvas(joined);g.origin();g.clear(.3,.4,.5)
  surface.draw({loop,branch},kind,2);g.pop()
  local data=joined:newImageData();local cr,cg,cb=data:getPixel(320,260)
  if kind=='hole' then assert(cr<.02 and cg<.02 and cb<.02,'Closed hole centre is a deep black void') end
  local sample={data:getPixel(360,250)};data:release()
  g.push('all');g.setCanvas(joined);g.origin();g.clear(.3,.4,.5)
  surface.draw({branch,loop},kind,2);g.pop()
  data=joined:newImageData();local r2,g2,b2=data:getPixel(360,250)
  assert(math.abs(sample[1]-r2)+math.abs(sample[2]-g2)+math.abs(sample[3]-b2)<.015,'Overlapping strokes do not have order-dependent seams')
  data:encode('png','terrain-union-'..kind..'.png');data:release()
 end
 joined:release()
 surface.field({H.stroke({300,200,302,204},4)},'hole')
 surface.field({crossed,bent},'hole')
 assert(json.encode({loop,branch,crossed,bent})==authored,'Materials never edit authored paths')
 assert(love.math.getRandomState()==random,'Materials never consume gameplay random state')
 -- Temporary lightning pits must shrink without invalidating the fixed union.
 local pit={x=530,y=340,rx=22,ry=17.16,seed=12,temporary=true}
 local target=g.newCanvas(960,600);local baked=surface.builds
 for frame=1,60 do
  pit.rx=22*(1-frame/70);pit.ry=17.16*(1-frame/70)
  g.push('all');g.setCanvas(target);g.origin();g.clear()
  surface.draw({loop,branch,pit},'hole',frame/60);g.pop()
 end
 assert(surface.builds-baked<=1,'Shrinking craters must not rebuild the static distance field')
 assert(surface.transient[pit],'Animated craters keep a reusable decal')
 target:release()
 local light=require('world_lighting');local apply=light.apply;local rendered
 light.apply=function(scene)rendered=apply(scene);return rendered end
 for _,world in ipairs({2,6}) do
  local zone=json.decode(json.encode(lava));zone.kind=world==2 and 'lava' or 'hole'
  local demo=layout(world,zone)
  demo.entities[#demo.entities+1]=H.stroke({355,170,400,135,455,142,500,180,485,230,440,255,385,238,355,180},22,zone.kind)
  demo.entities[#demo.entities+1]=H.stroke({458,228,505,275,560,290,590,330},25,zone.kind)
  demo.entities[#demo.entities+1]=H.stroke({650,190,690,220,675,260},15,zone.kind)
  if world==6 then
   demo.entities[#demo.entities+1]=H.stroke({575,35,755,35},20)
   demo.entities[#demo.entities+1]={kind='mob',type='gull',x=180,y=100,dir='down',speed=125}
   demo.entities[#demo.entities+1]={kind='mob',type='gull',x=660,y=430,dir='left',speed=125}
   demo.entities[#demo.entities+1]={kind='tornado',x=530,y=445}
  end
  if world==2 then
   demo.entities[#demo.entities+1]={kind='mob',type='imp',x=120,y=300}
   demo.entities[#demo.entities+1]=H.stroke({575,25,755,25},20,'lava')
   demo.entities[#demo.entities+1]={kind='wall',x=425,y=180,w=150,h=26}
   demo.entities[#demo.entities+1]={kind='wall',x=555,y=290,w=26,h=120,rotation=30}
  end
  App.sessionLayout=demo;LevelLayouts.disabled=false;App.start(world);require('run_start').active=false
  if world==2 then Burning.update(.01) end
  player.reset=false;love.draw();local data=rendered:newImageData();data:encode('png','terrain-zones-'..world..'.png');data:release()
 end
 light.apply=apply
 print('PASS drawn terrain: painted lava ignition, dry-ground exclusion, carried fire, flames above lava, no legacy lava puddles, closed and self-crossing fills, lethal lava, snapshots, resizing, walls above lava crossing all four edges, walls above nearby holes, straight and rotated walls, preserved sky openings, seamless materials, cache reuse and stable simulation')
 love.event.quit()
end
return T
