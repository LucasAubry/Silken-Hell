-- Angular cave stones, with warm grey mineral faces over dark packed earth.
local R={}
local function random(i) local v=math.sin(i*127.1+311.7)*43758.5453;return v-math.floor(v) end
function R.rock(x,y,w,h,seed)
 local g=love.graphics;local v=random(seed);local bevel=math.min(w,h)*(.16+v*.15)
 local p={x+bevel,y,x+w-bevel*(.6+v*.8),y+1+v*2,x+w,y+bevel,x+w-1,y+h-bevel,x+w-bevel,y+h,x+bevel*.6,y+h-1,x,y+h-bevel,x+1,y+bevel}
 g.setColor(.025,.014,.009,.48);g.push();g.translate(3,5);g.polygon('fill',p);g.pop()
 g.setColor(.12+v*.035,.10+v*.025,.075+v*.02);g.polygon('fill',p)
 g.setColor(.30+v*.075,.265+v*.065,.205+v*.055)
 g.polygon('fill',p[1],p[2],p[3],p[4],p[5],p[6],x+w*.73,y+h*.58,x+w*.26,y+h*.63,p[15],p[16])
 g.setColor(.43+v*.075,.385+v*.065,.30+v*.055);g.polygon('fill',p[1],p[2],p[3],p[4],x+w*(.52+v*.23),y+h*(.19+v*.16),x+w*.26,y+h*.63,p[15],p[16])
 g.setColor(.245+v*.035,.21+v*.03,.16+v*.025);g.polygon('fill',x+w*(.52+v*.23),y+h*(.19+v*.16),p[3],p[4],p[5],p[6],x+w*.73,y+h*.58)
 g.setLineWidth(1);g.setColor(.65,.57,.43,.55);g.line(p[15],p[16],p[1],p[2]+1,p[3],p[4]+1)
 g.setColor(.075,.058,.039,.7);g.line(x+w*.73,y+h*.58,x+w*.62,y+h*.76,x+w*.65,y+h-2)
 g.setColor(.67,.59,.45,.16);g.line(x+w*.17,y+h*.33,x+w*.43,y+h*.27,x+w*.65,y+h*.35)
 for i=1,8 do
  local xx=x+3+random(seed+i*9)*math.max(1,w-6);local yy=y+3+random(seed+i*13)*math.max(1,h-6)
  g.setColor(.72,.62,.46,.19);g.ellipse('fill',xx,yy,1.2,.7)
 end
end
function R.wall(r)
 local g=love.graphics;g.push('all');g.setShader()
 local horizontal=r.w>=r.h;local length=math.max(r.w,r.h);local thickness=math.min(r.w,r.h)
 local count=math.max(1,math.ceil(length/math.max(22,thickness*1.15)));local span=length/count
 for i=1,count do
  local seed=r.x*.3+r.y*.7+i*17
  R.rock(r.x+(horizontal and (i-1)*span or 0),r.y+(horizontal and 0 or (i-1)*span),horizontal and span+1 or r.w,horizontal and r.h or span+1,seed)
 end
 g.pop()
end
function R.edge(length,seed)
 local g=love.graphics;g.push('all');g.setShader()
 -- Two irregular courses of stones form the cave perimeter. Their inner
 -- silhouette stays close to the existing collision boundary at 22 pixels.
 g.setColor(.075,.047,.026);g.rectangle('fill',0,0,length,22)
 local x,i=0,0
 while x<length do
  local v=random(i+seed*91);local width=math.min(22+v*19,length-x)
  R.rock(x,-4,width+1,18+v*5,seed*101+i*17)
  x=x+width;i=i+1
 end
 x=0;i=0
 while x<length do
  local v=random(i+seed*127);local width=math.min(17+v*23,length-x)
  R.rock(x,8+v*3,width+1,12+random(i+seed*53)*3,seed*211+i*23)
  x=x+width;i=i+1
 end
 g.pop()
end
return R
