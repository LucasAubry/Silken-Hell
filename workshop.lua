local json=require 'json'
local W={biome=1,difficulty=1,difficultyExtra='0',filterBiome=0,filterDifficulty=0,sort='stars',page=1,rows={},status='',busy=false,publishing=false,title='',author='',focus=nil}
local function encodePath(s) return (s:gsub('[^%w%-._~]',function(c) return string.format('%%%02X',c:byte()) end)) end
local function savedIds()
    local ok,data=pcall(json.decode,love.filesystem.read('workshop-publications.json') or '{}')
    return ok and data or {}
end
function W.refresh()
    if W.busy then return end
    W.busy=true; W.status='Chargement des cartes…'
    Online.request('/v1/workshop?page='..W.page..'&biome='..W.filterBiome..'&difficulty='..W.filterDifficulty..'&sort='..W.sort,nil,function(data,code)
        W.busy=false
        if code==200 then W.rows=data.maps or {}; W.hasMore=data.hasMore; W.status=#W.rows==0 and 'Aucune carte publiée pour le moment.' or 'Les cartes les plus étoilées sont en tête.'
        else W.status=data.error or 'Workshop indisponible. Réessaie dans un instant.' end
    end)
end
function W.filter(key,value)
    if W.busy then return end
    W[key]=value;W.page=1;W.refresh()
end
function W.open()
    App.state='workshop'; W.publishing=false; W.focus=nil; love.keyboard.setTextInput(false); W.refresh()
end
function W.playLayout(layout,row)
    local valid,why=LayoutSchema.validate(layout)
    if not valid then W.status=why; return false end
    App.practice=nil;App.sessionLayout=layout; App.singleLevel=true; App.workshopMap=row
    App.start(layout.world); return true
end
function W.play(row)
    if W.busy then return end
    W.busy=true; W.status='Téléchargement de la carte…'
    Online.request('/v1/workshop/'..encodePath(row.id),nil,function(data,code)
        W.busy=false
        if code==200 then W.playLayout(data.layout,row)
        else W.status=data.error or 'Téléchargement impossible.' end
    end)
end
function W.star(row)
    if row.voting then return end
    row.voting=true
    Online.request('/v1/workshop/'..encodePath(row.id)..'/star',{starred=not row.starred},function(data,code)
        row.voting=false
        if code==200 then row.starred=data.starred; row.stars=data.stars; W.refresh()
        else W.status=data.error or 'Étoile non enregistrée. Réessaie.' end
    end)
end
function W.chooseLocal()
    W.publishing=true; W.focus=nil; W.localPage=1; W.localRows={}; W.selected=nil
    for key,layout in pairs(LevelLayouts.read()) do W.localRows[#W.localRows+1]={key=key,layout=layout} end
    table.sort(W.localRows,function(a,b) return a.key<b.key end)
    W.author=Profile.name~='' and Profile.name or 'Créateur'
    W.status=#W.localRows==0 and 'Crée puis applique un niveau dans l’éditeur pour le publier ici.' or 'Choisis une de tes cartes enregistrées.'
end
function W.selectLocal(row)
    W.biome=row.layout.biome or row.layout.world;W.difficulty=row.layout.difficulty or 1;W.difficultyExtra=tostring(row.layout.difficultyExtra or 0)
    W.selected=row; W.title='Carte '..Worlds.names[W.biome]
end
function W.materialize()
    if not W.selected then return end
    local l=json.decode(json.encode(W.selected.layout))
    l.world=W.biome;l.level=1;l.biome=W.biome;l.difficulty=W.difficulty;l.difficultyExtra=W.difficulty==5 and tonumber(W.difficultyExtra) or 0
    return l
end
function W.canPublish()
    local l=W.materialize()
    return l and W.validated and W.validated.hash==Replay.hash(l) and W.validated.build==Replay.build()
end
function W.testPublication()
    local l=W.materialize();local ok,why=LayoutSchema.validate(l)
    if not ok then W.status=why;return end
    W.validationRun={hash=Replay.hash(l)};W.validated=nil;Secret.duel=nil;App.preview=false
    W.playLayout(l)
end
function W.validationFinished(data,id)
    local layout=data.layouts and data.layouts[data.world..':'..data.startLevel]
    if data.completed and data.single and not data.duel and id and W.validationRun and layout and Replay.hash(layout)==W.validationRun.hash then W.validated={hash=W.validationRun.hash,replay=data,build=data.build};W.status='Carte terminée : tu peux la publier.' end
end
function W.resumePublication()
    App.leaveCustom();W.validationRun=nil;App.state='workshop';W.publishing=true
end
function W.publish()
    if W.busy or not W.selected then return end
    if not W.canPublish() then W.status='Termine cette version de la carte avant de la publier.';return end
    local title=W.title:match('^%s*(.-)%s*$');local author=W.author:match('^%s*(.-)%s*$')
    if title=='' or author=='' then W.status='Renseigne le titre et ton pseudo.';return end
    local layout=W.materialize();local valid,why=LayoutSchema.validate(layout);if not valid then W.status=why;return end
    local ids=savedIds();local key=W.selected.key
    W.busy=true;W.status='Vérification de la partie terminée…'
    Online.request('/v1/workshop/validate',{layout=layout,replay=W.validated.replay},function(proof,code)
        if code~=201 then W.busy=false;W.status=proof.error or 'Validation indisponible.';return end
        Online.request('/v1/workshop',{id=ids[key],title=title,author=author,layout=layout,proof=proof.id},function(data,status)
            W.busy=false
            if status==200 or status==201 then
                ids[key]=data.id;love.filesystem.write('workshop-publications.json',json.encode(ids))
                W.publishing=false;W.focus=nil;love.keyboard.setTextInput(false);W.page=1;W.refresh()
            else W.status=data.error or 'Publication impossible. Ta carte reste enregistrée localement.' end
        end)
    end)
end
function W.text(text)
    if not W.focus then return end
    text=text:gsub('[%c]','');if W.focus=='difficultyExtra' then text=text:gsub('[^%d]','') end; local value=(W[W.focus] or '')..text
    if (require('utf8').len(value) or 999)<=(W.focus=='difficultyExtra' and 3 or W.focus=='title' and 60 or 24) then W[W.focus]=value end
end
function W.key(key)
    if W.focus and key=='backspace' then
        local value=W[W.focus]; local index=require('utf8').offset(value,-1); if index then W[W.focus]=value:sub(1,index-1) end
    elseif key=='return' or key=='escape' then W.focus=nil; love.keyboard.setTextInput(false) end
end
return W
