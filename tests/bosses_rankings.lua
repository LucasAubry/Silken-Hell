local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    level(5,10); assert(Hedgehog.active and Hedgehog.hp==7 and not Campaign.canCollect())
    assert(Bestiary.seen.hedgehog)
    Hedgehog.fire(); assert(#Hedgehog.projectiles==12,'Salve espacée de douze piques')
    local spike=Hedgehog.projectiles[1]; assert(math.abs(math.sqrt(spike.vx^2+spike.vy^2)-300)<.001,'Piques rapides')
    player.x=-1000; player.y=-1000
    local bounces=0; local lastStage=1
    local bounceTargets={1,2,2,2,2,2,2}
    local moleTargets={1,2,3,4,5,5,5}
    for _=1,20000 do
        Hedgehog.update(.02)
        assert(#mobs==moleTargets[Hedgehog.stage],'Nombre de taupes conforme aux PV')
        if not Hedgehog.defeated then assert(Hedgehog.requiredBounces()==bounceTargets[Hedgehog.stage],'Rebonds conformes aux PV') end
        if Hedgehog.stage~=lastStage then
            assert(Hedgehog.bounces==bounceTargets[lastStage],'Nombre réel de rebonds de la série')
            bounces=bounces+Hedgehog.bounces; lastStage=Hedgehog.stage
        end
        assert(not Arena.blocked(Hedgehog.x-32,Hedgehog.y-32,64,64),'Boss hors des murs')
        if Hedgehog.defeated then break end
    end
    assert(Hedgehog.defeated and Hedgehog.bounces==2 and bounces+2==13,'Sept manches : rebonds plafonnés à deux')
    assert(#mobs==5,'Cinq taupes, ajoutées une par une')
    assert(Campaign.canCollect(),'Larme du hérisson libérée')
    local tx,ty=objet.larme.x,objet.larme.y; Campaign.updateTear(10)
    assert(tx==objet.larme.x and ty==objet.larme.y,'Larme finale immobile')
    level(5,10); Hedgehog.phaseTime=0; Hedgehog.update(.01)
    assert(Hedgehog.hp==7 and Hedgehog.bounces==0 and #mobs==1)
    Hedgehog.phaseTime=0; Hedgehog.update(.01)
    local stage,hp=Hedgehog.stage,Hedgehog.hp; love.resize(1600,900)
    assert(Hedgehog.phase=='ball' and Hedgehog.stage==stage and Hedgehog.hp==hp,'Combat conservé au redimensionnement')
    love.resize(love.graphics.getDimensions()); reset_level(); assert(Hedgehog.stage==1 and #mobs==1)
    Hedgehog.finishRound(); Hedgehog.roll(); Hedgehog.impact()
    assert(Hedgehog.phase=='ball' and Hedgehog.bounces==1,'Aucun arrêt au mur sans perte de PV')
    Hedgehog.impact(); assert(Hedgehog.phase=='stunned' and Hedgehog.hp==5,'Étourdi après perte de PV')
    local rx,ry=Hedgehog.x,Hedgehog.y
    player.x=-1000; player.y=-1000; Hedgehog.update(.2)
    assert(Hedgehog.phase=='stunned' and Hedgehog.x==rx and Hedgehog.y==ry,'Immobilisé pendant le stun')
    Hedgehog.update(.26); assert(Hedgehog.phase=='standing','Reprend ses attaques après le stun')
    Profile.scores={}
    for i=1,23 do Profile.scores[#Profile.scores+1]={world=4,name='Pseudo '..i,country='FR',time=20+i,deaths=i,skin=i%5+1} end
    Profile.scores[#Profile.scores+1]={world=4,name='Pseudo 1',country='FR',time=999,deaths=0,skin=1}
    local page=Online.page(4,false,2); assert(#page.scores==10 and page.total==23 and page.hasMore and page.scores[1].name=='Pseudo 11')
    page=Online.page(4,false,3); assert(#page.scores==3 and not page.hasMore)
    UI.boardWorld=4; UI.boardPage=2; App.state='rankings'; love.draw()
    Profile.scores={}
    for _,name in ipairs({'hedgehog','hedgehog_ball'}) do for _,dir in ipairs({'up','down','left','right'}) do
        local d=Art.imageData('assets/sprites/directional/'..name..'_'..dir..'.png')
        local _,_,_,alpha=d:getPixel(0,0); assert(alpha==0,'PNG transparent '..name..'_'..dir); d:release()
    end end
    print('PASS boss/classements : décollage continu, guêpes persistantes, 13 rebonds, deux rebonds et cinq taupes maximum, larme, skins et pagination')
end
return T
