local T={}
local function reset(n)
    Online.enabled=false;Replay.disabled=true;Replay.recording=false;Replay.playing=false
    App.singleLevel=false;App.practice=nil;App.sessionLayout=nil;App.hardcore=false;LevelLayouts.disabled=true
    Campaign.select(3);player.level=n or 1;reset_level();App.state='playing';player.reset=false
end
function T.run()
    for n=1,Worlds.levelCount(3) do
        reset(n);assert(Renaissance.active and Renaissance.remaining==2 and not Bosses.any())
        assert(#mobs==(n>=3 and 4 or 3));assert(not willCollide(player.x,player.y))
    end
    reset();local b=mobs[3];local x,y=b.x,b.y
    Renaissance.update(.1);assert((b.x-player.x)^2+(b.y-player.y)^2<(x-player.x)^2+(y-player.y)^2,'Bush pursues')
    b.age=3.99;Renaissance.update(.02)
    local minis={};for _,m in ipairs(mobs) do if m.mini then minis[#minis+1]=m end end
    assert(#minis==3 and #Renaissance.blasts==1,'Parent releases three mini bushes')
    for _,m in ipairs(minis) do m.age=2.19 end
    Renaissance.update(.02);assert(#mobs==2 and #Renaissance.blasts==4,'Minis explode without multiplying')
    reset();b=mobs[3];b.x=player.x+15;b.y=player.y+12;b.age=4
    Renaissance.update(0);assert(player.reset,'Explosion kills inside radius')
    reset();b=Renaissance.bush(player.x+15,player.y+12,true);b.age=b.fuse
    Renaissance.update(0);assert(player.reset,'Mini explosion kills inside radius')
    reset();local f=Renaissance.follower;local fy=f.y
    Renaissance.update(.1);assert(f.y<fy and not player.reset,'White spider follows harmlessly')
    reset();Renaissance.addSoil(110,290);assert(#Renaissance.soil==1)
    player.x=70;player.y=280;Arena.move(player,10,0);assert(player.x==70,'Soil blocks movement')
    assert(willCollide(100,280),'Soil also blocks player physics')
    Renaissance.soil[1].life=.01;Renaissance.update(.02);assert(#Renaissance.soil==0 and not willCollide(100,280),'Trail expires')
    reset();local kill=Hazards.kill;Hazards.kill=function() end
    for _=1,150 do Renaissance.update(.05) end
    Hazards.kill=kill;assert(#Renaissance.soil>0 and #Renaissance.soil<=11,'Moving tree leaves bounded trail')
    local e=Renaissance.eggs[2];player.x=e.x;player.y=e.y;App.simulate(0)
    assert(player.level==1 and Renaissance.remaining==1,'Either egg can be collected first')
    local oldWidth=Arena.width;love.resize(1500,800)
    assert(Renaissance.remaining==1 and Renaissance.eggs[2].taken,'Resize retains collected eggs')
    for _,s in ipairs(Renaissance.soil) do assert(Arena.blocked(s.x,s.y,s.w,s.h),'Resize preserves soil collision') end
    e=Renaissance.eggs[1];player.x=e.x;player.y=e.y;App.simulate(0)
    assert(player.level==2 and Renaissance.remaining==2,'Both eggs advance and reset encounter')
    reset();local egg=Renaissance.eggs[1];player.x=egg.x;player.y=egg.y;Renaissance.collect();assert(Renaissance.remaining==1);reset_level();assert(Renaissance.remaining==2 and #Renaissance.soil==0,'Death resets encounter')
    reset(Worlds.levelCount(3));App.hardcore=true
    for i=1,2 do local egg=Renaissance.eggs[i];player.x=egg.x;player.y=egg.y;App.simulate(0) end
    assert(App.state=='victory','Last pair completes Renaissance')
    App.hardcore=false
    Campaign.select(1);player.level=1;reset_level();assert(not Renaissance.active and #Renaissance.eggs==0,'Other worlds retain tears')
    print('PASS Renaissance: pursuit, chained explosions, damage, friendly spider, solid expiring trail, two eggs, progression, reset, resize and isolation')
    reset(3);Hazards.kill=function() end
    for _=1,50 do Renaissance.update(.05) end
    Hazards.kill=kill
    local tick=0
    love.update=function()
        tick=tick+1
        if tick==1 then App.capture='rebirth-garden.png'
        elseif tick==3 then
            local bush;for _,m in ipairs(mobs) do if m.type=='rebirth_bush' then bush=m;break end end
            bush.age=bush.fuse;Renaissance.update(.01);App.capture='rebirth-explosion.png'
        elseif tick==5 then io.stdout:flush();love.event.quit(0) end
    end
end
return T
