local C={world=1,names=Worlds.names,data={{},{},{},{},{},{}}}
C.titles={
 {'Le premier souffle','Les veilleurs','La ronde des lames','Le jardin des épines','Les ailes captives','Le silence des serpents','Les quatre gardiens','Le chœur brisé','Les portes du ciel','Le Merle noir'},
 {'La chute','Les braises','Le cercle des damnés','La forge','Les ailes de cendre','Le fleuve noir','Les sept sceaux','La gueule du feu','Le trône vide','La Guêpe solitaire'}
}
function C.install()
    -- Keep the authored positions and original encounters, before procedural walls were added.
    C.original=levels
    for w=1,6 do for n=1,10 do C.data[w][n]={} end end
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
function C.select(world) C.world=world; levels=C.data[world] end
function C.positions(n)
    if C.world==1 then
        local points={}
        for _,p in ipairs(C.original[n].larme_position) do
            if p.x>=0 then points[#points+1]={x=Arena.mapX(p.x),y=p.y} end
        end
        return points
    end
    local ring={{.5,85},{.82,135},{.9,280},{.82,460},{.5,510},{.18,460},{.1,280},{.18,135}}
    local indexes=n==8 and {1,2,3,4,5,6,7,8} or n%2==1 and {1,3,5,7} or {2,4,6,8}
    local points={}
    for _,i in ipairs(indexes) do local p=ring[((i-1+(C.world==2 and 2 or 0))%8)+1]; points[#points+1]={x=p[1]*Arena.width-15,y=p[2]-20} end
    return points
end
function C.reset()
    local previousSide=C.lastSide
    load_mob(); ghosts={}; just_loaded=false; larme_timer=0; larme_float_timer=0
    larme_interval=C.world==2 and (player.level==8 and 1.25 or 2.6) or 1.5
    player.speed=1; player.original_speed=1; player.is_frozen=false; player.freeze_timer=0; player.reset=false
    player.hitBox_width=30; player.hitBox_height=24; player.hitBox_offset_x=0; player.hitBox_offset_y=0
    local boss=player.level==10 and C.world<=2
    player.x=C.world==1 and Arena.mapX(C.original[player.level].player_position.x) or Arena.width/2-15; player.y=boss and 505 or 265
    local level={player_position={x=player.x,y=player.y},larme_position=C.positions(player.level),aureole_position={x=0,y=0}}
    if boss then level.larme_position={{x=Arena.width/2-15,y=280}} end
    levels[player.level]=level
    Arena.build(level.player_position,level.larme_position,boss)
    C.starts=C.starts or {{},{},{},{},{},{}}
    local count=#level.larme_position
    local start=C.starts[C.world][player.level]
    if not start then
        local previous=C.lastSide or 0; local wanted=previous%4+1
        start=1; local best=math.huge
        for i,p in ipairs(level.larme_position) do
            local a=math.atan2(p.y+20-300,p.x+15-Arena.width/2)
            local side=math.floor((a+math.pi/4)%(2*math.pi)/(math.pi/2))+1
            local distance=side==wanted and 0 or side==previous and 2 or 1
            if distance<best then best=distance; start=i end
        end
        C.starts[C.world][player.level]=start
    end
    larme_indexes[player.level]=start
    local first=level.larme_position[start] or {x=-100,y=-100}
    objet.larme.x=first.x; objet.larme.y=first.y
    if count>0 and not boss then
        local a=math.atan2(first.y+20-300,first.x+15-Arena.width/2)
        C.lastSide=math.floor((a+math.pi/4)%(2*math.pi)/(math.pi/2))+1
    end
    objet.larme.taken=boss; objet.larme_dropped=true
    if not boss then
        if C.world>=4 then Realms.spawn(C.world,player.level)
        elseif C.world==2 then C.spawnHell(player.level) else
            _G['mob_lv'..player.level]()
            -- The old 8/9 sketches had carriers but no trap to release their tear.
            if player.level==8 or player.level==9 then
                spawn_piege(180,170); spawn_piege(610,470)
            end
        end
    end
    C.carrier=nil
    for _,m in ipairs(mobs) do
        m.x=Arena.mapX(m.x)
        if C.world==1 and m.type~='piege' and m.speed then m.speed=m.speed*1.08 end
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
    Raven.reset(boss and C.world==1); Wasp.reset(boss and C.world==2)
    Hazards.reset(C.world==2,player.level)
    Realms.reset(C.world,player.level)
    C.updateTear(0)
    if App.state=='playing' then Bestiary.encounter() end
end
function C.spawnHell(n)
    spawn_scie(200,165,1,1.8+n*0.1,'down')
    spawn_spinner(650,470,95+n*4)
    if n>=2 then spawn_imp(120,470,65+n*2) end
    if n>=3 then spawn_scie(610,410,-1,2.1,'down') end
    if n>=4 then spawn_spinner(140,105,105) end
    if n>=5 then spawn_imp(670,115,80) end
    if n>=7 then spawn_spinner(380,110,120) end
    if n>=8 then spawn_imp(130,300,90) end
    if n==5 or n==7 then
        for _,m in ipairs(mobs) do if m.type=='imp' then m.has_larme=true; break end end
    end
    spawn_piege(255,445); spawn_piege(555,170)
end
function C.drawCircles()
    local g=love.graphics
    for _,p in ipairs(levels[player.level].larme_position) do
        local a=objet.aureole.img; local width=70
        g.setColor(C.world==2 and {1,0.12,0.1,0.9} or {1,1,1,0.95})
        g.draw(a,p.x+15,p.y+39,0,width/a:getWidth(),width/a:getWidth(),a:getWidth()/2,a:getHeight()/2)
    end
    g.setColor(1,1,1)
end
function C.draw()
    local g=love.graphics; local hell=C.world==2
    Arena.drawFloor(hell); C.drawCircles()
    if hell then
        for i=1,32 do
            local x=(i*79+math.sin(larme_float_timer+i)*14)%(Arena.width-50)+25
            local y=(i*47-larme_float_timer*(12+i%9))%570+15
            g.setColor(1,0.08+i%3*0.025,0.08,0.35); g.circle('fill',x,y,1+i%2)
        end
    end
    Hazards.draw(); Realms.drawGround(); Raven.drawGround(); Wasp.drawGround(); Arena.drawWalls(hell)
    C.drawTear()
    g.setColor(1,1,1)
end
function C.drawTear()
    local g=love.graphics
    if not objet.larme.taken then
        local x,y=objet.larme.x,objet.larme.y+math.sin(larme_float_timer*2)*4
        local tint=Worlds.color(C.world).tear
        g.setColor(tint); g.draw(particleSystem,x+15,y+20)
        g.draw(objet.larme.img,x,y,0,objet.larme.size)
    end
    g.setColor(1,1,1)
end
function C.drawMob(m)
    local behavior=MobBehaviors[m.type]; if behavior and behavior.draw then behavior.draw(m) end
end
function C.updateTear(dt)
    if C.carrier then
        if not objet.larme_dropped then
            objet.larme.x=C.carrier.x-15; objet.larme.y=C.carrier.y-45
        end
    elseif not Raven.active and not Wasp.active then select_tp_larme(dt) end
end
function C.canCollect()
    return not objet.larme.taken and (not C.carrier or objet.larme_dropped)
        and (not Raven.active or Raven.defeated) and (not Wasp.active or Wasp.defeated)
end
return C
