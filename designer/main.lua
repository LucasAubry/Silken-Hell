local g=love.graphics
local M,C,json,Worlds,Art,Biome,Projects
local state={all=true,world=1,level=1,category='Mobs',tool=nil,brush=28,grid=true,snap=true,scroll=0,buttons={},status='Choisis un objet à gauche, puis clique sur le terrain.',clock=0}
local color={bg={.018,.027,.045},panel={.035,.065,.10},line={.20,.39,.55},text={.87,.94,1},muted={.53,.66,.77},accent={.40,.74,1}}
local function q(s) return "'"..s:gsub("'","'\\''").."'" end
local function text(s,x,y,size,c,w)
    size=M and (M.workshop or M.devMode) and math.max(16,size or 16) or size
    g.setFont(state.fonts[size or 14]); g.setColor(c or color.text)
    if w and M and (M.workshop or M.devMode) then
        s=tostring(s);local f=state.fonts[size];local utf8=require('utf8')
        if f:getWidth(s)>w then repeat local at=utf8.offset(s,-1);s=at and s:sub(1,at-1) or '' until s=='' or f:getWidth(s..'…')<=w;s=s..'…' end
        g.print(s,x,y)
    elseif w then g.printf(tostring(s),x,y,w) else g.print(tostring(s),x,y) end
