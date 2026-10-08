local P=require('creator_projects')
local V={page=1,biome=1,kind='blank',sourcePage=1}
local M,S,text,button,backdrop
local function q(s)return "'"..s:gsub("'","'\\''").."'"end
function V.init(model,state,drawText,drawButton,background)
 M,S,text,button,backdrop=model,state,drawText,drawButton,background
 V.biome=M.world;V.page=1;V.view='home'
 local add=M.add
 M.add=function(template,...)
  local result=add(template,...)
  if M.workshop then S.status=require('workshop_access').warning(template,M.world) or '' end
  return result
 end
 local ok,err=P.importLegacy(M.save,M.drafts);if not ok then S.status=err end;V.library=P.list(M.save)
end
local function resetTools() S.tool=nil;S.drag=nil;S.input=nil;V.input=nil;love.keyboard.setTextInput(false) end
function V.home()
 local ok,err=M.home();if not ok then S.status=err;return end
 resetTools();V.view='home';V.publication=false;V.page=1;S.status='';V.library=P.list(M.save)
end
function V.open(p)
 M.openProject(p);resetTools();V.view='edit';S.status='';backdrop()
end
function V.create(source,count)
 local p,err=P.new(M.save,V.biome,source,count)
 if not p then S.status=err;return end
 V.open(p)
end
function V.field(owner,key,max)
 V.input={owner=owner,key=key,max=max or 60,replace=true};love.keyboard.setTextInput(true)
end
function V.text(s)
 if not V.input then return false end
 local i=V.input;s=s:gsub('[%c]','');if i.key=='difficultyExtra' then s=s:gsub('[^%d]','') end
 local value=(i.replace and '' or tostring(i.owner[i.key] or ''))..s
 if (require('utf8').len(value) or 999)<=i.max then i.owner[i.key]=i.key=='difficultyExtra' and (tonumber(value) or 0) or value;i.replace=false;M.persist() end
 return true
end
function V.key(key)
 if V.input then
  if key=='backspace' then local i=V.input;local value=tostring(i.owner[i.key] or '');local at=require('utf8').offset(value,-1);value=at and value:sub(1,at-1) or '';i.owner[i.key]=i.key=='difficultyExtra' and (tonumber(value) or 0) or value;i.replace=false;M.persist()
  elseif key=='return' or key=='kpenter' or key=='escape' then V.input=nil;love.keyboard.setTextInput(false) end
  return true
 end
 if V.publication then if key=='escape' then V.publication=false end;return true end
 if not M.currentProject and not M.devMode then if key=='escape' then V.view='home' end;return true end
 return false
end
function V.openPublish()
 resetTools();V.publication=true;V.status='';V.ticket=nil
 local e=M.currentProject.entries[M.currentProject.current]
 if e.author=='' then local f=require('platform').open(M.save..'/profile.txt','rb');local raw=f and f:read('*a') or '';if f then f:close()end;e.author=('\n'..raw):match('\nname=([^\n]*)') or '' end
 V.validated=P.proof(M.save,M.currentProject,M.currentProject.current)
end
function V.request(action)
 local p=M.currentProject;local e=p.entries[p.current]
 local ok,err=M.persist();if not ok then V.status=err;return end
 local valid,why=require('layout_schema').validate(P.layout(p,p.current));if not valid then V.status=why;return end
 if action=='publish' and (e.name:match('^%s*$') or e.author:match('^%s*$')) then V.status='Renseigne le nom et le pseudo.';return end
 local ticket=p.id..'-'..math.floor(love.timer.getTime()*1000000)
 ok,err=P.write(M.save,'creator-request.json',{ticket=ticket,projectId=p.id,slot=p.current,action=action,hash=require('replay').hash(P.layout(p,p.current))})
 if not ok then V.status=err;return end
 V.ticket=ticket;V.status=action=='validate' and 'Validation en cours…' or 'Publication en cours…'
 local heartbeat=P.read(M.save,'creator-heartbeat.json')
 if not heartbeat or os.time()-(heartbeat.time or 0)>5 then
  if not V.launching or love.timer.getTime()-V.launching>25 then
   local started=require('platform').launch('--creator-bridge',M.launchTarget)
   if not started then V.status='Impossible de lancer le jeu.' else V.launching=love.timer.getTime() end
  end
 end
end
function V.update(dt)
 V.clock=(V.clock or 0)+dt;if V.clock<.5 then return end;V.clock=0
 if not M.currentProject then V.library=P.list(M.save) end
 if S.previewTicket then local response=P.read(M.save,'preview-response.json');if response and response.ticket==S.previewTicket then S.status=response.message;S.previewTicket=nil end end
 if V.ticket then local status=P.read(M.save,'creator-response.json');if status and status.ticket==V.ticket then V.status=status.message end end
 if V.publication and M.currentProject then V.validated=P.proof(M.save,M.currentProject,M.currentProject.current) end
 if M.saveError then S.status='Sauvegarde impossible : '..tostring(M.saveError) end
