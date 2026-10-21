-- Fixed-direction gusts; simulation never depends on visual effects or RNG.
local G={range=1500,width=28,power=440,playerPower=300}
local Visibility=require('wind_visibility')
local function aim(m)
 local dx,dy=player.x+15-m.x,player.y+12-m.y
 local length=math.max(.001,math.sqrt(dx*dx+dy*dy))
 m.vx,m.vy=dx/length,dy/length;m.angle=math.atan2(dy,dx)-math.pi/2
end
function G.reaches(m,x,y)
 local dx,dy=x-m.x,y-m.y
 local along=dx*m.vx+dy*m.vy
 local across=math.abs(dx*m.vy-dy*m.vx)
 return along>20 and along<G.range and across<G.width
  and Visibility.clear(m.x,m.y,x,y)
end
function G.update(m,dt)
 if m.phase~='windup' and m.phase~='gust' and m.phase~='recover' then m.phase='roam' end
 if m.phase=='roam' and m.attackDelay~=nil and not m.attackStarted then
  local tell=math.min(.85,m.attackDelay);local start=m.attackDelay-tell
  local before=m.age-dt
  if m.age<start then return false end
  dt=math.max(0,m.age-math.max(before,start));m.attackStarted=true;m.cooldown=0
  aim(m);m.phase=tell>0 and 'windup' or 'gust';m.phaseTime=tell>0 and tell or (m.attackDuration or 2)
 end
 if m.phase=='roam' then
  if m.cooldown>0 then return false end
  local dx,dy=player.x+15-m.x,player.y+12-m.y
  local length=math.max(.001,math.sqrt(dx*dx+dy*dy))
  m.vx,m.vy=dx/length,dy/length;m.angle=math.atan2(dy,dx)-math.pi/2
  m.phase='windup';m.phaseTime=.85
 end
 if m.phase=='windup' then aim(m) end
 local remaining=dt
 -- Consume boundary time explicitly so a slow frame cannot extend a gust.
 while remaining>0 and m.phase~='roam' do
  local step=math.min(remaining,m.phaseTime,1/60)
  if m.phase=='gust' then
   -- Keep flying sideways while preserving the direction chosen at release.
   Arena.move(m,-m.vy*30*step,m.vx*30*step)
   for _,other in ipairs(mobs) do
    if other~=m and other.type~='mist_moth' and not (other.dead or other.spent or other.falling or other.capture or other.tunnelTravel or other.abyssHeld)
     and not Realms.underground(other) and other.hitBox_width and other.hitBox_height and other.type~='scie' and other.type~='piege' and not other.ground then
     local steps=math.max(1,math.ceil(G.power*step/4))
     for _=1,steps do
      if not G.reaches(m,other.x,other.y) then break end
      Arena.move(other,m.vx*G.power*step/steps,m.vy*G.power*step/steps)
      -- Forced travel must not join the old digging point to the new position.
      if other.type=='cloud_snail' then other.cx=nil;other.cy=nil end
      if require('mob_edge_fall').check(other) then break end
     end
    end
   end
  end
  remaining=remaining-step;m.phaseTime=m.phaseTime-step
  if m.phaseTime<=0 then
   if m.phase=='windup' then aim(m);m.phase='gust';m.phaseTime=m.attackDuration or 2
   elseif m.phase=='gust' then m.phase='recover';m.phaseTime=.65
   else m.phase='roam';m.cooldown=m.attackInterval or 2.5 end
  end
 end
 return true
