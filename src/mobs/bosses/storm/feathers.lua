local F={}
function F.update(s,dt)
 if s.phase~='lap' and s.phase~='hunt' then return end
 s.featherClock=(s.featherClock or .8)-dt
 if s.featherWarning then
  s.featherWarning=s.featherWarning-dt
  if s.featherWarning<=0 then
   local speed=250+math.min(4,s.wave)*15
   for i=-1,1 do
    local angle=s.featherAim+i*.30
    s.projectiles[#s.projectiles+1]={x=s.x,y=s.y,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,angle=angle,age=0}
   end
   s.featherWarning=nil;s.featherClock=math.max(.9,1.6-s.wave*.12)
  end
 elseif s.featherClock<=0 then
  local dx,dy=player.x+15-s.x,player.y+12-s.y
  -- Lock the aim before firing so stepping aside remains enough to dodge.
  if dx*dx+dy*dy>130^2 then
   s.featherAim=math.atan2(dy,dx);s.featherWarning=.45
  end
 end
 for i=#s.projectiles,1,-1 do
  local p=s.projectiles[i];local x,y=p.x,p.y
  p.age=p.age+dt;p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt
  if p.age>.12 and require('collision_shapes').sweptCircle('storm_feather',x,y,p.x,p.y,14) then Hazards.kill('storm')end
  if p.age>6 or p.x< -60 or p.x>Arena.width+60 or p.y< -60 or p.y>660 then table.remove(s.projectiles,i)end
 end
end
function F.draw(s)
 local g=love.graphics;g.push('all');g.setShader()
 if s.featherWarning then
  local pulse=1-s.featherWarning/.45
  g.setColor(1,.86,.35,.45+pulse*.5);g.setLineWidth(3)
  g.circle('line',s.x,s.y,48+pulse*16)
  for i=-1,1 do
   local a=s.featherAim+i*.30;local dx,dy=math.cos(a),math.sin(a)
   g.line(s.x+dx*58,s.y+dy*58,s.x+dx*85,s.y+dy*85)
  end
 end
 for _,p in ipairs(s.projectiles)do
  local dx,dy=math.cos(p.angle),math.sin(p.angle)
  g.setColor(1,.87,.45,.85);g.setLineWidth(3)
  g.line(p.x-dx*23,p.y-dy*23,p.x+dx*12,p.y+dy*12)
  g.setColor(1,1,1);Art.draw('black_feather',p.x,p.y,34,p.angle)
 end
 g.pop()
end
return F
