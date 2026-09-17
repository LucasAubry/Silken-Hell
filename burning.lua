local B={trails={},clock=0}
function B.reset() B.trails={}; B.clock=0 end
function B.update(dt)
    B.clock=B.clock+dt
    for i=#B.trails,1,-1 do local p=B.trails[i]; p.life=p.life-dt; if p.life<=0 then table.remove(B.trails,i) end end
    for _,m in ipairs(mobs) do
        if not m.ground and m.type~='piege' and m.type~='scie' and not m.abyssHeld and not m.spent then
            local inLava=false
            for _,p in ipairs(Hazards.lava) do if Hazards.inEllipse(m.x,m.y,p,0) then inLava=true; break end end
            m.burnTime=inLava and 5 or math.max(0,(m.burnTime or 0)-dt)
            if m.burnTime>0 then
                m.burnTrail=(m.burnTrail or 0)-dt
                if m.burnTrail<=0 then
                    m.burnTrail=.12
                    if #B.trails>=384 then table.remove(B.trails,1) end
                    B.trails[#B.trails+1]={x=m.x,y=m.y,life=2.8,seed=B.clock+m.x}
                end
            end
        end
    end
    B.contact()
end
function B.contact()
    for _,p in ipairs(B.trails) do
        if (player.x+15-p.x)^2+(player.y+12-p.y)^2<(12*math.min(1,p.life/.4)+8)^2 then Hazards.kill(); return end
    end
end
local function flame(x,y,size,seed,alpha)
    local g=love.graphics
    local sway=math.sin(B.clock*11+seed)*size*.22
    g.setColor(1,.16,.015,alpha*.8); g.ellipse('fill',x,y,size,size*.55)
    g.polygon('fill',x-size*.8,y,x+size*.7,y,x+sway,y-size*2.2)
    g.setColor(1,.64,.05,alpha); g.polygon('fill',x-size*.4,y,x+size*.4,y,x-sway*.5,y-size*1.45)
    g.setColor(1,.93,.45,alpha*.85); g.ellipse('fill',x,y-size*.22,size*.25,size*.45)
end
function B.drawGround()
    local g=love.graphics; g.push('all')
    for _,p in ipairs(B.trails) do
        local fade=math.min(1,p.life/.55)
        g.setColor(1,.13,.015,.1*fade); g.ellipse('fill',p.x,p.y,21*fade,13*fade)
        flame(p.x,p.y,8*fade,p.seed,.85*fade)
    end
    g.pop()
end
function B.drawMobs()
    local g=love.graphics; g.push('all')
    for _,m in ipairs(mobs) do if (m.burnTime or 0)>0 and not m.abyssHeld and not m.spent then
        local fade=math.min(1,m.burnTime)
        for i=1,3 do flame(m.x+(i-2)*9,m.y+7,5+i%2,m.x+i*2,fade*.8) end
        for i=1,4 do local t=(B.clock*1.6+i*.27)%1
            g.setColor(1,.5,.07,(1-t)*fade); g.circle('fill',m.x+math.sin(i*5+B.clock)*13,m.y-t*40,1)
        end
    end end
    g.pop()
end
function B.resize(ratio) for _,p in ipairs(B.trails) do p.x=p.x*ratio end end
return B
