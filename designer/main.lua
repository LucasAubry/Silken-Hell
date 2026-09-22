local g=love.graphics
local M,C,json,Worlds,Art,Biome
local state={all=true,world=1,level=1,category='Mobs',tool=nil,grid=true,snap=true,scroll=0,buttons={},status='Choisis un objet à gauche, puis clique sur le terrain.',clock=0}
local color={bg={.018,.025,.035},panel={.035,.055,.069},line={.30,.27,.18},text={.92,.90,.82},muted={.58,.62,.62},accent={.89,.75,.46}}
local function q(s) return "'"..s:gsub("'","'\\''").."'" end
local function text(s,x,y,size,c,w)
    g.setFont(state.fonts[size or 14]); g.setColor(c or color.text)
    if w then g.printf(tostring(s),x,y,w) else g.print(tostring(s),x,y) end
end
local function button(label,x,y,w,h,fn,active)
    local mx,my=love.mouse.getPosition(); local hover=mx>=x and mx<=x+w and my>=y and my<=y+h
    g.setColor(active and {.13,.32,.29} or hover and {.13,.17,.21} or {.085,.11,.14}); g.rectangle('fill',x,y,w,h,6)
    g.setColor(active and color.accent or color.line); g.rectangle('line',x,y,w,h,6)
    text(label,x+12,y+(h-18)/2,14,active and color.accent or color.text)
    state.buttons[#state.buttons+1]={x=x,y=y,w=w,h=h,fn=fn}
end
local function catalog(e)
    for _,c in ipairs(C) do if c.kind==e.kind and c.type==e.type then if e.customName then local copy={};for k,v in pairs(c) do copy[k]=v end;copy.name=e.customName;return copy end;return c end end
    return {name=e.customName or e.type or e.kind}
end
local function backdrop()
    if state.background then state.background:release() end
    state.background=g.newCanvas(M.layout.width,600)
    g.push('all'); g.setCanvas(state.background); g.origin(); g.clear(.25,.35,.45)
    if M.world==6 then
        if state.sky then g.setColor(1,1,1); g.draw(state.sky,0,0,0,M.layout.width/state.sky:getWidth(),600/state.sky:getHeight())
        else for i=1,140 do g.setColor(.8,.87,.94,.5); g.ellipse('fill',(i*137)%M.layout.width,(i*89)%600,55,33) end end
    else Biome.draw(M.world,M.layout.width,600,0) end
    g.setCanvas(); g.pop()
end
local function select(w,n)
    M.select(w,n); state.tool=nil; state.input=nil; state.scroll=0; backdrop()
end
local function bounds()
    local w,h=g.getDimensions(); local avail=w-530
    local scale=math.min(avail/M.layout.width,(h-270)/600)
    local x=270+(avail-M.layout.width*scale)/2; local y=190+(h-250-600*scale)/2
    return x,y,scale
end
local function point(mx,my)
    local x,y,s=bounds(); return (mx-x)/s,(my-y)/s
end
local function inside(mx,my)
    local x,y=point(mx,my); return x>=0 and x<=M.layout.width and y>=0 and y<=600
end
local function snapped(v) return state.snap and math.floor(v/10+.5)*10 or math.floor(v+.5) end
local function entity(e,ghost)
    local c=catalog(e); g.setColor(1,1,1,ghost and .45 or 1)
    if e.type=='larva' then Art.drawLarva(e.x,e.y,22,0,state.clock);return end
    if e.kind=='wall' then g.setColor(.29,.31,.33,ghost and .5 or 1); g.rectangle('fill',e.x-e.w/2,e.y-e.h/2,e.w,e.h); g.setColor(.65,.64,.56); g.rectangle('line',e.x-e.w/2,e.y-e.h/2,e.w,e.h)
    elseif e.kind=='hole' then g.setColor(.025,.04,.08); g.ellipse('fill',e.x,e.y,e.rx,e.ry); g.setColor(.5,.65,.8); g.ellipse('line',e.x,e.y,e.rx,e.ry)
    elseif e.kind=='rain' then g.setColor(.25,.6,1,.8); for i=-1,1 do g.line(e.x+i*8,e.y-18,e.x+i*8-5,e.y+7) end
    elseif e.kind=='current' then g.setColor(.2,.85,1,.2); g.ellipse('fill',e.x,e.y,e.rx,e.ry); text(e.dx==1 and '>' or '<',e.x-6,e.y-9,18)
    elseif c.art and Art.images[c.art] then
        local size=e.kind=='boss' and (e.type=='octopus' and 360 or (e.type=='skeleton_fish' or e.type=='skeleton_head') and 170 or 105) or e.kind=='spawn' and 55 or (e.kind=='tear' or e.kind=='light') and 44 or e.kind=='lava' and e.rx*2 or e.kind=='tunnel' and 95 or 60
        if e.kind=='tear' or e.kind=='light' then g.setColor(Worlds.color(M.world).tear) end
        if e.type=='gull' and e.electric then g.setColor(1,.88,.15) end
        if e.kind=='tear' or e.kind=='light' then Art.drawTinted(c.art,e.x,e.y,size)
        elseif e.kind=='abyss_part' then Art.draw(c.art,e.x,e.y,e.w,(e.rotation or 0)*math.pi/180,e.h)
        elseif e.type=='skeleton_head' then Art.draw(c.art,e.x,e.y,170,0,150)
        elseif e.type=='skeleton_fish' then
            local width=M.layout.width; local span=width*.48; local count=math.max(3,math.floor(span/205)+1)
            for i=1,((e.skeletonStage or 10)>=9 and count or 0) do
                local xx=e.x-width*.3+(i-1)*span/(count-1); local hh=95+18*math.sin(i/count*math.pi)
                Art.draw('skeleton_spine',xx,e.y,22,0,28)
                Art.draw('skeleton_rib',xx,e.y-hh/2-20,22,-.12,hh)
                Art.draw('skeleton_rib',xx,e.y+hh/2+20,22,math.pi+.12,hh)
            end
            Art.draw('skeleton_tail',e.x-width*.405,e.y,100,0,145)
            if (e.skeletonStage or 10)==10 then Art.draw('skeleton_head',e.x+width*.29,e.y,170,0,150) end
        else Art.draw(c.art,e.x,e.y,size) end
    end
    if e.kind=='spawn' then g.setColor(.3,1,.7,.75); g.circle('line',e.x,e.y,32) end
    if e.has_larme then g.setColor(Worlds.color(M.world).tear); g.circle('fill',e.x+21,e.y+20,6) end
    if e==M.selected then
        g.setColor(color.accent); g.setLineWidth(2)
        local w,h=e.w and e.w+8 or e.type=='skeleton_head' and 178 or 70,e.h and e.h+8 or e.type=='skeleton_head' and 158 or 70
        g.rectangle('line',e.x-w/2,e.y-h/2,w,h,4); g.setLineWidth(1)
    end
end
local function apply()
    local ok,msg=M.apply(); state.status=msg; state.error=not ok; return ok
end
local function preview()
    if not apply() then return end
    local request=json.encode({ticket=tostring(os.time())..'-'..tostring(love.timer.getTime()),layout=M.layout})
    local f=assert(io.open(M.save..'/preview-request.json.new','wb')); f:write(request); f:close()
    os.rename(M.save..'/preview-request.json.new',M.save..'/preview-request.json')
    local h=io.open(M.save..'/preview-heartbeat.txt','rb'); local heartbeat=h and tonumber(h:read('*a')) or 0; if h then h:close() end
    if heartbeat and os.time()-heartbeat<5 then state.status='Niveau rechargé dans la fenêtre de test.'; return end
    if state.launching and love.timer.getTime()-state.launching<25 then state.status='Le jeu démarre ; le dernier niveau sélectionné sera chargé.'; return end
    state.launching=love.timer.getTime()
    local runtime=os.getenv('HOME')..'/Library/Application Support/Silken Hell/runtime/love.app/Contents/MacOS/love'
    local archive=os.getenv('HOME')..'/Library/Application Support/Silken Hell/Silken Hell.love'
    local cmd='SILKEN_PREVIEW_WORLD='..M.world..' SILKEN_PREVIEW_LEVEL='..M.level..' '..q(runtime)..' '..q(archive)..' > '..q(os.getenv('HOME')..'/Library/Application Support/Silken Hell/preview.log')..' 2>&1 &'
    os.execute(cmd); state.status='Test lancé — cette fenêtre sera réutilisée au prochain test.'
end
local function loadArt()
    local paths={original='texture/spider_down.png',tear_ring='texture/aureole.png',catalog_ange='texture/mob/ange_down.png',catalog_snake='texture/mob/snake_down.png',catalog_trap='texture/mob/piege.png'}
    for _,c in ipairs(C) do if c.art and not Art.images[c.art] then
        local path=paths[c.art] or 'assets/sprites/'..c.art..'.png'
        if not love.filesystem.getInfo(path) then path='assets/sprites/directional/'..c.art..'.png' end
        Art.add(c.art,path)
    end end
    for _,key in ipairs({'skeleton_spine','skeleton_rib','skeleton_tail'}) do Art.add(key,'assets/sprites/'..key..'.png') end
    if love.filesystem.getInfo('sky_floor.png') then state.sky=g.newImage('sky_floor.png') end
end
function love.load()
    local project=os.getenv('SILKEN_PROJECT') or love.filesystem.getSource():match('^(.*)/designer/?$')
    assert(project,'Dossier du projet introuvable')
    local archive=os.getenv('SILKEN_ASSET_ARCHIVE') or os.getenv('HOME')..'/Library/Application Support/Silken Hell/Silken Hell.love'
    local f=assert(io.open(archive,'rb'),'Archive du jeu introuvable'); local bytes=f:read('*a'); f:close()
    state.assetData=love.filesystem.newFileData(bytes,'silken-assets.zip')
    assert(love.filesystem.mount(state.assetData,'',true),'Impossible de charger les ressources du jeu')
    json=require 'json'; Worlds=require 'worlds'; Art=require 'art'; Biome=require 'biome_floor'
    C=require 'catalog'; M=require 'model'; state.fonts={}
    for _,size in ipairs({12,14,16,18,22,28}) do state.fonts[size]=g.newFont(size) end
    loadArt()
    local save=os.getenv('HOME')..'/Library/Application Support/LOVE/'..(os.getenv('SILKEN_DESIGNER_TEST')=='1' and 'silken-hell-tests' or 'silken-hell')
    M.init(project,save); backdrop()
    local ok,templates=pcall(json.decode,love.filesystem.read('creature-templates.json') or '[]')
    if ok and type(templates)=='table' then for _,t in ipairs(templates) do if t.kind=='mob' or t.kind=='boss' then C[#C+1]=t end end end
    state.templates=ok and type(templates)=='table' and templates or {}
    state.editorSound=love.audio.newSource('music et song/song/editeur start.mp3','static');state.editorSound:setVolume(.65);state.editorSound:play()
    if os.getenv('SILKEN_DESIGNER_TEST')=='1' then require('selftest').run(M,state,select,apply,preview) end
end
function love.draw()
    if not M then return end
    state.buttons={}; local w,h=g.getDimensions(); g.clear(color.bg)
    g.setColor(color.panel); g.rectangle('fill',0,0,w,66); g.rectangle('fill',0,158,250,h-158); g.rectangle('fill',w-245,158,245,h-158)
    text('SILKEN HELL',24,17,22); text('CONCEPTEUR DE NIVEAUX',204,24,12,color.muted)
    button('Appliquer',w-266,14,124,38,apply,true); button('Tester',w-128,14,108,38,preview)
    for i,id in ipairs(Worlds.order) do button(Worlds.names[id],22+(i-1)*140,80,130,34,function() select(id,math.min(M.level,Worlds.levelCount(id))) end,M.world==id) end
    text('NIVEAU',24,129,12,color.muted)
    for n=1,Worlds.levelCount(M.world) do button(string.format('%02d',n),95+(n-1)*51,120,44,30,function() select(M.world,n) end,M.level==n) end
    button('Annuler',w-494,120,94,30,function() M.undo(false) end)
    button('Rétablir',w-390,120,94,30,function() M.undo(true) end)
    button(state.grid and 'Grille : oui' or 'Grille : non',w-286,120,124,30,function() state.grid=not state.grid end)
    button(state.snap and 'Aimant : oui' or 'Aimant : non',w-152,120,132,30,function() state.snap=not state.snap end)
    text('BIBLIOTHÈQUE',20,177,12,color.muted)
    for i,cat in ipairs({'Mobs','Pièges','Terrain','Boss'}) do button(cat,14+(i-1)%2*114,203+math.floor((i-1)/2)*36,106,30,function() state.category=cat; state.scroll=0 end,state.category==cat) end
    button(state.all and 'Tous les biomes' or 'Ce biome',14,280,220,30,function() state.all=not state.all; state.scroll=0 end,state.all)
    local palette={}
    for _,c in ipairs(C) do
        local cat=c.kind=='boss' and 'Boss' or c.kind=='mob' and (c.type=='piege' or c.type=='scie') and 'Pièges' or c.kind=='mob' and 'Mobs' or (c.kind=='magma_spawner' or c.kind=='lava' or c.kind=='vent' or c.kind=='hole' or c.kind=='tornado') and 'Pièges' or 'Terrain'
        if cat==state.category and (state.all or c.world==0 or c.world==M.world) then palette[#palette+1]=c end
    end
    local max=math.max(1,math.floor((h-386)/68)); state.scroll=math.min(state.scroll,math.max(0,#palette-max))
    for i=1,max do local c=palette[i+state.scroll]; if c then
        local y=324+(i-1)*68
        button('',14,y,220,60,function() state.tool=c; M.selected=nil; state.input=nil end,state.tool==c)
        if c.type=='larva' then Art.drawLarva(45,y+29,22,0,state.clock) elseif c.art then g.setColor(1,1,1); local a=Art.images[c.art]; local width=math.min(42,44*a.w/a.h); Art.draw(c.art,45,y+29,width) end
        text(c.name,77,y+8,12,nil,145); text(c.kind=='boss' and 'Rencontre' or c.kind=='mob' and 'Créature' or 'Placement',77,y+36,12,color.muted)
    end end
    text('Molette : parcourir la liste',20,h-54,12,color.muted)
    local x,y,scale=bounds(); state.canvas={x=x,y=y,s=scale}
    text(Worlds.names[M.world]..' / '..string.format('%02d',M.level),270,174,18)
    text(#M.layout.entities..' objets  ·  '..(M.dirty[M.key()] and 'Brouillon' or 'Version enregistrée'),w-575,178,12,color.muted)
    g.push('all'); g.setScissor(x,y,M.layout.width*scale,600*scale); g.translate(x,y); g.scale(scale)
    g.setColor(1,1,1); g.draw(state.background)
    if state.grid then g.setColor(1,1,1,.09); for xx=0,M.layout.width,40 do g.line(xx,0,xx,600) end; for yy=0,600,40 do g.line(0,yy,M.layout.width,yy) end end
    for _,e in ipairs(M.layout.entities) do if e.kind~='mob' and e.kind~='boss' and e.kind~='spawn' then entity(e) end end
    for _,e in ipairs(M.layout.entities) do if e.kind=='mob' or e.kind=='boss' or e.kind=='spawn' then entity(e) end end
    if state.tool then local mx,my=love.mouse.getPosition(); local px,py=point(mx,my)
        if inside(mx,my) then local ghost=M.clone(state.tool); ghost.x=snapped(px); ghost.y=snapped(py); entity(ghost,true) end
    end
    g.pop()
    g.setColor(color.line); g.rectangle('line',x,y,M.layout.width*scale,600*scale)
    local right=w-227; text('PROPRIÉTÉS',right,180,12,color.muted)
    local e=M.selected
    if e then
        text(catalog(e).name,right,208,18,nil,210)
        if e.kind=='mob' or e.kind=='boss' then
            button('Créer '..(e.kind=='boss' and 'ce boss' or 'ce monstre'),right,232,207,28,function() state.input='templateName';state.inputText=e.customName or catalog(e).name;love.keyboard.setTextInput(true) end)
        end
        local defaults=e.kind=='boss' and {movementRate=1,attackRate=1} or e.kind=='magma_spawner' and {spawnDelay=1,spawnInterval=3} or {}
        local row=0
        for _,f in ipairs({'x','y','w','h','rx','ry','speed','phase','dx','rota','radius','spawnDelay','spawnInterval','movementRate','attackRate','rotation'}) do if e[f]~=nil or defaults[f]~=nil then
            local value=e[f] or defaults[f]
            local yy=272+row*39; text(({rotation='Angle (°)',movementRate='Dépl. ×',attackRate='Attaques ×',spawnDelay='Début (s)',spawnInterval='Intervalle (s)',speed='Vitesse',radius='Rayon',phase='Phase',w='Largeur',h='Hauteur'})[f] or f:upper(),right,yy+8,12,color.muted)
            local label=state.input==f and state.inputText..'|' or tostring(math.floor(value*100+.5)/100)
            button(label,right+88,yy,117,34,function() state.input=f; state.inputText=tostring(value); love.keyboard.setTextInput(true) end,state.input==f)
            row=row+1
        end end
        local yy=280+row*39
        if e.kind=='mob' and e.type~='piege' and e.type~='scie' then
            button(e.has_larme and 'Porte une larme : oui' or 'Porte une larme : non',right,yy,207,32,function() M.checkpoint(); e.has_larme=not e.has_larme; M.persist() end,e.has_larme); yy=yy+42
        end
        if e.type=='mole' or e.type=='worm' then button(e.startUnderground and 'Départ : sous terre' or 'Départ : en surface',right,yy,207,32,function() M.checkpoint();e.startUnderground=not e.startUnderground;M.persist() end,e.startUnderground);yy=yy+42 end
        if e.type=='gull' then button(e.electric and 'Électrique : oui' or 'Électrique : non',right,yy,207,32,function() M.checkpoint(); e.electric=not e.electric; M.persist() end,e.electric); yy=yy+42 end
        button('Dupliquer',right,yy,99,34,function() local t=M.clone(e); M.add(t,math.min(M.layout.width-40,e.x+30),math.min(560,e.y+30)) end)
        button('Supprimer',right+108,yy,99,34,M.delete)
    else
        text(state.tool and state.tool.name or 'Aucun objet sélectionné',right,212,18,nil,208)
        text('Clique sur le terrain pour placer.\n\nÉchap : sélectionner et déplacer.\n\nGlisse un objet pour le déplacer.\n\nSuppr : effacer.\nCmd+Z / Cmd+Maj+Z : annuler / rétablir.',right,270,14,color.muted,205)
    end
    button('Restaurer l’original',right,h-110,207,34,function() M.restore(); state.status='Original restauré en brouillon. Appliquer pour le garder.' end)
    text('Les niveaux personnalisés ne sont pas classés.',right,h-66,12,color.muted,210)
    g.setColor(.025,.034,.047); g.rectangle('fill',0,h-30,w,30)
    text(state.status,18,h-23,12,state.error and {1,.46,.4} or color.muted,w-30)
    if state.input=='templateName' then
        g.setColor(0,0,0,.7);g.rectangle('fill',0,0,w,h)
        g.setColor(color.panel);g.rectangle('fill',w/2-260,h/2-110,520,220,8)
        g.setColor(color.accent);g.rectangle('line',w/2-260,h/2-110,520,220,8)
        text('NOM DE LA CRÉATION',w/2-230,h/2-80,22,color.accent)
        text(state.inputText..'|',w/2-230,h/2-20,18,color.text,460)
        text('Entrée : enregistrer · Échap : annuler',w/2-230,h/2+65,14,color.muted,460)
    end
end
function love.mousepressed(mx,my,button)
    for _,b in ipairs(state.buttons) do if mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h then if button==1 then b.fn() end; return end end
    if not inside(mx,my) then return end
    state.input=nil; love.keyboard.setTextInput(false)
    local x,y=point(mx,my)
    if button==2 then state.tool=nil end
    if state.tool and button==1 then M.add(state.tool,snapped(x),snapped(y)); return end
    M.selected=nil
    for i=#M.layout.entities,1,-1 do local e=M.layout.entities[i]
        local rx,ry=e.kind=='wall' and e.w/2 or 26,e.kind=='wall' and e.h/2 or 26
        local ex=e.type=='skeleton_fish' and e.x+M.layout.width*.32 or e.x
        local dx,dy=x-ex,y-e.y
        if e.kind=='abyss_part' then
            local a=(e.rotation or 0)*math.pi/180
            dx,dy=math.cos(a)*dx+math.sin(a)*dy,-math.sin(a)*dx+math.cos(a)*dy
            rx,ry=math.max(12,e.w/2),math.max(12,e.h/2)
        elseif e.type=='skeleton_head' then rx,ry=85,75 end
        if math.abs(dx)<=rx and math.abs(dy)<=ry then M.selected=e; M.checkpoint(); state.drag={dx=x-e.x,dy=y-e.y}; break end
    end
end
function love.mousemoved(mx,my)
    if state.drag and M.selected then local x,y=point(mx,my)
        M.selected.x=math.max(25,math.min(M.layout.width-25,snapped(x-state.drag.dx)))
        M.selected.y=math.max(25,math.min(575,snapped(y-state.drag.dy)))
    end
end
function love.mousereleased() if state.drag then M.persist(); state.drag=nil end end
function love.wheelmoved(x,y) if love.mouse.getX()<250 then state.scroll=math.max(0,state.scroll-y) end end
function love.textinput(s) if state.input then if state.input=='templateName' then state.inputText=(state.inputText..s:gsub('[%c]','')):sub(1,60) else state.inputText=state.inputText..s:gsub('[^%d%.%-]','') end end end
function love.keypressed(key)
    if state.input then
        if key=='backspace' then state.inputText=state.inputText:sub(1,-2)
        elseif key=='return' or key=='kpenter' then
            if state.input=='templateName' and M.selected then
                local name=state.inputText:match('^%s*(.-)%s*$')
                if name~='' then
                    M.checkpoint();M.selected.customName=name;M.persist()
                    local t=M.clone(M.selected);local base=catalog(M.selected);t.id=nil;t.x=nil;t.y=nil;t.art=base.art;t.name=name;t.world=M.world
                    C[#C+1]=t;state.templates[#state.templates+1]=t
                    love.filesystem.write('creature-templates.json',json.encode(state.templates));state.status='Création enregistrée dans la bibliothèque : '..name
                end
            end
            local v=tonumber(state.inputText)
            if v and M.selected then M.checkpoint(); M.selected[state.input]=v; M.persist() end
            state.input=nil; love.keyboard.setTextInput(false)
        elseif key=='escape' then state.input=nil; love.keyboard.setTextInput(false) end
        return
    end
    local cmd=love.keyboard.isDown('lgui','rgui','lctrl','rctrl')
    if key=='escape' then state.tool=nil; M.selected=nil
    elseif key=='delete' or key=='backspace' then M.delete()
    elseif key=='z' and cmd then M.undo(love.keyboard.isDown('lshift','rshift'))
    elseif key=='s' and cmd then apply()
    elseif M.selected then
        local step=state.snap and 10 or 1
        local dx=key=='left' and -step or key=='right' and step or 0
        local dy=key=='up' and -step or key=='down' and step or 0
        if dx~=0 or dy~=0 then M.checkpoint(); M.selected.x=M.selected.x+dx; M.selected.y=M.selected.y+dy; M.persist() end
    end
end
function love.update(dt) state.clock=state.clock+dt; if state.testUpdate then state.testUpdate() end end
function love.errorhandler(message) io.stderr:write(tostring(message)..'\n'..debug.traceback()..'\n'); return function() return 1 end end
