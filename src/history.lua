local H={}
H.scenes={
 {id='intro',label='Introduction'},
 {id='paradise_sky',label='Chapitre 1',world=6},
 {id='boss_egg',label='L’Œuf du Merle',unlock='boss_egg'},
 {id='boss_sky',label='L’Escargot d’orage',unlock='boss_sky'},
 {id='sky_earth',label='Chapitre 2',world=5},
 {id='boss_hedgehog',label='Le Hérisson Brise-Roche',unlock='boss_hedgehog'},
 {id='earth_ocean',label='Chapitre 3',world=4},
 {id='boss_octopus',label='La Pieuvre noire',unlock='boss_octopus'},
 {id='ocean_abyss',label='Chapitre 4',world=7},
 {id='boss_abyss',label='Le Monstre d’os',unlock='boss_abyss'},
 {id='abyss_hell',label='Chapitre 5',world=2},
 {id='boss_hell',label='Les Guêpes brûlées',unlock='boss_hell'},
 {id='hell_renaissance',label='Fin',world=3},
 {id='boss_queen',label='Le Cocon de la Reine',unlock='boss_queen'},
}
local fields={'selectedWorld','hardcore','preview','practice','singleLevel','sessionLayout','workshopMap','entryFromWorld','custom','runSkin','runEffects'}
function H.open()
 App.state='history';UI.buttons={};UI.pressed=nil;Input.index=1;love.keyboard.setTextInput(false)
end
function H.close()
 if H.saved then
  require('prologue_audio').stop()
  for _,key in ipairs(fields) do App[key]=H.saved[key] end
  player.level=H.saved.level
  Campaign.select(H.saved.world);Campaign.biome=H.saved.biome
  love.math.setRandomState(H.saved.rng)
  H.saved=nil
 end
 H.bossPreview=nil
 require('egg_boss_arrival').active=false
 require('hell_boss_arrival').active=false
 require('sky_boss_arrival').active=false
 require('octopus_boss_arrival').active=false
 require('hedgehog_boss_arrival').active=false
 require('queen_boss_arrival').active=false
 require('mobs.bosses.abyss.arrival').current=nil
 App.historyPreview=nil
 local C=require('run_start');C.active=false;C.arrival=nil;C.arrivalKind=nil;C.goAge=nil
 require('prologue').paused=false
 Replay.recording=false;Replay.input=nil
 H.open()
end
function H.startWorld(world)
 App.preview=true;App.hardcore=false;App.practice=nil;App.singleLevel=true;App.sessionLayout=nil;App.workshopMap=nil;Secret.duel=nil
 App.start(world)
end
function H.update(dt)
 if not App.historyPreview then return end
 if App.state=='prologue' then require('prologue').update(dt);return end
 if App.state=='pause' then return end
 if H.bossPreview=='egg' or H.bossPreview=='hell' or H.bossPreview=='sky' or H.bossPreview=='queen' or H.bossPreview=='octopus' or H.bossPreview=='hedgehog' then
  local B=require(H.bossPreview=='egg' and 'egg_boss_arrival' or H.bossPreview=='hedgehog' and 'hedgehog_boss_arrival' or H.bossPreview=='octopus' and 'octopus_boss_arrival' or H.bossPreview=='queen' and 'queen_boss_arrival' or H.bossPreview=='sky' and 'sky_boss_arrival' or 'hell_boss_arrival');B.update(math.min(dt,.05))
  if not B.active then H.close() end
  return
 end
 if H.bossPreview then
  local I=require('mobs.bosses.abyss.arrival')
  if I.current then I.update(I.current,math.min(dt,.05)) end
  if not I.current then H.close() end
  return
 end
 local C=require('run_start')
 if App.state=='playing' and C.arrival then C.advance(dt)
 else H.close() end
end
function H.unlocked(scene)
 if scene.id=='boss_egg' then return true end
 if scene.id=='intro' then return Profile.prologueSeen==true end
 return (Profile.transitionsSeen or {})[scene.unlock or tostring(scene.world)]==true
end
function H.play(id)
 local available=false
 for _,scene in ipairs(H.scenes) do
  if scene.id==id and H.unlocked(scene) then available=true;break end
 end
 if not available then return false end
 if H.saved then H.close() end
 H.saved={rng=love.math.getRandomState(),world=Campaign.world,biome=Campaign.biome,level=player.level}
 for _,key in ipairs(fields) do H.saved[key]=App[key] end
 App.historyPreview=true;App.preview=true;Replay.recording=false;Replay.input=nil;UI.buttons={};UI.pressed=nil
 if id=='story' then require('prologue').open(true)
 elseif id=='intro' then require('prologue_mystery').open()
 elseif id=='boss_egg' then H.startWorld(1);player.level=10;reset_level();H.bossPreview='egg'
 elseif id=='boss_queen' then H.startWorld(3);player.level=1;reset_level();H.bossPreview='queen'
 elseif id=='boss_hedgehog' then H.startWorld(5);player.level=10;reset_level();H.bossPreview='hedgehog'
 elseif id=='boss_octopus' then H.startWorld(4);player.level=10;reset_level();H.bossPreview='octopus'
 elseif id=='boss_sky' then H.startWorld(6);player.level=10;reset_level();H.bossPreview='sky'
 elseif id=='boss_hell' then H.startWorld(2);player.level=10;reset_level();H.bossPreview='hell'
 elseif id=='boss_abyss' then H.startWorld(7);player.level=10;reset_level();H.bossPreview=true
 elseif id=='abyss_hell' then H.startWorld(2);require('run_start').beginHellArrival()
 elseif id=='hell_renaissance' then H.startWorld(3);require('run_start').beginRenaissanceArrival()
 elseif id=='ocean_abyss' then H.startWorld(7);require('run_start').beginAbyssArrival()
 elseif id=='earth_ocean' then H.startWorld(4);require('run_start').beginOceanArrival()
 elseif id=='sky_earth' then H.startWorld(5);require('run_start').beginEarthArrival()
 elseif id=='paradise' then H.startWorld(1);require('run_start').beginArrival(true,true)
 else H.startWorld(6);require('run_start').beginSkyArrival(id=='paradise_sky') end
end
function H.visibleScenes(category)
 local out={}
 for _,scene in ipairs(H.scenes) do
  if (scene.unlock and 'boss' or 'chapters')==category and H.unlocked(scene) then out[#out+1]=scene end
 end
 return out
end
function H.draw()
 UI.text('Histoire',340,55,'heading',{.96,.94,.86},520,'center')
 for _,group in ipairs({{id='chapters',label='Chapitres',x=75},{id='boss',label='Boss',x=655}}) do
  UI.text(group.label,group.x,126,'body',{.96,.94,.86},470,'center')
  for i,scene in ipairs(H.visibleScenes(group.id)) do
   UI.button(scene.label,group.x,174+(i-1)*64,470,50,function()H.play(scene.id)end)
  end
 end
 UI.button('Retour',450,665,300,48,function()App.state='menu';Input.index=1 end)
end
function H.drawBack()
 UI.button('Retour',28,24,180,48,H.close)
end
function H.key(key)
 if key=='up' or key=='down' or key=='left' or key=='right' then Input.active=true;Input.navigate(key=='left' and -1 or key=='right' and 1 or 0,key=='up' and -1 or key=='down' and 1 or 0);return true end
 if key=='tab' then Input.active=true;Input.index=Input.index%math.max(1,#UI.buttons)+1;return true end
 if key=='return' or key=='kpenter' or key=='space' then
  local b=UI.buttons[Input.index];if b then UI.click(b.x+b.w/2,b.y+b.h/2) end;return true
 end
 return false
end
return H
