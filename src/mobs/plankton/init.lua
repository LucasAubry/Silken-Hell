local P={tearScale=.65,tearOffset=14,speedMultiplier=3}
local function free(m,x,y)
 if x<8 or x>Arena.width-8 or y<8 or y>Arena.height-8 or Arena.blocked(x-8,y-8,16,16) then return false end
 for _,other in ipairs(mobs) do
  if other~=m and other.type=='plankton' and not (other.dead or other.abyssHeld or other.edgeGone)
   and math.abs(x-other.x)<18 and math.abs(y-other.y)<18 then return false end
 end
 return true
end
local function separate(m)
 if free(m,m.x,m.y) then return end
 -- Resolve authored overlaps as well as displacement from external forces.
 for radius=18,180,9 do
  local count=math.ceil(radius*math.pi/9)
  for i=0,count-1 do
   local angle=i*math.pi*2/count
   local x,y=m.x+math.cos(angle)*radius,m.y+math.sin(angle)*radius
   if free(m,x,y) then m.x,m.y=x,y;return end
  end
 end
end
local function swim(m,vx,vy,dt)
 if dt<=0 then return end
 local x,y=m.x,m.y
 -- Restore the original axis-by-axis wall collision, without escape steering.
 if free(m,m.x+vx*dt,m.y) then m.x=m.x+vx*dt end
 if free(m,m.x,m.y+vy*dt) then m.y=m.y+vy*dt end
 m.vx,m.vy=(m.x-x)/dt,(m.y-y)/dt
 m.dir=Art.direction(m.vx,m.vy,m.dir)
end
function P.spawn(x,y,speed)
 local m={type='plankton',x=x,y=y,speed=speed or 90,age=0,dir='down',vx=0,vy=1,
  hitBox_width=16,hitBox_height=16,hitBox_offset_x=-8,hitBox_offset_y=-8}
 separate(m)
 mobs[#mobs+1]=m
 return m
end
local function contact(m)
 if not isTouching(player,m) then return false end
 m.dead=true;m.spent=true;m.burst=0
 Campaign.dropTear(m)
 return true
end
function P.update(m,dt)
 if m.dead then
  if m.burst then m.burst=m.burst+dt;if m.burst>=.7 then m.burst=nil end end
  return
 end
 if contact(m) then return end
 separate(m)
 if contact(m) then return end
 if m.is_frozen or m.tunnelTravel then return end
 m.age=m.age+dt
 local px,py=require('collision_shapes').center()
 local dx,dy=m.x-px,m.y-py
 local distance=math.sqrt(dx*dx+dy*dy)
 local vx,vy,speed
 if distance<230 then
  vx,vy=dx/math.max(distance,.001),dy/math.max(distance,.001);speed=m.speed
 else
  local a=m.age*.65+m.x*.002
  vx,vy=math.cos(a),math.sin(a);speed=m.speed*.16
 end
 -- Apply the boost to saved/editor speeds too, without rewriting authored maps.
 speed=speed*P.speedMultiplier
 local current=require('ocean_current')
 local flowSpeed=0
 for _,zone in ipairs(Realms.current) do flowSpeed=math.max(flowSpeed,zone.speed or 80) end
 local steps=math.max(1,math.ceil((speed+flowSpeed)*dt/4))
 for _=1,steps do
  local fx,fy=current.velocity(m.x,m.y,vx*speed,vy*speed,Realms.current)
  swim(m,fx,fy,dt/steps)
  if contact(m) then return end
 end
end
function P.art(x,y,size,t)
 local g=love.graphics
 g.push('all');g.translate(x,y);g.scale(size/12)
 local pulse=1+math.sin((t or 0)*5)*.08
 g.setColor(.3,1,.8,.12);g.circle('fill',0,0,7*pulse)
 g.setLineWidth(.8);g.setColor(.4,1,.83,.7)
 for i=1,5 do
  local a=i*math.pi*2/5;local sway=math.sin((t or 0)*7+i)*.6
  g.line(math.cos(a)*3,math.sin(a)*3,math.cos(a)*5+sway,math.sin(a)*5)
 end
 g.setColor(.45,1,.78,.9);g.ellipse('fill',0,0,3*pulse,4*pulse)
 g.setColor(.9,1,.7);g.circle('fill',-.6,-.8,1.2)
 g.pop()
end
function P.draw(m)
 if not m.dead then P.art(m.x,m.y,12,m.age);return end
 if not m.burst then return end
 local g=love.graphics;local t=m.burst;local fade=math.max(0,1-t/.7)
 g.push('all')
 -- Analytic motes keep the burst deterministic in replays, without random state.
 if t<.22 then
  local a=1-t/.22
  g.setColor(.65,1,.85,a*.5);g.setLineWidth(1.3*a)
  g.circle('line',m.x,m.y,3+t*100)
 end
 for i=1,32 do
  local angle=i*2.3999632297+(m.x+m.y)*.01
  local speed=65+(i*37%125);local travel=speed*(1-math.exp(-6*t))/6
  local x=m.x+math.cos(angle)*travel;local y=m.y+math.sin(angle)*travel+t*t*12
  local size=(.8+i%4*.38)*fade
  g.setColor(.25,.95,.72,.16*fade);g.circle('fill',x,y,size*2.5)
  g.setColor(i%5==0 and 1 or .45,1,i%5==0 and .8 or .78,fade)
  g.circle('fill',x,y,size)
 end
 g.pop()
end
return P
