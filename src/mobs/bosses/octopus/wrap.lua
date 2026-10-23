-- The SVG skin follows raised strikes, the player's grip and a wound coil.
local W={}
local tau=math.pi*2
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function delta(a,b)return (a-b+math.pi)%tau-math.pi end
local function distance(x,y)return math.sqrt(x*x+y*y)end
local function points(raw)
 local length=0
 for i,p in ipairs(raw) do
  local a,b=raw[math.max(1,i-1)],raw[math.min(#raw,i+1)]
  local d=math.max(.001,distance(b.x-a.x,b.y-a.y))
  if i>1 then length=length+distance(p.x-a.x,p.y-a.y)end
  p.nx,p.ny=-(b.y-a.y)/d,(b.x-a.x)/d;p.distance=length
  p.width=18*(1-(i-1)/(#raw-1))^.65+2.4
 end
 return raw
end
function W.install(O)
 local reset=O.reset
 function O.reset(active)
  reset(active);O.wrapArms={};O.wrapRest={};O.grip=nil;O.unwind=nil;O.attackClock=.7;O.attackSerial=0;O.guardClock=0;O.shot=1.5
  player.inkCoat=0;player.inkWobble=0
 end
 function O.updateTether()end
 function O.hurt()end
 function O.releaseCrabs()end
 function O.resizeWrap(ratio)
  for _,p in pairs(O.wrapArms or {})do if p.tx then p.tx=p.tx*ratio end end
  for _,p in ipairs({O.grip or false,O.unwind or false})do if p then
   p.x=p.x*ratio;p.start=math.atan2(math.sin(p.start),math.cos(p.start)*ratio)
   if p.last then p.last=math.atan2(math.sin(p.last),math.cos(p.last)*ratio)end
  end end
 end
 function O.drawInk()end
 function O.startStrike(arm,grabbable)
  local dx,dy=player.x+15-O.x,player.y+12-O.y;local d=math.max(1,distance(dx,dy))
  local reach=clamp(d,150,255)
  O.wrapArms[arm]={arm=arm,phase='raise',age=0,tx=clamp(O.x+dx/d*reach,45,Arena.width-45),ty=clamp(O.y+dy/d*reach,55,545),grabbable=grabbable}
 end
 function O.grab(p)
  if O.grip or O.unwind or not p.grabbable or p.phase~='ground' then return end
  local a=math.atan2(player.y+12-O.y,player.x+15-O.x)
  O.grip={arm=p.arm,start=a,last=a,progress=0,dir=0,x=p.tx,y=p.ty};O.rider={arm=p.arm};p.phase='held';O.guardClock=.7
 end
 function O.completeWrap()
  local t=O.grip;if not t then return end
  O.hp=math.max(0,O.hp-1);O.flash=.4
  O.unwind={arm=t.arm,start=t.start,dir=t.dir,progress=t.progress,age=0,x=player.x+15,y=player.y+12,angle=O.angle}
  O.grip=nil;O.rider=nil;O.wrapArms={};O.attackClock=1
  BossFX.burst(O.x,O.y,{.35,.8,.9},3)
 end
 function O.contact()
  if not O.active or O.defeated or O.liberating or player.reset then return end
  local px,py=player.x+15,player.y+12
  if distance(px-O.x,py-O.y)<72 then Hazards.kill('octopus');return end
  for _,p in pairs(O.wrapArms or {}) do
   if p.phase=='slam' then
    local dx,dy=p.tx-O.x,p.ty-O.y;local d=dx*dx+dy*dy
    local t=clamp(((px-O.x)*dx+(py-O.y)*dy)/math.max(1,d),0,1)
    if distance(px-O.x-t*dx,py-O.y-t*dy)<23 then Hazards.kill('octopus');return end
   elseif p.phase=='ground' and p.grabbable and distance(px-p.tx,py-p.ty)<30 and not (Bosses and Bosses.otherRider(O)) then
    O.grab(p)
   end
  end
 end
 function O.update(dt)
  if not O.active or player.reset or O.defeated or O.liberating then return end
  O.clock=O.clock+dt;O.flash=math.max(0,O.flash-dt)
  if O.unwind then
   local u=O.unwind;u.age=u.age+dt;local t=clamp(u.age/.85,0,1)
   O.angle=u.angle-u.dir*t*tau;u.progress=(1-t)*tau
   if t==1 then
    O.unwind=nil;O.angle=O.angle%tau
    if O.hp==0 then require('boss_liberation').start(O,'octopus',function()
     O.defeated=true;O.inkPools={};O.projectiles={};objet.larme.taken=false;objet.larme.x=O.x-15;objet.larme.y=O.y-20
    end) end
   end
  elseif O.grip then
   local t=O.grip;local px,py=player.x+15,player.y+12;local r=distance(px-O.x,py-O.y)
   local a=math.atan2(py-O.y,px-O.x);local change=delta(a,t.last);t.last=a
   if r>330 then O.wrapArms[t.arm]=nil;O.grip=nil;O.rider=nil;O.attackClock=.7
   else
    if r>=95 and math.abs(change)<.5 then
     if t.dir==0 and math.abs(change)>.002 then t.dir=change>0 and 1 or -1 end
     t.progress=math.max(0,t.progress+change*t.dir)
    end
    O.rider={arm=t.arm}
    if t.progress>=tau-.08 and distance(px-t.x,py-t.y)<55 then O.completeWrap() end
    O.guardClock=O.guardClock-dt
    if O.grip and O.guardClock<=0 then
     local count=math.min(7,O.maxHp-O.hp)
     for i=1,count do local arm=(t.arm+i-1)%8+1
      if not O.wrapArms[arm] then O.wrapArms[arm]={arm=arm,phase='wait',age=-.16*(i-1),grabbable=false}end
     end
     O.guardClock=2.2
    end
   end
  else
   O.attackClock=O.attackClock-dt
   if O.attackClock<=0 then
    O.attackSerial=O.attackSerial+1;O.startStrike((O.attackSerial-1)%8+1,true);O.attackClock=7
   end
  end
  for arm,p in pairs(O.wrapArms) do
   p.age=p.age+dt
   if p.phase=='wait' and p.age>=0 then O.startStrike(arm,false)
   elseif p.phase=='raise' and p.age>=.8 then p.phase='slam';p.age=0
   elseif p.phase=='slam' and p.age>=.16 then p.phase='ground';p.age=0
   elseif p.phase=='ground' and p.age> (p.grabbable and 5 or .35) then O.wrapArms[arm]=nil
   end
  end
  O.shot=O.shot-dt
  if O.shot<=0 and not O.unwind then O.ink();O.shot=2.5 end
  -- Ground ink coats the player rather than obscuring the screen.
  for i=#O.projectiles,1,-1 do local p=O.projectiles[i]
   p.age=p.age+dt;local t=math.min(1,p.age/.85)
   p.x=p.fromX+(p.tx-p.fromX)*t;p.y=p.fromY+(p.ty-p.fromY)*t
   if t==1 then O.inkPools[#O.inkPools+1]={x=p.tx,y=p.ty,rx=42,ry=30,life=6,seed=O.inkCount};table.remove(O.projectiles,i)end
  end
  for i=#O.inkPools,1,-1 do local p=O.inkPools[i];p.life=p.life-dt
   if p.life<=0 then table.remove(O.inkPools,i)
   elseif Hazards.inEllipse(player.x+15,player.y+12,p,0) then player.inkCoat=2.3 end
  end
  O.contact()
 end
 function O.wrapCurve(arm)
  local p=O.wrapArms[arm];local t=O.grip or O.unwind
  local raw={}
  if t and t.arm==arm then
   local winding=(t.dir==0 and 1 or t.dir)*t.progress
   local endX,endY=player.x+15,player.y+12
   if O.unwind then endX,endY=O.unwind.x,O.unwind.y end
   for i=0,64 do local q=i/64;local a=t.start+winding*math.min(1,q/.78);local radius=82
    local x,y=math.cos(a)*radius,math.sin(a)*radius
    if q>.78 then local f=(q-.78)/.22;x=x+(endX-O.x-x)*f;y=y+(endY-O.y-y)*f end
    raw[#raw+1]={x=x,y=y}
   end
  elseif p and p.tx then
   local a=math.atan2(p.ty-O.y,p.tx-O.x);local bx,by=math.cos(a)*42,math.sin(a)*42
   local lift=p.phase=='raise' and math.sin(math.min(1,p.age/.8)*math.pi*.5)*95 or 0
   for i=0,64 do local q=i/64
    raw[#raw+1]={x=bx+(p.tx-O.x-bx)*q,y=by+(p.ty-O.y-by)*q-lift*math.sin(q*math.pi*.7)}
   end
  else
   O.wrapRest=O.wrapRest or {};local cached=O.wrapRest[arm]
   if cached and cached.angle==O.angle then return cached.points end
   local rest=O.armCurve(arm);local c,s=math.cos(O.angle),math.sin(O.angle)
   for _,v in ipairs(rest)do raw[#raw+1]={x=v.x*c-v.y*s,y=v.x*s+v.y*c}end
  end
  local result=points(raw)
  if not p and not (t and t.arm==arm) then O.wrapRest[arm]={angle=O.angle,points=result}end
  return result
 end
 function O.drawArms()
  local g=love.graphics;g.push('all');g.setShader();g.translate(O.x,O.y)
  O.wrapMeshes=O.wrapMeshes or {}
  for arm=1,8 do
   local p=O.wrapArms[arm]
   if p and p.tx and p.phase=='raise' then
    g.setColor(1,.55,.1,.2+.2*p.age/.8);g.setLineWidth(34);g.line(0,0,p.tx-O.x,p.ty-O.y)
   end
   O.wrapMeshes[arm]=require('mobs.bosses.octopus.tentacle').draw(O.wrapCurve(arm),1,0,O.wrapMeshes[arm])
   if p and p.grabbable and p.phase=='ground' then
    g.setColor(.6,1,.9,.8);g.setLineWidth(2.5);g.circle('line',p.tx-O.x,p.ty-O.y,15+math.sin(O.clock*7)*2)
   end
  end
  g.pop()
 end
end
return W
