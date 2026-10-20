-- Warm only the actors and possible offspring of this preview map.
-- Other registered sprites stay lazy so changing the map can add resources safely.
local M={}
local directions={'up','down','left','right'}
local directional={spinner='serpent',fish='fish',jelly='jelly',worm='worm',mole='mole',waspling='waspling',larva='worm',blackbird_chick='merle',lanternfish='lanternfish'}
local sprites={magma_larva={'magma_larva'},crab={'crab_open','crab_closed','crab_dead'},abyss_fish={'abyss_fish'},light_jelly={'abyss_octopus'}}
local bosses={merle={'merle','blackbird_chick'},wasp={'wasp','wasp_ground','waspling','magma_larva'},hedgehog={'hedgehog','hedgehog_ball','worm','larva'},octopus={'crab'},storm={'merle_flight'},skeleton_head={'abyss_fish','lanternfish'},skeleton_fish={'abyss_fish','lanternfish'}}
function M.load(layout)
 if not layout then return end
 local art=require('art');local ink=require('paradise_ink');local biome=layout.biome or layout.world
 local function warm(key) return art.images[key] end
 local function facing(name,servant)
  for _,dir in ipairs(directions) do
   local key=name..'_'..dir;warm(key)
   if servant then local frame=require('servant_art').frames[key] end
   if biome==1 and name=='merle' then ink.frame(name..'_'..dir) end
  end
 end
 local function actor(kind)
  if directional[kind] then facing(directional[kind]) end
  for _,key in ipairs(sprites[kind] or {}) do warm(key) end
  if kind=='piege' then ink.frame('trap_open');ink.frame('trap_closed') end
  if kind=='scie' then ink.frame('wheel') end
  if kind=='ange' or kind=='snake' then
   local folder=kind=='snake' and 'serpent' or kind
   for _,dir in ipairs(directions) do
    require('art_filter').image('assets/monstres/paradis/'..folder..'/'..kind..'_'..dir..'.png')
    if biome==1 then ink.frame(kind..'_'..dir) end
   end
  end
 end
 for _,dir in ipairs(directions) do warm(Characters.model(dir,Characters.selected())) end
 for _,key in ipairs({'clock','skull','tear_ring'}) do warm(key) end
 if biome==1 then ink.frame('tear');ink.frame('border') end
 if biome==5 then warm('cave_wall') end
 if biome==4 then warm('ocean_coral_wall') end
 if biome==3 or biome==4 or biome==7 then
  local borders=require('biome_borders');borders.images=borders.images or {}
  borders.images[biome]=borders.images[biome] or require('art_filter').image('assets/environments/ink/wall-'..biome..'.png')
 end
 for _,e in ipairs(layout.entities) do
  if e.kind=='mob' then actor(e.type)
  elseif e.kind=='boss' then
   for _,kind in ipairs(bosses[e.type] or {}) do actor(kind);facing(directional[kind] or kind,true) end
   if e.type=='merle' then warm('merle_egg');warm('nest');warm('feather')
   elseif e.type=='storm' then warm('merle_flight');warm('black_feather')
   elseif e.type=='octopus' then warm('octopus_extended_down');warm('octopus_mantle');warm('ink_splatter');warm('ink_ground')
   elseif e.type=='skeleton_head' or e.type=='skeleton_fish' then
    for _,part in ipairs({'head','open','rib','spine','tail'}) do warm('skeleton_'..part) end
   end
  elseif e.kind=='abyss_gate' then warm('skeleton_head');warm('skeleton_open')
  elseif e.kind=='abyss_part' then warm(e.type)
  elseif e.kind=='magma_spawner' then warm('magma_nest');actor('magma_larva')
  elseif e.kind=='vent' then warm('electric_anemone')
  elseif e.kind=='nest' then warm('nest');warm('merle_egg')
  end
 end
end
return M
