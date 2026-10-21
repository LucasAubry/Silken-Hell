local U={buttons={},focus='name',boardWorld=1,clock=0}
local L=require 'localization'
local T=L.text
local g=love.graphics
local utf8=require 'utf8'
local BossHUD=require 'boss_hud'
local Motion=require 'ui_motion'
local gold={0.82,0.72,0.49}; local muted={0.47,0.59,0.61}; local white={0.91,0.91,0.83}
function U.load()
    U.fonts={tiny=g.newFont(10),small=g.newFont(12),body=g.newFont(16),medium=g.newFont(22),title=g.newFont('assets/fonts/police.ttf',82),heading=g.newFont(28)}
    U.fallbackFonts={}
    for name,font in pairs(U.fonts) do
        if name~='title' then
            local fallback=g.newFont('assets/fonts/NotoSansCJKjp-Regular.otf',({tiny=10,small=12,body=16,medium=22,heading=28})[name])
            U.fallbackFonts[name]=fallback; font:setFallbacks(fallback);font:setLineHeight(1.15)
        end
    end
    U.shader=g.newShader('assets/shaders/celestial.glsl')
    U.pixel=g.newImage(love.image.newImageData(1,1)); U.pixel:replacePixels(love.image.newImageData(1,1))
end
function U.text(t,x,y,font,color,width,align)
    return U.rawText(L.render(t),x,y,font,color,width,align)
end
function U.rawText(t,x,y,font,color,width,align)
    g.setFont(U.fonts[font or 'body']); g.setColor(color or white)
    if width then g.printf(t,x,y,width,align or 'left') else g.print(t,x,y) end
end
function U.ellipsize(text,font,width)
    local f=U.fonts[font]
    if f:getWidth(text)<=width then return text end
    while #text>0 and f:getWidth(text..'…')>width do text=text:sub(1,(utf8.offset(text,-1) or 1)-1) end
    return text..'…'
end
-- Fit labels on one line without letting long names intrude into neighbouring art.
function U.fitText(text,x,y,font,color,width,align)
    text=L.render(text);local f=U.fonts[font];local scale=math.min(1,width/math.max(1,f:getWidth(text)))
    local offset=align=='center' and (width-f:getWidth(text)*scale)/2 or align=='right' and width-f:getWidth(text)*scale or 0
    g.push();g.translate(x+offset,y);g.scale(scale,scale);U.rawText(text,0,0,font,color);g.pop()
end
local podiumColors={[1]={1,.81,.38},[2]={1,.28,.12},[3]={.55,1,.42},[4]={.15,.91,1},[5]={.91,.64,.32},[6]={.62,.72,1},[7]={.25,.61,1}}
function U.podiumName(name,x,y,font,rank,world)
 if rank>3 then U.rawText(name,x,y,font,white);return end
 local c=podiumColors[Worlds.biome(world)] or gold
 local strength=({1,.65,.4})[rank];local pulse=.8+.2*math.sin(U.clock*2)
 g.push('all')
 for radius=2,1,-1 do
  for _,v in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
   U.rawText(name,x+v[1]*radius,y+v[2]*radius,font,{c[1],c[2],c[3],.09*strength*pulse})
  end
 end
 U.podiumShader=U.podiumShader or g.newShader([[
 extern float clock;extern float strength;
 vec4 effect(vec4 color,Image image,vec2 uv,vec2 px) {
  float shine=pow(.5+.5*sin(px.x*.035-clock*2.4),18.)*.7*strength;
  vec4 p=Texel(image,uv);return vec4(mix(color.rgb,vec3(1.),shine),color.a*p.a);
 }]])
 g.setShader(U.podiumShader);U.podiumShader:send('clock',U.clock);U.podiumShader:send('strength',strength)
 U.rawText(name,x,y,font,{c[1],c[2],c[3],1});g.pop()
