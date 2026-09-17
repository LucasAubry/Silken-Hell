local T={}
local function level() Campaign.select(4); player.level=10; reset_level(); App.state='playing' end
function T.armPoint()
    local O=Octopus
    for y=O.y-175,O.y+175,3 do for x=O.x-175,O.x+175,3 do
        local d=(x-O.x)^2+(y-O.y)^2
        if d>95^2 and d<165^2 and O.touches(x,y) then return x,y end
    end end
    error('Tentacule introuvable')
end
function T.clearWave()
    local O=Octopus
    player.reset=false; player.x=40; player.y=530; O.rider=nil
    local x,y=T.armPoint(); local arm=O.armAt(x,y); local hp=O.hp; local spin=O.spin
    local remaining=O.arms[arm]
    for hit=1,remaining do
        O.releaseCrabs()
        local c; for _,candidate in ipairs(O.crabs) do if not candidate.dead then c=candidate; break end end
        assert(c,'Crabe disponible')
        c.launch=nil; c.x=x; c.y=y; O.crabContact(c)
        assert(c.dead==0,'Contact tentacule tue le crabe')
        assert(O.arms[arm]==remaining-hit,'Un impact retire exactement un point')
        assert(O.hp==hp-(hit==remaining and 1 or 0),'Vie perdue uniquement à la destruction du bras')
        O.crabContact(c); assert(O.arms[arm]==remaining-hit,'Pas de double impact du crabe mort')
    end
    assert(O.spin==-spin and not O.touches(x,y),'Bras détruit inutilisable et inversion')
end
function T.run()
    App.state='menu'; love.keypressed('escape'); assert(App.state=='quitConfirm'); love.draw()
    assert(#UI.buttons==2,'Dialogue modal sans boutons du menu derrière')
    love.keypressed('escape'); assert(App.state=='menu')
    level(); assert(player.x+15==Octopus.x and player.y>Octopus.y+220,'Départ sûr')
    local O=Octopus
    O.contact(); assert(not player.reset)
    local _,angle,size=O.sprite(); assert(angle==O.angle and size==360,'Poulpe réduit')
    O.summon=100; O.shot=100
    for i=1,100 do O.update(.025); assert(O.spin==1,'Sens fixe sans perte de vie') end
    level(); O.releaseCrabs(); assert(#O.crabs==8 and Bestiary.seen.crab)
    for _,c in ipairs(O.crabs) do assert(c.ty>O.y and c.launch==0,'Lancer vers le joueur') end
    local c=O.crabs[1]; player.x=50; player.y=500
    O.updateCrabs(.91); assert(not c.launch)
    c.x=100; c.y=450
    local d=(player.x+15-c.x)^2+(player.y+12-c.y)^2
    O.updateCrabs(.1)
    assert((player.x+15-c.x)^2+(player.y+12-c.y)^2<d,'Crabe poursuit le joueur')
    level(); local avoidance={x=O.x+145,y=O.y,speed=90,vx=-1,vy=0,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
    player.x=O.x-200; player.y=O.y-12
    O.walkCrab(avoidance,.1,function() end)
    assert(avoidance.x>=O.x+144 and math.abs(avoidance.y-O.y)>1,'Contournement naturel du corps')
    level(); local x,y=T.armPoint(); player.x=x-15; player.y=y-12; O.contact()
    assert(O.rider and not player.reset,'Tentacule accroche sans tuer')
    local speed=math.abs(O.angularVelocity); O.summon=100; O.shot=100; O.update(.2)
    assert(O.rider and math.abs(O.angularVelocity)>speed,'Rotation accélérée avec passager')
    assert(math.abs(math.sqrt((player.x+15-O.x)^2+(player.y+12-O.y)^2)-O.rider.radius)<.001)
    O.riderInput(1,0,true,.01); assert(not O.rider and O.grace>0,'Dash directionnel décroche')
    level(); x,y=T.armPoint(); player.x=x-15; player.y=y-12; O.contact()
    O.waveActive=true; O.crabs={{x=player.x+15,y=player.y+12,age=0,angle=0,speed=85}}
    O.crabContact(O.crabs[1]); assert(player.reset and not O.crabs[1].dead,'Collision crabe/passager prioritaire et mortelle')
    level()
    for i=1,8 do T.clearWave() end
    assert(O.defeated and Campaign.canCollect(),'Huit tentacules détruites libèrent la larme')
    O.updateCrabs(.6); assert(#O.crabs>0,'Mort sur le dos visible')
    love.draw(); O.updateCrabs(.61); assert(#O.crabs==0,'Enfouissement terminé')
    for _,pose in ipairs({'open','closed','dead'}) do
        local data=love.image.newImageData('assets/sprites/crab_'..pose..'.png')
        local _,_,_,alpha=data:getPixel(0,0); assert(alpha==0,'PNG transparent crabe '..pose); data:release()
    end
    level(); O.splash(); local g=love.graphics; local canvas=g.newCanvas(Arena.width,600)
    g.push('all'); g.setCanvas(canvas); g.clear(1,1,1); O.drawInk(); g.setCanvas(); g.pop()
    local data=canvas:newImageData(); local dark,total=0,0
    for y=30,570,20 do for x=30,Arena.width-30,20 do
        local r,gc,b=data:getPixel(x,y); total=total+1; if (r+gc+b)/3<.55 then dark=dark+1 end
    end end
    assert(dark/total>.65,'Encre noire devant la vue'); data:release(); canvas:release()
    print('PASS poulpe: sens fixe par PV, poursuite/lancer, accrochage/dash, collision passager, huit impacts par bras, bras détruits inactifs, contournement, victoire, encre et menu quitter')
end
function T.visual()
    local tick=0
    love.update=function(dt)
        tick=tick+1
        if tick==1 then
            level(); Octopus.angle=.5; Octopus.releaseCrabs(); Octopus.updateCrabs(.4)
            App.capture='octopus-revision-launch.png'
        elseif tick==5 then
            player.x=70; player.y=500
            Octopus.updateCrabs(.51)
            App.capture='octopus-revision-combat.png'
        elseif tick==9 then
            local x,y=T.armPoint(); player.x=x-15; player.y=y-12; Octopus.contact()
            Octopus.update(.25); App.capture='octopus-revision-rider.png'
        elseif tick==13 then Octopus.splash(); App.capture='octopus-revision-ink.png'
        elseif tick==17 then level(); T.clearWave(); T.clearWave(); Octopus.arms[3]=3; App.capture='octopus-damaged-arms.png'
        elseif tick==21 then App.state='menu'; love.keypressed('escape'); App.capture='menu-quit-confirm.png'
        elseif tick==25 then love.event.quit() end
    end
end
return T
