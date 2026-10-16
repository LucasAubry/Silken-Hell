local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 for _,w in ipairs(Worlds.order) do Profile.completed[w]=true;Hardcore.completed[tostring(w)]=true end
 App.practice=1;App.singleLevel=true;App.start(6);require('run_start').active=false
 local B=require('mobs.wind_bat')
 local m={x=200,y=300,speed=210,dx=1};player.x=500;player.y=500
 B.update(m,.2);assert(m.x==242 and m.y==300,'Rightward lane movement')
 m.dx=-1;B.update(m,.2);assert(m.x==200 and m.y==300,'Leftward lane movement')
 m.is_frozen=true;B.update(m,1);assert(m.x==200,'Freeze holds bat');m.is_frozen=false
 m.x=-47;B.update(m,.1);assert(m.x>Arena.width,'Crossing loops from opposite edge')
 m.x=200;m.dx=1;player.x=250;player.y=288;player.reset=false
 B.update(m,.4);assert(player.reset,'Swept crossing contact is lethal')
 local zone={kind='electric_ground',x=300,y=300,radius=12,points={0,-120,0,120}}
 local layout={world=6,level=1,width=Arena.width,height=600,entities={{kind='spawn',x=80,y=300},{kind='mob',type='wind_bat',x=150,y=180,speed=180,dx=-1},zone}}
 assert(require('layout_schema').validate(layout));assert(LevelLayouts.apply(layout))
 assert(#Hazards.electric==1 and mobs[1].dx==-1,'Editor options reach gameplay')
 local snapshot=LevelLayouts.snapshot();local found=false
 for _,e in ipairs(snapshot.entities) do if e.kind=='electric_ground' then found=e.points and #e.points==4 end end
 assert(found,'Electric brush survives snapshot/replay')
 player.reset=false;player.x=285;player.y=288;Hazards.contact();assert(player.reset,'Electric ground kills on contact')
 player.reset=false;player.x=230;player.y=288;Hazards.contact();assert(not player.reset,'Outside electricity is safe')
 player.x=270;player.tunnelTravel=true;require('electric_ground').contact(Hazards.electric);assert(not player.reset);player.tunnelTravel=nil
 local malformed=require('json').decode(require('json').encode(layout));malformed.entities[2].dx=0
 assert(not require('layout_schema').validate(malformed),'Direction validation')
 malformed=require('json').decode(require('json').encode(layout));malformed.entities[3].points=nil
 assert(not require('layout_schema').validate(malformed),'Electric zones require a brush footprint')
 local g=love.graphics;local canvas=g.newCanvas(1000,500)
 local octopus=Octopus;local hp,x,y=octopus.hp,octopus.x,octopus.y;local rng=love.math.getRandomState()
 g.push('all');g.setCanvas(canvas);g.origin();g.clear(.025,.04,.07,1)
 local entries={};for _,e in ipairs(Bestiary.entries) do entries[e.id]=e end
 require('bestiary_animation').draw(entries.octopus,250,250,350,4)
 require('bestiary_animation').draw(entries.lava,740,250,300,4)
 g.pop();canvas:newImageData():encode('png','celestial-bestiary.png');canvas:release()
 assert(hp==octopus.hp and x==octopus.x and y==octopus.y and rng==love.math.getRandomState(),'Preview leaves the live boss and RNG untouched')
 local A=require('winged_anchors');assert(A.menuOffset(6,216)<0 and A.menuOffset(1,216)==0 and A.menuOffset(7,216)==0,'Only winged skin shifts')
 local lx,ly=A.eye('left',1);local rx,ry=A.eye('right',1);assert(lx==-rx and ly==ry,'Profile cosmetics mirror correctly')
 App.start(6);assert(#Hazards.electric==0,'Reset clears authored electricity before reloading a map')
 assert(LevelLayouts.apply(layout));player.reset=false;App.state='playing';require('sky_weather').storm=false
 local frame=0
 love.update=function()
  frame=frame+1;UI.clock=4
  if frame==1 then App.capture='celestial-electric-ground.png'
  elseif frame==3 then
   App.state='menu';UI.menuArrival=0;Profile.character=6;Characters.browsed=6;Profile.achievements.heartbreak=true;Profile.tearExtension=true;Profile.skinEffects={hardcore=true,gold=true};App.capture='celestial-winged-menu.png'
  elseif frame==5 then
   App.selectedWorld=6;WorldMap.open();App.capture='celestial-worlds-before.png'
  elseif frame==7 then print('PASS celestial revision: bat lanes, contact, freeze, looping, electric ground, validation, replay snapshot, isolated previews and winged anchors');love.event.quit() end
 end
end
return T
