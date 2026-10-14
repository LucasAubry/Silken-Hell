-- Only death retries wait. Presentation keeps running outside the combat clocks.
local W={active=false,age=0}
function W.reset() W.active=false;W.age=0 end
function W.begin()
 W.active=true;W.age=0
 player.has_moved=false;player.walkMoving=false;player.dashing=false
end
function W.canMove(dt)
 local dx,dy=Input.move()
 local speed=300*player.speed*Hazards.speed()
 if not Input.slow() then speed=speed*1.8 end
 if speed<=0 or (dx==0 and dy==0) then return false end
 local step=math.min(speed*dt,8)
 local x=math.max(23,math.min(Arena.width-53,player.x+dx*step))
 local y=math.max(23,math.min(553,player.y+dy*step))
 return (x~=player.x and not willCollide(x,player.y))
  or (y~=player.y and not willCollide(player.x,y))
end
function W.update(dt)
 if not W.active then return false end
 if W.canMove(math.min(dt,.05)) then W.active=false;return false end
 W.age=W.age+dt
 larme_float_timer=larme_float_timer+dt
 particleSystem:update(dt)
 update_shadow_dash(dt)
 return true
end
function W.beginDraw()
 if not W.active then return end
 W.saved={}
 local seen={}
 local function shift(object,key,delta)
  if type(object[key])~='number' then return end
  W.saved[#W.saved+1]={object,key,object[key]};object[key]=object[key]+delta
 end
 local function actor(a)
  if not a or seen[a] then return end
  seen[a]=true;shift(a,'clock',W.age)
  for i,p in ipairs(a.lumenParticles or {}) do
   shift(p,'age',W.age)
   shift(p,'x',(math.sin(W.age*.6+i)-math.sin(i))*5)
   shift(p,'y',(math.cos(W.age*.7+i)-math.cos(i))*4)
  end
 end
 actor(Realms);actor(Ocean)
 for _,a in ipairs({Raven,Wasp,Hedgehog,Octopus,Storm,Abyss}) do actor(a) end
 actor(require('final_spider'))
 for _,item in ipairs(Bosses.items) do actor(item.boss) end
 for _,m in ipairs(mobs) do
  if m.type=='light_jelly' or m.type=='larva' then shift(m,'age',W.age) end
 end
 for i,p in ipairs(Realms.fireflies or {}) do
  shift(p,'x',math.sin(W.age*.7+i)*5-math.sin(i)*5)
  shift(p,'y',math.cos(W.age*.6+i)*4-math.cos(i)*4)
 end
end
function W.endDraw()
 for _,v in ipairs(W.saved or {}) do v[1][v[2]]=v[3] end
 W.saved=nil
end
return W