end
-- Combine walking and wind before collision checks, so opposing forces cancel
-- without a temporary step into a hole between walking and the gust update.
function G.playerVelocity(vx,vy,sprinting,sprintSpeed)
 if player.reset or player.falling or player.tunnelTravel or player.abyssHeld or player.whirl or player.throw or player.skyWhirl or player.skyThrow then return vx,vy end
 local wx,wy=0,0
 for _,m in ipairs(mobs) do
  if m.type=='mist_moth' and m.phase=='gust' and not (m.dead or m.falling or m.capture or m.is_frozen)
   and G.reaches(m,player.x+15,player.y+12) then wx=wx+m.vx*G.playerPower;wy=wy+m.vy*G.playerPower end
 end
 local force=math.sqrt(wx*wx+wy*wy)
 if force>0 and sprinting and sprintSpeed>0 then
  local nx,ny=wx/force,wy/force;local against=vx*nx+vy*ny
  if against<0 then
   local scale=math.min(1,G.playerPower/sprintSpeed)
   vx=vx+nx*against*(scale-1);vy=vy+ny*against*(scale-1)
  end
 end
 return vx+wx,vy+wy
end
local function cloudTexture()
 if G.cloud then return G.cloud end
 local data=love.image.newImageData(64,32)
 for y=0,27 do for x=0,39 do
  local d=math.min(((x-11)/9)^2+((y-17)/7)^2,((x-21)/11)^2+((y-12)/10)^2,((x-30)/8)^2+((y-17)/7)^2)
  local alpha=math.max(0,math.min(1,(1-d)*3))
  local shade=.82+.18*(1-y/28)
  data:setPixel(x,y,shade,math.min(1,shade+.045),1,alpha)
 end end
 -- Both streaks and puffs share one texture and one reusable GPU batch.
 for y=0,5 do for x=44,61 do
  local alpha=(y==0 or y==5 or x==44 or x==61) and 0 or 1
  data:setPixel(x,y,1,1,1,alpha)
 end end
 local g=love.graphics
 G.cloud=g.newImage(data);data:release();G.cloud:setFilter('linear','linear')
 G.puffQuad=g.newQuad(0,0,40,28,64,32)
 G.streakQuad=g.newQuad(45,1,16,4,64,32)
 G.batch=g.newSpriteBatch(G.cloud,128,'stream');G.lanes={}
 return G.cloud
end
function G.draw(m)
 if m.phase~='gust' then return end
 local g=love.graphics;g.push('all');g.setShader()
 cloudTexture();local batch=G.batch;batch:clear()
 local t=m.age or 0;local lanes=G.lanes;local angle=math.atan2(m.vy,m.vx)
 -- Nine wall-clipped lanes serve every streak and cloud puff in this frame.
 for lane=1,9 do
  local side=(lane-5)*6
  lanes[lane]=Visibility.limit(m.x-m.vy*side,m.y+m.vx*side,m.vx,m.vy,G.range)
 end
 for i=1,70 do
  local lane=1+i%9;local side=(lane-5)*6;local distance=(t*740+i*29)%G.range
  local length=math.min(24+9*math.sin(i),lanes[lane]-distance)
  if length>0 then
   local x=m.x+m.vx*distance-m.vy*side;local y=m.y+m.vy*distance+m.vx*side
   if x>=-36 and x<=Arena.width+36 and y>=-36 and y<=636 then
    batch:setColor(.84,.94,1,.78*(1-distance/G.range*.55))
    batch:add(G.streakQuad,x,y,angle,length/16,2.6/4,0,2)
   end
  end
 end
 local count=Graphics.quality==1 and 32 or 56
 for i=1,count do
  local lane=1+i%9;local side=(lane-5)*6
  local distance=(t*(280+i%5*35)+i*71)%G.range
  if distance>12 and distance<lanes[lane]-18 then
   local life=distance/G.range;local alpha=math.min(1,distance/65)*(1-life)*.42
   local x=m.x+m.vx*distance-m.vy*side;local y=m.y+m.vy*distance+m.vx*side
   if x>=-24 and x<=Arena.width+24 and y>=-24 and y<=624 then
    local size=.23+(i%5)*.07;local lift=math.sin(life*math.pi)*5
    batch:setColor(1,1,1,alpha)
    batch:add(G.puffQuad,x,y-lift,angle+math.sin(i+t)*.12,size*1.5,size,20,14)
   end
  end
 end
 g.setColor(1,1,1);g.draw(batch)
 g.pop()
end
return G
