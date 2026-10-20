local M={scroll=0,scrollTarget=0}
local g=love.graphics
local heights={170,380,590,800,1010,1220,1430,1640}
local monsters={[1]='merle',[6]='dragonfly',[5]='mole',[4]='fish',[7]='lanternfish',[2]='wasp',[3]='crown_spider',[8]='spider'}
local function point(i) return 365+math.sin((i-1)*1.35)*115,heights[i] end
local function camera(i) return math.max(0,math.min(1270,heights[i]-370)) end
function M.select(n,i)
    if not Worlds.canEnter(n) then return false end
    M.hardcore=false;UI.boardHardcore=false
    local x,y=point(i);M.route={{x=x,y=y}};M.arrival=nil
    App.selectedWorld=n;UI.boardWorld=n;M.target=i;M.viewIndex=i;M.scrollTarget=camera(i)
    return true
end
function M.branch(hardcore,silent)
    hardcore=hardcore==true
    if hardcore and not (App.selectedWorld==8 and Worlds.canEnter(8)) and not Hardcore.available(App.selectedWorld) then return false end
    if (M.hardcore==true)==hardcore then return true end
    M.hardcore=hardcore;UI.boardHardcore=hardcore;if not silent then Audio.play('go') end
    local x,y=point(M.target or 1)
    M.route={{x=x+(hardcore and 165 or 0),y=y}};M.arrival=nil
    return true
end
function M.open()
    local i=1;for index,n in ipairs(Worlds.selection) do if n==App.selectedWorld then i=index end end
    M.hardcore=M.hardcore and (App.selectedWorld==8 or Hardcore.available(App.selectedWorld)) or false;M.route={};M.arrival=nil
    M.scroll=camera(i);M.scrollTarget=M.scroll;M.target=i;M.viewIndex=i;M.x,M.y=point(i);M.x=M.x+(M.hardcore and 165 or 0)
    App.state='worlds'
