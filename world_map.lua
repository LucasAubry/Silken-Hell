local M={scroll=0,scrollTarget=0}
local g=love.graphics
local heights={170,380,590,800,1010,1220,1430,1640}
local monsters={[1]='merle',[6]='gull',[5]='mole',[4]='fish',[7]='lanternfish',[2]='wasp',[3]='crown_spider',[8]='spider'}
local function point(i) return 365+math.sin((i-1)*1.35)*115,heights[i] end
local function camera(i) return math.max(0,math.min(1270,heights[i]-370)) end
function M.select(n,i)
    if not Worlds.canEnter(n) then return false end
    M.route=M.route or {}
    if M.hardcore then
        local x,y=point(M.target or 1)
        M.route[#M.route+1]={x=x,y=y,holdCamera=true}
    end
    M.hardcore=false
    local x,y=point(i);M.route[#M.route+1]={x=x,y=y}
    App.selectedWorld=n;UI.boardWorld=n;M.target=i;M.viewIndex=i;M.scrollTarget=camera(i)
    return true
end
function M.branch(hardcore)
    hardcore=hardcore==true
    if App.selectedWorld==8 or (hardcore and not Hardcore.available(App.selectedWorld)) then return false end
    if (M.hardcore==true)==hardcore then return true end
    M.hardcore=hardcore;Audio.play('selection')
    local x,y=point(M.target or 1);M.route=M.route or {}
    M.route[#M.route+1]={x=x+(hardcore and 165 or 0),y=y}
    return true
end
function M.open()
    local i=1;for index,n in ipairs(Worlds.selection) do if n==App.selectedWorld then i=index end end
    M.hardcore=M.hardcore and Hardcore.available(App.selectedWorld) or false;M.route={}
    M.scroll=camera(i);M.scrollTarget=M.scroll;M.target=i;M.viewIndex=i;M.x,M.y=point(i);M.x=M.x+(M.hardcore and 165 or 0)
    App.state='worlds'
end
function M.wheel(y) M.scrollTarget=math.max(0,math.min(1270,(M.scrollTarget or M.scroll)-y*125)) end
function M.step(direction,silent)
    local i=math.max(1,math.min(#Worlds.selection,(M.viewIndex or M.target or 1)+direction))
    if i==M.viewIndex then return end
    M.viewIndex=i;M.scrollTarget=camera(i)
    local n=Worlds.selection[i]
    if Worlds.canEnter(n) then M.select(n,i);if not silent then Audio.play('selection') end end
end
function M.update(dt)
    local blend=1-math.exp(-8*math.max(0,dt))
    local scrollTarget=M.route and M.route[1] and M.route[1].holdCamera and M.scroll or (M.scrollTarget or M.scroll)
    M.scroll=M.scroll+(scrollTarget-M.scroll)*blend
    if math.abs(M.scroll-(M.scrollTarget or M.scroll))<.05 then M.scroll=M.scrollTarget end
    local distance=650*math.max(0,dt)
    while M.route and #M.route>0 do
        local p=M.route[1];local dx,dy=p.x-M.x,p.y-M.y;local length=math.sqrt(dx*dx+dy*dy)
        if length<=distance then M.x,M.y=p.x,p.y;distance=distance-length;table.remove(M.route,1)
        else M.x=M.x+dx/length*distance;M.y=M.y+dy/length*distance;break end
    end
end
function M.drawBackground(w,h)
    local scale=math.min(w/1200,h/750);local edge=w
    g.push('all');g.setColor(.008,.011,.015);g.rectangle('fill',0,0,w,h);g.setScissor()
    M.backgroundShader=M.backgroundShader or g.newShader('assets/world_map.glsl');M.backgroundShader:send('clock',UI.clock);M.backgroundShader:send('mapHeight',h/scale);M.backgroundShader:send('viewTop',(h/scale-750)/2);M.backgroundShader:send('scroll',M.scroll);local stops={};for _,n in ipairs(Worlds.selection) do stops[#stops+1]=Worlds.color(n).floor end;M.backgroundShader:send('stops',unpack(stops));g.setShader(M.backgroundShader);g.setColor(1,1,1);g.draw(UI.pixel,0,0,0,edge,h);g.setShader()
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
local function node(n,i,x,y)
    local c=Worlds.color(n);local locked=not Worlds.canEnter(n)
    if locked then
        g.setColor(.72+c.tear[1]*.28,.72+c.tear[2]*.28,.75+c.tear[3]*.25,.98)
        Art.draw('map_cloud',x+math.sin(UI.clock*.25+n)*5,y,420,0,165)
        UI.text('?',x-20,y-12,'heading',{.92,.94,1},40,'center')
        return
    end
    for r=5,1,-1 do g.setColor(c.tear[1],c.tear[2],c.tear[3],.018);g.ellipse('fill',x,y,42+r*12,24+r*7) end
    local soft=occupancy(x,y)
    circle('fill',x,y,24,{.015,.035,.045,.95},soft)
    g.setLineWidth(2);circle('line',x,y,24,{c.tear[1]*.5+.5,c.tear[2]*.5+.5,c.tear[3]*.5+.5,1},soft)
    if n==App.selectedWorld and not M.hardcore then
        circle('line',x,y,31,{1,.85,.48,.3+.15*math.sin(UI.clock*2)},soft)
    elseif Profile.hasCompleted(n) then g.setColor(1,.87,.55);g.line(x-8,y,x-2,y+6,x+10,y-7)
    else g.setColor(1,.91,.65);g.circle('fill',x,y,5) end
    g.setLineWidth(1)
    local labelX=math.max(48,x-245)
    g.setColor(.015,.025,.035,.96);g.rectangle('fill',labelX-6,y-20,187,40,8,8)
    UI.text(Worlds.names[n],labelX,y-10,'medium',{.97,.90,.72},175,'right')
    for j=1,2 do local a=UI.clock*.25+j*math.pi
        g.setColor(1,1,1,.9);Art.drawFacing(monsters[n],Art.direction(-math.sin(a),math.cos(a)),x+math.cos(a)*76,y+math.sin(a)*29,38)
    end
    UI.buttons[#UI.buttons+1]={x=labelX-6,y=math.max(125,y-35),w=x+40-labelX+6,h=math.max(0,math.min(680,y+35)-math.max(125,y-35)),run=function() M.select(n,i);M.branch(false) end,sound='selection'}
end
function M.draw()
    g.push('all')
    local sx,sy=g.transformPoint(35,125);local ex,ey=g.transformPoint(730,680);g.setScissor(sx,sy,ex-sx,ey-sy)
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
            if n~=8 and Worlds.canEnter(n) and Hardcore.unlocked() then
                local available=Hardcore.available(n)
                for j=1,12 do local t=j/13;g.setColor(.95,.65,.36,available and .6 or .18);g.circle('fill',x+165*t,y-18*math.sin(t*math.pi),1.5) end
                local bx=x+165
                if not Art.images.hardcore_skull then Art.add('hardcore_skull','assets/sprites/hardcore_skull.png') end
                if M.hardcore and n==App.selectedWorld then g.setLineWidth(1.5);circle('line',bx,y,31,{1,.8,.45,.65},occupancy(bx,y)) end
                g.setColor(1,1,1,available and 1 or .28);local icon=Art.images.hardcore_skull;Art.draw('hardcore_skull',bx,y,54*icon.w/math.max(icon.w,icon.h))
                if available and y>=145 and y<=638 then UI.buttons[#UI.buttons+1]={x=bx-28,y=y-28,w=56,h=80,run=function() M.select(n,i);M.branch(true) end,sound='selection'} end
            end
        end
    end
    g.setColor(1,1,1);Characters.draw(M.x or 365,(M.y or 210)-M.scroll,64,'down')
    g.setScissor();g.pop()
    -- Floating controls leave the painted terrain visible across the entire screen.
    g.setColor(.015,.025,.035,.83);g.rectangle('fill',45,32,670,85,12,12)
    UI.text('LA DESCENTE',68,48,'heading',{.98,.90,.71})
    UI.text('Un fil à suivre, un monde à découvrir.',70,88,'small',{.77,.81,.82})
    g.setColor(.015,.025,.035,.88);g.rectangle('fill',756,136,388,510,16,16)
    g.setColor(.86,.74,.49,.45);g.rectangle('line',756,136,388,510,16,16)
    UI.button('Haut',55,151,62,40,function() M.step(-1,true) end,false,false,'selection')
    UI.button('Bas',55,620,62,40,function() M.step(1,true) end,false,false,'selection')
    g.setColor(.95,.84,.59,.2);g.rectangle('fill',733,195,2,390)
    g.setColor(.95,.84,.59,.9);g.rectangle('fill',730,195+M.scroll/1270*356,8,34,4,4)
    local n=App.selectedWorld;local unlocked=Worlds.canEnter(n)
    UI.text(Worlds.displayName(n),784,169,'heading',{.95,.85,.65},330,'center')
    if M.hardcore then UI.text('HARDCORE',784,207,'small',{1,.72,.42},330,'center') end
    local best=Profile.ranking(n)[1]
    UI.text(M.hardcore and 'Chaque mort te fait reculer d’un niveau.\nMinimum : niveau 1.' or best and ('Record : '..UI.time(best.time)..'\n'..best.deaths..' morts') or 'Aucun parcours terminé',785,M.hardcore and 242 or 227,'body',{.75,.78,.81},330,'center')
    if n~=8 then
        local index=Worlds.rank(n)+5;g.setColor(1,1,1);Characters.portrait(index,950,331,74*(1+.025*math.sin(UI.clock*2)),'down',not Characters.unlocked(index))
        UI.text(Characters.unlocked(index) and ('Skin obtenu : '..Characters.names[index]) or 'Termine le monde pour gagner ce skin',780,377,'small',{.73,.74,.78},340,'center')
        UI.text(M.hardcore and 'Parcours complet · départ au niveau 1' or 'ENTRAÎNEMENT · sans classement',780,427,'small',{.89,.78,.52},340,'center')
        for level=1,(M.hardcore and 0 or Worlds.levelCount(n)) do
            local available=unlocked and level<=((Profile.levels or {})[n] or 1)
            UI.button(available and tostring(level) or '—',790+(level-1)%5*64,461+math.floor((level-1)/5)*42,55,34,function() App.practiceLevel(n,level) end,not available,false,'selection')
        end
    else UI.text('Toutes les rencontres réunies.\nUne porte ouvre le mode démon.',790,320,'body',{.75,.78,.81},320,'center') end
    if n~=8 and not M.hardcore and not Hardcore.available(n) then UI.text(Hardcore.unlocked() and 'Hardcore : termine ce monde.' or 'Hardcore : termine Terre (monde 3).',785,548,'small',{.82,.71,.51},330,'center') end
    UI.button(n==8 and 'Entrer au Sanctuaire' or M.hardcore and 'Commencer en hardcore' or 'Commencer le monde',790,578,320,45,function() App.openEntry(n,M.hardcore) end,not unlocked,true,'selection')
    g.setColor(.015,.025,.035,.8);g.rectangle('fill',45,688,670,38,8,8)
    UI.text('Haut / Bas : monde   ·   Droite : hardcore   ·   Gauche : normal',65,700,'small',{.85,.87,.84})
    UI.button('Retour',850,685,260,38,function() App.state='menu' end)
end
return M
