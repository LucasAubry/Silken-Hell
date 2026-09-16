local H={lava={}}
function H.kill()
    if not player.reset then player.reset=true; player.death=player.death+1; activateShaderEffect() end
end
function H.reset(hell,n)
    H.lava={}; player.venom=0; player.dashing=false
    if not hell then return end
    local spots=n==10 and {{.15,180,44,26},{.85,420,44,26}} or {{.32,190,42,25},{.68,420,48,27},{.72,215,35,22}}
    for i,p in ipairs(spots) do if i<=2 or n>=4 then H.lava[#H.lava+1]={x=p[1]*Arena.width,y=p[2],rx=p[3],ry=p[4]} end end
end
function H.inEllipse(x,y,p,pad)
    return ((x-p.x)/(p.rx+(pad or 0)))^2+((y-p.y)/(p.ry+(pad or 0)))^2<1
end
function H.contact()
    for _,p in ipairs(H.lava) do if H.inEllipse(player.x+15,player.y+12,p,5) then H.kill(); return end end
    if Wasp then Wasp.contact() end
end
function H.speed()
    local factor=player.venom>0 and 0.42 or 1
    if Raven.active then for _,n in ipairs(Raven.nests) do if H.inEllipse(player.x+15,player.y+12,n,0) then factor=math.min(factor,0.14) end end end
    return math.min(factor,Realms.speed())
end
function H.draw()
    local g=love.graphics
    for _,p in ipairs(H.lava) do
        g.setColor(1,0.36,0.03,0.13+math.sin(larme_float_timer*3)*0.04); g.ellipse('fill',p.x,p.y,p.rx+8,p.ry+8)
        g.setColor(1,1,1); Art.draw('lava',p.x,p.y,p.rx*2+12,0,p.ry*2+12)
    end
end
return H
