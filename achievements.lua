local A={}
-- Screenshot record: real elapsed time, with the current shared death penalty.
function A.maxanceTime() return Scoring.total(552.732,95) end
function A.gillouTime() return Scoring.total(2264.85,513) end
A.list={
    {id='gillou',name='Plus rapide que Gillou',description=function()
        return 'Vaincre les Sœurs de lave hardcore en moins de '..UI.time(A.gillouTime())..', pénalités comprises.'
    end},
    {id='maxance',name='Maxance',description=function()
        return 'Terminer le Paradis avec au moins 95 morts et un chrono final de 9:44.40 ou plus.'
    end}
}
function A.check(score,unlocked)
    if score.world==14 and Scoring.total(score.time,score.deaths)<A.gillouTime() then unlocked.gillou=true end
    if score.world==1 and score.deaths>=95 and Scoring.total(score.time,score.deaths)>=A.maxanceTime() then unlocked.maxance=true end
end
return A
