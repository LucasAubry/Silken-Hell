local json=require 'json'
local M={world=1,level=1,history={},future={},dirty={},drafts={},applied={version=1,levels={}}}
local function read(path)
    local f=io.open(path,'rb'); if not f then return end
    local s=f:read('*a'); f:close(); return s
end
local function atomic(path,text)
    local tmp=path..'.new'; local f,err=io.open(tmp,'wb'); if not f then return nil,err end
    local ok,why=f:write(text); f:close(); if not ok then os.remove(tmp); return nil,why end
    local result,msg=os.rename(tmp,path); if not result then os.remove(tmp) end
    return result,msg
end
function M.clone(t) return json.decode(json.encode(t)) end
function M.key() return M.workshop and require('workshop_maps').key(M.world) or M.world..':'..M.level end
function M.init(project,save,workshopBiome)
    M.project=project; M.save=save;M.workshop=workshopBiome~=nil
    M.filename=M.workshop and require('workshop_maps').file or 'custom_levels.json'
    M.applied={version=1,levels={}}
    M.defaults=json.decode(assert(love.filesystem.read('default_levels.json')))
    local raw=read(save..'/'..M.filename)
    if raw then local ok,t=pcall(json.decode,raw); if ok and t.version==1 then M.applied=t end end
    local draft=love.filesystem.read('drafts.json')
    if draft then local ok,t=pcall(json.decode,draft); if ok then M.drafts=t end end
    M.select(workshopBiome or 1,1)
end
function M.select(world,level)
    M.world=world; M.level=M.workshop and 1 or level; M.history={}; M.future={}; M.selected=nil
    local key=M.key()
    M.layout=require('layout_schema').splitAbyss(require('layout_schema').migrate(M.clone(M.drafts[key] or M.applied.levels[key] or (M.workshop and require('workshop_maps').blank(world) or assert(M.defaults.levels[key])))))
end
function M.persist()
    M.drafts[M.key()]=M.clone(M.layout); M.dirty[M.key()]=true
    love.filesystem.write(M.draftFilename or 'drafts.json',json.encode(M.drafts))
end
function M.checkpoint()
    M.history[#M.history+1]=M.clone(M.layout); if #M.history>60 then table.remove(M.history,1) end
    M.future={}
end
function M.undo(redo)
    local src,dst=redo and M.future or M.history,redo and M.history or M.future
    if #src==0 then return end
    dst[#dst+1]=M.clone(M.layout); M.layout=table.remove(src); M.selected=nil; M.persist()
end
function M.add(template,x,y)
    M.checkpoint(); local e=M.clone(template); e.name=nil; e.art=nil; e.world=nil
    e.x=x; e.y=y; e.id=tostring(love.timer.getTime())..'-'..tostring(#M.layout.entities+1)
    if e.kind=='spawn' then for i=#M.layout.entities,1,-1 do if M.layout.entities[i].kind=='spawn' then table.remove(M.layout.entities,i) end end end
    M.layout.entities[#M.layout.entities+1]=e; M.selected=e; M.persist(); return e
end
function M.rotate()
    if not M.selected or M.selected.kind~='wall' then return end
    M.checkpoint()
    local quarter=math.floor((M.selected.rotation or 0)/90+.5)
    M.selected.rotation=((quarter+1)%2)*90;M.persist()
end
function M.delete()
    if not M.selected then return end
    M.checkpoint(); for i,e in ipairs(M.layout.entities) do if e==M.selected then table.remove(M.layout.entities,i); break end end
    M.selected=nil; M.persist()
end
function M.validate(l) return require('layout_schema').validate(l) end
function M.apply()
    local ok,why=M.validate(M.layout); if not ok then return false,why end
    local old=read(M.save..'/'..M.filename)
    local applied={version=1,levels={}}
    if old then local valid,data=pcall(json.decode,old); if not valid or type(data.levels)~='table' then return false,'Le fichier de niveaux existant est invalide.' end; applied=data end
    applied.levels[M.key()]=M.clone(M.layout)
    if old then
        local backup=M.save..'/'..M.filename..'.backup-'..os.date('%Y%m%d-%H%M%S')..'-'..math.floor(love.timer.getTime()*1000)..'.json'
        local saved,err=atomic(backup,old); if not saved then return false,err end
    end
    local text=json.encode(applied)
    local saved,err=atomic(M.save..'/'..M.filename,text); if not saved then return false,err end
    M.applied=applied; M.dirty[M.key()]=nil
    if M.workshop then return true,'Carte enregistrée.' end
    local exported=atomic(M.project..'/custom_levels.json',text)
    return true,exported and 'Appliqué au jeu. Recharge ce niveau pour voir les changements.' or 'Appliqué au jeu ; export dans le projet indisponible.'
end
function M.restore()
    M.checkpoint(); M.layout=require('layout_schema').splitAbyss(M.clone(M.workshop and require('workshop_maps').blank(M.world) or M.defaults.levels[M.key()])); M.selected=nil; M.persist()
end
return M
