local T={}
function T.run()
    local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a)..' != '..tostring(b)) end
    near(Scoring.penalty(3),1);near(Scoring.penalty(1),1/3);near(Scoring.penalty(513),171)
    near(Achievements.gillouTime(),2435.85)
    local flags={}
    Achievements.check({world=14,time=2264.85,deaths=513},flags);assert(not flags.gillou,'Égalité ne suffit pas')
    Achievements.check({world=2,time=1,deaths=0},flags);assert(not flags.gillou,'Boss classique exclu')
    Achievements.check({world=14,time=2264.84,deaths=513},flags);assert(flags.gillou)
    Achievements.check({world=1,time=100,deaths=95},flags);assert(not flags.maxance)
    Achievements.check({world=6,time=100,deaths=96},flags);assert(not flags.maxance)
    Achievements.check({world=1,time=100,deaths=96},flags);assert(not flags.maxance)
    Achievements.check({world=1,time=552.732,deaths=95},flags);assert(flags.maxance)
    Profile.name='QA';Profile.scores={};Profile.achievements={}
    Profile.complete(14,2264.84,513);Profile.complete(1,552.732,95);Profile.load()
    assert(Profile.achievements.gillou and Profile.achievements.maxance,'Succès sauvegardés')
    near(Profile.ranking(14)[1].time,2435.84);near(Profile.scores[1].time,2264.84)
    LevelLayouts.disabled=true;Campaign.select(1);player.level=1;reset_level();App.state='playing'
    mobs={};Arena.interior={};player.x=300;player.y=300;player.speed=1;player.reset=false
    local oldKeys=love.keyboard.isDown;local slow=false;local moving=true
    love.keyboard.isDown=function(key) return moving and key==Profile.keys.right or slow and key==Profile.keys.dash end
    local x=player.x;App.move(.02);near(player.x-x,10.8);assert(player.dashing)
    slow=true;x=player.x;App.move(.02);near(player.x-x,6);assert(not player.dashing)
    moving=false;slow=false;x=player.x;App.move(.02);near(player.x,x);assert(not player.dashing)
    love.keyboard.isDown=oldKeys
    App.state='achievements';love.draw();App.capture='achievements-revision.png'
    local frames=0;love.update=function() frames=frames+1;if frames==3 then
        print('PASS controls/scoring/achievements: default sprint, held slowdown, fractional penalties, strict thresholds, persistence, UI')
        love.event.quit()
    end end
end
return T
