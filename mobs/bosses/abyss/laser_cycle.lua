-- Jaw encounter: rush a lit tooth, then pull outward before the bite.
local C={}
local teeth={{1084,363,1070,433,1090,405},{1130,344,1139,402,1149,374},{1185,316,1175,405,1197,365},{1000,716,963,757,990,758},{1057,743,1024,799,1055,785},{1121,790,1085,838,1112,834}}
local function point(a,x,y)
 return a.head.x-200+(x-294)/1054*400,a.head.y-180+(y-42)/932*360
end
function C.tooth(a)
 local t=teeth[a.toothIndex or 1];return point(a,(t[1]+t[3]+t[5])/3,(t[2]+t[4]+t[6])/3)
end
function C.setup(a)
 a.lightSites={};a.octopuses={};a.trail={};a.orbs={};a.shots={};a.vortices={};a.sparks={};a.rifts={}
 a.interior=nil;a.beam=nil;a.beams={};a.mines={};a.pressure=nil;a.threads={};a.ripples={};a.lures={};a.waves={};a.lightMotes={}
 a.phase='closed';a.phaseTime=0;a.duration=1.3;a.open=false;a.energy=0;a.aim=nil;a.grab=nil
 a.hp=#teeth;a.maxHp=#teeth;a.removedTeeth={};a.fragments={};a.toothIndex=1;a.laserHeadY=280
 player.charges=0;player.illuminated=0
end
function C.sheltered() return false end
function C.lockPlayer(a)
 return a.grab~=nil and not a.defeated and not player.reset
end
function C.enter(a,phase)
 a.phase=phase;a.phaseTime=0;a.open=phase=='open';a.eyeBlend=1;a.eyeFrom=nil
 if phase=='open' then
  local available={};for i=1,#teeth do if not a.removedTeeth[i] then available[#available+1]=i end end
  a.toothIndex=available[love.math.random(#available)];a.duration=2.65-.35*(1-a.hp/a.maxHp);a.extracted=false
 elseif phase=='closed' then a.duration=1.05+love.math.random()*.65
 elseif phase=='tell' then a.duration=.5
 elseif phase=='recoil' then a.duration=.8 end
 a.buildBones()
end
function C.contact(a)
 if a.defeated or player.reset or a.grab or a.phase~='open' or a.extracted or a.phaseTime>=a.duration then return end
 local x,y=C.tooth(a)
 if player.dashing and (player.x+15-x)^2+(player.y+12-y)^2<26^2 then
  a.grab={progress=0};player.x=x-15;player.y=y-12;player.dashing=false
 end
end
function C.update(a,dt)
 if a.defeated then return end
 a.clock=a.clock+dt;a.flash=math.max(0,a.flash-dt);a.phaseTime=a.phaseTime+dt
 player.charges=0;player.illuminated=0
 for i=#a.fragments,1,-1 do local p=a.fragments[i];p.age=p.age+dt;p.x=p.x+160*dt;p.y=p.y+p.vy*dt;p.vy=p.vy+170*dt;if p.age>1 then table.remove(a.fragments,i) end end
 -- Resolve the closing instant before extraction, even on a long frame.
 if a.phaseTime>=a.duration then
  if a.phase=='open' then
   local caught=a.grab~=nil;a.grab=nil;C.enter(a,'closed')
   if caught then player.abyssGrace=0;Hazards.kill('abyss_bite');return end
  elseif a.phase=='closed' then C.enter(a,'tell')
  elseif a.phase=='tell' then C.enter(a,'open')
  elseif a.phase=='recoil' then C.enter(a,'closed') end
 end
 if a.grab and not player.reset then
  local dx,dy=Input.move();local length=math.sqrt(dx*dx+dy*dy)
  local outward=length>0 and math.max(0,dx/length) or 0
  a.grab.progress=math.min(1,a.grab.progress+outward*dt/.72)
  local x,y=C.tooth(a);player.x=x-15+a.grab.progress*20;player.y=y-12
  player.has_moved=outward>0;player.dashing=false
  if a.grab.progress>=1 then
   a.fragments[#a.fragments+1]={x=x,y=y,age=0,vy=-65}
   a.removedTeeth[a.toothIndex]=true;a.grab=nil;a.extracted=true
   player.x=math.max(player.x,a.head.x+220);a.hurt(1)
   if not a.defeated then C.enter(a,'recoil') end
  end
 else C.contact(a) end
 a.buildBones()
end
local function polygon(a,t,offset)
 local out={};for i=1,6,2 do local x,y=point(a,t[i],t[i+1]);out[#out+1]=x+(offset or 0);out[#out+1]=y end
 return out
end
function C.draw(a)
 if a.defeated or not a.head then return end
 local g=love.graphics;g.push('all');g.setBlendMode('alpha')
 if a.open then
  for i in pairs(a.removedTeeth) do g.setColor(.006,.013,.022,1);g.polygon('fill',polygon(a,teeth[i])) end
  local x,y=C.tooth(a);local danger=a.duration-a.phaseTime<.6
  local c=danger and {1,.24,.12} or {.55,1,.88}
  local offset=a.grab and a.grab.progress*20 or 0
  for r=3,1,-1 do g.setColor(c[1],c[2],c[3],.055);g.circle('fill',x+offset,y,9+r*6) end
  g.setColor(c[1],c[2],c[3],1);g.polygon('fill',polygon(a,teeth[a.toothIndex],offset))
  g.setLineWidth(2);g.setColor(1,1,1,.9);g.polygon('line',polygon(a,teeth[a.toothIndex],offset))
  -- Outward chevrons teach the pull without adding a text panel.
  if a.grab then
   for i=1,3 do local xx=x+35+i*14;g.setColor(c[1],c[2],c[3],.35+.6*((a.clock*2+i/3)%1));g.line(xx-5,y-6,xx+1,y,xx-5,y+6) end
   g.setColor(.02,.04,.05,.9);g.rectangle('fill',x-20,y-29,40,4)
   g.setColor(c[1],c[2],c[3]);g.rectangle('fill',x-20,y-29,40*a.grab.progress,4)
  end
 end
 for _,p in ipairs(a.fragments) do g.setColor(.75,1,.9,1-p.age);g.polygon('fill',p.x-5,p.y-9,p.x+5,p.y-6,p.x,p.y+10) end
 g.pop()
end
return C
