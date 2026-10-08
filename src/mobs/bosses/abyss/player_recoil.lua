local K={}
function K.clear(a,x,y,time)
 if Arena.blocked(x,y,30,24)then return false end
 for _,f in ipairs(a.chargedFish or {})do
  local travel=math.max(0,(time or 0)-math.max(0,f.delay or 0))*300
  local fx,fy=f.x+math.cos(f.angle)*travel,f.y+math.sin(f.angle)*travel
  if (x+15-fx)^2+(y+12-fy)^2<65^2 then return false end
 end
 return true
end
function K.start(a,awayX,awayY)
 local angle=math.atan2(awayY,awayX);local best,score
 for i=0,15 do
  local turn=(i%2==0 and 1 or -1)*math.ceil(i/2)*math.pi/8
  local c,s=math.cos(angle+turn),math.sin(angle+turn)
  local distance=0
  for d=6,108,6 do
   if not K.clear(a,player.x+c*d,player.y+s*d,d/400)then break end
   distance=d
  end
  local rank=distance+math.cos(turn)*24
  if distance>0 and (not score or rank>score)then best={vx=c*400,vy=s*400,time=distance/400,safeRecoil=true,boss=a};score=rank end
 end
 player.abyssKnock=best
 -- Protect the release even when a wall leaves no room for a full recoil.
 player.abyssGrace=math.max(player.abyssGrace or 0,(best and best.time or 0)+.22)
end
function K.move(knock,dt)
 local steps=math.max(1,math.ceil(400*dt/3));local step=dt/steps
 for _=1,steps do
  local x,y=player.x+knock.vx*step,player.y+knock.vy*step
  if not K.clear(knock.boss,x,y,0)then knock.time=0;break end
  Arena.move(player,knock.vx*step,knock.vy*step)
 end
end
return K
