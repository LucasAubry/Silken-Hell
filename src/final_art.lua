-- Shared generated PNG sprites: combat, sanctuary and reunion use the same assets.
local A={}
function A.draw(name,x,y,width,angle,height)
 local key='final_'..name
 if not Art.images[key] then Art.add(key,'assets/sprites/final/'..name..'.png') end
 local a=Art.images[key]
 Art.draw(key,x,y,width,angle or 0,height or width*a.h/a.w)
end
-- Actual profile sprites replace rotating the front sprite during horizontal travel.
function A.facing(angle)
 local dx,dy=-math.sin(angle or 0),math.cos(angle or 0)
 if math.abs(dx)>math.abs(dy) then return dx>0 and 'right' or 'left' end
 return dy>0 and 'down' or 'up'
end
-- Turn the entire pose together; attachments share the same local coordinates.
function A.pose(angle)
 local dir=A.facing(angle)
 local base=({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir]
 local delta=math.atan2(math.sin((angle or 0)-base),math.cos((angle or 0)-base))
 return dir,delta
end
function A.spider(name,x,y,width,angle,walk)
 local servants=require('servant_art');local context=servants.current
 servants.current={type='queen_child',bossServant=name~='queen'}
 local dir,turn=A.pose(angle)
 if name~='queen' then turn=0 end
 local graphics=love.graphics
 local function body(sprite)
  local key='final_'..sprite
  if not Art.images[key] then Art.add(key,'assets/sprites/final/'..sprite..'.png') end
  local a=Art.images[key]
  local function pose(x,y)
   if not (walk and require('brown_walk').draw(a.image,dir,x,y,width,walk,a.quad)) then
    graphics.draw(a.image,a.quad,x,y,0,width/a.w,width/a.w,a.w/2,a.h/2)
   end
  end
  require('sprite_relief').draw(a,0,0,width,0,nil,math.max(1,width*.038),false,pose,
   name=='baby_white' or name=='queen' and walk and walk.enraged,walk and (walk.jumpHeight or 0)>0)

 end
 if not walk or (walk.jumpHeight or 0)<=0 then Art.contactShadow(x,y+width*.18,width*.34,width*.12,.24) end
 graphics.push('all');graphics.translate(x,y);graphics.rotate(turn)
 x,y=0,0
 if dir~='down' then
  local variant=(name=='queen' or name=='baby_red') and 'red' or name=='baby_black' and 'black' or 'white'
  local g=love.graphics;g.push('all');g.translate(x,y)
  if name=='partner' then
   if dir=='right' then g.scale(-1,1) end
   body(dir=='up' and 'partner_up' or 'partner_left')
  else body((dir=='right' and 'side_' or dir..'_')..variant) end
  g.pop()
 else
  body(name)
 end
 graphics.pop();servants.current=context
 return dir
end
function A.clutch(x,y,width,count,angle)
 local g=love.graphics;local scale=width/190
 local dir,turn=A.pose(angle);local side=dir=='left' or dir=='right'
 g.push('all');g.translate(x,y);g.rotate(turn)
 if side then g.scale(dir=='left' and -1 or 1,1) end
 g.scale(scale);g.setColor(1,1,1)
 for i=1,count do local a=i*2.399963;local r=math.sqrt(i/24)
  A.draw('egg',(side and -33 or 0)+math.cos(a)*r*(side and 17 or 22),(side and -32 or dir=='up' and 9 or -39)+math.sin(a)*r*17,7.56,0,10.8)
 end
 g.pop()
end
return A
