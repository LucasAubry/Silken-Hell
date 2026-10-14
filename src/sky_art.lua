-- Carved slate, ink silhouettes and woven wind. All motion is presentation-only.
local S={}
local tau=math.pi*2
local function tint(r,g,b,a)love.graphics.setColor(r,g,b,a or 1)end
function S.floor()
 local g=love.graphics;g.push('all');g.setShader();g.setLineWidth(1)
 local w=Arena.width
 -- Broken concentric engravings make the center readable without becoming walls.
 for i=0,11 do
  local a=i*tau/12
  tint(.56,.65,.61,.24)
  g.arc('line','open',w/2,300,182,a+.07,a+.35)
  tint(.12,.25,.29,.48)
  local x,y=w/2+math.cos(a)*194,300+math.sin(a)*194
  g.line(x-math.cos(a)*7,y-math.sin(a)*7,x+math.cos(a)*7,y+math.sin(a)*7)
 end
 for _,p in ipairs({{.1,82},{.9,82},{.1,518},{.9,518}}) do
  local x,y=w*p[1],p[2]
  tint(.11,.22,.27,.65);g.polygon('fill',x-21,y,x,y-13,x+21,y,x,y+13)
  tint(.61,.65,.51,.42);g.polygon('line',x-20,y,x,y-12,x+20,y,x,y+12)
  tint(.86,.80,.53,.65);g.line(x-9,y,x+9,y);g.line(x,y-5,x,y+5)
 end
 -- Chisel scratches stay away from the playable silhouettes.
 for i=1,48 do
  local x=55+(i*137.7)%(w-110);local y=65+(i*89.3)%470
  tint(.13,.25,.30,.24);g.line(x,y,x+6,y-3,x+13,y-2)
 end
 g.pop()
end
function S.bird(dir,x,y,size,time,boss,electric,variant)
 local g=love.graphics;local red,green,blue,opacity=g.getColor();time=time or 0
 local angle=({down=0,up=math.pi,left=math.pi/2,right=-math.pi/2})[dir] or 0
 g.push('all');g.setShader();g.translate(x,y);g.rotate(angle);g.scale(size/110)
 local function c(r,gg,b,a)tint(r*red,gg*green,b*blue,(a or 1)*opacity)end
 local flap=math.sin(time*(boss and 7 or 10))
 local outer=boss and {.11,.17,.23} or {.22,.33,.40}
 -- Ink contour and layered individual flight feathers, not a tinted old gull.
 c(.015,.035,.055,.28);g.ellipse('fill',3,14,40,19)
 for _,side in ipairs({-1,1}) do
  g.push();g.scale(side,1)
  c(.035,.075,.105);g.polygon('fill',6,10,13,-20,48,-29-flap*4,59,-15,42,14,18,29)
  for i=0,5 do
   local xx=15+i*6.1;local yy=-18+i*2-flap*(i/2)
   c(outer[1]+i*.018,outer[2]+i*.021,outer[3]+i*.02)
   g.polygon('fill',9,5,xx,yy,xx+9,yy-9,xx+7,yy+9,18+i*3,24-i*2)
   c(.58,.69,.69,.65);g.setLineWidth(.8);g.line(xx+2,yy-5,xx+1,yy+7,17+i*3,18-i)
   c(boss and .84 or .59,boss and .73 or .74,boss and .39 or .78,.85)
   g.polygon('fill',xx+4,yy-7,xx+9,yy-9,xx+7,yy-3)
  end
  c(.04,.09,.13);g.polygon('fill',3,12,20,23,15,39,5,27)
  c(.48,.63,.67,.8);g.line(8,19,15,31)
  g.pop()
 end
 c(.025,.055,.08);g.polygon('fill',0,-29,-13,-12,-11,18,0,29,11,18,13,-12)
 c(.24,.38,.43);g.polygon('fill',0,-25,-8,-8,-6,13,0,22,6,13,8,-8)
 c(.60,.70,.66);g.polygon('fill',0,-18,-6,-7,0,-2,6,-7)
 c(.04,.07,.09);g.polygon('fill',-9,-3,0,3,9,-3,6,12,0,15,-6,12)
 local eye=electric and {1,.83,.35} or {.76,.96,1}
 c(eye[1],eye[2],eye[3],.16);g.circle('fill',-5,5,7);g.circle('fill',5,5,7)
 c(eye[1],eye[2],eye[3]);g.rectangle('fill',-7,3,4,3);g.rectangle('fill',3,3,4,3)
 c(.92,.81,.48);g.polygon('fill',-3,11,3,11,0,boss and 44 or 27)
 if boss then
  for i=-2,2 do
   local xx=i*6;c(.06,.12,.16);g.polygon('fill',xx-3,-20,xx,-42+math.abs(i)*4,xx+3,-20)
   c(.86,.79,.51);g.line(xx,-26,xx,-37+math.abs(i)*4)
  end
  c(.81,.90,.82,.8);g.setLineWidth(1);g.arc('line','open',0,-2,31,math.pi*1.1,math.pi*1.9)
 elseif (variant or 0)%2==1 then
  c(.73,.81,.76,.8);g.line(-9,-12,-3,-23,0,-18,3,-23,9,-12)
 end
 if electric then
  c(1,.85,.40,.75);g.setLineWidth(1.2)
  for side=-1,1,2 do g.line(side*17,9,side*23,0,side*21,-5,side*32,-14) end
 end
 g.pop()
