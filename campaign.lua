local C={world=1,names=Worlds.names,data={{},{},{},{},{},{},{}}}
C.titles={
 {'Le premier souffle','Les veilleurs','La ronde des lames','Le jardin des épines','Les ailes captives','Le silence des serpents','Les quatre gardiens','Le chœur brisé','Les portes du ciel','Le Merle noir'},
 {'La chute','Les braises','Le cercle des damnés','La forge','Les ailes de cendre','Le fleuve noir','Les sept sceaux','La gueule du feu','Le trône vide','La Guêpe solitaire'}
}
function C.install()
    -- Keep the authored positions and original encounters, before procedural walls were added.
    C.original=levels
    for w=1,7 do for n=1,10 do C.data[w][n]={} end end
    for w=9,14 do C.data[w]={{}} end
    C.floor=love.graphics.newCanvas(800,600)
    love.graphics.setCanvas(C.floor); love.graphics.clear(0.105,0.035,0.04)
    for y=0,600,40 do for x=0,800,60 do
        local shade=0.07+((x*7+y*3)%17)/400
        love.graphics.setColor(shade+0.07,shade*0.45,shade*0.48)
        love.graphics.polygon('fill',x+2,y+2,x+57,y+4,x+55,y+37,x+4,y+35)
    end end
    for i=1,27 do
        local x=(i*137)%800; local y=(i*89)%600
        love.graphics.setColor(0.85,0.16,0.045,0.55); love.graphics.line(x,y,x+12,y+15,x+7,y+27,x+21,y+44)
    end
    love.graphics.setCanvas(); love.graphics.setColor(1,1,1)
    reset_level=C.reset; draw_level=C.draw
