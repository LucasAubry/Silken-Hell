local T={}
local function level(world,n)
    Campaign.select(world); player.level=n; reset_level(); App.state='playing'
end
function T.run()
    local disabled=LevelLayouts.disabled; LevelLayouts.disabled=true
    level(7,10)
    Abyss.open=true; Abyss.breathAt=Abyss.clock; Abyss.buildBones()
    player.x=Arena.width-70; player.y=480
    local deaths=player.death
    Hazards.kill(); assert(not player.reset and player.death==deaths,'Protection dès l’aspiration, avant les mises à jour des mobs')
    local m=mobs[1]; m.x=player.x+15; m.y=player.y+12
    assert(not isTouching(player,m),'Pas de collision ennemie pendant aspiration')
    Abyss.open=false; assert(isTouching(player,m),'Collisions restaurées à la fermeture')
    Abyss.open=true; Hazards.kill('bone'); assert(player.reset,'Les os restent mortels pendant aspiration')
    level(7,10); Abyss.open=true; Abyss.breathAt=0; Abyss.buildBones()
    local mx,my=Abyss.mouth(); player.x=mx+80; player.y=my+200; Abyss.charge(6)
    for _=1,340 do Abyss.update(.01); if player.abyssHeld or player.reset then break end end
    assert(player.abyssHeld and not player.reset,'Sans résistance la force aspire jusqu’à la bouche')
    Abyss.update(.61); assert(Abyss.spinTime>0 and Abyss.hp==7)
    Abyss.updatePlayer(.3); player.x=60; player.y=510; player.abyssGrace=0
    local hx,hy=Abyss.head.x,Abyss.head.y; Abyss.update(.7)
    assert(math.abs(Abyss.bones[2].angle+.12)>.3,'Les côtes tournent après le rejet')
    assert(Abyss.head.x==hx and Abyss.head.y==hy,'Le crâne ne tourne ni ne se déplace')
    -- Rotation must use the rotated silhouette, including its full collision bounds.
    local rib=Abyss.bones[2]; local hit=false
    for y=rib.y-80,rib.y+80,2 do for x=rib.x-80,rib.x+80,2 do
        if not hit and Abyss.boneTouches(rib,x,y) then player.x=x-15; player.y=y-12; Abyss.contact(); hit=player.reset end
    end end
    assert(hit,'Collision des os pendant leur rotation')
    level(7,10); Abyss.open=true; Abyss.breathAt=0; Abyss.buildBones()
    local cargo={}; for i=1,30 do local e={x=0,y=0,abyssHeld=Abyss}; cargo[i]=e; Abyss.cargo[i]={entity=e} end
    Abyss.spit(); local quadrants={}
    for _,e in ipairs(cargo) do
        assert(not e.abyssHeld and e.x>=40 and e.x<=Arena.width-40 and e.y>=70 and e.y<=540)
        quadrants[(e.x>Arena.width/2 and 1 or 0)+(e.y>300 and 2 or 0)]=true
    end
    for i=0,3 do assert(quadrants[i],'Rejet réparti dans les quatre quarts du terrain') end
    Abyss.update(3.3); assert(Abyss.spinTime==0 and Abyss.spinAngle==0,'Rotation terminée et os réalignés')
    level(7,10); Abyss.open=true; Abyss.breathAt=0; Abyss.buildBones()
    local sx,sy=Abyss.mouth(); player.x=sx+10; player.y=sy+120
    local distance=(player.x+15-sx)^2+(player.y+12-sy)^2
    local key=love.keyboard.isDown; love.keyboard.isDown=function(k) return k==Profile.keys.down or k==Profile.keys.dash end
    App.move(.05); Abyss.update(.05); love.keyboard.isDown=key
    assert((player.x+15-sx)^2+(player.y+12-sy)^2>distance,'Un dash permet de résister à proximité')
    for _,w in ipairs({1,2,3,4,5,6,7}) do level(w,1); love.draw(); assert(not player.reset) end
    -- Visual effects cannot change light-based combat mechanics.
    level(4,1); player.electrified=0; player.illuminated=0; Atmosphere.draw()
    assert(player.electrified==0 and player.illuminated==0)
    LevelLayouts.disabled=disabled; level(1,1)
    print('PASS abyss atmosphere: pull protection/bone exception, unavoidable idle suction, anchored head, rotating collisions, full-field scatter, lighting all biomes')
end
function T.visual()
    love.focus=function() end
    local tick=0; local worlds={1,5,4,2,6,3,7}
    love.update=function()
        tick=tick+1; UI.clock=14+tick*.016
        if tick%5==1 then
            local w=worlds[math.floor(tick/5)+1]
            if not w then love.event.quit(); return end
            LevelLayouts.disabled=true; level(w,w==7 and 10 or 4)
            if w==7 then Abyss.spit(); Abyss.update(.65) end
            App.capture='atmosphere-'..w..'.png'
        end
    end
end
return T
