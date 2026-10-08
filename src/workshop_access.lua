local A={}
function A.id(e)
 if e.kind=='abyss_part' then return 'skeleton_fish' end
 if e.kind~='mob' and e.kind~='boss' then return end
 if e.type=='skeleton_head' then return 'skeleton_fish' end
 if e.type=='hellserpent' then return 'wasp' end
 if e.type=='gull' and e.electric then return 'electric_gull' end
 return e.type
end
function A.check(layout,worlds,bestiary)
 worlds=worlds or Worlds;bestiary=bestiary or Bestiary
 local biome=layout.biome or layout.world
 if not worlds.canEnter(biome) then return false,'Débloque le biome '..worlds.names[biome]..' pour jouer à cette carte.' end
 for _,e in ipairs(layout.entities or {})do
  local id=A.id(e)
  if id and not bestiary.seen[id] then
   local name='ce monstre'
   for _,entry in ipairs(bestiary.entries)do if entry.id==id then name=entry.name;break end end
   return false,'Découvre '..name..' dans le jeu pour tester cette carte.'
  end
 end
 return true
end
function A.warning(e,biome)
 local id=A.id(e);if not id then return end
 for _,entry in ipairs(require('bestiary').entries)do if entry.id==id and entry.world~=biome then
  return 'Seuls les joueurs ayant découvert '..entry.name..' pourront tester cette carte.'
 end end
end
A.biomeNotice='Le biome choisi réserve la carte aux joueurs qui l’ont débloqué.'
return A
