local A={}
local T=require('localization').text
-- Screenshot record: real elapsed time, with the current shared death penalty.
function A.maxanceTime() return Scoring.total(552.732,95) end
function A.gillouTime() return Scoring.total(2264.85,513) end
A.list={
    {id='gillou',name='Plus rapide que Gillou',description=function()
        return 'Toucher les trois abeilles pendant le même KO, avant que l’une se réveille.'
    end},
    {id='maxance',name='Maxance',description=function()
        return 'Terminer le Paradis avec au moins 95 morts.'
    end}
}
for _,world in ipairs({1,6,5,4,7,2,3}) do
    local w=world
    A.list[#A.list+1]={id='flawless'..w,name=(Worlds.names[w] or 'Monde')..' sans faute',localizedName=function() return T('%s sans faute',T(Worlds.names[w] or 'Monde')) end,description=function() return T('Terminer %s sans mourir.',T(Worlds.names[w])) end}
end
function A.check(score,unlocked)
    if score.deaths==0 and not Worlds.isSecret(score.world) then unlocked['flawless'..score.world]=true end
    if score.world==1 and score.deaths>=95 then unlocked.maxance=true end
end
return A
