-- Deterministic attack art: stable silhouettes, brief bloom, no random draw state.
local F={}
local tau=math.pi*2
function F.rune(x,y,r,t,color,fill)
 local g=love.graphics;local c=color
 g.setColor(c[1],c[2],c[3],fill or .08);g.circle('fill',x,y,r)
 g.setLineWidth(1.5);g.setColor(c[1],c[2],c[3],.75)
 for i=0,3 do local a=i*tau/4+t*.4;g.arc('line','open',x,y,r,a,a+.8) end
 for i=0,7 do local a=i*tau/8;g.line(x+math.cos(a)*(r+3),y+math.sin(a)*(r+3),x+math.cos(a)*(r+7),y+math.sin(a)*(r+7)) end
end
function F.bolt(x,y,seed,t)
 local g=love.graphics;local fade=math.max(0,1-t/.48);local points={x,y}
 for i=1,12 do
  local h=math.sin(i*127.1+seed*311.7)*43758.5453;local jitter=(h-math.floor(h)-.5)*44
  points[#points+1]=x+jitter;points[#points+1]=y-i*(y+30)/12
 end
 for _,layer in ipairs({{20,.06},{10,.16},{4,.8},{1.5,1}}) do
  g.setColor(1,.82,.35,layer[2]*fade);g.setLineWidth(layer[1]);g.line(points)
 end
 for i=3,9,3 do local xx,yy=points[i*2-1],points[i*2];local dir=i%2==0 and 1 or -1
  g.setColor(1,.91,.64,fade*.7);g.setLineWidth(1.5);g.line(xx,yy,xx+dir*19,yy+12,xx+dir*13,yy+30,xx+dir*37,yy+47)
 end
 g.setColor(1,.94,.7,fade);g.circle('fill',x,y,5+fade*5)
 g.setColor(1,.8,.3,.5*fade);g.setLineWidth(2);g.ellipse('line',x,y,18+t*85,8+t*40)
 for i=1,9 do local a=i*2.4+seed;local r=t*130
  g.setColor(1,.88,.5,fade);g.line(x+math.cos(a)*r,y+math.sin(a)*r*.5,x+math.cos(a)*(r+5),y+math.sin(a)*(r+5)*.5)
 end
end
function F.lane(x,y,tx,ty,age,duration,r)
 local g=love.graphics;local angle=math.atan2(ty-y,tx-x);local nx,ny=-math.sin(angle)*r,math.cos(angle)*r
 local pulse=.4+.2*math.sin(age*16)
 g.setColor(.65,.8,1,.07);g.polygon('fill',x+nx,y+ny,tx+nx,ty+ny,tx-nx,ty-ny,x-nx,y-ny)
 g.setColor(.72,.86,1,pulse);g.setLineWidth(1.5);g.line(x+nx,y+ny,tx+nx,ty+ny);g.line(x-nx,y-ny,tx-nx,ty-ny)
 for i=1,12 do local t=(i/12+age*.18)%1;local px,py=x+(tx-x)*t,y+(ty-y)*t
  local dx,dy=math.cos(angle)*9,math.sin(angle)*9
  g.line(px-dx+nx*.12,py-dy+ny*.12,px,py,px-dx-nx*.12,py-dy-ny*.12)
 end
end
function F.wave(p,color)
 local g=love.graphics;local c=color;local r=p.r;local start=p.gap+p.opening/2;local finish=p.gap+tau-p.opening/2
 for _,layer in ipairs({{14,.06},{6,.22},{2, .95}}) do
  g.setLineWidth(layer[1]);g.setColor(c[1],c[2],c[3],layer[2]);g.arc('line','open',p.x,p.y,r,start,finish)
 end
 -- Foamy filaments break the perfect UI-circle silhouette without moving the hitbox.
 for band=1,2 do
  local points={}
  for i=0,72 do
   local angle=start+(finish-start)*i/72
   local ripple=math.sin(angle*13-p.age*5+band)*2+math.sin(angle*23+p.age*3)*1.5
   local rr=r-band*5+ripple
   points[#points+1]=p.x+math.cos(angle)*rr;points[#points+1]=p.y+math.sin(angle)*rr
  end
  g.setColor(c[1]*.7,c[2]*.9,c[3],.22/band);g.setLineWidth(1);g.line(points)
 end
 for i=0,13 do local angle=start+(finish-start)*(i+.2)/14;local rr=r-8-(p.age*23+i*13)%18
  local x,y=p.x+math.cos(angle)*rr,p.y+math.sin(angle)*rr
  g.setColor(.85,.5,.8,.38);g.circle('fill',x,y,1.2)
 end
 for _,a in ipairs({start,finish}) do
  g.setColor(.7,1,.92,1);g.circle('fill',p.x+math.cos(a)*r,p.y+math.sin(a)*r,3)
 end
end
return F
