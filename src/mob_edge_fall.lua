local F={}
local flying={ange=true,waspling=true,blackbird_chick=true,wind_bat=true,dragonfly=true,mist_moth=true}
function F.check(m)
 if flying[m.type] or m.type=='piege' or m.type=='scie' or m.dead or m.edgeFall~=nil or m.edgeGone or m.tunnelTravel or m.abyssHeld then return false end
 if m.x>=0 and m.x<=Arena.width and m.y>=0 and m.y<=600 and not (m.type=='cloud_snail' and Realms.fallAt(m.x,m.y)) then return false end
 m.edgeFall=0;m.falling=true
 Campaign.dropTear(m)
 return true
end
function F.update(m,dt)
 if m.edgeGone then return true end
 -- Scripted arrivals may start outside; gusts check each forced step.
 if m.fling then F.check(m) end
 if m.edgeFall~=nil then
  m.edgeFall=m.edgeFall+dt
  if m.edgeFall>=.55 then m.edgeGone=true;m.dead=true end
  return true
 end
 return false
end
return F
