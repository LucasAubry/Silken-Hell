local H={lava={}}
function H.kill(source)
    if require('boss_liberation').busy() then return end
    if Aftermath and (Aftermath.cleared or Aftermath.ready()) then return end
    if source~='charged_suction' and source~='abyss_bite' and source~='abyss_mine' and source~='abyss_tooth' and source~='abyss_laser' and source~='abyss_octopus' and source~='abyss_projectile' and Abyss and Abyss.isPulling() then return end
    if not player.reset and not player.tunnelTravel and not player.abyssHeld and not player.abyssSpit and (player.abyssGrace or 0)<=0 then player.reset=true; player.death=player.death+1; Profile.record('deaths'); activateShaderEffect() end
end
function H.reset(hell,n)
    Burning.reset()
    H.lava={}; player.venom=0; player.dashing=false; player.falling=false; player.fallTimer=0

end
function H.inEllipse(x,y,p,pad)
    return ((x-p.x)/(p.rx+(pad or 0)))^2+((y-p.y)/(p.ry+(pad or 0)))^2<1
end
function H.contact()
    Realms.contact(); Abyss.contact(); AbyssTerrain.contact(); Bosses.contact(); Magma.contact(); Burning.contact()
    for _,p in ipairs(H.lava) do if (p.points and require('ground_holes').contains(p,player.x+15,player.y+12)) or (not p.points and H.inEllipse(player.x+15,player.y+12,p,5)) then H.kill(); return end end
    if Wasp then Wasp.contact() end
    Storm.contact()
end
function H.openEdge(r,x,y,w,h)
 if Campaign.biome~=2 then return false end
 local px,py=x+w/2,y+h/2
 if r.w==Arena.width and (r.y==0 or r.y==578) then py=r.y==0 and 22 or 578
 elseif r.h==600 and (r.x==0 or r.x==Arena.width-22) then px=r.x==0 and 22 or Arena.width-22
 else return false end
 for _,zone in ipairs(H.lava) do if zone.points and require('ground_holes').contains(zone,px,py) then return true end end
 return false
end
function H.speed()
    local factor=player.venom>0 and 0.42 or 1
    if Raven.active then for _,n in ipairs(Raven.nests) do if H.inEllipse(player.x+15,player.y+12,n,0) then factor=math.min(factor,0.40) end end end
    return math.min(factor,Realms.speed(),Bosses.speed())
end
function H.draw()
    Magma.drawGround(); Burning.drawGround()
    local g=love.graphics
    for _,p in ipairs(H.lava) do
        if p.points then require('lava_zones').draw(p,UI.clock) else
        g.setColor(1,0.36,0.03,0.13+math.sin(larme_float_timer*3)*0.04); g.ellipse('fill',p.x,p.y,p.rx+8,p.ry+8)
        g.setColor(1,1,1); Art.draw('lava',p.x,p.y,p.rx*2+12,0,p.ry*2+12)
        end
    end
end
return H
