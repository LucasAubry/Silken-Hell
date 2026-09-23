local P = {name='', country='', character=1, unlocked=1, music=0.35, sound=0.65,
    stats={tears=0,deaths=0,attempts=0}, achievements={}, keys={up='up',down='down',left='left',right='right',dash='space'}, scores={}}
local json=require 'json'
local actions={'up','down','left','right','dash'}
function P.load()
    P.levels={};P.completed={};P.scores={}; P.achievements={};P.stats={tears=0,deaths=0,attempts=0}
    local data=love.filesystem.read('profile.txt') or ''
    local version=tonumber(data:match('progressVersion=(%d+)')) or 1
    for line in data:gmatch('[^\n]+') do
        local k,v=line:match('^(%w+)=(.*)$')
        if k and k:match('^level%d+$') then P.levels[tonumber(k:match('%d+'))]=math.max(1,math.min(10,tonumber(v) or 1))
        elseif k and k:match('^completed%d+$') then P.completed[tonumber(k:match('%d+'))]=v=='1'
        elseif k=='totalTears' then P.stats.tears=math.max(0,math.floor(tonumber(v) or 0))
        elseif k=='totalDeaths' then P.stats.deaths=math.max(0,math.floor(tonumber(v) or 0))
        elseif k=='totalAttempts' then P.stats.attempts=math.max(0,math.floor(tonumber(v) or 0))
        elseif k=='achievementGillou' then P.achievements.gillou=v=='2'
        elseif k=='achievementMaxance' then P.achievements.maxance=v=='2'
        elseif k and k:match('^flawless%d+$') then P.achievements[k]=v=='1'
        elseif k=='name' then P.name=v
        elseif k=='country' then P.country=v:match('^%u%u$') or ''
        elseif k=='character' then P.character=math.max(1,math.min(14,tonumber(v) or 1))
        elseif k=='unlocked' then P.unlocked=math.max(1,math.min(7,tonumber(v) or 1))
        elseif k=='music' or k=='sound' then P[k]=math.max(0,math.min(1,tonumber(v) or 0.5))
        else for _,a in ipairs(actions) do if k==a and v~='' then P.keys[a]=v end end end
    end
    if version<2 then
        local old=P.unlocked; P.unlocked=1
        for _,id in ipairs({1,2,4,5,6}) do if id<=old then P.unlocked=math.max(P.unlocked,Worlds.rank(id)) end end
    end
    -- Country is resolved from the connection by Cloudflare, never from language.
    P.country='ZZ'
    for line in (love.filesystem.read('scores.tsv') or ''):gmatch('[^\n]+') do
        local w,n,c,t,d,skin,replay=line:match('^(%d+)\t([^\t]+)\t(%u%u)\t([%d%.]+)\t(%d+)\t?(%d*)\t?([a-f0-9]*)$')
        if w and tonumber(t)>0 then table.insert(P.scores,{world=tonumber(w),name=n,country=c,time=tonumber(t),deaths=tonumber(d),skin=tonumber(skin) or 1,replay=replay and #replay==64 and replay or nil}) end
    end
    local valid,details=pcall(json.decode,love.filesystem.read('score_details.json') or '')
    if valid and type(details)=='table' then for _,s in ipairs(P.scores) do s.splits=details[RunDetails.key(s)] end end
    for _,score in ipairs(P.scores) do
        P.completed[score.world]=true;P.levels[score.world]=Worlds.levelCount(score.world)
        if score.world==2 then P.unlocked=math.max(P.unlocked,7) end
        Achievements.check(score,P.achievements)
    end
    if not data:match('statsVersion=1') then
        for _,score in ipairs(P.scores) do
            P.stats.deaths=P.stats.deaths+score.deaths
            P.stats.attempts=P.stats.attempts+score.deaths+1
            P.stats.tears=P.stats.tears+Worlds.levelCount(score.world)
        end
        P.save()
    end
end
function P.save()
    if Replay and Replay.playing then return end
    local rows={'statsVersion=1','totalTears='..P.stats.tears,'totalDeaths='..P.stats.deaths,'totalAttempts='..P.stats.attempts,'achievementGillou='..(P.achievements.gillou and '2' or '0'),'achievementMaxance='..(P.achievements.maxance and '2' or '0'),'progressVersion=2','name='..P.name,'country='..P.country,'character='..(P.character or 1),'unlocked='..P.unlocked,'music='..P.music,'sound='..P.sound}
    for id,done in pairs(P.achievements) do if id:match('^flawless%d+$') and done then rows[#rows+1]=id..'=1' end end
    for world,n in pairs(P.levels or {}) do rows[#rows+1]='level'..world..'='..n end
    for world,done in pairs(P.completed or {}) do if done then rows[#rows+1]='completed'..world..'=1' end end
    for _,a in ipairs(actions) do table.insert(rows,a..'='..P.keys[a]) end
    local ok=love.filesystem.write('profile.txt',table.concat(rows,'\n'))
    local scores={}
    for _,s in ipairs(P.scores) do scores[#scores+1]=string.format('%d\t%s\t%s\t%.3f\t%d\t%d\t%s',s.world,s.name,s.country,s.time,s.deaths,s.skin or 1,s.replay or '') end
    local ok2=love.filesystem.write('scores.tsv',table.concat(scores,'\n'))
    local details={};for _,s in ipairs(P.scores) do if s.splits then details[RunDetails.key(s)]=s.splits end end
    local ok3=love.filesystem.write('score_details.json',json.encode(details))
    P.error=not (ok and ok2 and ok3) and 'Sauvegarde impossible : vérifie les droits du dossier.' or nil
end
function P.record(kind)
    if Replay and Replay.playing then return end
    P.stats[kind]=(P.stats[kind] or 0)+1
    if kind=='deaths' then P.stats.attempts=P.stats.attempts+1 end
    P.save()
end
function P.ranking(world,country)
    local result={}
    for _,s in ipairs(P.scores) do if s.world==world then
        local row={}; for k,v in pairs(s) do row[k]=v end
        row.rawTime=s.time; row.penalty=Scoring.penalty(s.deaths); row.time=Scoring.total(s.time,s.deaths)
        result[#result+1]=row
    end end
    table.sort(result,function(a,b) if a.time==b.time then return a.deaths<b.deaths end return a.time<b.time end)
    local all={}
    for _,score in ipairs(result) do if not country or score.country==country then all[#all+1]=score end end
    return all
end
function P.levelReached(world,n)
    if Replay and Replay.playing then return end
    if App.singleLevel or App.sessionLayout or App.preview then return end
    P.levels=P.levels or {};P.levels[world]=math.max(P.levels[world] or 1,n);P.save()
end
function P.hasCompleted(world)
    if (P.completed or {})[world] then return true end
    for _,s in ipairs(P.scores) do if s.world==world then return true end end
    return false
end
function P.complete(world,time,deaths)
    if Replay and Replay.playing then return end
    P.completed=P.completed or {};P.completed[world]=true
    P.levels=P.levels or {};P.levels[world]=Worlds.levelCount(world)
    P.scores[#P.scores+1]={world=world,name=P.name,country=P.country,time=time,deaths=deaths,splits=RunDetails.snapshot(),skin=App.runSkin or P.character}
    if Replay and Replay.recording then Replay.finish(P.scores[#P.scores]) end
    Achievements.check(P.scores[#P.scores],P.achievements)
    if not Worlds.isSecret(world) then P.unlocked=math.max(P.unlocked,Worlds.rank(Worlds.next(world) or world)) end
    P.save()
end
return P
