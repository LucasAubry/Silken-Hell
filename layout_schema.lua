-- Validate data only; creators choose their own gameplay combinations.
local S={}
function S.migrate(layout)
    if type(layout)=='table' and type(layout.entities)=='table' then
        for _,e in ipairs(layout.entities) do if e.kind=='boss' and e.type=='hellserpent' then e.type='wasp' end end
    end
    return layout
end
-- The retired identifier remains readable for old saves and Workshop maps only.
local kinds={abyss_part=true,magma_spawner=true,spawn=true,tear=true,wall=true,mob=true,boss=true,nest=true,light=true,lava=true,vent=true,hole=true,tunnel=true,tornado=true,current=true,rain=true}
local mobs={magma_larva=true,ange=true,snake=true,piege=true,scie=true,spinner=true,imp=true,crab=true,abyss_fish=true,light_jelly=true,lanternfish=true,waspling=true,larva=true,blackbird_chick=true,fish=true,mole=true,worm=true,gull=true,jelly=true}
local bosses={skeleton_head=true,storm=true,merle=true,hellserpent=true,wasp=true,hedgehog=true,octopus=true,skeleton_fish=true}
function S.validate(l)
    if type(l)~='table' or not ({[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true})[l.world] or type(l.level)~='number' or l.level%1~=0 or l.level<1 or l.level>(l.world==3 and 6 or 10) then return false,'Monde ou niveau invalide.' end
    if type(l.width)~='number' or l.width<400 or l.width>4000 or l.height~=600 or type(l.entities)~='table' or #l.entities>1000 then return false,'Dimensions ou nombre d’objets invalide.' end
    if l.biome~=nil and not ({[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true})[l.biome] then return false,'Biome invalide.' end
    if l.difficulty~=nil and (type(l.difficulty)~='number' or l.difficulty%1~=0 or l.difficulty<1 or l.difficulty>5) then return false,'Difficulté entre 1 et 5.' end
    if l.difficultyExtra~=nil and (type(l.difficultyExtra)~='number' or l.difficultyExtra%1~=0 or l.difficultyExtra<0 or l.difficultyExtra>999 or (l.difficultyExtra>0 and l.difficulty~=5)) then return false,'Bonus rouge entre 0 et 999, au niveau 5.' end
    local spawn=0
    for _,e in ipairs(l.entities) do
        if type(e)~='table' or not kinds[e.kind] or (e.kind=='mob' and not mobs[e.type]) or (e.kind=='boss' and not bosses[e.type]) or (e.kind=='abyss_part' and not ({skeleton_tail=true,skeleton_rib=true,skeleton_spine=true})[e.type]) then return false,'Objet inconnu.' end
        for _,key in ipairs({'x','y','speed','w','h','rx','ry','radius','phase','dx','rota','seed','schoolId','spawnDelay','spawnInterval','movementRate','attackRate','skeletonStage','rotation'}) do
            local v=e[key]; if v~=nil and (type(v)~='number' or v~=v or math.abs(v)>10000) then return false,'Valeur numérique invalide.' end
        end
        for _,key in ipairs({'movementRate','attackRate'}) do if e[key] and (e[key]<.1 or e[key]>5) then return false,'Multiplicateur entre 0,1 et 5.' end end
        for _,key in ipairs({'spawnDelay','spawnInterval'}) do if e[key] and (e[key]<.1 or e[key]>120) then return false,'Délai entre 0,1 et 120 secondes.' end end
        if e.skeletonStage and (e.skeletonStage%1~=0 or e.skeletonStage<8 or e.skeletonStage>10) then return false,'Stade du squelette invalide.' end
        if not e.x or not e.y or e.x<0 or e.x>l.width or e.y<0 or e.y>600 then return false,'Un objet sort du terrain.' end
        for _,key in ipairs({'w','h','rx','ry','radius'}) do if e[key] and e[key]<1 then return false,'Les dimensions doivent être positives.' end end
        if e.kind=='wall' and (not e.w or not e.h) then return false,'Dimensions du mur manquantes.' end
        if e.customName~=nil and (type(e.customName)~='string' or #e.customName>60) then return false,'Nom de créature invalide.' end
        for _,key in ipairs({'electric','has_larme','elite','startUnderground'}) do if e[key]~=nil and type(e[key])~='boolean' then return false,'Option invalide.' end end
        if e.kind=='spawn' then spawn=spawn+1 end
    end
    if spawn~=1 then return false,'Il faut exactement un départ du joueur.' end
    return true
end
-- Split old whole-skeleton placements when opening them in the editor.
function S.splitAbyss(layout)
    local entities={}
    for _,e in ipairs(layout.entities) do
        if e.kind=='boss' and e.type=='skeleton_fish' then
            local stage=e.skeletonStage or (layout.world==7 and layout.level>=8 and layout.level or 10)
            local function part(typ,x,y,w,h,rotation)
                entities[#entities+1]={kind='abyss_part',type=typ,x=x,y=y,w=w,h=h,rotation=rotation or 0,id=(e.id or 'skeleton')..'-'..#entities}
            end
            local width=layout.width;local span=width*.48;local count=math.max(3,math.floor(span/205)+1)
            if stage>=9 then for i=1,count do
                local x=e.x-width*.3+(i-1)*span/(count-1);local h=95+18*math.sin(i/count*math.pi)
                part('skeleton_spine',x,e.y,22,28)
                part('skeleton_rib',x,e.y-h/2-20,18,h,-.12*180/math.pi)
                part('skeleton_rib',x,e.y+h/2+20,18,h,(math.pi+.12)*180/math.pi)
            end end
            part('skeleton_tail',e.x-width*.405,e.y,100,145)
            if stage==10 then
                entities[#entities+1]={kind='boss',type='skeleton_head',id=e.id,x=math.max(115,math.min(width-145,e.x+width*.29)),y=math.max(125,math.min(455,e.y)),movementRate=e.movementRate or 1,attackRate=e.attackRate or 1}
            end
        else entities[#entities+1]=e end
    end
    layout.entities=entities;return layout
end
return S
