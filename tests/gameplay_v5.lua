local T={}
local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
local function flood()
    local step=8; local seen={}; local queue={{player.x,player.y}}; local head=1
    local function key(x,y) return math.floor(x/step+.5)..':'..math.floor(y/step+.5) end
    seen[key(player.x,player.y)]=true
    while head<=#queue do local p=queue[head]; head=head+1
        for _,d in ipairs({{8,0},{-8,0},{0,8},{0,-8}}) do
            local x,y=p[1]+d[1],p[2]+d[2]; local k=key(x,y)
            if not seen[k] and x>=22 and y>=22 and x+30<=Arena.width-22 and y+24<578 and not Arena.blocked(x,y,30,24) then
                seen[k]=true; queue[#queue+1]={x,y}
            end
        end
    end
    return function(t) for _,p in ipairs(queue) do if checkCollision(p[1],p[2],30,24,t.x,t.y,30,40) then return true end end; return false end
end
function T.run()
    Campaign.starts={{},{},{},{},{},{}}; Campaign.lastSide=nil
    local sides={}; local previous
    for n=1,9 do
        level(2,n); assert(#Arena.interior>=1,'Murs Enfer sans chevauchement')
        if not Campaign.carrier then
            assert(Campaign.lastSide~=previous,'Côté différent du précédent')
            previous=Campaign.lastSide; sides[previous]=true
            local x,y=objet.larme.x,objet.larme.y; reset_level(); assert(objet.larme.x==x and objet.larme.y==y,'Mort conserve le départ')
        end
        local reachable=flood()
        for _,p in ipairs(levels[n].larme_position) do assert(reachable(p),'Chemin Enfer '..n) end
        for _,m in ipairs(mobs) do if m.type=='scie' then
            for i=1,60 do MobBehaviors.scie.update(m,.04,true)
                assert(not Arena.blocked(m.tipX-20,m.tipY-20,40,40),'Rotation libre des murs '..n)
            end
        end end
    end
    local count=0; for _ in pairs(sides) do count=count+1 end; assert(count>=3,'Plusieurs côtés de départ')
    level(1,5); assert(#Arena.interior==0)
    local order={}; local tear,mob=Campaign.drawTear,Campaign.drawMob
    Campaign.drawTear=function() order[#order+1]='tear'; tear() end
    Campaign.drawMob=function(m) order[#order+1]='mob'; mob(m) end
    love.draw(); Campaign.drawTear=tear; Campaign.drawMob=mob
    assert(order[1]=='tear','Toutes les larmes derrière les monstres')
    level(1,1); mobs={}; player.x=700; player.y=300
    spawn_imp(150,300,50); local m=mobs[1]; m.charge=-.01
    MobBehaviors.imp.update(m,.6); assert(m.charge<0 and m.x>205,'Charge au-delà de 0,5 seconde')
    MobBehaviors.imp.update(m,1); assert(m.charge<0,'Charge encore active après 1,6 seconde')
    MobBehaviors.imp.update(m,1); assert(m.charge<0,'Charge encore active après 2,6 secondes')
    MobBehaviors.imp.update(m,.5); assert(m.charge>0,'Fin après trois secondes')
    for _,w in ipairs({1,2}) do
        level(w,3); mobs={}; spawn_spinner(700,400,110); local snake=mobs[1]; setup_spinner(snake)
        local clone={}; for k,v in pairs(snake) do clone[k]=v end
        for i=1,600 do
            player.x=60; player.y=100; MobBehaviors.spinner.update(snake,1/60)
            player.x=Arena.width-80; player.y=500; MobBehaviors.spinner.update(clone,1/60)
            assert(snake.x==clone.x and snake.y==clone.y,'Serpent indépendant du joueur')
            assert(not Arena.blocked(snake.x-20,snake.y-20,40,40),'Serpent hors des murs')
        end
    end
    level(1,1); mobs={}; spawn_scie(400,300,1,2,'left'); local rotor=mobs[1]; setup_rotor(rotor)
    local x,y=rotor.tipX,rotor.tipY; MobBehaviors.scie.update(rotor,.5,true)
    assert(math.abs(rotor.tipX-x)+math.abs(rotor.tipY-y)>20,'Tête du piège en orbite')
    player.x=rotor.tipX-15; player.y=rotor.tipY-12; MobBehaviors.scie.update(rotor,0)
    assert(player.reset,'Collision sur la tête mobile')
    for _,d in ipairs({'up','down','left','right'}) do
        level(2,10);Wasp.reset(true);local b=Wasp.bees[1];b.dir=d
        require('tests.wasp_trio').hit(Wasp,b);assert(Wasp.hp==8,'Contact sûr direction '..d)
    end
    print('PASS v5: murs/chemins Enfer, côtés variés, charge longue, serpents indépendants, pièges orbitaux, plans de rendu et contact guêpe directionnel')
end
T.reachable=flood
return T
