local T={}
function T.run()
    Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
    App.sessionLayout=nil;App.singleLevel=false;LevelLayouts.disabled=true;Secret.duel=nil
    Input.slow=function() return false end
    local O=Octopus
    local function reset()
        Campaign.select(4);player.level=10;reset_level();App.state='playing'
        player.x=70;player.y=420;player.reset=false
    end
    local function crab(x,y,vx,vy)
        return {x=x,y=y,speed=150,age=0,angle=0,vx=1,vy=0,
            fling=vx and {vx=vx,vy=vy,time=1.6} or nil,
            hitBox_width=28,hitBox_height=24,hitBox_offset_x=-14,hitBox_offset_y=-12}
    end
    reset()
    for _,case in ipairs({
        {40,300,-760,0},{Arena.width-40,300,760,0},
        {100,40,0,-760},{100,560,0,760},
        {140,200,760,0,{x=180,y=130,w=20,h=140}},
        {200,140,0,760,{x=130,y=180,w=140,h=20}},
        {140,200,760,0,{x=180,y=130,w=20,h=140,rotation=35}}
    }) do
        reset()
        if case[5] then Arena.walls[#Arena.walls+1]=case[5] end
        local c=crab(case[1],case[2],case[3],case[4]);O.crabs={c}
        local hp=O.hp
        for _=1,60 do O.updateCrabs(1/120);if c.dead then break end end
        assert(c.dead==0 and #O.blasts==1,'Propelled crab explodes on border, interior and rotated walls')
        assert(O.hp==hp and O.stun==0,'Wall impact alone does not hurt or stun the boss')
        O.crabContact(c);O.explodeCrab(c)
        assert(#O.blasts==1,'A crab explodes only once')
    end
    for _,inked in ipairs({false,true}) do
        reset()
        local c=crab(36,200);c.inked=inked;O.crabs={c}
        O.updateCrabs(1/120)
        assert(c.dead==0 and #O.blasts==1,'Walking crab explodes on exact wall contact, with or without ink')
    end
    reset()
    local c=crab(36,200);O.crabs={c};O.crabContact(c)
    assert(c.dead==0,'Contact checks also explode a stationary crab touching a wall')
    reset()
    local first=crab(36,200);local neighbor=crab(90,200);O.crabs={first,neighbor}
    O.crabContact(first)
    assert(neighbor.fling and not neighbor.dead,'The explosion propels nearby crabs')
    Arena.walls[#Arena.walls+1]={x=140,y=150,w=20,h=100}
    for _=1,60 do O.updateCrabs(1/120);if neighbor.dead then break end end
    assert(neighbor.dead and #O.blasts==2,'A propelled neighbor explodes at the next wall')
    for _,state in ipairs({'emerge','is_frozen','tunnelTravel'}) do
        reset();local c=crab(36,200);c[state]=state=='emerge' and .5 or true
        O.crabContact(c);assert(not c.dead,'Inactive crab remains protected: '..state)
    end
    reset();O.defeated=true;local c=crab(36,200);O.crabContact(c)
    assert(not c.dead,'No wall explosion after boss defeat')
    reset();O.active=false;c=crab(40,200,-760,0)
    O.moveFlungCrab(c,.1,function()end)
    assert(not c.dead,'Ordinary ocean crabs retain their wall behavior')
    require('tests.crab_walls').run(reset)
    print('PASS crab wall explosions: borders, interior and rotated walls, walking, ink, chain reactions, single blast and ordinary crab detours')
    love.event.quit()
end
return T
