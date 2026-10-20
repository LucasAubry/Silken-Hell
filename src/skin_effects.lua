-- Cosmetics are independent of the fourteen skins. Legacy IDs stay replayable.
local E={names={gold='Éclat du champion',hardcore='Auréole hardcore',heartbreak='Cœur brisé'}}
function E.unlocked(kind)
 if kind=='heartbreak' then return (Profile.achievements or {}).heartbreak==true end
 if kind=='gold' then return (Profile.achievements or {}).top1==true or #(Profile.topRecords or {})>0 end
 if kind=='hardcore' then
  if (Profile.achievements or {}).hardcore==true then return true end
  local completed=Hardcore and Hardcore.completed or {}
  for _,world in ipairs(Worlds.order) do if completed[world] or completed[tostring(world)] then return true end end
  for _,score in ipairs(Profile.scores or {}) do
   if score.hardcore==true and Worlds.rank(score.world)<=#Worlds.order then return true end
  end
 end
 return false
end
function E.enabled(kind)
 if Replay and Replay.playing and not Replay.ghost then return (Replay.data.effects or {})[kind]==true end
 return E.unlocked(kind) and (kind=='heartbreak' and Profile.tearExtension==true or (Profile.skinEffects or {})[kind]==true)
end
function E.equip(kind,value)
 if not E.unlocked(kind) then return false end
 if kind=='heartbreak' then Profile.tearExtension=value==true
 else Profile.skinEffects=Profile.skinEffects or {};Profile.skinEffects[kind]=value==true end
 Profile.save();return true
end
function E.snapshot()
 return {gold=E.enabled('gold'),hardcore=E.enabled('hardcore'),heartbreak=E.enabled('heartbreak')}
end
function E.icon(kind,x,y,size,alpha,active)
 local g=love.graphics;g.push('all');g.setShader();g.setColor(1,1,1,alpha or 1)
 if kind=='heartbreak' then require('skin_extension').icon(x,y,size,alpha,active)
 elseif kind=='hardcore' then
  -- Angular, flat pieces leave the eyes and nose open, like the broken heart.
  g.translate(x,y);g.scale(size/14);g.setColor(1,.18,.23,alpha or 1)
  g.setLineWidth(1.1*14/size);g.setLineJoin('bevel')
  if active==false then
   g.polygon('line',-12,-4,-10,-10,-4,-13,5,-12,11,-7,12,-4,11,2,6,6,5,12,2,12,2,9,0,8,-2,9,-2,12,-5,11,-6,6,-11,2)
   g.polygon('line',-8,-5,-3,-3,-5,2,-9,0)
   g.polygon('line',7,-5,3,-3,5,2,9,0)
   g.polygon('line',0,-2,-2,4,0,6,2,4)
  else
  g.polygon('fill',-12,-4,-10,-10,-4,-13,5,-12,11,-7,12,-4,7,-5,3,-3,-3,-3,-8,-5)
  g.polygon('fill',-12,-4,-8,-5,-9,0,-5,2,-3,-3,0,-2,-2,4,-6,6,-11,2)
  g.polygon('fill',12,-4,7,-5,9,0,5,2,3,-3,0,-2,2,4,6,6,11,2)
  g.polygon('fill',-6,6,-2,4,0,6,2,4,6,6,5,12,2,12,2,9,0,8,-2,9,-2,12,-5,11)
  end
 else
  g.translate(x,y);g.scale(size/14);g.setColor(1,.83,.35,alpha or 1)
  local mode=active==false and 'line' or 'fill';g.setLineWidth(1.25*14/size);g.setLineJoin('bevel')
  g.polygon(mode,0,-14,-4,-4,-13,0,-4,3,-1,12,0,3,-3,0,2,-4)
  g.polygon(mode,4,-10,5,-3,13,1,5,3,1,14,3,3,0,0,4,-3)
 end
 g.pop()
end
function E.halo(x,y,size,dir,index)
 local g=love.graphics;local _,_,_,alpha=g.getColor()
 dir=dir or 'down'
 if alpha<.95 or size<20 then return end
 E.shader=E.shader or g.newShader('assets/shaders/skin_halo.glsl')
 index=index or (App.state=='menu' and Characters.menuIndex() or Characters.selected())
 local art=Art.images[Characters.model(dir)];local qx,qy=art.quad:getViewport()
 local iw,ih=art.image:getDimensions();local scale=size/math.max(art.w,art.h)
 -- Anchor the floating ring to the head in each authored pose, including the
 -- far head of the back view. The near poses frame the top of the forehead.
 local headX,headY=.5,dir=='up' and .13 or .43
 local rx,ry=size*.30,size*.125
 local facing,tilt=1,0
 if dir=='left' or dir=='right' then
  facing=dir=='right' and -1 or 1
  headX,headY=.29,.38
  rx,ry,tilt=size*.27,size*.12,.12*facing
 end
 local cx=x+(headX*iw-qx-art.w/2)*scale*facing
 local cy=y+(headY*ih-qy-art.h/2)*scale-size*.035
 if require('winged_anchors').winged(index) then
  local ax,ay,arx,ary=require('winged_anchors').halo(dir)
  cx,cy,rx,ry=x+ax*size,y+ay*size,arx*size,ary*size
 end
 -- Add light to the head instead of painting an opaque red band over it.
 g.push('all');g.setShader(E.shader);g.setBlendMode('add')
 E.shader:send('clock',UI.clock)
 g.translate(cx,cy);g.rotate(tilt)
 g.setColor(1,1,1,alpha)
 g.draw(UI.pixel,-rx,-ry,0,rx*2,ry*2);g.pop()
end
function E.behind(x,y,size,forced)
 if forced=='gold' or not forced and E.enabled('gold') then
  local fx=require('skin_reward_fx');fx.rays(x,y,size);fx.orbit(x,y,size,false,false)
 end
end
function E.front(x,y,size,forced,dir,index)
 if forced=='hardcore' or not forced and E.enabled('hardcore') then E.halo(x,y,size,dir,index) end
 if forced=='gold' or not forced and E.enabled('gold') then require('skin_reward_fx').orbit(x,y,size,true,false) end
end
return E
