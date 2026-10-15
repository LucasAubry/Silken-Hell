local T={}
function T.run()
 io.stdout:setvbuf('no');love.focus=function()end
 Online.enabled=false;Replay.disabled=true;Replay.playing=false;Replay.ghost=false
 Profile.save=function()end;Profile.record=function()end;Bestiary.save=function()end;LevelLayouts.disabled=true
 App.singleLevel=true;App.practice=1;App.start(6);App.practice=nil;require('run_start').active=false
 local W=require('sky_weather');local B=require('mobs.sky_insects');local json=require('json')
 assert(#mobs==2 and mobs[1].type=='dragonfly' and mobs[2].type=='mist_moth','The Sky contains both new creatures')
 W.warn(250,160);W.update(1.59);assert(#W.holes==0 and not player.reset,'The entire grey warning is safe')
 local target=W.strikes[1];player.x=500;W.update(.02)
 assert(target.x==250 and target.y==160 and #W.holes==1,'A warned target is fixed and creates one hole at impact')
 assert(Realms.fallAt(250,160) and not Realms.fallAt(310,160),'Lightning holes match their dangerous footprint')
 player.x=235;player.y=148;Realms.contact();assert(player.reset and player.falling,'Entering an impact hole causes a fall')
 reset_level();assert(#W.holes==0 and #W.trails==0 and #W.mist==0,'Retry clears all weather hazards')
 W.warn(player.x+15,player.y+12);W.update(1.61);assert(player.reset and player.falling,'Being struck is lethal')
 reset_level();W.trail(100,300,400,300);player.x=235;player.y=288
 W.contact();assert(not player.reset,'A fresh trail has a short visible arming delay')
 W.update(.23);assert(player.reset and not player.falling,'The electric trail kills without a fall')
 reset_level();W.trail(260,240,260,380);W.trails[1].age=.3;player.x=180;player.y=288
 local move,slow=Input.move,Input.slow;Input.move=function()return 1,0 end;Input.slow=function()return false end
 App.move(.25);assert(player.reset and player.x<270,'Dash substeps cannot cross an electric trail')
 Input.move=move;Input.slow=slow
 reset_level();W.storm=false;local dragon=mobs[1];player.x=500;player.y=288
 local minRadius,maxRadius=math.huge,0
 for i=1,150 do
  B.update(dragon,1/60);W.update(1/60)
  local radius=math.sqrt((dragon.tx-player.x-15)^2+(dragon.ty-player.y-12)^2)
  minRadius=math.min(minRadius,radius);maxRadius=math.max(maxRadius,radius)
 end
 assert(dragon.phase=='orbit' and maxRadius-minRadius>65 and #W.trails>0,'Dragonfly zigzags around the player and leaves electricity')
 local oldTarget=dragon.tx;player.x=player.x-120;B.update(dragon,1/60)
 assert(math.abs(dragon.tx-oldTarget)>70,'The orbit follows a moving player')
 local x,y,count=dragon.x,dragon.y,#W.trails;dragon.is_frozen=true;B.update(dragon,.5)
 assert(dragon.x==x and dragon.y==y and #W.trails==count,'Frozen dragonflies cannot move or emit electricity')
 dragon.is_frozen=false
 local moth=mobs[2];for i=1,180 do B.update(moth,1/60);W.update(1/60) end
 assert(#W.mist>=30 and #W.mist<=100 and W.mist[1].radius>=68,'Moth emits plentiful large dark mist clouds')
 W.storm=false;W.update(8);assert(#W.trails==0 and #W.mist==0,'Electricity and mist expire')
 reset_level();W.warn(250,160);W.update(1.61);local snapshot=json.encode(W.holes)
 W.resize(1.5);assert(W.fallAt(375,160) and not W.fallAt(250,160),'Impact holes scale with resized arenas')
 assert(snapshot~=json.encode(W.holes))
 local layout={world=6,level=1,width=960,height=600,skyRevision=1,entities={{kind='spawn',x=480,y=300}}}
 require('sky').prepare(layout);assert(require('layout_schema').validate(layout) and #layout.entities==3,'Editor defaults include valid placements')
 local authored={world=6,level=1,width=960,height=600,entities={{kind='spawn',x=480,y=300},{kind='tear',x=750,y=300}}}
 local old=json.encode(authored.entities);require('sky').prepare(authored);assert(old==json.encode(authored.entities),'Authored maps keep their objects')
 reset_level();W.update(4.01)
 assert(#W.strikes==1 and #W.holes==0,'The environment schedules a grey warning before an automatic strike')
 local spawn=levels[player.level].player_position;local strike=W.strikes[1]
 assert((strike.x-spawn.x-15)^2+(strike.y-spawn.y-12)^2>135^2,'Automatic strikes reserve the spawn')
 for i=1,1600 do W.update(.05) end
 assert(#W.holes>1 and #W.holes<=8,'Persistent holes have a bounded budget')
 for _,kind in ipairs({'dragonfly','mist_moth'}) do
  UI.bestiaryIcon({id=kind},100,100,64)
  require('sanctuary_scene').boss({type=kind},200,100)
 end
 -- Real game captures cover warning, impact and persistent hole with both creatures.
 reset_level();player.reset=false;W.phaseTime=999
 for i=1,14 do W.fog(Arena.width*.72+math.sin(i)*45,420+math.cos(i)*35);W.mist[#W.mist].age=1 end;
 W.trail(180,190,225,220);W.trail(225,220,280,195);W.trails[1].age=.4;W.trails[2].age=.4;W.warn(Arena.width*.43,390);W.strikes[1].age=1.1
 local frames=0
 love.update=function()
  frames=frames+1
  if frames==1 then App.capture='sky-weather-warning.png'
  elseif frames==3 then W.update(.52);App.capture='sky-weather-impact.png'
  elseif frames==5 then W.update(.5);App.capture='sky-weather-hole.png'
  elseif frames==8 then print('PASS Sky ecosystem: warned fixed strikes, impact and fall deaths, reset, lethal electric trails and dash crossing, zigzag orbit and pursuit, freeze, dense dark mist, resize, editor validation and preserved authored maps');love.event.quit() end
 end
 local draw=love.draw
 love.draw=function()
  local state=json.encode(require('replay_state').snapshot());local rng=love.math.getRandomState()
  draw()
  assert(love.math.getRandomState()==rng,'Drawing never consumes gameplay RNG')
  assert(json.encode(require('replay_state').snapshot())==state,'Drawing never changes simulation state')
 end
end
return T
