local E={}
function E.setup(a) a.rearEscape=nil;a.rearCooldown=0;a.rearDwell=0 end
function E.update(a,dt,px,py)
 a.rearCooldown=math.max(0,(a.rearCooldown or 0)-dt)
 if a.returnKnockTime>0 then a.rearEscape=nil;a.rearDwell=0;a.rearCooldown=2;return end
 local e=a.rearEscape
 if not e and a.rearCooldown<=0 then
  local tail
  local rear=a.webTail and 'tail' or a.webPartIds[#a.webPartIds] or 'head'
  for _,b in ipairs(a.bones)do if b.part==rear and (b.key=='skeleton_spine' or rear=='tail' or rear=='head')then tail=b;break end end
  if tail then
   local dx,dy=px-tail.x,py-tail.y;local angle=tail.angle or a.swimAngle
   local along=dx*math.cos(angle)+dy*math.sin(angle)
   local across=-dx*math.sin(angle)+dy*math.cos(angle)
   local h=a.swimHead
   if along< -12 and along> -220 and math.abs(across)<125 and h.x>0 and h.x<Arena.width and h.y>0 and h.y<600 then
    a.rearDwell=a.rearDwell+dt
   else a.rearDwell=0 end
   if a.rearDwell>=.12 then
    local c,s=math.cos(a.swimAngle),math.sin(a.swimAngle)
    local inward=-(Arena.width/2-h.x)*s+(300-h.y)*c
    e={age=0,angle=a.swimAngle,x=px,y=py,side=inward>=0 and 1 or -1}
    a.rearEscape=e;a.rearDwell=0;a.rearCooldown=4.5
    a.returnTurn=0
   end
  end
 end
 if not e then return end
 e.age=e.age+dt
 if e.age<.5 then return e.angle,390,0 end
 if e.age<1.95 then
  -- Aim at the captured position: the curve never tracks subsequent dodges.
  local angle=math.atan2(e.y-a.swimHead.y,e.x-a.swimHead.x)
  local delta=(angle-a.swimAngle+math.pi)%(2*math.pi)-math.pi
  if e.age<1.1 and delta*e.side<0 then delta=delta+e.side*math.pi*2 end
  return a.swimAngle+delta,270,2.8
 end
 a.rearEscape=nil
end
return E
