local B={}
function B.update(m,dt)
 if m.capture or m.is_frozen then return end
 m.age=(m.age or 0)+dt;m.phaseTime=(m.phaseTime or 1.5)-dt
 if type(m.phase)~='string' then m.phase='rest' end
 if m.phaseTime<=0 then
  if m.phase=='rest' then
   local dx,dy=player.x+15-m.x,player.y+12-m.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
   m.vx,m.vy=dx/d,dy/d;m.angle=math.atan2(dy,dx)-math.pi/2;m.phase='aim';m.phaseTime=.85
  elseif m.phase=='aim' then m.phase='blow';m.phaseTime=2.2
  else m.phase='rest';m.phaseTime=2 end
 end
 if m.phase=='blow' then
  local dx,dy=player.x+15-m.x,player.y+12-m.y
  local along=dx*m.vx+dy*m.vy;local across=math.abs(dx*m.vy-dy*m.vx)
  if along>0 and along<390 and across<24+along*.24 and not player.tunnelTravel and not player.abyssHeld then
   local force=390*(1-along/600);local distance=force*dt;local steps=math.max(1,math.ceil(distance/5))
   for _=1,steps do
    local x,y=player.x+m.vx*distance/steps,player.y+m.vy*distance/steps
    if not willCollide(x,player.y) then player.x=x end
    if not willCollide(player.x,y) then player.y=y end
    Hazards.contact();if player.reset then break end
   end
  end
 end
 if isTouching(player,m) then Hazards.kill() end
end
function B.draw(m)
 local g=love.graphics;g.push('all')
 if m.phase=='aim' or m.phase=='blow' then
  local vx,vy=m.vx,m.vy;local blowing=m.phase=='blow';local length=blowing and 390 or 110
  -- Air is visible only through drifting particles, never a filled cone.
  g.setLineWidth(1)
  for i=1,blowing and 72 or 20 do
   local progress=(m.age*(blowing and 1.65 or .5)+i*.618)%1
   local d=25+progress*length
   local side=math.sin(i*2.4)*(8+d*.22)+math.sin(m.age*4+i)*3
   local x,y=m.x+vx*d-vy*side,m.y+vy*d+vx*side
   local alpha=math.sin(progress*math.pi)*(blowing and .68 or .3)
   g.setColor(.83,.94,1,alpha)
   if i%3==0 then
    g.line(x-vx*(4+i%7),y-vy*(4+i%7),x,y)
   else
    local size=i%5==0 and 3 or 2
    g.rectangle('fill',math.floor(x),math.floor(y),size,size)
   end
  end
 end
 require('sky_insect_art').draw('wind_bat',m.x,m.y,82,m.age,m.angle)
 g.pop()
end
return B
