-- Gather storm sparks, then discharge them through a rod. Carrying three sparks
-- trades a stronger hit for a short overload deadline; no extra input is needed.
local C={}
function C.reset(s)
 s.charges=0;s.overload=0;s.pickups={};s.rods={};s.discharge=nil
end
local function safe(s,x,y,occupied)
 if not s.targetSafe(x,y) then return false end
 for _,p in ipairs(occupied) do if (p.x-x)^2+(p.y-y)^2<72^2 then return false end end
 return true
end
function C.place(s)
 local occupied={}
 for _,list in ipairs({s.rods,s.pickups}) do
  for _,p in ipairs(list) do if p.x and s.targetSafe(p.x,p.y) then occupied[#occupied+1]=p else p.invalid=true end end
 end
 local function position(p,fx,fy)
  if not p.invalid and p.x then return end
  local x,y=Arena.width*fx,fy
  if not safe(s,x,y,occupied) then
   local found=false
   for row=0,7 do for col=0,11 do
    local tx,ty=65+col*(Arena.width-130)/11,75+row*64
    if not found and safe(s,tx,ty,occupied) then x,y=tx,ty;found=true end
   end end
   if not found then p.invalid=true;return end
  end
  p.x,p.y,p.invalid=x,y,false;occupied[#occupied+1]=p
 end
 for i=1,2 do
  local p=s.rods[i] or {cooldown=0};s.rods[i]=p;position(p,i==1 and .17 or .83,300)
 end
 for i,site in ipairs({{.5,155},{.5,445},{.5,300}}) do
  local p=s.pickups[i] or {cooldown=0};s.pickups[i]=p;position(p,site[1],site[2])
 end
end
function C.discharge(s,p)
 local charges=s.charges
 if charges==0 or p.cooldown>0 or s.phase~='orbit' then return false end
 s.discharge={x=p.x,y=p.y,tx=s.x,ty=s.y,life=.45}
 s.hp=math.max(0,s.hp-(charges==3 and 4 or charges));s.flash=.3
 s.charges=0;s.overload=0;p.cooldown=3
 s.projectiles={};s.strikes={};s.boltsRemaining=0
 BossFX.burst(s.x,s.y,{.5,.85,1},2)
 if Campaign.biome==6 then require('sky_lightning').trigger(s.x,s.y,s.round) end
 if s.hp==0 then s.finish() else
  s.fallSide=p.x<Arena.width*.5 and 0 or 1;s.setPhase('flightTell')
 end
 return true
end
function C.contact(s)
 if s.phase~='orbit' then return end
 C.place(s)
 -- Discharge first: reaching a rod at the overload deadline is a valid save.
 for _,p in ipairs(s.rods) do
  if not p.invalid and require('collision_shapes').touchCircle('storm_rod',p.x,p.y,29) then
   if C.discharge(s,p) then return end
  end
 end
 for _,p in ipairs(s.pickups) do
  if not p.invalid and p.cooldown<=0 and s.charges<3 and require('collision_shapes').touchCircle('storm_spark',p.x,p.y,20) then
   p.cooldown=6;s.charges=s.charges+1
   if s.charges==3 then s.overload=4 end
   BossFX.burst(p.x,p.y,{.5,.85,1},.6)
  end
 end
end
function C.update(s,dt)
 for _,list in ipairs({s.rods,s.pickups}) do for _,p in ipairs(list) do p.cooldown=math.max(0,p.cooldown-dt) end end
 if s.discharge then s.discharge.life=s.discharge.life-dt;if s.discharge.life<=0 then s.discharge=nil end end
 C.contact(s)
 if s.charges==3 then
  s.overload=math.max(0,s.overload-dt)
  if s.overload<=0 then
   if Campaign.biome==6 then require('sky_lightning').trigger(player.x+15,player.y+12,s.round) end
   Hazards.kill('lightning')
  end
 end
end
function C.draw(s)
 local g=love.graphics
 for _,p in ipairs(s.rods) do if not p.invalid then
  local ready=p.cooldown<=0
  g.setColor(.05,.12,.20,.9);g.circle('fill',p.x,p.y,25)
  g.setColor(.45,.8,1,ready and .95 or .3);g.setLineWidth(2);g.circle('line',p.x,p.y,28)
  g.polygon('fill',p.x+3,p.y-21,p.x-10,p.y+2,p.x-1,p.y+2,p.x-4,p.y+21,p.x+11,p.y-3,p.x+2,p.y-3)
 end end
 for _,p in ipairs(s.pickups) do if not p.invalid and p.cooldown<=0 then
  local pulse=.8+.2*math.sin(s.clock*4)
  g.setColor(.25,.65,1,.18*pulse);g.circle('fill',p.x,p.y,23)
  g.setColor(.75,.95,1,pulse);g.setLineWidth(2);g.circle('line',p.x,p.y,13)
  g.polygon('fill',p.x,p.y-8,p.x+5,p.y,p.x,p.y+8,p.x-5,p.y)
 end end
 if s.charges>0 then
  local x,y=player.x+15,player.y+12
  g.setColor(.3,.7,1,.12*s.charges);g.circle('fill',x,y,26+s.charges*9)
  for i=1,s.charges do
   local a=s.clock*2+(i-1)*math.pi*2/s.charges
   g.setColor(.8,.96,1,1);g.circle('fill',x+math.cos(a)*28,y+math.sin(a)*28,4)
  end
  if s.charges==3 then
   g.setColor(1,.32,.18,.8+.2*math.sin(s.clock*18));g.setLineWidth(3)
   g.arc('line','open',x,y,40,-math.pi/2,-math.pi/2+math.max(.001,s.overload/4)*math.pi*2)
  end
 end
 if s.discharge then
  local p=s.discharge;g.setColor(.65,.9,1,p.life/.45);g.setLineWidth(4)
  g.line(p.x,p.y,(p.x+p.tx)*.5+12,(p.y+p.ty)*.5-12,p.tx,p.ty)
 end
end
return C
