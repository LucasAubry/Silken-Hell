local T={}
function T.run()
    local W=Wasp
    W.reset(true);W.hp=6
    local three=W.tempo();W.bees[1].hp=0
    local two=W.tempo();W.bees[2].hp=0
    assert(two>three and W.tempo()>two,'Chaque mort accélère même à phase constante')
    W.reset(true);W.rest=100;W.hitGrace=100;player.x=400;player.y=300
    local a,b,c=unpack(W.bees)
    a.x=300;a.y=65;a.attack=2;W.positionAttack(a)
    assert(a.vy==1)
    b.x=350;b.y=65;b.attack=2;W.positionAttack(b)
    assert(b.vy==-1,'La seconde abeille prend le côté opposé')
    c.x=400;c.y=65;c.attack=2;W.positionAttack(c)
    assert(c.vx~=0,'La troisième abeille utilise un autre axe')
    a.phase='charge';a.x=300;a.y=200;a.vx=0;a.vy=1
    W.updateBees(.05);assert(a.y>=239,'Charge initiale à 780 pixels/s')
    a.phase='fatigued';assert(W.directionAvailable(b,0,1),'Direction libérée après impact')
    for _,hp in ipairs({9,8,3}) do
        W.reset(true);W.hp=hp;W.round=2;W.rest=0;W.hitGrace=100
        local fire=W.fireLarva;local times={};local spawned={}
        W.fireLarva=function(bee)
            times[#times+1]=W.elapsed;spawned[#spawned+1]=fire(bee)
        end
        for i=1,500 do W.update(.01);if #times>0 then break end end
        W.fireLarva=fire
        assert(#times==W.stage(),'Nombre de larves conservé par phase')
        for i,m in ipairs(spawned) do
            assert(times[i]==times[1],'Volée simultanée')
            assert(m.type=='magma_larva' and m.speed==245 and m.fuse==3.6,'Comportement des nids réutilisé')
        end
        for i=1,50 do W.updateBees(.01) end
        assert(W.round>3,'Transition immédiate après les larves')
    end
    W.reset(true);player.x=-1000;player.y=-1000;W.hitGrace=1000
    local seen={}
    for i=1,4000 do
        player.reset=false;W.update(.005)
        local directions={}
        for _,bee in ipairs(W.bees) do
            if bee.phase=='charge' then
                local key=bee.vx..':'..bee.vy
                assert(not directions[key],'Jamais deux charges simultanées dans le même sens')
                directions[key]=true;seen[key]=true
            end
        end
    end
    local n=0;for _ in pairs(seen) do n=n+1 end
    assert(n==4,'Les quatre sens sont utilisés')
    print('PASS wasp speed: fast charges/transitions, acceleration per death, exclusive directions, simultaneous genuine magma larvae')
end
return T
