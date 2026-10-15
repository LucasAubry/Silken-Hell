-- Warm sedimentary rocks share the packed-earth floor palette.
local R={}
local function random(i) local v=math.sin(i*127.1+311.7)*43758.5453;return v-math.floor(v) end
function R.rock(x,y,w,h,seed)
 local g=love.graphics;local v=random(seed);local bevel=math.min(w,h)*(.16+v*.15)
 local p={x+bevel,y,x+w-bevel*(.6+v*.8),y+1+v*2,x+w,y+bevel,x+w-1,y+h-bevel,x+w-bevel,y+h,x+bevel*.6,y+h-1,x,y+h-bevel,x+1,y+bevel}
 g.setColor(.025,.014,.009,.48);g.push();g.translate(3,5);g.polygon('fill',p);g.pop()
 g.setColor(.13+v*.025,.065+v*.015,.027);g.polygon('fill',p)
 g.setColor(.29+v*.045,.16+v*.025,.077+v*.012)
 g.polygon('fill',p[1],p[2],p[3],p[4],p[5],p[6],x+w*.73,y+h*.58,x+w*.26,y+h*.63,p[15],p[16])
 g.setColor(.40+v*.04,.25+v*.025,.13);g.polygon('fill',p[1],p[2],p[3],p[4],x+w*(.52+v*.23),y+h*(.19+v*.16),x+w*.26,y+h*.63,p[15],p[16])
 g.setColor(.23,.12,.05);g.polygon('fill',x+w*(.52+v*.23),y+h*(.19+v*.16),p[3],p[4],p[5],p[6],x+w*.73,y+h*.58)
 g.setLineWidth(1);g.setColor(.56,.37,.19,.65);g.line(p[15],p[16],p[1],p[2]+1,p[3],p[4]+1)
 g.setColor(.08,.04,.019,.6);g.line(x+w*.73,y+h*.58,x+w*.62,y+h*.76,x+w*.65,y+h-2)
 for i=1,8 do
  local xx=x+3+random(seed+i*9)*math.max(1,w-6);local yy=y+3+random(seed+i*13)*math.max(1,h-6)
  g.setColor(.57,.36,.17,.16);g.ellipse('fill',xx,yy,1.5,.7)
 end
end
function R.wall(r)
 local g=love.graphics;g.push('all');g.setShader()
 local horizontal=r.w>=r.h;local length=math.max(r.w,r.h);local thickness=math.min(r.w,r.h)
 local count=math.max(1,math.ceil(length/math.max(24,thickness*1.6)));local span=length/count
 for i=1,count do
  local seed=r.x*.3+r.y*.7+i*17
  R.rock(r.x+(horizontal and (i-1)*span or 0),r.y+(horizontal and 0 or (i-1)*span),horizontal and span+1 or r.w,horizontal and r.h or span+1,seed)
 end
 g.pop()
end
function R.edge(length,seed)
 local g=love.graphics;g.push('all');g.setShader()
 -- A cut bank of compacted earth, with a dark vertical face and a lit crest.
 g.setColor(.075,.033,.014);g.rectangle('fill',0,0,length,22)
 local top={0,0,length,0}
 for x=length,0,-5 do top[#top+1]=x;top[#top+1]=13+random(math.floor(x/5)+seed*71)*3 end
 g.setColor(.23,.12,.052);g.polygon('fill',top)
 for i=0,math.ceil(length/12) do
  local x=i*12;local v=random(i+seed*91)
  g.setColor(.30+v*.055,.17+v*.025,.075);g.ellipse('fill',x+4,8+v*3,7,3)
  g.setColor(.43,.27,.13,.4);g.line(x,3+v*2,x+8,3+v*2)
  g.setColor(.11,.052,.023,.6);g.line(x+5,17,x+9,20,x+11,22)
 end
 g.setColor(.035,.018,.009,.30);g.rectangle('fill',0,22,length,4)
 g.pop()
end
return R
