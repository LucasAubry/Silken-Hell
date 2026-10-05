-- Fixed collision geometry shared by actors, projectiles and terrain.
local T={}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
function T.bounds(e,x,y)
 return (x or e.x)+(e.hitBox_offset_x or 0),(y or e.y)+(e.hitBox_offset_y or 0)+require('mobs.shared.floating').offset(e),e.hitBox_width,e.hitBox_height
end
function T.playerRect()return T.bounds(player)end
function T.center()
 local x,y,w,h=T.playerRect();return x+w/2,y+h/2
end
function T.touchRect(key,x,y,w,h)
 local px,py,pw,ph=T.playerRect()
 return checkCollision(px,py,pw,ph,x,y,w,h)
end
function T.projectile(x,y,w,h)
 local px,py,pw,ph=T.playerRect();return checkCollision(x,y,w,h,px,py,pw,ph)
end
-- These circle radii already include the original player margin.
function T.touchCircle(key,x,y,r)
 local px,py=T.center();return (px-x)^2+(py-y)^2<r*r
end
function T.sweptCircle(key,x,y,xx,yy,r)
 local px,py=T.center()
 local dx,dy=xx-x,yy-y;local n=dx*dx+dy*dy
 local t=n>0 and clamp(((px-x)*dx+(py-y)*dy)/n,0,1) or 0
 return (x+dx*t-px)^2+(y+dy*t-py)^2<=r*r
end
function T.circleRect(key,x,y,r)
 local px,py,pw,ph=T.playerRect()
 return (clamp(x,px,px+pw)-x)^2+(clamp(y,py,py+ph)-y)^2<r*r
end
function T.bone(b) return b.x,b.y,b.w,b.h end
function T.samples()
 local x,y,w,h=T.playerRect();return x+math.min(2,w/4),x+w-math.min(2,w/4),y+math.min(2,h/4),y+h-math.min(2,h/4)
end
function T.featherTouches(x,y,r)
 return T.touchCircle('player_feathers',x,y,r)
end
return T
