local json=require 'json'
local L={disabled=false}
local fields={'x','y','speed','rota','radius','phase','rx','ry','dx','seed','w','h','electric','has_larme','elite','startUnderground','customName','schoolId','spawnDelay','spawnInterval','movementRate','attackRate','skeletonStage','rotation'}
local function copy(t)
    local r={}; for _,k in ipairs(fields) do if type(t[k])=="number" or type(t[k])=="boolean" then r[k]=t[k] end end; return r
end
function L.snapshot()
    local out={width=Arena.width,height=600,world=Campaign.world,level=player.level,entities={}}
    local function put(kind,t,typ)
        local e=copy(t); e.kind=kind; e.type=typ; e.id='e'..(#out.entities+1); out.entities[#out.entities+1]=e; return e
    end
    put('spawn',{x=player.x+15,y=player.y+12})
    for _,p in ipairs(levels[player.level].larme_position) do put('tear',{x=p.x+15,y=p.y+39}) end
    local schools={}; local nextSchool=0
    for _,m in ipairs(mobs) do
        local e=put('mob',m,m.type)
        if m.school then if not schools[m.school] then nextSchool=nextSchool+1; schools[m.school]=nextSchool end; e.schoolId=schools[m.school] end
    end
    if Raven.active then for _,n in ipairs(Raven.nests) do put('nest',n) end end
    for _,r in ipairs(Arena.interior) do put('wall',{x=r.x+r.w/2,y=r.y+r.h/2,w=r.w,h=r.h}) end
    for kind,list in pairs({magma_spawner=Magma.spawners,lava=Hazards.lava,vent=Realms.vents,hole=Realms.holes,tunnel=Realms.tunnels,tornado=Realms.tornadoes,current=Realms.current,rain=Realms.rainSites}) do
        for _,p in ipairs(list) do put(kind,p) end
    end
    for kind,b in pairs({merle=Raven,wasp=Wasp,hedgehog=Hedgehog,octopus=Octopus,storm=Storm}) do
        if b.active then put('boss',b,kind) end
    end
    if Abyss.giant then put('boss',{x=Arena.width/2,y=280,skeletonStage=Abyss.skeletonStage},'skeleton_fish') end
    if Abyss.boss then
        for i=#out.entities,1,-1 do if out.entities[i].kind=='tear' then table.remove(out.entities,i) end end
        for _,p in ipairs(Abyss.lightSites) do put('light',p) end
    end
    if Realms.custom and not Abyss.boss then for _,light in ipairs(Abyss.lightSites) do put('light',light) end end
    for _,part in ipairs(AbyssTerrain.parts) do put('abyss_part',part,part.type) end
    for _,item in ipairs(Bosses.items) do
        local b=item.boss
        if item.kind=='skeleton_fish' then
            put('boss',{x=b.origin.x,y=b.origin.y,skeletonStage=b.skeletonStage,movementRate=b.movementRate,attackRate=b.attackRate},b.headOnly and 'skeleton_head' or 'skeleton_fish')
        else put('boss',b,item.kind) end
    end
    return out
end
function L.read()
    if Replay and Replay.data and (Replay.playing or Replay.recording) then return Replay.data.layouts end
    if L.disabled then return {} end
    if App and App.sessionLayout then local l=App.sessionLayout; return {[l.world..':'..l.level]=l} end
    local data=love.filesystem.read('custom_levels.json')
    if not data then return {} end
    local ok,obj=pcall(json.decode,data)
    if ok and type(obj)=='table' and obj.version==1 and type(obj.levels)=='table' then return obj.levels end
    return {}
end
function L.spawn(e)
    local kind=e.type
    if kind=='ange' then spawn_ange(e.x,e.y,e.speed or 2,e.has_larme)
    elseif kind=='snake' then spawn_snake(e.x,e.y,e.speed or 2)
    elseif kind=='piege' then spawn_piege(e.x,e.y)
    elseif kind=='scie' then spawn_scie(e.x,e.y,e.rota or 1,e.speed or 2)
    elseif kind=='spinner' then spawn_spinner(e.x,e.y,e.speed or 100)
    elseif kind=='magma_larva' then Magma.spawn(e.x,e.y,e.speed)
    elseif kind=='imp' then spawn_imp(e.x,e.y,e.speed or 80,e.elite)
    elseif kind=='crab' then Octopus.spawnCrab(e.x,e.y,e.speed or 100)
    elseif kind=='abyss_fish' or kind=='light_jelly' or kind=='lanternfish' then Abyss.add(kind,e.x,e.y,e.speed or 55)
    elseif kind=='waspling' or kind=='larva' or kind=='blackbird_chick' then
        mobs[#mobs+1]={type=kind,x=e.x,y=e.y,cx=e.x,cy=e.y,age=0,dir='down',speed=e.speed or 90,radius=e.radius or 48,hitBox_width=22,hitBox_height=22,hitBox_offset_x=-11,hitBox_offset_y=-11}
    elseif kind=='fish' then
        local school=e.schoolId and L.schools[e.schoolId]
        if not school then school={age=0,angle=0,members={}}; Realms.schools[#Realms.schools+1]=school; if e.schoolId then L.schools[e.schoolId]=school end end
        local m={type=kind,x=e.x,y=e.y,speed=e.speed or 100,age=0,school=school,slot=2,dir='down',hitBox_width=24,hitBox_height=24,hitBox_offset_x=-12,hitBox_offset_y=-12}
        m.slot=#school.members+1; school.members[#school.members+1]=m; mobs[#mobs+1]=m
    elseif kind=='mole' or kind=='worm' or kind=='gull' or kind=='jelly' then
        Realms.add(kind,e.x,e.y,e.speed or 80,e.elite)
        if kind=='mole' then mobs[#mobs].speed=e.speed or 140 end
    else return end
    local m=mobs[#mobs]; if (kind=='worm' or kind=='mole') and e.startUnderground~=nil then m.age=e.startUnderground and 0 or (kind=='mole' and 2.7 or 1.6) end; m.startUnderground=e.startUnderground; m.has_larme=e.has_larme or false; m.electric=e.electric
    if m.has_larme then Campaign.carrier=m; objet.larme_dropped=false end
    if m.type=='scie' then setup_rotor(m) elseif m.type=='spinner' then setup_spinner(m) end
    if m.imgs then m.img=m.imgs.down or m.imgs.up end
    if kind=='ange' or kind=='snake' then m.hitBox_width=28; m.hitBox_height=42; m.hitBox_offset_x=-14; m.hitBox_offset_y=-21 end
end
function L.apply(layout)
    if not layout or type(layout.entities)~='table' then return false end
    require('layout_schema').migrate(layout)
    local scale=Arena.width/layout.width; Realms.custom=true; L.schools={}; mobs={}; Campaign.carrier=nil; Realms.schools={}
    Magma.reset(); Burning.reset(); AbyssTerrain.reset()
    Hazards.lava={}; Realms.vents={}; Realms.holes={}; Realms.tunnels={}; Realms.tornadoes={}; Realms.current={}; Realms.rainSites={}
    Arena.interior={}; while #Arena.walls>4 do table.remove(Arena.walls) end
    levels[player.level].larme_position={}; local tears=levels[player.level].larme_position
    local bossEntities={}; local nests={}
    for _,raw in ipairs(layout.entities) do
        local e=copy(raw); e.type=raw.type; e.kind=raw.kind; e.x=e.x*scale
        if e.kind=='spawn' then player.x=e.x-15; player.y=e.y-12
        elseif e.kind=='tear' then tears[#tears+1]={x=e.x-15,y=e.y-39}
        elseif e.kind=='wall' then
            local r={x=e.x-e.w*scale/2,y=e.y-e.h/2,w=e.w*scale,h=e.h}; Arena.interior[#Arena.interior+1]=r; Arena.walls[#Arena.walls+1]=r
        elseif e.kind=='magma_spawner' then Magma.addSpawner(e.x,e.y,e.spawnDelay,e.spawnInterval)
        elseif e.kind=='mob' then L.spawn(e)
        elseif e.kind=='abyss_part' then AbyssTerrain.add(e)
        elseif e.kind=='boss' then bossEntities[#bossEntities+1]=e
        elseif e.kind=='nest' then nests[#nests+1]=e
        elseif e.kind=='light' then -- assigned below
        else
            local list=({magma_spawner=Magma.spawners,lava=Hazards.lava,vent=Realms.vents,hole=Realms.holes,tunnel=Realms.tunnels,tornado=Realms.tornadoes,current=Realms.current,rain=Realms.rainSites})[e.kind]
            if list and not (e.kind=='rain' and Campaign.biome==5) then e.rx=e.rx or 35; e.ry=e.ry or 25; e.phase=e.phase or 0; e.seed=e.seed or 1; e.cooldown=0; e.dx=e.dx or 1; list[#list+1]=e end
        end
    end
    for _,b in ipairs({Raven,Wasp,Hedgehog,Octopus,Storm}) do b.active=false end
    Abyss.boss=false; Abyss.giant=false; Abyss.bones={}; Abyss.head=nil
    local lights={}
    for _,e in ipairs(layout.entities) do if e.kind=='light' then lights[#lights+1]={x=e.x*scale,y=e.y} end end
    Abyss.lightSites=lights
    Abyss.active=Campaign.biome==7
    for _,m in ipairs(mobs) do if m.type=='light_jelly' or m.type=='abyss_fish' or m.type=='lanternfish' then Abyss.active=true end end
    for _,e in ipairs(bossEntities) do if e.type=='skeleton_fish' or e.type=='skeleton_head' then Abyss.active=true end end
    if #lights>0 or #AbyssTerrain.parts>0 then Abyss.active=true end
    Bosses.load(bossEntities,nests,lights)
    local abyssBoss=false
    for _,item in ipairs(Bosses.items) do
        if (item.kind=='skeleton_fish' or item.kind=='skeleton_head') and item.boss.boss then abyssBoss=true end
    end
    if abyssBoss then
        for i=#mobs,1,-1 do if mobs[i].type=='light_jelly' or mobs[i].type=='abyss_fish' or mobs[i].type=='lanternfish' then table.remove(mobs,i) end end
    end
    local boss=Bosses.alive()
    objet.larme.taken=boss
    local p=tears[1] or {x=Arena.width/2-15,y=280}; objet.larme.x=p.x; objet.larme.y=p.y; larme_indexes[player.level]=1
    levels[player.level].player_position={x=player.x,y=player.y}
    Arena.navigationVersion=(Arena.navigationVersion or 0)+1
    return true
end
MobBehaviors.waspling=require('mobs.waspling')
MobBehaviors.larva=require('mobs.larva')
MobBehaviors.blackbird_chick=require('mobs.blackbird_chick')
function L.applyCurrent()
    return L.apply(L.read()[Campaign.world..':'..player.level])
end
return L
