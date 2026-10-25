-- Compare the simulated world, not just the player's route. Quantization avoids
-- treating insignificant floating-point roundoff as a different encounter.
local S={}
local fields={'routeOffset','snailDistance','flightEdges','flightHeading','flightRetarget','flightOmega','flightRoll','cleanFromAngle','cleanFromSpeed','inkCoat','inkWobble','progress','last','grabbable','clearDelay','attackSerial','guardClock','cleanFromX','cleanFromY','fogTarget','fogHits','fogAmount','fogRows','fogFront','cleanStage','cleanClock','flightSpeed','snailAnchorX','snailAnchorY','playerX','playerY','wave','rope','lift','closing','exitX','turnClock','turnSign','cleanIndex','advanceWave','launchHeld','digDistance','arc','start','width','growth','growthDuration','eject','round','pattern','spawned','nextSpawn','orbitAngle','pushRemaining','sweepDir','pushed','entryX','entryY','entryVX','entryVY','entryAngle','entryRotation','entryLift','entryLegPhase','inputX','inputY','hitBoss','zoneStep','zoneSlot','edgeFall','edgeGone','attackDelay','attackDuration','attackInterval','attackClock','attackStarted','attackAngle','attackActive','startDirection','type','kind','x','y','cx','cy','vx','vy','tx','ty','angle','speed','age','life','time','clock',
 'snailId','pendingEggs','hits','touching','hatch','jumpCooldown','owner','id','frozen','eggSerial','volley','cast','damageGrace','contactGrace','jumpHeight','snare','phase','phaseTime','phaseAge','hp','maxHp','active','defeated','hidden','taken','dead','reset','falling',
 'fallTimer','charges','overload','cooldown','radius','r','rx','ry','w','h','rotation','seed','dir','burst','shot','bolt',
 'boltsRemaining','volleyClock','patrolClock','fishCharge','fishWave','electric','spent','committed',
 'weaveResume','weaveX','weaveY','weaveAngle','weaveCount','weaveFired','weaveSide','roamIndex','roamTime','roamSeed','volleyTell','shotAim','broodShift','delay','distance','heading','hitGrace','returnMode','liberating'}
local lists={'rings','snailRoute','inkPools','smoke','snails','digPath','route','snailHoles','trails','wind','mist','mistCuts','projectiles','strikes','holes','rain','tornadoes','current','vents','lightning','eggs','chicks',
 'minions','shots','bones','chargedFish','returnShots','webLinks','webAnchors','beams','lightSites','lumenParticles',
 'webs','stuck','bombs','bursts','babies','schools','members','pools','sparks','orbs','rods','pickups','walls','lava','spawners'}
local function actor(a,depth)
 if type(a)~='table' then return nil end
 local out={}
 if a.bossTimings then out.bossTimings={};for key,value in pairs(a.bossTimings) do out.bossTimings[key]=math.floor(value*1000+.5) end end
 for _,key in ipairs(fields) do
  local v=a[key]
  if type(v)=='number' and v==v and math.abs(v)<1e12 then out[key]=math.floor(v*1000+.5)
  elseif type(v)=='string' or type(v)=='boolean' then out[key]=v end
 end
 if depth>0 then
  if a.wrapArms then out.wrapArms={};for i,v in pairs(a.wrapArms)do out.wrapArms[tostring(i)]=actor(v,depth-1)end end
  for _,key in ipairs({'grip','unwind'})do if a[key] then out[key]=actor(a[key],depth-1)end end
  for _,key in ipairs(lists) do if type(a[key])=='table' then
   local entries={};for i,v in ipairs(a[key]) do entries[i]=actor(v,depth-1) end;out[key]=entries
  end end
 end
 return out
end
function S.snapshot()
 local out={whirl=actor(player.whirl,0),throw=actor(player.throw,0),sky=actor(require('sky_weather'),1),player=actor(player,0),tear=actor(objet.larme,0),mobs={},bosses={},
  realms=actor(Realms,2),hazards=actor(Hazards,1),magma=actor(Magma,1),arena=actor(Arena,1),
  retry=require('retry_wait').active,tearIndex=larme_indexes[player.level],
  tearTimer=math.floor((larme_timer or 0)*1000+.5),rng=Replay.rng:getState()}
 for i,m in ipairs(mobs) do out.mobs[i]=actor(m,1) end
 for i,b in ipairs({Raven,Wasp,Hedgehog,Octopus,Storm,Abyss,require('final_spider')}) do
  if b.active then out.bosses[tostring(i)]=actor(b,2) end
 end
 for i,item in ipairs(Bosses.items) do out.bosses['custom'..i]=actor(item.boss,2) end
 return out
end
function S.hash() return Replay.hash(S.snapshot()) end
return S
