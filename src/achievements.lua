local A={}
local T=require('localization').text
-- Screenshot record: real elapsed time, with the current shared death penalty.
function A.maxanceTime() return Scoring.total(552.732,95) end
function A.gillouTime() return Scoring.total(2264.85,513) end
A.list={
    {id='gillou',category='secrets',name='Plus rapide que Gillou',description=function()
        return 'Toucher les trois abeilles pendant le même KO, avant que l’une se réveille.'
    end},
    {id='maxance',category='secrets',name='Maxance',description=function()
        return 'Terminer le Paradis avec au moins 95 morts.'
    end}
}
for _,world in ipairs({1,6,5,4,7,2,3}) do
    local w=world
    A.list[#A.list+1]={id='flawless'..w,category='mastery',name=(Worlds.names[w] or 'Monde')..' sans faute',localizedName=function() return T('%s sans faute',T(Worlds.names[w] or 'Monde')) end,description=function() return T('Terminer %s sans mourir.',T(Worlds.names[w])) end}
end
for _,world in ipairs(Worlds.order) do
    local w=world
    A.list[#A.list+1]={id='world'..w,world=w,category='worlds',name=Worlds.names[w],description=function() return T('Terminer %s.',T(Worlds.names[w])) end}
end
A.list[#A.list+1]={id='bossflawless1',category='mastery',name='Coquille parfaite',description=function() return 'Vaincre l’Œuf du Merle sans mourir pendant le niveau.' end}
function A.unlocked(a)
    return a.world and Profile.hasCompleted(a.world) or Profile.achievements[a.id]==true
end
function A.enterLevel()
    if not A.level or A.level.world~=Campaign.world or A.level.number~=player.level then
        A.level={world=Campaign.world,number=player.level,deaths=player.death}
    end
end
function A.finishLevel()
    if Replay.playing or App.sessionLayout or App.preview or Campaign.world~=1 or player.level~=10 then return end
    local l=A.level
    if l and l.world==1 and l.number==10 and l.deaths==player.death and Raven.active and Raven.defeated then
        Profile.achievements.bossflawless1=true;Profile.save()
    end
end
function A.check(score,unlocked)
    if score.deaths==0 and not Worlds.isSecret(score.world) then unlocked['flawless'..score.world]=true end
    if score.world==1 and score.deaths==0 then unlocked.bossflawless1=true end
    if score.world==1 and score.deaths>=95 then unlocked.maxance=true end
end
return A
