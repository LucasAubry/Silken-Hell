-- Tracking gusts; simulation never depends on visual effects or RNG.
local G={range=1500,width=28,power=560}
local function aim(m)
 local dx,dy=player.x+15-m.x,player.y+12-m.y
 local length=math.max(.001,math.sqrt(dx*dx+dy*dy))
 m.vx,m.vy=dx/length,dy/length;m.angle=math.atan2(dy,dx)-math.pi/2
end
function G.reaches(m,x,y)
 local dx,dy=x-m.x,y-m.y
 local along=dx*m.vx+dy*m.vy
 local across=math.abs(dx*m.vy-dy*m.vx)
 return along>20 and along<G.range and across<G.width
  and Arena.direct(m.x-15,m.y-12,x-15,y-12)
end
function G.update(m,dt)
 if m.phase~='windup' and m.phase~='gust' and m.phase~='recover' then m.phase='roam' end
 if m.phase=='roam' then
  if m.cooldown>0 then return false end
  local dx,dy=player.x+15-m.x,player.y+12-m.y
  local length=math.max(.001,math.sqrt(dx*dx+dy*dy))
  m.vx,m.vy=dx/length,dy/length;m.angle=math.atan2(dy,dx)-math.pi/2
  m.phase='windup';m.phaseTime=.85
 end
 if m.phase=='windup' then aim(m) end
 local remaining=dt
 -- Consume boundary time explicitly so a slow frame cannot extend a gust.
 while remaining>0 and m.phase~='roam' do
  local step=math.min(remaining,m.phaseTime,1/60)
  if m.phase=='gust' then
   aim(m)
   -- Circle the target while continuing to face it.
   Arena.move(m,-m.vy*60*step,m.vx*60*step)
   aim(m)
   for _,other in ipairs(mobs) do
    if other~=m and not (other.dead or other.spent or other.falling or other.capture or other.tunnelTravel or other.abyssHeld)
     and not Realms.underground(other) and other.hitBox_width and other.hitBox_height and other.type~='scie' and other.type~='piege' and not other.ground then
     local steps=math.max(1,math.ceil(G.power*step/4))
     for _=1,steps do
      if not G.reaches(m,other.x,other.y) then break end
      Arena.move(other,m.vx*G.power*step/steps,m.vy*G.power*step/steps)
     end
    end
   end
  end
  if m.phase=='gust' and not (player.reset or player.falling or player.tunnelTravel or player.abyssHeld or player.skyWhirl or player.skyThrow) then
   local steps=math.max(1,math.ceil(G.power*step/4))
   for _=1,steps do
    if not G.reaches(m,player.x+15,player.y+12) then break end
    local dx,dy=m.vx*G.power*step/steps,m.vy*G.power*step/steps
    if not willCollide(player.x+dx,player.y) then player.x=player.x+dx end
    if not willCollide(player.x,player.y+dy) then player.y=player.y+dy end
    Hazards.contact();if player.reset then break end
   end
  end
  remaining=remaining-step;m.phaseTime=m.phaseTime-step
  if m.phaseTime<=0 then
   if m.phase=='windup' then aim(m);m.phase='gust';m.phaseTime=2
   elseif m.phase=='gust' then m.phase='recover';m.phaseTime=.65
   else m.phase='roam';m.cooldown=2.5 end
  end
 end
 return true
end
function G.draw(m)
 if m.phase~='gust' then return end
 local g=love.graphics;g.push('all');g.setShader();g.setLineWidth(1.5)
 local gust=m.phase=='gust';local t=m.age or 0
 for i=1,70 do
  local distance=gust and (t*740+i*29)%G.range or 25+i*17
  local side=math.sin(i*13.7)*(G.width-4)
  local x=m.x+m.vx*distance-m.vy*side;local y=m.y+m.vy*distance+m.vx*side
  if Arena.direct(m.x-15,m.y-12,x-15,y-12) then
   g.setColor(.84,.94,1,.78*(1-distance/G.range*.55));g.setLineWidth(2.6)
   local length=24+9*math.sin(i)
   g.line(x,y,x+m.vx*length,y+m.vy*length)
  end
 end
 g.pop()
end
return G
