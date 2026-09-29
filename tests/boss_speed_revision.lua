local T={}
local C=require 'mobs.bosses.abyss.pattern_cycle'
local J=C.jaw
local function reset(w)
 Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
 App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
 Campaign.select(w);player.level=10;reset_level();App.state='playing';player.reset=false
end
function T.run()
 io.stdout:setvbuf('no')
 local down,pad=Input.down,Input.pad;Input.pad=nil;Replay.input=nil
 for _,mode in ipairs({'accelerate','slow'}) do
  Profile.speedMode=mode
  Input.down=function() return false end;assert(Input.slow()==(mode=='accelerate'))
  Input.down=function() return true end;assert(Input.slow()==(mode=='slow'))
 end
 Profile.speedMode='accelerate';Replay.input={0,0,true};assert(Input.slow());Replay.input={0,0,false};assert(not Input.slow());Replay.input=nil;Input.down=down;Input.pad=pad
 local saved=love.filesystem.read('profile.txt');Profile.save();Profile.speedMode='slow';Profile.load();assert(Profile.speedMode=='accelerate');Profile.speedMode='slow';Profile.save();Profile.speedMode='accelerate';Profile.load();assert(Profile.speedMode=='slow');if saved then love.filesystem.write('profile.txt',saved) end;Profile.speedMode='accelerate'
 reset(6)
 for round=1,9 do for pass=0,4 do Storm.round=round;Storm.pass=pass;Storm.setPhase('flightTell');assert(Storm.dir~='down') end end
 Storm.x=Arena.width/2;Storm.y=40;Storm.hidden=false;Storm.phase='orbit';local H=require 'boss_hud';H.draw(Storm);assert(H.offsetY==0)
 reset(7);local b=Abyss;assert(b.head.w==340 and b.head.h==414 and b.open)
 assert(#J.order==4 and J.order[1]==4 and J.order[3]==6)
 for _,index in ipairs(J.order) do local x,y=J.target(b,index);assert(not J.blocked(b,x-15,y-12),'Every tooth target fits player') end
 local move=Input.move;Input.move=function() return 1,0 end
 for i=1,10 do
  b.hitGrace=0;local index=J.available(b);assert(index,'Teeth regenerate until victory')
  local x,y=J.target(b,index);player.x=x-15;player.y=y-12;player.dashing=true
  J.contact(b);assert(b.grab,'Accessible tooth attaches');J.update(b,.46);assert(b.hp==10-i,'One HP per tooth')
 end
 assert(b.defeated);Input.move=move
 reset(7);b=Abyss;C.enter(b,'traverse');player.x=Arena.width-60;player.y=540
 local start=b.swimHead.x;C.update(b,2.6);assert(not player.reset and b.swimHead.x>start and #b.bones>20 and #b.debris>0)
 assert(C.playerMinX(b)==23 and not C.blockedPlayer(b,400,500))
 local p=b.debris[1];local x,y=p.x,p.y;C.update(b,.05);assert(p.x==x and p.y>y,'Vertical bone falls straight')
 reset(7);b=Abyss;C.enter(b,'fire')
 for _,t in ipairs({0,.5,1.14,2.06,3}) do b.phaseTime=t;C.geometry(b);assert(#b.beams==0) end
 b.laserCount=2;b.phaseTime=5.7;C.geometry(b);assert(#b.beams==2)
 local beam=b.beams[1];local x,y=beam.x+math.cos(beam.angle)*450,beam.y+math.sin(beam.angle)*450
 player.x=x-15;player.y=y-12;player.dashing=false;b.visibleSince=nil;C.contact(b);assert(not player.reset,'Undrawn laser cannot kill')
 C.draw(b);b.phaseTime=5.9;C.contact(b);assert(player.reset,'Visible active laser is lethal')
 reset(7);b=Abyss;C.enter(b,'fire');b.phaseTime=2.1;C.geometry(b);player.x=450;player.y=400;C.contact(b);assert(not player.reset and not C.dangerAt(b,465,412),'Off pulse is safe')
 reset(7);b=Abyss;local kill=Hazards.kill;Hazards.kill=function() end;local phases={}
 for _=1,900 do C.update(b,1/30);phases[b.phase]=true end
 Hazards.kill=kill
 for _,name in ipairs({'roar','traverse','fire','gap','bones','settle','suction','recover','rest'}) do assert(phases[name],name..' remains reachable') end
 print('PASS revision: speed modes and persistence, replay input, no downward sky dash, fixed HUD, smaller open jaw, accessible spaced teeth and ten HP victory, straight traversal and vertical bones, slow laser pulses and visible collision')
 local frame=0;love.focus=function() end
 love.update=function()
  frame=frame+1
  if frame==1 then reset(7);App.capture='revision-abyss-head.png'
  elseif frame==3 then C.enter(Abyss,'traverse');player.x=Arena.width-60;player.y=540;C.update(Abyss,2.8);App.capture='revision-abyss-traverse.png'
  elseif frame==5 then reset(7);C.enter(Abyss,'fire');Abyss.phaseTime=1.4;C.geometry(Abyss);App.capture='revision-abyss-lasers.png'
  elseif frame==7 then App.state='settings';UI.settingsPage='general';App.capture='revision-speed-settings.png'
  elseif frame==9 then love.event.quit() end
 end
end
return T
