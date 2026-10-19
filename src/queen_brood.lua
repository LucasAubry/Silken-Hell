-- Wall impacts hatch a timed brood; their silk fades without immobilising players.
local B={}
function B.spawn(f,x,y)
 f.bombs[#f.bombs+1]={x=x,y=y,age=0,life=2.4,angle=0}
end
function B.impact(x,y,xx,yy)
 local steps=math.max(1,math.ceil(math.sqrt((xx-x)^2+(yy-y)^2)/6))
 for i=1,steps do
  local t=i/steps;local px,py=x+(xx-x)*t,y+(yy-y)*t
  if px<34 or px>Arena.width-34 or py<34 or py>566 or Arena.blocked(px-3,py-3,6,6) then
   return math.max(34,math.min(Arena.width-34,px)),math.max(34,math.min(566,py)),t
  end
 end
end
function B.update(f,dt)
 for i=#f.stuck,1,-1 do local w=f.stuck[i];w.age=w.age+dt;if w.age>=w.life then table.remove(f.stuck,i) end end
 for i=#f.bursts,1,-1 do local b=f.bursts[i];b.age=b.age+dt;if b.age>=.45 then table.remove(f.bursts,i) end end
 for i=#f.bombs,1,-1 do
  local b=f.bombs[i];b.age=b.age+dt
  local dx,dy=player.x+15-b.x,player.y+12-b.y;local d=math.sqrt(dx*dx+dy*dy)
  local ox,oy=b.x,b.y
  if d>1 then
   local step=math.min(d,65*dt);local x,y=b.x+dx/d*step,b.y+dy/d*step
   if not Arena.blocked(x-8,y-8,16,16) then b.x=x;b.y=y end
   b.angle=math.atan2(dy,dx)-math.pi/2
  end
  if (player.x+15-b.x)^2+(player.y+12-b.y)^2<18^2 then Hazards.kill() end
  require('brown_walk').advance(b,math.sqrt((b.x-ox)^2+(b.y-oy)^2),dt)
  if b.age>=b.life then
   f.bursts[#f.bursts+1]={x=b.x,y=b.y,age=0}
   f.stuck[#f.stuck+1]={x=b.x,y=b.y,age=0,life=7,r=12}
   if (player.x+15-b.x)^2+(player.y+12-b.y)^2<36^2 then Hazards.kill() end
   table.remove(f.bombs,i)
  end
 end
end
function B.speed(f)
 if not f.active or f.defeated then return 1 end
 local factor=1
 for _,w in ipairs(f.stuck) do
  if (player.x+15-w.x)^2+(player.y+12-w.y)^2<w.r^2 then
   factor=math.min(factor,1-.58*math.min(1,(w.life-w.age)/2.5))
  end
 end
 return factor
end
function B.drawGround(f)
 local g=love.graphics;local art=require('final_art')
 for _,w in ipairs(f.stuck) do
  local fade=math.min(1,(w.life-w.age)/2.5)
  -- Small beads of sticky venom replace the web pattern.
  for j=1,7 do
   local a=j*2.399;local r=j%3*3
   g.setColor(.22,.29,.055,.7*fade);g.ellipse('fill',w.x+math.cos(a)*r,w.y+math.sin(a)*r,5,3.5)
   g.setColor(.57,.64,.18,.45*fade);g.ellipse('fill',w.x+math.cos(a)*r-1,w.y+math.sin(a)*r-1,2,.8)
  end
 end
end
function B.draw(f)
 local g=love.graphics;local art=require('final_art')
 for _,b in ipairs(f.bombs) do
  local pulse=.5+.5*math.sin(b.age*(10+18*b.age/b.life))
  g.setColor(1,.3,.12,.16+pulse*.25);g.circle('line',b.x,b.y,16+pulse*4)
  g.setColor(1,.6+(.4*(1-pulse)),.6,1);art.spider('baby_red',b.x,b.y,25,b.angle,b)
 end
 for _,b in ipairs(f.bursts) do
  local t=b.age/.45;g.setColor(1,.65,.3,(1-t)*.8);g.circle('line',b.x,b.y,8+36*t)
  for i=1,12 do local a=i*math.pi/6;g.line(b.x+math.cos(a)*t*48,b.y+math.sin(a)*t*48,b.x+math.cos(a)*(t*48+5),b.y+math.sin(a)*(t*48+5)) end
 end
end
return B
