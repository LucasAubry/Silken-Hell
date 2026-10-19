-- Jagged volcanic slabs replace the grey masonry without changing collisions.
local R={}
function R.draw(r)
 local g=love.graphics;g.push('all');g.setShader()
 local x,y,w,h=r.x,r.y,r.w,r.h
 g.setColor(.075,.025,.032)
 g.polygon('fill',x,y+5,x+5,y,x+w-6,y,x+w,y+6,x+w,y+h-5,x+w-5,y+h,x+4,y+h,x,y+h-4)
 local cols=math.max(1,math.ceil(w/27));local rows=math.max(1,math.ceil(h/26))
 for j=1,rows do for i=1,cols do
  local xx=x+(i-1)*w/cols;local yy=y+(j-1)*h/rows;local cw,ch=w/cols,h/rows
  local n=(math.sin(i*31+j*71+x)*.5+.5)
  g.setColor(.13+n*.06,.045+n*.025,.045+n*.02)
  g.polygon('fill',xx+2,yy+ch*.3,xx+cw*.3,yy+1,xx+cw-2,yy+ch*.12,xx+cw-1,yy+ch*.8,xx+cw*.55,yy+ch-1,xx+1,yy+ch*.75)
  g.setColor(.38,.12,.055,.8);g.setLineWidth(1);g.line(xx+2,yy+ch*.3,xx+cw*.3,yy+1,xx+cw-2,yy+ch*.12)
  if (i+j)%2==0 then
   g.setColor(.85,.19,.025,.7);g.line(xx+cw*.3,yy+2,xx+cw*.48,yy+ch*.42,xx+cw*.34,yy+ch*.7)
  end
 end end
 g.pop()
end
return R
