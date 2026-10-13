local A={}
local T=require('localization').text
-- Screenshot record: real elapsed time, with the current shared death penalty.
function A.maxanceTime() return Scoring.total(552.732,95) end
function A.gillouTime() return Scoring.total(2264.85,513) end
A.list={
    {id='workshop_publish',category='community',name='Créateur',rewardSkin=24,description=function() return 'Publie une carte sur le Workshop.' end},
    {id='workshop_test',category='community',name='Explorateur',rewardSkin=25,description=function() return 'Teste une carte du Workshop ou ta propre création.' end},
    {id='heartbreak',category='secrets',name='Une triste fin',rewardEffect='heartbreak',description=function()
        return ''
    end},
    {id='worlds_all',category='worlds',name='Tous les mondes',trophy='story_first',
        description=function() return 'Termine les sept mondes en parcours complet (hors entraînement).' end},
    {id='story_all',category='story',name='Tous ses mots',story='all',trophy='story_all',
        description=function() local found,total=require('story').progress();return T('Retrouve tous les textes qu’elle t’a laissés. %d/%d',found,total) end},
    {id='gillou',category='secrets',name='3 piques d’un coup',rewardSkin=13,description=function()
        return 'En Enfer, fais charger les trois sœurs contre un mur, puis touche-les toutes avant le réveil de la première.'
    end},
    {id='maxance',category='secrets',name='C’est dur ?',rewardSkin=14,description=function()
        return 'Termine un parcours complet du Paradis avec au moins 95 morts.'
    end},
    {id='flawless_all',category='mastery',name='Un fil sans faute',trophy='flawless_all',rewardSkin=23,description=function()
        return 'Termine chacun des sept mondes sans mourir, en parcours complet (hors entraînement).'
    end},
    {id='hardcore_all',category='mastery',name='Tous les mondes · Hardcore',trophy='hardcore_all',rewardSkin=27,description=function()
        return 'Termine chacun des sept mondes en hardcore, en parcours complet (hors entraînement).'
    end},
    {id='hardcore',category='mastery',name='Auréole hardcore',rewardEffect='hardcore',description=function()
        return 'Termine un biome en hardcore, en parcours complet (hors entraînement).'
    end},
    {id='top1',category='mastery',name='Premier du classement',rewardEffect='gold',description=function()
        return 'Atteins la première place mondiale d’un biome, en normal ou en hardcore.'
    end}
}
for _,world in ipairs(Worlds.order) do
    local w=world
    A.list[#A.list+1]={id='world'..w,world=w,rewardSkin=w==4 and 4 or Worlds.rank(w)+5,category='worlds',name=Worlds.names[w],description=function() return T('Termine tous les niveaux de %s en parcours complet (hors entraînement).',T(Worlds.names[w])) end}
end
-- Group the gallery by its reward while preserving the order within each group.
local grouped,seen={},{}
for _,field in ipairs({'rewardEffect','rewardSkin','trophy'}) do
    for _,a in ipairs(A.list) do
        if a[field] and not seen[a.id] then grouped[#grouped+1]=a;seen[a.id]=true end
    end
end
A.list=grouped
local function allFlawless(flags,scores)
    local done={}
    for _,score in ipairs(scores or {}) do if score.deaths==0 then done[score.world]=true end end
    for _,world in ipairs(Worlds.order) do
        if flags['flawless'..world]~=true and not done[world] then return false end
    end
    return true
end
function A.unlocked(a)
    local flags=Profile.achievements or {}
    if a.id=='worlds_all' then
        for _,world in ipairs(Worlds.order) do if not Profile.hasCompleted(world) then return false end end
        return true
    end
    if a.id=='hardcore_all' then
        local done={}
        for _,score in ipairs(Profile.scores or {}) do if score.hardcore==true then done[score.world]=true end end
        for _,world in ipairs(Worlds.order) do
            if not done[world] and not ((Hardcore.completed or {})[tostring(world)] or (Hardcore.completed or {})[world]) then return false end
        end
        return true
    end
    if a.id=='flawless_all' then return flags.flawless_all==true or allFlawless(flags,Profile.scores) end
    if a.id=='top1' then return require('skin_effects').unlocked('gold') end
    if a.id=='hardcore' then return require('skin_effects').unlocked('hardcore') end
    if a.story then
        local found,total=require('story').progress()
        return found>=(a.story=='all' and total or a.story)
    end
    return a.world and Profile.hasCompleted(a.world) or flags[a.id]==true
end
-- Retain these hooks for the level lifecycle; the retired boss challenge no
-- longer awards progress. Its old save flag remains available to boss stats.
function A.enterLevel() end
function A.finishLevel() end
function A.canEarn()
    return not Replay.playing and not App.preview and not App.sessionLayout and not App.workshopMap
        and not App.practice and not App.singleLevel and not Secret.duel
end
function A.workshop(id)
    if Replay.playing or (id~='workshop_test' and id~='workshop_publish') or Profile.achievements[id] then return false end
    Profile.achievements[id]=true;Profile.save();return true
end
function A.award(id)
    if not A.canEarn() or Profile.achievements[id] then return false end
    Profile.achievements[id]=true;Profile.save();return true
end
function A.check(score,unlocked)
    -- Keep per-world flags as saved progress, not separate achievements. Runs
    -- may be completed in any order and in either normal or hardcore mode.
    if Worlds.rank(score.world)<=#Worlds.order then
        if score.deaths==0 then unlocked['flawless'..score.world]=true end
        if score.hardcore==true then unlocked.hardcore=true end
    end
    if allFlawless(unlocked) then unlocked.flawless_all=true end
    if score.world==1 and score.deaths>=95 then unlocked.maxance=true end
end
return A
