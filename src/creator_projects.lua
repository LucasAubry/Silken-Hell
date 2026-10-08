-- Durable creator projects, separate from campaign slots and publication proofs.
local json=require('json')
local P={index='creator-projects.json'}
function P.clone(value) return json.decode(json.encode(value)) end
function P.read(root,name)
 local f=io.open(root..'/'..name,'rb');if not f then return nil end
 local raw=f:read('*a');f:close();local ok,value=pcall(json.decode,raw)
 return ok and value or nil
end
function P.write(root,name,value)
 local path=root..'/'..name;local f,err=io.open(path..'.new','wb');if not f then return nil,err end
 local ok,why=f:write(json.encode(value));f:close();if not ok then return nil,why end
 return os.rename(path..'.new',path)
end
function P.validId(id) return type(id)=='string' and id:match('^[%w%-]+$')~=nil end
function P.load(root,id)
 if not P.validId(id) then return nil,'Projet introuvable.' end
 local p=P.read(root,'creator-project-'..id..'.json')
 if type(p)~='table' or p.id~=id or type(p.entries)~='table' or #p.entries<1 then return nil,'Projet introuvable.' end
 return p
end
function P.list(root)
 local index=P.read(root,P.index) or {};local out={}
 for _,id in ipairs(index) do local p=P.load(root,id);if p and not id:match('^legacy%-[1-7]%-') then out[#out+1]=p end end
 table.sort(out,function(a,b)if a.updated==b.updated then return a.id>b.id end;return (a.updated or 0)>(b.updated or 0) end)
 return out
end
function P.save(root,p)
 if not P.validId(p.id) then return nil,'Projet invalide.' end
 p.updated=os.time()
 local ok,err=P.write(root,'creator-project-'..p.id..'.json',p);if not ok then return nil,err end
 local index=P.read(root,P.index) or {};for _,id in ipairs(index) do if id==p.id then return true end end
 index[#index+1]=p.id;return P.write(root,P.index,index)
end
function P.new(root,biome,source,count)
 local id=tostring(os.time())..'-'..tostring(math.floor(love.timer.getTime()*1000000))..'-'..love.math.random(10000,99999)
 local p={version=1,id=id,name=(count==10 and 'Monde ' or 'Carte ')..require('worlds').names[biome],current=1,entries={}}
 for i=1,(count or 1) do
  local layout=P.clone(source or require('workshop_maps').blank(biome));layout.world=biome;layout.biome=biome;layout.level=1
  layout=require('layout_schema').splitAbyss(require('layout_schema').migrate(layout))
  p.entries[i]={name=p.name..((count or 1)>1 and ' '..i or ''),author='',difficulty=1,difficultyExtra=0,layout=layout}
 end
 local ok,err=P.save(root,p);if not ok then return nil,err end;return p
end
function P.layout(p,slot)
 local e=p.entries[slot];if not e then return nil end
 local l=P.clone(e.layout);l.level=1;l.world=l.biome or l.world;l.biome=l.world
 l.difficulty=e.difficulty or 1;l.difficultyExtra=l.difficulty==5 and (e.difficultyExtra or 0) or 0
 return l
end
function P.proofName(id,slot) return 'creator-proof-'..id..'-'..slot..'.json' end
function P.proof(root,p,slot)
 local proof=P.read(root,P.proofName(p.id,slot));local R=require('replay')
 if proof and proof.hash==R.hash(P.layout(p,slot)) and proof.build==R.build() then return proof end
end
function P.importLegacy(root,drafts)
 local saved=P.read(root,'workshop_maps.json');local entries={}
 for key,l in pairs(saved and saved.levels or {}) do entries[key]=l end
 for key,l in pairs(drafts or {}) do entries[key]=l end
 for key,l in pairs(entries) do
  if key:match('^workshop:') and type(l)=='table' and l.world and type(l.entities)=='table' then
   local id='legacy-'..key:gsub('[^%w%-]','-')
   if not P.load(root,id) then
    local biome=l.biome or l.world
    local names=require('worlds').names
    if names[biome] then
     local layout=P.clone(l);layout.level=1;layout.biome=biome;layout.world=biome
     local name='Carte '..names[biome]..(key:match('^workshop:') and '' or ' · '..tostring(l.level or 1))
     local p={version=1,id=id,name=name,current=1,entries={{name=name,author='',difficulty=l.difficulty or 1,difficultyExtra=l.difficultyExtra or 0,layout=layout}}}
     local ok,err=P.save(root,p);if not ok then return nil,err end
    end
   end
  end
 end
 return true
end
return P
