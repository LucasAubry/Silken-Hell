local C={}
local function add(kind,type,name,art,world,defaults)
    local e=defaults or {}; e.kind=kind; e.type=type; e.name=name; e.art=art; e.world=world
    C[#C+1]=e
end
add('spawn',nil,'Départ du joueur','original',0)
add('tear',nil,'Cercle de larme','tear_ring',0)
add('wall',nil,'Mur',nil,0,{w=100,h=24})
for _,v in ipairs({
 {'waspling','Petite guêpe','waspling_down',2,95},{'larva','Petit ver','worm_down',5,72},{'blackbird_chick','Petit merle','merle_down',1,77},
 {'ange','Ange gardien','catalog_ange',1,2},{'snake','Serpent céleste','catalog_snake',1,2},
 {'imp','Goule de braise','imp_down',2,85},{'spinner','Serpent tournoyant','serpent_down',2,105},
 {'fish','Poisson-lame','fish_down',4,110},{'jelly','Méduse électrique','jelly_down',4,50},{'crab','Crabe','crab_open',4,100},
 {'worm','Ver de terre','worm_down',5,90},{'mole','Taupe','mole_down',5,145},
 {'gull','Mouette','gull_down',6,140},{'light_jelly','Pieuvre abyssale','abyss_octopus',7,40},
 {'abyss_fish','Gueule des profondeurs','abyss_fish',7,75},{'lanternfish','Poisson-lanterne','lanternfish_down',7,55}
}) do add('mob',v[1],v[2],v[3],v[4],{speed=v[5]}) end
add('mob','piege','Piège de capture','catalog_trap',1)
add('mob','scie','Roue enchaînée','wheel',1,{speed=2,rota=1,radius=60})
add('mob','magma_larva','Larve de magma','magma_larva',2,{speed=245})
add('magma_spawner',nil,'Nid de larves','magma_nest',2,{rx=31,ry=23,spawnDelay=1,spawnInterval=3})
add('lava',nil,'Flaque de lave','lava',2,{rx=42,ry=27})
add('vent',nil,'Anémone électrique','electric_vent_idle',7,{rx=30,ry=23,phase=0})
add('tunnel',nil,'Tunnel (par paire)','earth_tunnel',5)
add('hole',nil,'Trou dans les nuages',nil,6,{rx=45,ry=30,seed=1})
add('tornado',nil,'Tornade','cloud_snare',6)
add('rain',nil,'Pluie',nil,6,{phase=0})
add('current',nil,'Courant marin',nil,4,{rx=50,ry=150,dx=1})
add('light',nil,'Source de lumière','tear_ring',7)
add('nest',nil,'Nid du Merle','nest',1,{rx=34,ry=25})
for _,v in ipairs({{'storm','Séraphin des orages','storm_down',6},{'merle','Le Merle noir','merle_down',1},{'wasp','Trois Sœurs de braise','wasp_down',2},{'hedgehog','Hérisson','hedgehog_down',5},{'octopus','Poulpe','octopus_extended_down',4},{'skeleton_fish','Léviathan','skeleton_head',7}}) do add('boss',v[1],v[2],v[3],v[4],{movementRate=1,attackRate=1}) end
return C
