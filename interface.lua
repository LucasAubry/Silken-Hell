local U={buttons={},focus='name',boardWorld=1,clock=0}
local g=love.graphics
local utf8=require 'utf8'
local gold={0.82,0.72,0.49}; local muted={0.47,0.59,0.61}; local white={0.91,0.91,0.83}
function U.load()
    U.fonts={small=g.newFont(12),body=g.newFont(16),medium=g.newFont(22),title=g.newFont('police.ttf',82),heading=g.newFont(28)}
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
            g.setColor(1,0.7,0.25,(hover and 0.035 or 0.015)*(1+pulse*0.3))
            bevel('fill',x-i*2,y-i,w+i*4,h+i*2,cut+i)
        end
        g.setBlendMode('alpha')
    end
    g.setColor(disabled and {0.06,0.09,0.10,0.85} or primary and {0.31,0.23,0.11,0.97} or {0.045,0.10,0.125,0.96})
    bevel('fill',x,y,w,h,cut)
    g.setColor(1,0.85,0.5,disabled and 0.1 or hover and 0.2 or 0.07)
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
    U.buttons[#U.buttons+1]={x=x,y=y,w=w,h=h,run=callback,disabled=disabled}
end
function U.mouse(x,y)
    if not x then x,y=love.mouse.getPosition() end
    local s=math.min(g.getWidth()/1200,g.getHeight()/750)
    return (x-(g.getWidth()-1200*s)/2)/s,(y-(g.getHeight()-750*s)/2)/s
end
function U.click(x,y)
    for i=#U.buttons,1,-1 do local b=U.buttons[i]
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
            if not b.disabled then Audio.play('click'); b.run() end; return
        end
    end
end
function U.background()
    U.shader:send('time',U.clock); U.shader:send('inferno',App.selectedWorld==2 and 1 or 0)
    g.setShader(U.shader); g.setColor(1,1,1); g.draw(U.pixel,0,0,0,1200,750); g.setShader()
    -- Feathered wings and an orbiting halo, drawn as native vector assets.
    g.push(); g.translate(600,265+math.sin(U.clock*0.55)*5)
    for side=-1,1,2 do
        for i=1,13 do
            local x=side*(20+i*11); local y=28+i*1.2
            g.setColor(0.72,0.78,0.70,0.10+(13-i)*0.011)
            g.polygon('fill',side*10,48,x,y-35,x+side*(48+i*1.8),y-80+i*2,x+side*14,y+18)
            g.setColor(0.8,0.75,0.55,0.17); g.line(side*10,48,x+side*40,y-55)
        end
    end
    g.setColor(0.86,0.75,0.46,0.8); g.ellipse('line',0,-32,28,8)

    g.pop()
    -- The actual player sprite is the menu's living centerpiece.
    if player and Art.images.original then
        local x=600+math.sin(U.clock*0.32)*9
        local y=247+math.sin(U.clock*0.9)*7
        g.setBlendMode('add')
        for i=10,1,-1 do g.setColor(1,0.73,0.3,0.006*i); g.ellipse('fill',x,y+38,45+i*8,18+i*4) end
        g.setBlendMode('alpha')
        g.setColor(0.86,0.80,0.57,0.5); g.line(x,62,x,y-80)
        g.setColor(1,1,1); Characters.draw(x,y,216,'down')
    end
    for i=1,95 do
        local x=(i*139+math.sin(U.clock*0.15+i)*18)%1200
        local y=(i*83-U.clock*(3+i%5))%750
        local alpha=0.18+0.3*(math.sin(U.clock+i)*0.5+0.5)
        g.setBlendMode('add'); g.setColor(1,0.8,0.4,alpha*0.15); g.circle('fill',x,y,5)
        g.setColor(1,0.9,0.66,alpha); g.circle('fill',x,y,i%3==0 and 1.6 or 0.8)
        if i%11==0 then g.line(x-4,y,x+4,y); g.line(x,y-4,x,y+4) end
        g.setBlendMode('alpha')
    end
    g.setColor(0.55,0.64,0.59,0.18); g.line(32,56,1168,56)
end
function U.time(t) return string.format('%02d:%05.2f',math.floor(t/60),t%60) end
function U.board(x,y,w,country)
    U.panel(x,y,w,410)
    U.text(country and U.countryName() or 'Monde',x+16,y+14,'medium')
    U.button(Campaign.names[U.boardWorld]..'  ·  Changer',x+16,y+48,w-32,32,function() App.state='boards' end)
    local scores,status=Online.scores(U.boardWorld,country)
    if #scores==0 then
        U.text(U.boardWorld==3 and 'À venir' or status=='loading' and 'Connexion…' or status=='offline' and 'Reconnexion…' or 'Aucun score',x+20,y+207,'body',muted,w-40,'center')
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
    end
end
function U.worldTabs(y)
    for i,name in ipairs(Campaign.names) do local n=i
        U.button(name,84+(i-1)*174,y,164,38,function() U.boardWorld=n; Online.refresh(n) end,false,U.boardWorld==i)
    end
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
    U.button('PARAMÈTRES',435,516,330,44,function() App.state='settings'; U.returnTo='menu' end)
    U.button('HISTOIRE',435,568,330,36,function() App.state='story'; U.storyOffset=0 end)
    U.button('BESTIAIRE'..(Bestiary.pending() and '   ·   i' or ''),435,613,330,36,Bestiary.open)
    U.button(string.format('%02d  %s',App.selectedWorld,Worlds.names[App.selectedWorld]:upper()),435,658,330,36,function() App.state='worlds' end)
end
function U.entry()
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
    U.text('DÉPLACEMENTS',360,175,'small',gold)
    local labels={up='Monter',down='Descendre',left='Gauche',right='Droite',dash='Dash'}
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
function U.worlds()
    U.text('Choisis ton monde',300,95,'heading',white,600,'center')
    for i,name in ipairs(Campaign.names) do local n=i; local x=90+((i-1)%3)*345; local y=170+math.floor((i-1)/3)*215
        U.panel(x,y,330,195)
        U.text(string.format('MONDE %02d',i),x+24,y+20,'small',gold)
        U.text(name,x+24,y+52,'heading',Worlds.color(i).tear)
        local locked=not Worlds.canEnter(i)
        local prev=Worlds.previous(i)
        U.button(i==3 and 'À venir' or (locked and 'Termine '..(Worlds.names[prev] or 'le Paradis') or 'Sélectionner'),x+20,y+130,290,42,function() App.selectedWorld=n; U.boardWorld=n; Online.refresh(n); App.state='menu' end,locked,i==App.selectedWorld)
    end
    U.button('Retour',490,651,220,38,function() App.state='menu' end)
end
function U.bestiaryIcon(entry,x,y,size)
    g.setColor(1,1,1)
    if entry.art=='cloud' then
        g.setColor(.79,.87,.95); g.ellipse('fill',x,y,size*.45,size*.2); g.circle('fill',x-size*.16,y-size*.1,size*.23); g.circle('fill',x+size*.14,y-size*.14,size*.28)
    elseif entry.art=='rain' then
        g.setColor(.35,.75,1); g.setLineWidth(3); for i=-1,1 do g.line(x+i*size*.2,y-size*.3,x+i*size*.2-size*.12,y+size*.3) end; g.setLineWidth(1)
    else Art.draw(entry.art,x,y,size) end
end
function U.bestiary()
    U.panel(95,88,1010,560)
    U.text('Bestiaire',125,110,'heading',gold)
    local known=0; for _,e in ipairs(Bestiary.entries) do if Bestiary.seen[e.id] then known=known+1 end end
    U.text(known..' / '..#Bestiary.entries,905,120,'body',muted,160,'right')
    local page=U.bestPage or 1
    for j=1,8 do local index=(page-1)*8+j; local e=Bestiary.entries[index]
        if e then local y=165+(j-1)*51; local seen=Bestiary.seen[e.id]
            U.button(seen and e.name or '???',125,y,330,43,function() U.bestSelected=index end,not seen,U.bestSelected==index)
        end
    end
    local e=Bestiary.entries[U.bestSelected or 0]
    if e and Bestiary.seen[e.id] then
        U.bestiaryIcon(e,780,275,176)
        U.text(e.name,490,385,'heading',white,570,'center')
        U.text(Worlds.names[e.world],490,428,'small',gold,570,'center')
        U.text(e.text,520,471,'medium',white,510,'center')
    else U.text('Rencontre les créatures pour découvrir leurs secrets.',535,350,'medium',muted,485,'center') end
    U.arrow(155,608,-1,function() U.bestPage=math.max(1,page-1) end)
    U.arrow(425,608,1,function() U.bestPage=math.min(math.ceil(#Bestiary.entries/8),page+1) end)
    U.text(page..' / '..math.ceil(#Bestiary.entries/8),220,598,'body',gold,140,'center')
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
    g.setColor(1,1,1); Art.draw('clock',49,31,25)
    U.outlined(U.time(timer),70,17,'medium',nil,144)
    g.setColor(1,1,1); Art.draw('skull',250,31,26)
    U.outlined(tostring(player.death),267,17,'medium',nil,65)
    U.outlined(string.format('%02d',player.level),564,16,'medium',nil,72)
    U.iconButton(1090,31,'pause',function() App.state='pause' end)
    U.iconButton(1150,31,'restart',function() App.start(Campaign.world) end)
    if Bestiary.pending() then U.button('i',1008,13,36,36,Bestiary.open,false,true) end
    local boss=Raven.active and Raven or Wasp
    if boss.active and not boss.defeated then
        U.outlined(boss.name,335,45,'medium',nil,530)
        local x,y,w,h=335,77,530,18
        g.setColor(0.12,0.045,0.09,0.92); bevel('fill',x-4,y-4,w+8,h+8,8)
        g.setColor(0.86,0.7,0.34); bevel('line',x-4,y-4,w+8,h+8,8)
        local fill=w*boss.hp/boss.maxHp
        g.setColor(0.5+boss.flash,0.13,0.19); g.rectangle('fill',x,y,fill,h)
        g.setColor(1,0.59,0.33); g.rectangle('fill',x,y,fill,3)
        for i=1,boss.maxHp-1 do local xx=x+w*i/boss.maxHp; g.setColor(0.18,0.055,0.1); g.line(xx,y+1,xx,y+h-1) end
        g.setColor(1,1,1); Art.draw('feather',x-23,y+9,32,-0.7); Art.draw('feather',x+w+23,y+9,32,0.7)
    end
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
function U.draw()
    U.buttons={}
    if App.state=='playing' then U.gameHud(); return end
    U.background()
    if App.state=='menu' then U.menu()
    elseif App.state=='entry' then U.entry()
    elseif App.state=='settings' then U.settings()
    elseif App.state=='worlds' then U.worlds()
    elseif App.state=='story' then U.story()
    elseif App.state=='bestiary' then U.bestiary()
    elseif App.state=='boards' then
        U.text('Les âmes les plus rapides',300,109,'heading',white,600,'center'); U.worldTabs(164)
        U.board(185,220,390,true); U.board(625,220,390,false)
        U.button('Retour',490,657,220,38,function() App.state='menu' end)
    elseif App.state=='pause' then
        U.panel(390,355,420,265); U.text('Un instant suspendu',410,378,'heading',white,380,'center')
        U.button('Reprendre',420,435,360,44,function() App.state='playing' end,false,true)
        U.button('Paramètres',420,490,360,40,function() App.state='settings'; U.returnTo='pause' end)
        U.button('Quitter la partie',420,541,360,40,function() App.state='menu' end)
    elseif App.state=='victory' then
        U.panel(355,350,490,300)
        U.text(Worlds.names[Campaign.world]..' · accompli',375,373,'heading',white,450,'center')
        U.text(Profile.name..'  ·  '..U.time(timer)..'  ·  '..player.death..' morts',380,423,'body',gold,440,'center')
        U.text(Worlds.next(Campaign.world) and Worlds.names[Worlds.next(Campaign.world)]..' est débloqué.' or 'Tous les mondes sont accomplis.',385,466,'body',muted,430,'center')
        U.text(Online.scoreStatus,375,507,'small',gold,450,'center')
        U.button(Worlds.next(Campaign.world) and 'Entrer : '..Worlds.names[Worlds.next(Campaign.world)] or 'Rejouer le Ciel',385,536,430,44,function() App.openEntry(Worlds.next(Campaign.world) or Campaign.world) end,false,true)
        U.button('Menu & classements',385,592,430,35,function() U.boardWorld=Campaign.world; App.state='menu' end)
    end
    if Profile.error then U.text(Profile.error,200,686,'small',{1,0.5,0.35},800,'center') end
end
return U
