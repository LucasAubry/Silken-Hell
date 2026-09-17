local T={}
function T.run()
    local disabled=LevelLayouts.disabled; LevelLayouts.disabled=true
    local function level(w,n) Campaign.select(w); player.level=n; reset_level(); App.state='playing' end
    for rank,w in ipairs(Worlds.order) do
        local first,last=Atmosphere.settings(w,1),Atmosphere.settings(w,10)
        assert(last.transmission<first.transmission and first.seed~=last.seed,'Lumière décroissante et disposition différente par niveau')
        if rank>1 then assert(first.transmission<Atmosphere.settings(Worlds.order[rank-1],1).transmission,'Moins de lumière à chaque monde') end
    end
    level(5,4); local count=0
    for _,m in ipairs(mobs) do if m.type=='mole' then count=count+1 end end
    assert(count==2,'Seconde taupe plus tôt dans la Terre')
    level(2,9); assert(not Bosses.any() and not Wasp.active and #mobs==6 and #Magma.spawners==3,'Niveau 9 Enfer normal')
    Magma.update(.99); local before=#mobs; Magma.update(.02); assert(#mobs==before+3,'Premières larves après une seconde')
    Magma.update(3.01); assert(#mobs==before+6,'Invocations toutes les trois secondes')
    local m=mobs[1]; local lava=Hazards.lava[1]; m.x=lava.x; m.y=lava.y
    player.x=60; player.y=510; Burning.update(.01)
    assert(m.burnTime==5 and #Burning.trails>0,'La lave embrase les monstres')
    m.x=lava.x+120; m.y=lava.y; Burning.update(.13)
    local trail=Burning.trails[#Burning.trails]
    player.x=trail.x-15; player.y=trail.y-12; Burning.contact(); assert(player.reset,'Traînée mortelle')
    player.reset=false; player.x=60; player.y=510; mobs={}; Burning.update(3)
    assert(#Burning.trails==0,'Le feu s’éteint sans accumulation')
    level(2,1); assert(#Burning.trails==0)
    local scores=Profile.scores; Profile.scores={
        {world=2,name='Rapide',country='FR',time=10,deaths=40},
        {world=2,name='Prudent',country='FR',time=11,deaths=0},
        {world=2,name='Rapide',country='FR',time=10.5,deaths=10}}
    local ranked=Profile.ranking(2); assert(ranked[1].name=='Prudent' and ranked[2].time==11 and ranked[2].penalty==.5)
    assert(Profile.scores[3].time==10.5 and Profile.ranking(2)[2].time==11,'Pas de double pénalité ni de modification des sauvegardes')
    timer=10; player.death=10; assert(Scoring.total(timer,player.death)==10.5); love.draw()
    App.state='rankings'; UI.boardWorld=2; UI.boardPage=1; love.draw(); App.state='menu'; love.draw()
    Profile.scores=scores; LevelLayouts.disabled=disabled; level(1,1)
    print('PASS fire/scoring: depth lighting, earth difficulty, Hell 9, 1s/3s larvae, burning/trails/reset, adjusted rankings without double penalty and UI')
end
function T.visual()
    love.focus=function() end
    local shots={{5,1},{5,9},{6,3},{2,9},{1,1},{4,9}}
    local tick=0
    love.update=function()
        tick=tick+1; UI.clock=12+tick*.016
        if tick%5==1 then
            local s=shots[math.floor(tick/5)+1]; if not s then love.event.quit();return end
            LevelLayouts.disabled=true; Campaign.select(s[1]);player.level=s[2];reset_level();App.state='playing';timer=65;player.death=10
            if s[1]==2 then local m=mobs[1];local lava=Hazards.lava[1];m.x=lava.x;m.y=lava.y;Burning.update(.01)
                for i=1,12 do m.x=m.x+8;Burning.update(.13) end
            end
            App.capture='depth-'..s[1]..'-'..s[2]..'.png'
        end
    end
end
return T
