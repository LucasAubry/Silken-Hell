local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
function T.run()
    for _,w in ipairs({2,4,5,6,7}) do for n=1,10 do
        level(w,n); assert(not Campaign.carrier,'Aucun porteur bloqué sans piège')
        for _,m in ipairs(mobs) do assert(m.type~='piege' and m.type~='scie' and not m.capture,'Pièges seulement au Paradis') end
        if w==5 then
            assert(#Realms.tunnels==2 and Bestiary.seen.earth_tunnel)
            local reachable=require('tests.gameplay_v5').reachable()
            for _,t in ipairs(Realms.tunnels) do
                assert(not Arena.blocked(t.x-52,t.y-38,104,76),'Tunnel libre de murs')
                assert(reachable({x=t.x-15,y=t.y-12}),'Tunnel accessible')
            end
            local a,b=Realms.tunnels[1],Realms.tunnels[2]
            player.x=a.x-15; player.y=a.y-12; Realms.updateTraversal(.01)
            assert(player.tunnelTravel and player.x==a.x-15,'Animation avant téléportation')
            Realms.updateTraversal(.23); assert(player.x==b.x-15 and player.tunnelLock,'Tunnel aller')
            Realms.updateTraversal(2); assert(player.x==b.x-15,'Pas de boucle de téléportation')
            player.x=b.x+60; Realms.updateTraversal(.01)
            player.x=b.x-15; Realms.updateTraversal(.01); Realms.updateTraversal(.45); assert(player.x==a.x-15,'Tunnel retour')
        end
    end end
    level(5,1); local mole
    for _,m in ipairs(mobs) do if m.type=='mole' then mole=m end end
    assert(mole.speed>=130,'Taupe plus rapide à la surface')
    level(5,10); Realms.spawnMole(200,200); assert(mobs[1].speed==140,'Taupes du boss accélérées')
    Hedgehog.fire(); assert(#Hedgehog.projectiles==12)
    level(6,1); local t=Realms.tornadoes[1]
    player.x=t.x-15; player.y=t.y-12; player.lastMoveX=1; player.lastMoveY=0
    Realms.updateTraversal(.01); assert(player.whirl,'Tornade attrape le joueur')
    local x=player.x; App.move(.1); assert(player.x==x,'Déplacement contrôlé pendant le tourbillon')
    Realms.updateTraversal(.2); assert(player.whirl and player.x~=x,'Rotation du joueur')
    Realms.updateTraversal(.5); assert(not player.whirl and player.throw,'Projection après rotation')
    local y=player.y; x=player.x; Realms.updateTraversal(.34); assert(math.abs(player.x-x)<1 and player.y>y+70 and player.reset,'Projection violente jusqu’au rebord')
    level(1,10); player.x=70; player.y=540; local old=Raven.fire; local count=0
    Raven.fire=function() count=count+1 end
    for _=1,40 do Raven.update(.1) end
    Raven.fire=old; assert(count>=13,'Merle en continu sans pause après dix tirs')
    local ids={}; for _,row in ipairs(Bestiary.list('traps')) do ids[row.entry.id]=true end
    assert(ids.piege and ids.scie and ids.cloud_snare and ids.earth_tunnel and ids.lava)
    for _,row in ipairs(Bestiary.list('creatures')) do assert(not row.entry.trap and not row.entry.boss) end
    print('PASS traversal: pièges limités au Paradis, tunnels accessibles aller/retour, tornades rotation/projection, taupes rapides, 12 piques, Merle continu, catégorie Pièges')
end
function T.visual()
    local d=love.image.newImageData('assets/sprites/earth_tunnel.png'); local _,_,_,a=d:getPixel(0,0); assert(a==0,'Tunnel PNG transparent'); d:release()
    Profile.unlocked=6; local tick=0
    love.update=function(dt)
        tick=tick+1; UI.clock=UI.clock+dt
        if tick==1 then level(5,4); App.capture='traversal-tunnels.png'
        elseif tick==5 then
            level(6,4); local t=Realms.tornadoes[1]; player.x=t.x-15; player.y=t.y-12
            Realms.updateTraversal(.01); Realms.clock=.12; Realms.updateTraversal(.1); App.capture='traversal-tornado.png'
        elseif tick==9 then
            Bestiary.discover('cloud_snare'); Bestiary.discover('earth_tunnel'); Bestiary.open(); UI.bestCategory='traps'; UI.bestPage=1
            for i,e in ipairs(Bestiary.entries) do if e.id=='earth_tunnel' then UI.bestSelected=i end end
            App.capture='traversal-bestiary.png'
        elseif tick==13 then
            level(5,10); Hedgehog.fire(); for _,p in ipairs(Hedgehog.projectiles) do p.x=p.x+p.vx*.5; p.y=p.y+p.vy*.5 end
            App.capture='traversal-hedgehog.png'
        elseif tick==17 then love.event.quit() end
    end
end
return T
