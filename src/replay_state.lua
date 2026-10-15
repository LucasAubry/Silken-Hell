-- Compare the simulated world, not just the player's route. Quantization avoids
-- treating insignificant floating-point roundoff as a different encounter.
local S={}
local fields={'type','kind','x','y','cx','cy','vx','vy','tx','ty','angle','speed','age','life','time','clock',
 'phase','phaseTime','phaseAge','hp','maxHp','active','defeated','hidden','taken','dead','reset','falling',
 'fallTimer','charges','overload','cooldown','radius','r','rx','ry','w','h','rotation','seed','dir','burst','shot','bolt',
 'boltsRemaining','volleyClock','patrolClock','fishCharge','fishWave','electric','spent','committed',
 'delay','distance','heading','hitGrace','returnMode','liberating'}
local lists={'trails','wind','mist','projectiles','strikes','holes','rain','tornadoes','current','vents','lightning','eggs','chicks',
 'minions','shots','bones','chargedFish','returnShots','webLinks','webAnchors','beams','lightSites','lumenParticles',
 'schools','members','pools','sparks','orbs','rods','pickups','walls','lava','spawners'}
local function actor(a,depth)
 if type(a)~='table' then return nil end
 local out={}
 for _,key in ipairs(fields) do
  local v=a[key]
  if type(v)=='number' and v==v and math.abs(v)<1e12 then out[key]=math.floor(v*1000+.5)
  elseif type(v)=='string' or type(v)=='boolean' then out[key]=v end
 end
 if depth>0 then
  for _,key in ipairs(lists) do if type(a[key])=='table' then
   local entries={};for i,v in ipairs(a[key]) do entries[i]=actor(v,depth-1) end;out[key]=entries
  end end
 end
 return out
end
function S.snapshot()
 local out={sky=actor(require('sky_weather'),1),player=actor(player,0),tear=actor(objet.larme,0),mobs={},bosses={},
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
