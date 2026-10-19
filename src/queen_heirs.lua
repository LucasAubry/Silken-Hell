-- Hatched guardians share attacks and redirect player hits to the queen.
local H={}
H.colors={{.35,.85,1},{.85,.45,1},{1,.68,.22},{.4,1,.6},{1,.4,.65},{.65,.65,1}}
local function clamp(x,a,b)return math.max(a,math.min(b,x))end
function H.color(id)return id==0 and {1,.94,.72} or H.colors[(id-1)%#H.colors+1]end
function H.hatch(f,e)
 f.babies[#f.babies+1]={id=e.seed,seed=e.seed,x=e.x,y=e.y,age=0,phase='webs',phaseTime=0,shot=.7,cast=0,volley=0,angle=0,variant=e.seed%2==0 and 'white' or 'black',frozen=0,jumpCooldown=5+e.seed*.35,contactGrace=.5,jumpHeight=0}
end
function H.jump(b)
 b.jumpCooldown=6.5;b.frozen=0;b.phase='intro_jump';b.phaseTime=0;b.contactGrace=1.05
 b.jump={x=b.x,y=b.y,tx=b.x<Arena.width/2 and Arena.width-110 or 110,ty=b.y<300 and 480 or 120}
 b.angle=math.atan2(b.jump.ty-b.y,b.jump.tx-b.x)-math.pi/2
end
function H.hit(f,b)
 if f.defeated or f.hp<=0 or b.phase=='intro_jump' or b.contactGrace>0 then return end
 H.jump(b);f.damage(true)
end
local function move(b,x,y,speed,dt)
 local dx,dy=x-b.x,y-b.y;local d=math.sqrt(dx*dx+dy*dy)
 if d>0 then local n=math.min(d,speed*dt);b.x=b.x+dx/d*n;b.y=b.y+dy/d*n;b.angle=math.atan2(dy,dx)-math.pi/2 end
 return d
end
function H.update(f,dt)
 for _,b in ipairs(f.babies)do
  b.jumpCooldown=math.max(0,(b.jumpCooldown or 5)-dt)
  if b.phase=='webs' and b.frozen<=0 and b.jumpCooldown<=0 then H.jump(b) end
  local x,y=b.x,b.y;b.age=b.age+dt;b.contactGrace=math.max(0,b.contactGrace-dt)
  if b.phase~='intro_jump' and b.contactGrace<=0 and require('collision_shapes').touchCircle('queen_baby',b.x,b.y,27) then if f.snare>0 then Hazards.kill() else H.hit(f,b) end;return end
  if b.frozen>0 then b.frozen=math.max(0,b.frozen-dt);b.walkMoving=false
  else
   b.phaseTime=b.phaseTime+dt;b.cast=math.max(0,b.cast-dt)
   if b.phase=='intro_jump' then
    local t=math.min(1,b.phaseTime/.85);local u=t*t*(3-2*t);local j=b.jump
    b.x=j.x+(j.tx-j.x)*u;b.y=j.y+(j.ty-j.y)*u;b.jumpHeight=math.sin(t*math.pi)*100
    if t>=1 then b.phase='webs';b.phaseTime=0;b.jump=nil;b.jumpHeight=0;b.shot=.6;f.fire(b,true) end
   elseif b.phase=='aim' then
    if b.phaseTime>=.65 then b.phase='charge';b.phaseTime=0 end
   elseif b.phase=='charge' then
    move(b,b.chargeX,b.chargeY,920,dt)
    local dx,dy=b.x-x,b.y-y;local n=dx*dx+dy*dy
    local t=n>0 and clamp(((player.x+15-x)*dx+(player.y+12-y)*dy)/n,0,1) or 0
    if b.contactGrace<=0 and (x+dx*t-player.x-15)^2+(y+dy*t-player.y-12)^2<27^2 then
     b.x=x+dx*t;b.y=y+dy*t;if f.snare>0 then Hazards.kill() else H.hit(f,b) end;return
    elseif (b.x-b.chargeX)^2+(b.y-b.chargeY)^2<16 or b.phaseTime>1.7 then b.phase='webs';b.shot=.4 end
   else
    b.shot=b.shot-dt
    if b.shot<=0 then f.fire(b,false);b.shot=1.05 end
    if b.cast<=0 and b.shot>.10 then
     move(b,Arena.width*.5+math.sin(f.clock*.5+b.id*1.7)*Arena.width*.23,230+math.cos(f.clock*.65+b.id)*110,110,dt)
     b.angle=math.atan2(player.y+12-b.y,player.x+15-b.x)-math.pi/2
    end
   end
   require('brown_walk').advance(b,math.sqrt((b.x-x)^2+(b.y-y)^2),dt)
   if b.phase=='intro_jump' then b.walkMoving=false end
  end
 end
end
function H.draw(f)
 local g=love.graphics;local art=require('final_art')
 for _,b in ipairs(f.babies)do
  local color=H.color(b.id)
  g.setColor(1,1,1);art.spider('baby_'..b.variant,b.x,b.y-(b.jumpHeight or 0),55,b.angle,b)
  if b.frozen>0 then g.setColor(color[1],color[2],color[3],.8);art.draw('web_wall',b.x,b.y,58) end
  if b.phase=='aim' then g.setColor(color[1],color[2],color[3],.5);g.circle('line',b.chargeX,b.chargeY,30) end
 end
end
return H
