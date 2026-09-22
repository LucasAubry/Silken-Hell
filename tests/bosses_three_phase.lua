local T={}
local function level(w,n)
 Replay.recording=false;Replay.playing=false;Replay.data=nil;App.sessionLayout=nil;App.singleLevel=false;App.practice=nil
 LevelLayouts.disabled=true;Campaign.select(w);player.level=n;reset_level();App.state='playing';player.reset=false
end
local function abyss(b)
 assert(b.boss and b.phase=='lightning' and #b.bones==1 and b.bones[1].flip and b.head.w==285)
 assert(b.head.x==Arena.width-155 and b.mouth()<b.head.x,'Large head faces left from right edge')
 b.update(.7);local blue,red=0,0
 for _,p in ipairs(b.threads) do if p.red then red=red+1 else blue=blue+1 end end
 assert(blue>0 and red>0,'Both bolt colors emitted')
 b.threads={{x=player.x+15,y=player.y+12,vx=0,vy=0,age=0,seed=0,life=1}};b.update(.01)
 assert(player.charges==1 and player.illuminated>0,'Blue bolt grants charge and light')
 local kill=Hazards.kill;local killed=false;Hazards.kill=function() killed=true end
 b.threads={{x=player.x+15,y=player.y+12,vx=0,vy=0,age=0,seed=0,life=1,red=true}};b.update(.01);assert(killed,'Red bolt is lethal')
 b.setPhase('plankton');b.threads={};b.update(.7);assert(#b.plankton>0)
 killed=false;b.plankton={{x=player.x+15,y=player.y+12,vx=0,vy=0,age=0,seed=0,life=1}};b.update(.01);assert(killed,'Plankton is lethal')
 b.plankton={};b.setPhase('suction');local mx,my=b.mouth();player.x=mx-160;player.y=my-12;player.charges=0;player.electrified=0
 local x=player.x;b.update(.05);assert(player.x>x,'Suction pulls toward left-facing mouth')
 killed=false;player.x=mx-15;player.y=my-12;b.contact();assert(killed and not player.abyssHeld,'Uncharged swallow kills immediately')
 Hazards.kill=kill;player.charges=2;player.electrified=20;local hp=b.hp;b.contact();assert(player.abyssHeld==b)
 b.update(.51);assert(b.hp==hp-2 and player.abyssSpit and not player.abyssHeld and not player.reset,'Charged swallow damages and ejects safely')
 Abyss.updatePlayer(.3);player.abyssGrace=0;b.setPhase('suction');mx,my=b.mouth();player.x=mx-15;player.y=my-12;player.charges=3;player.electrified=20;b.hp=3
 b.contact();b.update(.51);assert(b.defeated and Campaign.canCollect(),'Boss defeat releases tear')
 Abyss.updatePlayer(.3)
end
function T.run()
 Online.enabled=false;Replay.disabled=true
 level(7,10);abyss(Abyss)
 local layout=require('json').decode(love.filesystem.read('tests/abyss_three_layout.json'))
 require('layout_schema').splitAbyss(layout);assert(#layout.entities==2 and layout.entities[2].type=='skeleton_fish','Editor keeps the new head encounter intact')
 LevelLayouts.disabled=false;Workshop.playLayout(layout);assert(#AbyssTerrain.parts==0 and #mobs==0);abyss(Bosses.items[1].boss)
 level(7,8);assert(not Abyss.boss and #Abyss.bones>0,'Earlier skeleton levels preserved')
 level(4,10);local o=Octopus;player.x=o.x+250-15;player.y=o.y-12
 local random=love.math.random;love.math.random=function() error('Unexpected octopus RNG') end
 o.ink();local far=o.projectiles[1];assert(far.tx<o.x and math.abs(far.ty-o.y)<.01)
 o.ink();local near=o.projectiles[2];assert(math.abs(math.sqrt((near.tx-player.x-15)^2+(near.ty-player.y-12)^2)-95)<.01)
 local px,py=near.tx,near.ty;o.inkCount=1;o.ink();assert(o.projectiles[3].tx==px and o.projectiles[3].ty==py,'Ink targeting is repeatable')
 o.crabs={};o.releaseCrabs();for _,c in ipairs(o.crabs) do assert((c.x-o.x)^2+(c.y-o.y)^2>=185^2) end
 local c={x=o.x-240,y=o.y,speed=195,age=0,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
 local reached=false
 for i=1,1200 do o.walkCrab(c,1/120,function() end);assert((c.x-o.x)^2+(c.y-o.y)^2>=184^2,'Crab goes around boss');if (c.x-player.x-15)^2+(c.y-player.y-12)^2<45^2 then reached=true;break end end
 assert(reached,'Crab reaches opposite side by circling boss')
 c.inked=true;c.frenzy=true;c.frenzyTurn=0;o.walkCrab(c,.01,function() end);love.math.random=random
 level(5,10);Hedgehog.fire();assert(#Hedgehog.projectiles==18);Hedgehog.roll();assert(math.sqrt(Hedgehog.vx^2+Hedgehog.vy^2)>=474.99)
 print('PASS three-phase abyss native/saved map, blue charge, red/plankton death, suction, charged victory, deterministic ink, crab detour, 18 faster hedgehog spikes')
 level(7,10);local tick=0
 love.update=function(dt)
  tick=tick+1
  if tick==1 then Abyss.charge(20);Abyss.update(.7);App.capture='abyss-three-lightning.png'
  elseif tick==3 then Abyss.setPhase('plankton');Abyss.threads={};Abyss.update(.7);App.capture='abyss-three-plankton.png'
  elseif tick==5 then Abyss.setPhase('suction');Abyss.plankton={};Abyss.update(.1);App.capture='abyss-three-suction.png'
  elseif tick==7 then level(4,10);App.capture='octopus-blue-purple.png'
  elseif tick==9 then level(1,10);Raven.hp=1;App.capture='egg-vertical-crack.png'
  elseif tick==11 then io.stdout:flush();love.event.quit(0) end
 end
end
return T
