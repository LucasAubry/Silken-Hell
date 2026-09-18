local T={}
function T.run()
    Campaign.select(2);player.level=10;LevelLayouts.disabled=true;reset_level();App.state='playing'
    local W=Wasp
    local walls,interior=Arena.walls,Arena.interior
    Arena.walls={unpack(walls,1,4)};Arena.interior={}
    local function reset()
        W.reset(true);W.rest=100;player.reset=false;player.abyssGrace=0;player.x=400;player.y=300
        for _,b in ipairs(W.bees) do b.x=100*b.id;b.y=100 end
    end
    for _,phase in ipairs({'ready','queued','position','aim','charge','hiding','cooldown','dead'}) do
        reset();local b=W.bees[1];b.phase=phase;b.x=player.x+15;b.y=player.y+12
        if phase=='dead' then b.hp=0;b.deadTime=100 end
        W.contact();assert(player.reset,'Collision dans la phase '..phase)
    end
    reset();local b=W.bees[1];b.phase='position';b.x=250;b.y=310
    W.approach(b,600,310,4000,.1);assert(player.reset,'Collision balayée pendant repositionnement rapide')
    reset();b=W.bees[1];b.phase='charge';b.x=250;b.y=310;b.vx=1;b.vy=0;W.roundActive=true
    W.updateBees(.2);assert(player.reset,'Collision balayée pendant charge rapide')
    reset();b=W.bees[1];b.phase='fatigued';b.x=415;b.y=312
    W.contact();assert(b.hp==2 and not player.reset,'Coup au KO sans mort immédiate')
    local other=W.bees[2];other.x=415;other.y=312;W.contact()
    assert(player.reset,'Toucher une sœur ne protège pas contre les autres')
    reset();b=W.bees[1];b.hp=1;b.phase='fatigued';b.x=415;b.y=312
    W.contact();assert(b.hp==0 and not player.reset,'Brève sortie sûre du corps nouvellement tué')
    player.x=700;player.y=500;W.update(1)
    player.x=b.x-15;player.y=b.y-12;W.contact();assert(player.reset and b.phase=='dead','Cadavre persistant mortel')
    for _,attack in ipairs({1,2,3}) do
        reset();W.bees[1].hp=0;W.bees[1].phase='dead';W.bees[2].hp=0;W.bees[2].phase='dead'
        b=W.bees[3];b.attack=attack;b.phase='aim';b.time=0;b.launchLarva=true;b.vx=1;b.vy=0
        W.roundActive=true;W.hp=3;local count=#mobs
        W.updateBees(.001);assert(#mobs==count+2,'Deux larves au départ de chaque attaque solo '..attack)
        W.updateBees(.001);assert(#mobs==count+2,'Pas de double émission')
        assert(mobs[#mobs].type=='magma_larva')
    end
    reset();W.bees[1].hp=0;W.bees[1].phase='dead';W.bees[2].hp=0;W.bees[2].phase='dead'
    b=W.bees[3];b.hp=1;W.hp=1;b.phase='fatigued';b.x=415;b.y=312
    W.contact();assert(W.defeated and not objet.larme.taken)
    for _,dead in ipairs(W.bees) do assert((objet.larme.x+15-dead.x)^2+(objet.larme.y+20-dead.y)^2>=100^2,'Larme accessible hors des corps') end
    player.x=700;player.y=500;W.update(1);love.draw()
    player.x=b.x-15;player.y=b.y-12;W.contact();assert(player.reset,'Cadavres dangereux même après victoire')
    Arena.walls,Arena.interior=walls,interior
    print('PASS wasp contact: all flight phases, swept motion, local hit grace, persistent lethal corpses, safe reward, solo larvae on all attacks')
end
return T