end
function C.select(world) C.world=world; C.biome=Worlds.biome(world,player and player.level or 1); levels=C.data[world] end
function C.positions(n)
    if C.biome==1 then
        local points={}
        for _,p in ipairs(C.original[n].larme_position) do
            if p.x>=0 then points[#points+1]={x=math.max(60,math.min(Arena.width-90,Arena.mapX(p.x))),y=p.y} end
        end
        return points
    end
    local ring={{.5,85},{.82,135},{.9,280},{.82,460},{.5,510},{.18,460},{.1,280},{.18,135}}
    local indexes=n==8 and {1,2,3,4,5,6,7,8} or n%2==1 and {1,3,5,7} or {2,4,6,8}
    local points={}
    for _,i in ipairs(indexes) do local p=ring[((i-1+(C.biome==2 and 2 or 0))%8)+1]; points[#points+1]={x=math.max(60,math.min(Arena.width-90,p[1]*Arena.width-15)),y=p[2]-20} end
    return points
end
function C.reset()
    Aftermath.reset()
    AbyssTerrain.reset()
    C.biome=Worlds.biome(C.world,player.level)
    local world=C.biome; local n=(Worlds.isSecret(C.world)) and 10 or player.level
    BossFX.reset()
    if Bosses then Bosses.reset() end
    local previousSide=C.lastSide
    load_mob(); ghosts={}; just_loaded=false; larme_timer=0; larme_float_timer=0
    larme_interval=world==2 and (n==8 and 1.25 or 2.6) or 1.5
    player.speed=1; player.original_speed=1; player.is_frozen=false; player.freeze_timer=0; player.reset=false
    player.lastMoveX=0; player.lastMoveY=1
    player.hitBox_width=30; player.hitBox_height=24; player.hitBox_offset_x=0; player.hitBox_offset_y=0
    local boss=n==10 and (world<=2 or world==5 or world==4 or world==7 or world==6)
    player.x=world==1 and Arena.mapX(C.original[n].player_position.x) or Arena.width/2-15; player.y=boss and 505 or 265
    local level={player_position={x=player.x,y=player.y},larme_position=C.positions(n),aureole_position={x=0,y=0}}
    if boss then level.larme_position={{x=Arena.width/2-15,y=280}} end
    levels[player.level]=level
    Arena.build(level.player_position,level.larme_position,boss)
    C.starts=C.starts or {{},{},{},{},{},{},{}}
    C.starts[world]=C.starts[world] or {}
    local count=#level.larme_position
    local start=C.starts[world][player.level]
    if not start then
        local previous=C.lastSide or 0; local wanted=previous%4+1
        start=1; local best=math.huge
        for i,p in ipairs(level.larme_position) do
            local a=math.atan2(p.y+20-300,p.x+15-Arena.width/2)
            local side=math.floor((a+math.pi/4)%(2*math.pi)/(math.pi/2))+1
            local distance=side==wanted and 0 or side==previous and 2 or 1
            if distance<best then best=distance; start=i end
        end
        C.starts[world][player.level]=start
    end
    larme_indexes[player.level]=start
    local first=level.larme_position[start] or {x=-100,y=-100}
    objet.larme.x=first.x; objet.larme.y=first.y
    if count>0 and not boss then
        local a=math.atan2(first.y+20-300,first.x+15-Arena.width/2)
        C.lastSide=math.floor((a+math.pi/4)%(2*math.pi)/(math.pi/2))+1
    end
    objet.larme.abyssHeld=nil; objet.larme.taken=boss; objet.larme_dropped=true
    if not boss and C.world~=3 then
        if world>=4 then Realms.spawn(world,n)
        elseif world==2 then C.spawnHell(n) else
            _G['mob_lv'..n]()
            -- The old 8/9 sketches had carriers but no trap to release their tear.
            if n==8 or n==9 then
                spawn_piege(180,170); spawn_piege(610,470)
            end
        end
    end
    C.carrier=nil
    for _,m in ipairs(mobs) do
        m.x=Arena.mapX(m.x)
        if world==1 and m.type~='piege' and m.speed then m.speed=m.speed*1.08 end
        if m.has_larme then C.carrier=m; objet.larme_dropped=false end
        if m.type=='scie' then m.hitBox_width=42; m.hitBox_height=42; m.hitBox_offset_x=-21; m.hitBox_offset_y=-21 end
        if m.type=='ange' or m.type=='snake' then m.hitBox_width=28; m.hitBox_height=42; m.hitBox_offset_x=-14; m.hitBox_offset_y=-21 end
        local ox,oy=m.hitBox_offset_x or 0,m.hitBox_offset_y or 0
        local x,y=Arena.clearSpot(m.x+ox,m.y+oy,m.hitBox_width,m.hitBox_height)
        m.x=x-ox; m.y=y-oy
        -- Sprites are visible from the first frame, including stationary traps.
        if not m.img and m.imgs then m.img=m.imgs[m.dir] or m.imgs.up end
    end
    for _,m in ipairs(mobs) do
        if m.type=='spinner' then setup_spinner(m)
        elseif m.type=='scie' then setup_rotor(m) end
    end
    if C.carrier then C.lastSide=previousSide end
    C.clearTearSites()
    Raven.reset(boss and world==1); Wasp.reset(boss and world==2)
    Hedgehog.reset(boss and world==5)
    Octopus.reset(boss and world==4)
    Storm.reset(boss and world==6)
    Hazards.reset(world==2,n)
    Arena.reconcile()
    Realms.reset(world,n)
    Ocean.reset(world)
    Abyss.reset(world,n)
    Magma.reset()
    if LevelLayouts and C.world~=3 and not Worlds.isSecret(C.world) then LevelLayouts.applyCurrent() end
    if not Realms.custom then C.clearGroundSites(); if world==2 then Magma.populate(n) end end
    if Secret then Secret.configure();if Secret.duel then Secret.duel.time=0;if Secret.duel.kind=='mob' then objet.larme.taken=true end end end
    local hasOctopus=Octopus.active
    for _,item in ipairs(Bosses.items) do if item.kind=='octopus' then hasOctopus=true end end
    if hasOctopus then for i=#mobs,1,-1 do if mobs[i].type=='jelly' then table.remove(mobs,i) end end end
    BossFX.update(0)
    Renaissance.reset()
    C.updateTear(0)
    if App.state=='playing' then Bestiary.encounter() end
end
function C.spawnHell(n)
    spawn_spinner(650,470,95+n*4)
    if n>=2 then spawn_imp(120,470,65+n*2) end
    if n>=4 then spawn_spinner(140,105,105) end
    if n>=5 then spawn_imp(670,115,80) end
    if n>=7 then spawn_spinner(380,110,120) end
    if n>=8 then spawn_imp(130,300,90) end
end
function C.clearTearSites()
    for _,m in ipairs(mobs) do if m.type=='piege' or m.type=='scie' then
        local radius=m.type=='scie' and (m.radius or 60)+22 or 32
        local function clear(x,y)
            if Arena.blocked(x-radius,y-radius,radius*2,radius*2) then return false end
            for _,p in ipairs(levels[player.level].larme_position) do
                if (x-p.x-15)^2+(y-p.y-39)^2<(radius+26)^2 then return false end
            end
            return (x-player.x-15)^2+(y-player.y-12)^2>(radius+35)^2
        end
        if not clear(m.x,m.y) then
            local best,bx,by=math.huge
            for y=65+radius,550-radius,12 do for x=26+radius,Arena.width-26-radius,12 do
                local d=(x-m.x)^2+(y-m.y)^2
                if d<best and clear(x,y) then best,bx,by=d,x,y end
            end end
            assert(bx,'Emplacement libre pour le piège'); m.x,m.y=bx,by
        end
    end end
end
function C.clearGroundSites()
    local sites=Abyss.boss and Abyss.lightSites or levels[player.level].larme_position
    for _,list in ipairs({Hazards.lava,Realms.vents,Realms.holes,Realms.tornadoes}) do
        for _,t in ipairs(list) do
            local radius=math.max(t.rx or 45,t.ry or 30)+28
            local function clear(x,y)
                if Arena.blocked(x-radius,y-radius,radius*2,radius*2) then return false end
                for _,p in ipairs(sites) do
                    local px,py=Abyss.boss and p.x or p.x+15,Abyss.boss and p.y or p.y+39
                    if (x-px)^2+(y-py)^2<radius^2 then return false end
                end
                return true
            end
            if not clear(t.x,t.y) then
                local best,bx,by=math.huge
                for y=85,515,15 do for x=80,Arena.width-80,15 do
                    local d=(x-t.x)^2+(y-t.y)^2
                    if d<best and clear(x,y) then best,bx,by=d,x,y end
                end end
                if bx then t.x,t.y=bx,by end
            end
        end
    end
end
function C.drawCircles()
    if Renaissance.active then return end
    if (Abyss.boss and not Abyss.defeated) or Bosses.hud().active or Raven.active or Wasp.active or Hedgehog.active or Octopus.active or Storm.active then return end
    local g=love.graphics
    for _,p in ipairs(levels[player.level].larme_position) do
        g.setColor(Worlds.color(C.world).tear)
        if C.biome==5 then g.setColor(.72,.51,.30,.72) end
        if C.biome==7 then g.setColor(.3,.7,1,Abyss.siteVisibility(p.x+15,p.y+39)) end
        Art.drawTinted('tear_ring',p.x+15,p.y+39,44)
    end
    g.setColor(1,1,1)
end
function C.draw()
    local g=love.graphics; local hell=C.biome==2
    Arena.drawFloor(hell);if C.world==3 then Meadow.draw() end; C.drawCircles(); Abyss.drawSites()
    if hell then
        for i=1,32 do
            local x=(i*79+math.sin(larme_float_timer+i)*14)%(Arena.width-50)+25
            local y=(i*47-larme_float_timer*(12+i%9))%570+15
            g.setColor(1,0.08+i%3*0.025,0.08,0.35); g.circle('fill',x,y,1+i%2)
        end
    end
    Hazards.draw(); Realms.drawGround(); Ocean.drawGround(); Octopus.drawGround(); Raven.drawGround(); Wasp.drawGround(); Storm.drawGround(); Bosses.drawGround(); Arena.drawWalls(hell)
    C.drawTear()
    g.setColor(1,1,1)
end
function C.drawTear(overlay)
    if Renaissance.active then Renaissance.drawEggs();return end
    if Aftermath.cleared and not overlay then return end
    if objet.larme.abyssHeld or (C.carrier and not objet.larme_dropped and (Realms.underground(C.carrier) or C.carrier.tunnelTravel)) then return end
    local g=love.graphics
    if not objet.larme.taken then
        local x,y=objet.larme.x,objet.larme.y+(Aftermath.cleared and 0 or math.sin(larme_float_timer*2)*4)
        local tint=Worlds.color(C.biome).tear
        if C.biome==5 then tint={.86,.65,.39} end
        if C.biome~=5 then g.setColor(tint);g.draw(particleSystem,x+15,y+20) end
        local previous=g.getShader()
        if overlay then
            C.victoryTearShader=C.victoryTearShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
                vec4 p=Texel(tex,uv);
                return vec4(vec3(.4,.55,.65)+p.rgb*vec3(.6,.45,.35),p.a)*color;
            }]])
            g.setShader(C.victoryTearShader);g.setColor(1,1,1)
        elseif C.biome==5 then
            C.tearShader=C.tearShader or g.newShader([[vec4 effect(vec4 color,Image tex,vec2 uv,vec2 px) {
                vec4 p=Texel(tex,uv);float v=max(p.r,max(p.g,p.b));
                return vec4(.66+.30*v,.43+.33*v,.22+.28*v,p.a)*color;
            }]])
            g.setShader(C.tearShader);g.setColor(1,1,1)
        end
        g.draw(objet.larme.img,x,y,0,objet.larme.size);g.setShader(previous)
    end
    g.setColor(1,1,1)
