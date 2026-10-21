local H={lava={},electric={}}
function H.kill(source)
    if require('boss_liberation').busy() then return end
    if Aftermath and (Aftermath.cleared or Aftermath.ready()) then return end
    if source~='charged_suction' and source~='abyss_bite' and source~='abyss_mine' and source~='abyss_tooth' and source~='abyss_laser' and source~='abyss_octopus' and source~='abyss_projectile' and Abyss and Abyss.isPulling() then return end
    if not player.reset and not player.tunnelTravel and not player.abyssHeld and not player.abyssSpit and (player.abyssGrace or 0)<=0 then player.reset=true; player.death=player.death+1; Profile.record('deaths'); activateShaderEffect() end
end
function H.reset(hell,n)
    Burning.reset()
    H.lava={};H.electric={}; player.venom=0; player.dashing=false; player.falling=false; player.fallTimer=0

end
function H.inEllipse(x,y,p,pad)
    return ((x-p.x)/(p.rx+(pad or 0)))^2+((y-p.y)/(p.ry+(pad or 0)))^2<1
end
function H.inLava(x,y,pad)
    for _,p in ipairs(H.lava) do
        if p.points then
            if require('ground_holes').containsFast(p,x,y) then return true end
        elseif H.inEllipse(x,y,p,pad) then return true end
    end
    return false
end
function H.contact()
    Realms.contact(); Abyss.contact(); AbyssTerrain.contact(); Bosses.contact(); Magma.contact(); Burning.contact()
    if H.inLava(player.x+15,player.y+12,5) then H.kill(); return end

    if Wasp then Wasp.contact() end
    Storm.contact()
end
function H.openEdge(r,x,y,w,h)
 if require('sky').openEdges() then
  return (r.w==Arena.width and r.h==22 and (r.y==0 or r.y==578))
      or (r.h==600 and r.w==22 and (r.x==0 or r.x==Arena.width-22))
 end
 if Campaign.biome~=2 then return false end
 local px,py=x+w/2,y+h/2
 if r.w==Arena.width and (r.y==0 or r.y==578) then py=r.y==0 and 22 or 578
 elseif r.h==600 and (r.x==0 or r.x==Arena.width-22) then px=r.x==0 and 22 or Arena.width-22
 else return false end
 for _,zone in ipairs(H.lava) do if zone.points and require('ground_holes').containsFast(zone,px,py) then return true end end
 return false
end
function H.speed()
    local factor=player.venom>0 and 0.42 or 1
    if Raven.active then for _,n in ipairs(Raven.nests) do if H.inEllipse(player.x+15,player.y+12,n,0) then factor=math.min(factor,0.40) end end end
    return math.min(factor,Realms.speed(),Bosses.speed(),require('queen_brood').speed(require('final_spider')))
end
function H.drawFloor()
    require('lava_zones').drawAll(H.lava,UI.clock)

end
function H.draw()
    Magma.drawGround(); Burning.drawGround()
end
return H
