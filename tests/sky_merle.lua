local T={}
local function reset(custom)
    Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
    App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;LevelLayouts.disabled=true
    Campaign.select(6);player.level=10;reset_level();App.state='playing';player.reset=false
    if custom then
        LevelLayouts.disabled=false
        Workshop.playLayout({world=6,level=10,width=960,height=600,entities={
            {kind='spawn',x=480,y=505},{kind='boss',type='storm',x=480,y=170},
            {kind='tornado',x=230,y=220},{kind='tornado',x=730,y=405}}})
    end
    return custom and Bosses.items[1].boss or Storm
end
local function charge(b)
    player.x=90;player.y=450;b.projectiles={};b.trails={};b.strikes={};b.shot=100;b.bolt=100
    b.summon();b.update(.5);assert(b.chargeTime==0,'Lightning is telegraphed before charging')
    b.update(.51);assert(b.chargeTime>5 and not player.reset,'Gold lightning charges without killing')
end
local function hit(b)
    b.hitGrace=0;player.x=b.x-15;player.y=b.y-12;player.dashing=true;b.contact();player.dashing=false
end
local function encounter(custom)
    local b=reset(custom);assert(b.active and b.hp==8 and not b.electric and #Realms.tornadoes==0)
    Realms.lightningClock=0;Realms.updateLightning(1);assert(#Realms.lightning==0,'Ambient lethal lightning yields to boss lightning')
    local kill=Hazards.kill;local deaths=0;Hazards.kill=function() deaths=deaths+1 end
    hit(b);assert(b.hp==8 and deaths==1,'Uncharged dash cannot hurt the boss')
    b.chargeTime=2;player.dashing=false;b.contact();assert(b.hp==8 and deaths==2,'Charge requires a dash')
    player.x=90;player.y=450;b.chargeTime=0;b.fire();assert(not b.projectiles[1].electric,'First half uses ordinary feathers')
    for i=1,4 do charge(b);hit(b);assert(b.hp==8-i and b.chargeTime==0) end
    assert(b.electric and b.phase=='lightning','Half HP transforms immediately')
    player.x=90;player.y=450;b.hitGrace=0;b.shot=0;b.bolt=0;b.update(.05)
    assert(#b.projectiles>0 and b.projectiles[1].electric and #b.strikes>0 and #b.trails>0,'Electric feathers, trails and ground lightning coexist')
    b.projectiles={};b.trails={{x=200,y=300,tx=240,ty=300,life=2.2}}
    player.x=205;player.y=288;b.chargeTime=3;local before=deaths;b.contact();assert(deaths==before+1,'Charge never grants trail immunity')
    player.x=80;player.y=450;b.shot=100;b.bolt=100;b.update(2.3);assert(#b.trails==0,'Trails expire')
    b.projectiles={};b.trails={};b.setPhase('tornado');b.chargeTime=0
    local t=b.tornado;assert(t.x==Arena.width/2 and t.y==Arena.height/2)
    player.x=t.x+180-15;player.y=t.y-12;local x=player.x;b.updateTornado(.5);assert(player.x==x,'Tornado warning does not pull')
    t.age=t.warning;b.updateTornado(.05);assert(player.x<x,'Active tornado pulls player')
    x=player.x
    local move,slow=Input.move,Input.slow;Input.move=function() return 1,0 end;Input.slow=function() return false end
    App.move(.05);b.updateTornado(.05);Input.move=move;Input.slow=slow
    assert(player.x>x,'Real player running speed overcomes suction')
    local mob={x=t.x+200,y=t.y,hitBox_width=20,hitBox_height=20,hitBox_offset_x=-10,hitBox_offset_y=-10}
    mobs={mob};b.projectiles={{x=t.x+200,y=t.y,vx=0,vy=0,life=2}}
    b.updateTornado(.05);assert(mob.x<t.x+200 and b.projectiles[1].vx<0,'Tornado pulls creatures and feathers')
    mobs={};b.projectiles={};player.x=t.x-15;player.y=t.y-12;b.updateTornado(.01);assert(player.skyWhirl,'Core captures player')
    b.updateTornado(.81);assert(player.skyThrow and not player.skyWhirl,'Vortex throws captured player')
    before=deaths;for i=1,100 do b.updateTornado(.02);if not player.skyThrow then break end end
    assert(deaths==before+1 and not player.skyThrow,'Wall impact kills thrown player')
    player.x=80;player.y=450;b.setPhase('tornado');b.updateTornado(6.3);assert(not b.tornado,'Tornado stops on its own')
    b.setPhase('lightning');charge(b);b.update(6);assert(b.chargeTime==0,'Unused charge expires')
    b.setPhase('lightning')
    while b.hp>0 do charge(b);hit(b) end
    assert(b.defeated and Campaign.canCollect() and #b.trails==0 and not b.tornado,'Charged hits win and clear hazards')
    Hazards.kill=kill
    b=reset(custom);assert(not player.skyWhirl and not player.skyThrow and b.chargeTime==0 and not b.electric,'Reset clears encounter state')
end
function T.run()
    encounter(false);encounter(true)
    Bosses.load({{type='storm',x=240,y=160},{type='storm',x=720,y=160}},{},{})
    local a,c=Bosses.items[1].boss,Bosses.items[2].boss
    a.chargeTime=3;a.setPhase('tornado');a.trails={{x=100,y=200,tx=150,ty=220,life=1}}
    assert(c.chargeTime==0 and not c.tornado and #c.trails==0,'Custom boss instances keep independent state')
    Bosses.resize(1.25);assert(a.trails[1].x==125 and a.trails[1].tx==187.5 and a.tornado.x==Arena.width/2*1.25,'Resize keeps tornado and trail endpoints aligned')
    print('PASS sky Merle: native/custom, charged dash, half-HP transformation, lethal trails, concurrent lightning, resistible timed vortex, capture/wall death, victory/reset')
    reset(false)
    local saved=require('json').decode(love.filesystem.read('tests/sky_merle_layout.json'))
    assert(LayoutSchema.validate(saved))
    LevelLayouts.disabled=false;App.sessionLayout=saved;reset_level()
    assert(#Bosses.items==1 and Bosses.items[1].kind=='storm' and #Realms.rainSites==0 and #Realms.holes==0,'Authored sky level ten loads the boss arena')
    local b=Bosses.items[1].boss;local frame=0
    love.focus=function() end
    love.update=function()
        frame=frame+1
        if frame==1 then App.capture='sky-merle-normal.png'
        elseif frame==3 then
            b.hp=4;b.electric=true;b.name='Merle noir · Fureur électrique';b.hitGrace=0
            player.x=650;player.y=420;b.summon();b.strikes[1].age=.5;b.fire();b.shot=100;b.bolt=100
            local kill=Hazards.kill;Hazards.kill=function() end
            for i=1,24 do b.update(1/60) end
            Hazards.kill=kill;b.chargeTime=4;App.capture='sky-merle-electric.png'
        elseif frame==5 then b.setPhase('tornado');b.tornado.age=2;b.chargeTime=0;App.capture='sky-merle-tornado.png'
        elseif frame==7 then io.stdout:flush();love.event.quit(0) end
    end
end
return T
