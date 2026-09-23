local T={}
local function level(world,n)
 Replay.recording=false;Replay.playing=false;Replay.data=nil;Replay.disabled=true
 App.hardcore=false;App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;Secret.duel=nil
 LevelLayouts.disabled=true;Campaign.select(world);player.level=n;reset_level();App.state='playing';player.reset=false
end
function T.run()
 Online.enabled=false
 level(7,10);local b=Abyss
 for _,m in ipairs(mobs) do assert(m.type~='light_jelly','No octopuses in default boss fight') end
 assert(#b.lightSites==2 and b.lightSites[1].cage,'Two right-side cages')
 for _,p in ipairs(b.lightSites) do assert(p.x>Arena.width*.7 and not Arena.blocked(p.x-24,p.y-24,48,48),'Cages on right side') end
 local hp=b.hp;b.updateCages(1);assert(b.hp==hp,'Unlit cages deal no damage')
 local c=b.lightSites[1];player.x=c.x-15;player.y=c.y-12
 b.refreshLight();assert(not player.circleLight and player.illuminated==0,'Empty cage does not light the player')
 b.charge(6);local r1=b.playerLightRadius();b.charge(6);local r2=b.playerLightRadius();b.charge(6);assert(r1<r2 and r2<b.playerLightRadius())
 b.updateCages(0);assert(player.charges==0 and c.light==3 and player.electrified==0,'Cage banks all charges')
 player.x=400;player.y=500;b.updateCages(0);c.light=1;hp=b.hp;b.updateCages(1)
 assert(b.hp==hp and not b.open,'One cage neither damages nor opens boss')
 local previousSpeed=1
 for count=1,1 do
  b.lightSites[count].light=1;b.updateCages(.1)
  assert(b.hp==hp and not b.open,'Fewer than two cages leave boss invulnerable')
  assert(b.attackSpeed()>previousSpeed,'Each cage accelerates attacks');previousSpeed=b.attackSpeed()
 end
 b.clock=100;b.update(0);assert(not b.open,'Time alone never opens mouth')
 b.lightSites[2].light=1;b.updateCages(.1)
 assert(b.open and b.hp<hp and b.breathAt==b.clock,'Second cage opens mouth and enables damage')
 b.lightSites[2].light=0;hp=b.hp;b.updateCages(.1);assert(b.hp==hp,'Damage stops immediately if one cage goes dark')
 b.lightSites[2].light=1
 local lights={};b.addLights(lights);assert(#lights>=2 and lights[1][3]>70,'Cages illuminate their immediate surroundings')
 b.open=true;b.updateCages(3);for _,p in ipairs(b.lightSites) do assert(p.light==0,'Suction drains cage light') end
 level(7,10);b=Abyss;b.open=true;b.buildBones();local mx,my=b.mouth()
 player.x=mx-15;player.y=my-12;b.charge(6);b.contact()
 assert(player.reset and not player.abyssHeld,'Charged swallow is lethal despite suction immunity')
 level(7,10);b=Abyss;b.open=true;b.buildBones();mx,my=b.mouth();player.x=mx-15;player.y=my-12;b.contact()
 assert(not player.reset and player.abyssHeld==b,'Uncharged swallow is safe')
 hp=b.hp;b.spit();assert(not player.reset and not player.abyssHeld and player.abyssSpit and b.hp==hp)
 level(7,10);b=Abyss;b.nextShot=0;b.update(.01);assert(#b.threads>=3,'Boss fires blue lightning')
 local bolt=b.threads[1];bolt.x=player.x+15;bolt.y=player.y+12;bolt.vx=0;bolt.vy=0;b.update(.01);assert(player.charges>0,'Blue lightning charges player')
 level(7,10);b=Abyss;b.hp=.001;for _,p in ipairs(b.lightSites) do p.light=1 end;b.updateCages(.1)
 assert(b.defeated and not objet.larme.taken and Campaign.canCollect(),'Cage damage wins encounter')
 level(7,10);LevelLayouts.disabled=false
 Workshop.playLayout({world=7,level=10,width=960,height=600,entities={{kind='spawn',x=480,y=510},{kind='mob',type='light_jelly',x=250,y=220},{kind='boss',type='skeleton_head',x=650,y=270},{kind='tear',x=480,y=300},{kind='light',x=300,y=300}}})
 for _,m in ipairs(mobs) do assert(m.type~='light_jelly','No octopuses in authored boss fight') end
 local custom=Bosses.items[1].boss;assert(#custom.lightSites==2 and custom.lightSites[1].cage,'Authored boss also uses two right corners')
 level(7,3);local octopuses=0;for _,m in ipairs(mobs) do if m.type=='light_jelly' then octopuses=octopuses+1 end end;assert(octopuses>0,'Ordinary abyss levels retain creatures')
 level(7,8);assert(not Abyss.boss and not Abyss.lightSites[1].cage,'Earlier skeleton stages preserved')
 level(5,1);assert(Atmosphere.settings(5,1).transmission<.8,'Reduced earth lighting')
 print('PASS two right cages, banking charges, charge-dependent radius, two-cage opening/damage gate and attack acceleration, suction drain, charged death/dark survival, boss blue bolts, victory and authored bosses')
 local tick=0
 love.update=function()
  tick=tick+1
  if tick==1 then for _,w in ipairs(Worlds.order) do Profile.completed[w]=true end;App.selectedWorld=5;WorldMap.hardcore=false;WorldMap.open();App.capture='earth-cages-map.png'
  elseif tick==3 then level(5,1);Realms.larvae={{x=320,y=270,age=0},{x=365,y=300,age=.6},{x=440,y=330,age=1.2}};App.capture='earth-cages-terre.png'
  elseif tick==5 then level(7,10);mobs={};Abyss.lightSites[1].light=3;Abyss.lightSites[2].light=1;Abyss.charge(6);Abyss.charge(6);Abyss.charge(6);Abyss.fireBlue();App.capture='earth-cages-lit.png'
  elseif tick==7 then Abyss.open=true;Abyss.clock=5.8;Abyss.buildBones();App.capture='earth-cages-suction.png'
  elseif tick>=9 and tick<=15 then level(Worlds.order[tick-8],10)
  elseif tick==16 then print('PASS monster shadow rendering across all seven worlds');io.stdout:flush();love.event.quit(0) end
 end
end
return T
