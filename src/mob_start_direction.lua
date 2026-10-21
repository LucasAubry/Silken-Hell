-- Optional authored departure; absent fields preserve every existing trajectory.
local D={vectors={right={1,0},down={0,1},left={-1,0},up={0,-1}},labels={right='Droite',down='Bas',left='Gauche',up='Haut'}}
local kinds={blackbird_chick=true,spinner=true,jelly=true,light_jelly=true,fish=true,cloud_beast=true,cloud_snail=true,mist_moth=true,wind_bat=true}
function D.supported(e)
 return e.kind=='mob' and kinds[e.type] and not (e.has_larme and (e.type=='jelly' or e.type=='fish'))
end
function D.angle(e)
 local v=D.vectors[e.startDirection];return v and math.atan2(v[2],v[1])
end
function D.apply(m,e)
 if not D.supported(e) or not D.vectors[e.startDirection] then return end
 m.startDirection=e.startDirection
 local v=D.vectors[e.startDirection];local a=D.angle(e)
 m.dir=e.startDirection;m.vx,m.vy=v[1],v[2];m.angle=a-math.pi/2
 if m.type=='blackbird_chick' then
  m.heading=math.atan2(-v[1]*.75,v[2]);m.cx=m.x-math.cos(m.heading)*m.radius;m.cy=m.y-math.sin(m.heading)*m.radius*.75
 end
 if m.type=='spinner' then m.rotation=a end
 if m.type=='cloud_snail' or m.type=='mist_moth' then
  m.tx,m.ty=m.x+v[1]*180,m.y+v[2]*180;m.roamTime=3
  if m.type=='cloud_snail' then m.angle=a else m.cooldown=3 end
 end
end
-- Autonomous swimmers resume their natural drift smoothly after departure.
function D.motion(m,vx,vy)
 local v=D.vectors[m.startDirection];if not v or m.age>=1.2 then return vx,vy end
 local t=math.max(0,(m.age-.7)/.5);t=t*t*(3-2*t)
 return v[1]*(1-t)+vx*t,v[2]*(1-t)+vy*t
end
return D
