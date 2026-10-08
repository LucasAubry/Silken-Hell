local B={count=2,ropeLength=160}
local probes={{0,0},{12,0},{-12,0},{0,12},{0,-12}}
local function noise(n) return math.sin(n*127.1)*43758.5453%1 end
function B.destination(id,round)
 local n=id+(round or 0)*97
 return 90+noise(n)*math.max(1,Arena.width-370),185+noise(n+41)*330
end
function B.spawn(a,fromX,fromY)
 a.bombLayoutSerial=(a.bombLayoutSerial or 0)+1
 a.bombs={}
 for i=1,B.count do
  local x,y=B.destination(i,a.bombLayoutSerial)
  a.bombs[i]={x=fromX or x,y=fromY or y,tx=x,ty=y,fromX=fromX,fromY=fromY,flight=fromX and 0 or nil,r=15}
 end
end
local function nearSegment(x,y,ax,ay,bx,by,r)
 local dx,dy=bx-ax,by-ay;local t=math.max(0,math.min(1,((x-ax)*dx+(y-ay)*dy)/math.max(.001,dx*dx+dy*dy)))
 return (x-ax-dx*t)^2+(y-ay-dy*t)^2<=r*r
end
function B.explode(a,b)
 if b.hit then return end
 b.hit=true;b.attached=false
 if (player.x+15-b.x)^2+(player.y+12-b.y)^2<65^2 then Hazards.kill('abyss_bomb') end
 for _,list in ipairs({a.lumenParticles or {},Realms.fireflies or {}})do for _,p in ipairs(list)do
  if not p.consumed then
   local dx,dy=p.x-b.x,p.y-b.y;local d=math.sqrt(dx*dx+dy*dy)
   if d<180 then
    local nx,ny=d>.01 and dx/d or 1,d>.01 and dy/d or 0
    local impulse=650*(1-d/180)
    p.scatter=nil;p.exhaled=false;p.wakeVx=(p.wakeVx or 0)+nx*impulse;p.wakeVy=(p.wakeVy or 0)+ny*impulse
   end
  end
 end end
 BossFX.burst(b.x,b.y,{1,.48,.12},6)
 a.bombBursts=a.bombBursts or {};a.bombBursts[#a.bombBursts+1]={x=b.x,y=b.y,age=0}
end
function B.tooth(a,p,ox,oy)
 if not p.tooth or (p.throatTravel or 0)>0 then return false end
 for _,b in ipairs(a.bombs or {})do
  if not b.hit and (b.armDelay or 0)<=0 and not b.swallowAge and nearSegment(b.x,b.y,ox,oy,p.x,p.y,b.r+5) then
   local attached=b.attached;B.explode(a,b)
   if attached then Hazards.kill('abyss_bomb') end
   -- A shot can clear a mine; only swallowing it wounds the boss.
   if (player.x+15-b.x)^2+(player.y+12-b.y)^2<65^2 then Hazards.kill('abyss_bomb') end
   return true
  end
 end
 return false
end
function B.launch(a)
 local mx,my=a.mouth()
 local tx,ty=player.x+15,player.y+12
 a.bombs[#a.bombs+1]={x=mx,y=my,fromX=mx,fromY=my,tx=tx,ty=ty,flight=0,flightDuration=1,r=15}
end
local function bossHit(a,b)
 if a.physicsTest or a.phase~='traverse' or a.defeated then return false end
 for _,bone in ipairs(a.bones or {})do
  local dx,dy=b.x-bone.x,b.y-bone.y
  local radius=math.max(bone.w,bone.h)*.55+b.r
  if dx*dx+dy*dy<radius*radius then
  for _,offset in ipairs(probes)do
   if a.boneTouches(bone,b.x+offset[1],b.y+offset[2]) then return true end
  end end
 end
 return false
end
function B.beginFrame(a,dt)
 local x,y=player.x+15,player.y+12
 a.ropeFrame={x=a.ropeFrameX or x,y=a.ropeFrameY or y,tx=x,ty=y,dt=dt,elapsed=0}
 a.ropeFrameX,a.ropeFrameY=x,y
end
local function protectPlayer(a,b,px,py)
 local dx,dy=b.x-px,b.y-py;local d=math.sqrt(dx*dx+dy*dy);local safe=b.r+24
 -- A collected bomb keeps its exact position until the player has walked clear.
 if b.pickupOverlap then
  if d<safe then return end
  b.pickupOverlap=nil
 end
 if d<safe then
  local nx,ny=d>.01 and dx/d or -(a.ropeDirX or 0),d>.01 and dy/d or -(a.ropeDirY or 1)
  b.x,b.y=px+nx*safe,py+ny*safe
  local inward=(b.vx or 0)*nx+(b.vy or 0)*ny
  if inward<0 then b.vx=b.vx-inward*nx;b.vy=b.vy-inward*ny end
 end
end
function B.update(a,dt)
 local px,py=player.x+15,player.y+12
 local frame=a.ropeFrame
 if frame then
  frame.elapsed=math.min(frame.dt,frame.elapsed+dt);local t=frame.dt>0 and frame.elapsed/frame.dt or 1
  px=frame.x+(frame.tx-frame.x)*t;py=frame.y+(frame.ty-frame.y)*t
 end
 local oldX,oldY=a.ropePlayerX or px,a.ropePlayerY or py
 local dx,dy=px-oldX,py-oldY;local moved=math.sqrt(dx*dx+dy*dy)
 if moved>.01 then
  local mix=1-math.exp(-dt*12)
  local ux=(a.ropeDirX or dx/moved)*(1-mix)+dx/moved*mix
  local uy=(a.ropeDirY or dy/moved)*(1-mix)+dy/moved*mix
  local length=math.sqrt(ux*ux+uy*uy)
  if length>.001 then a.ropeDirX,a.ropeDirY=ux/length,uy/length end
 end
 local ax,ay=px-(a.ropeDirX or 0)*14,py-(a.ropeDirY or 1)*14
 local avx,avy=(ax-(a.ropeAnchorX or ax))/dt,(ay-(a.ropeAnchorY or ay))/dt
 a.ropeAnchorX,a.ropeAnchorY=ax,ay;a.ropePlayerX,a.ropePlayerY=px,py
 for _,b in ipairs(a.bombs or {})do if not b.hit then
  b.previousX,b.previousY=b.x,b.y
  b.pickupGrace=math.max(0,(b.pickupGrace or 0)-dt)
  if b.flight then
   b.flight=math.min(1,b.flight+dt/(b.flightDuration or .4));local t=1-(1-b.flight)^2
   b.x=b.fromX+(b.tx-b.fromX)*t;b.y=b.fromY+(b.ty-b.fromY)*t
   b.vx=(b.x-b.previousX)/dt;b.vy=(b.y-b.previousY)/dt
   if b.flight==1 then b.flight=nil;b.vx=0;b.vy=0 end
  elseif b.attached then
   b.ropeLength=B.ropeLength
   b.vx=(b.vx or 0)*math.exp(-dt*.65);b.vy=(b.vy or 0)*math.exp(-dt*.65)
   b.x=b.x+b.vx*dt;b.y=b.y+b.vy*dt
   local rx,ry=b.x-ax,b.y-ay;local d=math.sqrt(rx*rx+ry*ry)
   if d>B.ropeLength then
    b.x=ax+rx/d*B.ropeLength;b.y=ay+ry/d*B.ropeLength
    -- An inextensible thread pulls the bomb but preserves its sideways momentum.
    local nx,ny=rx/d,ry/d
    local outward=(b.vx-avx)*nx+(b.vy-avy)*ny
    if outward>0 then b.vx=b.vx-outward*nx;b.vy=b.vy-outward*ny end
   end
   protectPlayer(a,b,px,py)
  end
  if Arena.blocked(b.x-b.r,b.y-b.r,b.r*2,b.r*2) then B.explode(a,b)
  elseif not b.flight then
   if bossHit(a,b) then
    B.explode(a,b);a.bombsEaten=(a.bombsEaten or 0)+1
    require('mobs.bosses.abyss.bone_stock').speed(a);a.hurt(1)

   end
  end
 end end
 for i,b in ipairs(a.bombs or {})do if not b.hit then
  for j=i+1,#a.bombs do local q=a.bombs[j]
   if not q.hit then
    local dx,dy=q.x-b.x,q.y-b.y;local d=math.sqrt(dx*dx+dy*dy);local radius=b.r+q.r
    if d<radius and (b.pickupGrace or 0)==0 and (q.pickupGrace or 0)==0 then
     local nx,ny=d>.01 and dx/d or 1,d>.01 and dy/d or 0
     local closing=((b.vx or 0)-(q.vx or 0))*nx+((b.vy or 0)-(q.vy or 0))*ny
     if closing>120 then B.explode(a,b);B.explode(a,q)
     else
      local push=(radius-d)/2+.01
      if b.attached then b.x=b.x-nx*push;b.y=b.y-ny*push end
      if q.attached then q.x=q.x+nx*push;q.y=q.y+ny*push end
      if closing>0 then
       b.vx=(b.vx or 0)-nx*closing*.6;b.vy=(b.vy or 0)-ny*closing*.6
       q.vx=(q.vx or 0)+nx*closing*.6;q.vy=(q.vy or 0)+ny*closing*.6
      end
     end
    end
   end
  end
 end end
 -- Pair separation must not stretch either thread beyond its fixed length.
 for _,b in ipairs(a.bombs or {})do if b.attached and not b.hit then
  local dx,dy=b.x-ax,b.y-ay;local d=math.sqrt(dx*dx+dy*dy)
  if d>B.ropeLength then b.x=ax+dx/d*B.ropeLength;b.y=ay+dy/d*B.ropeLength end
  protectPlayer(a,b,px,py)
  if Arena.blocked(b.x-b.r,b.y-b.r,b.r*2,b.r*2)then B.explode(a,b)end
 end end
 for i=#(a.bombBursts or {}),1,-1 do local b=a.bombBursts[i];b.age=b.age+dt;if b.age>.5 then table.remove(a.bombBursts,i)end end
end
function B.player(a)
 local px,py=player.x+15,player.y+12
 local ox,oy=a.bombPlayerX or px,a.bombPlayerY or py;a.bombPlayerX=px;a.bombPlayerY=py
 if player.abyssSpit or a.carryPlayer then return end
 for _,b in ipairs(a.bombs or {})do
  if not b.hit and not b.attached and nearSegment(0,0,ox-(b.previousX or b.x),oy-(b.previousY or b.y),px-b.x,py-b.y,b.r+12) then
   b.flight=nil;b.attached=true;b.ropeLength=B.ropeLength;b.pickupGrace=.35;b.clearedPlayer=false
   b.vx=0;b.vy=0
   b.pickupOverlap=true
  end
 end
end
function B.mouth(a,mx,my,dt)
 -- Bombs now strike the whole body instead of being swallowed.
 a.open=(a.toothOpen or 0)>0
end

function B.draw(a)
 local g=love.graphics;g.push('all')
 for _,b in ipairs(a.bombs or {})do if not b.hit and not b.inside then
  if b.attached then
   local ax,ay=a.ropeAnchorX or player.x+15,a.ropeAnchorY or player.y+12
   local d=math.sqrt((b.x-ax)^2+(b.y-ay)^2);local slack=math.max(0,b.ropeLength-d)*.18
   g.setBlendMode('alpha');g.setColor(.65,.83,.95,.3);g.setLineWidth(2.5)
   g.line(ax,ay,(ax+b.x)/2,(ay+b.y)/2+slack,b.x,b.y)
   g.setColor(.9,.96,1,.85);g.setLineWidth(.8);g.line(ax,ay,(ax+b.x)/2,(ay+b.y)/2+slack,b.x,b.y)
  end
  g.push();g.translate(b.x,b.y);local scale=(1-.35*math.min(1,(b.swallowAge or 0)/.12))*(1-.8*(b.armDelay or 0));g.scale(scale);g.translate(-b.x,-b.y)
  g.setColor(.07,.08,.11);g.circle('fill',b.x,b.y,b.r)
  g.setColor(1,.4,.12);g.setLineWidth(2);g.circle('line',b.x,b.y,b.r)
  g.setColor(.8,.63,.3);g.line(b.x+3,b.y-b.r,b.x+6,b.y-b.r-8,b.x+11,b.y-b.r-10)
  g.setBlendMode('add');g.setColor(1,.65,.15,.6+.2*math.sin(a.clock*16));g.circle('fill',b.x+11,b.y-b.r-10,3);g.setBlendMode('alpha')
  g.setColor(.6,.72,.8,.65);g.circle('fill',b.x-4,b.y-5,3)
  if b.attached then
   g.setColor(.96,.98,1,.95);g.setLineWidth(1.2)
   g.ellipse('line',b.x,b.y,b.r+1,b.r*.58)
   g.push();g.translate(b.x,b.y);g.rotate(-.65)
   g.ellipse('line',0,0,b.r*.54,b.r+1);g.pop()
   g.setColor(1,1,1,.85);g.circle('line',b.x,b.y,b.r+1)
  end
  g.pop()
 end end
 g.setBlendMode('add')
 for _,b in ipairs(a.bombBursts or {})do local t=b.age/.5
  g.setColor(1,.35,.08,(1-t)*.6);g.circle('fill',b.x,b.y,12+t*68)
  g.setColor(1,.85,.4,1-t);g.setLineWidth(4*(1-t)+1);g.circle('line',b.x,b.y,15+t*95)
 end
 g.pop()
end
return B
