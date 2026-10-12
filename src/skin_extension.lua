local E={}
function E.unlocked() return Profile.achievements.heartbreak==true or (Profile.skinGrants or {}).heartbreak==true end
function E.toggle()
 if not E.unlocked() then return end
 Profile.tearExtension=not Profile.tearExtension;Profile.save()
end
function E.icon(x,y,size,alpha,active)
 local g=love.graphics;g.push('all');g.setShader();g.translate(x,y);g.scale(size/14)
 g.setColor(.96,.38,.49,alpha or 1)
 local mode=active==false and 'line' or 'fill';g.setLineWidth(1.25*14/size);g.setLineJoin('bevel')
 g.polygon(mode,-2,-9,-8,-12,-14,-6,-13,0,-3,12,-1,3,-5,-1,0,-5)
 g.polygon(mode,3,-9,8,-12,14,-6,13,0,0,12,3,3,-1,-1,4,-5)
 g.pop()
end
function E.draw(x,y,size,dir,force,bothEyes)
 if not force and not require('skin_effects').enabled('heartbreak') then return end
 dir=dir or 'down';if dir=='up' then return end
 local a=Art.images[Characters.model(dir)];if not a then return end
 local qx,qy=a.quad:getViewport();local iw,ih=a.image:getDimensions()
 local scale=size/math.max(a.w,a.h)
 local side=dir=='left' or dir=='right'
 -- Keep the chosen front eye; mirror the tear with the visible profile eye.
 local ey=((side and .59 or .64)*ih-qy-a.h/2)*scale
 local g=love.graphics;local _,_,_,alpha=g.getColor();g.push('all');g.setShader()
 local radius=math.max(1,size*.013)
 for eye=1,(bothEyes and not side and 2 or 1) do
 local ex=((side and .22 or eye==2 and .60 or .40)*iw-qx-a.w/2)*scale
 if dir=='right' then ex=-ex end
 g.setColor(.38,.75,1,alpha*.55);g.setLineWidth(math.max(1,size*.008))
 g.line(x+ex,y+ey,x+ex,y+ey+size*.12)
 -- Overlapping drops keep the stream visible across the animation wrap.
 for i=0,1 do
  local t=((UI.clock or 0)*.65+i*.5+(eye-1)*.23)%1;local fade=math.min(1,t*8,(1-t)*5)*alpha
  local length=size*.15*t
  g.setColor(.52,.85,1,fade);g.ellipse('fill',x+ex,y+ey+length,radius,radius*1.45)
  g.setColor(.9,.98,1,fade*.9);g.ellipse('fill',x+ex-radius*.25,y+ey+length-radius*.3,radius*.3,radius*.65)
 end
 end
 g.pop()
end
return E
