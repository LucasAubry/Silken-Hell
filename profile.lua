local P = {name='', country='', character=1, unlocked=1, music=0.35, sound=0.65,
    stats={tears=0,deaths=0,attempts=0}, achievements={}, keys={up='up',down='down',left='left',right='right',dash='space'}, scores={}}
local actions={'up','down','left','right','dash'}
function P.load()
    P.scores={}; P.achievements={};P.stats={tears=0,deaths=0,attempts=0}
    local data=love.filesystem.read('profile.txt') or ''
    local version=tonumber(data:match('progressVersion=(%d+)')) or 1
    for line in data:gmatch('[^\n]+') do
        local k,v=line:match('^(%w+)=(.*)$')
        if k=='totalTears' then P.stats.tears=math.max(0,math.floor(tonumber(v) or 0))
        elseif k=='totalDeaths' then P.stats.deaths=math.max(0,math.floor(tonumber(v) or 0))
        elseif k=='totalAttempts' then P.stats.attempts=math.max(0,math.floor(tonumber(v) or 0))
        elseif k=='achievementGillou' then P.achievements.gillou=v=='1'
        elseif k=='achievementMaxance' then P.achievements.maxance=v=='2'
        elseif k=='name' then P.name=v
        elseif k=='country' then P.country=v:match('^%u%u$') or ''
        elseif k=='character' then P.character=math.max(1,math.min(5,tonumber(v) or 1))
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
        local w,n,c,t,d,skin=line:match('^(%d+)\t([^\t]+)\t(%u%u)\t([%d%.]+)\t(%d+)\t?(%d*)$')
        if w and tonumber(t)>0 then table.insert(P.scores,{world=tonumber(w),name=n,country=c,time=tonumber(t),deaths=tonumber(d),skin=tonumber(skin) or 1}) end
    end
    for _,score in ipairs(P.scores) do
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
    local rows={'statsVersion=1','totalTears='..P.stats.tears,'totalDeaths='..P.stats.deaths,'totalAttempts='..P.stats.attempts,'achievementGillou='..(P.achievements.gillou and '1' or '0'),'achievementMaxance='..(P.achievements.maxance and '2' or '0'),'progressVersion=2','name='..P.name,'country='..P.country,'character='..(P.character or 1),'unlocked='..P.unlocked,'music='..P.music,'sound='..P.sound}
    for _,a in ipairs(actions) do table.insert(rows,a..'='..P.keys[a]) end
    local ok=love.filesystem.write('profile.txt',table.concat(rows,'\n'))
    local scores={}
    for _,s in ipairs(P.scores) do scores[#scores+1]=string.format('%d\t%s\t%s\t%.3f\t%d\t%d',s.world,s.name,s.country,s.time,s.deaths,s.skin or 1) end
    local ok2=love.filesystem.write('scores.tsv',table.concat(scores,'\n'))
    P.error=not (ok and ok2) and 'Sauvegarde impossible : vérifie les droits du dossier.' or nil
end
function P.record(kind)
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
function P.complete(world,time,deaths)
    P.scores[#P.scores+1]={world=world,name=P.name,country=P.country,time=time,deaths=deaths,skin=App.runSkin or P.character}
    Achievements.check(P.scores[#P.scores],P.achievements)
    if not Worlds.isSecret(world) then P.unlocked=math.max(P.unlocked,Worlds.rank(Worlds.next(world) or world)) end
    P.save()
end
return P
