local F={}
function F.actors(owner,boss)
 local list,previous,nextPositions={},owner.starPrevious or {},{}
 local function add(key,x,y,radius)
  local old=previous[key] or {x=x,y=y}
  list[#list+1]={x=x,y=y,ox=old.x,oy=old.y,radius=radius}
  nextPositions[key]={x=x,y=y}
 end
 add('player',player.x+15,player.y+12,65)
 if boss and not owner.physicsTest then
  for _,b in ipairs(owner.bones)do if b.part=='head' or b.part=='tail' or b.key=='skeleton_spine' then
   add('bone'..tostring(b.part),b.x,b.y,b.part=='head' and 85 or b.part=='tail' and 65 or 42)
  end end
  for _,f in ipairs(owner.chargedFish or {})do if f.delay<=0 then add(f,f.x,f.y,43) end end
 else
  for _,m in ipairs(mobs or {})do if not m.abyssHeld then add(m,m.x,m.y,40) end end
 end
 owner.starPrevious=nextPositions
 return list
end
function F.stir(p,dt,actors)
 p.starHomeX=p.starHomeX or p.x;p.starHomeY=p.starHomeY or p.y
 local vx,vy=p.wakeVx or 0,p.wakeVy or 0
 local visibility=1
 local function influence(x,y,ox,oy,radius)
  local sx,sy=x-ox,y-oy;local length=sx*sx+sy*sy
  local t=length>.001 and math.max(0,math.min(1,((p.x-ox)*sx+(p.y-oy)*sy)/length)) or 1
  local dx,dy=p.x-(ox+sx*t),p.y-(oy+sy*t);local d=math.sqrt(dx*dx+dy*dy)
  if d<radius then
   local nx,ny=d>.01 and dx/d or 1,d>.01 and dy/d or 0
   local weight=1-d/radius
   local strength=weight*weight*1100
   vx=vx+(nx*strength-ny*weight*150)*dt
   vy=vy+(ny*strength+nx*weight*150)*dt
   visibility=math.min(visibility,math.max(.03,math.min(1,d/(radius*.5))))
  end
 end
 if actors then for _,m in ipairs(actors)do influence(m.x,m.y,m.ox,m.oy,m.radius)end
 else influence(player.x+15,player.y+12,player.x+15,player.y+12,65) end
 -- A weak restoring force refills the wake instead of accumulating stars at the walls.
 vx=vx+(p.starHomeX-p.x)*.28*dt;vy=vy+(p.starHomeY-p.y)*.28*dt
 local drag=math.exp(-dt*2.5);p.wakeVx=vx*drag;p.wakeVy=vy*drag
 p.x=p.x+p.wakeVx*dt;p.y=p.y+p.wakeVy*dt
 p.starVisibility=visibility
end
function F.boltShape(age,seed)
 local g=love.graphics;local points={-32,math.sin(age*12+(seed or 0))*4,-20,-4,-10,3,0,0}
 g.setColor(.2,.65,1,.3);g.setLineWidth(7);g.line(points)
 g.setColor(.65,.95,1,1);g.setLineWidth(2);g.line(points)
end
function F.bolt(p,clock)
 local g=love.graphics;g.push('all');g.setBlendMode('add');g.translate(p.x,p.y);g.rotate(math.atan2(p.vy or 0,p.vx or 1))
 F.boltShape(clock,p.seed or p.y);g.pop()
end
return F
