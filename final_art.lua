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
function A.spider(name,x,y,width,angle)
 local dir,turn=A.pose(angle)
 local graphics=love.graphics;graphics.push('all');graphics.translate(x,y);graphics.rotate(turn)
 x,y=0,0
 if dir~='down' then
  local variant=(name=='queen' or name=='baby_red') and 'red' or name=='baby_black' and 'black' or 'white'
  local g=love.graphics;g.push('all');g.translate(x,y)
  if name=='baby_white' then
   A.babyEyeShader=A.babyEyeShader or g.newShader([[vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pos) {
    vec4 p=Texel(tex,uv);if(p.r>p.g*1.4 && p.g>.12 && p.b<.25) p.rgb=vec3(p.r,.035,.045);return p*color;
   }]])
   g.setShader(A.babyEyeShader)
  end
  A.draw((dir=='right' and 'side_' or dir..'_')..variant,0,0,width,0)
  if name=='queen' then
   if not Art.images.reward_crown then Art.add('reward_crown','assets/skins/accessoires/couronne.png') end
   g.setColor(1,1,1);Art.draw('reward_crown',dir=='up' and 0 or (dir=='left' and -1 or 1)*width*.19,dir=='up' and -width*.29 or -width*.09,dir=='up' and width*.18 or width*.24,dir=='left' and -.25 or dir=='right' and .25 or 0)
  end
  g.pop()
 else A.draw(name,x,y,width,0) end
 graphics.pop()
 return dir
end
function A.clutch(x,y,width,count,angle)
 local g=love.graphics;local scale=width/190
 local dir,turn=A.pose(angle);local side=dir=='left' or dir=='right'
 g.push('all');g.translate(x,y);g.rotate(turn)
 if side then g.scale(dir=='left' and -1 or 1,1) end
 g.scale(scale);g.setColor(1,1,1)
 for i=1,count do local a=i*2.399963;local r=math.sqrt(i/24)
  A.draw('egg',(side and -36 or 0)+math.cos(a)*r*(side and 24 or 31),(side and -35 or dir=='up' and 20 or -43)+math.sin(a)*r*23,7.56,0,10.8)
 end
 g.pop()
end
return A
