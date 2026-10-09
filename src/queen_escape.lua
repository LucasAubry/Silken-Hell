local Q={required=12,window=1.5}
function Q.reset(f)
 f.enraged=false;f.silkBits={};f.webShake=0;f.escapeTaps={};f.escapeHeld={};f.cornerPending=false;f.cornerLay=false;f.cornerSlots=nil
end
function Q.struggle(f,dt)
 f.webShake=math.max(0,f.webShake-dt)
 for i=#f.silkBits,1,-1 do local p=f.silkBits[i];p.age=p.age+dt;p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.vx=p.vx*math.exp(-3*dt);p.vy=p.vy+35*dt;if p.age>.7 then table.remove(f.silkBits,i) end end
 local x,y=Input.move();local held={x<-.45,x>.45,y<-.45,y>.45,not Input.slow()}
 local pressed=false
 for i,value in ipairs(held) do if value and not f.escapeHeld[i] then pressed=true end end
 f.escapeHeld=held
 if f.snare<=0 or player.reset or f.defeated then f.escapeTaps={};return end
 for i=#f.escapeTaps,1,-1 do if f.clock-f.escapeTaps[i]>Q.window then table.remove(f.escapeTaps,i) end end
 if pressed then f.escapeTaps[#f.escapeTaps+1]=f.clock;f.webShake=.17;Q.shed(f,3) end
 if #f.escapeTaps<Q.required then return end
 f.snare=0;f.snareSource=nil;f.escapeTaps={};f.webGrace=1.2;f.cornerPending=true;f.enraged=true;Q.shed(f,28)
 if f.target==player and (f.phase=='aim' or f.phase=='charge') then
  f.phase='recover';f.phaseTime=0;f.target=nil;f.dashing=false;f.afterimages={};f.contactGrace=.35
 end
end
function Q.shed(f,count)
 for i=1,count do
  local angle=i*2.399+f.clock*17;local speed=65+(i%5)*18
  f.silkBits[#f.silkBits+1]={x=player.x+15+math.cos(angle)*24,y=player.y+12+math.sin(angle)*24,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,age=0,angle=angle}
 end
end
function Q.draw(f)
 local g=love.graphics;g.push('all');g.setShader();g.setLineWidth(1)
 if f.snare>0 then
  local progress=#f.escapeTaps/Q.required;local shake=f.webShake/.17
  local x=player.x+15+math.sin(f.clock*130)*shake*3;local y=player.y+12+math.cos(f.clock*113)*shake*2
  g.setColor(.94,.97,1,.85)
  for i=1,12 do
   local a=i*math.pi/6;local b=(i+1)*math.pi/6
   if (i*7%13)/13>=progress*.85 then g.line(x+math.cos(a)*6,y+math.sin(a)*6,x+math.cos(a)*32,y+math.sin(a)*32) end
   for ring=1,3 do local r=ring*10
    if ((i*5+ring*3)%17)/17>=progress*.8 then g.line(x+math.cos(a)*r,y+math.sin(a)*r,x+math.cos(b)*r,y+math.sin(b)*r) end
   end
  end
 end
 for _,p in ipairs(f.silkBits) do
  g.setColor(.95,.98,1,(1-p.age/.7)*.85)
  local dx,dy=math.cos(p.angle+p.age*3)*4,math.sin(p.angle+p.age*3)*4
  g.line(p.x-dx,p.y-dy,p.x+dx,p.y+dy)
 end
 g.pop()
end
function Q.beginLay(f)
 f.cornerLay=f.cornerPending;f.cornerPending=false;f.cornerSlots=nil;f.cornerReady=false
 if not f.cornerLay then f.chooseNest();return end
 local px,py=player.x+15,player.y+12
 local right=px<Arena.width/2;local bottom=py<300
 f.nest={x=right and Arena.width-135 or 135,y=bottom and 465 or 145}
 f.cornerSlots={}
 for row=0,5 do for col=0,6 do
  f.cornerSlots[#f.cornerSlots+1]={x=right and Arena.width-65-col*46 or 65+col*46,y=bottom and 525-row*46 or 95+row*46}
 end end
 f.cornerGoal=f.carried;f.cornerTimer=0;f.shot=.25
end
function Q.point(f)
 for _,p in ipairs(f.cornerSlots) do
  local free=not p.used and (p.x-player.x-15)^2+(p.y-player.y-12)^2>=65^2
  for _,e in ipairs(f.eggs) do if (p.x-e.x)^2+(p.y-e.y)^2<44^2 then free=false;break end end
  if free then p.used=true;return p end
 end
end
function Q.lay(f,dt,move)
 if not f.cornerReady then
  if move(f,f.nest.x,f.nest.y,270*f.surge,dt)<5 then f.cornerReady=true;f.cornerTimer=0 end
 else
  f.cornerTimer=f.cornerTimer+dt
  if f.cornerTimer>=.18 then f.cornerTimer=f.cornerTimer-.18;f.layEgg() end
 end
 f.shot=f.shot-dt
 if f.shot<=0 then f.shoot();f.shot=.5 end
 if f.carried<=0 or f.batch>=f.cornerGoal then
  f.cornerLay=false;f.enraged=f.cornerPending;f.cornerSlots=nil;f.phase='webs';f.phaseTime=0;f.shot=.5
 end
end
return Q
