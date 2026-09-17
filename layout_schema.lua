-- Validate data only; creators choose their own gameplay combinations.
local S={}
function S.migrate(layout)
    if type(layout)=='table' and type(layout.entities)=='table' then
        for _,e in ipairs(layout.entities) do if e.kind=='boss' and e.type=='hellserpent' then e.type='wasp' end end
    end
    return layout
end
-- The retired identifier remains readable for old saves and Workshop maps only.
local kinds={magma_spawner=true,spawn=true,tear=true,wall=true,mob=true,boss=true,nest=true,light=true,lava=true,vent=true,hole=true,tunnel=true,tornado=true,current=true,rain=true}
local mobs={magma_larva=true,ange=true,snake=true,piege=true,scie=true,spinner=true,imp=true,crab=true,abyss_fish=true,light_jelly=true,lanternfish=true,waspling=true,larva=true,blackbird_chick=true,fish=true,mole=true,worm=true,gull=true,jelly=true}
local bosses={storm=true,merle=true,hellserpent=true,wasp=true,hedgehog=true,octopus=true,skeleton_fish=true}
function S.validate(l)
    if type(l)~='table' or not ({[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true})[l.world] or type(l.level)~='number' or l.level%1~=0 or l.level<1 or l.level>(l.world==3 and 6 or 10) then return false,'Monde ou niveau invalide.' end
    if type(l.width)~='number' or l.width<400 or l.width>4000 or l.height~=600 or type(l.entities)~='table' or #l.entities>1000 then return false,'Dimensions ou nombre d’objets invalide.' end
    local spawn=0
    for _,e in ipairs(l.entities) do
        if type(e)~='table' or not kinds[e.kind] or (e.kind=='mob' and not mobs[e.type]) or (e.kind=='boss' and not bosses[e.type]) then return false,'Objet inconnu.' end
        for _,key in ipairs({'x','y','speed','w','h','rx','ry','radius','phase','dx','rota','seed','schoolId'}) do
            local v=e[key]; if v~=nil and (type(v)~='number' or v~=v or math.abs(v)>10000) then return false,'Valeur numérique invalide.' end
        end
        if not e.x or not e.y or e.x<0 or e.x>l.width or e.y<0 or e.y>600 then return false,'Un objet sort du terrain.' end
        for _,key in ipairs({'w','h','rx','ry','radius'}) do if e[key] and e[key]<1 then return false,'Les dimensions doivent être positives.' end end
        if e.kind=='wall' and (not e.w or not e.h) then return false,'Dimensions du mur manquantes.' end
        for _,key in ipairs({'electric','has_larme','elite'}) do if e[key]~=nil and type(e[key])~='boolean' then return false,'Option invalide.' end end
        if e.kind=='spawn' then spawn=spawn+1 end
    end
    if spawn~=1 then return false,'Il faut exactement un départ du joueur.' end
    return true
end
return S
