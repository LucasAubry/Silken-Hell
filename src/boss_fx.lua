local F={events={},states={},power=0,clock=0}
function F.reset() F.events={}; F.states={}; F.power=0; F.clock=0 end
function F.burst(x,y,color,power)
    if #F.events<32 then F.events[#F.events+1]={x=x,y=y,color=color or {1,.85,.55},age=0,power=power or 3} end
    F.power=math.min(6,math.max(F.power,power or 3))
end
function F.update(dt)
    F.clock=F.clock+dt; F.power=math.max(0,F.power-dt*16)
    for i=#F.events,1,-1 do local p=F.events[i]; p.age=p.age+dt; if p.age>.65 then table.remove(F.events,i) end end
    local list={Raven,Wasp,Hedgehog,Octopus,Storm}; if Abyss.boss then list[#list+1]=Abyss end
    for _,item in ipairs(Bosses.items) do list[#list+1]=item.boss end
    for _,b in ipairs(list) do if b.active then
        local previous=F.states[b]; local x,y=b.x or (b.head and b.head.x) or Arena.width/2,b.y or (b.head and b.head.y) or 280
        if previous then
            if b.hp<previous.hp then F.burst(x,y,b.hp==0 and {1,.9,.7} or {1,.24,.2},b.hp==0 and 6 or 4)
            elseif (b.bounces or 0)>previous.bounces then F.burst(x,y,{.85,.65,.35},3)
            elseif b.open and not previous.open then F.burst(x,y,{.3,.7,1},3)
            elseif b.rider and not previous.rider then F.burst(x,y,{.25,.8,1},2)
            elseif #(b.projectiles or {})-previous.projectiles>=3 and F.clock-previous.attack>.6 then F.burst(x,y,{.6,.75,1},1.2); previous.attack=F.clock
            elseif b.phase~=previous.phase and (b.phase=='landing' or b.phase=='rest') then F.burst(x,y,{.6,.85,1},2) end
        end
        F.states[b]={hp=b.hp,bounces=b.bounces or 0,phase=b.phase,open=b.open,rider=b.rider~=nil,projectiles=#(b.projectiles or {}),attack=previous and previous.attack or -1}
    end end
end
function F.offset() return math.sin(F.clock*59)*F.power,math.cos(F.clock*71)*F.power*.65 end
function F.draw()
    local g=love.graphics; g.push('all'); g.setBlendMode('add')
    for _,p in ipairs(F.events) do
        local t=math.min(1,p.age/.65);local c=p.color
        -- A quick outward snap eases into a short tail without adding camera shake.
        local spread=1-(1-t)^3;local fade=(1-t)^1.6
        g.setColor(c[1],c[2],c[3],fade*.42);g.setLineWidth(1.2)
        g.ellipse('line',p.x,p.y,14+spread*65,8+spread*38)
        local flash=math.max(0,1-p.age/.12)
        if flash>0 then
            local r=3+flash*(3+p.power)
            g.setColor(1,.95,.82,flash*.65)
            g.polygon('fill',p.x-r,p.y,p.x-2,p.y-2,p.x,p.y-r*.75,
                p.x+2,p.y-2,p.x+r,p.y,p.x+2,p.y+2,p.x,p.y+r*.75,p.x-2,p.y+2)
        end
        for i=1,12 do
            local a=i*math.pi/6+p.x*.01;local r=spread*(30+p.power*9)
            local x,y=p.x+math.cos(a)*r,p.y+math.sin(a)*r*.7
            local tail=(2+p.power)*math.max(0,1-t*2.5)
            g.setColor(c[1],c[2],c[3],fade*.65);g.setLineWidth(1)
            g.line(x-math.cos(a)*tail,y-math.sin(a)*tail*.7,x,y)
            g.setColor(c[1]*.65+.35,c[2]*.65+.35,c[3]*.65+.35,fade*.8)
            g.circle('fill',x,y,1.5*(1-t)+.3)
        end
    end
    g.pop()
end
return F
