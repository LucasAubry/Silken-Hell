local F={}
function F.setup(a)
 a.lumenParticles={};a.starPrevious=nil
 for i=1,300 do
  a.lumenParticles[i]={id=i,x=25+(math.sin(i*127.1)*43758.5453%1)*(Arena.width-50),y=35+(math.sin(i*311.7)*19642.349%1)*530,age=i,wakeVx=0,wakeVy=0}
 end
end
function F.update(a,dt,wakes)
 local fx=require('abyss_light_fx');local actors=fx.actors(a,true)
 for _,p in ipairs(a.lumenParticles)do
  p.age=p.age+dt
  fx.stir(p,dt,actors)
  p.x=p.x+math.sin(p.age*.6+p.id)*4*dt;p.y=p.y+math.cos(p.age*.7+p.id)*3*dt
  for _,w in ipairs(wakes)do
   local dx,dy=w.x-w.ox,w.y-w.oy
   local length=math.sqrt(dx*dx+dy*dy)
   if length>.001 then
    local ux,uy=dx/length,dy/length
    local along=(p.x-w.ox)*ux+(p.y-w.oy)*uy
    -- Include a short lead-in so the cloud parts before the tooth reaches it.
    if along> -28 and along<length+42 then
     local across=(p.x-w.ox)*(-uy)+(p.y-w.oy)*ux
     local distance=math.abs(across)
     if distance<40 then
      local side=across>=0 and 1 or -1
      local lead=math.max(0,along-length)
      local push=(1-distance/40)*(1-lead/50)
      p.wakeVx=p.wakeVx-uy*side*push*320*dt
      p.wakeVy=p.wakeVy+ux*side*push*320*dt
      -- Leave a clear corridor even when a fast tooth crosses it in one frame.
      if along>=0 and along<=length+14 and distance<17 then
       local shift=(17-distance)*side
       p.x=p.x-uy*shift;p.y=p.y+ux*shift
      end
     end
    end
   end
  end
  p.x=math.max(22,math.min(Arena.width-22,p.x));p.y=math.max(30,math.min(570,p.y))
 end
end
function F.draw(a)
 local g=love.graphics;g.push('all');g.setBlendMode('add')
 for _,p in ipairs(a.lumenParticles)do
  local pulse=(.65+.2*math.sin(p.age*1.3+p.id))*(p.starVisibility or 1)
  g.setColor(.08,.35,1,.022*pulse);g.circle('fill',p.x,p.y,20+p.id%9)
  g.setColor(.12,.45,1,.035*pulse);g.circle('fill',p.x,p.y,10+p.id%5)
  local vx,vy=p.wakeVx or 0,p.wakeVy or 0
  if vx*vx+vy*vy>225 then g.setColor(.25,.7,1,.35*pulse);g.setLineWidth(1);g.line(p.x-vx*.035,p.y-vy*.035,p.x,p.y) end
  g.setColor(.2,.65,1,.24*pulse);g.circle('fill',p.x,p.y,4)
  g.setColor(.45,.85,1,.9*pulse);g.circle('fill',p.x,p.y,1.1+(p.id%3)*.45)
 end
 g.pop()
end
return F