end
function C.drawMob(m)
    if m.abyssHeld then return end
    local behavior=MobBehaviors[m.type]
    if not behavior or not behavior.draw then return end
    if m.tunnelTravel then
        local scale,dy=Realms.travelPose(m);local travel=m.tunnelTravel;m.tunnelTravel=nil
        local g=love.graphics;g.push('all');g.translate(m.x,m.y+dy);g.scale(math.max(.001,scale));g.translate(-m.x,-m.y)
        behavior.draw(m);g.pop();m.tunnelTravel=travel
    else behavior.draw(m) end
end
function C.updateTear(dt)
    if Renaissance.active then Renaissance.syncEgg();return end
    if Aftermath.cleared then Aftermath.centerTear();return end
    if C.carrier then
        if not objet.larme_dropped then
            local m=C.carrier; local dx,dy=0,1
            if m.dir=='up' then dy=-1 elseif m.dir=='left' then dx,dy=-1,0 elseif m.dir=='right' then dx,dy=1,0 end
            objet.larme.x=m.x-15-dx*36; objet.larme.y=m.y-20-dy*36
        end
    elseif not Bosses.hud().active and not (Abyss and Abyss.active and Abyss.open) and not Raven.active and not Wasp.active and not Hedgehog.active and not Octopus.active and not Storm.active and not (Abyss and Abyss.boss) then select_tp_larme(dt) end
end
function C.canCollect()
    return not Bosses.alive() and not objet.larme.taken and (not C.carrier or objet.larme_dropped)
        and (not Raven.active or Raven.defeated) and (not Wasp.active or Wasp.defeated) and (not Hedgehog.active or Hedgehog.defeated) and (not Octopus.active or Octopus.defeated) and (not Abyss.boss or Abyss.defeated) and (not Storm.active or Storm.defeated)
end
return C