end
-- Shared hit area for player identities in compact and full leaderboards.
function U.playerTarget(score,x,y,w,h)
 local mx,my=U.mouse()
 local hover=Input and Input.active and Input.index==#U.buttons+1
  or not (Input and Input.active) and mx>=x and mx<=x+w and my>=y and my<=y+h
 if hover then
  g.push('all');g.setShader();g.setLineWidth(1.5)
  g.setColor(gold[1],gold[2],gold[3],.09);g.rectangle('fill',x,y,w,h,5)
  g.setColor(gold[1],gold[2],gold[3],.9);g.rectangle('line',x,y,w,h,5)
  g.pop()
 end
 U.buttons[#U.buttons+1]={x=x,y=y,w=w,h=h,run=function()require('player_profile').open(score)end,sound='go'}
 return hover
end
function U.panel(x,y,w,h,animated)
    g.setColor(0.018,0.035,0.05,0.88); g.rectangle('fill',x,y,w,h,5)
    g.setColor(0.65,0.61,0.43,0.28); g.rectangle('line',x,y,w,h,5)
    if animated then require('panel_border').draw(x,y,w,h,U.clock,gold)
    else g.setColor(gold); g.line(x+16,y,x+48,y); g.line(x+w-48,y+h,x+w-16,y+h) end
end
local function bevel(mode,x,y,w,h,cut)
    g.polygon(mode,x+cut,y,x+w-cut,y,x+w,y+cut,x+w,y+h-cut,x+w-cut,y+h,x+cut,y+h,x,y+h-cut,x,y+cut)
end
function U.button(label,x,y,w,h,callback,disabled,primary,sound,raw,tint)
    local gold=tint or gold
    local mx,my=U.mouse()
    local hover=not disabled and ((Input and Input.active) and Input.index==#U.buttons+1 or not (Input and Input.active) and mx>=x and mx<=x+w and my>=y and my<=y+h)
    if App.state=='workshop' and Workshop.dropdown and not U.drawingDropdown then hover=false end
    local key=Motion.key(x,y,w,h);local focus=Motion.focus(key,hover)
    if disabled then focus=0 end
    local click=not disabled and Motion.pressAmount(key) or 0
    local originalY=y
    local pressed=U.pressed and U.pressed.state==App.state and U.pressed.x==x and U.pressed.y==y
    if pressed then y=y+3 elseif Motion.enabled() then y=y-focus*1.2+click*3 end
    local cut=math.min(10,h/4); local pulse=0.5+0.5*math.sin(U.clock*2.5)
    g.setColor(0,0.015,0.02,0.55); bevel('fill',x,originalY+4,w,h,cut)
    if not disabled and (primary or focus>.01) then
        g.setBlendMode('add')
        for i=4,1,-1 do
            g.setColor(gold[1],gold[2],gold[3],((primary and .015 or 0)+focus*.025)*(1+pulse*0.3))
            bevel('fill',x-i*2,y-i,w+i*4,h+i*2,cut+i)
        end
        g.setBlendMode('alpha')
    end
    g.setColor(disabled and {0.06,0.09,0.10,0.85} or primary and {gold[1]*.32,gold[2]*.32,gold[3]*.32,.97} or {0.045,0.10,0.125,0.96})
    bevel('fill',x,y,w,h,cut)
    g.setColor(gold[1],gold[2],gold[3],disabled and 0.1 or .07+focus*.13+click*.15)
    g.polygon('fill',x+cut,y+2,x+w-cut,y+2,x+w-3,y+cut,x+w-3,y+h/2,x+3,y+h/2,x+3,y+cut)
    g.setLineWidth(primary and 2 or 1)
    g.setColor(disabled and {0.3,0.34,0.31} or {math.min(1,gold[1]+focus*.15),math.min(1,gold[2]+focus*.15),math.min(1,gold[3]+focus*.15)}); bevel('line',x,y,w,h,cut)
    g.setColor(gold[1],gold[2],gold[3],.3); bevel('line',x+4,y+4,w-8,h-8,math.max(2,cut-2))
    g.setLineWidth(1)
    if Motion.enabled() and focus>.01 then
        local span=(w-28)*focus/2
        g.setColor(gold[1],gold[2],gold[3],focus*.7);g.line(x+w/2-span,y+h-6,x+w/2+span,y+h-6)
    end
    if w>200 then
        for _,cx in ipairs({x+18,x+w-18}) do
            g.setColor(disabled and muted or gold); g.polygon('fill',cx,y+h/2-4,cx+3,y+h/2,cx,y+h/2+4,cx-3,y+h/2)
        end
    end
    local translated=raw and label or L.render(label)
    if App.state=='workshop' or App.state=='settings' or App.state=='graphics' or App.state=='bestiary' or App.state=='bossWorld' or App.state=='achievements' or App.state=='victory' or App.state=='history' then translated=U.ellipsize(translated,'body',w-24) end
    local font=U.fonts.body:getWidth(translated)>w-24 and 'small' or 'body'
    local scale=math.min(1,(w-24)/math.max(1,U.fonts[font]:getWidth(translated)))
    g.push();g.translate(x+w/2,y+h/2);g.scale(scale,scale)
    U.rawText(translated,-U.fonts[font]:getWidth(translated)/2,-U.fonts[font]:getHeight()/2,font,disabled and muted or primary and {1,0.93,0.7} or white)
    g.pop()
    U.buttons[#U.buttons+1]={x=x,y=originalY,w=w,h=h,run=callback,disabled=disabled,sound=sound or ((label:lower():find('retour') or label:lower():find('quitter')) and 'back' or 'go')}
end
function U.mouse(x,y)
    if not x then x,y=love.mouse.getPosition() end
    local s=math.min(g.getWidth()/1200,g.getHeight()/750)
    return (x-(g.getWidth()-1200*s)/2)/s,(y-(g.getHeight()-750*s)/2)/s
end
function U.click(x,y)
    local dropdown=App.state=='workshop' and Workshop.dropdown
    if dropdown and dropdown.bounds then
        local b=dropdown.bounds
        if x<b.x or x>b.x+b.w or y<b.y or y>b.y+b.h then Workshop.dropdown=nil;Input.index=1;return true end
    end
    for i=#U.buttons,1,-1 do local b=U.buttons[i]
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h
            and (not b.radius or (x-b.x-b.w/2)^2+(y-b.y-b.h/2)^2<=b.radius^2) then
            if not b.disabled then
                if U.pressed then return true end
                Audio.play(b.sound or 'go')
                Motion.press(b.x,b.y,b.w,b.h)
                if App.state=='menu' then U.pressed={x=b.x,y=b.y,state=App.state,age=0,run=b.run} else b.run() end
            end; return true
        end
    end
end
function U.updatePress(dt)
    local p=U.pressed;if not p then return end
    p.age=p.age+dt
    if App.state~=p.state then U.pressed=nil
    elseif p.age>=.11 then U.pressed=nil;p.run() end
end
function U.theme()
    local selected=(App.state=='rankings' or App.state=='boards') and U.boardWorld or App.selectedWorld
    local inLevel=App.state=='pause' or ((App.state=='settings' or App.state=='graphics') and U.returnTo=='pause')
    local w=inLevel and Campaign.biome or selected==8 and 8 or Worlds.biome(selected or 1,1); local palette=Worlds.color(w)
    U.shader:send('time',U.clock); U.shader:send('biome',w)
    U.shader:send('deep',w==1 and {.91,.81,.65} or palette.floor); U.shader:send('fog',w==1 and {.96,.86,.70} or palette.ink)
    local tint=({[1]={1,.97,.89},[2]={1,.22,.08},[3]={.48,.91,.38},[4]={.15,.9,1},[5]={.75,.46,.22},[6]={.65,.87,1},[7]={.45,.48,1},[8]={.72,.55,1}})[w] or {1,.83,.47}
    U.shader:send('accent',tint)
    for i=1,3 do gold[i]=tint[i]*.8+.12 end
    return w,tint
end
function U.menuPosition()
    U.menuArrival=U.menuArrival or U.clock
    local t=math.min(1,math.max(0,(U.clock-U.menuArrival)/3.2))
    local settle=t*t*(3-2*t)
    return 600+math.sin(U.clock*.32)*9*settle,-180+427*settle+math.sin(U.clock*.9)*7*settle
end
function U.background()
    local w,tint=U.theme()
    g.setShader(U.shader); g.setColor(1,1,1); g.draw(U.pixel,0,0,0,1200,750); g.setShader()
    -- Ambient motes stay behind the opaque character, including its eyes.
    for i=1,95 do
        local x=(i*139+math.sin(U.clock*0.15+i)*18)%1200
        local y=(i*83-U.clock*(3+i%5))%750
        local alpha=0.18+0.3*(math.sin(U.clock+i)*0.5+0.5)
        g.setBlendMode('add'); g.setColor(tint[1],tint[2],tint[3],alpha*0.15); g.circle('fill',x,y,5)
        g.setColor(tint[1],tint[2],tint[3],alpha); g.circle('fill',x,y,i%3==0 and 1.6 or 0.8)
        if i%11==0 then g.line(x-4,y,x+4,y); g.line(x,y-4,x,y+4) end
        g.setBlendMode('alpha')
    end
    -- The actual player sprite is the menu's living centerpiece.
    if player and Art.images.original and App.state~='skins' and App.state~='achievements' then
        local x=600+math.sin(U.clock*0.32)*9
        local y=247+math.sin(U.clock*0.9)*7
        if App.state=='menu' then x,y=U.menuPosition() end
        local selected=Characters.menuIndex()
        y=y+require('winged_anchors').menuOffset(selected,216)
        if U.lastPortrait~=selected then U.portraitChanged=U.clock;U.lastPortrait=selected end
        local t=math.min(1,math.max(0,(U.clock-(U.portraitChanged or U.clock))/.28))
        if Motion.enabled() then y=y-7*math.sin(t*math.pi)*(1-t) end
        g.setBlendMode('add')
        if not U.halo then
            local vertices={{0,0,0,0,1,1,1,.26}}
            for i=0,64 do local a=i*math.pi/32;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
            U.halo=g.newMesh(vertices,'fan','static')
        end
        g.setColor(tint[1],tint[2],tint[3],.55+.06*math.sin(U.clock*.8));g.draw(U.halo,x,y,0,155,115)
        g.setBlendMode('alpha')
        local _,screenTop=g.inverseTransformPoint(0,0)
        require('silk_art').menuThread(x,screenTop-2,y,216)
        g.setColor(1,1,1); Characters.selectionPortrait(x,y,216)
    end
end
function U.time(t) return string.format('%02d:%05.2f',math.floor(t/60),t%60) end
function U.board(x,y,w,country)
    U.panel(x,y,w,410,true)
    if not Worlds.canViewScores(U.boardWorld,U.boardHardcore) then U.text('Classement voilé',x+16,y+16,'medium',gold);U.text('Termine ce monde pour découvrir ses records.',x+24,y+180,'body',muted,w-48,'center');return end
    local function open() U.boardReturn=nil;U.boardCountry=country; U.boardPage=1; App.state='rankings' end
    U.buttons[#U.buttons+1]={x=x,y=y,w=w,h=410,run=open}
    U.text(country and U.countryName() or 'Monde',x+16,y+14,'medium')
    U.button(Campaign.names[U.boardWorld]..'  ·  Voir tous',x+16,y+48,w-32,32,open)
    local scores,status=Online.scores(U.boardWorld,country,U.boardHardcore)
    if #scores==0 then
        U.text(status=='loading' and 'Connexion…' or status=='offline' and 'Reconnexion…' or 'Aucun score',x+20,y+207,'body',muted,w-40,'center')
    end
    for i=1,math.min(10,#scores) do local score=scores[i]; local yy=y+96+(i-1)*30
        U.text(tostring(i),x+12,yy+3,'small',gold)
        U.playerTarget(score,x+30,yy,w-150,28)
        g.setColor(1,1,1); Characters.scorePortrait(score,x+43,yy+11,25)
        local name=U.ellipsize(score.name,'body',w-219)
        U.podiumName(name,x+61,yy+3,'body',i,U.boardWorld)
        U.text(U.time(score.time),x+w-117,yy+3,'small',gold)
        g.setColor(1,1,1); Art.draw('skull',x+w-43,yy+10,14)
        U.text(tostring(score.deaths or 0),x+w-32,yy+3,'small',white)
        U.text('('..Scoring.label(score.deaths)..')',x+w-80,yy+17,'tiny',muted,68,'right')
    end
end
function U.worldTabs(y)
    local list=U.boardHardcore and Worlds.selection or Worlds.order
    local step=1113/#list
    for i,n in ipairs(list) do local name=Worlds.canViewScores(n,U.boardHardcore) and Worlds.names[n] or '???'
        U.button(name,48+(i-1)*step,y,step-9,38,function() U.boardWorld=n; U.boardPage=1; Online.refresh(n,U.boardHardcore) end,not Worlds.canViewScores(n,U.boardHardcore),U.boardWorld==n,'go')
    end
end
function U.backRankings()
    App.state=U.boardReturn or 'menu';U.boardReturn=nil
end
function U.rankings()
    if RunDetails.view then RunDetails.draw();return end
    U.button(U.boardHardcore and 'Mode normal' or 'Mode hardcore',950,92,205,36,function()
        U.boardHardcore=not U.boardHardcore;U.boardPage=1
        if U.boardWorld>8 or U.boardWorld==8 and not U.boardHardcore then U.boardWorld=1 end
    end)
    g.push();g.translate(300,80);g.scale(1.25);U.text('Classement',0,0,'heading',gold,480,'center');g.pop();U.worldTabs(145)
    U.button('Monde',220,194,240,34,function() U.boardLocal=false;U.boardCountry=false;U.boardPage=1 end,false,not U.boardLocal and not U.boardCountry)
    U.button(U.countryName(),480,194,240,34,function() U.boardLocal=false;U.boardCountry=true;U.boardPage=1 end,false,not U.boardLocal and U.boardCountry)
    U.button('Cet appareil',740,194,240,34,function() U.boardLocal=true;U.boardPage=1 end,false,U.boardLocal)
    U.boardPage=U.boardPage or 1
    local data,status
    if not Worlds.canViewScores(U.boardWorld,U.boardHardcore) then
        data={scores={},total=0,hasMore=false};status='locked'
    elseif U.boardLocal then
        local all=Profile.ranking(U.boardWorld,nil,U.boardHardcore);local rows={}
        for i=(U.boardPage-1)*10+1,math.min(U.boardPage*10,#all) do rows[#rows+1]=all[i] end
        data={scores=rows,total=#all,hasMore=U.boardPage*10<#all};status='local'
    else data,status=Online.page(U.boardWorld,U.boardCountry,U.boardPage,U.boardHardcore) end
    U.panel(150,244,970,352)
    U.text('Rang',224,255,'small',muted); U.text('Joueur',330,255,'small',muted)
    U.text('Chrono',724,255,'small',muted); U.text('Morts · pénalité',843,255,'small',muted)
    for i,s in ipairs(data.scores) do local y=287+(i-1)*29
        U.text(tostring((U.boardPage-1)*10+i),226,y,'body',gold)
        U.playerTarget(s,280,y-2,430,27)
        g.setColor(1,1,1); Characters.scorePortrait(s,300,y+9,26)
        U.podiumName(U.ellipsize(s.name,'body',368),330,y,'body',(U.boardPage-1)*10+i,U.boardWorld); U.text(U.time(s.time),724,y,'body',gold)
        U.text(tostring(s.deaths)..' ('..Scoring.label(s.deaths)..')',843,y,'small',white)
        U.infoBadge(976,y+10,10)
        U.buttons[#U.buttons+1]={x=966,y=y,w=20,h=22,run=function() RunDetails.openScore(s,U.boardWorld) end,sound='go'}
        U.button('Visionner',990,y-2,112,25,function() Replay.watch(s) end,not (s.replay or s.hasReplay))
    end
    if #data.scores==0 then U.text(status=='locked' and 'Termine ce monde pour voir son classement' or status=='loading' and 'Connexion…' or status=='offline' and 'Connexion indisponible' or 'Aucun score',300,407,'body',muted,600,'center') end
    U.rawText(T('Page %d / %d  ·  %d records',U.boardPage,math.max(1,math.ceil((data.total or 0)/10)),data.total or 0),370,610,'body',gold,460,'center')
    U.button('Précédente',200,605,160,36,function() U.boardPage=U.boardPage-1 end,U.boardPage==1 or status=='loading')
    U.button('Suivante',840,605,160,36,function() U.boardPage=U.boardPage+1 end,not data.hasMore or status=='loading')
    U.text(Replay.status or '',190,641,'body',muted,820,'center')
    U.button('Retour',490,675,220,38,U.backRankings)
end
function U.countryName()
    local names={FR='France',BE='Belgique',CH='Suisse',CA='Canada',US='États-Unis',GB='Royaume-Uni',DE='Allemagne',ES='Espagne',IT='Italie',PT='Portugal',MA='Maroc',DZ='Algérie',TN='Tunisie'}
    local c=Online.country
    if c=='ZZ' then return Online.connected and 'Pays indisponible' or 'Détection du pays…' end
    return names[c] or c
end
function U.playGlow(x,y,w,h)
    if not Graphics.effects then return end
    g.push('all');g.setBlendMode('add')
    local pulse=.65+.35*math.sin(U.clock*2.4)
    for i=10,1,-1 do
        g.setColor(gold[1],gold[2],gold[3],(.022+.019*pulse)*(1-i/12))
        bevel('fill',x-i*2,y-i*1.6,w+i*4,h+i*3.2,10+i)
    end
    for side=0,1 do
        local t=(U.clock*.35+side*.5)%1;local xx=x+12+t*(w-24);local yy=y+side*h
        for r=8,1,-1 do g.setColor(1,.87,.48,.04*(1-r/10));g.ellipse('fill',xx,yy,r*3,r) end
        g.setColor(1,.97,.75,.9);g.line(math.max(x+11,xx-14),yy,math.min(x+w-11,xx+14),yy)
    end
    g.pop()
end
function U.menu()
    U.boardWorld=App.selectedWorld or 1
    U.boardHardcore=WorldMap.hardcore==true
    U.board(32,214,290,true); U.board(878,214,290,false)
    local effects=require('skin_effects')
    for i,kind in ipairs({'hardcore','heartbreak','gold'}) do
        if effects.unlocked(kind) then
            local x,y,r=728+(i-1)*44,301,16;local active=effects.enabled(kind)
            local mx,my=U.mouse();local hover=Input.active and Input.index==#U.buttons+1 or not Input.active and (mx-x)^2+(my-y)^2<=r*r
            local tint=kind=='hardcore' and {1,.18,.23} or kind=='heartbreak' and {.96,.38,.49} or {1,.82,.36}
            g.push('all');g.setShader()
            if hover then
                g.setBlendMode('add')
                for ring=6,1,-1 do g.setColor(tint[1],tint[2],tint[3],.035);g.circle('fill',x,y,r+ring*2) end
                g.setBlendMode('alpha')
            end
            g.setColor(active and {tint[1]*.23,tint[2]*.23,tint[3]*.23,.96} or {.04,.07,.09,.96});g.circle('fill',x,y,r)
            g.setColor(tint[1],tint[2],tint[3],hover and 1 or .75);g.setLineWidth(hover and 2 or 1);g.circle('line',x,y,r)
            effects.icon(kind,x,y,10,(active or hover) and 1 or .65,active);g.pop()
            U.buttons[#U.buttons+1]={x=x-r,y=y-r,w=r*2,h=r*2,radius=r,effect=kind,run=function()effects.equip(kind,not effects.enabled(kind))end,sound=active and 'back' or 'go'}
        end
    end
    local sx,sy=U.menuPosition()
    U.buttons[#U.buttons+1]={x=sx-105,y=sy-95,w=210,h=190,run=function()App.state='skins';Input.index=1 end,sound='go'}
    U.text('Silken Hell',320,332,'title',white,560,'center')
    U.arrow(430,248,-1,function() Characters.cycle(-1) end)
    U.arrow(770,248,1,function() Characters.cycle(1) end)
    require('menu_trophies').draw(gold)
    local biomeColor=Worlds.color(App.selectedWorld).tear
    U.playGlow(425,496,350,54)
    U.button(WorldMap.hardcore and 'JOUER · HARDCORE' or 'JOUER',425,496,350,54,function() App.openEntry(App.selectedWorld,WorldMap.hardcore) end,false,true,'selection',false,biomeColor)
    U.button('BESTIAIRE',425,557,170,38,Bestiary.open)
    U.button('SUCCÈS',605,557,170,38,function() require('achievements_screen').open() end)
    U.button('HISTOIRE',425,603,170,38,function() require('history').open() end)
    U.button('WORKSHOP',605,603,170,38,Workshop.open)
    U.button(Worlds.names[App.selectedWorld]:upper(),425,650,350,36,WorldMap.open,false,false,'go')
    if Graphics.effects then
        g.push('all');g.setBlendMode('add')
        for i=1,7 do
            local t=(U.clock*.18+i/7)%1;local x=438+t*324
            g.setColor(biomeColor[1],biomeColor[2],biomeColor[3],math.sin(t*math.pi)*.55)
            g.circle('fill',x,546+math.sin(U.clock*1.5+i)*1.5,1.1)
        end
        g.pop()
    end
    U.iconButton(1148,54,'settings',function() App.state='settings'; U.returnTo='menu' end)
end
function U.skins()
    U.text('SKINS',100,54,'heading',white,1000,'center')
    local mx,my=U.mouse()
    for position,i in ipairs(Characters.baseIndices) do
        local x=78+((position-1)%6)*176;local y=120+math.floor((position-1)/6)*130
        local unlocked=Characters.unlocked(i)
        local hover=Input.active and Input.index==#U.buttons+1 or not Input.active and mx>=x and mx<=x+164 and my>=y and my<=y+118
        g.setColor(.025,.045,.065,.95);g.rectangle('fill',x,y,164,118,7)
        g.setColor((Characters.selected()==i or hover) and gold or {.20,.28,.33});g.setLineWidth(1);g.rectangle('line',x,y,164,118,7)
        g.setColor(1,1,1);Characters.portrait(i,x+82,y+45,78,'down',not unlocked)
        U.rawText(U.ellipsize(unlocked and Characters.names[i] or '???','body',148),x+8,y+88,'body',white,148,'center')
        U.buttons[#U.buttons+1]={x=x,y=y,w=164,h=118,disabled=not unlocked,run=function()Characters.select(i);App.state='menu';Input.index=1 end,sound='go'}
    end
    U.button('Retour',440,666,320,44,function()App.state='menu';Input.index=1 end)
end
function U.entry()
    if Input.active then
        U.panel(270,150,660,550)
        U.rawText(T('TON PSEUDO : ')..App.draftName,290,174,'heading',white,620,'center')
        local letters='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
        for i=1,#letters do local letter=letters:sub(i,i)
            U.button(letter,300+((i-1)%9)*67,270+math.floor((i-1)/9)*58,57,44,function() love.textinput(letter) end)
        end
        U.button('Espace',300,514,190,40,function() love.textinput(' ') end)
        U.button('Effacer',510,514,190,40,function() love.keypressed('backspace');Input.active=true end)
        if App.error then U.text(App.error,300,566,'small',{1,.5,.3},600,'center') end
        U.button('JOUER',300,615,380,46,App.submit,false,true,'selection')
        U.button('Retour',700,615,200,46,function() App.state='menu' end)
        return
    end
    U.panel(375,325,450,336)
    U.text('TON NOM DANS L’ÉTERNITÉ',395,346,'heading',white,410,'center')
    U.button(T('Pseudo : ')..App.draftName..(U.focus=='name' and '|' or ''),405,425,390,44,function() U.focus='name' end,false,false,nil,true)
    U.text('PAYS DÉTECTÉ : '..U.countryName(),405,491,'body',gold,390,'center')
    if App.error then U.text(App.error,405,539,'small',{1,0.5,0.35},390,'center') end
    U.button('JOUER',405,574,244,48,App.submit,false,true,'selection')
    U.button('Retour',663,574,132,48,function() App.state='menu' end)
end
function U.settings()
    U.panel(280,75,640,652)
    U.text('Paramètres',310,110,'heading',white)
    local function tab(page) U.settingsPage=page;Input.cancelBinding() end
    U.button('Jeu et son',310,163,180,40,function() tab('general') end,false,U.settingsPage~='shortcuts' and U.settingsPage~='language')
    U.button('Raccourcis',510,163,180,40,function() tab('shortcuts') end,false,U.settingsPage=='shortcuts')
    U.button('Langue',710,163,180,40,function() tab('language') end,false,U.settingsPage=='language')
    if U.settingsPage=='language' then
        for i,option in ipairs(L.options) do
            local code=option.code
            U.button(option.name,310,233+(i-1)*53,580,42,function()
                Profile.language=code;U.bestScroll=0;U.storySource=nil;Profile.save()
            end,false,Profile.language==code)
        end
    elseif U.settingsPage=='shortcuts' then
        local pad=U.bindingTab=='pad'
        local function device(value) Input.cancelBinding();U.bindingTab=value;U.bindingPage=1 end
        U.button('Clavier',310,222,280,38,function() device('keyboard') end,false,not pad)
        U.button('Manette',610,222,280,38,function() device('pad') end,false,pad)
        local setup=require('controller_setup')
        if pad then
            local selected=Input.device or Input.pad
            U.button(selected and selected:getName() or 'Aucune manette',310,274,390,38,function()
                Input.cancelBinding();Input.scan();local devices=Input.devices;local index=0
                for n,j in ipairs(devices) do if j==Input.device then index=n end end
                Input.device=devices[index%math.max(1,#devices)+1]
                if Input.device and Input.device:isGamepad() then Input.pad=Input.device;Input.axisHeld={} end
            end,setup.wizard~=nil,false,nil,true)
            U.button('Détecter',720,274,170,38,function() setup.error=nil;Input.detect() end,setup.wizard~=nil)
            if setup.wizard then
                local w=setup.wizard;local step=setup.steps[w.index]
                U.text(w.index..' / '..#setup.steps,310,350,'body',gold,580,'center')
                U.text(setup.error or (w.release and 'Relâche la commande' or step[2]),310,405,'body',white,580,'center')
                U.button('Annuler',310,535,280,42,setup.cancel)
                U.button('Passer',610,535,280,42,setup.skip,not step[3] or setup.error~=nil)
                return
            end
            if not selected or not selected:isGamepad() then
                U.text(setup.error or (selected and 'Configuration nécessaire' or 'Aucune manette détectée'),310,395,'body',white,580,'center')
                U.button('Configurer',310,470,580,44,function() setup.begin(selected) end,not selected)
                U.button('Retour',310,666,580,40,function() Input.cancelBinding();App.state=U.returnTo or 'menu' end,false,true)
                return
            end
        end
        local rows={{'up','Monter'},{'down','Descendre'},{'left','Gauche'},{'right','Droite'},{'dash',Profile.speedMode=='slow' and 'Ralentir' or 'Accélérer'},{'pause','Pause / reprendre'},{'restartLevel','Rejouer le niveau'},{'restartWorld','Recommencer le monde'},{'nextWorld','Monde suivant'},{'previousWorld','Monde précédent'},{'replaySlower','Replay : ralentir'},{'replayFaster','Replay : accélérer'}}
        if pad then rows[#rows+1]={'bestiary','Bestiaire'} end
        local page=U.bindingPage or 1
        local perPage=pad and 6 or 7
        for i=1,perPage do local row=rows[(page-1)*perPage+i]
            if row then local action=row[1];local y=(pad and 323 or 279)+(i-1)*(pad and 41 or 43)
                U.rawText(U.ellipsize(T(row[2]),'body',310),310,y+11,'body')
                local label=pad and require('pad_controls').label(Profile.padBindings[action]) or Input.label(Profile.keys[action])
                U.button(U.binding==action and '…' or label,640,y,250,37,function() Input.beginBinding(action,pad and 'pad' or 'keyboard') end)
            end
        end
        if U.binding then
            U.button('Annuler',310,590,280,40,Input.cancelBinding)
            if pad then U.button('Effacer',610,590,280,40,function() Input.bind('none') end) end
        else
            U.button('←',310,590,pad and 70 or 100,40,function() U.bindingPage=page-1 end,page==1)
            U.text(page..' / '..math.ceil(#rows/perPage),pad and 390 or 470,601,'body',gold,pad and 90 or 260,'center')
            U.button('→',pad and 490 or 790,590,pad and 70 or 100,40,function() U.bindingPage=page+1 end,page==math.ceil(#rows/perPage))
            if pad then U.button('Configurer',610,590,280,40,function() setup.begin(Input.device or Input.pad) end) end
        end
    else
        U.button(Profile.speedMode=='slow' and 'Touche vitesse : ralentir' or 'Touche vitesse : accélérer',310,247,580,44,function() Profile.speedMode=Profile.speedMode=='slow' and 'accelerate' or 'slow';Profile.save() end)
        for i,k in ipairs({'music','sound'}) do local key=k;local y=327+(i-1)*68
            U.text(T(k=='music' and 'Ambiance' or 'Effets')..'  '..math.floor(Profile[k]*100+0.5)..' %',310,y+12,'body')
            U.button('−',660,y,60,42,function() Profile[key]=math.max(0,Profile[key]-0.1);Profile.save() end)
            U.button('+',734,y,60,42,function() Profile[key]=math.min(1,Profile[key]+0.1);Profile.save() end)
            U.button('Muet',808,y,82,42,function() Profile[key]=0;Profile.save() end)
        end
        U.button(love.window.getFullscreen() and 'Plein écran : activé' or 'Plein écran : désactivé',310,491,580,44,App.toggleFullscreen)
        U.button('Graphismes',310,559,580,44,function() Input.cancelBinding();App.state='graphics' end)
        local dev=require('dev_profile')
        if dev.available() then
            if dev.status then U.rawText(U.ellipsize(dev.status,'body',580),310,216,'body',gold,580,'center') end
            local armed=U.devResetArmed and U.clock<U.devResetArmed
            U.button(armed and 'Confirmer le reset' or 'Réinitialiser',310,610,280,40,function()
                if U.devResetArmed and U.clock<U.devResetArmed then dev.apply(false) else U.devResetArmed=U.clock+5 end
            end)
            U.button('Tout débloquer',610,610,280,40,function()dev.apply(true)end)
        end
    end
    U.button('Retour',310,666,580,40,function() Input.cancelBinding();App.state=U.returnTo or 'menu';Profile.save() end,false,true)
end
function U.worlds() WorldMap.draw() end
function U.bestiaryIcon(entry,x,y,size)
    require('bestiary_animation').draw(entry,x,y,size,U.clock)
end
function U.scrollBestiary(amount)
    U.bestScroll=math.max(0,math.min(U.bestScrollMax or 0,(U.bestScroll or 0)+amount))
end
function U.bestiary()
    U.panel(95,88,1010,560)
    U.text('Bestiaire',125,110,'heading',gold)
    local category=U.bestCategory or 'creatures'
    local function selectCategory(value)
        local first=Bestiary.list(value)[1]
        U.bestCategory=value;U.bestPage=1;U.bestSelected=first and first.index;U.bestScroll=0;U.bestHardcore=false;U.bestVariant=first and Bestiary.defaultVariant(first.entry,Bestiary.worldFilter) or 1
    end
    U.button('Créatures',360,107,155,38,function() selectCategory('creatures') end,Bestiary.levelFilter and #Bestiary.list('creatures')==0,category=='creatures')
    U.button('Boss',530,107,135,38,function() selectCategory('boss') end,Bestiary.levelFilter and #Bestiary.list('boss')==0,category=='boss')
    U.button('Pièges',680,107,145,38,function() selectCategory('traps') end,Bestiary.levelFilter and #Bestiary.list('traps')==0,category=='traps')
    local rows=Bestiary.list(category)
    local known=0; for _,e in ipairs(Bestiary.entries) do if Bestiary.seen[e.id] then known=known+1 end end
    if not Bestiary.levelFilter then
        U.button(Bestiary.worldFilter and (Worlds.canEnter(Bestiary.worldFilter) and Worlds.names[Bestiary.worldFilter] or '?') or 'Tous les mondes',840,107,235,38,function()
            local index=Bestiary.worldFilter and Worlds.rank(Bestiary.worldFilter) or 0
            Bestiary.worldFilter=Worlds.order[index+1];selectCategory(category)
        end)
    end
    local page=U.bestPage or 1
    for j=1,8 do local row=rows[(page-1)*8+j]; local index=row and row.index; local e=row and row.entry
        if e then local y=165+(j-1)*51; local seen=Bestiary.known(e)
            U.button(seen and e.name or '???',125,y,330,43,function() U.bestSelected=index;U.bestScroll=0;U.bestHardcore=false;U.bestVariant=Bestiary.defaultVariant(e,Bestiary.worldFilter) end,not seen,U.bestSelected==index)
        end
    end
    local e=Bestiary.entries[U.bestSelected or 0]
    if e and Bestiary.known(e) then
        if U.bestTextEntry~=e.id then U.bestTextEntry=e.id;U.bestScroll=0;U.bestRevealed=U.clock end
        local variants=Bestiary.variants[e.id]
        local appearance=Bestiary.appearance(e,U.bestVariant)
        if variants then
            U.arrow(560,245,-1,function()U.bestVariant=((U.bestVariant or 1)-2)%#variants+1;U.bestScroll=0 end)
            U.arrow(1000,245,1,function()U.bestVariant=(U.bestVariant or 1)%#variants+1;U.bestScroll=0 end)
        end
        local reveal=Motion.reveal(U.bestRevealed or U.clock,.22)
        if appearance.undiscovered then require('locked_art').bind() end
        U.bestiaryIcon(appearance,780,245+5*(1-reveal),132*(.94+.06*reveal));g.setShader()
        if appearance.undiscovered then require('locked_art').question(780,245,132) end
        U.rawText(U.ellipsize(appearance.undiscovered and '???' or T(appearance.name),'body',570),490,332,'body',white,570,'center')
        U.text(Worlds.canEnter(appearance.world) and Worlds.names[appearance.world] or '?',490,373,'body',gold,570,'center')
        local content=appearance.undiscovered and '' or L.render(Bestiary.description(appearance,false))
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
            U.button('-',915,615,54,26,function() U.scrollBestiary(-80) end)
            U.button('+',977,615,54,26,function() U.scrollBestiary(80) end)
        end
    else U.text(Bestiary.levelFilter and 'Aucune créature dans ce niveau.' or 'Rencontre les créatures pour découvrir leurs secrets.',535,350,'body',muted,485,'center') end
    U.arrow(155,608,-1,function() U.bestPage=math.max(1,page-1) end)
    U.arrow(425,608,1,function() U.bestPage=math.min(math.max(1,math.ceil(#rows/8)),page+1) end)
    U.text(page..' / '..math.max(1,math.ceil(#rows/8)),220,598,'body',gold,140,'center')
    U.button('Retour',490,668,220,38,function() App.state=U.bestReturn or 'menu' end)
end
function U.arrowArt(cx,cy,dir,hover,angle,ink)
    g.push('all');g.translate(cx,cy);g.rotate(angle or 0)
    g.setColor(0.08,0.06,0.025,0.9);g.polygon('fill',0,-24,24,0,0,24,-24,0)
    g.setColor(ink or (hover and {1,0.95,0.7} or gold));g.polygon('line',0,-24,24,0,0,24,-24,0)
    g.polygon('fill',dir*8,0,-dir*5,-8,-dir*5,8);g.pop()
end
function U.arrow(cx,cy,dir,callback)
    local originalY=cy
    if U.pressed and U.pressed.state==App.state and U.pressed.x==cx-24 and U.pressed.y==cy-24 then cy=cy+3 end
    local mx,my=U.mouse();local hover=(mx-cx)^2+(my-cy)^2<24^2
    U.arrowArt(cx,cy,dir,hover)
    U.buttons[#U.buttons+1]={x=cx-24,y=originalY-24,w=48,h=48,run=callback}
end

function U.outlined(text,x,y,font,color,width)
    text=L.render(text)
    g.setFont(U.fonts[font or 'medium'])
    g.setColor(0.1,0.055,0.02,0.95)
    for dx=-2,2,2 do for dy=-2,2,2 do g.printf(text,x+dx,y+dy,width,'center') end end
    g.setColor(color or {1,0.85,0.51}); g.printf(text,x,y,width,'center')
end
function U.infoBadge(x,y,r)
    g.push('all');g.setColor(.15,.08,.025,.95);g.circle('fill',x,y,r,8)
    local ink={.96,.79,.46};g.setColor(ink);g.setLineWidth(1.2);g.circle('line',x,y,r,8)
    U.text('i',x-r,y-9,'small',ink,r*2,'center');g.pop()
end
function U.iconButton(cx,cy,kind,callback,disabled,paradise)
    if paradise then return require('paradise_hud').icon(U,cx,cy,kind,callback,disabled) end
    local mx,my=U.mouse(); local hover=(mx-cx)^2+(my-cy)^2<19^2
    g.setColor(0.15,0.08,0.025,0.8); g.circle('fill',cx,cy,18)
    g.setColor(disabled and muted or hover and {1,0.95,0.75} or gold); g.setLineWidth(2); g.circle('line',cx,cy,18)
    if kind=='pause' then g.rectangle('fill',cx-6,cy-7,4,14); g.rectangle('fill',cx+2,cy-7,4,14)
    elseif kind=='settings' then
        local teeth={}
        for i=0,31 do
            local angle=i*math.pi/16;local radius=i%4<2 and 12 or 9
            teeth[#teeth+1]=cx+math.cos(angle)*radius;teeth[#teeth+1]=cy+math.sin(angle)*radius
        end
        g.polygon('line',teeth);g.circle('line',cx,cy,4)
    else
        g.push();g.translate(cx,cy)
        if kind=='refresh' and disabled and Motion.enabled() then g.rotate(U.clock*5) end
        g.arc('line','open',0,0,9,-math.pi*0.8,math.pi*0.65);g.polygon('fill',-12,4,-2,6,-7,-4);g.pop()
    end
    g.setLineWidth(1)
    U.buttons[#U.buttons+1]={x=cx-20,y=cy-20,w=40,h=40,radius=20,run=callback,disabled=disabled}
end
function U.sanctuaryReturns()
 if Secret.inArena() and not Replay.playing then
  U.button('Menu',929,53,90,30,App.leaveCustom)
  U.button('Sanctuaire',1028,53,150,30,Secret.returnToSanctuary)
 end
end
function U.deathCounter()
    g.setColor(1,1,1); Art.draw('skull',250,31,26)
    local deaths=tostring(player.death)
    local deathWidth=math.max(35,U.fonts.medium:getWidth(deaths))
    U.outlined(deaths,273,17,'medium',nil,deathWidth)
    local penalty='('..Scoring.label(player.death)..')'
    local penaltyX=273+deathWidth+9
    U.outlined(penalty,penaltyX,21,'body',gold,U.fonts.body:getWidth(penalty))
end
function U.gameHud()
    if Ending and Ending.active then Ending.drawHud();U.sanctuaryReturns();return end
    local paradise=require('paradise_hud');local styled=paradise.active()
    Hardcore.draw()
    if App.practice and not Replay.playing then
        if styled then
            local encounter=Bosses.any() or Raven.active or Wasp.active or Storm.active or Hedgehog.active or Abyss.boss or Octopus.active
            paradise.status(U,'Entraînement · non classé',encounter and 28 or 688,encounter and 58 or 11,295,40)
        else U.fitText('Entraînement · non classé',640,22,'small',{.8,.85,.9},140) end
    end
    if Campaign.biome==7 and not require('abyss_gate').active and not Abyss.encounterActive() then U.text('Charges : '..(player.charges or 0),790,22,'small',{.4,.9,1}) end
    if styled then paradise.draw(U)
    else
        g.setColor(1,1,1); Art.draw('clock',49,31,25)
        U.outlined(U.time(Replay.playing and Replay.frame*Replay.step or Scoring.total(timer,player.death)),70,17,'medium',nil,144)
        U.deathCounter()
        if Replay.playing then
            U.outlined(Replay.ghost and 'Entraînement' or ('/ '..U.time(Replay.data.frames*Replay.step)),335,43,'small',gold,215)
        end
        U.outlined(string.format('%02d',player.level),564,16,'medium',nil,72)
    end
    require('game_feedback').drawHud()
    if Replay.playing then
        U.iconButton(1070,31,'pause',function() if not Replay.job then Replay.paused=not Replay.paused end end,nil,styled)
        U.button('Quitter',1100,13,95,36,function() Replay.stop() end)
    else
        if App.preview and not App.historyPreview then U.button('Recharger',835,13,160,36,function() if not PreviewBridge.reload() then App.state='pause' end end) end
        U.iconButton(1090,31,'pause',function() App.state='pause' end,nil,styled)
        U.iconButton(1150,31,'restart',App.restartCurrent,nil,styled)
    end
    if not Replay.playing then
        if styled then U.iconButton(1026,31,'info',Bestiary.openLevel,false,true)
        else U.button('i',1008,13,36,36,Bestiary.openLevel,false,true) end
    end
    local boss=Bosses.any() and Bosses.hud() or Raven.active and Raven or Wasp.active and Wasp or Storm.active and Storm or Hedgehog.active and Hedgehog or (Abyss.boss and Abyss) or Octopus
    if Abyss.boss and not Abyss.defeated and not Replay.playing then
        U.button(Abyss.physicsTest and 'Réactiver le boss' or 'Désactiver le boss',925,65,250,36,function()
            require('mobs.bosses.abyss.pattern_cycle').togglePhysics(Abyss)
        end)
    end
    if not boss.physicsTest then BossHUD.draw(boss) end
    U.sanctuaryReturns()
end
function U.story()
    U.panel(230,105,740,563)
    U.text('Histoire',260,125,'heading',gold,680,'center')
    local story=Story.localizedText()
    if story~='' then
        if U.storySource~=story then
            U.storySource=story; U.storyOffset=400; U.storyText=g.newText(U.fonts.medium)
            U.storyText:setf(story,640,'center')
        end
        U.storyLimit=math.max(400,100+U.storyText:getHeight())
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
    if (extra or 0)>0 then U.text('+'..extra,x+level*13,y-5,'body',c) end
end
function U.workshopSelect(key,label,x,y,w,h,filter)
    local isDifficulty=key~='biome' and key~='filterBiome'
    local value=Workshop[key] or 0
    U.button(isDifficulty and value>0 and '' or label,x,y,w,h,function()
        Workshop.focus=nil;love.keyboard.setTextInput(false)
        local options={};local biome=key=='biome' or key=='filterBiome'
        if filter then options[#options+1]={value=0,label=biome and 'Tous les biomes' or 'Toutes difficultés'} end
        for _,value in ipairs(biome and Worlds.order or {1,2,3,4,5}) do
            options[#options+1]={value=value,label=biome and Worlds.names[value] or ''}
        end
        Workshop.dropdown={key=key,options=options,x=x,y=y,w=w,h=h,filter=filter,opened=U.clock}
        Input.index=1
        for i,option in ipairs(options) do if option.value==Workshop[key] then Input.index=i end end
    end,Workshop.busy)
    if isDifficulty and value>0 then require('difficulty_tears').draw(value,x+w/2-(value-1)*9,y+h/2-3,18,5) end
    g.setColor(Workshop.busy and muted or gold);g.polygon('fill',x+w-17,y+h/2-2,x+w-9,y+h/2-2,x+w-13,y+h/2+3)
end
function U.workshopDropdown()
    local d=Workshop.dropdown;if not d then return end
    local height=#d.options*35+12
    local y=d.y+d.h+4;if y+height>595 then y=d.y-height-4 end
    d.bounds={x=d.x,y=y,w=d.w,h=height}
    g.setColor(0,0,0,.3);g.rectangle('fill',90,140,1020,490)
    local revealed=math.max(1,height*Motion.reveal(d.opened or U.clock,.18))
    local top=y<d.y and y+height-revealed or y
    g.push('all')
    local sx,sy=g.transformPoint(d.x-2,top);local ex,ey=g.transformPoint(d.x+d.w+2,top+revealed)
    g.intersectScissor(sx,sy,ex-sx,ey-sy)
    U.panel(d.x,y,d.w,height);U.buttons={}
    U.drawingDropdown=true
    for i,option in ipairs(d.options) do
        U.button(option.label,d.x+6,y+6+(i-1)*35,d.w-12,33,function()
            Workshop.dropdown=nil;Input.index=1
            if d.filter then Workshop.filter(d.key,option.value) else Workshop[d.key]=option.value end
        end,false,Workshop[d.key]==option.value)
        if d.key~='biome' and d.key~='filterBiome' and option.value>0 then
            require('difficulty_tears').draw(option.value,d.x+d.w/2-(option.value-1)*9,y+19+(i-1)*35,18,5)
        end
    end
    U.drawingDropdown=nil;g.pop()
end
function U.voteStar(row,x,y)
    local feedback=Workshop.voteFeedback
    local t=feedback and feedback.id==row.id and math.max(0,math.min(1,(U.clock-feedback.at)/.42)) or 1
    if not Motion.enabled() then t=1 end
    local bump=math.sin(t*math.pi)*(1-t)
    local size=1+bump*(feedback and feedback.added and .65 or -.3)
    local points={}
    for point=0,9 do local angle=-math.pi/2+point*math.pi/5;local radius=(point%2==0 and 8 or 3.7)*size
        points[#points+1]=x+math.cos(angle)*radius;points[#points+1]=y+math.sin(angle)*radius
    end
    g.setColor(row.starred and gold or muted);g.polygon(row.starred and 'fill' or 'line',points)
    if t<1 and feedback.added then
        g.setColor(gold[1],gold[2],gold[3],math.sin(t*math.pi)*(1-t));g.setLineWidth(1)
        for i=0,4 do local a=-math.pi/2+i*math.pi*2/5;local r=10+t*6
            g.line(x+math.cos(a)*r,y+math.sin(a)*r,x+math.cos(a)*(r+3*(1-t)),y+math.sin(a)*(r+3*(1-t)))
        end
    end
end
function U.workshop()
    U.panel(90,82,1020,610)
    U.text('WORKSHOP',125,101,'heading',white,950,'center')
    if Workshop.removing then
        local row=Workshop.removing
        U.text('Retirer cette carte du Workshop ?',160,220,'heading',white,880,'center')
        U.rawText(U.ellipsize(row.title,'body',800),200,295,'body',gold,800,'center')
        U.button('Retirer',260,410,320,48,function() Workshop.remove(row) end,Workshop.busy)
        U.button('Annuler',620,410,320,48,function() Workshop.removing=nil end,Workshop.busy)
    elseif Workshop.stats then
        local stats=Workshop.stats;local d=stats.data
        U.rawText(U.ellipsize(stats.row.title,'heading',880),160,165,'heading',gold,880,'center')
        local function number(n) return n and string.format('%.1f',n) or '—' end
        local rows={{'Joueurs',d.players},{'Parties lancées',d.sessions},{'Cartes terminées',d.completions},{'Morts totales',d.deaths},
            {'Essais moyens avant réussite',number(d.averageAttempts)},{'Taux de réussite',d.sessions>0 and string.format('%.0f %%',100*d.completions/d.sessions) or '—'},
            {'Temps moyen',d.averageTime and U.time(d.averageTime) or '—'},{'Meilleur temps',d.bestTime and U.time(d.bestTime) or '—'}}
        for i,r in ipairs(rows) do local col=(i-1)%2;local y=230+math.floor((i-1)/2)*55
            U.text(r[1],150+col*470,y,'body',muted);U.rawText(tostring(r[2]),510+col*470,y,'body',white)
        end
        U.text('Zones les plus meurtrières',150,460,'medium',gold)
        for i,spot in ipairs(d.hotspots or {}) do
            local level,x,y=spot.zone:match('(%d+):(%d+):(%d+)')
            local area=({'Haut','Centre','Bas'})[tonumber(y)+1]..' · '..({'Gauche','Centre gauche','Centre droit','Droite'})[tonumber(x)+1]
            U.text(area..' : '..spot.deaths..' morts',150,495+(i-1)*29,'body',white)
        end
        U.button('Retour',440,630,320,40,function() Workshop.stats=nil end)
    elseif Workshop.publishing then
        if Workshop.editorProject then
            U.text(Worlds.names[Workshop.biome],125,190,'heading',white,400,'center')
            U.button('Retour à l’éditeur',125,270,400,48,function() Creator.open() end)
        else
        for i,biome in ipairs(Worlds.order) do
            U.button(Worlds.names[biome],125,167+(i-1)*58,400,48,function() Workshop.selectBiome(biome) end,Workshop.busy,Workshop.biome==biome)
        end end
        if Workshop.selected then
            U.button(T('Titre de la carte')..' : '..Workshop.title..(Workshop.focus=='title' and '|' or ''),560,167,510,48,function() Workshop.focus='title'; love.keyboard.setTextInput(true) end,false,false,nil,true)
            U.button(T('Pseudo : ')..Workshop.author..(Workshop.focus=='author' and '|' or ''),560,228,510,48,function() Workshop.focus='author'; love.keyboard.setTextInput(true) end,false,false,nil,true)
            U.workshopSelect('difficulty','Difficulté '..Workshop.difficulty..'/5',560,289,510,44)
            U.button('Modifier la carte',560,347,510,44,Workshop.edit,Workshop.busy)
            U.button('Terminer la carte pour la valider',560,405,510,48,Workshop.testPublication,Workshop.busy or Workshop.selected.saved==false)
            U.button('PUBLIER LA CARTE',560,466,510,48,Workshop.publish,Workshop.busy or not Workshop.canPublish(),true)
            U.button('Préparer pour Steam',560,527,510,48,Workshop.exportSteam,Workshop.busy or not Workshop.canPublish())
        end
        U.button('Retour au Workshop',400,650,400,38,Workshop.open)
    else
        U.button('Créer une carte',125,149,615,40,function() Creator.open() end,not Profile.hasCompleted(1))
        U.button('Actualiser',755,149,315,40,Workshop.refresh,Workshop.busy)
        U.workshopSelect('filterBiome',Workshop.filterBiome==0 and 'Tous les biomes' or Worlds.names[Workshop.filterBiome],125,198,300,40,true)
        U.workshopSelect('filterDifficulty',Workshop.filterDifficulty==0 and 'Toutes difficultés' or 'Difficulté '..Workshop.filterDifficulty,440,198,300,40,true)
        U.button(({stars='Les plus aimées',easy='Faciles → difficiles',hard='Difficiles → faciles'})[Workshop.sort],755,198,315,40,function() Workshop.filter('sort',({stars='easy',easy='hard',hard='stars'})[Workshop.sort]) end,Workshop.busy)
        for i,row in ipairs(Workshop.rows) do
            local y=244+(i-1)*39
            local locked=not Worlds.canEnter(row.biome or row.world)
            g.push('all')
            if locked then U.lockedMapShader=U.lockedMapShader or g.newShader('vec4 effect(vec4 c, Image t, vec2 uv, vec2 p){vec4 v=Texel(t,uv)*c;float l=dot(v.rgb,vec3(.299,.587,.114));return vec4(vec3(l*.65),v.a); }');g.setShader(U.lockedMapShader) end
            U.rawText(U.ellipsize(row.title,'body',310),130,y+8,'body',locked and muted or white)
            U.difficulty(row.difficulty,row.difficultyExtra,455,y+14)
            if row.owned then
                U.button('Statistiques',610,y,145,36,function() Workshop.statistics(row) end,Workshop.busy)
                U.button('Retirer',765,y,90,36,function() Workshop.removing=row end,Workshop.busy)
            else
                U.rawText(U.ellipsize(row.author..' · '..(locked and '???' or T(Worlds.names[row.biome or row.world] or '')),'body',240),610,y+8,'body',muted)
            end
            U.button('   '..row.stars,865,y,85,36,function() Workshop.star(row) end,row.voting or row.owned)
            U.voteStar(row,883,y+18)
            U.button('Jouer',965,y,105,36,function() Workshop.play(row) end,Workshop.busy or locked)
            g.pop()
        end
        U.button('Précédent',125,565,200,40,function() Workshop.page=Workshop.page-1; Workshop.refresh() end,Workshop.page<=1 or Workshop.busy)
        U.text('Page '..Workshop.page,460,576,'body',white,280,'center')
        U.button('Suivant',870,565,200,40,function() Workshop.page=Workshop.page+1; Workshop.refresh() end,not Workshop.hasMore or Workshop.busy)
        U.button('Retour',450,650,300,38,App.leaveCustom)
    end
    U.text(Workshop.status,125,609,'body',gold,945,'center')
    U.workshopDropdown()
end
function U.draw()
    U.buttons={}
    if App.state=='prologue' then require('prologue').ui();return end
    if App.state=='creatorConfirm' then Creator.draw();return end
    if App.state=='skinUnlock' then require('skin_unlock').draw();return end
    if App.state=='playing' then U.gameHud();if Replay and Replay.playing then Replay.controls() end;if Secret.duel and Secret.duel.kind=='mob' then U.text(Secret.duel.name..(Secret.duel.kind=='mob' and (' · Survie '..math.ceil(math.max(0,20-Secret.duel.time))..' s') or ' · Duel'),300,90,'body',white,600,'center') end;return end
    if App.state=='bossWorld' then Secret.draw();return end
    if App.state=='worlds' then U.theme() else U.background() end
    if App.state=='menu' then U.menu()
    elseif App.state=='history' then require('history').draw()
    elseif App.state=='quitConfirm' then
        U.menu()
        g.setColor(0,0,0,.7); g.rectangle('fill',0,0,1200,750)
        U.buttons={}
        U.panel(375,270,450,240)
        U.text('Quitter Silken Hell ?',395,304,'heading',white,410,'center')
        U.button('Rester',410,378,380,44,function() App.state='menu' end,false,true)
        U.button('Quitter le jeu',410,438,380,40,function() App.quitDelay=.4 end)
    elseif App.state=='workshop' then U.workshop()
    elseif App.state=='playerProfile' then require('player_profile').draw()
    elseif App.state=='statistics' then require('statistics').draw()
    elseif App.state=='achievements' then require('achievements_screen').draw()
    elseif App.state=='skins' then U.skins()
    elseif App.state=='topRecords' then require('top_records').draw()
    elseif App.state=='customVictory' then
        U.panel(300,235,600,350); U.text(Secret.duel and 'Duel terminé' or App.practice and 'Entraînement terminé' or 'Carte terminée',330,265,'heading',white,540,'center')
        U.text(U.time(Scoring.total(timer,player.death))..' · '..player.death..' morts ('..Scoring.label(player.death)..')',330,325,'body',gold,540,'center')
        if App.workshopMap then U.button('Donner une étoile',375,380,450,42,function() Workshop.star(App.workshopMap) end,App.workshopMap.starred) end
        U.button(App.preview and not App.historyPreview and 'Recharger les modifications' or 'Rejouer',375,441,450,42,App.preview and not App.historyPreview and PreviewBridge.reload or App.restartCurrent)
        U.button(Secret.duel and 'Retour au Sanctuaire' or App.practice and 'Retour aux mondes' or 'Retour au Workshop',375,497,450,42,function() if Workshop.validationRun then Workshop.resumePublication() elseif Secret.duel then Secret.open() elseif App.practice then App.leaveCustom();App.state='worlds' else App.leaveCustom(); Workshop.open() end end)
    elseif App.state=='entry' then U.entry()
    elseif App.state=='graphics' then Graphics.draw()
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
        local preview=App.preview and not App.historyPreview
        U.panel(390,355,420,(Secret.inArena() or preview) and 315 or 265); U.text('Un instant suspendu',410,378,'heading',white,380,'center')
        U.button('Reprendre',420,435,360,44,function() App.state='playing' end,false,true)
        U.button('Paramètres',420,490,360,40,function() App.state='settings'; U.returnTo='pause' end)
        U.button('Retour au menu',420,541,360,40,App.leaveCustom)
        if preview then U.button('Recharger les modifications',420,592,360,40,PreviewBridge.reload)
        elseif Secret.inArena() then U.button('Retour au Sanctuaire',420,592,360,40,Secret.returnToSanctuary) end
        if preview and PreviewBridge.error then U.text(PreviewBridge.error,200,686,'body',{1,.5,.35},800,'center') end
    elseif App.state=='victory' then
        require('victory_screen').draw()
    end
    if Profile.error then U.text(Profile.error,200,686,'small',{1,0.5,0.35},800,'center') end
end
function U.secretScissor()
    local w,h=g.getDimensions();local s=math.min(w/1200,h/750)
    return (w-1200*s)/2+70*s,(h-750*s)/2+220*s,1060*s,310*s
end
return U
