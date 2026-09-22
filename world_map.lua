local M={scroll=0,scrollTarget=0}
local g=love.graphics
local heights={170,550,955,1340,1760,2200,2660,3210}
local monsters={[1]='merle',[6]='gull',[5]='mole',[4]='fish',[7]='lanternfish',[2]='wasp',[3]='crown_spider',[8]='spider'}
local function point(i) return 365+math.sin((i-1)*1.35)*115,heights[i] end
local function camera(i) return math.max(0,math.min(2850,heights[i]-350)) end
function M.select(n,i)
    if not Worlds.canEnter(n) then return end
    App.selectedWorld=n;UI.boardWorld=n;M.target=i;M.viewIndex=i;M.scrollTarget=camera(i)
end
function M.open()
    local i=1;for index,n in ipairs(Worlds.selection) do if n==App.selectedWorld then i=index end end
    M.scroll=camera(i);M.scrollTarget=M.scroll;M.target=i;M.viewIndex=i;M.x,M.y=point(i)
    App.state='worlds'
end
function M.wheel(y) M.scrollTarget=math.max(0,math.min(2850,(M.scrollTarget or M.scroll)-y*125)) end
function M.step(direction)
    local i=math.max(1,math.min(#Worlds.selection,(M.viewIndex or M.target or 1)+direction))
    if i==M.viewIndex then return end
    M.viewIndex=i;M.scrollTarget=camera(i)
    local n=Worlds.selection[i]
    if Worlds.canEnter(n) then M.select(n,i);Audio.play('go') end
end
function M.update(dt)
    local blend=1-math.exp(-8*math.max(0,dt))
    M.scroll=M.scroll+((M.scrollTarget or M.scroll)-M.scroll)*blend
    if math.abs(M.scroll-(M.scrollTarget or M.scroll))<.05 then M.scroll=M.scrollTarget end
    local x,y=point(M.target or 1)
    M.x=(M.x or x)+(x-(M.x or x))*blend;M.y=(M.y or y)+(y-(M.y or y))*blend
end
function M.drawBackground(w,h)
    M.backdrop=M.backdrop or g.newImage('assets/sprites/world_descent.png')
    local uiScale=math.min(w/1200,h/750)
    local edge=(w-1200*uiScale)/2+744*uiScale
    local scale=math.max(w/1200,h/750);local imageScale=1200*scale/M.backdrop:getWidth()
    g.push('all')
    g.setColor(.008,.011,.015,1);g.rectangle('fill',0,0,w,h)
    g.setScissor(0,0,edge,h)
    g.setColor(1,1,1);g.draw(M.backdrop,(w-1200*scale)/2,(h-750*scale)/2-M.scroll*scale,0,imageScale,imageScale)
    g.setColor(.015,.025,.035,.23);g.rectangle('fill',0,0,edge,h)
    g.pop()
end
local function node(n,i,x,y)
    local c=Worlds.color(n);local locked=not Worlds.canEnter(n)
    if locked then
        g.setColor(.72+c.tear[1]*.28,.72+c.tear[2]*.28,.75+c.tear[3]*.25,.98)
        Art.draw('map_cloud',x+math.sin(UI.clock*.25+n)*5,y,420,0,165)
        UI.text('?',x-20,y-12,'heading',{.92,.94,1},40,'center')
        return
    end
    for j=1,2 do local a=UI.clock*.25+j*math.pi
        g.setColor(1,1,1,.9);Art.drawFacing(monsters[n],Art.direction(-math.sin(a),math.cos(a)),x+math.cos(a)*105,y+math.sin(a)*38,38)
    end
    g.setColor(.015,.035,.045,.85);g.circle('fill',x,y,24)
    g.setColor(c.tear[1]*.5+.5,c.tear[2]*.5+.5,c.tear[3]*.5+.5,1);g.setLineWidth(2);g.circle('line',x,y,24)
    if n==App.selectedWorld then
        g.setColor(1,.85,.48,.3+.15*math.sin(UI.clock*2));g.circle('line',x,y,31)
    elseif Profile.hasCompleted(n) then g.setColor(1,.87,.55);g.line(x-8,y,x-2,y+6,x+10,y-7)
    else g.setColor(1,.91,.65);g.circle('fill',x,y,5) end
    g.setLineWidth(1)
    g.setColor(.015,.025,.035,.8);g.rectangle('fill',x-145,y+39,290,43,8,8)
    UI.text(Worlds.names[n],x-140,y+48,'medium',{.97,.90,.72},280,'center')
    UI.buttons[#UI.buttons+1]={x=x-135,y=math.max(125,y-35),w=270,h=math.max(0,math.min(680,y+83)-math.max(125,y-35)),run=function() M.select(n,i) end,sound='go'}
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
        if y>-100 and y<820 then node(n,i,x,y) end
    end
    g.setColor(1,1,1);Characters.draw(M.x or 365,(M.y or 210)-M.scroll-17,62,'down')
    g.setScissor();g.pop()
    -- Floating controls leave the painted terrain visible across the entire screen.
    g.setColor(.015,.025,.035,.83);g.rectangle('fill',45,32,670,85,12,12)
    UI.text('LA DESCENTE',68,48,'heading',{.98,.90,.71})
    UI.text('Un fil à suivre, un monde à découvrir.',70,88,'small',{.77,.81,.82})
    g.setColor(.015,.025,.035,.88);g.rectangle('fill',756,136,388,510,16,16)
    g.setColor(.86,.74,.49,.45);g.rectangle('line',756,136,388,510,16,16)
    UI.button('Haut',653,151,62,40,function() M.step(-1) end)
    UI.button('Bas',653,620,62,40,function() M.step(1) end)
    g.setColor(.95,.84,.59,.2);g.rectangle('fill',733,195,2,390)
    g.setColor(.95,.84,.59,.9);g.rectangle('fill',730,195+M.scroll/2850*356,8,34,4,4)
    local n=App.selectedWorld;local unlocked=Worlds.canEnter(n)
    UI.text(Worlds.displayName(n),784,169,'heading',{.95,.85,.65},330,'center')
    local best=Profile.ranking(n)[1]
    UI.text(best and ('Record : '..UI.time(best.time)..'\n'..best.deaths..' morts') or 'Aucun parcours terminé',785,227,'body',{.75,.78,.81},330,'center')
    if n~=8 then
        local index=Worlds.rank(n)+5;g.setColor(1,1,1);Characters.portrait(index,950,331,74*(1+.025*math.sin(UI.clock*2)),'down',not Characters.unlocked(index))
        UI.text(Characters.unlocked(index) and ('Skin obtenu : '..Characters.names[index]) or 'Termine le monde pour gagner ce skin',780,377,'small',{.73,.74,.78},340,'center')
        UI.text('ENTRAÎNEMENT · sans classement',780,427,'small',{.89,.78,.52},340,'center')
        for level=1,Worlds.levelCount(n) do
            local available=unlocked and level<=((Profile.levels or {})[n] or 1)
            UI.button(available and tostring(level) or '—',790+(level-1)%5*64,461+math.floor((level-1)/5)*42,55,34,function() App.practiceLevel(n,level) end,not available)
        end
    else UI.text('Toutes les rencontres réunies.\nUne porte ouvre le mode démon.',790,320,'body',{.75,.78,.81},320,'center') end
    UI.button(n==8 and 'Entrer au Sanctuaire' or 'Commencer le monde',790,578,320,45,function() App.openEntry(n) end,not unlocked,true)
    g.setColor(.015,.025,.035,.8);g.rectangle('fill',45,688,670,38,8,8)
    UI.text('Flèches : changer de monde     ·     Molette : explorer',65,700,'small',{.85,.87,.84})
    UI.button('Retour',850,685,260,38,function() App.state='menu' end)
end
return M