end
function S.tornado(t,time)
 local g=love.graphics;g.push('all');g.setShader()
 local x,y=t.x,t.y;local active=(t.cooldown or 0)<=0;local alpha=active and 1 or .4
 tint(.025,.08,.12,.65*alpha);g.ellipse('fill',x,y+7,32,15)
 tint(.55,.74,.77,.55*alpha);g.setLineWidth(1);g.ellipse('line',x,y+3,33,13)
 -- Opposed strands weave a funnel around a dark core; front/back fade gives depth.
 for strand=0,3 do
  local points={}
  for i=0,32 do
   local h=i/32;local a=time*5+h*tau*1.6+strand*tau/4
   local radius=9+27*h*h
   points[#points+1]=x+math.cos(a)*radius
   points[#points+1]=y-h*67+math.sin(a)*radius*.26
  end
  tint(.04,.15,.21,.55*alpha);g.setLineWidth(5);g.line(points)
  tint(.46,.72,.79,.7*alpha);g.setLineWidth(2.2);g.line(points)
  tint(.82,.93,.89,.7*alpha);g.setLineWidth(.7);g.line(points)
 end
 for i=1,9 do
  local h=(i/9+time*.32)%1;local a=time*5+i*2.4;local r=10+28*h*h
  local xx,yy=x+math.cos(a)*r,y-h*67+math.sin(a)*r*.3
  tint(.90,.81,.52,math.sin(h*math.pi)*.85*alpha)
  g.polygon('fill',xx,yy-2,xx+3,yy,xx,yy+2,xx-3,yy)
 end
 -- Retain steering feedback during the spin, with no text overlay.
 if player and player.whirl and player.whirl.tornado==t then
  local dx,dy=player.whirl.dx,player.whirl.dy
  tint(1,.91,.63,.9);g.setLineWidth(2)
  local xx,yy=x+dx*45,y+dy*45
  g.line(x+dx*26,y+dy*26,xx,yy,xx-dx*8-dy*5,yy-dy*8+dx*5)
  g.line(xx,yy,xx-dx*8+dy*5,yy-dy*8-dx*5)
 end
 g.pop()
end
function S.wind(width,height,time,wind)
 local g=love.graphics;g.push('all');g.setShader()
 local strength=math.sqrt(wind.x^2+wind.y^2);local dx,dy=1,-.15
 if strength>4 then dx,dy=wind.x/strength,wind.y/strength end
 local count=Graphics.quality==1 and 18 or 40
 for i=1,count do
  local x=(i*137.31+time*dx*(20+strength*.4))%width
  local y=(i*79.73+time*dy*(20+strength*.4)+math.sin(time*.5+i)*14)%height
  local pulse=(.5+.5*math.sin(time*.6+i))*.25
  if i%3==0 then
   tint(.91,.83,.59,pulse+.1);g.polygon('fill',x,y-2,x+1,y,x,y+2,x-1,y)
  else
   tint(.55,.80,.83,pulse);g.setLineWidth(.8)
   g.line(x-dx*14,y-dy*14,x-dx*7-dy*2,y-dy*7+dx*2,x,y)
  end
 end
 g.pop()
end
function S.trap(kind,x,y,size,active,angle)
 local g=love.graphics;g.push('all');g.setShader();g.translate(x,y);g.rotate(angle or 0);g.scale(size/64)
 local wheel=kind=='scie'
 if not wheel then g.scale(1,.48) end
 tint(.025,.065,.09);g.circle('fill',0,0,29)
 for i=0,7 do
  g.push();g.rotate(i*tau/8)
  tint(.19,.32,.38);g.polygon('fill',20,-10,29,-9,32,1,20,9,active and 4 or 17,0)
  tint(.65,.76,.72);g.setLineWidth(1);g.line(24,-9,29,-8,31,0,active and 5 or 18,0)
  if wheel or active then tint(.87,.81,.55);g.polygon('fill',20,-5,33,0,20,3) end
  g.pop()
 end
 if wheel then tint(.66,.76,.72);g.circle('line',0,0,12);tint(.87,.81,.55);g.polygon('fill',0,-7,5,0,0,7,-5,0) end
 g.pop()
end
function S.feather(x,y,angle,size)
 local g=love.graphics;g.push('all');g.translate(x,y);g.rotate(angle);g.scale((size or 32)/32)
 tint(.035,.07,.10);g.polygon('fill',-18,0,-11,-5,2,-3,9,0,2,3,-11,5)
 tint(.45,.65,.70);g.setLineWidth(.8);g.line(-15,0,8,0)
 for i=-10,0,4 do g.line(i-3,-3,i,0,i-3,3) end
 g.pop()
end
return S