end
function M.wheel(y) M.scrollTarget=math.max(0,math.min(1270,(M.scrollTarget or M.scroll)-y*125)) end
function M.step(direction,silent)
    local i=math.max(1,math.min(#Worlds.selection,(M.viewIndex or M.target or 1)+direction))
    if i==M.viewIndex then return end
    M.viewIndex=i;M.scrollTarget=camera(i)
    local n=Worlds.selection[i]
    if Worlds.canEnter(n) then M.select(n,i);if not silent then Audio.play('go') end end
end
function M.update(dt)
    local blend=1-math.exp(-8*math.max(0,dt))
    local scrollTarget=M.route and M.route[1] and M.route[1].holdCamera and M.scroll or (M.scrollTarget or M.scroll)
    M.scroll=M.scroll+(scrollTarget-M.scroll)*blend
    if math.abs(M.scroll-(M.scrollTarget or M.scroll))<.05 then M.scroll=M.scrollTarget end
    local distance=650*math.max(0,dt)
    while M.route and #M.route>0 do
        local p=M.route[1];local dx,dy=p.x-M.x,p.y-M.y;local length=math.sqrt(dx*dx+dy*dy)
        if length<=distance then
            M.x,M.y=p.x,p.y;distance=distance-length;table.remove(M.route,1)
            if #M.route==0 then M.arrival={x=p.x,y=p.y,at=UI.clock} end
        else M.x=M.x+dx/length*distance;M.y=M.y+dy/length*distance;break end
    end
end
function M.drawBackground(w,h)
    local scale=math.min(w/1200,h/750);local edge=w
    g.push('all');g.setColor(.008,.011,.015);g.rectangle('fill',0,0,w,h);g.setScissor()
    M.backgroundShader=M.backgroundShader or g.newShader('assets/shaders/world_map.glsl');M.backgroundShader:send('clock',UI.clock);M.backgroundShader:send('mapHeight',h/scale);M.backgroundShader:send('viewTop',(h/scale-750)/2);M.backgroundShader:send('scroll',M.scroll);local stops={};for _,n in ipairs(Worlds.selection) do stops[#stops+1]=Worlds.color(n).floor end;M.backgroundShader:send('stops',unpack(stops));g.setShader(M.backgroundShader);g.setColor(1,1,1);g.draw(UI.pixel,0,0,0,edge,h);g.setShader()
    local tint=Worlds.color(App.selectedWorld or 1).tear
    for layer=1,7 do
        local vertices={0,0}
        for row=0,24 do local y=h*row/24;local depth=y/scale+M.scroll*.18
            local x=edge*(.07+layer*.022)+math.sin(depth*.004+layer*.63)*edge*.032
            vertices[#vertices+1]=x;vertices[#vertices+1]=y
        end
        vertices[#vertices+1]=0;vertices[#vertices+1]=h
        g.setColor(tint[1]*.12,tint[2]*.15,tint[3]*.18,.3);g.polygon('fill',vertices)
        g.setColor(tint[1]*.55+.2,tint[2]*.55+.2,tint[3]*.55+.2,.08);g.setLineWidth(scale);g.line(vertices)
        g.push();g.translate(edge,0);g.scale(-1,1);g.setColor(tint[1]*.12,tint[2]*.15,tint[3]*.18,.3);g.polygon('fill',vertices);g.setColor(.6,.72,.7,.07);g.line(vertices);g.pop()
    end
    for i=1,48 do local x=(i*137.3)%math.max(1,edge);local y=(i*79.7-M.scroll*.13+UI.clock*(2+i%3))%h
        g.setColor(.9,.84,.57,.12+.12*math.sin(i+UI.clock));g.circle('fill',x,y,1.1*scale)
    end
    g.pop()
end
-- Soften only the circle underneath the marker, using its actual animated position.
local function occupancy(x,y)
    local dx,dy=(M.x or -1000)-x,(M.y or -1000)-M.scroll-y
    return math.max(0,1-math.sqrt(dx*dx+dy*dy)/26)
end
local function circle(mode,x,y,r,color,soft)
    g.setColor(color)
    if soft<.01 then g.circle(mode,x,y,r);return end
    M.circleShader=M.circleShader or g.newShader([[
        extern float radius;
        extern float softness;
        extern float filled;
        vec4 effect(vec4 color, Image image, vec2 uv, vec2 screen) {
            float d=length((uv-.5)*104.);
            float edge=d-radius;
            float ring=exp(-.5*edge*edge/(softness*softness))*min(1.,1.3/softness);
            float disk=1.-smoothstep(-softness*1.8,softness*1.8,edge);
            return vec4(color.rgb,color.a*mix(ring,disk,filled));
        }
    ]])
    g.push('all');g.setShader(M.circleShader)
    M.circleShader:send('radius',r);M.circleShader:send('softness',.7+soft*3.8)
    M.circleShader:send('filled',mode=='fill' and 1 or 0)
    g.draw(UI.pixel,x-52,y-52,0,104,104);g.pop()
end
local function markerMob(name,dir,x,y)
    if name=='dragonfly' then return require('sky_insect_art').draw(name,x,y,44,UI.clock) end
    local a=Art.images[name..'_'..dir]
    local min,mag,anisotropy=a.image:getFilter();local mip,bias=a.image:getMipmapFilter()
    a.image:setFilter('nearest','nearest');a.image:setMipmapFilter()
    g.setColor(1,1,1);local scale=44/math.max(a.w,a.h)
    local shader=g.getShader();if name=='fish' then Art.fishPalette() end
    g.draw(a.image,a.quad,x,y,0,scale,scale,a.w/2,a.h/2);g.setShader(shader)
    a.image:setFilter(min,mag,anisotropy);a.image:setMipmapFilter(mip,bias)
end
local function node(n,i,x,y)
    local c=Worlds.color(n);local locked=not Worlds.canEnter(n)
    if locked then
        require('map_cocoon').draw(x,y,n,UI.clock)
        return
    end
    for r=5,1,-1 do g.setColor(c.tear[1],c.tear[2],c.tear[3],.018);g.ellipse('fill',x,y,42+r*12,24+r*7) end
    -- A layered stone medallion gives each stop a physical place on the route.
    g.setColor(.004,.008,.015,.75);g.ellipse('fill',x,y+18,45,18)
    g.setColor(c.floor[1]*.6+.035,c.floor[2]*.6+.035,c.floor[3]*.6+.035)
    g.polygon('fill',x-38,y+2,x-26,y-22,x+26,y-22,x+38,y+2,x+25,y+25,x-25,y+25)
    g.setColor(c.tear[1],c.tear[2],c.tear[3],.30);g.setLineWidth(1)
    g.line(x-38,y+2,x-26,y-22,x+26,y-22,x+38,y+2)
    local soft=occupancy(x,y)
    circle('fill',x,y,24,{.015,.035,.045,.95},soft)
    g.setLineWidth(2);circle('line',x,y,24,{c.tear[1]*.5+.5,c.tear[2]*.5+.5,c.tear[3]*.5+.5,1},soft)
    if n==App.selectedWorld and not M.hardcore then
        circle('line',x,y,31,{1,.85,.48,.3+.15*math.sin(UI.clock*2)},soft)
    elseif Profile.hasCompleted(n) then g.setColor(1,.87,.55);g.line(x-8,y,x-2,y+6,x+10,y-7)
    else g.setColor(1,.91,.65);g.circle('fill',x,y,5) end
    g.setLineWidth(1)
    local labelX=math.max(48,x-265)
    local labelW=x-54-labelX;local selected=n==App.selectedWorld
    local ink=selected and {.99,.92,.72} or {.77,.80,.77}
    -- Names sit on the route itself, with a fine illuminated underline.
    UI.text(Worlds.names[n],labelX+1,y-12,'medium',{0,.005,.012,.85},labelW,'right')
    UI.text(Worlds.names[n],labelX,y-14,'medium',ink,labelW,'right')
    local lineEnd=x-54;local lineStart=lineEnd-math.min(labelW,selected and 118 or 68)
    g.setColor(c.tear[1],c.tear[2],c.tear[3],selected and .85 or .35)
    g.line(lineStart,y+18,lineEnd,y+18)
    local tip=lineEnd+9;local size=selected and 3 or 2
    g.setColor(ink[1],ink[2],ink[3],selected and .95 or .5)
    g.polygon('fill',tip-size,y+18,tip,y+18-size,tip+size,y+18,tip,y+18+size)
    if Profile.flawless(n) then require('flawless_badge').draw(x+32,y+25,12) end
    do local a=math.sin(UI.clock*.5)*.15
        local xx,yy=x+63,y-34+math.sin(UI.clock+i)*3
        if n==3 then
            g.setColor(1,1,1);require('final_art').spider('queen',xx,yy,44,a)
        else markerMob(monsters[n],Art.direction(-math.sin(a),math.cos(a)),xx,yy) end
    end
    UI.buttons[#UI.buttons+1]={x=labelX-6,y=math.max(125,y-35),w=x+40-labelX+6,h=math.max(0,math.min(680,y+35)-math.max(125,y-35)),run=function() M.select(n,i);M.branch(false,true) end,sound='go'}
end
function M.draw()
    -- Render the route separately so cocoons and paths fade out at the viewport edges.
    local previousCanvas=g.getCanvas()
    M.routeCanvas=M.routeCanvas or g.newCanvas(730,750)
    M.routeCanvas:setFilter('nearest','nearest')
    g.push('all');g.setCanvas(M.routeCanvas);g.origin();g.setScissor();g.clear(0,0,0,0)
    g.setScissor(35,0,695,750)
    local lastX,lastY
    for i,n in ipairs(Worlds.selection) do
        local x,y=point(i);y=y-M.scroll
        if lastX then
            for j=1,42 do local t=j/42;local ease=t*t*(3-2*t)
                g.setColor(1,.9,.62,Worlds.canEnter(n) and .68 or .15)
                g.circle('fill',lastX+(x-lastX)*ease,lastY+(y-lastY)*t,1.5)
            end
        end
        lastX,lastY=x,y
        if y>-100 and y<820 then
            node(n,i,x,y)
            if Worlds.canEnter(n) and (n==8 or Hardcore.unlocked()) then
                local available=n==8 or Hardcore.available(n)
                for j=1,12 do local t=j/13;g.setColor(.95,.65,.36,available and .6 or .18);g.circle('fill',x+165*t,y-18*math.sin(t*math.pi),1.5) end
                local bx=x+165
                if not Art.images.hardcore_skull then Art.add('hardcore_skull','assets/sprites/hardcore_skull.png') end
                if M.hardcore and n==App.selectedWorld then g.setLineWidth(1.5);circle('line',bx,y,31,{1,.8,.45,.65},occupancy(bx,y)) end
                g.setColor(1,1,1,available and 1 or .28);local icon=Art.images.hardcore_skull;Art.draw('hardcore_skull',bx,y,54*icon.w/math.max(icon.w,icon.h)*(Graphics.effects and (1+.035*math.sin(UI.clock*1.8+i*.5)) or 1))
                if available and y>=145 and y<=638 then UI.buttons[#UI.buttons+1]={x=bx-28,y=y-28,w=56,h=80,run=function() M.select(n,i);M.branch(true,true) end,sound='go'} end
            end
        end
    end
    local arrival=M.arrival;local age=arrival and UI.clock-arrival.at or 1
    if Graphics.effects and age>=0 and age<.4 then
        local t=age/.4;local c=M.hardcore and {1,.24,.12} or Worlds.color(App.selectedWorld).tear
        g.setColor(c[1],c[2],c[3],(1-t)*.65);g.setLineWidth(2*(1-t)+.5)
        g.circle('line',arrival.x,arrival.y-M.scroll,27+21*(1-(1-t)^3));g.setLineWidth(1)
    end
    local markerX,markerY=M.x or 365,(M.y or 210)-M.scroll
    g.setColor(1,1,1);Characters.draw(markerX,markerY,64,'down',nil,App.selectedWorld)
    if App.selectedWorld==4 or App.selectedWorld==7 then
        local bubble=require('breathing_bubble')
        local x,y,r=bubble.headPosition(markerX,markerY,64,'down')
        if require('integrated_skins').bubble(Characters.selected()) then
            if App.selectedWorld==7 then bubble.drawLantern(x,y,r,UI.clock,nil,nil,'down') end
        else bubble.drawAt(x,y,r,UI.clock,App.selectedWorld==7,nil,nil,nil,'down') end
    end
    g.setCanvas(previousCanvas);g.pop()
    M.edgeShader=M.edgeShader or g.newShader([[
        vec4 effect(vec4 color,Image image,vec2 uv,vec2 screen) {
            float y=uv.y*750.;
            float fade=smoothstep(0.,125.,y)*(1.-smoothstep(655.,750.,y));
            return Texel(image,uv)*color*fade;
        }
    ]])
    g.push('all');g.setShader(M.edgeShader);g.setColor(1,1,1)
    g.setBlendMode('alpha','premultiplied');g.draw(M.routeCanvas);g.pop()
    -- The selected biome has a framed diorama and a compact, readable control stack.
    local n=App.selectedWorld;local unlocked=Worlds.canEnter(n)
    local palette=Worlds.color(n==8 and 7 or n).tear
    local accent=M.hardcore and {1,.40,.24} or palette
    g.setColor(.004,.009,.015,.52);g.rectangle('fill',763,131,388,535,12,12)
    g.setColor(.015,.025,.035,.95);g.rectangle('fill',756,124,388,532,10,10)
    g.setColor(accent[1],accent[2],accent[3],.5);g.setLineWidth(1);g.rectangle('line',756,124,388,532,10,10)
    g.setColor(.94,.85,.63,.8);g.line(780,124,1120,124)
    UI.text('LES MONDES',64,65,'heading',{.94,.88,.72})
    UI.text(Worlds.displayName(n),778,145,'heading',{.97,.91,.76},344,'center')
    UI.button('↑',64,685,62,38,function() M.step(-1,true) end,false,false,'go')
    UI.button('↓',138,685,62,38,function() M.step(1,true) end,false,false,'go')
    g.setColor(.95,.84,.59,.15);g.rectangle('fill',733,195,2,390)
    g.setColor(accent[1],accent[2],accent[3],.85);g.rectangle('fill',731,195+M.scroll/1270*356,6,34,3,3)
    local hardcoreAvailable=n==8 and unlocked or Hardcore.available(n)
    UI.button('Classique',780,190,163,34,function()M.branch(false)end,false,not M.hardcore)
    UI.button('Hardcore',953,190,163,34,function()M.branch(true)end,not hardcoreAvailable,M.hardcore)
    require('world_preview').draw(n,780,238,336,148,M.hardcore)
    local best=Profile.ranking(n,nil,M.hardcore)[1]
    UI.text(best and ('Record  '..UI.time(best.time)..'  ·  '..best.deaths..' morts') or 'Aucun record',780,398,'body',{.86,.86,.80},336,'center')
    if n~=8 then
        UI.text(M.hardcore and 'Parcours complet' or 'Entraînement',780,437,'body',{.94,.85,.65},336,'center')
        if M.hardcore then
            UI.text('Chaque mort fait reculer\nd’un niveau.',790,478,'body',{.82,.82,.78},316,'center')
        else
            for level=1,Worlds.levelCount(n) do
                local available=unlocked and level<=((Profile.levels or {})[n] or 1)
                UI.button(available and tostring(level) or '—',790+(level-1)%5*64,471+math.floor((level-1)/5)*42,55,34,function()App.practiceLevel(n,level)end,not available,false,'selection')
            end
        end
    else
        UI.text(M.hardcore and 'Les sept boss à la suite' or 'Créatures et boss découverts',780,445,'body',{.94,.85,.65},336,'center')
        local index=Characters.selected();g.setColor(1,1,1);Characters.portrait(index,948,513,66,'down')
    end
    UI.button(n==8 and 'Entrer au Sanctuaire' or M.hardcore and 'Jouer en hardcore' or 'Jouer',790,587,320,46,function()App.openEntry(n,M.hardcore)end,not unlocked,true,'selection')
    UI.button('Retour',850,685,260,38,function() UI.boardHardcore=M.hardcore;App.state='menu' end)
end
return M
