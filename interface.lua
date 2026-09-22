local U={buttons={},focus='name',boardWorld=1,clock=0}
local g=love.graphics
local utf8=require 'utf8'
local BossHUD=require 'boss_hud'
local gold={0.82,0.72,0.49}; local muted={0.47,0.59,0.61}; local white={0.91,0.91,0.83}
function U.load()
    U.fonts={tiny=g.newFont(10),small=g.newFont(12),body=g.newFont(16),medium=g.newFont(22),title=g.newFont('police.ttf',82),heading=g.newFont(28)}
    U.shader=g.newShader('assets/celestial.glsl')
    U.pixel=g.newImage(love.image.newImageData(1,1)); U.pixel:replacePixels(love.image.newImageData(1,1))
end
function U.text(t,x,y,font,color,width,align)
    g.setFont(U.fonts[font or 'body']); g.setColor(color or white)
    if width then g.printf(t,x,y,width,align or 'left') else g.print(t,x,y) end
end
function U.panel(x,y,w,h)
    g.setColor(0.018,0.035,0.05,0.88); g.rectangle('fill',x,y,w,h,5)
    g.setColor(0.65,0.61,0.43,0.28); g.rectangle('line',x,y,w,h,5)
    g.setColor(gold); g.line(x+16,y,x+48,y); g.line(x+w-48,y+h,x+w-16,y+h)
end
local function bevel(mode,x,y,w,h,cut)
    g.polygon(mode,x+cut,y,x+w-cut,y,x+w,y+cut,x+w,y+h-cut,x+w-cut,y+h,x+cut,y+h,x,y+h-cut,x,y+cut)