end
local function button(label,x,y,w,h,fn,active)
    local mx,my=love.mouse.getPosition(); local hover=mx>=x and mx<=x+w and my>=y and my<=y+h
    g.setColor(active and {.13,.32,.29} or hover and {.13,.17,.21} or {.085,.11,.14}); g.rectangle('fill',x,y,w,h,6)
    g.setColor(active and color.accent or color.line); g.rectangle('line',x,y,w,h,6)
    if M and (M.workshop or M.devMode) then
        local f=state.fonts[16];local utf8=require('utf8')
        if f:getWidth(label)>w-24 then repeat local at=utf8.offset(label,-1);label=at and label:sub(1,at-1) or '' until label=='' or f:getWidth(label..'…')<=w-24;label=label..'…' end
    end
    text(label,x+12,y+(h-18)/2,14,active and color.accent or color.text)
    state.buttons[#state.buttons+1]={x=x,y=y,w=w,h=h,fn=fn}
end
local function catalog(e)
    for _,c in ipairs(C) do if c.kind==e.kind and c.type==e.type then if e.customName then local copy={};for k,v in pairs(c) do copy[k]=v end;copy.name=e.customName;return copy end;return c end end
    return {name=e.customName or e.type or e.kind}
end
local function backdrop()
    if state.background then state.background:release() end
    state.background=g.newCanvas(M.layout.width,600,{dpiscale=1})
    g.push('all'); g.setCanvas(state.background); g.origin(); g.clear(.25,.35,.45)
    Biome.draw(M.world,M.layout.width,600,0)
    g.setCanvas(); g.pop()
end
local function select(w,n)
    M.select(w,n); state.tool=nil;state.stroke=nil; state.input=nil; state.scroll=0;state.category=(w==6 or w==2) and 'Terrain' or 'Mobs';state.all=false; backdrop()
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
local function brush(e) return e and (e.kind=='hole' or e.kind=='lava' or e.kind=='electric_ground') end
-- Explicit time also freezes procedural sprites which use the real clock in game.
local function drawArt(key,x,y,width,angle,height)
    Art.draw(key,x,y,width,angle,height,0)
end
local function entity(e,ghost,terrainDrawn)
    local c=catalog(e); g.setColor(1,1,1,ghost and .45 or 1)
    if e.type=='cloud_beast' then require('mobs.cloud_beast').art(e.x,e.y,45,0,0);return end
    if e.type=='cloud_snail' then require('cloud_snail').art(e.x,e.y,45,0,0);return end
    if e.type=='dragonfly' or e.type=='mist_moth' or e.type=='wind_bat' or e.type=='lava_scorpion' then require('sky_insect_art').draw(e.type,e.x,e.y,e.type=='wind_bat' and 48 or 64,0,e.type=='wind_bat' and (e.dx==-1 and math.pi/2 or -math.pi/2) or nil);return end
    if e.kind=='mob' and (e.type=='piege' or e.type=='scie') then require('trap_art').draw(e.type,e.x,e.y,e.type=='scie' and 60 or 52,M.world,false,0);return end
    if e.kind=='wall' and M.world==5 then
        g.push('all');g.translate(e.x,e.y);g.rotate((e.rotation or 0)*math.pi/180)
        require('earth_rocks').wall({x=-e.w/2,y=-e.h/2,w=e.w,h=e.h});g.pop();return
    end
    if e.kind=='wall' then g.push();g.translate(e.x,e.y);g.rotate((e.rotation or 0)*math.pi/180);g.translate(-e.x,-e.y);g.setColor(.29,.31,.33,ghost and .5 or 1); g.rectangle('fill',e.x-e.w/2,e.y-e.h/2,e.w,e.h); g.setColor(.65,.64,.56); g.rectangle('line',e.x-e.w/2,e.y-e.h/2,e.w,e.h);g.pop()
    elseif e.kind=='tornado' then
        require('tornado_art').draw(Art,e.x,e.y,state.clock,94,ghost and .45 or 1)
    elseif e.kind=='lava' and e.points then
        if not terrainDrawn then require('lava_zones').draw(e,state.clock,ghost and .5 or 1,M.world) end
    elseif e.kind=='electric_ground' then
        require('electric_ground').draw({e},state.clock,ghost and .5 or 1)
    elseif e.kind=='hole' then
        if not terrainDrawn then require('terrain_surface').draw({e},'hole',state.clock,ghost and .5 or 1,M.world) end
    elseif e.kind=='rain' then g.setColor(.25,.6,1,.8); for i=-1,1 do g.line(e.x+i*8,e.y-18,e.x+i*8-5,e.y+7) end
    elseif e.kind=='current' then g.setColor(.2,.85,1,.2); g.ellipse('fill',e.x,e.y,e.rx,e.ry); text(e.dx==1 and '>' or '<',e.x-6,e.y-9,18)
    elseif e.type=='larva' then Art.drawWorm('down',e.x,e.y,30,0)
    elseif e.type=='magma_larva' then
        local a=Art.images.magma_larva;local size=38
        drawArt('magma_larva',e.x,e.y,size*a.w/math.max(a.w,a.h),0,size*a.h/math.max(a.w,a.h))
    elseif c.art and Art.images[c.art] then
        local size=e.kind=='boss' and (e.type=='octopus' and 360 or (e.type=='skeleton_fish' or e.type=='skeleton_head') and 170 or 105) or e.kind=='spawn' and 55 or (e.kind=='tear' or e.kind=='light') and 44 or e.kind=='lava' and e.rx*2 or e.kind=='tunnel' and 95 or 60
        if e.kind=='tear' or e.kind=='light' then g.setColor(Worlds.color(M.world).tear) end
        if e.kind=='tear' or e.kind=='light' then Art.drawTinted(c.art,e.x,e.y,size)
        elseif e.kind=='abyss_gate' then drawArt(c.art,e.x,e.y,e.w or 540,0,e.h or (e.w or 540)*1.2)
        elseif e.kind=='abyss_part' then drawArt(c.art,e.x,e.y,e.w,(e.rotation or 0)*math.pi/180,e.h)
        elseif e.type=='skeleton_head' then drawArt(c.art,e.x,e.y,170,0,150)
        elseif e.type=='skeleton_fish' then
            local width=M.layout.width; local span=width*.48; local count=math.max(3,math.floor(span/205)+1)
            for i=1,((e.skeletonStage or 10)>=9 and count or 0) do
                local xx=e.x-width*.3+(i-1)*span/(count-1); local hh=95+18*math.sin(i/count*math.pi)
                drawArt('skeleton_spine',xx,e.y,22,0,28)
                drawArt('skeleton_rib',xx,e.y-hh/2-20,22,-.12,hh)
                drawArt('skeleton_rib',xx,e.y+hh/2+20,22,math.pi+.12,hh)
            end
            drawArt('skeleton_tail',e.x-width*.405,e.y,100,0,145)
            if (e.skeletonStage or 10)==10 then drawArt('skeleton_head',e.x+width*.29,e.y,170,0,150) end
        else drawArt(c.art,e.x,e.y,size) end
    end
    if e.kind=='spawn' then g.setColor(.3,1,.7,.75); g.circle('line',e.x,e.y,32) end
    if e.has_larme then g.setColor(Worlds.color(M.world).tear); g.circle('fill',e.x+21,e.y+20,6) end
    if e==M.selected then
        g.setColor(color.accent); g.setLineWidth(2)
        local w,h=e.w and e.w+8 or e.type=='skeleton_head' and 178 or 70,e.h and e.h+8 or e.type=='skeleton_head' and 158 or 70
        g.push();g.translate(e.x,e.y);g.rotate((e.rotation or 0)*math.pi/180)
        if brush(e) and e.points then
            local x0,y0,x1,y1=require('ground_holes').bounds(e);g.rectangle('line',x0-4,y0-4,x1-x0+8,y1-y0+8,4)
        else g.rectangle('line',-w/2,-h/2,w,h,4) end
        g.pop(); g.setLineWidth(1)
    end
end
local function apply()
    local ok,msg=M.apply(); state.status=msg; state.error=not ok; return ok
end
local function preview()
    local valid,why=M.validate(M.layout);if not valid then state.status=why;state.error=true;return end
    if not apply() then return end
    state.previewTicket=tostring(os.time())..'-'..tostring(love.timer.getTime())
    local request=json.encode({ticket=state.previewTicket,layout=M.layout,workshop=M.workshop==true})
    local f=assert(require('platform').open(M.save..'/preview-request.json.new','wb')); f:write(request); f:close()
    local saved,err=require('platform').replace(M.save..'/preview-request.json.new',M.save..'/preview-request.json')
    if not saved then state.status=err;state.error=true;return end
    local h=require('platform').open(M.save..'/preview-heartbeat.txt','rb'); local heartbeat=h and tonumber(h:read('*a')) or 0; if h then h:close() end
    if heartbeat and os.time()-heartbeat<5 then state.status=M.workshop and 'Carte rechargée.' or 'Niveau rechargé dans la fenêtre de test.'; return end
    if state.launching and love.timer.getTime()-state.launching<25 then state.status=M.workshop and 'Démarrage du test…' or 'Le jeu démarre ; le dernier niveau sélectionné sera chargé.'; return end
    state.launching=love.timer.getTime()
    local ok=require('platform').launch('--preview',M.launchTarget)
    state.status=ok and 'Test lancé.' or 'Impossible de lancer le test.'
    state.error=not ok

end
local function loadArt()
    local paths={original='assets/skins/base_marron/down.png',tear_ring='assets/textures/aureole.png',catalog_ange='assets/monstres/paradis/ange/ange_down.png',catalog_snake='assets/monstres/paradis/serpent/snake_down.png',catalog_trap='assets/monstres/paradis/pieges/piege.png'}
    for _,c in ipairs(C) do if c.art and not Art.images[c.art] then
        local path=paths[c.art] or 'assets/sprites/'..c.art..'.png'
        if not love.filesystem.getInfo(require('asset_paths').resolve(path)) then path='assets/sprites/directional/'..c.art..'.png' end
        Art.add(c.art,path)
    end end
    for _,key in ipairs({'skeleton_spine','skeleton_rib','skeleton_tail'}) do Art.add(key,'assets/sprites/'..key..'.png') end
end
function love.load()
    local source=love.filesystem.getSource():gsub('\\','/')
    local project=os.getenv('SILKEN_PROJECT') or source:match('^(.*)/designer/?$')
    local launchTarget=source
    if not SILKEN_EMBEDDED_EDITOR then
        assert(project,'Dossier du projet introuvable')
        local archive=os.getenv('SILKEN_ASSET_ARCHIVE') or project..'/dist/game.love'
        local f=assert(io.open(archive,'rb'),'Construis le jeu avec python3 tools/package.py avant de lancer cet éditeur.')
        local bytes=f:read('*a');f:close()
        state.assetData=love.filesystem.newFileData(bytes,'silken-assets.zip')
        assert(love.filesystem.mount(state.assetData,'',true),'Impossible de charger les ressources du jeu')
        launchTarget=archive
    end
    love.filesystem.setRequirePath(love.filesystem.getRequirePath()..';src/?.lua;src/?/init.lua')
    require('editor_icon').install()
    json=require 'json'; Worlds=require 'worlds'; Art=require 'art'; Biome=require 'biome_floor'
    C=require 'catalog'; M=require 'model'; state.fonts={}
    for _,size in ipairs({12,14,16,18,22,28}) do state.fonts[size]=g.newFont(size) end
    loadArt()
    local save=require('platform').saveDirectory(os.getenv('SILKEN_DESIGNER_TEST')=='1' and 'silken-hell-tests' or 'silken-hell')
    project=project or (not love.filesystem.isFused() and not source:match('%.love$') and source) or save
    M.init(project,save,tonumber(os.getenv('SILKEN_WORKSHOP_BIOME')));if M.workshop then state.status='' end
    if os.getenv('SILKEN_DESIGNER_TEST')~='1' or os.getenv('SILKEN_CREATOR_PROJECT_TEST')=='1' then
        require('project_model').install(M);Projects=require('project_ui');Projects.init(M,state,text,button,backdrop);state.status=''
    end
    M.launchTarget=launchTarget
    backdrop()
    local ok,templates=pcall(json.decode,love.filesystem.read('creature-templates.json') or '[]')
    if ok and type(templates)=='table' then for _,t in ipairs(templates) do if t.kind=='mob' or t.kind=='boss' then C[#C+1]=t end end end
    state.templates=ok and type(templates)=='table' and templates or {}
    state.editorSound=love.audio.newSource('assets/audio/effects/editeur start.mp3','static');state.editorSound:setVolume(.65);state.editorSound:play()
    if os.getenv('SILKEN_DESIGNER_TEST')=='1' and os.getenv('SILKEN_CELESTIAL_EDITOR_TEST')=='1' then require('celestial_selftest').run(M,state,select);return end
    if os.getenv('SILKEN_DESIGNER_TEST')=='1' and os.getenv('SILKEN_MAP_PREVIEW_TEST')=='1' then require('preview_selftest').run(M,state,select);return end
    if os.getenv('SILKEN_DESIGNER_TEST')=='1' then require(os.getenv('SILKEN_EDITOR_DRAWING_TEST')=='1' and 'drawing_selftest' or os.getenv('SILKEN_GROUND_HOLES_TEST')=='1' and 'holes_selftest' or M.projects and 'project_selftest' or M.workshop and 'workshop_selftest' or 'selftest').run(M,state,select,apply,preview) end
end
function love.draw()
    if not M then return end
    state.buttons={}; local w,h=g.getDimensions(); g.clear(color.bg)
    if Projects and Projects.homeDraw() then return end
    if M.projects and not M.devMode and M.world~=(M.layout.biome or M.layout.world) then M.world=M.layout.biome or M.layout.world;backdrop() end
    g.setColor(color.panel); g.rectangle('fill',0,0,w,66); g.rectangle('fill',0,158,250,h-158); g.rectangle('fill',w-245,158,245,h-158)
    if Projects then Projects.header() else
    text('SILKEN HELL',24,17,22); if M.workshop then text('WORKSHOP',204,20,22) else text('CONCEPTEUR DE NIVEAUX',204,24,12,color.muted) end
    button(M.workshop and 'Enregistrer' or 'Appliquer',w-266,14,124,38,apply,true)
    end
    button('Tester',w-128,14,108,38,preview)
    for i,id in ipairs(Worlds.order) do button(Worlds.names[id],22+(i-1)*140,80,130,34,function() select(id,math.min(M.level,Worlds.levelCount(id))) end,M.world==id) end
    if not M.workshop then
    text('NIVEAU',24,129,12,color.muted)
    for n=1,Worlds.levelCount(M.world) do button(string.format('%02d',n),95+(n-1)*51,120,44,30,function() select(M.world,n) end,M.level==n) end
    end
    button('Annuler',w-494,120,94,30,function() M.undo(false) end)
    button('Rétablir',w-390,120,94,30,function() M.undo(true) end)
    button(state.grid and 'Grille : oui' or 'Grille : non',w-286,120,124,30,function() state.grid=not state.grid end)
    button(state.snap and 'Aimant : oui' or 'Aimant : non',w-152,120,132,30,function() state.snap=not state.snap end)
    if M.world==6 or M.world==2 then
        local kind=M.world==6 and 'hole' or 'lava'
        button(M.world==6 and 'Dessiner les trous' or 'Dessiner la lave',14,166,220,30,function()
            for _,c in ipairs(C) do if c.kind==kind then state.tool=c;M.selected=nil;state.input=nil;state.category='Terrain';state.all=false;state.scroll=0;break end end
        end,state.tool and state.tool.kind==kind)
    else text('BIBLIOTHÈQUE',20,177,12,color.muted) end
    for i,cat in ipairs({'Mobs','Pièges','Terrain','Boss'}) do button(cat,14+(i-1)%2*114,203+math.floor((i-1)/2)*36,106,30,function() state.category=cat; state.scroll=0 end,state.category==cat) end
    button(state.all and 'Tous les biomes' or 'Ce biome',14,280,220,30,function() state.all=not state.all; state.scroll=0 end,state.all)
    local palette={}
    for _,c in ipairs(C) do
        local cat=(c.kind=='boss' or c.kind=='abyss_gate') and 'Boss' or c.kind=='mob' and (c.type=='piege' or c.type=='scie') and 'Pièges' or c.kind=='mob' and 'Mobs' or (c.kind=='magma_spawner'  or c.kind=='vent' or c.kind=='tornado') and 'Pièges' or 'Terrain'
        if cat==state.category and (state.all or c.world==0 or c.world==M.world) then palette[#palette+1]=c end
    end
    local max=math.max(1,math.floor((h-386)/68)); state.scroll=math.min(state.scroll,math.max(0,#palette-max))
    for i=1,max do local c=palette[i+state.scroll]; if c then
        local y=324+(i-1)*68
        button('',14,y,220,60,function() state.tool=c; M.selected=nil; state.input=nil end,state.tool==c)
        if c.type=='cloud_beast' then require('mobs.cloud_beast').art(45,y+29,42,0,0)
        elseif c.type=='cloud_snail' then require('cloud_snail').art(45,y+29,42,0,0)
        elseif c.type=='dragonfly' or c.type=='mist_moth' or c.type=='wind_bat' or c.type=='lava_scorpion' then require('sky_insect_art').draw(c.type,45,y+29,42,0)
        elseif c.type=='larva' then Art.drawLarva(45,y+29,22,0,0) elseif c.art then g.setColor(1,1,1); local a=Art.images[c.art]; local width=math.min(42,44*a.w/a.h); drawArt(c.art,45,y+29,width) end
        local insect=c.type=='cloud_beast' or c.type=='cloud_snail' or c.type=='dragonfly' or c.type=='mist_moth' or c.type=='wind_bat' or c.type=='lava_scorpion';local label=c.name
        if insect then
            local utf8=require('utf8');local font=state.fonts[16]
            if font:getWidth(label)>145 then repeat local at=utf8.offset(label,-1);label=at and label:sub(1,at-1) or '' until label=='' or font:getWidth(label..'…')<=145;label=label..'…' end
        end
        text(label,77,y+((insect or M.workshop or M.devMode or brush(c)) and 20 or 8),(insect or brush(c)) and 16 or 12,nil,145); if not insect and not M.workshop and not M.devMode and not brush(c) then text(c.kind=='boss' and 'Rencontre' or c.kind=='mob' and 'Créature' or 'Placement',77,y+36,12,color.muted) end
    end end
    if not M.workshop and not M.devMode then text('Molette : parcourir la liste',20,h-54,12,color.muted) end
    local x,y,scale=bounds(); state.canvas={x=x,y=y,s=scale}
    if M.workshop then text(require('workshop_access').biomeNotice,270,148,16,color.muted,w-520) end
    text(Worlds.names[M.world]..(M.workshop and '' or ' / '..string.format('%02d',M.level)),270,174,18)
    if not M.workshop and not M.devMode then text(#M.layout.entities..' objets  ·  '..(M.dirty[M.key()] and 'Brouillon' or 'Version enregistrée'),w-575,178,12,color.muted) end
    -- Render into a map-sized target: even effects which temporarily reset
    -- the scissor cannot paint into the space around the level.
    if not state.mapCanvas or state.mapCanvas:getWidth()~=M.layout.width then
        if state.mapCanvas then state.mapCanvas:release() end
        state.mapCanvas=g.newCanvas(M.layout.width,600,{dpiscale=1})
        state.mapCanvas:setFilter('linear','linear')
    end
    g.push('all');g.setCanvas(state.mapCanvas);g.origin();g.setScissor();g.setShader();g.clear(0,0,0,0)
    g.setColor(1,1,1); g.draw(state.background)
    if state.grid then g.setColor(1,1,1,.09); for xx=0,M.layout.width,40 do g.line(xx,0,xx,600) end; for yy=0,600,40 do g.line(0,yy,M.layout.width,yy) end end
    local holes,lava={},{}
    local moving=state.drag and M.selected and brush(M.selected) and M.selected.points and M.selected
    for _,e in ipairs(M.layout.entities) do
        if e~=moving then
            if e.kind=='hole' then holes[#holes+1]=e elseif e.kind=='lava' and e.points then lava[#lava+1]=e end
        end
    end
    require('terrain_surface').draw(holes,'hole',state.clock,1,M.world)
    require('editor_terrain').draw(lava,M.world,state.clock)
    if moving then require('brush_preview').draw(moving) end
    if state.stroke then require('brush_preview').draw(state.stroke) end
    for _,e in ipairs(M.layout.entities) do if e.kind~='mob' and e.kind~='boss' and e.kind~='spawn' then entity(e,false,true) end end
    for _,e in ipairs(M.layout.entities) do if e.kind=='mob' or e.kind=='boss' or e.kind=='spawn' then entity(e) end end
    if state.tool then local mx,my=love.mouse.getPosition(); local px,py=point(mx,my)
        if inside(mx,my) then
            if brush(state.tool) then g.setColor(color.accent);g.circle('line',px,py,state.brush)
            else local ghost=M.clone(state.tool); ghost.x=snapped(px); ghost.y=snapped(py); entity(ghost,true) end
        end
    end
    g.pop()
    g.push('all');g.setShader();g.setBlendMode('alpha','premultiplied');g.setColor(1,1,1)
    g.draw(state.mapCanvas,x,y,0,scale,scale);g.pop()
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
        for _,f in ipairs({'x','y','w','h','rx','ry','speed','phase','dx','rota','radius','spawnDelay','spawnInterval','movementRate','attackRate','rotation'}) do if (e[f]~=nil or defaults[f]~=nil) and not (e.kind=='wall' and f=='rotation') and not (e.type=='wind_bat' and f=='dx') then
            local value=e[f] or defaults[f]
            local yy=272+row*39; text(({rotation='Angle (°)',movementRate='Dépl. ×',attackRate='Attaques ×',spawnDelay='Début (s)',spawnInterval='Intervalle (s)',speed='Vitesse',radius='Rayon',phase='Phase',w='Largeur',h='Hauteur'})[f] or f:upper(),right,yy+8,12,color.muted,M.projects and 103 or nil)
            local label=state.input==f and state.inputText..'|' or tostring(math.floor(value*100+.5)/100)
            button(label,right+(M.projects and 110 or 88),yy,M.projects and 95 or 117,34,function() state.input=f; state.inputText=tostring(value); love.keyboard.setTextInput(true) end,state.input==f)
            row=row+1
        end end
        local yy=280+row*39
        if e.type=='wind_bat' then button(e.dx==-1 and 'Droite → gauche' or 'Gauche → droite',right,yy,207,34,function() M.checkpoint();e.dx=e.dx==-1 and 1 or -1;M.persist() end);yy=yy+42 end
        if e.kind=='wall' then button('Tourner de 90°',right,yy,207,34,M.rotate);yy=yy+42 end
        if e.kind=='mob' and e.type~='piege' and e.type~='scie' then
            button(e.has_larme and 'Porte une larme : oui' or 'Porte une larme : non',right,yy,207,32,function() M.checkpoint(); e.has_larme=not e.has_larme; M.persist() end,e.has_larme); yy=yy+42
        end
        if e.type=='mole' or e.type=='worm' then button(e.startUnderground and 'Départ : sous terre' or 'Départ : en surface',right,yy,207,32,function() M.checkpoint();e.startUnderground=not e.startUnderground;M.persist() end,e.startUnderground);yy=yy+42 end
        button('Dupliquer',right,yy,99,34,function() local t=M.clone(e); M.add(t,math.min(M.layout.width-40,e.x+30),math.min(560,e.y+30)) end)
        button('Supprimer',right+108,yy,99,34,M.delete)
    else
        text(state.tool and state.tool.name or 'Aucun objet sélectionné',right,212,18,nil,208)
        if state.tool and brush(state.tool) then
            text('Taille : '..state.brush*2,right,268,16)
            button('−',right,308,98,36,function() state.brush=math.max(4,state.brush-4) end)
            button('+',right+108,308,98,36,function() state.brush=math.min(120,state.brush+4) end)
        elseif not M.workshop and not M.devMode then text('Clique sur le terrain pour placer.\n\nÉchap : sélectionner et déplacer.\n\nGlisse un objet pour le déplacer.\n\nSuppr : effacer.\nCmd+Z / Cmd+Maj+Z : annuler / rétablir.',right,270,14,color.muted,205) end
    end
    button(M.workshop and 'Vider la carte' or 'Restaurer l’original',right,h-110,207,34,function() M.restore(); state.status=M.workshop and 'Carte réinitialisée.' or 'Original restauré en brouillon. Appliquer pour le garder.' end)
    if not M.workshop and not M.devMode then text('Les niveaux personnalisés ne sont pas classés.',right,h-66,12,color.muted,210) end
    g.setColor(.025,.034,.047); g.rectangle('fill',0,h-30,w,30)
    text(state.status~='' and state.status or (M.workshop and require('workshop_access').biomeNotice or ''),18,h-23,16,state.error and {1,.46,.4} or color.muted,w-30)
    if state.input=='templateName' then
        g.setColor(0,0,0,.7);g.rectangle('fill',0,0,w,h)
        g.setColor(color.panel);g.rectangle('fill',w/2-260,h/2-110,520,220,8)
        g.setColor(color.accent);g.rectangle('line',w/2-260,h/2-110,520,220,8)
        text('NOM DE LA CRÉATION',w/2-230,h/2-80,22,color.accent)
        text(state.inputText..'|',w/2-230,h/2-20,18,color.text,460)
        if not M.workshop and not M.devMode then text('Entrée : enregistrer · Échap : annuler',w/2-230,h/2+65,14,color.muted,460) end
    end
    if Projects then Projects.drawPublication() end
end
function love.mousepressed(mx,my,button)
    for _,b in ipairs(state.buttons) do if mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h then if button==1 then b.fn() end; return end end
    if Projects and ((not M.currentProject and not M.devMode) or Projects.publication) then return end
    if not inside(mx,my) then return end
    state.input=nil; love.keyboard.setTextInput(false)
    local x,y=point(mx,my)
    if button==2 then state.tool=nil;state.stroke=nil end
    if state.tool and brush(state.tool) and button==1 then
        M.selected=nil;state.stroke={kind=state.tool.kind,x=x,y=y,radius=state.brush,points={0,0}};return
    end
    if state.tool and button==1 then M.add(state.tool,snapped(x),snapped(y));state.status=require('workshop_access').warning(state.tool,M.world) or ''; return end
    M.selected=nil
    for i=#M.layout.entities,1,-1 do local e=M.layout.entities[i]
        local rx,ry=e.kind=='wall' and e.w/2 or 26,e.kind=='wall' and e.h/2 or 26
        local ex=e.type=='skeleton_fish' and e.x+M.layout.width*.32 or e.x
        local dx,dy=x-ex,y-e.y
        if e.kind=='abyss_part' or e.kind=='abyss_gate' or e.kind=='wall' then
            local a=(e.rotation or 0)*math.pi/180
            dx,dy=math.cos(a)*dx+math.sin(a)*dy,-math.sin(a)*dx+math.cos(a)*dy
            rx,ry=math.max(12,e.w/2),math.max(12,e.h/2)
        elseif e.type=='skeleton_head' then rx,ry=85,75 end
        local hit=brush(e) and e.points and require('ground_holes').contains(e,x,y)
            or not (brush(e) and e.points) and math.abs(dx)<=rx and math.abs(dy)<=ry
        if hit then M.selected=e; M.checkpoint(); state.drag={dx=x-e.x,dy=y-e.y}; break end
    end
end
function love.mousemoved(mx,my)
    if Projects and ((not M.currentProject and not M.devMode) or Projects.publication) then return end
    if state.stroke then
        local x,y=point(mx,my);local e=state.stroke;local p=e.points
        x=math.max(0,math.min(M.layout.width,x))-e.x;y=math.max(0,math.min(600,y))-e.y
        if (x-p[#p-1])^2+(y-p[#p])^2>=16 then
            if #p>=512 then local reduced={};for i=1,#p,4 do reduced[#reduced+1]=p[i];reduced[#reduced+1]=p[i+1] end;e.points=reduced;p=reduced end
            p[#p+1]=x;p[#p+1]=y
        end
        return
    end
    if state.drag and M.selected then local x,y=point(mx,my)
        M.selected.x=math.max(25,math.min(M.layout.width-25,snapped(x-state.drag.dx)))
        M.selected.y=math.max(25,math.min(575,snapped(y-state.drag.dy)))
    end
end
function love.mousereleased(mx,my,button)
    if state.stroke and button==1 then
        love.mousemoved(mx,my)
        local points={};local e=state.stroke
        for i=1,#e.points,2 do points[i]=e.x+e.points[i];points[i+1]=e.y+e.points[i+1] end
        local hole=require('ground_holes').stroke(points,e.radius,e.kind)
        M.add(hole,hole.x,hole.y);M.selected=nil;state.stroke=nil;state.status='';return
    end
    if state.drag then M.persist();state.drag=nil end
end
function love.wheelmoved(x,y) if love.mouse.getX()<250 then state.scroll=math.max(0,state.scroll-y) end end
function love.textinput(s) if Projects and Projects.text(s) then return end;if state.input then if state.input=='templateName' then state.inputText=(state.inputText..s:gsub('[%c]','')):sub(1,60) else state.inputText=state.inputText..s:gsub('[^%d%.%-]','') end end end
function love.keypressed(key)
    if Projects and Projects.key(key) then return end
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
    if key=='escape' then state.tool=nil;state.stroke=nil; M.selected=nil
    elseif key=='delete' or key=='backspace' then M.delete()
    elseif key=='z' and cmd then M.undo(love.keyboard.isDown('lshift','rshift'))
    elseif key=='s' and cmd then apply()
    elseif key=='r' and M.selected and M.selected.kind=='wall' then M.rotate()
    elseif M.selected then
        local step=state.snap and 10 or 1
        local dx=key=='left' and -step or key=='right' and step or 0
        local dy=key=='up' and -step or key=='down' and step or 0
        if dx~=0 or dy~=0 then M.checkpoint(); M.selected.x=M.selected.x+dx; M.selected.y=M.selected.y+dy; M.persist() end
    end
end
function love.update(dt) state.clock=state.clock+dt;if Projects then Projects.update(dt) end; if state.testUpdate then state.testUpdate() end;require('graphics_settings').pace(true) end
function love.quit()
    if Projects and (M.currentProject or M.devMode) then local ok,err=M.persist();if not ok and not M.devMode then state.status='Sauvegarde impossible : '..tostring(err);return true end end
end
function love.errorhandler(message) io.stderr:write(tostring(message)..'\n'..debug.traceback()..'\n'); return function() return 1 end end
