-- Commit to passes near the player's predicted position; never orbit a fixed route.
local H={}
function H.setup(a)
 a.hunt=nil;a.excursion=nil;a.huntTime=0;a.bite=nil;a.biteCooldown=1;a.huntPX=player.x+15;a.huntPY=player.y+12;a.huntVX=0;a.huntVY=0
end
function H.update(a,dt,x,y)
 local h=a.swimHead;local c,s=math.cos(a.swimAngle),math.sin(a.swimAngle)
 local k=1-math.exp(-5*dt)
 a.huntVX=a.huntVX+(math.max(-400,math.min(400,(x-a.huntPX)/dt))-a.huntVX)*k
 a.huntVY=a.huntVY+(math.max(-400,math.min(400,(y-a.huntPY)/dt))-a.huntVY)*k
 a.huntPX,a.huntPY=x,y;a.biteCooldown=math.max(0,a.biteCooldown-dt)
 if a.returnKnockTime>0 then a.bite=nil;a.hunt=nil;a.biteCooldown=1.5 end
 a.huntTime=a.huntTime+dt
 if not a.excursion and not a.bite and a.returnKnockTime<=0 and a.huntTime>5.2 then
  -- Carry the current heading through a border, then return promptly.
  a.excursion={angle=a.swimAngle,age=0,outside=0};a.rearEscape=nil;a.hunt=nil
 end
 if a.excursion then
  local e=a.excursion;e.age=e.age+dt
  local out=h.x< -65 or h.x>Arena.width+65 or h.y< -65 or h.y>665
  if out then e.outside=e.outside+dt end
  if e.outside<.3 and e.age<5 then return e.angle,320,1.1,false end
  a.excursion=nil;a.huntTime=0;a.hunt=nil;a.biteCooldown=1
 end
 local mx,my=a.mouth();local dx,dy=x-mx,y-my
 if not a.bite and a.biteCooldown<=0 and dx*dx+dy*dy<165^2 and dx*c+dy*s>-28 then
  a.bite={age=0,angle=math.atan2(y-h.y,x-h.x)};a.rearEscape=nil
 end
 if a.bite then
  local b=a.bite;b.age=b.age+dt
  if b.age<.27 then b.angle=math.atan2(y-h.y,x-h.x) end
  if b.age<1.02 then return b.angle,b.age<.27 and 160 or 570,b.age<.27 and 3.5 or .85,true end
  a.bite=nil;a.biteCooldown=2;a.hunt=nil;a.returnShotTimer=math.max(a.returnShotTimer,.55)
 end
 local outside=h.x<-35 or h.x>Arena.width+35 or h.y<-35 or h.y>635
 local plan=a.hunt
 if not plan or plan.age>1.9 or (h.x-plan.x)^2+(h.y-plan.y)^2<90^2 or outside and not plan.returning then
  local dx,dy=x-h.x,y-h.y;local d=math.max(1,math.sqrt(dx*dx+dy*dy))
  local side=dx*a.huntVY-dy*a.huntVX>=0 and 1 or -1
  local bend=outside and 0 or math.min(145,d*.32)*side
  plan={x=math.max(85,math.min(Arena.width-85,x+a.huntVX*.4-dy/d*bend)),y=math.max(85,math.min(515,y+a.huntVY*.4+dx/d*bend)),age=0,returning=outside}
  a.hunt=plan
 end
 plan.age=plan.age+dt
 return math.atan2(plan.y-h.y,plan.x-h.x),outside and 310 or 235+math.min(65,math.sqrt((x-h.x)^2+(y-h.y)^2)*.09),outside and 3 or 1.4,false
end
return H
