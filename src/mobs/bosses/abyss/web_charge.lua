local M={}
local function pointDistance(x,y,ax,ay,bx,by)
 local dx,dy=bx-ax,by-ay;local t=math.max(0,math.min(1,((x-ax)*dx+(y-ay)*dy)/math.max(.001,dx*dx+dy*dy)))
 return (x-ax-dx*t)^2+(y-ay-dy*t)^2
end
function M.delay(a) return .65+2.5*(a.hp-1)/(a.maxHp-1) end
function M.setup(a)
 a.webMode=true;a.physicsTest=false;App.abyssPhysicsTest=false
 a.phase='traverse';a.hp=8;a.maxHp=8;a.webSegments=6;a.webTail=true
 a.webScale=1.05;a.swimHead={x=Arena.width*.70,y=210};a.swimAngle=0;a.swimPath={};a.open=false
 for d=600,0,-6 do a.swimPath[#a.swimPath+1]={x=a.swimHead.x-d,y=a.swimHead.y} end
 a.bombs={};a.debris={};a.threads={};a.webLinks={};a.webHeld=nil;a.webCharge=false;a.webTimer=3.2;a.webSerial=0;a.webFlee=0
 a.webAnchors={}
 for i,p in ipairs({{.45,410}})do
  a.webAnchors[i]={x=Arena.width*p[1],y=p[2],parts={{key='skeleton_spine',x=Arena.width*p[1],y=p[2],w=50,h=28,angle=i*.8}}}
 end
 player.abyssSpit=nil;player.abyssHeld=nil;player.abyssGrace=0;a.carryPlayer=false;a.grab=nil
 a.buildBones()
end
function M.weave(a)
 local px,py=player.x+15,player.y+12
 for i,p in ipairs(a.webAnchors)do if (px-p.x)^2+(py-p.y)^2<29^2 then
  if a.webHeld and a.webHeld~=i then
   local exists=false
   for _,link in ipairs(a.webLinks)do if not link.broken and ((link.a==i and link.b==a.webHeld) or (link.b==i and link.a==a.webHeld))then exists=true end end
   if not exists then a.webLinks[#a.webLinks+1]={a=a.webHeld,b=i} end
  end
  a.webHeld=i;break
 end end
end
function M.contact(a)
 if a.defeated or player.reset then return end
 M.weave(a)
 if a.physicsTest then return end
 for _,b in ipairs(a.bones)do if a.overlapsBone(b)then Hazards.kill('abyss_bite');return end end
end
function M.hit(a,obstacle)
 if not a.webCharge or a.hp<=0 then return end
 a.webCharge=false;a.open=false
 if obstacle then obstacle.blocked=true;if obstacle.a then obstacle.broken=true end end
 local parts={};local part=a.webTail and 'tail' or a.webSegments
 for _,b in ipairs(a.bones)do if b.part==part then
  parts[#parts+1]={key=b.key,x=b.x,y=b.y,w=b.w,h=b.h,angle=b.angle}
 end end
 if #parts>0 then
  local p=parts[1];a.webAnchors[#a.webAnchors+1]={x=p.x,y=p.y,parts=parts,blocked=true,detachedAt=a.clock}
 end
 if a.webTail then a.webTail=false elseif a.webSegments>0 then a.webSegments=a.webSegments-1 end
 a.webFlee=.85
 a.webFleeAngle=math.atan2(a.swimHead.y-player.y-12,a.swimHead.x-player.x-15)
 a.hurt(1);a.webTimer=M.delay(a);a.webSerial=a.webSerial+1;a.buildBones()
end
local function collides(a,x,y,r)
 for _,p in ipairs(a.webAnchors)do
  if not p.blocked and (x-p.x)^2+(y-p.y)^2<(r+18)^2 then return p end
 end
 for _,link in ipairs(a.webLinks)do if not link.broken then
  local p,q=a.webAnchors[link.a],a.webAnchors[link.b]
  if pointDistance(x,y,p.x,p.y,q.x,q.y)<r*r then return link end
 end end
end
function M.update(a,dt)
 if a.defeated or player.reset or a.hp<=0 then return end
 local steps=math.max(1,math.ceil(dt*240));local step=dt/steps
 for _=1,steps do
  a.clock=a.clock+step;a.flash=math.max(0,a.flash-step)
  M.weave(a)
  if not a.physicsTest then
   for _,p in ipairs(a.webAnchors)do if p.blocked then
    local clear=true;for _,b in ipairs(a.bones)do if (b.x-p.x)^2+(b.y-p.y)^2<85^2 then clear=false;break end end
    if clear then p.blocked=false end
   end end
   local fleeing=(a.webFlee or 0)>0
   if fleeing then a.webFlee=math.max(0,a.webFlee-step) else a.webTimer=a.webTimer-step end
   if not a.webCharge and not fleeing and a.webTimer<=0 then
    a.webCharge=true;a.open=true
    a.swimAngle=math.atan2(player.y+12-a.swimHead.y,player.x+15-a.swimHead.x)
    a.webTimer=.8
   end
   local ox,oy=a.swimHead.x,a.swimHead.y
   local previous=a.bones
   if not a.webCharge then
    local h=a.swimHead
    local target=fleeing and a.webFleeAngle or math.atan2(player.y+12-h.y,player.x+15-h.x)
    -- Steer back into the arena before an escape reaches its boundary.
    local vx,vy=math.cos(target),math.sin(target)
    if h.x<170 then vx=vx+(170-h.x)/45 elseif h.x>Arena.width-170 then vx=vx-(h.x-Arena.width+170)/45 end
    if h.y<170 then vy=vy+(170-h.y)/45 elseif h.y>430 then vy=vy-(h.y-430)/45 end
    target=math.atan2(vy,vx)
    local delta=(target-a.swimAngle+math.pi)%(2*math.pi)-math.pi
    local turnRate=fleeing and 5 or 2.4
    a.swimAngle=a.swimAngle+math.max(-turnRate*step,math.min(turnRate*step,delta))
   end
   local speed=a.webCharge and 1450 or (fleeing and 230 or 190)
   a.swimHead.x=ox+math.cos(a.swimAngle)*speed*step
   a.swimHead.y=oy+math.sin(a.swimAngle)*speed*step
   local edge=a.swimHead.x<100 or a.swimHead.x>Arena.width-100 or a.swimHead.y<105 or a.swimHead.y>495
   if edge then
    a.swimHead.x=math.max(100,math.min(Arena.width-100,a.swimHead.x));a.swimHead.y=math.max(105,math.min(495,a.swimHead.y))
   end
   a.buildBones()
   if a.webCharge then
    local struck
    for k=0,2 do
     local t=k/2
     for i,b in ipairs(a.bones)do
      local old=previous[i] or b
      struck=collides(a,old.x+(b.x-old.x)*t,old.y+(b.y-old.y)*t,(b.part=='head' and 34 or 12)*(a.webScale or 1))
      if struck then
       a.swimHead.x=ox+(a.swimHead.x-ox)*t;a.swimHead.y=oy+(a.swimHead.y-oy)*t
       a.buildBones();M.hit(a,struck);break
      end
     end
     if struck then break end
    end
   end
   if a.webCharge and (edge or a.webTimer<=0)then a.webCharge=false;a.open=false;a.webTimer=M.delay(a)end
   local last=a.swimPath[#a.swimPath]
   if not last or (last.x-a.swimHead.x)^2+(last.y-a.swimHead.y)^2>36 then
    a.swimPath[#a.swimPath+1]={x=a.swimHead.x,y=a.swimHead.y};if #a.swimPath>180 then table.remove(a.swimPath,1)end
   end
  end
  M.contact(a);if player.reset or a.hp<=0 then break end
 end
end
function M.draw(a)
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 for _,p in ipairs(a.webAnchors)do
  local age=p.detachedAt and math.max(0,a.clock-p.detachedAt)
  if age then
   -- Keep the original bone tint; only the surrounding motes mark the drop.
   local pulse=.5+.5*math.sin(a.clock*2.6)
   g.setColor(.65,.85,1,.035+pulse*.025);g.circle('fill',p.x,p.y,35)
   g.setColor(.82,.94,1)
  else g.setColor(.82,.94,1) end
  for _,b in ipairs(p.parts)do Art.draw(b.key,b.x,b.y,b.w,b.angle,b.h)end
  if age then
   g.setColor(.75,.9,1,.55);g.setLineWidth(1.5);g.circle('line',p.x,p.y,22)
   -- Analytic particles require no simulation, allocations or growing particle list.
   for j,b in ipairs(p.parts)do
    if age<1.15 then
     local fade=1-age/1.15
     for i=1,18 do
      local angle=i*2.39996+j;local speed=35+(i*29%70)
      local travel=speed*age/(1+age*1.8)
      local x=b.x+math.cos(angle)*travel
      local y=b.y+math.sin(angle)*travel-age*12
      g.setColor(.65,.85,1,fade*.16);g.circle('fill',x,y,6*fade+2)
      g.setColor(.88,.95,1,fade);g.circle('fill',x,y,1+fade*(i%3)*.6)
     end
    end
    for i=1,3 do
     local t=(a.clock*.35+i/3+j*.17)%1
     local x=b.x+math.sin(i*2.4+j)*18;local y=b.y+10-t*35
     g.setColor(.8,.92,1,math.sin(t*math.pi)*.5);g.circle('fill',x,y,1.3)
    end
   end
  else
   g.setColor(.6,.85,1,.45);g.setLineWidth(1);g.circle('line',p.x,p.y,21)
  end
 end
 for _,link in ipairs(a.webLinks)do if not link.broken then
  local p,q=a.webAnchors[link.a],a.webAnchors[link.b]
  g.setColor(.4,.7,1,.2);g.setLineWidth(5);g.line(p.x,p.y,q.x,q.y)
  g.setColor(.95,.98,1,.95);g.setLineWidth(1.5);g.line(p.x,p.y,q.x,q.y)
 end end
 if a.webHeld then
  local p=a.webAnchors[a.webHeld]
  g.setColor(.8,.9,1,.45);g.setLineWidth(1);g.line(p.x,p.y,player.x+15,player.y+12)
 end
 g.pop()
end
return M
