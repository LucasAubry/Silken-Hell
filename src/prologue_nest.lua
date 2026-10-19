-- Woven leaf-and-twig bed, cached once; no concentric outline rings.
local N={}
local function random(i,s)local v=math.sin(i*127.1+s*311.7)*43758.5453;return v-math.floor(v)end
local function oval(rx,ry,seed)
 local points={}
 for i=0,63 do local a=i*math.pi/32;local r=1+.045*math.sin(a*5+seed)+.025*math.sin(a*9-seed)
  points[#points+1]=math.cos(a)*rx*r;points[#points+1]=math.sin(a)*ry*r
 end
 return points
end
function N.load()
 if N.image then return end
 local g=love.graphics;N.image=g.newCanvas(240,160,{dpiscale=2})
 g.push('all');g.setCanvas(N.image);g.origin();g.setShader();g.clear();g.translate(120,76)
 for i=8,1,-1 do g.setColor(.045,.035,.019,.025);g.ellipse('fill',3,8,88+i,48+i*.7) end
 g.setColor(.18,.105,.042);g.polygon('fill',oval(89,51,.2))
 g.setColor(.33,.22,.095);g.polygon('fill',oval(80,44,1.3))
 -- Recessed earth and soft dried leaves in the hollow.
 g.setColor(.095,.085,.038);g.polygon('fill',oval(65,32,2))
 g.setColor(.25,.24,.11);g.ellipse('fill',0,6,62,27)
 for i=1,58 do
  local a=i*2.399;local r=math.sqrt(random(i,5));local x,y=math.cos(a)*60*r,6+math.sin(a)*25*r
  g.push();g.translate(x,y);g.rotate(a);g.setColor(.32+random(i,7)*.20,.25+random(i,8)*.13,.10+random(i,9)*.07,.82)
  g.ellipse('fill',0,0,4+random(i,10)*5,2+random(i,11)*2);g.pop()
 end
 -- Short, curved, overlapping twigs follow the rim in different directions.
 for i=1,175 do
  local a=i*2.399;local radius=.78+random(i,2)*.25
  local length=.22+random(i,3)*.55;local slant=(random(i,4)-.5)*.20
  local points={}
  for j=0,5 do local t=j/5;local angle=a+(t-.5)*length;local r=radius+slant*(t-.5)
   points[#points+1]=math.cos(angle)*88*r;points[#points+1]=math.sin(angle)*49*r+math.sin(t*math.pi)*2
  end
  local light=random(i,6);g.setColor(.14+light*.15,.085+light*.09,.032+light*.035)
  g.setLineWidth(2+random(i,12)*2);g.line(points)
  g.setColor(.40+light*.22,.25+light*.18,.105+light*.10,.85);g.setLineWidth(.8+random(i,13));g.line(points)
 end
 -- A few leaves tuck over the rim and break its silhouette.
 for i=1,21 do
  local a=i*2.399;g.push();g.translate(math.cos(a)*86,math.sin(a)*47);g.rotate(a+.8)
  g.setColor(.24+random(i,18)*.15,.24+random(i,19)*.13,.075)
  g.ellipse('fill',0,0,5+random(i,20)*5,3);g.pop()
 end
 -- Small silk tufts bind the twigs, without a drawn spiderweb across the bed.
 for i=1,16 do
  local a=i*2.399;local x,y=math.cos(a)*74,math.sin(a)*39
  g.setColor(.82,.77,.58,.17);g.ellipse('fill',x,y,5,2)
 end
 g.pop()
end
function N.draw(x,y)
 N.load();local g=love.graphics;g.push('all');g.setShader();g.setColor(1,1,1)
 g.setBlendMode('alpha','premultiplied');g.draw(N.image,x-120,y-76);g.pop()
end
return N