end
function U.button(label,x,y,w,h,callback,disabled,primary)
    local mx,my=U.mouse(); local hover=not disabled and mx>=x and mx<=x+w and my>=y and my<=y+h
    local cut=math.min(10,h/4); local pulse=0.5+0.5*math.sin(U.clock*2.5)
    g.setColor(0,0.015,0.02,0.55); bevel('fill',x,y+4,w,h,cut)
    if not disabled and (primary or hover) then
        g.setBlendMode('add')
        for i=4,1,-1 do
            g.setColor(gold[1],gold[2],gold[3],(hover and 0.035 or 0.015)*(1+pulse*0.3))
            bevel('fill',x-i*2,y-i,w+i*4,h+i*2,cut+i)
        end
        g.setBlendMode('alpha')
    end
    g.setColor(disabled and {0.06,0.09,0.10,0.85} or primary and {gold[1]*.32,gold[2]*.32,gold[3]*.32,.97} or {0.045,0.10,0.125,0.96})
    bevel('fill',x,y,w,h,cut)
    g.setColor(gold[1],gold[2],gold[3],disabled and 0.1 or hover and 0.2 or 0.07)
    g.polygon('fill',x+cut,y+2,x+w-cut,y+2,x+w-3,y+cut,x+w-3,y+h/2,x+3,y+h/2,x+3,y+cut)
    g.setLineWidth(primary and 2 or 1)
    g.setColor(disabled and {0.3,0.34,0.31} or hover and {1,0.9,0.58} or gold); bevel('line',x,y,w,h,cut)
    g.setColor(0.85,0.72,0.4,0.3); bevel('line',x+4,y+4,w-8,h-8,math.max(2,cut-2))
    g.setLineWidth(1)
    if w>200 then
        for _,cx in ipairs({x+18,x+w-18}) do
            g.setColor(disabled and muted or gold); g.polygon('fill',cx,y+h/2-4,cx+3,y+h/2,cx,y+h/2+4,cx-3,y+h/2)
        end
    end
    U.text(label,x+12,y+(h-20)/2,'body',disabled and muted or primary and {1,0.93,0.7} or white,w-24,'center')
    U.buttons[#U.buttons+1]={x=x,y=y,w=w,h=h,run=callback,disabled=disabled,sound=(label:lower():find('retour') or label:lower():find('quitter')) and 'back' or 'go'}
end
function U.mouse(x,y)
    if not x then x,y=love.mouse.getPosition() end
    local s=math.min(g.getWidth()/1200,g.getHeight()/750)
    return (x-(g.getWidth()-1200*s)/2)/s,(y-(g.getHeight()-750*s)/2)/s
end
function U.click(x,y)
    for i=#U.buttons,1,-1 do local b=U.buttons[i]
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
            if not b.disabled then Audio.play(b.sound or 'go'); b.run() end; return
        end
    end
end
function U.theme()
    local w=App.selectedWorld==8 and 8 or Worlds.biome(App.selectedWorld or 1,1); local palette=Worlds.color(w)
    U.shader:send('time',U.clock); U.shader:send('biome',w)
    U.shader:send('deep',palette.floor); U.shader:send('fog',palette.ink)
    local tint=({[1]={1,.83,.47},[2]={1,.22,.08},[3]={1,.3,.4},[4]={.15,.9,1},[5]={.75,.46,.22},[6]={.65,.87,1},[7]={.45,.48,1},[8]={.72,.55,1}})[w] or {1,.83,.47}
    U.shader:send('accent',tint)
    for i=1,3 do gold[i]=tint[i]*.8+.12 end
    return w,tint
end
function U.background()
    local w,tint=U.theme()
    g.setShader(U.shader); g.setColor(1,1,1); g.draw(U.pixel,0,0,0,1200,750); g.setShader()
    -- The actual player sprite is the menu's living centerpiece.
    if player and Art.images.original then
        local x=600+math.sin(U.clock*0.32)*9
        local y=247+math.sin(U.clock*0.9)*7
        g.setBlendMode('add')
        if not U.halo then
            local vertices={{0,0,0,0,1,1,1,.26}}
            for i=0,64 do local a=i*math.pi/32;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
            U.halo=g.newMesh(vertices,'fan','static')
        end
        g.setColor(tint[1],tint[2],tint[3],.55+.06*math.sin(U.clock*.8));g.draw(U.halo,x,y,0,155,115)
        g.setBlendMode('alpha')
        g.setColor(0.86,0.80,0.57,0.5); g.line(x,62,x,y-80)
        g.setColor(1,1,1); Characters.draw(x,y,216,'down')
    end
    for i=1,95 do
        local x=(i*139+math.sin(U.clock*0.15+i)*18)%1200
        local y=(i*83-U.clock*(3+i%5))%750
        local alpha=0.18+0.3*(math.sin(U.clock+i)*0.5+0.5)
        g.setBlendMode('add'); g.setColor(tint[1],tint[2],tint[3],alpha*0.15); g.circle('fill',x,y,5)
        g.setColor(tint[1],tint[2],tint[3],alpha); g.circle('fill',x,y,i%3==0 and 1.6 or 0.8)
        if i%11==0 then g.line(x-4,y,x+4,y); g.line(x,y-4,x,y+4) end
        g.setBlendMode('alpha')
    end
    g.setColor(0.55,0.64,0.59,0.18); g.line(32,56,1168,56)
end
function U.time(t) return string.format('%02d:%05.2f',math.floor(t/60),t%60) end
function U.board(x,y,w,country)
    U.panel(x,y,w,410)
    if not Worlds.canViewScores(U.boardWorld) then U.text('Classement voilé',x+16,y+16,'medium',gold);U.text('Termine ce monde pour découvrir ses records.',x+24,y+180,'body',muted,w-48,'center');return end
    local function open() U.boardCountry=country; U.boardPage=1; App.state='rankings' end
    U.buttons[#U.buttons+1]={x=x,y=y,w=w,h=410,run=open}
    U.text(country and U.countryName() or 'Monde',x+16,y+14,'medium')
    U.button(Campaign.names[U.boardWorld]..'  ·  Voir tous',x+16,y+48,w-32,32,open)
    local scores,status=Online.scores(U.boardWorld,country)
    if #scores==0 then
        U.text(status=='loading' and 'Connexion…' or status=='offline' and 'Reconnexion…' or 'Aucun score',x+20,y+207,'body',muted,w-40,'center')
    end
    for i=1,math.min(10,#scores) do local score=scores[i]; local yy=y+96+(i-1)*30
        U.text(tostring(i),x+12,yy+3,'small',gold)
        g.setColor(1,1,1); Characters.portrait(score.skin or 1,x+43,yy+11,25)
        local name=score.name
        while U.fonts.small:getWidth(name)>w-184 do name=name:sub(1,(utf8.offset(name,-1) or 1)-1) end
        U.text(name,x+61,yy+3,'small',white)
        U.text(U.time(score.time),x+w-117,yy+3,'small',gold)
        g.setColor(1,1,1); Art.draw('skull',x+w-43,yy+10,14)
        U.text(tostring(score.deaths or 0),x+w-32,yy+3,'small',white)
        U.text('('..Scoring.label(score.deaths)..')',x+w-80,yy+17,'tiny',muted,68,'right')
    end
end
function U.worldTabs(y)
    local list=Worlds.isSecret(U.boardWorld) and {9,10,11,12,13,14} or Worlds.order
    for i,n in ipairs(list) do local name=Worlds.canViewScores(n) and Worlds.names[n] or '???'
        U.button(name,48+(i-1)*159,y,150,38,function() U.boardWorld=n; U.boardPage=1; Online.refresh(n) end,not Worlds.canViewScores(n),U.boardWorld==n)
    end
end
function U.rankings()
    U.button(Worlds.isSecret(U.boardWorld) and 'Mondes classiques' or 'Mode démon',950,92,205,36,function() U.boardWorld=Worlds.isSecret(U.boardWorld) and 1 or 14;U.boardPage=1 end)
    U.text('Classement des âmes',300,90,'heading',gold,600,'center'); U.worldTabs(145)
    U.button('Monde',220,194,240,34,function() U.boardLocal=false;U.boardCountry=false;U.boardPage=1 end,false,not U.boardLocal and not U.boardCountry)
    U.button(U.countryName(),480,194,240,34,function() U.boardLocal=false;U.boardCountry=true;U.boardPage=1 end,false,not U.boardLocal and U.boardCountry)
    U.button('Cet appareil',740,194,240,34,function() U.boardLocal=true;U.boardPage=1 end,false,U.boardLocal)
    U.boardPage=U.boardPage or 1
    local data,status
    if U.boardLocal then
        local all=Profile.ranking(U.boardWorld);local rows={}
        for i=(U.boardPage-1)*10+1,math.min(U.boardPage*10,#all) do rows[#rows+1]=all[i] end
        data={scores=rows,total=#all,hasMore=U.boardPage*10<#all};status='local'
    else data,status=Online.page(U.boardWorld,U.boardCountry,U.boardPage) end
    U.panel(150,244,970,352)
    U.text('Rang',224,255,'small',muted); U.text('Joueur',330,255,'small',muted)
    U.text('Chrono',724,255,'small',muted); U.text('Morts · pénalité',843,255,'small',muted)
    for i,s in ipairs(data.scores) do local y=287+(i-1)*29
        U.text(tostring((U.boardPage-1)*10+i),226,y,'body',gold)
        g.setColor(1,1,1); Characters.portrait(s.skin or 1,300,y+9,26)
        U.text(s.name,330,y,'body',white); U.text(U.time(s.time),724,y,'body',gold)
        U.text(tostring(s.deaths)..' ('..Scoring.label(s.deaths)..')',843,y,'small',white)
        U.button('Visionner',990,y-2,112,25,function() Replay.watch(s) end,not (s.replay or s.hasReplay))
    end
    if #data.scores==0 then U.text(status=='loading' and 'Connexion…' or status=='offline' and 'Connexion indisponible' or 'Aucun score',300,407,'body',muted,600,'center') end
    U.text(string.format('Page %d / %d  ·  %d records',U.boardPage,math.max(1,math.ceil((data.total or 0)/10)),data.total or 0),370,610,'body',gold,460,'center')
    U.button('Précédente',200,605,160,36,function() U.boardPage=U.boardPage-1 end,U.boardPage==1 or status=='loading')
    U.button('Suivante',840,605,160,36,function() U.boardPage=U.boardPage+1 end,not data.hasMore or status=='loading')
    U.text(Replay.status or '',190,641,'small',muted,820,'center')
    U.button('Retour',490,675,220,38,function() App.state='menu' end)
end
function U.countryName()
    local names={FR='France',BE='Belgique',CH='Suisse',CA='Canada',US='États-Unis',GB='Royaume-Uni',DE='Allemagne',ES='Espagne',IT='Italie',PT='Portugal',MA='Maroc',DZ='Algérie',TN='Tunisie'}
    local c=Online.country
    if c=='ZZ' then return Online.connected and 'Pays indisponible' or 'Détection du pays…' end
    return names[c] or c
end
function U.menu()
    U.board(32,214,290,true); U.board(878,214,290,false)
    U.text('Silken Hell',320,332,'title',white,560,'center')
    U.arrow(430,248,-1,function() Characters.cycle(-1) end)
    U.arrow(770,248,1,function() Characters.cycle(1) end)
    U.button('JOUER',425,450,350,54,function() App.openEntry(App.selectedWorld) end,false,true)
    U.button('PARAMÈTRES',425,511,170,38,function() App.state='settings'; U.returnTo='menu' end)
    U.button('HISTOIRE',605,511,170,38,function() App.state='story'; U.storyOffset=0 end)
    U.button('BESTIAIRE',425,557,170,38,Bestiary.open)
    U.button(Worlds.names[App.selectedWorld]:upper(),425,650,350,36,WorldMap.open)
    U.button('SUCCÈS',605,557,170,38,function() App.state='achievements' end)
    U.button('WORKSHOP',425,603,170,38,Workshop.open)
    U.button('CRÉER',605,603,170,38,Creator.open)
    if Creator.status~='' then U.text(Creator.status,335,698,'small',muted,530,'center') end
end
function U.entry()
    if Input.active then
        U.panel(270,150,660,550)
        U.text('TON PSEUDO : '..App.draftName,290,174,'heading',white,620,'center')
        U.text('A : ajouter une lettre · X : effacer · B : retour',290,223,'small',muted,620,'center')
        local letters='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        for i=1,#letters do local letter=letters:sub(i,i)
            U.button(letter,300+((i-1)%9)*67,270+math.floor((i-1)/9)*58,57,44,function() love.textinput(letter) end)
        end
        U.button('Espace',300,514,190,40,function() love.textinput(' ') end)
        U.button('Effacer',510,514,190,40,function() love.keypressed('backspace');Input.active=true end)
        if App.error then U.text(App.error,300,566,'small',{1,.5,.3},600,'center') end
        U.button('JOUER',300,615,380,46,App.submit,false,true)
        U.button('Retour',700,615,200,46,function() App.state='menu' end)
        return
    end
    U.panel(375,325,450,336)
    U.text('TON NOM DANS L’ÉTERNITÉ',395,346,'heading',white,410,'center')
    U.button('Pseudo : '..App.draftName..(U.focus=='name' and '|' or ''),405,425,390,44,function() U.focus='name' end)
    U.text('PAYS DÉTECTÉ : '..U.countryName(),405,491,'body',gold,390,'center')
    if App.error then U.text(App.error,405,539,'small',{1,0.5,0.35},390,'center') end
    U.button('JOUER',405,574,244,48,App.submit,false,true)
    U.button('Retour',663,574,132,48,function() App.state='menu' end)
end
function U.settings()
    U.panel(330,90,540,602)
    U.text('Paramètres',360,120,'heading',white)
    U.text(Input.pad and ('Manette : '..Input.pad:getName()) or 'Manette : branchement détecté automatiquement',360,160,'small',muted,480)
    U.text('DÉPLACEMENTS',360,182,'small',gold)
    local labels={up='Monter',down='Descendre',left='Gauche',right='Droite',dash='Ralentir'}
    for i,a in ipairs({'up','down','left','right','dash'}) do local action=a
        U.text(labels[a],360,208+(i-1)*44,'body')
        U.button(U.binding==a and 'Appuie sur une touche…' or Profile.keys[a]:upper(),560,200+(i-1)*44,280,35,function() U.binding=action end)
    end
    U.text('SON',360,444,'small',gold)
    for i,k in ipairs({'music','sound'}) do local key=k; local y=472+(i-1)*50
        U.text((k=='music' and 'Ambiance' or 'Effets')..'  '..math.floor(Profile[k]*100+0.5)..' %',360,y+6,'body')
        U.button('−',620,y,60,34,function() Profile[key]=math.max(0,Profile[key]-0.1); Profile.save() end)
        U.button('+',692,y,60,34,function() Profile[key]=math.min(1,Profile[key]+0.1); Profile.save() end)
        U.button('Muet',770,y,70,34,function() Profile[key]=0; Profile.save() end)
    end
    U.button(love.window.getFullscreen() and 'Plein écran : activé  ·  F11' or 'Plein écran : désactivé  ·  F11',360,574,480,35,App.toggleFullscreen)
    U.button('Retour',360,632,480,40,function() U.binding=nil; App.state=U.returnTo or 'menu'; Profile.save() end,false,true)
end
function U.worlds() WorldMap.draw() end
function U.bestiaryIcon(entry,x,y,size)
    g.setColor(1,1,1)
    if entry.id=='electric_gull' then g.setColor(1,.88,.15) end
    if entry.art=='cloud' then
        g.setColor(.79,.87,.95); g.ellipse('fill',x,y,size*.45,size*.2); g.circle('fill',x-size*.16,y-size*.1,size*.23); g.circle('fill',x+size*.14,y-size*.14,size*.28)
    elseif entry.art=='rain' then
        g.setColor(.35,.75,1); g.setLineWidth(3); for i=-1,1 do g.line(x+i*size*.2,y-size*.3,x+i*size*.2-size*.12,y+size*.3) end; g.setLineWidth(1)
    else Art.draw(entry.art,x,y,size) end
    g.setColor(1,1,1)
end
function U.scrollBestiary(amount)
    U.bestScroll=math.max(0,math.min(U.bestScrollMax or 0,(U.bestScroll or 0)+amount))
end
function U.bestiary()
    U.panel(95,88,1010,560)
    U.text('Bestiaire',125,110,'heading',gold)
    local category=U.bestCategory or 'creatures'
    U.button('Créatures',360,107,155,38,function() U.bestCategory='creatures'; U.bestPage=1; U.bestSelected=nil end,false,category=='creatures')
    U.button('Boss',530,107,135,38,function() U.bestCategory='boss'; U.bestPage=1; U.bestSelected=nil end,false,category=='boss')
    U.button('Pièges',680,107,145,38,function() U.bestCategory='traps'; U.bestPage=1; U.bestSelected=nil end,false,category=='traps')
    local rows=Bestiary.list(category)
    local known=0; for _,e in ipairs(Bestiary.entries) do if Bestiary.seen[e.id] then known=known+1 end end
    U.text(known..' / '..#Bestiary.entries,905,120,'body',muted,160,'right')
    local page=U.bestPage or 1
    for j=1,8 do local row=rows[(page-1)*8+j]; local index=row and row.index; local e=row and row.entry
        if e then local y=165+(j-1)*51; local seen=Bestiary.seen[e.id]
            U.button(seen and e.name or '???',125,y,330,43,function() U.bestSelected=index;U.bestScroll=0;U.bestHardcore=false end,not seen,U.bestSelected==index)
        end
    end
    local e=Bestiary.entries[U.bestSelected or 0]
    if e and Bestiary.seen[e.id] then
        if U.bestTextEntry~=e.id then U.bestTextEntry=e.id;U.bestScroll=0 end
        if U.bestHardcore and e.id=='wasp' then g.setShader(Wasp.lavaMaterial(U.clock)) end
        U.bestiaryIcon(e,780,245,132);g.setShader()
        U.text(U.bestHardcore and e.id=='wasp' and 'Les Sœurs de lave' or e.name,490,332,'heading',white,570,'center')
        U.text(Worlds.names[e.world],490,373,'small',gold,570,'center')
        if e.boss then
            U.button(U.bestHardcore and 'Voir la version normale' or 'Voir la version démon',585,399,390,34,function() U.bestHardcore=not U.bestHardcore;U.bestScroll=0 end)
        end
        local content=Bestiary.description(e,U.bestHardcore and e.boss)
        local font=U.fonts.body;local _,lines=font:getWrap(content,490)
        local height=#lines*font:getHeight()*font:getLineHeight()
        U.bestScrollMax=math.max(0,height-161);U.bestScroll=math.min(U.bestScroll or 0,U.bestScrollMax)
        local scale=math.min(g.getWidth()/1200,g.getHeight()/750)
        local ox,oy=(g.getWidth()-1200*scale)/2,(g.getHeight()-750*scale)/2
        g.push('all');g.setScissor(ox+515*scale,oy+448*scale,505*scale,161*scale)
        U.text(content,520,448-U.bestScroll,'body',white,490,'left');g.pop()
        if U.bestScrollMax>0 then
            local thumb=math.max(22,161*161/height)
            g.setColor(.3,.35,.4,.45);g.rectangle('fill',1047,448,4,161)
            g.setColor(gold);g.rectangle('fill',1047,448+(161-thumb)*U.bestScroll/U.bestScrollMax,4,thumb)
            U.text('Molette · touches haut/bas · stick droit',535,621,'small',muted,350)
            U.button('-',915,615,54,26,function() U.scrollBestiary(-80) end)
            U.button('+',977,615,54,26,function() U.scrollBestiary(80) end)
        end
    else U.text('Rencontre les créatures pour découvrir leurs secrets.',535,350,'medium',muted,485,'center') end
    U.arrow(155,608,-1,function() U.bestPage=math.max(1,page-1) end)
    U.arrow(425,608,1,function() U.bestPage=math.min(math.ceil(#rows/8),page+1) end)
    U.text(page..' / '..math.ceil(#rows/8),220,598,'body',gold,140,'center')
    U.button('Retour',490,668,220,38,function() App.state=U.bestReturn or 'menu' end)
end
function U.arrow(cx,cy,dir,callback)
    local mx,my=U.mouse(); local hover=(mx-cx)^2+(my-cy)^2<24^2
    g.setColor(0.08,0.06,0.025,0.9); g.polygon('fill',cx,cy-24,cx+24,cy,cx,cy+24,cx-24,cy)
    g.setColor(hover and {1,0.95,0.7} or gold); g.polygon('line',cx,cy-24,cx+24,cy,cx,cy+24,cx-24,cy)
    g.polygon('fill',cx+dir*8,cy,cx-dir*5,cy-8,cx-dir*5,cy+8)
    U.buttons[#U.buttons+1]={x=cx-24,y=cy-24,w=48,h=48,run=callback}
end
function U.outlined(text,x,y,font,color,width)
    g.setFont(U.fonts[font or 'medium'])
    g.setColor(0.1,0.055,0.02,0.95)
    for dx=-2,2,2 do for dy=-2,2,2 do g.printf(text,x+dx,y+dy,width,'center') end end
    g.setColor(color or {1,0.85,0.51}); g.printf(text,x,y,width,'center')
end
function U.iconButton(cx,cy,kind,callback)
    local mx,my=U.mouse(); local hover=(mx-cx)^2+(my-cy)^2<19^2
    g.setColor(0.15,0.08,0.025,0.8); g.circle('fill',cx,cy,18,8)
    g.setColor(hover and {1,0.95,0.75} or gold); g.setLineWidth(2); g.circle('line',cx,cy,18,8)
    if kind=='pause' then g.rectangle('fill',cx-6,cy-7,4,14); g.rectangle('fill',cx+2,cy-7,4,14)
    else g.arc('line','open',cx,cy,9,-math.pi*0.8,math.pi*0.65); g.polygon('fill',cx-12,cy+4,cx-2,cy+6,cx-7,cy-4) end
    g.setLineWidth(1)
    U.buttons[#U.buttons+1]={x=cx-20,y=cy-20,w=40,h=40,run=callback}
end
function U.gameHud()
    if App.practice and not Replay.playing then U.text('Entraînement · non classé',640,22,'small',{.8,.85,.9}) end
    if Campaign.biome==7 then U.text('Charges : '..(player.charges or 0),790,22,'small',{.4,.9,1}) end
    g.setColor(1,1,1); Art.draw('clock',49,31,25)
    U.outlined(U.time(Scoring.total(timer,player.death)),70,17,'medium',nil,144)
    g.setColor(1,1,1); Art.draw('skull',250,31,26)
    U.outlined(tostring(player.death),267,17,'medium',nil,65)
    U.text(Scoring.label(player.death),335,24,'small',gold)
    U.outlined(string.format('%02d',player.level),564,16,'medium',nil,72)
    if Replay.playing then
        U.iconButton(1090,31,'pause',function() Replay.paused=not Replay.paused end)
        U.button('Quitter',1118,13,75,36,function() Replay.stop() end)
    else
        U.iconButton(1090,31,'pause',function() App.state='pause' end)
        U.iconButton(1150,31,'restart',App.restartCurrent)
    end
    local bossId=Bestiary.currentBoss()
    if not Replay.playing and (bossId or Bestiary.pending()) then U.button('i',1008,13,36,36,Bestiary.openBoss,false,true) end
    if bossId and not Replay.playing then U.button('Démon',904,13,94,36,function() Bestiary.openBoss();U.bestHardcore=true;U.bestScroll=0 end) end
    local boss=Bosses.any() and Bosses.hud() or Raven.active and Raven or Wasp.active and Wasp or Storm.active and Storm or Hedgehog.active and Hedgehog or (Abyss.boss and Abyss) or Octopus
    BossHUD.draw(boss)
end
function U.story()
    U.panel(230,105,740,563)
    U.text('Histoire',260,125,'heading',gold,680,'center')
    if Story.text~='' then
        if U.storySource~=Story.text then
            U.storySource=Story.text; U.storyText=g.newText(U.fonts.medium)
            U.storyText:setf(Story.text,640,'center')
        end
        U.storyLimit=440+U.storyText:getHeight()
        local x,y=g.transformPoint(260,178); local ex,ey=g.transformPoint(940,596)
        g.setScissor(x,y,ex-x,ey-y)
        g.setColor(white); g.draw(U.storyText,280,596-(U.storyOffset or 0))
        g.setScissor()
    end
    U.button('Retour',440,610,320,40,function() App.state='menu' end)
end
function U.difficulty(level,extra,x,y)
    level=level or 1;local colors={{1,1,1},{1,.88,.71},{1,.65,.42},{1,.36,.24},{1,.12,.12}}
    local c=colors[level] or colors[1]
    for i=1,level do local xx=x+(i-1)*13;g.setColor(c);g.circle('fill',xx,y+4,4);g.polygon('fill',xx-4,y+3,xx,y-5,xx+4,y+3) end
    if (extra or 0)>0 then U.text('+'..extra,x+level*13,y-5,'small',c) end
end
function U.workshop()
    U.panel(90,82,1020,610)
    U.text('WORKSHOP',125,101,'heading',white,950,'center')
    if Workshop.publishing then
        for i=1,5 do local row=Workshop.localRows[(Workshop.localPage-1)*5+i]; if row then
            U.button('Carte '..((Workshop.localPage-1)*5+i)..' · '..Worlds.names[row.layout.biome or row.layout.world],125,167+(i-1)*61,400,48,function() Workshop.selectLocal(row) end,false,Workshop.selected==row)
        end end
        U.button('Précédent',125,480,190,36,function() Workshop.localPage=Workshop.localPage-1 end,Workshop.localPage==1)
        U.button('Suivant',330,480,195,36,function() Workshop.localPage=Workshop.localPage+1 end,Workshop.localPage*5>=#Workshop.localRows)
        if Workshop.selected then
            U.text('Titre de la carte',567,175,'small',gold)
            U.button(Workshop.title..(Workshop.focus=='title' and '|' or ''),560,205,510,48,function() Workshop.focus='title'; love.keyboard.setTextInput(true) end)
            U.text('Ton pseudo',567,275,'small',gold)
            U.button(Workshop.author..(Workshop.focus=='author' and '|' or ''),560,303,510,44,function() Workshop.focus='author'; love.keyboard.setTextInput(true) end)
            U.button('Biome : '..Worlds.names[Workshop.biome],125,535,400,35,function() Workshop.biome=Worlds.order[Worlds.rank(Workshop.biome)%#Worlds.order+1] end)
            U.button('Difficulté '..Workshop.difficulty..'/5',560,363,510,35,function() Workshop.difficulty=Workshop.difficulty%5+1 end)
            U.difficulty(Workshop.difficulty,tonumber(Workshop.difficultyExtra) or 0,576,421)
            if Workshop.difficulty==5 then U.button('Rouge + '..Workshop.difficultyExtra,755,409,315,34,function() Workshop.focus='difficultyExtra';love.keyboard.setTextInput(true) end) end
            U.button('PUBLIER LA CARTE',560,525,510,43,Workshop.publish,Workshop.busy or not Workshop.canPublish(),true)
            U.button('Terminer la carte pour la valider',560,460,510,42,Workshop.testPublication,Workshop.busy)
        end
        U.button('Retour au Workshop',400,631,400,40,Workshop.open)
    else
        U.button('Publier ma carte',125,149,300,40,Workshop.chooseLocal)
        U.button('Créer une carte',440,149,300,40,Creator.open)
        U.button('Actualiser',755,149,315,40,Workshop.refresh,Workshop.busy)
        U.button(Workshop.filterBiome==0 and 'Tous les biomes' or Worlds.names[Workshop.filterBiome],125,198,300,32,function()
            local rank=Workshop.filterBiome==0 and 0 or Worlds.rank(Workshop.filterBiome);Workshop.filter('filterBiome',Worlds.order[rank+1] or 0)
        end,Workshop.busy)
        U.button(Workshop.filterDifficulty==0 and 'Toutes difficultés' or 'Difficulté '..Workshop.filterDifficulty,440,198,300,32,function() Workshop.filter('filterDifficulty',(Workshop.filterDifficulty+1)%6) end,Workshop.busy)
        U.button(({stars='Les plus étoilées',easy='Faciles → difficiles',hard='Difficiles → faciles'})[Workshop.sort],755,198,315,32,function() Workshop.filter('sort',({stars='easy',easy='hard',hard='stars'})[Workshop.sort]) end,Workshop.busy)
        for i,row in ipairs(Workshop.rows) do
            local y=240+(i-1)*39
            U.text(row.title,130,y+5,'small',white,310);U.difficulty(row.difficulty,row.difficultyExtra,455,y+11)
            U.text(row.author..' · '..(Worlds.names[row.biome or row.world] or ''),610,y+5,'small',muted,240)
            U.button('   '..row.stars,865,y,85,34,function() Workshop.star(row) end,row.voting)
            local points={}; for point=0,9 do local angle=-math.pi/2+point*math.pi/5; local radius=point%2==0 and 8 or 3.7; points[#points+1]=883+math.cos(angle)*radius; points[#points+1]=y+17+math.sin(angle)*radius end
            g.setColor(row.starred and gold or muted); g.polygon(row.starred and 'fill' or 'line',points)
            U.button('Jouer',965,y,105,34,function() Workshop.play(row) end,Workshop.busy)
        end
        U.button('Précédent',125,565,200,36,function() Workshop.page=Workshop.page-1; Workshop.refresh() end,Workshop.page<=1 or Workshop.busy)
        U.text('Page '..Workshop.page,460,572,'small',muted,280,'center')
        U.button('Suivant',870,565,200,36,function() Workshop.page=Workshop.page+1; Workshop.refresh() end,not Workshop.hasMore or Workshop.busy)
        U.button('Retour',450,640,300,36,App.leaveCustom)
    end
    U.text(Workshop.status,125,606,'small',gold,945,'center')
end
function U.draw()
    U.buttons={}
    if App.state=='playing' then U.gameHud();if Replay and Replay.playing then U.text('SPECTATEUR · '..Replay.speed..'×'..(Replay.paused and ' · PAUSE' or '')..'  |  Espace : pause  ·  Gauche/droite : vitesse  ·  Échap : quitter',150,680,'small',white,900,'center') end;if Secret.duel then U.text(Secret.duel.name..(Secret.duel.kind=='mob' and (' · Survie '..math.ceil(math.max(0,20-Secret.duel.time))..' s') or ' · Duel'),300,90,'body',white,600,'center') end;return end
    if App.state=='bossWorld' then Secret.draw();return end
    if App.state=='worlds' then U.theme() else U.background() end
    if App.state=='menu' then U.menu()
    elseif App.state=='quitConfirm' then
        U.menu()
        g.setColor(0,0,0,.7); g.rectangle('fill',0,0,1200,750)
        U.buttons={}
        U.panel(375,270,450,240)
        U.text('Quitter Silken Hell ?',395,304,'heading',white,410,'center')
        U.button('Rester',410,378,380,44,function() App.state='menu' end,false,true)
        U.button('Quitter le jeu',410,438,380,40,function() App.quitDelay=.4 end)
    elseif App.state=='workshop' then U.workshop()
    elseif App.state=='achievements' then
        U.panel(230,105,740,563); U.text('SUCCÈS',260,130,'heading',white,680,'center')
        local totals={{'Larmes récupérées',Profile.stats.tears},{'Morts',Profile.stats.deaths},{'Essais',Profile.stats.attempts}}
        for i,v in ipairs(totals) do local x=270+(i-1)*226
            U.panel(x,184,208,76);U.text(tostring(v[2]),x+10,194,'heading',gold,188,'center');U.text(v[1],x+10,232,'small',muted,188,'center')
        end
        U.button(U.hideCompleted and 'Afficher les succès accomplis' or 'Masquer les succès accomplis',310,276,580,34,function() U.hideCompleted=not U.hideCompleted;U.achievementPage=1 end)
        local row=0;local visible=0;U.achievementPage=U.achievementPage or 1
        for _,a in ipairs(Achievements.list) do
            local unlocked=Profile.achievements[a.id]
            if not (unlocked and U.hideCompleted) then
                visible=visible+1
                if math.floor((visible-1)/2)+1==U.achievementPage then
                local y=323+row*121;row=row+1;U.panel(270,y,660,108)
                U.text(unlocked and a.name or 'Succès secret',292,y+12,'medium',unlocked and gold or white,616)
                U.text(unlocked and a.description() or 'À découvrir en jouant.',292,y+46,'body',muted,616)
                U.text(unlocked and ('DÉBLOQUÉ'..(a.id=='gillou' and ' · Skin Gillou' or a.id=='maxance' and ' · Skin Maxance' or '')) or '???',292,y+84,'small',gold,616)
            end
            end
        end
        U.button('Précédent',270,575,155,30,function() U.achievementPage=U.achievementPage-1 end,U.achievementPage<=1)
        U.button('Suivant',775,575,155,30,function() U.achievementPage=U.achievementPage+1 end,U.achievementPage*2>=visible)
        U.button('Retour',440,610,320,40,function() App.state='menu' end)
    elseif App.state=='customVictory' then
        U.panel(300,235,600,350); U.text(App.practice and 'Entraînement terminé' or Secret.duel and 'Duel terminé' or 'Carte terminée',330,265,'heading',white,540,'center')
        U.text(U.time(Scoring.total(timer,player.death))..' · '..player.death..' morts ('..Scoring.label(player.death)..')',330,325,'body',gold,540,'center')
        if App.workshopMap then U.button('Donner une étoile',375,380,450,42,function() Workshop.star(App.workshopMap) end,App.workshopMap.starred) end
        U.button('Rejouer',375,441,450,42,App.restartCurrent)
        U.button(App.practice and 'Retour aux mondes' or Secret.duel and 'Retour au Sanctuaire' or 'Retour au Workshop',375,497,450,42,function() if Workshop.validationRun then Workshop.resumePublication() elseif App.practice then App.leaveCustom();App.state='worlds' elseif Secret.duel then Secret.open() else App.leaveCustom(); Workshop.open() end end)
    elseif App.state=='entry' then U.entry()
    elseif App.state=='settings' then U.settings()
    elseif App.state=='worlds' then U.worlds()
    elseif App.state=='story' then U.story()
    elseif App.state=='bestiary' then U.bestiary()
    elseif App.state=='bossWorld' then Secret.draw()
    elseif App.state=='rankings' then U.rankings()
    elseif App.state=='boards' then
        U.text('Les âmes les plus rapides',300,109,'heading',white,600,'center'); U.worldTabs(164)
        U.board(185,220,390,true); U.board(625,220,390,false)
        U.button('Retour',490,657,220,38,function() App.state='menu' end)
    elseif App.state=='pause' then
        U.panel(390,355,420,265); U.text('Un instant suspendu',410,378,'heading',white,380,'center')
        U.button('Reprendre',420,435,360,44,function() App.state='playing' end,false,true)
        U.button('Paramètres',420,490,360,40,function() App.state='settings'; U.returnTo='pause' end)
        U.button('Quitter la partie',420,541,360,40,App.leaveCustom)
    elseif App.state=='victory' then
        U.panel(355,350,490,300)
        U.text(Worlds.names[Campaign.world]..' · accompli',375,373,'heading',white,450,'center')
        U.text(Profile.name..'  ·  '..U.time(Scoring.total(timer,player.death))..'  ·  '..player.death..' morts ('..Scoring.label(player.death)..')',380,423,'body',gold,440,'center')
        U.text(Worlds.isSecret(Campaign.world) and 'Défi démon terminé.' or Worlds.next(Campaign.world) and Worlds.names[Worlds.next(Campaign.world)]..' est débloqué.' or 'Tous les mondes sont accomplis.',385,466,'body',muted,430,'center')
        U.text(Online.scoreStatus,375,507,'small',gold,450,'center')
        U.button(Worlds.next(Campaign.world) and 'Entrer : '..Worlds.names[Worlds.next(Campaign.world)] or 'Rejouer : '..Worlds.names[Campaign.world],385,536,430,44,function() App.openEntry(Worlds.next(Campaign.world) or Campaign.world) end,false,true)
        U.button(Worlds.isSecret(Campaign.world) and 'Retour au Sanctuaire' or 'Menu & classements',385,592,430,35,function() U.boardWorld=Campaign.world;if Worlds.isSecret(Campaign.world) then Secret.open() else App.state='menu' end end)
    end
    if Profile.error then U.text(Profile.error,200,686,'small',{1,0.5,0.35},800,'center') end
end
function U.secretScissor()
    local w,h=g.getDimensions();local s=math.min(w/1200,h/750)
    return (w-1200*s)/2+70*s,(h-750*s)/2+220*s,1060*s,310*s
end
return U
