-- The same sprite-space triangles drive tooth rendering, removal and collision.
local J={}
local teeth={{1084,363,1070,433,1090,405},{1130,344,1139,402,1149,374},{1185,316,1175,405,1197,365},{1000,716,963,757,990,758},{1057,743,1024,799,1055,785},{1121,790,1085,838,1112,834}}
local order={4,1,5,2,6,3}
function J.point(a,x,y)
 local qx,qy,qw,qh=Art.images.skeleton_open.quad:getViewport()
 return a.head.x-a.head.w/2+(x-qx)/qw*a.head.w,a.head.y-a.head.h/2+(y-qy)/qh*a.head.h
end
function J.polygon(a,index)
 local p={};for i=1,6,2 do local x,y=J.point(a,teeth[index][i],teeth[index][i+1]);p[#p+1]=x;p[#p+1]=y end
 return p
end
local function inside(p,x,y)
 local function side(i,j) return (p[j]-p[i])*(y-p[i+1])-(p[j+1]-p[i+1])*(x-p[i]) end
 local u,v,w=side(1,3),side(3,5),side(5,1)
 return (u>=0 and v>=0 and w>=0) or (u<=0 and v<=0 and w<=0)
end
function J.removedAt(a,x,y)
 for index in pairs(a.removedTeeth or {}) do if inside(J.polygon(a,index),x,y) then return true end end
 return false
end
function J.solid(a,x,y)
 return a.boneTouches(a.bones[1],x,y) and not J.removedAt(a,x,y)
end
function J.blocked(a,x,y)
 if a.defeated or not a.active or not a.boss or player.abyssSpit or a.grab then return false end
 if x>=a.head.x+a.head.w/2+4 then return false end
 if x<a.head.x+20 then return true end
 -- Keep the back of the skull and the outside of the jaws inaccessible.
 if y+12<a.head.y-135 or y+12>a.head.y+195 then return true end
 -- Sample the actual visible bone mask, with the player's small gameplay body.
 for yy=y+2,y+22,4 do for xx=x+2,x+28,4 do if J.solid(a,xx,yy) then return true end end end
 return false
end
function J.available(a)
 if a.defeated or not a.open then return nil end
 for _,index in ipairs(order) do if not a.removedTeeth[index] then return index end end
end
function J.target(a,index)
 index=index or J.available(a);if not index then return end
 local t=teeth[index];local tip=1
 for i=3,5,2 do if (index<=3 and t[i+1]>t[tip+1]) or (index>3 and t[i+1]<t[tip+1]) then tip=i end end
 local x,y=J.point(a,t[tip],t[tip+1])
 local key=table.concat({index,a.head.x,a.head.y,a.head.w,a.head.h},':')
 a.toothTargets=a.toothTargets or {}
 local cached=a.toothTargets[key];if cached then return cached.x,cached.y end
 local bx,by,best=nil,nil,math.huge
 -- Fit the whole player beside the actual tooth, never inside a neighbouring bone.
 for outward=0,72,4 do for inward=20,76,4 do
  local xx,yy=x+outward,y+(index<=3 and inward or -inward)
  local score=outward*outward+inward*inward
  if score<best and not J.blocked(a,xx-15,yy-12) then bx,by,best=xx,yy,score end
 end end
 bx,by=bx or x+72,by or y+(index<=3 and 76 or -76)
 a.toothTargets[key]={x=bx,y=by};return bx,by
end
function J.contact(a)
 if not a.open or a.defeated or a.grab or player.reset or player.abyssSpit or not player.dashing then return end
 local nearest,best
 for _,index in ipairs(order) do if not a.removedTeeth[index] then
  local x,y=J.target(a,index);local d=(player.x+15-x)^2+(player.y+12-y)^2
  if d<24^2 and (not best or d<best) then nearest={index=index,progress=0,x=x,y=y};best=d end
 end end
 if nearest then a.grab=nearest;player.x=nearest.x-15;player.y=nearest.y-12;player.dashing=false end
end
function J.update(a,dt)
 for i=#a.fragments,1,-1 do local f=a.fragments[i];f.age=f.age+dt;f.x=f.x+210*dt;f.y=f.y+f.vy*dt;f.vy=f.vy+230*dt;if f.age>1 then table.remove(a.fragments,i) end end
 if not a.grab then return end
 if a.defeated or player.reset then a.grab=nil;return end
 local g=a.grab;local dx,dy=Input.move();local n=math.sqrt(dx*dx+dy*dy)
 local pull=n>0 and math.max(0,dx/n) or 0
 g.progress=math.min(1,g.progress+pull*dt/.45)
 player.x=g.x-15+g.progress*18;player.y=g.y-12;player.dashing=false
 if g.progress>=1 then
  a.removedTeeth[g.index]=true;a.grab=nil
  -- Release into clear space rather than the next tooth's collision pixels.
  local limit=a.head.x+a.head.w/2+6
  while player.x<limit and J.blocked(a,player.x,player.y) do player.x=player.x+3 end
  a.fragments[#a.fragments+1]={x=g.x,y=g.y,age=0,vy=-90}
  a.hurt(1)
  -- A fresh row supplies the remaining damage when a tougher boss outlives six teeth.
  if not a.defeated then
   local remaining=0;for index=1,6 do if not a.removedTeeth[index] then remaining=remaining+1 end end
   if remaining==0 then
    for index=1,math.min(6,a.hp) do a.removedTeeth[index]=nil end
    a.toothTargets={}
   end
  end
  BossFX.burst(g.x,g.y,{.9,.85,.6},1)
 end
end
function J.draw(a)
 if a.defeated or not a.open then return end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for index in pairs(a.removedTeeth) do g.setColor(.002,.004,.008,1);g.polygon('fill',J.polygon(a,index)) end
 for _,index in ipairs(order) do if not a.removedTeeth[index] then
  g.setColor(.8,.72,.4,.8);g.polygon('fill',J.polygon(a,index))
  g.setColor(1,.92,.65,.9);g.setLineWidth(1);g.polygon('line',J.polygon(a,index))
 end end
 if a.grab and not (Abyss and Abyss.playerHidden()) then
  local p=a.grab
  g.setColor(.03,.025,.01,.9);g.rectangle('fill',p.x-20,p.y-31,40,4)
  g.setColor(1,.9,.55);g.rectangle('fill',p.x-20,p.y-31,40*p.progress,4)
  for i=1,3 do local x=p.x+25+i*12;g.line(x-4,p.y-5,x+1,p.y,x-4,p.y+5) end
 end
 for _,f in ipairs(a.fragments) do g.setColor(.9,.85,.65,1-f.age);g.polygon('fill',f.x-5,f.y-8,f.x+5,f.y-5,f.x,f.y+11) end
 g.pop()
end
return J
