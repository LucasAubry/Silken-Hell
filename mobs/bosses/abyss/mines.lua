local M={}
function M.spawn(a)
 local slot=a.mineSerial%4;a.mineSerial=a.mineSerial+1
 local x=Arena.width*(slot%2==0 and .69 or .85);local y=slot%2==0 and 175 or 435
 if (x-player.x-15)^2+(y-player.y-12)^2<100^2 then y=600-y end
 x,y=Arena.clearSpot(x-18,y-18,36,36)
 a.mines[#a.mines+1]={x=x+18,y=y+18,age=0,vx=0,vy=0,armed=false,grace=0}
end
function M.update(a,dt)
 if not a.boss or a.defeated then a.mines={};return end
 if not a.open then
  a.nextMine=a.nextMine-dt
  if a.nextMine<=0 and #a.mines<2 then M.spawn(a);a.nextMine=1.6 end
 end
 local mx,my=a.mouth()
 for i=#a.mines,1,-1 do
  local p=a.mines[i];p.age=p.age+dt;p.grace=math.max(0,p.grace-dt)
  local dx,dy=p.x-player.x-15,p.y-player.y-12;local dist=math.sqrt(dx*dx+dy*dy)
  if p.age>.6 and dist<35 and p.grace<=0 then
   if player.dashing then
    if dist<1 then dx,dy=player.lastMoveX or 1,player.lastMoveY or 0;dist=math.max(1,math.sqrt(dx*dx+dy*dy)) end
    p.armed=true;p.vx=dx/dist*360;p.vy=dy/dist*360;p.grace=.35;p.freeTime=0
    Audio.play('pick')
   else Hazards.kill('abyss_mine') end
  end
  local consumed=false
  if p.armed then
   p.freeTime=(p.freeTime or 0)+dt
   if a.open then
    local dx,dy=mx-p.x,my-p.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
    p.vx,p.vy=dx/d*430,dy/d*430
   end
   local steps=math.max(1,math.ceil(math.sqrt(p.vx*p.vx+p.vy*p.vy)*dt/6))
   for _=1,steps do
    p.x=p.x+p.vx*dt/steps;p.y=p.y+p.vy*dt/steps
    if a.open and (p.x-mx)^2+(p.y-my)^2<38^2 then
     table.remove(a.mines,i);consumed=true
     a.spit();a.recoil=1.2;a.breathAt=a.clock+5.5;a.nextShot=1.4;a.threads={};a.pressure=nil
     BossFX.burst(mx,my,{1,.56,.18},1.6);a.hurt(2)
     if a.defeated then return end
     break
    end
    if Arena.blocked(p.x-12,p.y-12,24,24) or p.freeTime>4 then
     BossFX.burst(p.x,p.y,{1,.5,.15},.8)
     if p.grace<=0 and (p.x-player.x-15)^2+(p.y-player.y-12)^2<48^2 then Hazards.kill('abyss_mine') end
     table.remove(a.mines,i);consumed=true;break
    end
   end
  end
  if not consumed and p.armed and p.grace<=0 and (p.x-player.x-15)^2+(p.y-player.y-12)^2<28^2 then Hazards.kill('abyss_mine') end
 end
end
function M.draw(a)
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,p in ipairs(a.mines or {}) do
  local alpha=math.min(1,p.age/.6)
  if not p.armed then
   g.setColor(.3,.42,.46,alpha*.7);g.setLineWidth(2);g.line(p.x,p.y+14,p.x,p.y+30)
   g.ellipse('fill',p.x,p.y+30,9,3)
  end
  g.setColor(.055,.10,.13,alpha);g.circle('fill',p.x,p.y,17)
  g.setColor(.45,.62,.64,alpha);g.setLineWidth(2);g.circle('line',p.x,p.y,16)
  for j=1,8 do local angle=j*math.pi/4+p.age*(p.armed and 2 or .1)
   g.setColor(.61,.73,.67,alpha);g.line(p.x+math.cos(angle)*14,p.y+math.sin(angle)*14,p.x+math.cos(angle)*22,p.y+math.sin(angle)*22)
  end
  local pulse=.7+.3*math.sin(p.age*(p.armed and 16 or 3))
  g.setColor(1,.46,.12,alpha*pulse);g.circle('fill',p.x,p.y,7)
  g.setColor(1,.9,.5,alpha);g.circle('fill',p.x-1,p.y-1,3)
 end
 g.pop()
end
return M
