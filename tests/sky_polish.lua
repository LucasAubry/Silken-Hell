local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end
 App.singleLevel=true;App.practice=1;App.hardcore=false;Secret.duel=nil
 local E=require('level_environment');local N=require('cloud_snail');local W=require('sky_weather');local H=require('ground_holes')
 local map={world=6,level=1,width=960,height=600,environment={rain=false,leaves=true,blue=true},entities={
  {kind='spawn',x=800,y=500},{kind='tear',x=850,y=100},{kind='mob',type='cloud_snail',x=180,y=280,speed=66},
  {kind='mob',type='cloud_snail',x=450,y=430,speed=66},{kind='mob',type='cloud_beast',x=600,y=180,speed=330},
  {kind='hole',x=290,y=200,radius=30,points={0,0,0,140}},
  {kind='electric_ground',x=500,y=450,radius=20,points={0,0,80,0}}}}
 assert(LayoutSchema.validate(map));App.sessionLayout=map;App.start(6);require('run_start').active=false
 assert(#Hazards.electric==0,'Legacy authored electricity is removed on load')
 for _,entity in ipairs(LevelLayouts.activeLayout.entities) do assert(entity.kind~='electric_ground') end
 assert(not E.active('rain') and E.active('leaves') and E.active('blue'),'Game reads the saved environment')
 assert(LevelLayouts.snapshot().environment.rain==false,'Environment survives replay snapshot')
 for _,world in ipairs({1,2,4,5,6,7}) do
  local old=Campaign.biome;Campaign.biome=world;App.selectedWorld=1;App.state='pause'
  assert(UI.theme()==world,'Pause uses the tested biome, not the menu selection');Campaign.biome=old
 end
 App.state='playing'
 local snail=mobs[1];snail.tx=400;snail.ty=280;snail.roamTime=20
 local ox,oy=snail.x,snail.y
 for i=1,180 do N.update(snail,1/60);assert(not snail.falling and not H.contains(Realms.holes[1],snail.x,snail.y),'Snail steers around authored holes') end
 assert((snail.x-ox)^2+(snail.y-oy)^2>30^2,'Avoidance keeps moving when a route exists')
 assert(N.unsafe(mobs[2].x,mobs[2].y,snail),'Other snails are avoided')
 local holes=Realms.holes;Realms.holes={};W.snailHoles={}
 local a,b=mobs[1],mobs[2]
 a.x,a.y,a.cx,a.cy,a.tx,a.ty,a.roamTime=180,400,nil,nil,600,400,20
 b.x,b.y,b.cx,b.cy,b.tx,b.ty,b.roamTime=420,400,nil,nil,80,400,20
 for i=1,180 do
  N.update(a,1/60);N.update(b,1/60)
  assert(not a.falling and not b.falling and (a.x-b.x)^2+(a.y-b.y)^2>=40^2,'Facing snails avoid each other and their trails')
 end
 Realms.holes=holes
 local beast=mobs[3];local bx,by=beast.x,beast.y;require('mobs.cloud_beast').update(beast,.3)
 assert((beast.x-bx)^2+(beast.y-by)^2>3^2 and beast.phase=='surface','Cloud beast moves before diving')
 W.snailHoles={};N.trail(200,180,200,320,1);N.trail(229,180,229,320,2);N.trail(245,280,290,280,1)
 local a,b=W.snailHoles[1],W.snailHoles[2];a.radius=12;b.radius=12
 assert(N.fallAt(214.5,250),'Very close trails merge their lethal footprint')
 local lighting=require('world_lighting');local apply=lighting.apply;local scene
 lighting.apply=function(canvas)scene=apply(canvas);return scene end
 local rng=love.math.getRandomState();local state=require('replay_state').hash();love.draw();lighting.apply=apply
 local pixels=scene:newImageData();pixels:encode('png','sky-polish.png');pixels:release()
 assert(state==require('replay_state').hash() and rng==love.math.getRandomState(),'Decorative drawing does not change simulation')
 local mask=N.union:newImageData()
 local middle=mask:getPixel(214,250);local authored=mask:getPixel(290,280)
 assert(middle>=.5 and authored>.5,'One union mask contains close trails and authored holes');mask:release()
 local distances=N.distanceResult:newImageData();assert(distances:getPixel(214,250)>.63,'Merged parallel trails have depth instead of an internal rim');distances:release()
 local builds=require('terrain_surface').builds;love.draw();assert(require('terrain_surface').builds==builds,'Unchanged union does not rebuild terrain')
 local g=love.graphics;local canvas=g.newCanvas(160,120)
 local options={rain=false,leaves=false,ashes=false,fireflies=false,blue=false}
 for _,option in ipairs(E.options) do
  options[option.key]=true
  g.push('all');g.setCanvas(canvas);g.origin();g.clear();E.draw(1,160,120,1,options,true);g.pop()
  local image=canvas:newImageData();local visible=0
  for y=0,119 do for x=0,159 do local r,g,b,a=image:getPixel(x,y);visible=visible+r+g+b+a end end
  image:release();assert(visible>1,'Enabled effect renders: '..option.key);options[option.key]=false
 end
 g.push('all');g.setCanvas(canvas);g.origin();g.clear();E.draw(6,160,120,1,options,true);g.pop()
 local image=canvas:newImageData();local visible=0
 for y=0,119 do for x=0,159 do local r,g,b,a=image:getPixel(x,y);visible=visible+r+g+b+a end end
 image:release();canvas:release();assert(visible==0,'All disabled effects leave a transparent image')
 local bad=require('json').decode(require('json').encode(map));bad.environment.rain='yes';assert(not LayoutSchema.validate(bad),'Environment validates booleans')
 print('PASS Sky polish: movement, avoidance, merged collision/rendering, environment persistence, electrical migration and pause biome')
 love.event.quit()
end
return T
