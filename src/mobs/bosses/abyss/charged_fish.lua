local F={}
function F.setup(a) a.chargedFish={};a.fishCharge=0;a.fishWave=0 end
function F.speed(charges,yellow)
 return (300+60*math.max(0,(charges or 0)-1))*(yellow and 1.1 or 1)
end
local function redSchool(a,px,py)
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
local function yellowSchool(a,px,py)
 -- A fixed axis through the player's position at spawn; no later homing.
 local centerY=math.max(160,math.min(440,py))
 for side=1,2 do
  local x=side==1 and -45 or Arena.width+45
  local y=centerY+(side==1 and -112 or 112)
  local angle=math.atan2(py-y,px-x)
  a.chargedFish[#a.chargedFish+1]={yellow=true,x=x,y=y,originX=x,originY=y,heading=angle,
   angle=angle,distance=0,phase=(side-1)*math.pi,delay=.45+(side-1)*.35,age=0,life=5,committed=true}
 end
end
function F.trigger(a)
 a.fishCharge=a.fishCharge+1;a.fishWave=a.fishWave+1
 player.charges=a.fishCharge;player.electrified=4;player.illuminated=4
 local red,yellow=false,false
 for _,f in ipairs(a.chargedFish) do if f.yellow then yellow=true else red=true end end
 local px,py=player.x+15,player.y+12
 if not red then redSchool(a,px,py) end
 -- Crossing three charges must add the new attackers even during an existing wave.
 if a.fishCharge>=3 and not yellow then yellowSchool(a,px,py) end
end
function F.project(f,travel)
 if not f.yellow then return f.x+math.cos(f.angle)*travel,f.y+math.sin(f.angle)*travel end
 local distance=(f.distance or 0)+travel
 local phase=f.phase or 0
 local offset=(math.sin(distance*math.pi*2/180+phase)-math.sin(phase))*32
 local c,s=math.cos(f.heading),math.sin(f.heading)
 return f.originX+c*distance-s*offset,f.originY+s*distance+c*offset
end
function F.update(a,dt,px,py)
 player.electrified=a.fishCharge>0 and 4 or 0;player.illuminated=player.electrified;player.charges=a.fishCharge
 for i=#a.chargedFish,1,-1 do
  local f=a.chargedFish[i]
  local elapsed=math.min(f.life,math.max(0,dt-math.max(0,f.delay)))
  f.delay=f.delay-dt
  if elapsed>0 then
   local speed=F.speed(a.fishCharge,f.yellow)
   -- Small steps cover the zigzag and fast charges without skipping collisions.
   local steps=math.max(1,math.ceil(elapsed*speed/8));local step=elapsed/steps
   for _=1,steps do
    f.age=f.age+step;f.life=f.life-step
    if not f.committed then
     local dx,dy=px-f.x,py-f.y;local d=math.sqrt(dx*dx+dy*dy)
     f.angle=math.atan2(dy,dx)
     if d<180 or f.age>1.5 then f.committed=true end
    end
    local x,y=F.project(f,speed*step)
    if f.yellow then
     f.angle=math.atan2(y-f.y,x-f.x);f.distance=f.distance+speed*step
    end
    f.x,f.y=x,y
    if (f.x-px)^2+(f.y-py)^2<24^2 then Hazards.kill('abyss_bite') end
    if player.reset then break end
   end
   if f.life<=.000001 or (f.age>1 and (f.x< -100 or f.x>Arena.width+100 or f.y< -100 or f.y>700))then table.remove(a.chargedFish,i) end
   if player.reset then break end
  end
 end
end
function F.visibility(f,px,py)
 local d=math.sqrt((f.x-px)^2+(f.y-py)^2)
 local radius=(player.charges or 0)>0 and Abyss.playerLightRadius() or 75
 return math.max(0,math.min(1,(radius-d)/100))
end
function F.draw(a)
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,f in ipairs(a.chargedFish)do if f.delay<=0 then
  local alpha=F.visibility(f,player.x+15,player.y+12)
  g.setColor(.7,.8,.95,alpha);Art.draw('abyss_fish',f.x,f.y,85,f.angle)
  local art=Art.images.abyss_fish;local h=85*art.h/art.w
  local ex=f.x+math.cos(f.angle)*25.5+math.sin(f.angle)*h*.07
  local ey=f.y+math.sin(f.angle)*25.5-math.cos(f.angle)*h*.07
  g.setColor(1,f.yellow and .8 or .05,.02,.24);g.circle('fill',ex,ey,7)
  g.setColor(1,f.yellow and .95 or .12,f.yellow and .12 or .06,1);g.circle('fill',ex,ey,2.3)
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
