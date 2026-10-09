local F={}
function F.setup(a) a.chargedFish={};a.fishCharge=0;a.fishWave=0 end
function F.trigger(a)
 a.fishCharge=a.fishCharge+1;a.fishWave=a.fishWave+1
 player.charges=a.fishCharge;player.electrified=4;player.illuminated=4
 -- Accumulate charges without stacking overlapping schools.
 if #a.chargedFish>0 then return end
 local px,py=player.x+15,player.y+12
 local centerX=math.max(190,math.min(Arena.width-190,px))
 local centerY=math.max(155,math.min(445,py))
 -- Identical player positions always give identical openings, including near corners.
 for row=1,2 do for side=1,4 do
  local offset=row==1 and -1 or 1
  local x,y
  if side==1 then x,y=-45,centerY+offset*112
  elseif side==2 then x,y=Arena.width+45,centerY+offset*112
  elseif side==3 then x,y=centerX+offset*151,-45
  else x,y=centerX+offset*151,645 end
  a.chargedFish[#a.chargedFish+1]={x=x,y=y,side=side,delay=.3+(row-1)*.85+(side-1)*.12,age=0,life=5,angle=math.atan2(py-y,px-x)}
 end end
 -- A delayed central pair increases pressure without closing the initial gaps.
 for side=3,4 do
  local x,y=centerX,side==3 and -45 or 645
  a.chargedFish[#a.chargedFish+1]={x=x,y=y,side=side,delay=1.85+(side-3)*.25,age=0,life=5,angle=math.atan2(py-y,px-x)}
 end
end
function F.update(a,dt,px,py)
 player.electrified=a.fishCharge>0 and 4 or 0;player.illuminated=player.electrified;player.charges=a.fishCharge
 for i=#a.chargedFish,1,-1 do
  local f=a.chargedFish[i];f.delay=f.delay-dt
  if f.delay<=0 then
   f.age=f.age+dt;f.life=f.life-dt
   local dx,dy=px-f.x,py-f.y;local d=math.sqrt(dx*dx+dy*dy)
   if not f.committed then
    f.angle=math.atan2(dy,dx)
    if d<180 or f.age>1.5 then f.committed=true end
   end
   local speed=300
   f.x=f.x+math.cos(f.angle)*speed*dt;f.y=f.y+math.sin(f.angle)*speed*dt
   if (f.x-px)^2+(f.y-py)^2<24^2 then Hazards.kill('abyss_bite') end
   if f.life<=0 or (f.age>1 and (f.x< -100 or f.x>Arena.width+100 or f.y< -100 or f.y>700))then table.remove(a.chargedFish,i) end
  end
 end
end
function F.visibility(f,px,py)
 local d=math.sqrt((f.x-px)^2+(f.y-py)^2)
 return math.max(0,math.min(1,(190-d)/100))
end
function F.draw(a)
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,f in ipairs(a.chargedFish)do if f.delay<=0 then
  local alpha=F.visibility(f,player.x+15,player.y+12)
  g.setColor(.7,.8,.95,alpha);Art.draw('abyss_fish',f.x,f.y,85,f.angle)
  local art=Art.images.abyss_fish;local h=85*art.h/art.w
  local ex=f.x+math.cos(f.angle)*25.5+math.sin(f.angle)*h*.07
  local ey=f.y+math.sin(f.angle)*25.5-math.cos(f.angle)*h*.07
  g.setColor(1,.05,.02,.24);g.circle('fill',ex,ey,7)
  g.setColor(1,.12,.06,1);g.circle('fill',ex,ey,2.3)
 end end
 if a.fishCharge>0 then
  local x,y=player.x+15,player.y+12
  g.setColor(.2,.75,1,.65);g.setLineWidth(1.4)
  for i=1,math.min(12,a.fishCharge)do
   local angle=a.clock*.8+(i-1)*math.pi*2/math.min(12,a.fishCharge)
   g.setColor(.55,.95,1,.95);g.circle('fill',x+math.cos(angle)*37,y+math.sin(angle)*37,2.5)
  end
  g.setColor(.2,.75,1,.65)
  for i=1,4 do
   local angle=a.clock*3+i*math.pi/2;local c,s=math.cos(angle),math.sin(angle)
   g.line(x+c*22,y+s*22,x+c*29-s*4,y+s*29+c*4,x+c*32,y+s*32)
  end
 end
 g.pop()
end
return F