end
function V.homeDraw()
 if M.currentProject or M.devMode then return false end
 local g=love.graphics;local w,h=g.getDimensions();local left=math.max(30,(w-1020)/2)
 text('CRÉATION DE NIVEAUX',left,45,28)
 if V.view=='home' then
  button('Créer une carte',left,110,310,52,function()V.view='new';V.kind='blank';V.sourcePage=1;S.status=''end,true)
  button('Créer depuis une carte',left+335,110,310,52,function()V.view='new';V.kind='copy';V.sourcePage=1;S.status=''end)
  button('Niveaux dev',left+670,110,320,52,function()local ok,err=M.openDev();if ok then resetTools();V.view='edit';backdrop()else S.status=err end end)
  local list=V.library or {};text('PROJETS EN COURS',left,200,22)
  for i=1,6 do local p=list[(V.page-1)*6+i];if p then
   button(p.name,left,245+(i-1)*59,780,48,function()V.open(p)end)
   text(#p.entries==1 and '1 carte' or (#p.entries..' niveaux'),left+805,259+(i-1)*59,16)
  end end
  if #list==0 then text('Aucun projet enregistré.',left,260,18) end
  button('Précédent',left,h-85,200,42,function()V.page=math.max(1,V.page-1)end)
  text(tostring(V.page),left+480,h-73,18)
  button('Suivant',left+790,h-85,200,42,function()if V.page*6<#list then V.page=V.page+1 end end)
 else
  button('Carte vide',left,105,300,46,function()V.kind='blank'end,V.kind=='blank')
  button('Depuis une carte',left+330,105,300,46,function()V.kind='copy'end,V.kind=='copy')
  button('10 niveaux vides',left+660,105,330,46,function()V.kind='world'end,V.kind=='world')
  for i,b in ipairs(require('worlds').order) do button(require('worlds').names[b],left+(i-1)*142,177,132,42,function()V.biome=b;V.sourcePage=1 end,V.biome==b)end
  text(require('workshop_access').biomeNotice,left,226,16,nil,990)
  if V.kind=='copy' then
   local sources={}
   for _,p in ipairs(V.library or {}) do for i,e in ipairs(p.entries) do if (e.layout.biome or e.layout.world)==V.biome then sources[#sources+1]={name=e.name,layout=e.layout} end end end
   for n=1,10 do local layout=M.defaults.levels[V.biome..':'..n];if layout then sources[#sources+1]={name=require('worlds').names[V.biome]..' · '..n,layout=layout}end end
   for i=1,6 do local row=sources[(V.sourcePage-1)*6+i];if row then button(row.name,left,250+(i-1)*57,990,46,function()V.create(row.layout,1)end)end end
   button('Précédent',left,610,200,42,function()V.sourcePage=math.max(1,V.sourcePage-1)end)
   button('Suivant',left+790,610,200,42,function()if V.sourcePage*6<#sources then V.sourcePage=V.sourcePage+1 end end)
  else
   button('Créer',left+300,330,400,60,function()V.create(nil,V.kind=='world' and 10 or 1)end,true)
  end
  button('Retour',left,h-70,200,42,function()V.view='home'end)
 end
 if S.status~='' then text(S.status,left,h-28,16,{1,.55,.4},990)end
 return true
end
function V.header()
 local w=love.graphics.getWidth();local p=M.currentProject
 if M.devMode then
  button('Mes projets',24,14,145,38,V.home);text('NIVEAUX DEV',190,22,22)
  button('Appliquer au jeu',w-420,14,265,38,function()local ok,msg=M.apply();S.status=msg end,true)
  return
 end
 button('Mes projets',24,14,145,38,V.home)
 button(p.name..(V.input and V.input.key=='name' and V.input.owner==p and '|' or ''),184,14,w-920,38,function()V.field(p,'name')end)
 button('Enregistrer',w-706,14,140,38,function()local ok,msg=M.apply();S.status=msg end)
 button('Publier un niveau',w-550,14,190,38,V.openPublish,true)
 if #p.entries>1 then
  for i=1,#p.entries do button(tostring(i),24+(i-1)*58,120,52,30,function()local ok,err=M.selectSlot(i);if ok then resetTools();backdrop()else S.status=err end end,p.current==i)end
 end
end
function V.drawPublication()
 if not V.publication then return end
 local g=love.graphics;local w,h=g.getDimensions();local x,y=(w-650)/2,(h-570)/2
 g.setColor(0,0,0,.85);g.rectangle('fill',0,0,w,h);g.setColor(.035,.065,.10);g.rectangle('fill',x,y,650,570,10)
 S.buttons={};local p=M.currentProject;local e=p.entries[p.current]
 text('PUBLIER UN NIVEAU',x+35,y+26,28)
 button('Nom : '..e.name..(V.input and V.input.owner==e and V.input.key=='name' and '|' or ''),x+35,y+90,580,46,function()V.field(e,'name')end)
 button('Pseudo : '..e.author..(V.input and V.input.key=='author' and '|' or ''),x+35,y+150,580,46,function()V.field(e,'author',24)end)
 text('Difficulté',x+35,y+207,18)
 for i=1,5 do
  local bx=x+35+(i-1)*116
  button('',bx,y+238,108,42,function()e.difficulty=i;e.difficultyExtra=0;M.persist()end,e.difficulty==i)
  require('difficulty_tears').draw(i,bx+54-(i-1)*9,y+257,18,5)
 end
 text(require('workshop_access').biomeNotice,x+35,y+294,16,nil,580)
 local proof=V.validated and V.validated.hash==require('replay').hash(P.layout(p,p.current)) and V.validated
 button(proof and 'Rejouer la validation' or 'Terminer pour valider',x+35,y+334,580,46,function()V.request('validate')end)
 button('Publier',x+35,y+394,580,46,function()if proof then V.request('publish')else V.status='Termine cette version pour la valider.'end end,proof~=nil)
 if V.status and V.status~='' then text(V.status,x+35,y+457,16,{.6,.85,1},580)end
 button('Retour',x+225,y+512,200,38,function()V.publication=false;V.input=nil;love.keyboard.setTextInput(false)end)
end
return V
