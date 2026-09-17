local T={}
local function level(w,n) Campaign.select(w);player.level=n;reset_level();App.state='playing' end
function T.run()
    local disabled=LevelLayouts.disabled;LevelLayouts.disabled=true
    for _,w in ipairs({1,2,4,5,7}) do
        level(w,9);Realms.lightningClock=0;Realms.updateLightning(.1)
        assert(#Realms.lightning==0,'Foudre uniquement au Ciel')
    end
    level(6,1);Realms.lightningClock=0;Realms.updateLightning(.01);assert(#Realms.lightning>0)
    level(2,10)
    local p=Hazards.lava[1];local m={hitBox_width=10,hitBox_height=10}
    assert(Arena.navGraph(m).clear(p.x,p.y),'Lave traversable par la navigation')
    Wasp.lavaClock=0;Wasp.updateLava(.01);assert(#Wasp.eruptions==1 and #Wasp.projectiles==0)
    Wasp.updateLava(1);assert(#Wasp.eruptions==0 and #Wasp.projectiles==5,'Éruption annoncée puis cinq braises')
    local x,y=Wasp.landingSpot()
    for _,lava in ipairs(Hazards.lava) do assert(not Hazards.inEllipse(x,y,lava,65),'Atterrissage accessible hors lave') end
    for _,name in ipairs({'wasp','wasp_ground'}) do for _,dir in ipairs({'up','down','left','right'}) do
        local d=love.image.newImageData('assets/sprites/directional/'..name..'_'..dir..'.png')
        local _,_,_,a=d:getPixel(0,0);assert(a==0,'PNG transparent');d:release()
    end end
    level(4,10);local O=Octopus
    O.ink();local tx,ty=O.projectiles[1].tx,O.projectiles[1].ty
    player.x=50;player.y=70;O.updateInk(.9)
    assert(#O.projectiles==0 and #O.inkPools==1 and player.ink==0,'Encre atterrit sur le terrain')
    local function crab(x,y) return {x=x,y=y,age=0,angle=0,speed=180,vx=1,vy=0,hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12} end
    local c=crab(tx,ty);O.crabs={c};O.waveActive=true;O.updateCrabs(.01)
    assert(c.frenzy and not c.dead,'Crabe agité avant explosion')
    c.frenzy=.001;local other=crab(c.x+60,c.y);O.crabs={c,other};O.updateCrabs(.01)
    assert(c.dead and other.fling and #O.blasts==1,'Explosion propulse les voisins')
    O.inkPools={};other.x=100;other.y=100;other.fling={vx=580,vy=0,time=.65}
    player.x=150;player.y=88;player.reset=false;O.updateCrabs(.15)
    assert(player.reset,'Crabe propulsé mortel sans traverser le joueur')
    level(4,10);player.x=50;player.y=70;O.releaseCrabs();local first=O.liveCrabs();O.summon=0;O.shot=100;O.update(.01)
    assert(O.liveCrabs()>first,'Invocation régulière malgré les crabes vivants')
    O.crabs={crab(O.x+250,O.y)};c=O.crabs[1];player.x=O.x-300;player.y=O.y-12
    for i=1,100 do O.walkCrab(c,.01,function() end);assert((c.x-O.x)^2+(c.y-O.y)^2>=204.9^2,'Distance de sécurité des tentacules') end
    LevelLayouts.disabled=disabled;level(1,1)
    print('PASS ink/lava: traversable lava, sky-only lightning, eruption warning, safe landing, red alpha sprites, ground ink, frenzy, explosion, lethal knockback, recurring summons and avoidance')
end
function T.visual()
    love.focus=function() end;local tick=0
    love.update=function()
        tick=tick+1;LevelLayouts.disabled=true
        if tick==1 then level(2,10);Wasp.lavaClock=0;Wasp.updateLava(.6);App.capture='infernal-wasp-red.png'
        elseif tick==5 then level(4,10);Octopus.releaseCrabs();player.x=60;player.y=500;Octopus.updateCrabs(.91)
            for i=1,4 do Octopus.ink();Octopus.updateInk(.9) end
            Octopus.crabs[1].frenzy=.5;App.capture='octopus-ground-ink.png'
        elseif tick==10 then love.event.quit() end
    end
end
return T
